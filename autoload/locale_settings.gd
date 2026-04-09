extends Node

## Player language: Simplified Chinese (default) or English. Persisted under user://.

const SETTINGS_PATH := "user://locale_settings.json"
const LOCALE_ZH := "zh_CN"
const LOCALE_EN := "en"

var locale: String = LOCALE_ZH

signal locale_changed(new_locale: String)


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		locale = LOCALE_ZH
		_save()
		return
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		locale = LOCALE_ZH
		return
	var txt: String = f.get_as_text()
	f.close()
	var j := JSON.new()
	if j.parse(txt) != OK:
		locale = LOCALE_ZH
		return
	var data = j.data
	if data is Dictionary:
		var l: String = str((data as Dictionary).get("locale", LOCALE_ZH))
		if l == LOCALE_EN or l == LOCALE_ZH:
			locale = l
		else:
			locale = LOCALE_ZH
	else:
		locale = LOCALE_ZH


func _save() -> void:
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"locale": locale}))
	f.close()


func set_locale(code: String) -> void:
	if code != LOCALE_EN and code != LOCALE_ZH:
		return
	if locale == code:
		return
	locale = code
	_save()
	locale_changed.emit(locale)


func get_locale() -> String:
	return locale


func is_english() -> bool:
	return locale == LOCALE_EN
