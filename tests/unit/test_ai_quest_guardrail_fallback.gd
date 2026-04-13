extends GutTest

## W5-AC: AI failure/degrade must not block gameplay loop.

var _ai: AIQuestSystem
var _received_quest: Dictionary = {}
var _received_npc: String = ""


func before_each() -> void:
	_ai = preload("res://autoload/ai_quest_system.gd").new()
	add_child(_ai)
	_ai.set_process(false)
	_received_quest = {}
	_received_npc = ""
	_ai.ai_quest_request_completed.connect(_on_ai_quest_request_completed)


func after_each() -> void:
	if is_instance_valid(_ai):
		_ai.queue_free()
	_ai = null


func test_breaker_open_degrades_to_procedural_without_blocking() -> void:
	_ai._ai_guardrail_state["breaker_until"] = float(Time.get_unix_time_from_system()) + 120.0
	var opportunity := {
		"npc": "pierre",
		"quest_template": "fetch_item",
		"type": "daily_need"
	}

	_ai.generate_ai_enhanced_quest(opportunity)

	assert_eq(_received_npc, "pierre", "fallback completion should still emit npc id")
	assert_false(_received_quest.is_empty(), "fallback completion should return a playable quest")
	assert_eq(str(_received_quest.get("ai_degraded_to", "")), "procedural_breaker", "degrade mode should be marked")


func _on_ai_quest_request_completed(npc_id: String, quest_data: Dictionary) -> void:
	_received_npc = npc_id
	_received_quest = quest_data.duplicate(true)
