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
		_messages = data.duplicate(true)
	else:
		_apply_defaults()


func _apply_defaults() -> void:
	_messages = {
		"activity_zone": {
			"fish_river": "钓鱼 · 河流",
			"fish_ocean": "钓鱼 · 海洋",
			"mine_prefix": "矿区 · {band}",
			"mine_band_0": "表层",
			"mine_band_1": "铁矿带",
			"mine_band_2": "深脉",
			"chop_forest": "伐木 · 森林"
		},
		"quick_tip": {
			"farm_upgrade_stand_on_field": "Stand on the farm field to upgrade.",
			"shop_open_near_pierre": "Open the shop near Pierre.",
			"sell_nothing_selected": "Nothing selected to sell.",
			"sell_item_cannot": "This item can't be sold.",
			"sell_success_gold": "Sold for {gold}g.",
			"shop_bought_item": "Bought {item}",
			"shop_purchase_failed": "Can't afford or out of stock."
		}
	}


func get_text(section: String, key: String) -> String:
	var sec: Dictionary = _messages.get(section, {})
	return str(sec.get(key, ""))


func format_text(section: String, key: String, vars: Dictionary = {}) -> String:
	var msg: String = get_text(section, key)
	for k in vars.keys():
		msg = msg.replace("{%s}" % str(k), str(vars[k]))
	return msg


func get_activity_text(key: String) -> String:
	return get_text("activity_zone", key)


func format_activity_text(key: String, vars: Dictionary = {}) -> String:
	return format_text("activity_zone", key, vars)
