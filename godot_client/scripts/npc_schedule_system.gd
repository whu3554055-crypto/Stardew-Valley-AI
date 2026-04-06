extends Node

# NPC日程系统
# 管理所有NPC的每日行程安排

var npc_schedules = {
	"pierre": {
		"name": "Pierre",
		"schedule": {
			6.0: {"location": "home", "position": Vector2(900, 100), "activity": "wake_up"},
			8.0: {"location": "general_store", "position": Vector2(500, 200), "activity": "open_shop"},
			12.0: {"location": "town_square", "position": Vector2(400, 300), "activity": "lunch_break"},
			17.0: {"location": "general_store", "position": Vector2(500, 200), "activity": "work"},
			20.0: {"location": "home", "position": Vector2(900, 100), "activity": "rest"},
			22.0: {"location": "home", "position": Vector2(900, 100), "activity": "sleep"}
		}
	},
	"abigail": {
		"name": "Abigail",
		"schedule": {
			7.0: {"location": "home", "position": Vector2(850, 150), "activity": "wake_up"},
			9.0: {"location": "cemetery", "position": Vector2(200, 500), "activity": "explore"},
			13.0: {"location": "town_square", "position": Vector2(350, 350), "activity": "socialize"},
			16.0: {"location": "forest", "position": Vector2(100, 600), "activity": "adventure"},
			19.0: {"location": "saloon", "position": Vector2(700, 400), "activity": "relax"},
			22.0: {"location": "home", "position": Vector2(850, 150), "activity": "sleep"}
		}
	},
	"lewis": {
		"name": "Lewis镇长",
		"schedule": {
			7.0: {"location": "home", "position": Vector2(950, 120), "activity": "wake_up"},
			9.0: {"location": "town_hall", "position": Vector2(600, 150), "activity": "work"},
			12.0: {"location": "town_square", "position": Vector2(450, 280), "activity": "inspect_town"},
			15.0: {"location": "town_hall", "position": Vector2(600, 150), "activity": "meetings"},
			18.0: {"location": "saloon", "position": Vector2(700, 400), "activity": "relax"},
			21.0: {"location": "home", "position": Vector2(950, 120), "activity": "sleep"}
		}
	}
}

var current_time = 8.0
var npcs_dict = {}

func _ready():
	print("NPC日程系统初始化")

func register_npc(npc_id: String, npc_node):
	"""注册NPC到调度系统"""
	npcs_dict[npc_id] = npc_node
	print("注册NPC: ", npc_id)

func update_time(new_time: float):
	"""更新时间并检查是否需要切换NPC活动"""
	current_time = new_time

	for npc_id in npc_schedules.keys():
		if npcs_dict.has(npc_id):
			check_and_update_npc_activity(npc_id)

func check_and_update_npc_activity(npc_id: String):
	"""检查并更新NPC当前活动"""
	var schedule = npc_schedules[npc_id]["schedule"]
	var npc_node = npcs_dict[npc_id]

	# 找到当前时间应该执行的活动
	var current_activity = null
	var next_activity_time = 24.0

	for time_key in schedule.keys():
		if current_time >= time_key:
			if not current_activity or time_key > current_activity["time"]:
				current_activity = schedule[time_key]
				current_activity["time"] = time_key

	if current_activity:
		# 检查NPC是否已经在正确位置
		var target_pos = current_activity["position"]
		var distance = npc_node.global_position.distance_to(target_pos)

		if distance > 50:
			# 移动到目标位置
			move_npc_to(npc_node, target_pos, current_activity["activity"])

func move_npc_to(npc_node, target_position: Vector2, activity: String):
	"""移动NPC到指定位置"""
	print(npc_node.npc_name, " 前往: ", activity, " at ", target_position)

	# 使用Tween平滑移动
	var tween = npc_node.create_tween()
	tween.tween_property(npc_node, "position", target_position, 8.0)  # 8秒移动时间
	tween.tween_callback(func():
		npc_node.current_activity = activity
		print(npc_node.npc_name, " 到达，开始: ", activity)
	)

	# 更新NPC活动状态
	npc_node.current_activity = "moving_to_" + activity

func get_npc_current_activity(npc_id: String) -> String:
	"""获取NPC当前活动"""
	if npcs_dict.has(npc_id):
		return npcs_dict[npc_id].current_activity
	return "unknown"

func get_npcs_at_location(location: String) -> Array:
	"""获取指定位置的所有NPC"""
	var result = []
	var current_schedule = null

	for npc_id in npc_schedules.keys():
		var schedule = npc_schedules[npc_id]["schedule"]
		for time_key in schedule.keys():
			if current_time >= time_key:
				if schedule[time_key]["location"] == location:
					result.append(npc_id)
					break

	return result

func debug_print_all_schedules():
	"""调试：打印所有NPC当前状态"""
	print("\n=== NPC日程状态 ===")
	for npc_id in npc_schedules.keys():
		if npcs_dict.has(npc_id):
			var npc = npcs_dict[npc_id]
			print(npc_schedules[npc_id]["name"], ": ", npc.current_activity, " at ", npc.position)
	print("==================\n")
