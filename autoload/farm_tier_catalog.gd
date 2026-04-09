extends Node

## Loads `res://data/farm/tiers.json` — tier bonuses, upgrade costs, and `farm_upgrade_rect`.
## Edit the JSON to tune tiers without code changes; falls back to embedded defaults if the file is missing.

const CONFIG_PATH := "res://data/farm/tiers.json"

var _version: int = 1
var _tiers: Array = []
var _interaction: Dictionary = {}
var _tier_by_num: Dictionary = {}


func _ready() -> void:
	_load_file()


func _load_file() -> void:
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("FarmTierCatalog: missing %s — using defaults" % CONFIG_PATH)
		_apply_defaults()
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("FarmTierCatalog: JSON parse error — using defaults")
		_apply_defaults()
		return
	var data = json.data
	if data is Dictionary:
		_apply_dict(data)
	else:
		_apply_defaults()


func _apply_defaults() -> void:
	_version = 1
	_interaction = {
		"farm_upgrade_rect": [400, 300, 360, 220],
		"farm_upgrade_hint": "Stand on the field · U = upgrade farm tier"
	}
	_tiers = [
		{
			"tier": 1,
			"display_name": "Homestead",
			"growth_speed_multiplier": 1.0,
			"harvest_bonus_chance": 0.0,
			"harvest_bonus_max": 0,
			"upgrade_cost_gold": 0,
			"upgrade_cost_items": {}
		},
		{
			"tier": 2,
			"display_name": "Expanded Plot",
			"growth_speed_multiplier": 1.06,
			"harvest_bonus_chance": 0.22,
			"harvest_bonus_max": 1,
			"upgrade_cost_gold": 450,
			"upgrade_cost_items": {"wood_log": 20}
		}
	]
	_rebuild_index()


func _apply_dict(data: Dictionary) -> void:
	_version = int(data.get("version", 1))
	_interaction = data.get("interaction", {})
	var arr: Array = data.get("tiers", [])
	_tiers = []
	for e in arr:
		if e is Dictionary:
			_tiers.append(e.duplicate(true))
	if _tiers.is_empty():
		_apply_defaults()
		return
	_rebuild_index()


func _rebuild_index() -> void:
	_tier_by_num.clear()
	for e in _tiers:
		if e is Dictionary:
			var n: int = int(e.get("tier", 0))
			if n > 0:
				_tier_by_num[n] = e


func config_version() -> int:
	return _version


func tier_def(tier_num: int) -> Dictionary:
	return _tier_by_num.get(tier_num, {})


func max_tier() -> int:
	var m := 0
	for k in _tier_by_num.keys():
		m = maxi(m, int(k))
	return m


func growth_speed_multiplier(tier_num: int) -> float:
	var d: Dictionary = tier_def(tier_num)
	return float(d.get("growth_speed_multiplier", 1.0))


func harvest_bonus_chance(tier_num: int) -> float:
	var d: Dictionary = tier_def(tier_num)
	var v: float = float(d.get("harvest_bonus_chance", 0.0))
	return clampf(v, 0.0, 1.0)


func harvest_bonus_max(tier_num: int) -> int:
	var d: Dictionary = tier_def(tier_num)
	return maxi(0, int(d.get("harvest_bonus_max", 0)))


func get_farm_upgrade_rect() -> Rect2:
	var r: Variant = _interaction.get("farm_upgrade_rect", [400.0, 300.0, 360.0, 220.0])
	if r is Array and r.size() >= 4:
		return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return Rect2(400, 300, 360, 220)


func get_farm_upgrade_hint() -> String:
	if UITextCatalog:
		var t: String = UITextCatalog.get_text("farm_tier", "farm_upgrade_hint")
		if not t.is_empty():
			return t
	return str(_interaction.get("farm_upgrade_hint", ""))


func next_tier_def(current_tier: int) -> Dictionary:
	return tier_def(current_tier + 1)


func localized_display_name(tier_num: int) -> String:
	var k: String = "tier_name_%d" % tier_num
	if UITextCatalog:
		var t: String = UITextCatalog.get_text("farm_tier", k)
		if not t.is_empty():
			return t
	var d: Dictionary = tier_def(tier_num)
	return str(d.get("display_name", "?"))


func get_message(key: String) -> String:
	if UITextCatalog:
		var loc: String = UITextCatalog.get_text("farm_tier", key)
		if not loc.is_empty():
			return loc
	var msgs: Dictionary = _interaction.get("messages", {})
	var fallback: Dictionary = {
		"unavailable": "Farm tiers unavailable.",
		"max_tier": "Farm is already at max tier.",
		"not_enough_gold": "Not enough gold ({gold}g needed).",
		"missing_materials": "Missing materials for upgrade.",
		"upgraded": "Farm upgraded: {tier_name} — crops grow a bit faster.",
		"hud_speed": "grow {speed_pct}%",
		"hud_bonus": "yield +{bonus_pct}% up to +{bonus_max}",
		"hud_line_upgradable": "farm · T{tier} {tier_name} · {speed_text} · {bonus_text} · U upgrade",
		"hud_line_max": "farm · T{tier} {tier_name} · {speed_text} · {bonus_text} · max"
	}
	return str(msgs.get(key, fallback.get(key, "")))


func format_message(key: String, vars: Dictionary = {}) -> String:
	var msg: String = get_message(key)
	for k in vars.keys():
		msg = msg.replace("{%s}" % str(k), str(vars[k]))
	return msg
