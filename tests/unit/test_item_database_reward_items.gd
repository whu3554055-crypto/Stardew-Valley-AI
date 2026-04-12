extends GutTest

## G1: shop / agentic reward item ids must exist in ItemDatabase (invalid_reward_item guard).

func test_core_shop_items_exist_for_agentic_rewards() -> void:
	var ids: PackedStringArray = PackedStringArray([
		"parsnip_seeds", "cauliflower_seeds", "potato_seeds", "corn_seeds", "pumpkin_seeds",
		"basic_fertilizer", "worm_bait", "premium_bait", "bread", "fishing_rod", "pickaxe_iron"
	])
	for item_id in ids:
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		assert_false(tpl.is_empty(), "ItemDatabase should define '%s' (shop + reward guardrail)" % item_id)
