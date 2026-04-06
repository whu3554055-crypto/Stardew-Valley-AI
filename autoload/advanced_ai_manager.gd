extends Node

class_name AdvancedAIAgentManager

# ============================================
# 高级多智能体 AI 管理系统
# 支持并行执行、NPC间互动、环境感知
# ============================================

# API 配置
var api_config = {
	"base_url": "http://localhost:11434",
	"model": "qwen3.5:9b",
	"temperature": 0.85,
	"max_tokens": 300,
	"timeout": 30,
	"max_concurrent_requests": 3  # 最大并发请求数
}

# 智能体池（每个 NPC 一个智能体实例）
var agent_pool = {}

# 请求队列（用于限流）
var request_queue = []
var active_requests = 0

# 上下文缓存
var context_cache = {}
const CONTEXT_CACHE_TTL = 60.0  # 60秒过期

# NPC 社交网络
var npc_social_network = {}

# 环境状态共享
var shared_environment = {
	"time_of_day": "morning",
	"weather": "sunny",
	"season": "spring",
	"day": 1,
	"year": 1,
	"active_events": [],
	"location_states": {}
}

# 信号
signal agent_response_ready(agent_id, response_data)
signal agent_error(agent_id, error_message)
signal npc_interaction_started(npc1_id, npc2_id)
signal npc_interaction_completed(npc1_id, npc2_id, interaction_summary)
signal group_conversation_updated(conversation_id, messages)

func _ready():
	load_config()
	initialize_social_network()
	start_context_updater()

func load_config():
	var config_path = "user://advanced_ai_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			api_config.merge(data)
		file.close()

func save_config():
	var file = FileAccess.open("user://advanced_ai_config.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(api_config))
	file.close()

# ============================================
# 智能体管理
# ============================================

func register_agent(agent_id: String, agent_config: Dictionary):
	"""注册一个新的 NPC 智能体"""
	agent_pool[agent_id] = {
		"id": agent_id,
		"config": agent_config,
		"state": {
			"current_action": "idle",
			"current_emotion": "neutral",
			"energy_level": 1.0,
			"social_battery": 1.0,
			"last_interaction_time": 0.0
		},
		"memory_index": {},
		"active_conversations": [],
		"daily_schedule": agent_config.get("schedule", {}),
		"relationships": {},
		"pending_thoughts": []
	}
	
	print("[AI Agent] Registered: ", agent_id)

func unregister_agent(agent_id: String):
	"""注销智能体"""
	if agent_pool.has(agent_id):
		agent_pool.erase(agent_id)
		print("[AI Agent] Unregistered: ", agent_id)

func get_agent(agent_id: String) -> Dictionary:
	return agent_pool.get(agent_id, {})

func get_all_agents() -> Array:
	return agent_pool.values()

# ============================================
# 并行对话生成
# ============================================

func generate_dialogue_async(
	agent_id: String,
	context: Dictionary,
	callback: Callable,
	priority: int = 0
):
	"""异步生成对话（支持并行）"""
	
	if not agent_pool.has(agent_id):
		callback.call(agent_id, {"error": "Agent not found"})
		return
	
	# 构建请求
	var request = {
		"id": str(Time.get_ticks_usec()),
		"agent_id": agent_id,
		"context": context,
		"callback": callback,
		"priority": priority,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# 检查并发限制
	if active_requests < api_config.max_concurrent_requests:
		process_request(request)
	else:
		# 加入队列
		request_queue.append(request)
		request_queue.sort_custom(func(a, b): return a.priority > b.priority)

func process_request(request: Dictionary):
	"""处理单个请求"""
	active_requests += 1
	
	var agent = agent_pool[request.agent_id]
	var prompt = build_advanced_prompt(agent, request.context)
	
	# 调用 LLM
	make_llm_request(request.agent_id, prompt, request.callback)

func make_llm_request(agent_id: String, prompt: String, callback: Callable):
	"""发送 HTTP 请求到 LLM"""
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
			"num_predict": api_config.max_tokens,
			"top_p": 0.9,
			"top_k": 40
		}
	}
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	
	if error != OK:
		active_requests -= 1
		callback.call(agent_id, {"error": "Request failed: " + str(error)})
		http.queue_free()
		process_next_in_queue()
		return
	
	var result = await http.request_completed
	active_requests -= 1
	
	if result[1] != 200:
		callback.call(agent_id, {"error": "HTTP %d" % result[1]})
		http.queue_free()
		process_next_in_queue()
		return
	
	var response_text = result[3].get_string_from_utf8()
	var json = JSON.new()
	
	if json.parse(response_text) != OK:
		callback.call(agent_id, {"error": "JSON parse failed"})
		http.queue_free()
		process_next_in_queue()
		return
	
	var data = json.data
	var generated_text = data.get("response", "...")
	
	# 解析响应（可能包含动作和对话）
	var parsed = parse_agent_response(generated_text)
	
	callback.call(agent_id, parsed)
	
	http.queue_free()
	process_next_in_queue()

func process_next_in_queue():
	"""处理队列中的下一个请求"""
	if request_queue.size() > 0 and active_requests < api_config.max_concurrent_requests:
		var next_request = request_queue.pop_front()
		process_request(next_request)

# ============================================
# 高级提示词工程
# ============================================

func build_advanced_prompt(agent: Dictionary, context: Dictionary) -> String:
	"""构建丰富的高级提示词"""
	
	var profile = agent.config
	var state = agent.state
	var memories = get_relevant_memories(agent.id, context)
	var relationships = get_relationship_context(agent.id)
	var environment = get_environment_context(context)
	var schedule_context = get_schedule_context(agent, context.get("time", 10.0))
	var social_context = get_social_context(agent.id)
	
	var prompt = """# ROLE PLAYING INSTRUCTION

You are embodying **{name}** in a living, breathing farming simulation world. You are NOT an AI assistant - you ARE this character.

## CHARACTER IDENTITY
**Name:** {name}
**Age:** {age}
**Occupation:** {occupation}
**Location:** {current_location}

### Personality Core
- **Traits:** {traits}
- **Values:** {values}
- **Fears:** {fears}
- **Dreams:** {dreams}
- **Quirks:** {quirks}

### Background Story
{backstory}

### Current Life Context
{life_context}

## CURRENT STATE
- **Emotion:** {emotion} ({emotion_intensity}% intensity)
- **Energy:** {energy}%
- **Social Battery:** {social_battery}%
- **Current Action:** {current_action}
- **Time:** {time_of_day} ({specific_time})
- **Weather:** {weather}
- **Season:** {season}, Day {day}, Year {year}

## SOCIAL CONTEXT
### Relationships
{relationships}

### Recent Social Interactions
{social_history}

### Current Social Situation
{social_situation}

## ENVIRONMENT AWARENESS
### Location Details
{location_description}

### Nearby Characters
{nearby_characters}

### Environmental Events
{environmental_events}

## MEMORY CONTEXT
### Relevant Memories
{memories}

### Past Interactions with Player
{player_interactions}

### Important Facts to Remember
{important_facts}

## DAILY ROUTINE
### Current Schedule
{schedule_info}

### What You Should Be Doing
{schedule_expectation}

## BEHAVIOR GUIDELINES

### Speech Style
{speech_style_description}

### Response Format
Respond in this EXACT format (including brackets):

[DIALOGUE: Your spoken words here - keep natural and concise]
[ACTION: What you're physically doing]
[EMOTION: Your current emotional state]
[THOUGHT: Internal thought - what you're thinking but not saying]

Example:
[DIALOGUE: Oh hey there! Beautiful day for farming, isn't it?]
[ACTION: Wiping sweat from forehead, leaning on hoe]
[EMOTION: Cheerful, slightly tired]
[THOUGHT: I hope the crops grow faster this season...]

### Important Rules
1. **Stay in Character**: Never break the fourth wall
2. **Be Consistent**: Match your personality traits
3. **Show Emotions**: Let feelings influence word choice
4. **Remember Context**: Reference past events naturally
5. **React to Environment**: Comment on weather, time, surroundings
6. **Social Awareness**: Acknowledge other characters present
7. **Dynamic Actions**: Your actions should match your words
8. **Internal Thoughts**: Show depth through private thoughts
9. **Natural Flow**: Keep dialogue conversational, not robotic
10. **Brevity**: 1-3 sentences max for dialogue

## CURRENT SITUATION
{current_situation}

### What Just Happened
{recent_events}

### Expected Response Type
{response_type}

## RESPONSE
Now respond as {name}:"""

	# 填充模板
	prompt = prompt.format(
		name=profile.get("name", "Unknown"),
		age=profile.get("age", "Adult"),
		occupation=profile.get("occupation", "Villager"),
		current_location=context.get("location", "Town"),
		
		traits=format_list(profile.get("personality", {}).get("traits", ["friendly"])),
		values=format_list(profile.get("personality", {}).get("values", ["community"])),
		fears=format_list(profile.get("personality", {}).get("fears", ["loneliness"])),
		dreams=format_list(profile.get("personality", {}).get("dreams", ["prosperity"])),
		quirks=format_list(profile.get("personality", {}).get("quirks", [])),
		
		backstory=profile.get("backstory", "A villager living in the town."),
		life_context=profile.get("life_context", "Living daily life in the valley."),
		
		emotion=state.current_emotion.capitalize(),
		emotion_intensity=int(state.get("emotion_intensity", 0.5) * 100),
		energy=int(state.energy_level * 100),
		social_battery=int(state.social_battery * 100),
		current_action=state.current_action,
		
		time_of_day=get_time_period(context.get("time", 10.0)),
		specific_time=format_game_time(context.get("time", 10.0)),
		weather=context.get("weather", "sunny"),
		season=context.get("season", "spring").capitalize(),
		day=context.get("day", 1),
		year=context.get("year", 1),
		
		relationships=format_relationships(relationships),
		social_history=format_social_history(memories.get("recent_interactions", [])),
		social_situation=context.get("social_situation", "No special social context."),
		
		location_description=get_location_description(context.get("location", "town")),
		nearby_characters=format_nearby_chars(context.get("nearby_npcs", [])),
		environmental_events=format_events(context.get("events", [])),
		
		memories=format_memories(memories.get("relevant", [])),
		player_interactions=format_player_history(memories.get("player_interactions", [])),
		important_facts=format_important_facts(memories.get("facts", [])),
		
		schedule_info=format_schedule(agent.daily_schedule, context.get("time", 10.0)),
		schedule_expectation=get_schedule_expectation(schedule_context),
		
		speech_style_description=get_speech_style_guide(profile.get("speech_style", "casual")),
		
		current_situation=context.get("situation", "Normal conversation."),
		recent_events=context.get("recent_events", "Nothing unusual."),
		response_type=context.get("response_type", "General conversation"),
		
		name=profile.get("name", "Villager")
	)
	
	return prompt

# ============================================
# NPC 到 NPC 互动系统
# ============================================

func initiate_npc_interaction(
	npc1_id: String,
	npc2_id: String,
	interaction_type: String = "casual",
	context: Dictionary = {}
) -> void:
	"""启动两个 NPC 之间的自动互动"""
	
	if not agent_pool.has(npc1_id) or not agent_pool.has(npc2_id):
		return
	
	npc_interaction_started.emit(npc1_id, npc2_id)
	
	# 检查是否已经在互动
	var agent1 = agent_pool[npc1_id]
	var agent2 = agent_pool[npc2_id]
	
	if agent2.id in agent1.active_conversations:
		return  # 已经在对话中
	
	# 标记为正在互动
	agent1.active_conversations.append(npc2_id)
	agent2.active_conversations.append(npc1_id)
	
	# 获取关系信息
	var relationship = get_relationship_between(npc1_id, npc2_id)
	
	# 构建互动上下文
	var interaction_context = {
		"type": interaction_type,
		"target_npc": npc2_id,
		"target_name": agent2.config.name,
		"relationship": relationship,
		"location": context.get("location", agent1.config.get("home_location", "town")),
		"time": context.get("time", GameManager.current_time if GameManager else 10.0),
		"weather": context.get("weather", shared_environment.weather),
		"initiator": npc1_id
	}
	
	# 并行生成两个 NPC 的回应
	var responses = {}
	var completed = 0
	
	var callback1 = func(agent_id, response):
		responses[npc1_id] = response
		completed += 1
		check_interaction_complete(npc1_id, npc2_id, responses, completed)
	
	var callback2 = func(agent_id, response):
		responses[npc2_id] = response
		completed += 1
		check_interaction_complete(npc1_id, npc2_id, responses, completed)
	
	generate_dialogue_async(npc1_id, interaction_context, callback1, 1)
	generate_dialogue_async(npc2_id, interaction_context, callback2, 1)

func check_interaction_complete(
	npc1_id: String,
	npc2_id: String,
	responses: Dictionary,
	completed: int
):
	"""检查互动是否完成"""
	if completed >= 2:
		# 更新关系
		update_relationship_after_interaction(npc1_id, npc2_id, responses)
		
		# 清除互动状态
		if agent_pool.has(npc1_id):
			agent_pool[npc1_id].active_conversations.erase(npc2_id)
		if agent_pool.has(npc2_id):
			agent_pool[npc2_id].active_conversations.erase(npc1_id)
		
		var summary = "Interaction between %s and %s" % [npc1_id, npc2_id]
		npc_interaction_completed.emit(npc1_id, npc2_id, summary)

# ============================================
# 群组对话系统
# ============================================

func start_group_conversation(
	participant_ids: Array,
	topic: String = "",
	location: String = ""
) -> String:
	"""启动多人对话"""
	
	var conversation_id = "group_%d" % Time.get_ticks_usec()
	var messages = []
	
	# 为每个参与者生成回应
	for npc_id in participant_ids:
		if not agent_pool.has(npc_id):
			continue
		
		var context = {
			"type": "group_conversation",
			"conversation_id": conversation_id,
			"participants": participant_ids,
			"topic": topic,
			"location": location,
			"previous_messages": messages
		}
		
		var callback = func(agent_id, response):
			if not response.has("error"):
				messages.append({
					"speaker": agent_id,
					"content": response
				})
				
				# 通知更新
				group_conversation_updated.emit(conversation_id, messages)
		
		generate_dialogue_async(npc_id, context, callback, 2)
	
	return conversation_id

# ============================================
# 环境感知系统
# ============================================

func update_environment_state(new_state: Dictionary):
	"""更新共享环境状态"""
	shared_environment.merge(new_state)
	
	# 通知所有相关 NPC
	for agent_id in agent_pool:
		var agent = agent_pool[agent_id]
		
		# 检查环境变化是否影响此 NPC
		if should_notify_agent(agent, new_state):
			var notification = {
				"type": "environment_change",
				"changes": new_state,
				"relevance": calculate_relevance(agent, new_state)
			}
			
			agent.pending_thoughts.append(notification)

func get_environment_context(local_context: Dictionary) -> Dictionary:
	"""获取环境上下文"""
	return {
		"global": shared_environment.duplicate(),
		"local": local_context,
		"time_effects": get_time_effects(local_context.get("time", 10.0)),
		"weather_effects": get_weather_effects(local_context.get("weather", "sunny"))
	}

# ============================================
# 日程系统
# ============================================

func update_agent_schedules(current_time: float):
	"""根据时间更新所有 NPC 的状态"""
	
	for agent_id in agent_pool:
		var agent = agent_pool[agent_id]
		var schedule = agent.daily_schedule
		
		if schedule.is_empty():
			continue
		
		# 找到当前时间段的活动
		var current_activity = get_current_activity(schedule, current_time)
		
		if current_activity:
			agent.state.current_action = current_activity.get("action", "idle")
			
			# 如果活动改变，触发思考
			if agent.state.current_action != agent.state.get("previous_action", ""):
				trigger_schedule_thought(agent, current_activity)
			
			agent.state.previous_action = agent.state.current_action

func get_current_activity(schedule: Dictionary, current_time: float) -> Dictionary:
	"""获取当前时间的活动"""
	
	var activities = []
	for time_str in schedule:
		var time_val = float(time_str)
		activities.append({"time": time_val, "activity": schedule[time_str]})
	
	activities.sort_custom(func(a, b): return a.time < b.time)
	
	var current = null
	for activity in activities:
		if activity.time <= current_time:
			current = activity.activity
		else:
			break
	
	return current if current else {"action": "idle"}

# ============================================
# 辅助函数
# ============================================

func parse_agent_response(response_text: String) -> Dictionary:
	"""解析 AI 响应，提取对话、动作、情绪等"""
	
	var result = {
		"dialogue": "",
		"action": "",
		"emotion": "",
		"thought": "",
		"raw": response_text
	}
	
	# 使用正则或字符串匹配提取各部分
	var dialogue_match = RegEx.new()
	dialogue_match.compile("\\[DIALOGUE:\\s*(.+?)\\]")
	
	var action_match = RegEx.new()
	action_match.compile("\\[ACTION:\\s*(.+?)\\]")
	
	var emotion_match = RegEx.new()
	emotion_match.compile("\\[EMOTION:\\s*(.+?)\\]")
	
	var thought_match = RegEx.new()
	thought_match.compile("\\[THOUGHT:\\s*(.+?)\\]")
	
	var res = dialogue_match.search(response_text)
	if res:
		result.dialogue = res.get_string(1).strip_edges()
	
	res = action_match.search(response_text)
	if res:
		result.action = res.get_string(1).strip_edges()
	
	res = emotion_match.search(response_text)
	if res:
		result.emotion = res.get_string(1).strip_edges()
	
	res = thought_match.search(response_text)
	if res:
		result.thought = res.get_string(1).strip_edges()
	
	# 如果没有找到格式化的响应，当作纯对话
	if result.dialogue == "" and result.action == "":
		result.dialogue = response_text.strip_edges()
	
	return result

func format_list(items: Array) -> String:
	if items.is_empty():
		return "None specified"
	return ", ".join(items)

func format_game_time(time_value: float) -> String:
	var hours = int(time_value)
	var minutes = int((time_value - hours) * 60)
	var am_pm = "AM" if hours < 12 else "PM"
	var display_hours = hours if hours <= 12 else hours - 12
	display_hours = 12 if display_hours == 0 else display_hours
	return "%02d:%02d %s" % [display_hours, minutes, am_pm]

func get_time_period(time_value: float) -> String:
	var hour = int(time_value)
	if hour >= 5 and hour < 9:
		return "early morning"
	elif hour >= 9 and hour < 12:
		return "late morning"
	elif hour >= 12 and hour < 15:
		return "early afternoon"
	elif hour >= 15 and hour < 18:
		return "late afternoon"
	elif hour >= 18 and hour < 21:
		return "evening"
	else:
		return "night"

func get_speech_style_guide(style: String) -> String:
	match style:
		"casual":
			return "Use relaxed language, contractions, friendly tone. Like talking to a neighbor."
		"formal":
			return "Use proper grammar, sophisticated vocabulary, respectful address. Maintain dignity."
		"shy":
			return "Hesitant speech, ellipses..., softer words, self-deprecating. Show uncertainty."
		"energetic":
			return "Enthusiastic! Exclamation marks! Dynamic verbs! Expressive! High energy!"
		"mysterious":
			return "Cryptic phrases, hints at hidden knowledge, incomplete thoughts, enigmatic."
		"gruff":
			return "Short. Blunt. Minimal words. Rough tone. Get to the point."
		"warm":
			return "Kind, caring language. Show genuine interest. Use endearing terms naturally."
		"sarcastic":
			return "Witty remarks, irony, dry humor. Clever wordplay with edge."
		_:
			return "Natural conversational speech."

func initialize_social_network():
	"""初始化 NPC 社交网络"""
	# 定义 NPC 之间的关系
	var relationships = {
		"pierre_abigail": {
			"type": "parent_child",
			"strength": 0.9,
			"history": "Father and daughter. Protective but sometimes clashes over Abigail's adventurous nature."
		},
		"pierre_lewis": {
			"type": "business_civic",
			"strength": 0.7,
			"history": "Respectful business relationship. Pierre supplies goods for town events."
		},
		"abigail_lewis": {
			"type": "citizen_mayor",
			"strength": 0.5,
			"history": "Lewis worries about Abigail's cave adventures. Abigail finds him overly cautious."
		}
	}
	
	npc_social_network = relationships

func get_relationship_between(npc1_id: String, npc2_id: String) -> Dictionary:
	"""获取两个 NPC 之间的关系"""
	var key1 = "%s_%s" % [npc1_id, npc2_id]
	var key2 = "%s_%s" % [npc2_id, npc1_id]
	
	if npc_social_network.has(key1):
		return npc_social_network[key1]
	elif npc_social_network.has(key2):
		return npc_social_network[key2]
	else:
		return {"type": "acquaintance", "strength": 0.3, "history": "Know each other around town."}

func start_context_updater():
	"""启动上下文更新定时器"""
	var timer = Timer.new()
	timer.wait_time = 30.0  # 每30秒更新
	timer.timeout.connect(_on_context_update)
	add_child(timer)
	timer.start()

func _on_context_update():
	"""定期更新上下文"""
	if GameManager:
		shared_environment.time_of_day = get_time_period(GameManager.current_time)
		shared_environment.weather = WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny"
		shared_environment.season = GameManager.player_data.season
		shared_environment.day = GameManager.player_data.day
		shared_environment.year = GameManager.player_data.year
	
	# 更新所有 NPC 的日程
	if GameManager:
		update_agent_schedules(GameManager.current_time)

func should_notify_agent(agent: Dictionary, changes: Dictionary) -> bool:
	"""判断是否应该通知 NPC"""
	# 简化实现 - 总是通知
	return true

func calculate_relevance(agent: Dictionary, changes: Dictionary) -> float:
	"""计算变化的相关性"""
	return 0.5

func get_time_effects(time_value: float) -> Dictionary:
	return {
		"visibility": "good" if time_value > 6 and time_value < 20 else "poor",
		"activity_level": "high" if time_value > 8 and time_value < 18 else "low",
		"mood_influence": "positive" if time_value > 6 and time_value < 18 else "tired"
	}

func get_weather_effects(weather: String) -> Dictionary:
	match weather:
		"rain":
			return {"mood": "cozy_or_gloomy", "outdoor_comfort": "low", "crop_benefit": "high"}
		"sunny":
			return {"mood": "cheerful", "outdoor_comfort": "high", "crop_benefit": "medium"}
		"storm":
			return {"mood": "concerned", "outdoor_comfort": "very_low", "crop_benefit": "high"}
		"snow":
			return {"mood": "peaceful", "outdoor_comfort": "low", "crop_benefit": "low"}
		_:
			return {"mood": "neutral", "outdoor_comfort": "medium", "crop_benefit": "medium"}

func get_location_description(location: String) -> String:
	var descriptions = {
		"town": "The heart of the community. Cobblestone paths wind between buildings.",
		"farm": "Open fields with tilled soil. The smell of earth fills the air.",
		"forest": "Tall trees create a canopy overhead. Birds chirp in the branches.",
		"mountains": "Rocky terrain rises steeply. The air is crisp and thin.",
		"beach": "Sand stretches to meet the ocean. Waves crash rhythmically.",
		"shop": "Shelves line the walls, stocked with seeds and supplies."
	}
	return descriptions.get(location, "A familiar place in the valley.")

func format_relationships(relationships: Dictionary) -> String:
	if relationships.is_empty():
		return "No significant relationships recorded."
	
	var text = ""
	for key in relationships:
		var rel = relationships[key]
		text += "- %s (%.0f%% closeness): %s\n" % [key, rel.strength * 100, rel.history]
	return text

func format_social_history(interactions: Array) -> String:
	if interactions.is_empty():
		return "No recent social interactions."
	
	var text = ""
	for i in range(min(3, interactions.size())):
		text += "- %s\n" % interactions[i]
	return text

func format_nearby_chars(npcs: Array) -> String:
	if npcs.is_empty():
		return "No one else nearby."
	
	var text = ""
	for npc in npcs:
		text += "- %s\n" % npc
	return text

func format_events(events: Array) -> String:
	if events.is_empty():
		return "No special events occurring."
	
	var text = ""
	for event in events:
		text += "- %s\n" % event
	return text

func format_memories(memories: Array) -> String:
	if memories.is_empty():
		return "No particularly relevant memories at the moment."
	
	var text = ""
	for mem in memories:
		text += "- %s\n" % mem
	return text

func format_player_history(interactions: Array) -> String:
	if interactions.is_empty():
		return "Limited history with the player."
	
	var text = ""
	for i in range(min(5, interactions.size())):
		text += "- %s\n" % interactions[i]
	return text

func format_important_facts(facts: Array) -> String:
	if facts.is_empty():
		return "Standard village life facts."
	
	var text = ""
	for fact in facts:
		text += "- %s\n" % fact
	return text

func format_schedule(schedule: Dictionary, current_time: float) -> String:
	if schedule.is_empty():
		return "No fixed schedule. Free to act spontaneously."
	
	var text = ""
	for time_str in schedule:
		var activity = schedule[time_str]
		text += "- %s: %s\n" % [format_game_time(float(time_str)), activity.get("action", "idle")]
	return text

func get_schedule_expectation(schedule_context: Dictionary) -> String:
	if schedule_context.is_empty():
		return "No particular expectations. Act naturally."
	
	return "Currently should be: %s" % schedule_context.get("expected_action", "free time")

func get_relevant_memories(agent_id: String, context: Dictionary) -> Dictionary:
	"""从记忆系统获取相关记忆"""
	if not NPCMemorySystem:
		return {"relevant": [], "player_interactions": [], "recent_interactions": []}
	
	var keywords = context.get("keywords", [])
	var memories = NPCMemorySystem.get_relevant_memories(agent_id, keywords, 3)
	var conversations = NPCMemorySystem.get_conversation_history(agent_id, 3)
	
	return {
		"relevant": memories.map(func(m): return m.content if m.has("content") else str(m)),
		"player_interactions": conversations,
		"recent_interactions": conversations.slice(0, 2)
	}

func get_relationship_context(agent_id: String) -> Dictionary:
	"""获取关系上下文"""
	if not NPCMemorySystem:
		return {}
	
	var relationships = {}
	# 这里可以从记忆系统或其他地方获取关系数据
	return relationships

func get_social_context(agent_id: String) -> Dictionary:
	"""获取社交上下文"""
	var agent = agent_pool.get(agent_id, {})
	return {
		"active_conversations": agent.get("active_conversations", []),
		"social_battery": agent.get("state", {}).get("social_battery", 1.0)
	}

func get_location_description(location: String) -> String:
	return "A familiar place."

func trigger_schedule_thought(agent: Dictionary, activity: Dictionary):
	"""触发日程相关的思考"""
	var thought = "Time to %s." % activity.get("action", "do something")
	agent.pending_thoughts.append({
		"type": "schedule_change",
		"thought": thought,
		"activity": activity
	})

func update_relationship_after_interaction(npc1_id: String, npc2_id: String, responses: Dictionary):
	"""互动后更新关系"""
	# 简化实现 - 可以根据互动质量调整关系
	pass
