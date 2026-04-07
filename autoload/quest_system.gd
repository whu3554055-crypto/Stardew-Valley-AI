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
		"description": "Earn 1000 gold from selling crops.",
		"objectives": [
			{"type": "earn_gold", "amount": 1000, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 200, "items": []}
	}

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
	objective.current += amount

	if objective.current >= objective.count:
		objective.current = objective.count
		check_quest_completion(quest_id)

	quest_updated.emit(quest_id, objective_index)

func check_quest_completion(quest_id: String):
	var quest = quests[quest_id]

	for objective in quest.objectives:
		if objective.current < objective.count:
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
	# Check all active quests for progress
	for quest_id in active_quests:
		var quest = quests[quest_id]
		for i in range(quest.objectives.size()):
			var objective = quest.objectives[i]
			if objective.type == event_type:
				if data.get("crop_id") == objective.get("crop_id") or objective.get("crop_id") == null:
					update_quest_progress(quest_id, i, data.get("count", 1))

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
		"objectives": [
			{"type": "talk", "npc_id": npc_id, "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 80, "items": []}
	}
	start_quest(quest_id)
	last_story_quest_day_key = day_key
