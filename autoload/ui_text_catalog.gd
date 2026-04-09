extends Node

const MESSAGES_DIR := "res://data/ui/"

var _messages: Dictionary = {}


func _ready() -> void:
	if LocaleSettings:
		LocaleSettings.locale_changed.connect(_on_locale_changed)
	_load_file()


func _on_locale_changed(_code: String) -> void:
	_load_file()


func reload() -> void:
	_load_file()


func _path_for_locale(code: String) -> String:
	return "%smessages_%s.json" % [MESSAGES_DIR, code]


func _load_file() -> void:
	var code: String = "zh_CN"
	if LocaleSettings:
		code = LocaleSettings.get_locale()
	var path: String = _path_for_locale(code)
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("UITextCatalog: missing %s — trying zh_CN" % path)
		if code != "zh_CN":
			path = _path_for_locale("zh_CN")
			f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("UITextCatalog: fallback defaults")
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
		_messages = (data as Dictionary).duplicate(true)
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
			"stamina_low": "体力过低——进食或休息到明天。"
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


## Maps WeatherSystem English name (e.g. "Sunny") to localized label.
func localized_weather_name(english_name: String) -> String:
	var k: String = english_name.to_lower()
	var t: String = get_text("weather", k)
	if t.is_empty():
		return english_name
	return t


## Maps season id (spring, summer, …) to localized display name.
func localized_season_name(season_id: String) -> String:
	var k: String = season_id.to_lower()
	var t: String = get_text("season", k)
	if t.is_empty():
		return season_id.capitalize()
	return t


func get_ui_text(key: String) -> String:
	return get_text("ui", key)


## Achievement copy lives under `achievements.{id}.title` / `.description` in JSON.
func get_achievement_field(achievement_id: String, field: String) -> String:
	var sec: Variant = _messages.get("achievements", {})
	if sec is Dictionary:
		var inner: Variant = (sec as Dictionary).get(achievement_id, {})
		if inner is Dictionary:
			return str((inner as Dictionary).get(field, ""))
	return ""


## Prefer `items.{item_id}` in JSON; fallback to ItemDatabase name.
func get_item_display_name(item_id: String) -> String:
	var n: String = get_text("items", item_id)
	if not n.is_empty():
		return n
	if ItemDatabase:
		var it: Dictionary = ItemDatabase.get_item(item_id)
		if not it.is_empty():
			return str(it.get("name", item_id))
	return item_id


func get_recipe_picker_title(mode: String) -> String:
	return get_text("recipe_picker", mode + "_title")


func get_recipe_picker_empty_detail() -> String:
	return get_text("recipe_picker", "empty_detail")


## History entries: `{ "key", "params", "day", "season", "year" }` → localized line.
func format_history_line(e: Dictionary) -> String:
	var key: String = str(e.get("key", "unknown"))
	var params: Dictionary = {}
	if e.get("params") is Dictionary:
		params = (e.get("params") as Dictionary).duplicate(true)
	params["day"] = int(e.get("day", 1))
	params["season"] = localized_season_name(str(e.get("season", "spring")))
	params["year"] = int(e.get("year", 1))
	if key == "achievement_unlocked":
		var aid: String = str(params.get("achievement_id", ""))
		var tit: String = get_achievement_field(aid, "title")
		if tit.is_empty() and AchievementSystem and AchievementSystem.achievements.has(aid):
			tit = str(AchievementSystem.achievements[aid].get("title", aid))
		params["title"] = tit
	var template: String = get_text("history", key)
	if template.is_empty():
		return "[%s / %s / day %s] %s" % [str(params["year"]), str(params["season"]), str(params["day"]), key]
	return format_text("history", key, params)
