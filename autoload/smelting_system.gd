extends Node

## Matches SmelterArea in main scene (rough forge slab near farm).
const SMELTER_X_MIN := 380.0
const SMELTER_X_MAX := 580.0
const SMELTER_Y_MIN := 70.0
const SMELTER_Y_MAX := 260.0

func can_smelt_here(player_pos: Vector2) -> bool:
	return player_pos.x >= SMELTER_X_MIN and player_pos.x <= SMELTER_X_MAX \
		and player_pos.y >= SMELTER_Y_MIN and player_pos.y <= SMELTER_Y_MAX

func try_smelt_one() -> Dictionary:
	if GameManager and not GameManager.try_consume_stamina(3.0):
		return {"ok": false, "message": "Too tired to work the furnace."}

	var recipes: Array = [
		{"in": {"copper_ore": 5, "coal": 1}, "out": "copper_bar", "qty": 1},
		{"in": {"iron_ore": 5, "coal": 1}, "out": "iron_bar", "qty": 1},
		{"in": {"gold_ore": 5, "coal": 2}, "out": "gold_bar", "qty": 1},
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
		if GatheringSfx:
			GatheringSfx.play_smelt()
		var nm: String = str(template.get("name", out_id))
		return {"ok": true, "message": "Smelted: %s" % nm}
	return {"ok": false, "message": "Need ore and coal (5 ore + 1–2 coal)."}

func _can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if InventoryManager.count_item(str(k)) < int(costs[k]):
			return false
	return true

func _consume(costs: Dictionary) -> void:
	for k in costs.keys():
		InventoryManager.consume_item_by_id(str(k), int(costs[k]))
