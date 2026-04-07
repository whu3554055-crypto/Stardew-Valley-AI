extends Node

## Workbench east of kitchen (no overlap with kitchen x<=820).
const BENCH_X_MIN := 825.0
const BENCH_X_MAX := 1040.0
const BENCH_Y_MIN := 275.0
const BENCH_Y_MAX := 430.0

func can_craft_here(player_pos: Vector2) -> bool:
	return player_pos.x >= BENCH_X_MIN and player_pos.x <= BENCH_X_MAX \
		and player_pos.y >= BENCH_Y_MIN and player_pos.y <= BENCH_Y_MAX

func try_craft_one() -> Dictionary:
	var recipes: Array = [
		{"in": {"wood_log": 2, "coal": 1}, "out": "worm_bait", "qty": 5},
		{"in": {"wood_log": 3, "copper_bar": 1}, "out": "sprinkler_basic", "qty": 1},
	]
	for r in recipes:
		var cost: Dictionary = r.get("in", {})
		if not _can_afford(cost):
			continue
		var out_id: String = str(r.get("out", ""))
		var template: Dictionary = ItemDatabase.get_item(out_id)
		if template.is_empty():
			return {"ok": false, "message": "Recipe output missing."}
		var qty: int = int(r.get("qty", 1))
		if not InventoryManager.can_add_quantity(template, qty):
			var nm: String = str(template.get("name", out_id))
			return {"ok": false, "message": "Inventory full — need room for %s ×%d." % [nm, qty]}
		if GameManager and not GameManager.try_consume_stamina(3.0):
			return {"ok": false, "message": "Too tired to work the bench."}
		for i in range(qty):
			if not InventoryManager.add_item(template.duplicate(true)):
				return {"ok": false, "message": "Inventory full."}
		_consume(cost)
		if QuestSystem:
			QuestSystem.track_event("craft_item", {"item_id": out_id, "count": 1})
		if GatheringSfx:
			GatheringSfx.play_craft()
		var nm2: String = str(template.get("name", out_id))
		return {"ok": true, "message": "Crafted: %s" % nm2}
	var hint: String = RecipeHelpers.hint_first_unaffordable(recipes)
	if hint.is_empty():
		return {"ok": false, "message": "No craft available."}
	return {"ok": false, "message": "Can't craft yet. %s" % hint}

func _can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if InventoryManager.count_item(str(k)) < int(costs[k]):
			return false
	return true

func _consume(costs: Dictionary) -> void:
	for k in costs.keys():
		InventoryManager.consume_item_by_id(str(k), int(costs[k]))
