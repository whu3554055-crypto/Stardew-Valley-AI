extends Node

## Season (Music) + weather / region / night crickets (Ambience). Region follows player position.

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

## Location loops (farm uses gentle stream — farm_animals asset not shipped).
const PATH_REGION := {
	"forest": "res://assets/audio/locations/forest_birds.ogg",
	"beach": "res://assets/audio/locations/beach_waves.ogg",
	"river": "res://assets/audio/ambience_extended/river_flow.wav",
	"town": "res://assets/audio/locations/town_crowd.ogg",
	"farm": "res://assets/audio/ambience_extended/stream_gentle.wav",
}

const PATH_NIGHT_CRICKETS := "res://assets/audio/ambience_extended/crickets_night.wav"

var _season_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer
var _region_player: AudioStreamPlayer
var _night_player: AudioStreamPlayer

var _poll_accum: float = 0.0
const REGION_POLL_SEC := 0.4
var _last_region_key: String = "__init__"

func _ready() -> void:
	_season_player = _make_player("SeasonBed", "Music", -10.0)
	_weather_player = _make_player("WeatherLayer", "Ambience", -14.0)
	_region_player = _make_player("RegionLayer", "Ambience", -16.0)
	_night_player = _make_player("NightCrickets", "Ambience", -18.0)
	add_child(_season_player)
	add_child(_weather_player)
	add_child(_region_player)
	add_child(_night_player)
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

func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum < REGION_POLL_SEC:
		return
	_poll_accum = 0.0
	if get_tree().current_scene == null:
		return
	_apply_region_layer(_get_player_position())

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
	_apply_day_night_layer()

func _on_season_changed(_season: String) -> void:
	_apply_season_bed()

func _on_day_changed(_day: int) -> void:
	_apply_season_bed()

func _on_game_time_changed(_t: float) -> void:
	_apply_day_night_layer()

func _refresh_all() -> void:
	_apply_season_bed()
	_apply_weather_layer()
	var pos: Vector2 = _get_player_position()
	if pos != Vector2.ZERO:
		_apply_region_layer(pos, true)
	_apply_day_night_layer()

func _apply_season_bed() -> void:
	if not GameManager:
		return
	var s: String = str(GameManager.player_data.get("season", "spring")).to_lower()
	var path: String = PATH_SEASON.get(s, PATH_SEASON["spring"])
	_play_loop_stream(_season_player, path)

func _apply_weather_layer() -> void:
	if not WeatherSystem:
		return
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.RAIN:
			_play_loop_stream(_weather_player, PATH_WEATHER["rain"])
		WeatherSystem.WeatherType.STORM:
			_play_loop_stream(_weather_player, PATH_WEATHER["storm"])
		WeatherSystem.WeatherType.SNOW:
			_play_loop_stream(_weather_player, PATH_WEATHER["snow_wind"])
		_:
			_stop_stream(_weather_player)

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

func _resolve_region_ambient_key(pos: Vector2) -> String:
	if GameZones.contains_forest(pos):
		return "forest"
	if FishingSystem:
		var fz: String = FishingSystem.get_fish_zone(pos)
		if fz == "ocean":
			return "beach"
		if fz == "river":
			return "river"
	if FarmTierCatalog and FarmTierCatalog.get_farm_upgrade_rect().has_point(pos):
		return "farm"
	if GameZones.rect_near_pierre().has_point(pos):
		return "town"
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
