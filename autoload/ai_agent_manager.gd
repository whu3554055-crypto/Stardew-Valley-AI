extends Node

# AI Agent configuration - Updated for multi-LLM backend
# Defaults favor 阿里云 DashScope OpenAI-compatible API so Agentic works without local Ollama.
# API key is never committed: use user://ai_agent_config.json, env var, or res://data/local/ai_secrets.json (gitignored).
var api_config = {
	"backend_url": "http://localhost:8080",  # FastAPI backend endpoint
	"base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1",
	"model": "qwen-plus",
	"temperature": 0.7,
	"max_tokens": 256,
	"timeout": 60,
	"use_backend": true,  # Use Python backend with multi-LLM router
	"task_type": "npc_dialogue",  # For smart routing
	# Direct LLM: "ollama" = POST /api/generate; "openai_compatible" = Bearer + /chat/completions (阿里云通义等)
	"llm_provider": "openai_compatible",
	"api_key": ""
}

# Request cache to avoid repeated calls
var response_cache = {}
const CACHE_EXPIRY = 300  # 5 minutes

# Current pending requests
var pending_requests = {}
var generation_trace_log: Array = []
const MAX_GENERATION_TRACE = 50

signal dialogue_generated(npc_id, dialogue)
signal agent_error(npc_id, error_message)
signal backend_status_changed(available: bool)

var _backend_available: bool = false

func _append_generation_trace(entry: Dictionary) -> void:
	generation_trace_log.append(entry)
	if generation_trace_log.size() > MAX_GENERATION_TRACE:
		generation_trace_log.pop_front()

func get_generation_trace(limit: int = 20) -> Array:
	var n: int = mini(maxi(limit, 1), generation_trace_log.size())
	if n <= 0:
		return []
	return generation_trace_log.slice(generation_trace_log.size() - n, generation_trace_log.size())

func print_generation_trace(limit: int = 20) -> void:
	var rows: Array = get_generation_trace(limit)
	print("[AIAgentManager] Generation trace (latest ", rows.size(), "):")
	for r in rows:
		var src: String = str(r.get("source", "unknown"))
		var ok: bool = bool(r.get("ok", false))
		var elapsed: int = int(r.get("elapsed_ms", -1))
		var mark: String = "OK" if ok else "ERR"
		print(" - ", mark, " ", src, " ", elapsed, "ms ", str(r))

func dump_generation_trace_to_file(path: String = "user://ai_generation_trace.log", limit: int = 50) -> bool:
	var rows: Array = get_generation_trace(limit)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[AIAgentManager] Failed to open trace file: ", path)
		return false
	for r in rows:
		f.store_line(JSON.stringify(r))
	f.close()
	print("[AIAgentManager] Wrote ", rows.size(), " trace rows to ", path)
	return true

func _ready():
	load_config()
	# Check backend availability on startup
	check_backend_status()

func _merge_llm_secrets_if_needed() -> void:
	# After user:// merge: fill api_key from environment or local file (not for public repos).
	var key: String = str(api_config.get("api_key", "")).strip_edges()
	if not key.is_empty():
		return
	for env_name in ["DASHSCOPE_API_KEY", "ALIYUN_API_KEY", "ALIYUN_DASHSCOPE_API_KEY"]:
		var ev: String = OS.get_environment(env_name).strip_edges()
		if not ev.is_empty():
			api_config.api_key = ev
			print("[AIAgentManager] Using API key from environment (%s)" % env_name)
			return
	var secret_path: String = "res://data/local/ai_secrets.json"
	if FileAccess.file_exists(secret_path):
		var f: FileAccess = FileAccess.open(secret_path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Dictionary:
				var k2: String = str(data.get("api_key", "")).strip_edges()
				if not k2.is_empty():
					api_config.api_key = k2
					if data.has("base_url"):
						api_config.base_url = str(data.get("base_url", api_config.base_url))
					if data.has("model"):
						api_config.model = str(data.get("model", api_config.model))
					if data.has("llm_provider"):
						api_config.llm_provider = str(data.get("llm_provider", api_config.llm_provider))
					print("[AIAgentManager] Loaded API key from res://data/local/ai_secrets.json")

func check_backend_status() -> void:
	"""Check if Python backend is available"""
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/health" % api_config.backend_url
	var error = http.request(url, [], HTTPClient.METHOD_GET)
	
	if error == OK:
		var result = await http.request_completed
		_backend_available = (result[1] == 200)
		emit_signal("backend_status_changed", _backend_available)
		print("[AIAgentManager] Backend status: ", "✓ Available" if _backend_available else "✗ Unavailable")
	else:
		_backend_available = false
		emit_signal("backend_status_changed", false)
		print("[AIAgentManager] Backend unavailable: ", error)
	
	http.queue_free()

func load_config():
	var config_path = "user://ai_agent_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			api_config.merge(data)
		file.close()
	_merge_llm_secrets_if_needed()

func save_config():
	var config_path = "user://ai_agent_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(api_config))
	file.close()

func configure_api(base_url: String, model: String, temperature: float = 0.8):
	api_config.base_url = base_url
	api_config.model = model
	api_config.temperature = temperature
	save_config()


func _chat_completions_url(base_raw: String) -> String:
	var b: String = str(base_raw).strip_edges()
	while b.ends_with("/"):
		b = b.substr(0, b.length() - 1)
	if b.ends_with("/chat/completions"):
		return b
	return "%s/chat/completions" % b


func _extract_openai_compatible_text(data: Dictionary) -> String:
	if data.has("error"):
		var err = data["error"]
		if err is Dictionary:
			return "__error__:" + str(err.get("message", JSON.stringify(err)))
		return "__error__:" + str(err)
	var choices = data.get("choices", [])
	if choices is Array and choices.size() > 0:
		var ch = choices[0]
		if ch is Dictionary:
			var msg = ch.get("message", {})
			if msg is Dictionary:
				return str(msg.get("content", ""))
			return str(ch.get("text", ""))
	return ""


func _parse_http_error_body(body: PackedByteArray) -> String:
	var txt: String = body.get_string_from_utf8().strip_edges()
	if txt.is_empty():
		return ""
	var jp := JSON.new()
	if jp.parse(txt) != OK or not (jp.data is Dictionary):
		return txt.substr(0, mini(280, txt.length()))
	var d: Dictionary = jp.data
	if d.has("error"):
		var e = d["error"]
		if e is Dictionary:
			return str(e.get("message", e.get("code", JSON.stringify(e))))
		return str(e)
	if d.has("message"):
		return str(d["message"])
	return txt.substr(0, mini(280, txt.length()))


func _llm_http_post_with_retry(
	url: String,
	header_lines: Array,
	body_str: String,
	timeout_sec: float,
	retry_on_throttle: bool
) -> Dictionary:
	var max_attempts: int = 2 if retry_on_throttle else 1
	for attempt in range(max_attempts):
		var http := HTTPRequest.new()
		add_child(http)
		http.timeout = timeout_sec
		var err := http.request(url, header_lines, HTTPClient.METHOD_POST, body_str)
		if err != OK:
			http.queue_free()
			return {"ok": false, "error": "request_failed", "detail": str(err)}
		var rw = await http.request_completed
		var status: int = int(rw[1])
		var body: PackedByteArray = rw[3]
		http.queue_free()
		if status == 200:
			return {"ok": true, "body": body}
		if attempt + 1 < max_attempts and [429, 502, 503].has(status):
			await get_tree().create_timer(1.5).timeout
			continue
		var err_detail: String = _parse_http_error_body(body)
		var err_msg: String = "HTTP %d" % status
		if not err_detail.is_empty():
			err_msg = "%s — %s" % [err_msg, err_detail]
		return {"ok": false, "error": err_msg}
	return {"ok": false, "error": "HTTP request failed"}


# Generate dialogue using AI agent
func generate_dialogue(
	npc_id: String,
	npc_name: String,
	personality: Dictionary,
	context: Dictionary,
	player_history: Array,
	prompt_template: String = ""
) -> void:
	
	var cache_key = "%s_%s_%d" % [npc_id, str(context), len(player_history)]
	
	# Check cache first
	if response_cache.has(cache_key):
		var cached = response_cache[cache_key]
		if Time.get_unix_time_from_system() - cached.timestamp < CACHE_EXPIRY:
			dialogue_generated.emit(npc_id, cached.response)
			return
	
	# Build the prompt
	var full_prompt = build_npc_prompt(
		npc_name, personality, context, player_history, prompt_template
	)
	
	# Make async request
	make_llm_request(npc_id, full_prompt, cache_key)

# Build comprehensive NPC prompt
func build_npc_prompt(
	npc_name: String,
	personality: Dictionary,
	context: Dictionary,
	player_history: Array,
	custom_template: String
) -> String:
	
	var time_info = context.get("time", "morning")
	var weather = context.get("weather", "sunny")
	var season = context.get("season", "spring")
	var location = context.get("location", "town")
	var relationship = context.get("relationship", 0)
	var recent_interactions = context.get("recent_interactions", [])
	
	# Personality traits
	var traits = personality.get("traits", ["friendly"])
	var occupation = personality.get("occupation", "villager")
	var backstory = personality.get("backstory", "")
	var speech_style = personality.get("speech_style", "normal")
	var interests = personality.get("interests", [])
	var mood = personality.get("current_mood", "neutral")
	
	var prompt = """You are roleplaying as %s, an NPC in a farming simulation game similar to Stardew Valley.

## CHARACTER PROFILE
**Name:** %s
**Occupation:** %s
**Personality Traits:** %s
**Speech Style:** %s
**Interests:** %s
**Current Mood:** %s

## BACKSTORY
%s

## CURRENT CONTEXT
- **Time:** %s
- **Weather:** %s
- **Season:** %s
- **Location:** %s
- **Relationship with Player:** %d/10 (0=stranger, 10=best friend)

## RECENT INTERACTIONS WITH PLAYER
%s

## INSTRUCTIONS
1. Respond in character as %s
2. Keep responses concise (1-3 sentences max)
3. Reflect your personality traits and current mood
4. Consider the time, weather, and your relationship level
5. Reference past interactions naturally if relevant
6. Show emotion through word choice and tone
7. If you have interests, mention them when appropriate
8. Be consistent with your occupation and backstory

## SPEECH STYLE GUIDE
%s

Respond with ONLY the dialogue text, no quotes or explanations.""" % [
		npc_name, npc_name, occupation, 
		str(traits), speech_style, str(interests), mood,
		backstory,
		time_info, weather, season, location, relationship,
		format_interaction_history(recent_interactions),
		npc_name,
		get_speech_style_guide(speech_style)
	]
	
	var memory_snippets = context.get("memory_snippets", [])
	if memory_snippets is Array and memory_snippets.size() > 0:
		prompt += "\n## RELEVANT MEMORIES (rumors, things you remember, town gossip)\n"
		for s in memory_snippets:
			prompt += "- %s\n" % str(s)
		prompt += "\nUse these only when they fit the moment; do not dump the whole list.\n"
	
	if custom_template != "":
		prompt += "\n\n" + custom_template
	
	return prompt

func format_interaction_history(history: Array) -> String:
	if history.is_empty():
		return "(No previous interactions)"
	
	var formatted = ""
	# History is newest-first; show up to the 5 most recent entries from the start
	var n = min(5, history.size())
	for i in range(n):
		var interaction = history[i]
		formatted += "- Day %d: %s\n" % [interaction.get("day", 0), interaction.get("summary", "")]
	
	return formatted

func get_speech_style_guide(style: String) -> String:
	match style:
		"formal":
			return "Use proper grammar, sophisticated vocabulary, polite expressions"
		"casual":
			return "Use contractions, slang, relaxed language, friendly tone"
		"shy":
			return "Use hesitant language, ellipses..., softer expressions, self-doubt"
		"energetic":
			return "Use exclamation marks!, enthusiastic language, dynamic expressions"
		"mysterious":
			return "Use cryptic language, hints, incomplete thoughts, enigmatic phrases"
		"gruff":
			return "Use short sentences, blunt language, minimal words, rough tone"
		_:
			return "Use natural, conversational language"

# Make HTTP request to LLM API
func request_text_generation(request: Dictionary) -> Dictionary:
	"""
	Unified client-side text generation entry.
	Request keys:
	- prompt (String, required)
	- model (String, optional)
	- temperature (float, optional)
	- max_tokens (int, optional)
	- extra_options (Dictionary, optional)
	- use_backend (bool, optional; default false)
	- backend_path (String, optional; requires use_backend)
	- backend_body (Dictionary, optional)
	- backend_text_key (String, optional; default "response")
	- timeout_sec (float, optional; overrides manager timeout)
	"""
	var prompt: String = str(request.get("prompt", ""))
	if prompt.is_empty():
		return {"ok": false, "error": "Missing prompt"}
	var source: String = str(request.get("source", "unknown"))
	var started_ms: int = Time.get_ticks_msec()

	var use_backend: bool = bool(request.get("use_backend", false))
	var backend_path: String = str(request.get("backend_path", ""))
	var use_direct_openai: bool = (
		not (use_backend and _backend_available and not backend_path.is_empty())
		and str(api_config.get("llm_provider", "ollama")) == "openai_compatible"
	)
	if use_direct_openai:
		if str(api_config.get("base_url", "")).strip_edges().is_empty():
			return {"ok": false, "error": "Missing base_url for openai_compatible"}
		if str(api_config.get("api_key", "")).strip_edges().is_empty():
			return {"ok": false, "error": "Missing api_key (set in user://ai_agent_config.json or AI config UI)"}

	var timeout_sec: float = float(request.get("timeout_sec", api_config.get("timeout", 30)))

	var headers := ["Content-Type: application/json"]
	var backend_body: Dictionary = request.get("backend_body", {})
	var backend_text_key: String = str(request.get("backend_text_key", "response"))
	var body_payload: Dictionary = {}
	var url: String = ""

	if use_backend and _backend_available and not backend_path.is_empty():
		url = "%s%s" % [str(api_config.get("backend_url", "http://localhost:8080")), backend_path]
		body_payload = backend_body if backend_body is Dictionary else {}
		if body_payload.is_empty():
			body_payload = {"prompt": prompt}
	elif use_direct_openai:
		url = _chat_completions_url(str(api_config.get("base_url", "")))
		var ak: String = str(api_config.get("api_key", "")).strip_edges()
		headers = ["Content-Type: application/json", "Authorization: Bearer %s" % ak]
		body_payload = {
			"model": str(request.get("model", api_config.get("model", "qwen-plus"))),
			"messages": [{"role": "user", "content": prompt}],
			"temperature": float(request.get("temperature", api_config.get("temperature", 0.7))),
			"max_tokens": int(request.get("max_tokens", api_config.get("max_tokens", 256)))
		}
		var extra_o: Dictionary = request.get("extra_options", {})
		if extra_o is Dictionary:
			for k in ["top_p", "frequency_penalty", "presence_penalty"]:
				if extra_o.has(k):
					body_payload[k] = extra_o[k]
	else:
		url = "%s/api/generate" % str(api_config.get("base_url", "http://localhost:11434"))
		var options: Dictionary = {
			"temperature": float(request.get("temperature", api_config.get("temperature", 0.7))),
			"num_predict": int(request.get("max_tokens", api_config.get("max_tokens", 256))),
		}
		var extra_options: Dictionary = request.get("extra_options", {})
		if extra_options is Dictionary:
			options.merge(extra_options, true)
		body_payload = {
			"model": str(request.get("model", api_config.get("model", "qwen3.5:9b"))),
			"prompt": prompt,
			"stream": false,
			"options": options
		}

	var post: Dictionary = await _llm_http_post_with_retry(
		url, headers, JSON.stringify(body_payload), timeout_sec, use_direct_openai
	)
	if not bool(post.get("ok", false)):
		var err_key: String = str(post.get("error", ""))
		if err_key == "request_failed":
			_append_generation_trace({
				"ts": Time.get_unix_time_from_system(),
				"source": source,
				"use_backend": use_backend and not backend_path.is_empty(),
				"ok": false,
				"error": "request_failed",
				"elapsed_ms": Time.get_ticks_msec() - started_ms
			})
			return {"ok": false, "error": "Request failed: %s" % str(post.get("detail", ""))}
		_append_generation_trace({
			"ts": Time.get_unix_time_from_system(),
			"source": source,
			"use_backend": use_backend and not backend_path.is_empty(),
			"ok": false,
			"error": "http_error",
			"detail": err_key,
			"elapsed_ms": Time.get_ticks_msec() - started_ms
		})
		return {"ok": false, "error": err_key}

	var response_text: String = (post["body"] as PackedByteArray).get_string_from_utf8()
	var json := JSON.new()
	if json.parse(response_text) != OK:
		_append_generation_trace({
			"ts": Time.get_unix_time_from_system(),
			"source": source,
			"use_backend": use_backend and not backend_path.is_empty(),
			"ok": false,
			"error": "json_parse_failed",
			"elapsed_ms": Time.get_ticks_msec() - started_ms
		})
		return {"ok": false, "error": "JSON parse failed"}

	var data: Dictionary = json.data if json.data is Dictionary else {}
	var text_out: String = ""
	if use_backend and not backend_path.is_empty():
		if data.has(backend_text_key):
			text_out = str(data.get(backend_text_key, ""))
		elif data.has("summary"):
			text_out = str(data.get("summary", ""))
		else:
			text_out = str(data.get("response", "..."))
	elif use_direct_openai:
		text_out = _extract_openai_compatible_text(data)
		if text_out.begins_with("__error__:"):
			_append_generation_trace({
				"ts": Time.get_unix_time_from_system(),
				"source": source,
				"use_backend": false,
				"ok": false,
				"error": "openai_error",
				"detail": text_out.trim_prefix("__error__:"),
				"elapsed_ms": Time.get_ticks_msec() - started_ms
			})
			return {"ok": false, "error": text_out.trim_prefix("__error__:")}
	else:
		text_out = str(data.get("response", "..."))
	_append_generation_trace({
		"ts": Time.get_unix_time_from_system(),
		"source": source,
		"use_backend": use_backend and not backend_path.is_empty(),
		"ok": true,
		"text_len": text_out.length(),
		"elapsed_ms": Time.get_ticks_msec() - started_ms
	})
	return {
		"ok": true,
		"text": text_out,
		"raw": data
	}


func make_llm_request(npc_id: String, prompt: String, cache_key: String) -> void:
	var gen: Dictionary = await request_text_generation({
		"prompt": prompt,
		"source": "npc_dialogue:%s" % npc_id
	})
	if not bool(gen.get("ok", false)):
		agent_error.emit(npc_id, str(gen.get("error", "Generation failed")))
		return
	var generated_text: String = str(gen.get("text", "..."))
	
	# Cache the response
	response_cache[cache_key] = {
		"response": generated_text,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	dialogue_generated.emit(npc_id, generated_text)

# Quick chat function for simple interactions
func quick_chat(
	npc_id: String,
	npc_name: String,
	message: String,
	personality: Dictionary = {},
	context: Dictionary = {}
) -> void:
	
	var default_personality = {
		"traits": ["friendly"],
		"occupation": "villager",
		"backstory": "A friendly villager living in the town.",
		"speech_style": "casual",
		"interests": ["farming"],
		"current_mood": "happy"
	}
	
	var final_personality = default_personality
	final_personality.merge(personality)
	
	var default_context = {
		"time": "morning",
		"weather": "sunny",
		"season": "spring",
		"location": "town",
		"relationship": 5,
		"recent_interactions": []
	}
	
	var final_context = default_context
	final_context.merge(context)
	
	generate_dialogue(
		npc_id,
		npc_name,
		final_personality,
		final_context,
		[],
		"Player says: " + message
	)

# Update NPC mood based on events
func update_npc_mood(
	npc_id: String,
	mood_change: Dictionary
) -> Dictionary:
	# This would integrate with the NPC's emotion system
	# For now, return a sample mood
	return {
		"mood": mood_change.get("mood", "neutral"),
		"intensity": mood_change.get("intensity", 0.5),
		"duration": mood_change.get("duration", 60.0)
	}

# Generate quest using AI agent
func generate_quest(
	npc_id: String,
	prompt: String
) -> void:
	if not _backend_available:
		return
		
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/v1/agent/%s/task" % [api_config.backend_url, npc_id]
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"task_type": "quest_generation",
		"prompt": prompt
	})
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		agent_error.emit(npc_id, "Quest generation request failed")
		http.queue_free()
		return
	
	var result = await http.request_completed
	if result[1] == 200:
		var response = JSON.parse_string(result[3].get_string_from_utf8())
		# This would ideally emit a specific signal that AIQuestSystem listens to
		# For now we use dialogue_generated as a placeholder or could add a new signal
		dialogue_generated.emit(npc_id, JSON.stringify(response.get("result", {})))
	
	http.queue_free()
# ============================================================================
# Phase 1 & 2 Features - Agent Control and WebSocket Integration
# ============================================================================

# Start autonomous agent for an NPC
func start_autonomous_agent(npc_id: String, interval: float = 10.0, personality: Dictionary = {}) -> void:
	"""Start autonomous decision-making agent for an NPC"""
	if not _backend_available:
		print("[AIAgentManager] Backend not available, cannot start agent")
		agent_error.emit(npc_id, "Backend unavailable")
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/v1/agent/%s/start" % [api_config.backend_url, npc_id]
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"interval": interval,
		"personality": personality
	})
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if error == OK:
		var result = await http.request_completed
		if result[1] == 200:
			var response = JSON.parse_string(result[3].get_string_from_utf8())
			print("[AIAgentManager] Agent started for ", npc_id, ": ", response)
		else:
			print("[AIAgentManager] Failed to start agent: ", result[1])
			agent_error.emit(npc_id, "HTTP " + str(result[1]))
	else:
		print("[AIAgentManager] Request failed: ", error)
		agent_error.emit(npc_id, "Request error " + str(error))
	
	http.queue_free()

# Stop autonomous agent for an NPC
func stop_autonomous_agent(npc_id: String) -> void:
	"""Stop autonomous agent for an NPC"""
	if not _backend_available:
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/v1/agent/%s/stop" % [api_config.backend_url, npc_id]
	var error = http.request(url, [], HTTPClient.METHOD_POST)
	
	if error == OK:
		var result = await http.request_completed
		if result[1] == 200:
			print("[AIAgentManager] Agent stopped for ", npc_id)
		else:
			print("[AIAgentManager] Failed to stop agent: ", result[1])
	
	http.queue_free()

# Get cache statistics
func get_cache_stats() -> Dictionary:
	"""Get Redis cache statistics"""
	if not _backend_available:
		return {}
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/v1/cache/stats" % api_config.backend_url
	var error = http.request(url, [], HTTPClient.METHOD_GET)
	
	var stats = {}
	
	if error == OK:
		var result = await http.request_completed
		if result[1] == 200:
			stats = JSON.parse_string(result[3].get_string_from_utf8())
			print("[AIAgentManager] Cache stats: ", stats)
	
	http.queue_free()
	return stats

# Clear cache
func clear_cache() -> void:
	"""Clear all cached data"""
	if not _backend_available:
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/v1/cache/clear" % api_config.backend_url
	var error = http.request(url, [], HTTPClient.METHOD_POST)
	
	if error == OK:
		var result = await http.request_completed
		if result[1] == 200:
			print("[AIAgentManager] Cache cleared")
			response_cache.clear()
	
	http.queue_free()

# Setup WebSocket connection for real-time events
func setup_websocket(client_id: String = "player1") -> void:
	"""Initialize WebSocket connection for real-time communication"""
	if has_node("/root/WebSocketClient"):
		print("[AIAgentManager] WebSocket already initialized")
		return
	
	var ws_client = preload("res://autoload/websocket_client.gd").new()
	ws_client.client_id = client_id
	get_tree().root.add_child(ws_client)
	
	# Connect signals
	ws_client.connection_status_changed.connect(_on_ws_connection_changed)
	ws_client.npc_dialogue_received.connect(_on_ws_npc_dialogue)
	ws_client.agent_action_received.connect(_on_ws_agent_action)
	ws_client.world_event_received.connect(_on_ws_world_event)
	
	print("[AIAgentManager] WebSocket client initialized")

# Subscribe to specific event types
func subscribe_to_events(event_types: Array) -> void:
	"""Subscribe to WebSocket events"""
	if not has_node("/root/WebSocketClient"):
		setup_websocket()
	
	var ws_client = get_node_or_null("/root/WebSocketClient")
	if ws_client:
		for event_type in event_types:
			ws_client.subscribe_to_event(event_type)
			print("[AIAgentManager] Subscribed to: ", event_type)

# WebSocket signal handlers
func _on_ws_connection_changed(status: bool):
	"""Handle WebSocket connection status changes"""
	print("[AIAgentManager] WebSocket connection: ", "connected" if status else "disconnected")

func _on_ws_npc_dialogue(npc_id: String, dialogue: String, emotion: String):
	"""Handle NPC dialogue received via WebSocket"""
	print("[AIAgentManager] Real-time dialogue from ", npc_id, ": ", dialogue)
	dialogue_generated.emit(npc_id, dialogue)

func _on_ws_agent_action(npc_id: String, action: String, result: Dictionary):
	"""Handle autonomous agent actions"""
	print("[AIAgentManager] Agent action: ", npc_id, " -> ", action)
	# Could trigger animations, sound effects, etc.

func _on_ws_world_event(event_type: String, data: Dictionary):
	"""Handle world events"""
	print("[AIAgentManager] World event: ", event_type, " - ", data)
	# Could update weather, time, etc.
