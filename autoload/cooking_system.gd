extends Node

## Matches KitchenArea in main scene (counter south-east of farm).
const KITCHEN_X_MIN := 600.0
const KITCHEN_X_MAX := 820.0
const KITCHEN_Y_MIN := 260.0
const KITCHEN_Y_MAX := 430.0

func can_cook_here(player_pos: Vector2) -> bool:
	return player_pos.x >= KITCHEN_X_MIN and player_pos.x <= KITCHEN_X_MAX \
		and player_pos.y >= KITCHEN_Y_MIN and player_pos.y <= KITCHEN_Y_MAX

func try_cook_one() -> Dictionary:
	if GameManager and not GameManager.try_consume_stamina(2.0):
		return {"ok": false, "message": "Too tired to cook."}

	var recipes: Array = [
		{"in": {"bread": 1, "fish_sardine": 1}, "out": "fish_sandwich", "qty": 1},
		{"in": {"fish_sardine": 1}, "out": "grilled_sardine", "qty": 1},
		{"in": {"fish_perch": 1}, "out": "grilled_perch", "qty": 1},
		{"in": {"fish_trout": 1}, "out": "grilled_trout", "qty": 1},
		{"in": {"fish_carp": 1}, "out": "grilled_carp", "qty": 1},
		{"in": {"parsnip": 1}, "out": "roasted_parsnip", "qty": 1},
		{"in": {"potato": 1}, "out": "baked_potato", "qty": 1},
		{"in": {"cauliflower": 1}, "out": "roasted_cauliflower", "qty": 1},
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
		for i in range(qty):
			if not InventoryManager.add_item(template.duplicate(true)):
				return {"ok": false, "message": "Inventory full."}
		_consume(cost)
		if QuestSystem:
			QuestSystem.track_event("cook_meal", {"dish_id": out_id, "count": 1})
		if GatheringSfx:
			GatheringSfx.play_cook()
		var nm: String = str(template.get("name", out_id))
		return {"ok": true, "message": "Cooked: %s" % nm}
	return {"ok": false, "message": "Need ingredients (fish, vegetables, or bread+fish)."}

func _can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if InventoryManager.count_item(str(k)) < int(costs[k]):
			return false
	return true

func _consume(costs: Dictionary) -> void:
	for k in costs.keys():
		InventoryManager.consume_item_by_id(str(k), int(costs[k]))
