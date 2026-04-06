extends CharacterBody2D

class_name AdvancedNPC

# ============================================
# 高级 NPC - 支持自主行为、多智能体互动
# ============================================

@export var npc_id: String = "npc_default"
@export var npc_name: String = "Villager"
@export var use_ai_dialogue: bool = true

@export_group("Personality")
@export var personality_traits: Array[String] = ["friendly"]
@export var values: Array[String] = ["community"]
@export var fears: Array[String] = ["loneliness"]
@export var dreams: Array[String] = ["prosperity"]
@export var quirks: Array[String] = []

@export_group("Background")
@export_multiline var backstory: String = "A villager living in the town."
@export var occupation: String = "Villager"
@export var age: String = "Adult"
@export var home_location: String = "town"

@export_group("Behavior")
@export var speech_style: String = "casual"
@export var interests: Array[String] = ["farming"]
@export var daily_schedule: Dictionary = {}

# AI 配置
var ai_config = {}

# 当前状态
var current_state = {
	"action": "idle",
	"emotion": "neutral",
	"emotion_intensity": 0.5,
	"target_position": null,
	"is_moving": false,
	"in_conversation": false,
	"conversation_partners": [],
	"energy": 1.0,
	"last_action_change": 0.0,
	"current_catchphrase": "",
	"habit_timer": 0.0
}

# 节点引用
@onready var sprite = $Sprite2D
@onready var name_label = $NameLabel
@onready var interaction_area = $InteractionArea
@onready var emotion_indicator = $EmotionIndicator
@onready var action_indicator = $ActionIndicator
@onready var catchphrase_label = $CatchphraseLabel  # 显示口头禅的气泡

# 信号
signal dialogue_ready(npc_id, dialogue_data)
signal action_started(npc_id, action)
signal action_completed(npc_id, action)
signal moved_to_position(npc_id, position)
signal spontaneous_speech(npc_id, speech_data)

const SPEED = 80.0
const WANDER_INTERVAL = 3.0

var wander_timer = 0.0
var state_check_timer = 0.0

func _ready():
	# 设置 ID
	if npc_id == "npc_default":
		npc_id = name.to_lower().replace(" ", "_")
	
	name_label.text = npc_name
	name_label.visible = false
	
	# 构建 AI 配置
	build_ai_config()
	
	# 注册到高级 AI 管理器
	if AdvancedAIAgentManager:
		AdvancedAIAgentManager.register_agent(npc_id, ai_config)
	
	# 注册到行为控制器
	if NPCBehaviorController:
		NPCBehaviorController.register_npc(npc_id)
		
		# 连接信号
		NPCBehaviorController.npc_moved_to.connect(_on_move_request)
		NPCBehaviorController.spontaneous_interaction.connect(_on_spontaneous_interaction)
	
	# 连接对话信号
	if AdvancedAIAgentManager:
		AdvancedAIAgentManager.agent_response_ready.connect(_on_ai_response)
	
	# 播放初始化音效
	play_initialization_sound()
	
	print("[AdvancedNPC] Initialized: ", npc_name, " (", npc_id, ")")

func _process(delta):
	update_timers(delta)
	update_movement()
	update_visual_indicators()
	update_catchphrases(delta)
	update_habitual_actions(delta)
	check_environmental_triggers()

func build_ai_config():
	"""构建 AI 配置"""
	ai_config = {
		"name": npc_name,
		"age": age,
		"occupation": occupation,
		"backstory": backstory,
		"home_location": home_location,
		"personality": {
			"traits": personality_traits,
			"values": values,
			"fears": fears,
			"dreams": dreams,
			"quirks": quirks
		},
		"speech_style": speech_style,
		"interests": interests,
		"schedule": daily_schedule,
		"life_context": "%s living in %s. Works as %s." % [npc_name, home_location, occupation]
	}

func update_timers(delta: float):
	"""更新定时器"""
	wander_timer -= delta
	state_check_timer -= delta
	
	if wander_timer <= 0 and not current_state.in_conversation:
		wander_timer = WANDER_INTERVAL + randf_range(-1.0, 1.0)
		decide_next_action()
	
	if state_check_timer <= 0:
		state_check_timer = 5.0
		check_state_changes()

func decide_next_action():
	"""决定下一步行动"""
	# 如果有日程安排，优先执行
	if not daily_schedule.is_empty() and AdvancedAIAgentManager:
		var current_time = GameManager.current_time if GameManager else 10.0
		var activity = AdvancedAIAgentManager.get_current_activity(daily_schedule, current_time)
		
		if activity:
			set_action(activity.get("action", "idle"))
			return
	
	# 否则随机游荡
	if randf() < 0.4:
		start_wandering()

func start_wandering():
	"""开始游荡"""
	var wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var target_pos = global_position + wander_dir * 100.0
	
	# 限制在合理范围内
	target_pos.x = clamp(target_pos.x, 50, 1200)
	target_pos.y = clamp(target_pos.y, 50, 650)
	
	current_state.target_position = target_pos
	current_state.is_moving = true
	set_action("wandering")

func update_movement():
	"""更新移动"""
	if not current_state.is_moving or current_state.in_conversation:
		velocity = Vector2.ZERO
		return
	
	if current_state.target_position:
		var direction = (current_state.target_position - global_position).normalized()
		velocity = direction * SPEED
		
		# 检查是否到达目标
		if global_position.distance_to(current_state.target_position) < 5.0:
			current_state.is_moving = false
			current_state.target_position = null
			moved_to_position.emit(npc_id, global_position)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 更新朝向
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func set_action(new_action: String):
	"""设置当前动作"""
	if current_state.action != new_action:
		var old_action = current_state.action
		current_state.action = new_action
		current_state.last_action_change = Time.get_unix_time_from_system()
		
		action_started.emit(npc_id, new_action)
		
		# 播放对应动画（如果有）
		play_action_animation(new_action)

func play_action_animation(action: String):
	"""播放动作动画"""
	# 这里可以扩展为实际的动画播放
	match action:
		"wandering":
			pass  # 播放行走动画
			play_activity_sound("walking")
		"reading":
			pass  # 播放阅读动画
			play_activity_sound("reading")
		"working":
			pass  # 播放工作动画
			play_activity_sound("working")
		"resting":
			pass  # 播放休息动画

func play_initialization_sound():
	"""播放初始化音效"""
	if NPCAudioManager and EnhancedPersonalitySystem:
		var audio_profile = EnhancedPersonalitySystem.get_npc_audio_profile(npc_id)
		if audio_profile.has("greeting"):
			NPCAudioManager.play_emotion_sound(npc_id, current_state.emotion)

func play_activity_sound(activity: String):
	"""播放活动音效"""
	if NPCAudioManager and EnhancedPersonalitySystem:
		var activity_sounds = EnhancedPersonalitySystem.get_activity_sounds(npc_id, activity)
		if not activity_sounds.is_empty():
			var sound_path = activity_sounds[randi() % activity_sounds.size()]
			NPCAudioManager.play_activity_sound(npc_id, sound_path, 0.7)

func update_visual_indicators():
	"""更新视觉指示器"""
	# 显示情绪
	if emotion_indicator and NPCEmotionSystem:
		var emotion_desc = NPCEmotionSystem.get_emotion_description(npc_id)
		# 可以显示情绪图标或颜色

func check_environmental_triggers():
	"""检查环境触发器"""
	# 天气变化
	if WeatherSystem and randf() < 0.01:
		var weather = WeatherSystem.get_weather_name().to_lower()
		if weather == "rain" and current_state.action != "seeking_shelter":
			maybe_react_to_weather(weather)
	
	# 环境音效（低频率）
	if NPCAudioManager and EnhancedPersonalitySystem and randf() < 0.005:
		play_ambient_sound()

func play_ambient_sound():
	"""播放环境音效"""
	var location = get_current_location_name()
	var ambient_sounds = EnhancedPersonalitySystem.get_ambient_sounds(npc_id, location)
	if not ambient_sounds.is_empty():
		var sound_path = ambient_sounds[randi() % ambient_sounds.size()]
		NPCAudioManager.play_ambient_sound(npc_id, sound_path, 0.4)

func maybe_react_to_weather(weather: String):
	"""对天气做出反应"""
	match weather:
		"rain":
			if randf() < 0.7:
				spontaneous_speech.emit(npc_id, {
					"type": "reaction",
					"text": get_weather_comment("rain"),
					"priority": "low"
				})
				# Play rain reaction sound
				if NPCAudioManager:
					NPCAudioManager.play_emotion_sound(npc_id, "neutral")

func get_weather_comment(weather: String) -> String:
	"""获取天气评论"""
	match weather:
		"rain":
			var comments = [
				"Looks like it's going to rain...",
				"I hope the crops enjoy this!",
				"Good weather for staying inside with a book."
			]
			return comments[randi() % comments.size()]
	return ""

func check_state_changes():
	"""检查状态变化"""
	# 能量恢复
	if current_state.action == "resting":
		current_state.energy = min(1.0, current_state.energy + 0.05)
	else:
		current_state.energy = max(0.0, current_state.energy - 0.01)
	
	# 如果能量太低，自动休息
	if current_state.energy < 0.2 and current_state.action != "resting":
		set_action("resting")

# ============================================
# 对话系统
# ============================================

func interact(player_message: String = "") -> String:
	"""与玩家互动"""
	current_state.in_conversation = true
	
	if use_ai_dialogue and AdvancedAIAgentManager:
		return generate_ai_response(player_message)
	else:
		return get_fallback_dialogue()

func generate_ai_response(player_message: String) -> String:
	"""生成 AI 响应"""
	var context = build_interaction_context(player_message)
	
	var callback = func(agent_id, response):
		if agent_id == npc_id:
			if response.has("error"):
				dialogue_ready.emit(npc_id, {
					"dialogue": "Sorry, I'm not feeling talkative right now...",
					"error": true
				})
			else:
				dialogue_ready.emit(npc_id, response)
				
				# 更新情绪
				if response.has("emotion") and NPCEmotionSystem:
					parse_and_set_emotion(response.emotion)
				
				current_state.in_conversation = false
	
	AdvancedAIAgentManager.generate_dialogue_async(npc_id, context, callback, 10)
	
	return "..."  # 等待异步响应

func build_interaction_context(player_message: String) -> Dictionary:
	"""构建交互上下文"""
	var nearby_npcs = get_nearby_npcs()
	
	return {
		"type": "player_interaction",
		"player_message": player_message,
		"time": GameManager.current_time if GameManager else 10.0,
		"weather": WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny",
		"season": GameManager.player_data.season if GameManager else "spring",
		"day": GameManager.player_data.day if GameManager else 1,
		"year": GameManager.player_data.year if GameManager else 1,
		"location": get_current_location_name(),
		"nearby_npcs": nearby_npcs,
		"my_action": current_state.action,
		"my_emotion": current_state.emotion,
		"keywords": extract_keywords(player_message)
	}

func extract_keywords(message: String) -> Array:
	"""提取关键词"""
	var keywords = []
	var important_words = ["crop", "farm", "weather", "festival", "gift", "friend", "work"]
	
	for word in important_words:
		if word in message.to_lower():
			keywords.append(word)
	
	return keywords

func get_fallback_dialogue() -> String:
	"""备用对话"""
	var fallbacks = [
		"Hello there!",
		"Nice day, isn't it?",
		"How's your farm doing?",
		"See you around!"
	]
	return fallbacks[randi() % fallbacks.size()]

func _on_ai_response(agent_id: String, response: Dictionary):
	"""处理 AI 响应"""
	if agent_id != npc_id:
		return
	
	# 执行动作
	if response.has("action") and response.action != "":
		execute_action(response.action)
	
	# 更新情绪
	if response.has("emotion"):
		current_state.emotion = response.emotion.to_lower()

func execute_action(action_text: String):
	"""执行动作"""
	action_text = action_text.to_lower()
	
	if "walk" in action_text or "move" in action_text:
		# 解析移动方向
		start_wandering()
	elif "wave" in action_text:
		# 挥手动作
		pass
	elif "work" in action_text or "farm" in action_text:
		set_action("working")
	elif "rest" in action_text or "sit" in action_text:
		set_action("resting")

func parse_and_set_emotion(emotion_text: String):
	"""解析并设置情绪"""
	emotion_text = emotion_text.to_lower()
	
	if "happy" in emotion_text or "cheerful" in emotion_text:
		current_state.emotion = "happy"
	elif "sad" in emotion_text or "unhappy" in emotion_text:
		current_state.emotion = "sad"
	elif "tired" in emotion_text:
		current_state.emotion = "tired"
	elif "excited" in emotion_text:
		current_state.emotion = "excited"
	else:
		current_state.emotion = "neutral"

# ============================================
# NPC 间互动
# ============================================

func start_conversation_with(other_npc: AdvancedNPC, topic: String = ""):
	"""主动与其他 NPC 对话"""
	if current_state.in_conversation:
		return
	
	current_state.in_conversation = true
	current_state.conversation_partners.append(other_npc.npc_id)
	
	if AdvancedAIAgentManager:
		var context = {
			"type": "npc_to_npc",
			"target_npc": other_npc.npc_id,
			"target_name": other_npc.npc_name,
			"topic": topic,
			"relationship": get_relationship_with(other_npc.npc_id)
		}
		
		var callback = func(agent_id, response):
			if not response.has("error"):
				spontaneous_speech.emit(npc_id, {
					"type": "npc_conversation",
					"target": other_npc.npc_id,
					"content": response
				})
		
		AdvancedAIAgentManager.generate_dialogue_async(npc_id, context, callback, 5)

func get_relationship_with(other_npc_id: String) -> Dictionary:
	"""获取与另一个 NPC 的关系"""
	if AdvancedAIAgentManager:
		return AdvancedAIAgentManager.get_relationship_between(npc_id, other_npc_id)
	return {"type": "acquaintance", "strength": 0.5}

# ============================================
# 辅助函数
# ============================================

func get_nearby_npcs(radius: float = 200.0) -> Array:
	"""获取附近的 NPC"""
	var nearby = []
	
	# 需要从场景中查找
	var world = get_tree().get_root()
	for child in world.get_children():
		if child is AdvancedNPC and child != self:
			if global_position.distance_to(child.global_position) <= radius:
				nearby.append(child.npc_id)
	
	return nearby

func get_current_location_name() -> String:
	"""获取当前位置名称"""
	var pos = global_position
	
	if pos.x < 300:
		return "forest"
	elif pos.x > 900:
		return "beach"
	elif pos.y < 250:
		return "mountains"
	else:
		return "town"

func _on_move_request(requested_npc_id: String, target: Vector2):
	"""处理移动请求"""
	if requested_npc_id == npc_id:
		current_state.target_position = target
		current_state.is_moving = true

func _on_spontaneous_interaction(npc1_id: String, npc2_id: String, type: String):
	"""处理自发互动"""
	if npc1_id == npc_id or npc2_id == npc_id:
		# 参与互动
		var other_id = npc2_id if npc1_id == npc_id else npc1_id
		participate_in_interaction(other_id, type)

func participate_in_interaction(other_npc_id: String, interaction_type: String):
	"""参与互动"""
	current_state.in_conversation = true
	current_state.conversation_partners.append(other_npc_id)
	
	set_action("chatting")

func _on_interaction_area_mouse_entered():
	name_label.visible = true

func _on_interaction_area_mouse_exited():
	if not current_state.in_conversation:
		name_label.visible = false

func _exit_tree():
	"""清理"""
	if AdvancedAIAgentManager:
		AdvancedAIAgentManager.unregister_agent(npc_id)
	
	if NPCBehaviorController:
		NPCBehaviorController.unregister_npc(npc_id)

# ============================================
# 口头禅和习惯动作系统
# ============================================

func update_catchphrases(delta: float):
	"""更新口头禅显示"""
	if not NPCPersonalitySystem and not EnhancedPersonalitySystem:
		return
	
	# 随机显示口头禅（低频率）
	if randf() < 0.001 and not current_state.in_conversation:
		var situation = detect_situation()
		var catchphrase = ""
		
		# Try enhanced system first, fallback to old system
		if EnhancedPersonalitySystem:
			catchphrase = EnhancedPersonalitySystem.get_catchphrase(npc_id, situation)
		elif NPCPersonalitySystem:
			catchphrase = NPCPersonalitySystem.get_catchphrase(npc_id, situation)
		
		if catchphrase != "":
			show_catchphrase_bubble(catchphrase)
			play_greeting_sound(situation)

func update_habitual_actions(delta: float):
	"""更新习惯动作"""
	if not NPCPersonalitySystem:
		return
	
	current_state.habit_timer -= delta
	
	if current_state.habit_timer <= 0 and not current_state.in_conversation:
		current_state.habit_timer = randf_range(10.0, 30.0)
		
		# 根据当前情绪执行习惯动作
		var mood = get_current_mood_category()
		var habit_action = NPCPersonalitySystem.get_habitual_action(npc_id, mood)
		
		if habit_action != "":
			execute_habit_action(habit_action)

func show_catchphrase_bubble(text: String):
	"""显示口头禅气泡"""
	# 如果有 catchphrase_label，显示文本
	if has_node("CatchphraseLabel"):
		catchphrase_label.text = text
		catchphrase_label.visible = true
		
		# 3秒后隐藏
		await get_tree().create_timer(3.0).timeout
		catchphrase_label.visible = false

func execute_habit_action(action: String):
	"""执行习惯动作"""
	# 这里可以触发动画或特效
	print("[NPC:%s] Habit: %s" % [npc_name, action])
	
	# 播放习惯动作音效
	if NPCAudioManager:
		NPCAudioManager.play_activity_sound(npc_id, "", 0.5)
	
	# 示例：根据动作改变状态
	if "humming" in action or "whistling" in action:
		# 播放哼唱动画/音效
		play_emotion_sound("happy")
	elif "jumping" in action:
		# 小跳跃
		velocity.y = -100
	elif "spinning" in action:
		# 旋转
		sprite.rotation += PI

func play_greeting_sound(situation: String):
	"""播放问候音效"""
	if NPCAudioManager and EnhancedPersonalitySystem:
		var greeting_sounds = EnhancedPersonalitySystem.get_greeting_sounds(npc_id, situation)
		if not greeting_sounds.is_empty():
			var sound_path = greeting_sounds[randi() % greeting_sounds.size()]
			NPCAudioManager.play_greeting_sound(npc_id, sound_path, 0.8)

func play_emotion_sound(emotion: String):
	"""播放情绪音效"""
	if NPCAudioManager:
		NPCAudioManager.play_emotion_sound(npc_id, emotion)

func detect_situation() -> String:
	"""检测当前情境"""
	if current_state.energy < 0.3:
		return "tired"
	
	var weather = WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny"
	if weather == "rain":
		return "raining"
	
	var time = GameManager.current_time if GameManager else 10.0
	if time < 8:
		return "morning"
	elif time > 20:
		return "night"
	
	# 默认返回 greeting
	return "greeting"

func get_current_mood_category() -> String:
	"""获取当前情绪分类"""
	match current_state.emotion:
		"happy", "excited", "cheerful":
			return "happy"
		"sad", "worried", "anxious":
			return "worried"
		"thinking", "confused":
			return "thinking"
		"bored", "tired":
			return "bored"
		_:
			return "idle"

func react_to_gift(gift_id: String) -> Dictionary:
	"""对礼物做出反应"""
	if not NPCPersonalitySystem and not EnhancedPersonalitySystem:
		return {"level": "neutral", "points": 20}
	
	var reaction = {}
	if EnhancedPersonalitySystem:
		reaction = EnhancedPersonalitySystem.check_gift_preference(npc_id, gift_id)
	elif NPCPersonalitySystem:
		reaction = NPCPersonalitySystem.check_gift_preference(npc_id, gift_id)
	
	# 根据喜好程度触发不同反应
	match reaction.level:
		"loved":
			trigger_emotion_reaction("loves_it")
			play_emotion_sound("happy")
			if EnhancedPersonalitySystem:
				show_catchphrase_bubble(EnhancedPersonalitySystem.get_catchphrase(npc_id, "excitement"))
			elif NPCPersonalitySystem:
				show_catchphrase_bubble(NPCPersonalitySystem.get_catchphrase(npc_id, "excitement"))
		"liked":
			trigger_emotion_reaction("likes_it")
			play_emotion_sound("happy")
		"disliked":
			trigger_emotion_reaction("dislikes_it")
			play_emotion_sound("sad")
		"hated":
			trigger_emotion_reaction("hates_it")
			play_emotion_sound("angry")
	
	return reaction

func trigger_emotion_reaction(reaction_type: String):
	"""触发情绪反应"""
	var special_reaction = ""
	if EnhancedPersonalitySystem:
		special_reaction = EnhancedPersonalitySystem.get_special_reaction(npc_id, reaction_type)
	elif NPCPersonalitySystem:
		special_reaction = NPCPersonalitySystem.get_special_reaction(npc_id, reaction_type)
	
	if special_reaction != "":
		show_catchphrase_bubble(special_reaction)
