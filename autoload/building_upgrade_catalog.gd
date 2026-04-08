extends Node

const CONFIG_PATH := "res://data/buildings/upgrades.json"

var _interaction: Dictionary = {}
var _level_by_num: Dictionary = {}


func _ready() -> void:
	_load_file()


func _load_file() -> void:
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("BuildingUpgradeCatalog: missing %s — using defaults" % CONFIG_PATH)
		_apply_defaults()
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_warning("BuildingUpgradeCatalog: parse error — using defaults")
		_apply_defaults()
		return
	var d: Dictionary = json.data
	_interaction = d.get("interaction", {})
	_level_by_num.clear()
	var levels: Array = d.get("levels", [])
	for e in levels:
		if e is Dictionary:
			var lv: int = int(e.get("level", 0))
			if lv > 0:
				_level_by_num[lv] = e.duplicate(true)
	if _level_by_num.is_empty():
		_apply_defaults()


func _apply_defaults() -> void:
	_interaction = {
		"house_upgrade_rect": [560, 240, 300, 220],
		"hud_line_upgradable": "house · L{level} {name} · +{stamina_bonus} max stamina · H upgrade",
		"hud_line_max": "house · L{level} {name} · +{stamina_bonus} max stamina · max",
		"tip_outside": "Stand near the farmhouse to upgrade.",
		"tip_not_enough_gold": "Not enough gold ({gold}g needed).",
		"tip_missing_materials": "Missing materials for house upgrade.",
		"tip_upgraded": "House upgraded to {name}! Max stamina +{stamina_bonus}.",
		"tip_max": "House is already at max level."
	}
	_level_by_num = {
		1: {"level": 1, "name": "Cabin", "stamina_max_bonus": 0, "upgrade_cost_gold": 0, "upgrade_cost_items": {}},
		2: {"level": 2, "name": "Cozy House", "stamina_max_bonus": 20, "upgrade_cost_gold": 700, "upgrade_cost_items": {"wood_log": 40, "copper_bar": 2}}
	}


func level_def(level: int) -> Dictionary:
	return _level_by_num.get(level, {})


func next_level_def(level: int) -> Dictionary:
	return level_def(level + 1)


func max_level() -> int:
	var m: int = 1
	for k in _level_by_num.keys():
		m = maxi(m, int(k))
	return m


func get_house_rect() -> Rect2:
	var r: Variant = _interaction.get("house_upgrade_rect", [560, 240, 300, 220])
	if r is Array and r.size() >= 4:
		return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return Rect2(560, 240, 300, 220)


func format_message(key: String, vars: Dictionary = {}) -> String:
	var msg: String = str(_interaction.get(key, ""))
	for k in vars.keys():
		msg = msg.replace("{%s}" % str(k), str(vars[k]))
	return msg
