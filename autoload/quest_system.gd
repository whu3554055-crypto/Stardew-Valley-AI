extends Node

class_name QuestSystem

enum QuestStatus {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED,
	TURNED_IN
}

var quests = {}
var active_quests = []
var completed_quests = []
var last_story_quest_day_key = ""

signal quest_started(quest_id)
signal quest_updated(quest_id, objective)
signal quest_completed(quest_id)

func _ready():
	initialize_quests()

func initialize_quests():
	# Tutorial quest
	quests["tutorial_plant"] = {
		"id": "tutorial_plant",
		"title": "Your First Crop",
		"description": "Plant a parsnip seed and water it.",
		"objectives": [
			{"type": "plant", "crop_id": "parsnip", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 50, "items": ["parsnip_seeds:5"]}
	}

	quests["tutorial_harvest"] = {
		"id": "tutorial_harvest",
		"title": "First Harvest",
		"description": "Harvest your first crop.",
		"objectives": [
			{"type": "harvest", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 100, "items": []}
	}

	quests["earn_gold"] = {
		"id": "earn_gold",
		"title": "Entrepreneur",
		"description": "Earn 1000 gold by selling items at the shop.",
		"objectives": [
			{"type": "earn_gold", "count": 1000, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 200, "items": []}
	}

	quests["intro_fish"] = {
		"id": "intro_fish",
		"title": "First Catch",
		"description": "Catch real fish (not junk) 3 times — river east, ocean south.",
		"objectives": [
			{"type": "fish_caught", "count": 3, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["worm_bait:5"]}
	}

	quests["intro_mine"] = {
		"id": "intro_mine",
		"title": "Into the Stone",
		"description": "Mine ore 5 times.",
		"objectives": [
			{"type": "mine_ore", "count": 5, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 60, "items": ["coal:3"]}
	}

	quests["intro_smelt"] = {
		"id": "intro_smelt",
		"title": "Hot Metal",
		"description": "Smelt any bar at the furnace once.",
		"objectives": [
			{"type": "smelt_bar", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["coal:2"]}
	}

	quests["intro_eat"] = {
		"id": "intro_eat",
		"title": "A Bite to Eat",
		"description": "Eat something to recover energy (select food, press E).",
		"objectives": [
			{"type": "consume_food", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 25, "items": ["bread:2"]}
	}

	quests["intro_cook"] = {
		"id": "intro_cook",
		"title": "Home Cooking",
		"description": "Cook a meal at the kitchen counter (empty hands, E).",
		"objectives": [
			{"type": "cook_meal", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 35, "items": ["bread:1"]}
	}

	quests["intro_chop"] = {
		"id": "intro_chop",
		"title": "Lumberjack",
		"description": "Chop wood in the forest (west) with the axe equipped.",
		"objectives": [
			{"type": "chop_wood", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 30, "items": ["coal:2"]}
	}

	quests["intro_craft"] = {
		"id": "intro_craft",
		"title": "Workbench",
		"description": "Craft something at the workbench (east of kitchen, empty hands, E).",
		"objectives": [
			{"type": "craft_item", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["wood_log:3"]}
	}

func _objective_goal_max(o: Dictionary) -> int:
	if o.has("count"):
		return int(o["count"])
	if o.has("amount"):
		return int(o["amount"])
	return 1

func start_quest(quest_id: String):
	if not quests.has(quest_id):
		return

	var quest = quests[quest_id]
	if quest.status == QuestStatus.NOT_STARTED:
		quest.status = QuestStatus.IN_PROGRESS
		active_quests.append(quest_id)
		quest_started.emit(quest_id)

func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1):
	if not quests.has(quest_id):
		return

	var quest = quests[quest_id]
	if quest.status != QuestStatus.IN_PROGRESS:
		return

	var objective = quest.objectives[objective_index]
	var goal: int = _objective_goal_max(objective)
	objective.current += amount
	if objective.current >= goal:
		objective.current = goal
		check_quest_completion(quest_id)

	quest_updated.emit(quest_id, objective_index)

func check_quest_completion(quest_id: String):
	var quest = quests[quest_id]

	for objective in quest.objectives:
		if int(objective.get("current", 0)) < _objective_goal_max(objective):
			return

	# All objectives complete
	quest.status = QuestStatus.COMPLETED
	complete_quest(quest_id)

func complete_quest(quest_id: String):
	var quest = quests[quest_id]
	quest.status = QuestStatus.COMPLETED

	# Give rewards
	if quest.reward.has("gold"):
		GameManager.player_data.gold += quest.reward.gold

	if quest.reward.has("items"):
		for item_str in quest.reward.items:
			var parts = item_str.split(":")
			var item_id = parts[0]
			var count = int(parts[1]) if parts.size() > 1 else 1
			var item_template = ItemDatabase.get_item(item_id)
			for i in range(count):
				InventoryManager.add_item(item_template.duplicate(true))

	# Move from active to completed
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	if AIEconomySystem:
		AIEconomySystem.on_quest_completed(quest)
	quest_completed.emit(quest_id)

func turn_in_quest(quest_id: String):
	if not quests.has(quest_id):
		return

	var quest = quests[quest_id]
	if quest.status == QuestStatus.COMPLETED:
		quest.status = QuestStatus.TURNED_IN
		return true
	return false

func get_active_quests() -> Array:
	var result = []
	for quest_id in active_quests:
		result.append(quests[quest_id])
	return result

func get_completed_quests() -> Array:
	var result = []
	for quest_id in completed_quests:
		result.append(quests[quest_id])
	return result

func track_event(event_type: String, data: Dictionary):
	for quest_id in active_quests:
		var quest = quests[quest_id]
		for i in range(quest.objectives.size()):
			var objective = quest.objectives[i]
			if str(objective.get("type", "")) != event_type:
				continue
			if not _objective_matches_event(objective, data):
				continue
			if event_type == "earn_gold":
				var g: int = int(data.get("gold", 0))
				if g <= 0:
					continue
				var goal: int = _objective_goal_max(objective)
				objective.current = mini(goal, int(objective.get("current", 0)) + g)
				check_quest_completion(quest_id)
				quest_updated.emit(quest_id, i)
			else:
				update_quest_progress(quest_id, i, int(data.get("count", 1)))

func _objective_matches_event(objective: Dictionary, data: Dictionary) -> bool:
	"""Generic matcher for objective/event payload compatibility."""
	var ot: String = str(objective.get("type", ""))
	if ot == "fish_caught":
		if objective.has("fish_id"):
			return str(data.get("fish_id", "")) == str(objective.get("fish_id", ""))
		return true
	if ot == "mine_ore":
		if objective.has("ore_id"):
			return str(data.get("ore_id", "")) == str(objective.get("ore_id", ""))
		return true
	if ot == "smelt_bar":
		if objective.has("bar_id"):
			return str(data.get("bar_id", "")) == str(objective.get("bar_id", ""))
		return true
	if ot == "consume_food":
		if objective.has("item_id"):
			return str(data.get("item_id", "")) == str(objective.get("item_id", ""))
		return true
	if ot == "cook_meal":
		if objective.has("dish_id"):
			return str(data.get("dish_id", "")) == str(objective.get("dish_id", ""))
		return true
	if ot == "chop_wood":
		return true
	if ot == "craft_item":
		if objective.has("item_id"):
			return str(data.get("item_id", "")) == str(objective.get("item_id", ""))
		return true
	if ot == "earn_gold":
		return true
	if objective.has("crop_id"):
		return data.get("crop_id") == objective.get("crop_id")
	if objective.has("npc_id"):
		return data.get("npc_id") == objective.get("npc_id")
	return true

func add_story_daily_quest(event_data: Dictionary):
	"""
	Create one lightweight daily quest from narrative event.
	Playable-first: simple talk objective with clear reward.
	"""
	var day_key = "%d-%s-%d" % [GameManager.player_data.year, GameManager.player_data.season, GameManager.player_data.day]
	if day_key == last_story_quest_day_key:
		return
	
	var npc_id = str(event_data.get("npc_id", "pierre"))
	var title = str(event_data.get("title", "Daily Story Task"))
	var quest_id = "story_daily_%s" % day_key
	
	quests[quest_id] = {
		"id": quest_id,
		"title": title,
		"description": "Talk to %s to follow today's story." % npc_id.capitalize(),
		"story_npc_id": npc_id,
		"narrative_id": str(event_data.get("narrative_id", "")),
		"narrative_day_key": str(event_data.get("narrative_day_key", day_key)),
		"narrative_source": str(event_data.get("narrative_source", "local")),
		"source": "daily_narrative",
		"objectives": [
			{"type": "talk", "npc_id": npc_id, "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 80, "items": []}
	}
	start_quest(quest_id)
	last_story_quest_day_key = day_key

func add_quest_from_ai(ai_quest: Dictionary) -> void:
	"""
	Bridge AIQuestSystem quest into QuestSystem tracking so UI/events stay unified.
	This keeps QuestSystem read-model consistent without owning AI reward settlement.
	"""
	var quest_id: String = str(ai_quest.get("id", ""))
	if quest_id.is_empty():
		return
	if quests.has(quest_id):
		return
	var reward_gold: int = int(ai_quest.get("rewards", {}).get("gold", 0))
	var target_count: int = int(ai_quest.get("target_count", 1))
	var qtype: String = str(ai_quest.get("type", "fetch"))
	var objective_type: String = "collect_item" if qtype == "fetch" else "delivery"
	var objective: Dictionary = {
		"type": objective_type,
		"item_id": str(ai_quest.get("target_item", "")),
		"count": maxi(1, target_count),
		"current": 0
	}
	quests[quest_id] = {
		"id": quest_id,
		"title": str(ai_quest.get("name", "AI Quest")),
		"description": str(ai_quest.get("description", "")),
		"objectives": [objective],
		"status": QuestStatus.IN_PROGRESS,
		"reward": {"gold": reward_gold, "items": []},
		"source": "ai_quest_system",
	}
	if not active_quests.has(quest_id):
		active_quests.append(quest_id)
	quest_started.emit(quest_id)


func save_snapshot() -> Dictionary:
	var qd: Dictionary = {}
	for qid in quests.keys():
		qd[qid] = _serialize_quest_entry(quests[qid])
	return {
		"quests": qd,
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"last_story_quest_day_key": last_story_quest_day_key
	}


func _serialize_quest_entry(q: Dictionary) -> Dictionary:
	var out: Dictionary = q.duplicate(true)
	out["status"] = int(q.get("status", QuestStatus.NOT_STARTED))
	return out


func load_snapshot(data: Variant) -> void:
	if not data is Dictionary:
		return
	var d: Dictionary = data
	if d.has("last_story_quest_day_key"):
		last_story_quest_day_key = str(d["last_story_quest_day_key"])
	if d.get("active_quests") is Array:
		active_quests = d["active_quests"].duplicate()
	if d.get("completed_quests") is Array:
		completed_quests = d["completed_quests"].duplicate()
	if d.get("quests") is Dictionary:
		var qsave: Dictionary = d["quests"]
		for qid in qsave.keys():
			var saved: Dictionary = qsave[qid].duplicate(true)
			if saved.has("status"):
				saved["status"] = int(saved["status"])
			quests[qid] = saved
	for qid in completed_quests:
		if active_quests.has(qid):
			active_quests.erase(qid)
