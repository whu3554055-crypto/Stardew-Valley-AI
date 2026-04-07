extends Node

## Bounds must match Main scene node `MineArea` (global AABB used for point test).
const MINE_GLOBAL_X_MIN := 70.0
const MINE_GLOBAL_X_MAX := 310.0
const MINE_GLOBAL_Y_MIN := 300.0
const MINE_GLOBAL_Y_MAX := 520.0

var _last_swing_time: float = -100.0
const SWING_COOLDOWN_SEC := 1.2

func can_mine_here(player_pos: Vector2) -> bool:
	return player_pos.x >= MINE_GLOBAL_X_MIN and player_pos.x <= MINE_GLOBAL_X_MAX \
		and player_pos.y >= MINE_GLOBAL_Y_MIN and player_pos.y <= MINE_GLOBAL_Y_MAX

func try_swing(player_pos: Vector2) -> Dictionary:
	if not can_mine_here(player_pos):
		return {"ok": false, "message": ""}
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_swing_time < SWING_COOLDOWN_SEC:
		return {"ok": false, "message": "You catch your breath..."}
	_last_swing_time = now

	var roll := randf()
	if roll < 0.22:
		return _grant_ore("stone_chunk", "")
	if roll < 0.55:
		return _grant_ore("copper_ore", "")
	return _grant_ore("coal", "")

func _grant_ore(item_id: String, empty_msg: String) -> Dictionary:
	var template: Dictionary = ItemDatabase.get_item(item_id)
	if template.is_empty():
		return {"ok": false, "message": "Mine yielded nothing (missing item data)."}
	InventoryManager.add_item(template.duplicate(true))
	var msg: String = empty_msg
	if msg.is_empty():
		msg = "Mined: %s" % str(template.get("name", item_id))
	return {"ok": true, "message": msg, "item_id": item_id}
