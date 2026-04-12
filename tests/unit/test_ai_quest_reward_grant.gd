extends GutTest

## B1: AI quest completion grants gold, GameManager friendship/skill_xp, and inventory items.

const GIVER := "gut_ai_quest_reward_npc"
const OTHER := "gut_ai_quest_reward_npc2"

var _ai: AIQuestSystem
var _inv_snap: Dictionary = {}
var _gold0: int
var _friend0: Dictionary
var _skill0: Dictionary
var _bread0: int
var _bait0: int


func before_each() -> void:
	assert_true(InventoryManager != null, "test needs InventoryManager autoload")
	_inv_snap = InventoryManager.save_snapshot()
	_ai = preload("res://autoload/ai_quest_system.gd").new()
	add_child(_ai)
	_ai.set_process(false)
	GameManager.ensure_progression_subtrees()
	_gold0 = int(GameManager.player_data.get("gold", 0))
	_friend0 = (GameManager.player_data["npc_friendship"] as Dictionary).duplicate(true)
	_skill0 = (GameManager.player_data["skill_xp"] as Dictionary).duplicate(true)
	_bread0 = InventoryManager.count_item("bread")
	_bait0 = InventoryManager.count_item("worm_bait")


func after_each() -> void:
	if is_instance_valid(_ai):
		_ai.queue_free()
	_ai = null
	InventoryManager.load_snapshot(_inv_snap)
	GameManager.player_data["gold"] = _gold0
	GameManager.player_data["npc_friendship"] = _friend0.duplicate(true)
	GameManager.player_data["skill_xp"] = _skill0.duplicate(true)


func test_grant_quest_rewards_applies_gold_friendship_skill_and_items() -> void:
	var quest := {
		"id": "gut_q_reward_1",
		"quest_giver": GIVER,
		"reward_skill": "farming",
		"rewards": {
			"gold": 42,
			"friendship": 3,
			"skill_xp": 25,
			"skill": "farming",
			"item": "bread",
			"item_count": 2,
			"items": [{"id": "bread", "count": 1}, "worm_bait:1"]
		}
	}
	_ai.grant_quest_rewards(quest)

	assert_eq(int(GameManager.player_data.get("gold", 0)), _gold0 + 42, "gold should increase")
	assert_eq(GameManager.get_npc_friendship(GIVER), int(_friend0.get(GIVER, 0)) + 3, "friendship dict")
	assert_eq(GameManager.get_skill_xp("farming"), int(_skill0.get("farming", 0)) + 25, "skill_xp farming")
	assert_eq(InventoryManager.count_item("bread"), _bread0 + 3, "bread x2 + items array bread + worm_bait")
	assert_eq(InventoryManager.count_item("worm_bait"), _bait0 + 1, "worm_bait from items string")


func test_grant_quest_rewards_friendship_both() -> void:
	var quest := {
		"id": "gut_q_reward_2",
		"quest_giver": GIVER,
		"npc1": GIVER,
		"npc2": OTHER,
		"rewards": {"friendship_both": 2}
	}
	_ai.grant_quest_rewards(quest)
	assert_eq(GameManager.get_npc_friendship(GIVER), int(_friend0.get(GIVER, 0)) + 2)
	assert_eq(GameManager.get_npc_friendship(OTHER), int(_friend0.get(OTHER, 0)) + 2)
