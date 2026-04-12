extends GutTest

## B2: shop trades and quest completion nudge market demand (AIEconomySystem).

var _market_snap: Dictionary = {}
var _pressure_snap: Dictionary = {}


func before_each() -> void:
	assert_true(AIEconomySystem != null)
	_market_snap = AIEconomySystem.market_state.duplicate(true)
	_pressure_snap = AIEconomySystem._daily_quest_pressure.duplicate(true)


func after_each() -> void:
	AIEconomySystem.market_state = _market_snap.duplicate(true)
	AIEconomySystem._daily_quest_pressure = _pressure_snap.duplicate(true)


func test_on_shop_trade_buy_increases_item_demand() -> void:
	var item_id := "parsnip_seeds"
	AIEconomySystem.initialize_item_market(item_id)
	var d0: float = float(AIEconomySystem.market_state.items[item_id].demand)
	AIEconomySystem.on_shop_trade(item_id, 3, true)
	var d1: float = float(AIEconomySystem.market_state.items[item_id].demand)
	assert_gt(d1, d0, "buying from shop should raise tracked demand")


func test_on_quest_completed_delivery_bumps_target_item() -> void:
	var item_id := "potato"
	AIEconomySystem.initialize_item_market(item_id)
	var d0: float = float(AIEconomySystem.market_state.items[item_id].demand)
	AIEconomySystem.on_quest_completed({
		"id": "ut_econ_delivery",
		"source": "quest_system",
		"reward": {"gold": 0, "items": []},
		"objectives": [{"type": "delivery", "item_id": item_id, "count": 1, "current": 1}]
	})
	var d1: float = float(AIEconomySystem.market_state.items[item_id].demand)
	assert_gt(d1, d0)


func test_on_quest_completed_fish_objective_bumps_bait() -> void:
	var item_id := "worm_bait"
	AIEconomySystem.initialize_item_market(item_id)
	var d0: float = float(AIEconomySystem.market_state.items[item_id].demand)
	AIEconomySystem.on_quest_completed({
		"id": "ut_econ_fish",
		"source": "quest_system",
		"reward": {"gold": 0, "items": []},
		"objectives": [{"type": "fish_caught", "count": 3, "current": 3}]
	})
	var d1: float = float(AIEconomySystem.market_state.items[item_id].demand)
	assert_gt(d1, d0)


func test_on_quest_completed_accepts_rewards_alias_and_dict_items() -> void:
	AIEconomySystem.initialize_item_market("bread")
	AIEconomySystem.initialize_item_market("coal")
	var d_b0: float = float(AIEconomySystem.market_state.items["bread"].demand)
	var d_c0: float = float(AIEconomySystem.market_state.items["coal"].demand)
	AIEconomySystem.on_quest_completed({
		"id": "ut_econ_ai_shape",
		"source": "ai_quest_system",
		"rewards": {"gold": 30, "items": [{"id": "bread", "count": 2}], "item": "coal", "item_count": 1},
		"objectives": []
	})
	var d_b1: float = float(AIEconomySystem.market_state.items["bread"].demand)
	var d_c1: float = float(AIEconomySystem.market_state.items["coal"].demand)
	assert_gt(d_b1, d_b0, "dict items in rewards[] should bump demand")
	assert_gt(d_c1, d_c0, "single item + item_count should bump demand")
