extends Node

# Quest System - Task and Daily Narrative Management
# Manages active quests, daily tasks, and quest rewards

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String, reward_gold: int)
signal quest_updated(quest_id: String, progress: int, target: int)
signal daily_quest_refreshed()

# Quest definitions
var quest_definitions = {
	# Main story quests
	"intro_farming": {
		"title": "农场入门",
		"description": "学习基本的种植流程。种植1个防风草并浇水。",
		"type": "tutorial",
		"objectives": [
			{"type": "plant_crop", "target": "parsnip", "count": 1},
			{"type": "water_crop", "count": 1}
		],
		"rewards": {
			"gold": 50,
			"items": [{"id": "potato_seeds", "quantity": 3}]
		},
		"repeatable": false
	},
	"first_harvest": {
		"title": "第一次收获",
		"description": "收获你种植的第一批作物。",
		"type": "tutorial",
		"objectives": [
			{"type": "harvest_crop", "count": 1}
		],
		"rewards": {
			"gold": 100,
			"items": [{"id": "cauliflower_seeds", "quantity": 2}]
		},
		"repeatable": false
	},

	# Daily quests
	"daily_watering": {
		"title": "勤劳的农夫",
		"description": "今天浇灌5块农田。",
		"type": "daily",
		"objectives": [
			{"type": "water_crop", "count": 5}
		],
		"rewards": {
			"gold": 80
		},
		"repeatable": true,
		"refresh_daily": true
	},
	"daily_harvest": {
		"title": "丰收日",
		"description": "今天收获3个作物。",
		"type": "daily",
		"objectives": [
			{"type": "harvest_crop", "count": 3}
		],
		"rewards": {
			"gold": 120
		},
		"repeatable": true,
		"refresh_daily": true
	},
	"daily_social": {
		"title": "社交时间",
		"description": "与3个不同的NPC对话。",
		"type": "daily",
		"objectives": [
			{"type": "talk_to_npc", "count": 3}
		],
		"rewards": {
			"gold": 60
		},
		"repeatable": true,
		"refresh_daily": true
	},

	# NPC quests
	"pierre_supply": {
		"title": "皮埃尔的补给",
		"description": "为杂货店提供5个防风草。",
		"type": "npc",
		"giver": "pierre",
		"objectives": [
			{"type": "deliver_item", "item": "parsnip", "count": 5}
		],
		"rewards": {
			"gold": 200,
			"items": [{"id": "corn_seeds", "quantity": 2}]
		},
		"repeatable": true
	},
	"abigail_adventure": {
		"title": "阿比盖尔的冒险",
		"description": "听阿比盖尔讲述她的冒险故事。",
		"type": "npc",
		"giver": "abigail",
		"objectives": [
			{"type": "talk_to_npc", "npc": "abigail", "count": 5}
		],
		"rewards": {
			"gold": 100
		},
		"repeatable": false
	}
}

# Active quests: { quest_id: { "progress": { objective_index: current_progress }, "completed_objectives": [] } }
var active_quests = {}
var completed_quests = []
var available_daily_quests = []

var current_day = 1
var inventory_system = null
var farming_system = null

func _ready():
	print("Quest system initialized")
	find_systems()
	generate_daily_quests()

func find_systems():
	"""Find required systems"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		if main.has_node("TownSquare/InventorySystem"):
			inventory_system = main.get_node("TownSquare/InventorySystem")
		if main.has_node("TownSquare/FarmingSystem"):
			farming_system = main.get_node("TownSquare/FarmingSystem")

func accept_quest(quest_id: String) -> bool:
	"""Accept a new quest"""
	if not quest_definitions.has(quest_id):
		print("Unknown quest: ", quest_id)
		return false

	if quest_id in completed_quests and not quest_definitions[quest_id]["repeatable"]:
		print("Quest already completed: ", quest_id)
		return false

	if quest_id in active_quests:
		print("Quest already active: ", quest_id)
		return false

	# Initialize quest progress
	active_quests[quest_id] = {
		"progress": {},
		"completed_objectives": []
	}

	# Initialize progress for each objective
	var quest_data = quest_definitions[quest_id]
	for i in range(quest_data["objectives"].size()):
		active_quests[quest_id]["progress"][i] = 0

	emit_signal("quest_accepted", quest_id)
	print("Accepted quest: ", quest_definitions[quest_id]["title"])
	return true

func update_quest_progress(quest_id: String, objective_type: String, amount: int = 1, extra_data: Dictionary = {}):
	"""Update progress for a specific quest objective"""
	if not active_quests.has(quest_id):
		return

	var quest_data = quest_definitions[quest_id]
	var objectives = quest_data["objectives"]

	for i in range(objectives.size()):
		var objective = objectives[i]

		if objective["type"] != objective_type:
			continue

		# Check additional conditions
		if objective.has("target") and extra_data.has("target"):
			if objective["target"] != extra_data["target"]:
				continue

		if objective.has("npc") and extra_data.has("npc"):
			if objective["npc"] != extra_data["npc"]:
				continue

		# Update progress
		if i in active_quests[quest_id]["completed_objectives"]:
			continue

		active_quests[quest_id]["progress"][i] += amount

		var target_count = objective.get("count", 1)
		var current_progress = active_quests[quest_id]["progress"][i]

		emit_signal("quest_updated", quest_id, current_progress, target_count)

		# Check if objective completed
		if current_progress >= target_count:
			active_quests[quest_id]["completed_objectives"].append(i)
			print("Objective completed: ", objective_type)

	# Check if all objectives completed
	check_quest_completion(quest_id)

func check_quest_completion(quest_id: String):
	"""Check if quest is fully completed"""
	if not active_quests.has(quest_id):
		return

	var quest_data = quest_definitions[quest_id]
	var total_objectives = quest_data["objectives"].size()
	var completed_count = active_quests[quest_id]["completed_objectives"].size()

	if completed_count >= total_objectives:
		complete_quest(quest_id)

func complete_quest(quest_id: String):
	"""Complete a quest and give rewards"""
	if not active_quests.has(quest_id):
		return

	var quest_data = quest_definitions[quest_id]
	var rewards = quest_data["rewards"]

	# Give gold reward
	if rewards.has("gold") and inventory_system:
		inventory_system.update_gold(rewards["gold"])
		print("Quest reward: ", rewards["gold"], "g")

	# Give item rewards
	if rewards.has("items") and inventory_system:
		for item_reward in rewards["items"]:
			inventory_system.add_item(item_reward["id"], item_reward["quantity"])
			print("Quest reward: ", item_reward["quantity"], "x ", item_reward["id"])

	# Mark as completed
	if not quest_data["repeatable"]:
		completed_quests.append(quest_id)

	active_quests.erase(quest_id)

	emit_signal("quest_completed", quest_id, rewards.get("gold", 0))
	print("Quest completed: ", quest_data["title"])

func generate_daily_quests():
	"""Generate available daily quests"""
	available_daily_quests.clear()

	# Select random daily quests
	var daily_pool = []
	for quest_id in quest_definitions.keys():
		if quest_definitions[quest_id].get("refresh_daily", false):
			daily_pool.append(quest_id)

	# Pick 2-3 random daily quests
	var num_dailies = min(3, daily_pool.size())
	for i in range(num_dailies):
		if daily_pool.is_empty():
			break
		var idx = randi() % daily_pool.size()
		available_daily_quests.append(daily_pool[idx])
		daily_pool.remove_at(idx)

	emit_signal("daily_quest_refreshed")
	print("Daily quests refreshed: ", available_daily_quests.size())

func advance_day():
	"""Called when a new day starts"""
	current_day += 1
	generate_daily_quests()
	print("Day advanced to ", current_day)

func get_active_quests_info() -> Array:
	"""Get information about all active quests"""
	var info = []

	for quest_id in active_quests.keys():
		var quest_data = quest_definitions[quest_id]
		var quest_progress = active_quests[quest_id]

		var objectives_info = []
		for i in range(quest_data["objectives"].size()):
			var objective = quest_data["objectives"][i]
			var progress = quest_progress["progress"].get(i, 0)
			var target = objective.get("count", 1)
			var completed = i in quest_progress["completed_objectives"]

			objectives_info.append({
				"description": format_objective_description(objective),
				"progress": progress,
				"target": target,
				"completed": completed
			})

		info.append({
			"id": quest_id,
			"title": quest_data["title"],
			"description": quest_data["description"],
			"type": quest_data["type"],
			"objectives": objectives_info
		})

	return info

func format_objective_description(objective: Dictionary) -> String:
	"""Format objective into human-readable description"""
	match objective["type"]:
		"plant_crop":
			return "种植 %d 个%s" % [objective.get("count", 1), get_crop_name(objective.get("target", ""))]
		"water_crop":
			return "浇灌 %d 块农田" % objective.get("count", 1)
		"harvest_crop":
			return "收获 %d 个作物" % objective.get("count", 1)
		"talk_to_npc":
			return "与 %d 个NPC对话" % objective.get("count", 1)
		"deliver_item":
			return "交付 %d 个%s" % [objective.get("count", 1), get_item_name(objective.get("item", ""))]
		_:
			return "未知目标"

func get_crop_name(crop_id: String) -> String:
	"""Get crop display name"""
	if farming_system and farming_system.crop_types.has(crop_id):
		return farming_system.crop_types[crop_id]["name"]
	return crop_id

func get_item_name(item_id: String) -> String:
	"""Get item display name"""
	if inventory_system and inventory_system.item_definitions.has(item_id):
		return inventory_system.item_definitions[item_id]["name"]
	return item_id

func print_quest_log():
	"""Debug: Print current quest log"""
	print("\n=== QUEST LOG ===")
	print("Day: ", current_day)

	print("\nActive Quests:")
	var active_info = get_active_quests_info()
	for quest in active_info:
		print("  ", quest["title"])
		for obj in quest["objectives"]:
			var status = "[DONE]" if obj["completed"] else "[%d/%d]" % [obj["progress"], obj["target"]]
			print("    ", status, " ", obj["description"])

	print("\nCompleted Quests:")
	for quest_id in completed_quests:
		print("  ", quest_definitions[quest_id]["title"])

	print("=================\n")
