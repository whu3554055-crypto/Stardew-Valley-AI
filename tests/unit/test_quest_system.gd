extends GutTest

var quest_system: QuestSystem = null

func before_each() -> void:
	quest_system = preload("res://autoload/quest_system.gd").new()
	quest_system.initialize_quests()

func after_each() -> void:
	if quest_system:
		quest_system.queue_free()
	quest_system = null

func test_daily_narrative_quest_dedupes_by_narrative_day_key() -> void:
	var event_day_1 := {
		"npc_id": "pierre",
		"title": "Story Task A",
		"narrative_id": "n1",
		"narrative_day_key": "story_day_2026_04_09"
	}
	var event_day_1_refresh := {
		"npc_id": "abigail",
		"title": "Story Task B",
		"narrative_id": "n2",
		"narrative_day_key": "story_day_2026_04_09"
	}

	quest_system.add_story_daily_quest(event_day_1)
	var first_ids := _get_daily_narrative_quest_ids()
	assert_eq(first_ids.size(), 1, "first insert should create one daily narrative quest")
	var stable_quest_id := String(first_ids[0])

	quest_system.add_story_daily_quest(event_day_1_refresh)
	var second_ids := _get_daily_narrative_quest_ids()
	assert_eq(second_ids.size(), 1, "same narrative_day_key should refresh existing quest, not duplicate")
	assert_eq(String(second_ids[0]), stable_quest_id, "quest id should remain stable on refresh")

	var refreshed: Dictionary = quest_system.quests[stable_quest_id]
	assert_eq(String(refreshed.get("story_npc_id", "")), "abigail", "refresh should overwrite payload details")
	assert_true(quest_system.active_quests.has(stable_quest_id), "daily narrative quest should remain active")

func _get_daily_narrative_quest_ids() -> Array:
	var ids: Array = []
	for qid in quest_system.quests.keys():
		var q: Dictionary = quest_system.quests[qid]
		if String(q.get("source", "")) == "daily_narrative":
			ids.append(qid)
	return ids
