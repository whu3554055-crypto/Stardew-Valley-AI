extends Node

## Loads/saves per-bus volume from `user://audio_mix.json` (dB). Applied on boot before gameplay.
## UI: `AudioMixPanel` (F10) calls `save_current()`.

const USER_PATH := "user://audio_mix.json"
const BUS_ORDER: PackedStringArray = ["Master", "Music", "Ambience", "SFX", "Voice"]

func _ready() -> void:
	_apply_from_file()

func _apply_from_file() -> void:
	var f: FileAccess = FileAccess.open(USER_PATH, FileAccess.READ)
	if f == null:
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return
	var data = json.data
	if not (data is Dictionary):
		return
	var d: Dictionary = data as Dictionary
	for bus_name in BUS_ORDER:
		if not d.has(bus_name):
			continue
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		var v: Variant = d[bus_name]
		if v is float or v is int:
			AudioServer.set_bus_volume_db(idx, float(v))

func save_current() -> void:
	var out: Dictionary = {}
	for bus_name in BUS_ORDER:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		out[bus_name] = AudioServer.get_bus_volume_db(idx)
	var f: FileAccess = FileAccess.open(USER_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("AudioMixSettings: cannot write %s" % USER_PATH)
		return
	f.store_string(JSON.stringify(out))
	f.close()
