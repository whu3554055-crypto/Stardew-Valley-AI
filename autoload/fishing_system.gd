extends Node

var _last_cast_time: float = -100.0
const CAST_COOLDOWN_SEC := 1.8

func can_fish_here(player_pos: Vector2) -> bool:
	# Main scene: southern "water" band — walk toward the bottom of the map to fish.
	return player_pos.y >= 480.0

func try_cast(player_pos: Vector2) -> Dictionary:
	if not can_fish_here(player_pos):
		return {"ok": false, "message": ""}
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_cast_time < CAST_COOLDOWN_SEC:
		return {"ok": false, "message": "The line needs a moment..."}
	_last_cast_time = now

	var rain_bonus := 0.0
	if WeatherSystem and WeatherSystem.is_raining():
		rain_bonus = 0.12

	var roll := randf()
	if roll < 0.28 - rain_bonus * 0.1:
		return _grant_catch("junk_boot", "Only old boots today...")
	if roll < 0.62 + rain_bonus:
		return _grant_catch("fish_sardine", "")
	return _grant_catch("fish_perch", "")

func _grant_catch(item_id: String, junk_message: String) -> Dictionary:
	var template: Dictionary = ItemDatabase.get_item(item_id)
	if template.is_empty():
		return {"ok": false, "message": "Catch failed (missing item data)."}
	InventoryManager.add_item(template.duplicate(true))
	var msg: String = junk_message
	if msg.is_empty():
		msg = "You caught a %s!" % str(template.get("name", item_id))
	return {"ok": true, "message": msg, "item_id": item_id}
