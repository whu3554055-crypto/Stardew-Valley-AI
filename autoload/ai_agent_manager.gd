extends Node

class_name AIAgentManager

# AI Agent configuration - Updated for multi-LLM backend
var api_config = {
	"backend_url": "http://localhost:8080",  # FastAPI backend endpoint
	"base_url": "http://localhost:11434",  # Ollama (fallback)
	"model": "qwen3.5:9b",
	"temperature": 0.7,
	"max_tokens": 256,
	"timeout": 30,
	"use_backend": true,  # Use Python backend with multi-LLM router
	"task_type": "npc_dialogue"  # For smart routing
}

# Request cache to avoid repeated calls
var response_cache = {}
const CACHE_EXPIRY = 300  # 5 minutes

# Current pending requests
var pending_requests = {}

signal dialogue_generated(npc_id, dialogue)
signal agent_error(npc_id, error_message)
signal backend_status_changed(available: bool)

var _backend_available: bool = false

func _ready():
	load_config()
	# Check backend availability on startup
	check_backend_status()

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
	
	if custom_template != "":
		prompt += "\n\n" + custom_template
	
	return prompt

func format_interaction_history(history: Array) -> String:
	if history.is_empty():
		return "(No previous interactions)"
	
	var formatted = ""
	for i in range(max(0, history.size() - 5), history.size()):  # Last 5 interactions
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
func make_llm_request(npc_id: String, prompt: String, cache_key: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "%s/api/generate" % api_config.base_url
	var headers = ["Content-Type: application/json"]
	
	var body = {
		"model": api_config.model,
		"prompt": prompt,
		"stream": false,
		"options": {
			"temperature": api_config.temperature,
			"num_predict": api_config.max_tokens
		}
	}
	
	var json_body = JSON.stringify(body)
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		agent_error.emit(npc_id, "Failed to send request: " + str(error))
		http.queue_free()
		return
	
	# Wait for response
	var result = await http.request_completed
	
	if result[1] != 200:
		agent_error.emit(npc_id, "HTTP Error: %d" % result[1])
		http.queue_free()
		return
	
	var response_text = result[3].get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		agent_error.emit(npc_id, "JSON Parse Error")
		http.queue_free()
		return
	
	var data = json.data
	var generated_text = data.get("response", "...")
	
	# Cache the response
	response_cache[cache_key] = {
		"response": generated_text,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	dialogue_generated.emit(npc_id, generated_text)
	http.queue_free()

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
>>>>+++ REPLACE



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
