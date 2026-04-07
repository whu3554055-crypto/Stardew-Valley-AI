extends Node

class_name NPCBehaviorController

# ============================================
# NPC 自主行为控制器
# 管理 NPC 的日常活动、决策和自动化互动
# ============================================

# NPC 行为模式
enum BehaviorMode {
	SCHEDULED,      # 按计划行动
	AUTONOMOUS,     # 自主决策
	INTERACTIVE,    # 与玩家互动
	SOCIAL,         # 与其他 NPC 社交
	IDLE            # 空闲
}

# 行为配置
var behavior_config = {
	"decision_interval": 10.0,     # 每10秒做一次决策
	"social_chance": 0.3,           # 30% 几率进行社交
	"wander_radius": 100.0,         # 游荡范围
	"max_conversation_distance": 150.0  # 对话最大距离
}

# NPC 状态跟踪
var npc_states = {}
var active_behaviors = {}
var behavior_timers = {}
var npc_relationship_stage = {}

# 信号
signal npc_started_action(npc_id, action)
signal npc_completed_action(npc_id, action)
signal npc_moved_to(npc_id, position)
signal spontaneous_interaction(npc1_id, npc2_id, type)
signal relationship_feedback(npc_id, stage, delta)

func _ready():
	initialize_npc_states()
	start_behavior_loop()

func _exit_tree():
	# 清理定时器
	for timer in behavior_timers.values():
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()

func initialize_npc_states():
	"""初始化所有 NPC 的状态"""
	# 从 AdvancedAIAgentManager 获取注册的 NPC
	if AdvancedAIAgentManager:
		for agent in AdvancedAIAgentManager.get_all_agents():
			var npc_id = agent.id
			npc_states[npc_id] = {
				"id": npc_id,
				"mode": BehaviorMode.SCHEDULED,
				"current_action": "idle",
				"target_position": null,
				"last_decision_time": 0.0,
				"energy": 1.0,
				"social_need": 0.5,
				"happiness": 0.7,
				"inventory": []
			}

func start_behavior_loop():
	"""启动行为循环"""
	var timer = Timer.new()
	timer.wait_time = behavior_config.decision_interval
	timer.timeout.connect(_on_behavior_tick)
	add_child(timer)
	timer.start()
	
	# 更频繁的位置更新
	var move_timer = Timer.new()
	move_timer.wait_time = 2.0
	move_timer.timeout.connect(_on_movement_tick)
	add_child(move_timer)
	move_timer.start()

func _on_behavior_tick():
	"""定期行为更新"""
	var current_time = GameManager.current_time if GameManager else 10.0
	
	for npc_id in npc_states:
		var state = npc_states[npc_id]
		
		# 检查是否应该做决策
		if current_time - state.last_decision_time >= behavior_config.decision_interval / 60.0:
			make_decision(npc_id)
			state.last_decision_time = current_time
		
		# 更新状态
		update_npc_state(npc_id)

func _on_movement_tick():
	"""定期移动更新"""
	for npc_id in npc_states:
		var state = npc_states[npc_id]
		
		if state.target_position and state.mode != BehaviorMode.INTERACTIVE:
			move_towards_target(npc_id, state.target_position)

func make_decision(npc_id: String):
	"""为 NPC 做出决策"""
	var state = npc_states[npc_id]
	var agent = AdvancedAIAgentManager.get_agent(npc_id) if AdvancedAIAgentManager else null
	
	if not agent:
		return
	
	# 收集决策信息
	var context = gather_decision_context(npc_id)
	
	# 决定行为模式
	var new_mode = decide_behavior_mode(npc_id, context)
	state.mode = new_mode
	
	# 执行对应的行为
	match new_mode:
		BehaviorMode.SCHEDULED:
			execute_scheduled_behavior(npc_id, context)
		BehaviorMode.AUTONOMOUS:
			execute_autonomous_behavior(npc_id, context)
		BehaviorMode.SOCIAL:
			execute_social_behavior(npc_id, context)
		BehaviorMode.IDLE:
			execute_idle_behavior(npc_id, context)

func gather_decision_context(npc_id: String) -> Dictionary:
	"""收集决策所需的上下文信息"""
	var state = npc_states[npc_id]
	var agent = AdvancedAIAgentManager.get_agent(npc_id)
	
	return {
		"time": GameManager.current_time if GameManager else 10.0,
		"weather": WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny",
		"season": GameManager.player_data.season if GameManager else "spring",
		"location": get_npc_location(npc_id),
		"nearby_npcs": get_nearby_npcs(npc_id),
		"nearby_player": is_player_nearby(npc_id),
		"energy": state.energy,
		"social_need": state.social_need,
		"current_schedule": agent.get("daily_schedule", {}),
		"personality": agent.get("config", {}).get("personality", {})
	}

func decide_behavior_mode(npc_id: String, context: Dictionary) -> int:
	"""决定行为模式"""
	var state = npc_states[npc_id]
	
	# 如果玩家在附近，优先互动
	if context.nearby_player:
		return BehaviorMode.INTERACTIVE
	
	# 高社交需求且附近有 NPC → 社交
	if state.social_need > 0.7 and context.nearby_npcs.size() > 0:
		if randf() < behavior_config.social_chance:
			return BehaviorMode.SOCIAL
	
	# 有日程安排 → 按计划行动
	if not context.current_schedule.is_empty():
		return BehaviorMode.SCHEDULED
	
	# 低能量 → 休息
	if state.energy < 0.3:
		return BehaviorMode.IDLE
	
	# 默认自主行动
	return BehaviorMode.AUTONOMOUS

func execute_scheduled_behavior(npc_id: String, context: Dictionary):
	"""执行计划行为"""
	var agent = AdvancedAIAgentManager.get_agent(npc_id)
	if not agent or agent.daily_schedule.is_empty():
		return
	
	var current_time = context.time
	var schedule = agent.daily_schedule
	
	# 找到当前应该做什么
	var expected_activity = AdvancedAIAgentManager.get_current_activity(schedule, current_time)
	
	if expected_activity:
		var action = expected_activity.get("action", "idle")
		var location = expected_activity.get("location", "")
		
		state_changed(npc_id, action)
		
		# 移动到目标位置
		if location != "":
			var target_pos = get_location_position(location)
			if target_pos:
				npc_states[npc_id].target_position = target_pos
		
		# 通知 AI 系统
		if AdvancedAIAgentManager:
			AdvancedAIAgentManager.update_agent_schedules(current_time)

func execute_autonomous_behavior(npc_id: String, context: Dictionary):
	"""执行自主行为"""
	var state = npc_states[npc_id]
	var personality = context.personality
	
	# 根据个性选择活动
	var activities = choose_activities(personality)
	
	if activities.size() > 0:
		var chosen = activities[randi() % activities.size()]
		state_changed(npc_id, chosen.action)
		
		# 可能移动到新位置
		if chosen.has("location"):
			var target_pos = get_location_position(chosen.location)
			if target_pos:
				state.target_position = target_pos

func execute_social_behavior(npc_id: String, context: Dictionary):
	"""执行社交行为"""
	var nearby = context.nearby_npcs
	
	if nearby.size() == 0:
		return
	
	# 选择一个 NPC 互动
	var target_npc = nearby[randi() % nearby.size()]
	
	# 发起 NPC 间互动
	if AdvancedAIAgentManager:
		AdvancedAIAgentManager.initiate_npc_interaction(
			npc_id,
			target_npc,
			"casual",
			context
		)
		
		spontaneous_interaction.emit(npc_id, target_npc, "casual")
		state_changed(npc_id, "chatting_with_%s" % target_npc)

func execute_idle_behavior(npc_id: String, context: Dictionary):
	"""执行空闲行为"""
	state_changed(npc_id, "resting")
	
	# 恢复能量
	npc_states[npc_id].energy = min(1.0, npc_states[npc_id].energy + 0.1)

func update_npc_state(npc_id: String):
	"""更新 NPC 状态"""
	var state = npc_states[npc_id]
	
	# 能量消耗
	if state.current_action != "resting":
		state.energy = max(0.0, state.energy - 0.01)
	
	# 社交需求增长
	state.social_need = min(1.0, state.social_need + 0.005)
	
	# 如果在社交，降低需求
	if state.current_action.begins_with("chatting"):
		state.social_need = max(0.0, state.social_need - 0.02)

func state_changed(npc_id: String, new_action: String):
	"""状态改变"""
	var old_action = npc_states[npc_id].current_action
	
	if old_action != new_action:
		npc_states[npc_id].current_action = new_action
		npc_started_action.emit(npc_id, new_action)

func move_towards_target(npc_id: String, target: Vector2):
	"""向目标移动"""
	# 这里需要实际的 NPC 节点引用
	# 简化实现 - 发出信号让主场景处理
	npc_moved_to.emit(npc_id, target)

func get_npc_location(npc_id: String) -> String:
	"""获取 NPC 当前位置名称"""
	# 简化实现
	return "town"

func get_nearby_npcs(npc_id: String, radius: float = 200.0) -> Array:
	"""获取附近的 NPC"""
	var nearby = []
	var my_pos = get_npc_position(npc_id)
	
	if not my_pos:
		return nearby
	
	for other_id in npc_states:
		if other_id == npc_id:
			continue
		
		var other_pos = get_npc_position(other_id)
		if other_pos and my_pos.distance_to(other_pos) <= radius:
			nearby.append(other_id)
	
	return nearby

func is_player_nearby(npc_id: String, radius: float = 100.0) -> bool:
	"""检查玩家是否在附近"""
	# 简化实现
	return false

func get_npc_position(npc_id: String) -> Vector2:
	"""获取 NPC 位置"""
	# 需要从实际场景中获取
	return Vector2.ZERO

func get_location_position(location_name: String) -> Vector2:
	"""获取位置坐标"""
	var locations = {
		"shop": Vector2(700, 400),
		"town_center": Vector2(500, 350),
		"forest_edge": Vector2(200, 300),
		"mountain_base": Vector2(400, 200),
		"home": Vector2(600, 450)
	}
	return locations.get(location_name, Vector2(500, 350))

func choose_activities(personality: Dictionary) -> Array:
	"""根据个性选择活动"""
	var traits = personality.get("traits", [])
	var interests = personality.get("interests", [])
	
	var activities = []
	
	# 根据兴趣添加活动
	if "adventure" in interests or "exploring" in interests:
		activities.append({"action": "exploring", "location": "mountain_base"})
	
	if "farming" in interests or "nature" in interests:
		activities.append({"action": "tending_garden", "location": "farm"})
	
	if "reading" in interests or "studying" in interests:
		activities.append({"action": "reading", "location": "home"})
	
	if "socializing" in interests or "community" in interests:
		activities.append({"action": "socializing", "location": "town_center"})
	
	# 默认活动
	if activities.is_empty():
		activities.append({"action": "wandering", "location": "town_center"})
	
	return activities

# ============================================
# 外部接口
# ============================================

func register_npc(npc_id: String, initial_state: Dictionary = {}):
	"""注册新的 NPC"""
	npc_states[npc_id] = {
		"id": npc_id,
		"mode": BehaviorMode.SCHEDULED,
		"current_action": "idle",
		"target_position": null,
		"last_decision_time": 0.0,
		"energy": 1.0,
		"social_need": 0.5,
		"happiness": 0.7,
		"inventory": []
	}
	
	npc_states[npc_id].merge(initial_state)
	if not npc_relationship_stage.has(npc_id):
		npc_relationship_stage[npc_id] = "neutral"

func unregister_npc(npc_id: String):
	"""注销 NPC"""
	npc_states.erase(npc_id)

func force_interaction(npc1_id: String, npc2_id: String, type: String = "casual"):
	"""强制两个 NPC 互动"""
	if AdvancedAIAgentManager:
		AdvancedAIAgentManager.initiate_npc_interaction(npc1_id, npc2_id, type)

func set_npc_mode(npc_id: String, mode: int):
	"""设置 NPC 行为模式"""
	if npc_states.has(npc_id):
		npc_states[npc_id].mode = mode

func get_npc_state(npc_id: String) -> Dictionary:
	"""获取 NPC 状态"""
	return npc_states.get(npc_id, {})

func get_all_npc_states() -> Dictionary:
	"""获取所有 NPC 状态"""
	return npc_states.duplicate(true)

func get_all_npc_ids() -> Array:
	"""Provide NPC id list for cross-system integrations."""
	return npc_states.keys()

func apply_relationship_update(npc_id: String, stage: String, delta: int = 0):
	"""Apply relationship stage from backend and trigger local feedback."""
	npc_relationship_stage[npc_id] = stage
	relationship_feedback.emit(npc_id, stage, delta)
	
	if NPCEmotionSystem:
		match stage:
			"close", "warming":
				NPCEmotionSystem.trigger_emotion(npc_id, "gift_received", {"relationship": 0.8})
			"tense", "conflict":
				NPCEmotionSystem.trigger_emotion(npc_id, "rude_behavior", {"relationship": -0.5})
