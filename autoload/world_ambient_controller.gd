extends Node

## Season (Music) + weather / region / night crickets (Ambience). Region follows player position.
## Dawn one-shot birds + gentle day/night volume on the season bed.

const PATH_SEASON := {
	"spring": "res://assets/audio/ambience/spring.ogg",
	"summer": "res://assets/audio/ambience/summer.ogg",
	"fall": "res://assets/audio/ambience/fall.ogg",
	"winter": "res://assets/audio/ambience/winter.ogg",
}

const PATH_WEATHER := {
	"rain": "res://assets/audio/ambience/rain.ogg",
	"storm": "res://assets/audio/ambience/storm.ogg",
	"snow_wind": "res://assets/audio/ambience_extended/wind_trees.wav",
}

const PATH_REGION := {
	"forest": "res://assets/audio/locations/forest_birds.ogg",
	"beach": "res://assets/audio/locations/beach_waves.ogg",
	"river": "res://assets/audio/ambience_extended/river_flow.wav",
	"town": "res://assets/audio/locations/town_crowd.ogg",
	"farm": "res://assets/audio/ambience_extended/stream_gentle.wav",
}

const PATH_NIGHT_CRICKETS := "res://assets/audio/ambience_extended/crickets_night.wav"
const PATH_MORNING_BIRDS := "res://assets/audio/ambience_extended/birds_morning.wav"

const SEASON_DB_DAY := -10.0
const SEASON_DB_NIGHT := -13.0
const REGION_DB_DAY := -16.0
const REGION_DB_NIGHT := -17.5

var _season_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer
var _region_player: AudioStreamPlayer
var _night_player: AudioStreamPlayer
var _morning_player: AudioStreamPlayer

var _poll_accum: float = 0.0
const REGION_POLL_MAX := 0.5
const REGION_MOVE_MIN := 48.0
var _last_region_sample_pos: Vector2 = Vector2(1e12, 1e12)
var _last_region_key: String = "__init__"
var _last_morning_chirp_key: int = -1
var _activity_duck_sec: float = 0.0
const ACTIVITY_DUCK_DB := 2.5
const INDOOR_DUCK_DB := 2.0

func _ready() -> void:
	_season_player = _make_player("SeasonBed", "Music", SEASON_DB_DAY)
	_weather_player = _make_player("WeatherLayer", "Ambience", -14.0)
	_region_player = _make_player("RegionLayer", "Ambience", REGION_DB_DAY)
	_night_player = _make_player("NightCrickets", "Ambience", -18.0)
	_morning_player = _make_player("MorningBirds", "Ambience", -14.0)
	_morning_player.volume_db = -14.0
	add_child(_season_player)
	add_child(_weather_player)
	add_child(_region_player)
	add_child(_night_player)
	add_child(_morning_player)
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	if GameManager:
		if not GameManager.season_changed.is_connected(_on_season_changed):
			GameManager.season_changed.connect(_on_season_changed)
		if not GameManager.day_changed.is_connected(_on_day_changed):
			GameManager.day_changed.connect(_on_day_changed)
		if not GameManager.time_changed.is_connected(_on_game_time_changed):
			GameManager.time_changed.connect(_on_game_time_changed)
	call_deferred("_refresh_all")

func request_activity_duck(duration_sec: float = 1.0) -> void:
	_activity_duck_sec = maxf(_activity_duck_sec, duration_sec)

func _process(delta: float) -> void:
	if _activity_duck_sec > 0.0:
		_activity_duck_sec = maxf(0.0, _activity_duck_sec - delta)
	_apply_ambient_volume_modifiers()

	_poll_accum += delta
	if get_tree().current_scene == null:
		return
	var pos: Vector2 = _get_player_position()
	var moved_far: bool = _last_region_sample_pos.distance_to(pos) >= REGION_MOVE_MIN
	if _poll_accum < REGION_POLL_MAX and not moved_far:
		return
	_poll_accum = 0.0
	_last_region_sample_pos = pos
	_apply_region_layer(pos)

func _make_player(node_name: String, bus_name: String, vol_db: float) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = node_name
	p.bus = bus_name
	p.volume_db = vol_db
	return p

func _get_player_position() -> Vector2:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return Vector2.ZERO
	var pl: Node = scene.get_node_or_null("Player")
	if pl:
		return pl.global_position
	return Vector2.ZERO

func _on_weather_changed(_new_weather: int) -> void:
	_apply_weather_layer()
	_apply_season_volume_mix()
	_apply_day_night_layer()

func _on_season_changed(_season: String) -> void:
	_apply_season_bed()

func _on_day_changed(_day: int) -> void:
	_apply_season_bed()

func _on_game_time_changed(_t: float) -> void:
	_try_morning_birds_one_shot()
	_apply_season_volume_mix()
	_apply_ambient_volume_modifiers()
	_apply_day_night_layer()

func _refresh_all() -> void:
	_apply_season_bed()
	_apply_weather_layer()
	var pos: Vector2 = _get_player_position()
	if pos != Vector2.ZERO:
		_apply_region_layer(pos, true)
	_apply_season_volume_mix()
	_apply_ambient_volume_modifiers()
	_apply_day_night_layer()

func _apply_season_bed() -> void:
	if not GameManager:
		return
	var s: String = str(GameManager.player_data.get("season", "spring")).to_lower()
	var path: String = PATH_SEASON.get(s, PATH_SEASON["spring"])
	_play_loop_stream(_season_player, path)
	_apply_season_volume_mix()

func _compute_season_volume_db() -> float:
	if not GameManager:
		return SEASON_DB_DAY + _weather_music_offset_db()
	var t: float = GameManager.current_time
	var base: float
	if _is_night_hours(t):
		base = SEASON_DB_NIGHT
	elif t >= 6.0 and t < 7.5:
		var k: float = clampf((t - 6.0) / 1.5, 0.0, 1.0)
		base = lerpf(SEASON_DB_NIGHT, SEASON_DB_DAY, k)
	elif t >= 19.0 and t < 20.0:
		var k2: float = clampf((t - 19.0) / 1.0, 0.0, 1.0)
		base = lerpf(SEASON_DB_DAY, SEASON_DB_NIGHT, k2)
	else:
		base = SEASON_DB_DAY
	return base + _weather_music_offset_db()

func _weather_music_offset_db() -> float:
	if not WeatherSystem:
		return 0.0
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.SUNNY:
			return 0.0
		WeatherSystem.WeatherType.OVERCAST, WeatherSystem.WeatherType.WINDY:
			return -1.5
		WeatherSystem.WeatherType.RAIN:
			return -2.5
		WeatherSystem.WeatherType.STORM:
			return -3.5
		WeatherSystem.WeatherType.SNOW:
			return -2.0
	return 0.0

func _weather_music_pitch() -> float:
	if not WeatherSystem:
		return 1.0
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.SUNNY:
			return 1.0
		WeatherSystem.WeatherType.OVERCAST, WeatherSystem.WeatherType.WINDY:
			return 0.993
		WeatherSystem.WeatherType.RAIN:
			return 0.982
		WeatherSystem.WeatherType.STORM:
			return 0.971
		WeatherSystem.WeatherType.SNOW:
			return 0.986
	return 1.0

func _apply_season_volume_mix() -> void:
	if not _season_player:
		return
	if _season_player.stream == null:
		return
	_season_player.volume_db = _compute_season_volume_db()
	_season_player.pitch_scale = _weather_music_pitch()

func _apply_ambient_volume_modifiers() -> void:
	if not GameManager:
		return
	var night: bool = _is_night_hours(GameManager.current_time)
	var base_r: float = REGION_DB_NIGHT if night else REGION_DB_DAY
	var pos: Vector2 = _get_player_position()
	if GameZones.is_indoor_station(pos):
		base_r -= INDOOR_DUCK_DB
	if _activity_duck_sec > 0.0:
		base_r -= ACTIVITY_DUCK_DB
	if _region_player.playing:
		_region_player.volume_db = base_r
	if _weather_player.playing:
		var vb: float = float(_weather_player.get_meta("wa_vol_base", -14.0))
		if GameZones.is_indoor_station(pos):
			vb -= INDOOR_DUCK_DB
		if _activity_duck_sec > 0.0:
			vb -= ACTIVITY_DUCK_DB
		_weather_player.volume_db = vb

func _morning_chirp_key() -> int:
	if not GameManager:
		return 0
	var y: int = int(GameManager.player_data.get("year", 1))
	var d: int = int(GameManager.player_data.get("day", 1))
	return y * 10000 + d

func _should_skip_morning_birds() -> bool:
	if not WeatherSystem:
		return false
	if WeatherSystem.is_raining():
		return true
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.STORM, WeatherSystem.WeatherType.SNOW:
			return true
		_:
			return false

func _try_morning_birds_one_shot() -> void:
	if not GameManager:
		return
	var t: float = GameManager.current_time
	if t < 6.0 or t >= 6.5:
		return
	var k: int = _morning_chirp_key()
	if k == _last_morning_chirp_key:
		return
	if _should_skip_morning_birds():
		return
	if not ResourceLoader.exists(PATH_MORNING_BIRDS):
		return
	if _morning_player.playing:
		return
	var stream: AudioStream = load(PATH_MORNING_BIRDS) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_last_morning_chirp_key = k
	_morning_player.stream = stream
	_morning_player.volume_db = -13.5
	_morning_player.play()

func _apply_weather_layer() -> void:
	if not WeatherSystem:
		return
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.RAIN:
			_play_loop_stream(_weather_player, PATH_WEATHER["rain"])
			_weather_player.set_meta("wa_vol_base", -13.5)
		WeatherSystem.WeatherType.STORM:
			_play_loop_stream(_weather_player, PATH_WEATHER["storm"])
			_weather_player.set_meta("wa_vol_base", -11.5)
		WeatherSystem.WeatherType.SNOW:
			_play_loop_stream(_weather_player, PATH_WEATHER["snow_wind"])
			_weather_player.set_meta("wa_vol_base", -14.0)
		_:
			_stop_stream(_weather_player)
	_apply_ambient_volume_modifiers()

func _apply_region_layer(pos: Vector2, force: bool = false) -> void:
	var key: String = _resolve_region_ambient_key(pos)
	if not force and key == _last_region_key:
		return
	_last_region_key = key
	if key == "default":
		_stop_stream(_region_player)
		return
	var path: String = PATH_REGION.get(key, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_stop_stream(_region_player)
		return
	_play_loop_stream(_region_player, path)
	_apply_ambient_volume_modifiers()

func _resolve_region_ambient_key(pos: Vector2) -> String:
	if GameZones.contains_forest(pos):
		return "forest"
	if FishingSystem:
		var fz: String = FishingSystem.get_fish_zone(pos)
		if fz == "ocean":
			return "beach"
		if fz == "river":
			return "river"
	if GameZones.rect_near_pierre().has_point(pos):
		return "town"
	if FarmTierCatalog and FarmTierCatalog.get_farm_upgrade_rect().has_point(pos):
		return "farm"
	return "default"

func _is_night_hours(t: float) -> bool:
	return t < 6.0 or t >= 20.0

func _is_storm_weather() -> bool:
	return WeatherSystem and WeatherSystem.current_weather == WeatherSystem.WeatherType.STORM

func _apply_day_night_layer() -> void:
	if not GameManager:
		return
	var want_night: bool = _is_night_hours(GameManager.current_time)
	if want_night and _is_storm_weather():
		want_night = false
	if want_night:
		_play_loop_stream(_night_player, PATH_NIGHT_CRICKETS)
	else:
		_stop_stream(_night_player)

func _play_loop_stream(player: AudioStreamPlayer, path: String) -> void:
	if path.is_empty():
		_stop_stream(player)
		return
	if player.get_meta("wa_path", "") == path and player.playing:
		return
	if not ResourceLoader.exists(path):
		push_warning("[WorldAmbient] Missing audio: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
	player.set_meta("wa_path", path)
	player.stream = stream
	player.play()

func _stop_stream(player: AudioStreamPlayer) -> void:
	player.stop()
	if player.has_meta("wa_path"):
		player.remove_meta("wa_path")
	if player == _weather_player and player.has_meta("wa_vol_base"):
		player.remove_meta("wa_vol_base")
