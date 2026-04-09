extends GutTest

var quest_system: QuestSystem = null

func before_each() -> void:
	quest_system = preload("res://autoload/quest_system.gd").new()
	quest_system._load_managed_chain_config()
	quest_system._load_chain_templates()
	quest_system.initialize_quests()

func after_each() -> void:
	if quest_system:
		quest_system.queue_free()
	quest_system = null

func test_activate_chain_for_narrative_prefers_mining_theme() -> void:
	quest_system.activate_chain_for_narrative({"theme": "adventure"})
	assert_true(quest_system.active_quests.has("managed_mining_chain_1"), "adventure theme should activate mining chain first step")

func test_on_day_passed_marks_urgent_when_reaches_deadline() -> void:
	quest_system.start_quest("managed_supply_chain_1")
	var q: Dictionary = quest_system.quests.get("managed_supply_chain_1", {})
	assert_false(q.is_empty())
	var today: int = quest_system._current_day_index()
	q["deadline_day_index"] = today
	q["managed_state"] = "active"
	quest_system.on_day_passed()
	assert_eq(String(q.get("managed_state", "")), "urgent", "quest should become urgent on deadline day")

func test_on_day_passed_fails_when_deadline_passed() -> void:
	quest_system.start_quest("managed_supply_chain_1")
	var q: Dictionary = quest_system.quests.get("managed_supply_chain_1", {})
	assert_false(q.is_empty())
	var today: int = quest_system._current_day_index()
	q["deadline_day_index"] = today - 1
	q["managed_state"] = "active"
	quest_system.on_day_passed()
	assert_eq(String(q.get("managed_state", "")), "failed", "quest should fail after deadline")

func test_chain_templates_expose_cooldown_days() -> void:
	assert_true(quest_system.chain_cooldown_days.has("managed_supply_chain"))
	assert_true(int(quest_system.chain_cooldown_days.get("managed_supply_chain", 0)) >= 0)

func test_reward_pool_pick_returns_weighted_item() -> void:
	var item: String = quest_system._pick_weighted_pool_item([
		{"item": "bread:1", "weight": 100}
	])
	assert_eq(item, "bread:1", "single-entry weighted pool should deterministically return item")
