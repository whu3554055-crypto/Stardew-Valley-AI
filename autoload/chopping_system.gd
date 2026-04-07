extends Node

## Forest patch west of farm (no overlap with MineArea y>=300).
const FOREST_X_MIN := 40.0
const FOREST_X_MAX := 340.0
const FOREST_Y_MIN := 90.0
const FOREST_Y_MAX := 285.0

func can_chop_here(player_pos: Vector2) -> bool:
	return player_pos.x >= FOREST_X_MIN and player_pos.x <= FOREST_X_MAX \
		and player_pos.y >= FOREST_Y_MIN and player_pos.y <= FOREST_Y_MAX

func try_chop_one() -> Dictionary:
	if GameManager and not GameManager.try_consume_stamina(4.0):
		return {"ok": false, "message": "Too tired to swing the axe."}

	var n: int = 1 + (randi() % 2)
	var template: Dictionary = ItemDatabase.get_item("wood_log")
	if template.is_empty():
		return {"ok": false, "message": "Missing wood item data."}
	for i in range(n):
		if not InventoryManager.add_item(template.duplicate(true)):
			return {"ok": false, "message": "Inventory full."}
	if QuestSystem:
		QuestSystem.track_event("chop_wood", {"count": 1})
	if GatheringSfx:
		GatheringSfx.play_chop()
	return {"ok": true, "message": "Chopped %d wood." % n}
