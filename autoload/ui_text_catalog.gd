extends Node

const CONFIG_PATH := "res://data/ui/messages.json"

var _messages: Dictionary = {}


func _ready() -> void:
	_load_file()


func _load_file() -> void:
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("UITextCatalog: missing %s — using defaults" % CONFIG_PATH)
		_apply_defaults()
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("UITextCatalog: JSON parse error — using defaults")
		_apply_defaults()
		return
	var data = json.data
	if data is Dictionary:
		_messages = data.get("activity_zone", {})
	else:
		_apply_defaults()


func _apply_defaults() -> void:
	_messages = {
		"fish_river": "钓鱼 · 河流",
		"fish_ocean": "钓鱼 · 海洋",
		"mine_prefix": "矿区 · {band}",
		"mine_band_0": "表层",
		"mine_band_1": "铁矿带",
		"mine_band_2": "深脉",
		"chop_forest": "伐木 · 森林"
	}


func get_activity_text(key: String) -> String:
	return str(_messages.get(key, ""))


func format_activity_text(key: String, vars: Dictionary = {}) -> String:
	var msg: String = get_activity_text(key)
	for k in vars.keys():
		msg = msg.replace("{%s}" % str(k), str(vars[k]))
	return msg
