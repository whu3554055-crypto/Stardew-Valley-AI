extends Node

const GT := preload("res://scripts/gathering_tables.gd")

const CAST_COOLDOWN_SEC := 1.6
const HOOK_WINDOW_SEC := 1.65

var _last_catch_time: float = -100.0
var _fish_phase: String = "idle"  # idle | hook
var _hook_deadline: float = 0.0
var _bait_flag: bool = false

func get_fish_zone(player_pos: Vector2) -> String:
	if player_pos.x >= 1000.0 and player_pos.y >= 220.0 and player_pos.y <= 520.0:
		return "river"
	if player_pos.y >= 480.0:
		return "ocean"
	return ""

func can_fish_here(player_pos: Vector2) -> bool:
	return get_fish_zone(player_pos) != ""

func _process(_delta: float) -> void:
	if _fish_phase == "hook" and Time.get_ticks_msec() / 1000.0 > _hook_deadline:
		_fish_phase = "idle"

func handle_fish_input(player_pos: Vector2) -> Dictionary:
	if not can_fish_here(player_pos):
		return {"ok": false, "message": ""}

	var now: float = Time.get_ticks_msec() / 1000.0

	if _fish_phase == "hook":
		if now > _hook_deadline:
			_fish_phase = "idle"
			return {"ok": false, "message": "The fish got away."}
		_fish_phase = "idle"
		_last_catch_time = now
		return _resolve_catch(player_pos)

	# idle -> start hook window
	if now - _last_catch_time < CAST_COOLDOWN_SEC:
		return {"ok": false, "message": "The line needs a moment..."}

	_bait_flag = InventoryManager.count_item("worm_bait") > 0
	_fish_phase = "hook"
	_hook_deadline = now + HOOK_WINDOW_SEC
	return {
		"ok": true,
		"phase": "hook_prompt",
		"message": "A bite! Press E again!"
	}

func _resolve_catch(player_pos: Vector2) -> Dictionary:
	var zone: String = get_fish_zone(player_pos)
	var season: String = "spring"
	var hour: int = 12
	var raining := false
	if GameManager:
		season = str(GameManager.player_data.get("season", "spring"))
		hour = int(GameManager.current_time)
	if WeatherSystem:
		raining = WeatherSystem.is_raining()

	var weights: Dictionary = GT.get_fish_table(zone, season, hour, raining)
	if _bait_flag:
		for k in weights.keys():
			if str(k).begins_with("fish_"):
				weights[k] = float(weights[k]) * 1.18

	var item_id: String = _weighted_pick(weights)
	if item_id.is_empty():
		item_id = "junk_boot"
	return _grant_catch(item_id, "")

func _weighted_pick(weights: Dictionary) -> String:
	var total := 0.0
	for k in weights.keys():
		total += float(weights[k])
	if total <= 0.0:
		return ""
	var r: float = randf() * total
	for k in weights.keys():
		r -= float(weights[k])
		if r <= 0.0:
			return str(k)
	for k in weights.keys():
		return str(k)
	return ""

func _grant_catch(item_id: String, junk_message: String) -> Dictionary:
	var template: Dictionary = ItemDatabase.get_item(item_id)
	if template.is_empty():
		return {"ok": false, "message": "Catch failed (missing item data)."}
	if not InventoryManager.add_item(template.duplicate(true)):
		return {"ok": false, "message": "Inventory full."}
	if _bait_flag:
		InventoryManager.consume_item_by_id("worm_bait", 1)
	if GatheringAlmanac:
		GatheringAlmanac.record_fish(item_id)
	if QuestSystem:
		QuestSystem.track_event("fish_caught", {"fish_id": item_id, "count": 1})
	var msg: String = junk_message
	if msg.is_empty():
		msg = "You caught a %s!" % str(template.get("name", item_id))
	return {"ok": true, "message": msg, "item_id": item_id}
