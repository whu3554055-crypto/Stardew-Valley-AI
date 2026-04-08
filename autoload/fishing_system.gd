extends Node

const GT := preload("res://scripts/gathering_tables.gd")

const CAST_COOLDOWN_SEC := 1.45
const HOOK_WINDOW_SEC := 1.78
const HOOK_EARLY_MIN_SEC := 0.22
const BAIT_WEIGHT_MULT_BY_TIER := {
	1: 1.25,  # worm bait
	2: 1.55   # premium bait
}

var _last_catch_time: float = -100.0
var _fish_phase: String = "idle"  # idle | hook
var _hook_deadline: float = 0.0
var _hook_start_time: float = 0.0
var _bait_tier: int = 0

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
		if now < _hook_start_time + HOOK_EARLY_MIN_SEC:
			_fish_phase = "idle"
			return {"ok": false, "message": "Too soon — wait for a solid tug."}
		if now > _hook_deadline:
			_fish_phase = "idle"
			return {"ok": false, "message": "The bite slipped — you were too slow."}
		if GameManager and not GameManager.try_consume_stamina(6.0):
			_fish_phase = "idle"
			return {"ok": false, "message": "Too tired to reel in."}
		_fish_phase = "idle"
		_last_catch_time = now
		return _resolve_catch(player_pos)

	# idle -> start hook window
	if now - _last_catch_time < CAST_COOLDOWN_SEC:
		return {"ok": false, "message": "The line needs a moment..."}
	if GameManager and not GameManager.try_consume_stamina(4.0):
		return {"ok": false, "message": "Too tired to fish."}

	_bait_tier = _resolve_best_bait_tier()
	_fish_phase = "hook"
	_hook_start_time = now
	_hook_deadline = now + HOOK_WINDOW_SEC
	if GatheringSfx:
		GatheringSfx.play_fish_cast()
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

	var wx: String = ""
	if WeatherSystem:
		wx = str(WeatherSystem.get_weather_name()).to_lower()

	var weights: Dictionary = GT.get_fish_table(zone, season, hour, raining, wx)
	if _bait_tier > 0:
		var mult: float = float(BAIT_WEIGHT_MULT_BY_TIER.get(_bait_tier, 1.0))
		for k in weights.keys():
			if str(k).begins_with("fish_"):
				weights[k] = float(weights[k]) * mult

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
	if GatheringSfx:
		GatheringSfx.play_fish_catch()
	if _bait_tier > 0:
		_consume_bait_for_tier(_bait_tier)
	if GatheringAlmanac:
		GatheringAlmanac.record_fish(item_id)
	# Quests: count real fish only (junk_* does not advance "catch fish" tutorials).
	if QuestSystem and str(item_id).begins_with("fish_"):
		QuestSystem.track_event("fish_caught", {"fish_id": item_id, "count": 1})
	var msg: String = junk_message
	if msg.is_empty():
		msg = _catch_message(item_id, template)
	return {"ok": true, "message": msg, "item_id": item_id}

func _catch_message(item_id: String, template: Dictionary) -> String:
	match item_id:
		"junk_boot":
			return "Only an old boot… better luck next cast."
		"junk_seaweed":
			return "A soggy clump of seaweed. The sea mocks you."
		"fish_pike":
			return "A fierce northern pike — long jaws, cold water."
		"fish_halibut":
			return "A flat halibut from the deep — heavy pull on the line."
		_:
			return "You caught a %s!" % str(template.get("name", item_id))


func _resolve_best_bait_tier() -> int:
	if InventoryManager.count_item("premium_bait") > 0:
		return 2
	if InventoryManager.count_item("worm_bait") > 0:
		return 1
	return 0


func _consume_bait_for_tier(tier: int) -> void:
	match tier:
		2:
			InventoryManager.consume_item_by_id("premium_bait", 1)
		1:
			InventoryManager.consume_item_by_id("worm_bait", 1)
