extends Node

## Loads `res://data/presentation/immersion_config.json` for audio/visual tuning (falls back to baked defaults if missing).

const CONFIG_PATH := "res://data/presentation/immersion_config.json"

var _data: Dictionary = {}
var _loaded: bool = false

func _ready() -> void:
	_load_file()

func _load_file() -> void:
	var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("ImmersionConfig: missing %s — using empty config + code fallbacks" % CONFIG_PATH)
		_data = {}
		_loaded = true
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("ImmersionConfig: JSON parse error — using empty config + code fallbacks")
		_data = {}
		_loaded = true
		return
	if json.data is Dictionary:
		_data = json.data
	else:
		_data = {}
	_loaded = true

func get_music_offset_db_for_weather(w: int) -> float:
	var k: String = weather_key_from_enum(w)
	return get_level_dict("audio.levels.music_offset_db", k, 0.0)

func get_music_pitch_for_weather(w: int) -> float:
	var k: String = weather_key_from_enum(w)
	return get_level_dict("audio.levels.music_pitch", k, 1.0)

func get_weather_vol_base_db(weather_key: String) -> float:
	return get_level_dict("audio.levels.weather_vol_base", weather_key, -14.0)

func get_shop_bell_after_door_sec() -> float:
	return get_float("audio.levels.shop_bell_after_door_sec", 0.18)

func get_footstep_path(kind: String) -> String:
	var p: Variant = get_nested("audio.paths.footsteps.%s" % kind, "")
	return str(p)

func get_storm_sfx() -> Dictionary:
	var d: Variant = get_nested("audio.storm", {})
	return d if d is Dictionary else {}

func get_mine_sfx_reverb() -> Dictionary:
	var d: Variant = get_nested("audio.sfx_mine_reverb", {})
	return d if d is Dictionary else {}

func get_forest_presence() -> Dictionary:
	var d: Variant = get_nested("audio.forest_presence", {})
	return d if d is Dictionary else {}

func get_stamina_low_config() -> Dictionary:
	var d: Variant = get_nested("audio.stamina_low", {})
	return d if d is Dictionary else {}

func get_time_tint_hours() -> Dictionary:
	return {
		"dawn_start": get_float("visual.time_tint.dawn_start", 5.0),
		"dawn_end": get_float("visual.time_tint.dawn_end", 7.0),
		"dusk_start": get_float("visual.time_tint.dusk_start", 17.0),
		"dusk_end": get_float("visual.time_tint.dusk_end", 20.0),
		"night_after_hour": get_float("visual.time_tint.night_after_hour", 21.0),
	}

func get_nested(path: String, default: Variant = null) -> Variant:
	var parts: PackedStringArray = path.split(".")
	var cur: Variant = _data
	for p in parts:
		if cur is Dictionary and (cur as Dictionary).has(p):
			cur = (cur as Dictionary)[p]
		else:
			return default
	return cur

func weather_key_from_enum(w: int) -> String:
	if not WeatherSystem:
		return "sunny"
	match w:
		WeatherSystem.WeatherType.SUNNY:
			return "sunny"
		WeatherSystem.WeatherType.OVERCAST:
			return "overcast"
		WeatherSystem.WeatherType.WINDY:
			return "windy"
		WeatherSystem.WeatherType.RAIN:
			return "rain"
		WeatherSystem.WeatherType.STORM:
			return "storm"
		WeatherSystem.WeatherType.SNOW:
			return "snow"
	return "sunny"

func get_season_audio_path(season_key: String) -> String:
	var p: Variant = get_nested("audio.paths.season.%s" % season_key.to_lower(), "")
	return str(p)

func get_weather_audio_path(key: String) -> String:
	var p: Variant = get_nested("audio.paths.weather.%s" % key, "")
	return str(p)

func get_region_audio_path(key: String) -> String:
	var p: Variant = get_nested("audio.paths.region.%s" % key, "")
	return str(p)

func get_one_shot_path(key: String) -> String:
	var p: Variant = get_nested("audio.paths.%s" % key, "")
	return str(p)

func get_level(path: String, default: float) -> float:
	var v: Variant = get_nested(path, default)
	if v is float or v is int:
		return float(v)
	return default

func get_level_dict(path: String, key: String, default: float) -> float:
	var d: Variant = get_nested(path, {})
	if d is Dictionary and (d as Dictionary).has(key):
		var v: Variant = (d as Dictionary)[key]
		if v is float or v is int:
			return float(v)
	return default

func get_color_from_array(path: String, fallback: Color) -> Color:
	var v: Variant = get_nested(path, null)
	if v is Array:
		var a: Array = v as Array
		if a.size() >= 3:
			return Color(
				float(a[0]),
				float(a[1]),
				float(a[2]),
				float(a[3]) if a.size() > 3 else 1.0
			)
	return fallback

func get_weather_tint_color(w: int) -> Color:
	var k: String = weather_key_from_enum(w)
	return get_color_from_array("visual.weather_tints.%s" % k, Color.WHITE)

func get_ui_weather_accent_mult(w: int) -> Color:
	var k: String = weather_key_from_enum(w)
	return get_color_from_array("visual.ui_weather_accent_mult.%s" % k, Color.WHITE)

func get_time_tint_night() -> Color:
	return get_color_from_array("visual.time_tint.night", Color(0.86, 0.88, 0.96, 1.0))

func get_time_tint_dusk() -> Color:
	return get_color_from_array("visual.time_tint.dusk_target", Color(0.9, 0.9, 0.97, 1.0))

func get_float(path: String, default: float) -> float:
	return get_level(path, default)

func get_particle(path: String, default: float) -> float:
	return get_level(path, default)

func get_particle_int(path: String, default: int) -> int:
	var v: Variant = get_nested(path, default)
	if v is int:
		return v
	if v is float:
		return int(v)
	return default

func get_fish_river_rect() -> Rect2:
	var a: Variant = get_nested("zones.fish_river", [])
	if a is Array and (a as Array).size() >= 4:
		var ar: Array = a as Array
		return Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3]))
	return Rect2(1000.0, 220.0, 3200.0, 300.0)

func get_fish_ocean_rect() -> Rect2:
	var a: Variant = get_nested("zones.fish_ocean", [])
	if a is Array and (a as Array).size() >= 4:
		var ar: Array = a as Array
		return Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3]))
	return Rect2(-500.0, 480.0, 4000.0, 2000.0)

func get_station_rect(key: String) -> Rect2:
	var a: Variant = get_nested("zones.stations.%s" % key, [])
	if a is Array and (a as Array).size() >= 4:
		var ar: Array = a as Array
		return Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3]))
	var fb: Dictionary = {
		"kitchen": Rect2(600, 260, 220, 170),
		"workbench": Rect2(825, 275, 215, 155),
		"smelter": Rect2(380, 70, 200, 190),
		"forest": Rect2(40, 95, 280, 180),
		"near_pierre": Rect2(560, 260, 280, 280),
	}
	return fb.get(key, Rect2())

func get_barn_rect() -> Rect2:
	var a: Variant = get_nested("zones.barn", [])
	if a is Array and (a as Array).size() >= 4:
		var ar: Array = a as Array
		return Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3]))
	return Rect2(920.0, 285.0, 200.0, 140.0)

func get_mine_bounds() -> Dictionary:
	var d: Variant = get_nested("zones.mine", {})
	if d is Dictionary:
		return d as Dictionary
	return {
		"x_min": 70.0,
		"x_max": 310.0,
		"y_min": 300.0,
		"y_max": 520.0,
		"depth_break_1": 380.0,
		"depth_break_2": 460.0,
	}

func ambience_lowpass_config() -> Dictionary:
	var d: Variant = get_nested("audio.ambience_bus_lowpass", {})
	return d if d is Dictionary else {}

func apply_ambience_lowpass_for_precipitation(active: bool) -> void:
	var cfg: Dictionary = ambience_lowpass_config()
	if not bool(cfg.get("enabled_for_precipitation", false)):
		return
	var bus_name: String = str(cfg.get("bus_name", "Ambience"))
	var slot: int = int(cfg.get("effect_slot_index", 0))
	var dry: float = float(cfg.get("cutoff_hz_dry", 20500.0))
	var wet: float = float(cfg.get("cutoff_hz_wet", 4800.0))
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if AudioServer.get_bus_effect_count(idx) <= slot:
		return
	AudioServer.set_bus_effect_enabled(idx, slot, active)
	var eff: AudioEffect = AudioServer.get_bus_effect(idx, slot)
	if eff is AudioEffectLowPassFilter:
		(eff as AudioEffectLowPassFilter).cutoff_hz = wet if active else dry
