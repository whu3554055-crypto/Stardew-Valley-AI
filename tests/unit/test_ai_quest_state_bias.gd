extends GutTest

## P2-3 regression: AI quest state bias + quality guardrail helpers.

var _aiq: AIQuestSystem = null


func before_each() -> void:
	_aiq = preload("res://autoload/ai_quest_system.gd").new()
	add_child(_aiq)
	_aiq.set_process(false)


func after_each() -> void:
	if is_instance_valid(_aiq):
		_aiq.queue_free()
	_aiq = null


func test_quality_score_accepts_rich_payload() -> void:
	var score: float = _aiq._score_ai_quest_payload({
		"title": "Storm Relief Logistics",
		"description": "The storm damaged supply routes. Help us route emergency goods before sunset.",
		"objective": "Deliver 3 bread and talk to Pierre in town square.",
		"motivation": "Families are waiting and this keeps morale stable."
	})
	assert_gt(score, 0.75, "rich AI payload should pass quality threshold")


func test_world_state_bias_prefers_relationship_after_talk_events() -> void:
	_aiq._recent_events = [
		{"type": "talk", "data": {"npc_id": "pierre"}},
		{"type": "talk", "data": {"npc_id": "abigail"}}
	]
	var bias: Dictionary = _aiq._derive_world_state_bias()
	assert_gt(float(bias.get("relationship_build", 0.0)), float(bias.get("fetch_item", 0.0)))
