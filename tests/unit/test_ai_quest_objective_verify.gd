extends GutTest

## Regression tests for AIQuestSystem.verify_active_objectives (fetch / delivery / talk).

var _inv_snap: Dictionary = {}
var _aiq: AIQuestSystem = null


func before_each() -> void:
	assert_true(InventoryManager != null, "test needs InventoryManager autoload")
	_inv_snap = InventoryManager.save_snapshot()
	InventoryManager.clear_inventory()
	_aiq = preload("res://autoload/ai_quest_system.gd").new()
	add_child(_aiq)
	_aiq.set_process(false)


func after_each() -> void:
	if is_instance_valid(_aiq):
		_aiq.queue_free()
		_aiq = null
	InventoryManager.load_snapshot(_inv_snap)


func test_verify_fetch_completes_when_backpack_has_enough() -> void:
	var tpl: Dictionary = ItemDatabase.get_item("potato")
	assert_false(tpl.is_empty(), "potato item should exist in ItemDatabase")
	InventoryManager.add_item(tpl.duplicate(true))
	InventoryManager.add_item(tpl.duplicate(true))
	var q := {
		"id": "ut_ai_fetch_1",
		"name": "UT Fetch",
		"type": "fetch",
		"target_item": "potato",
		"target_count": 2,
		"rewards": {},
		"status": "active",
	}
	_aiq.active_quests[q["id"]] = q
	_aiq.verify_active_objectives()
	assert_false(_aiq.active_quests.has(q["id"]), "fetch quest should leave active when completed")
	assert_true(_aiq.completed_quests.has(q["id"]), "fetch quest should land in completed")


func test_verify_talk_completes_after_talk_event() -> void:
	var q := {
		"id": "ut_ai_talk_1",
		"name": "UT Talk",
		"type": "talk",
		"target_npc": "abigail",
		"rewards": {},
		"status": "active",
	}
	_aiq.active_quests[q["id"]] = q
	_aiq.track_event("talk", {"npc_id": "abigail"})
	_aiq.verify_active_objectives()
	assert_true(_aiq.completed_quests.has(q["id"]), "talk quest should complete after matching talk event")


func test_verify_delivery_requires_target_talk_then_consumes_item() -> void:
	var tpl: Dictionary = ItemDatabase.get_item("bread")
	assert_false(tpl.is_empty(), "bread item should exist")
	InventoryManager.add_item(tpl.duplicate(true))
	var q := {
		"id": "ut_ai_delivery_1",
		"name": "UT Delivery",
		"type": "delivery",
		"target_item": "bread",
		"target_count": 1,
		"target_npc": "pierre",
		"rewards": {},
		"status": "active",
	}
	_aiq.active_quests[q["id"]] = q
	_aiq.verify_active_objectives()
	assert_true(_aiq.active_quests.has(q["id"]), "delivery with npc should wait for talk")
	_aiq.track_event("talk", {"npc_id": "pierre"})
	_aiq.verify_active_objectives()
	assert_true(_aiq.completed_quests.has(q["id"]), "delivery completes after talk + consume")
	assert_eq(InventoryManager.count_item("bread"), 0, "item should be consumed on complete")
