extends GutTest

var ai_quest_system: AIQuestSystem = null

func before_each() -> void:
	ai_quest_system = preload("res://autoload/ai_quest_system.gd").new()

func after_each() -> void:
	if ai_quest_system:
		ai_quest_system.queue_free()
	ai_quest_system = null

func test_normalize_payload_clips_and_maps_delivery_objective_type() -> void:
	var payload := {
		"title": "A".repeat(120),
		"description": "B".repeat(300),
		"objective": "Please deliver this parcel to Pierre today.",
		"motivation": "C".repeat(200),
		"target_item": "potato",
		"target_count": 0
	}

	var normalized: Dictionary = ai_quest_system._normalize_ai_quest_payload(payload)

	assert_eq(String(normalized.get("title", "")).length(), 72, "title should be clipped to 72 chars")
	assert_eq(String(normalized.get("description", "")).length(), 240, "description should be clipped to 240 chars")
	assert_eq(String(normalized.get("motivation", "")).length(), 140, "motivation should be clipped to 140 chars")
	assert_eq(int(normalized.get("target_count", 0)), 1, "target_count should be at least 1")
	assert_eq(String(normalized.get("objective_type", "")), AIQuestSystem.OBJECTIVE_DELIVERY, "objective text should map to delivery")

func test_parse_ai_quest_json_handles_markdown_fence_and_objective_mapping() -> void:
	var raw_json := """```json
{
  "title": "Parcel Rush",
  "description": "Need this delivered before sunset.",
  "objective": "Talk to Mayor Lewis about the shipment.",
  "motivation": "Town logistics are blocked.",
  "target_item": "letter",
  "target_count": 2
}
```"""

	var parsed: Dictionary = ai_quest_system._parse_ai_quest_json(raw_json)

	assert_false(parsed.is_empty(), "fenced JSON should be parsed")
	assert_eq(String(parsed.get("title", "")), "Parcel Rush")
	assert_eq(String(parsed.get("objective_type", "")), AIQuestSystem.OBJECTIVE_TALK, "objective text should map to talk objective")
	assert_eq(int(parsed.get("target_count", 0)), 2)

func test_apply_objective_type_maps_to_runtime_verifiable_type() -> void:
	var quest := {
		"type": "fetch",
		"objective_type": AIQuestSystem.OBJECTIVE_TALK,
		"target_npc": "pierre"
	}
	ai_quest_system._apply_objective_type_to_quest(quest)
	assert_eq(String(quest.get("type", "")), "talk", "talk objective should map quest.type to talk")

func test_completion_hint_for_talk_quest_not_empty() -> void:
	var quest := {
		"type": "talk",
		"description": "Please check in with Pierre.",
		"target_npc": "pierre"
	}
	var text: String = ai_quest_system._append_completion_hint(quest)
	assert_true(text.find("Completion:") >= 0, "talk quest should include explicit completion hint")
