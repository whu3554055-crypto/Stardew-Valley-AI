extends Node

## Season (Music) + weather / region / night crickets (Ambience). Region follows player position.
## Dawn one-shot birds + gentle day/night volume on the season bed.
## Tuning: `res://data/presentation/immersion_config.json` (ImmersionConfig autoload).

const _FB_SEASON := {
	"spring": "res://assets/audio/ambience_extended/birds_forest.wav",
	"summer": "res://assets/audio/ambience_extended/birds_forest.wav",
	"fall": "res://assets/audio/ambience_extended/leaves_rustle.wav",
	"winter": "res://assets/audio/ambience_extended/wind_trees.wav",
}

var _season_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer
var _windy_player: AudioStreamPlayer
var _region_player: AudioStreamPlayer
var _night_player: AudioStreamPlayer
var _morning_player: AudioStreamPlayer

var _poll_accum: float = 0.0
var _last_region_sample_pos: Vector2 = Vector2(1e12, 1e12)
var _last_region_key: String = "__init__"
var _last_morning_chirp_key: int = -1
var _activity_duck_sec: float = 0.0
var _season_crossfade_active: bool = false
var _season_crossfade_tween: Tween = null

func _ready() -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		return
	var sdb: float = _lvl("audio.levels.season_db_day", -10.0)
	_season_player = _make_player("SeasonBed", "Music", sdb)
	_weather_player = _make_player("WeatherLayer", "Ambience", -14.0)
	_windy_player = _make_player("WindyLayer", "Ambience", -14.5)
	var rday: float = _lvl("audio.levels.region_db_day", -16.0)
	_region_player = _make_player("RegionLayer", "Ambience", rday)
	_night_player = _make_player("NightCrickets", "Ambience", -18.0)
	_morning_player = _make_player("MorningBirds", "Ambience", -14.0)
	_morning_player.volume_db = -14.0
	add_child(_season_player)
	add_child(_weather_player)
	add_child(_windy_player)
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
	call_deferred("_connect_world_router_ambient_refresh")


func _on_tree_exiting_stop_audio() -> void:
	_kill_season_crossfade_tween()
	for p in [_season_player, _weather_player, _windy_player, _region_player, _night_player, _morning_player]:
		if p:
			_stop_stream(p)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_on_tree_exiting_stop_audio()


func _connect_world_router_ambient_refresh() -> void:
	if WorldRouter and not WorldRouter.world_changed.is_connected(_on_world_router_scene_changed):
		WorldRouter.world_changed.connect(_on_world_router_scene_changed)


func _on_world_router_scene_changed(_scene_path: String) -> void:
	_last_region_sample_pos = Vector2(1e12, 1e12)
	call_deferred("_refresh_all")


func _exit_tree() -> void:
	_on_tree_exiting_stop_audio()

func _lvl(path: String, fb: float) -> float:
	return ImmersionConfig.get_float(path, fb) if ImmersionConfig else fb

func request_activity_duck(duration_sec: float = 1.0) -> void:
	_activity_duck_sec = maxf(_activity_duck_sec, duration_sec)

func _process(delta: float) -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		return
	if _activity_duck_sec > 0.0:
		_activity_duck_sec = maxf(0.0, _activity_duck_sec - delta)
	_apply_ambient_volume_modifiers()
	_apply_season_volume_mix()

	var poll_max: float = _lvl("audio.levels.region_poll_max_sec", 0.5)
	var move_min: float = _lvl("audio.levels.region_move_min_px", 48.0)
	_poll_accum += delta
	if get_tree().current_scene == null:
		return
	var pos: Vector2 = _get_player_position()
	var moved_far: bool = _last_region_sample_pos.distance_to(pos) >= move_min
	if _poll_accum < poll_max and not moved_far:
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
	_sync_ambience_lowpass()

func _on_season_changed(_season: String) -> void:
	_begin_season_crossfade_if_needed()

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
	_sync_ambience_lowpass()

func _season_db_day() -> float:
	return _lvl("audio.levels.season_db_day", -10.0)

func _season_db_night() -> float:
	return _lvl("audio.levels.season_db_night", -13.0)

func _region_db_day() -> float:
	return _lvl("audio.levels.region_db_day", -16.0)

func _region_db_night() -> float:
	return _lvl("audio.levels.region_db_night", -17.5)

func _activity_duck_db() -> float:
	return _lvl("audio.levels.activity_duck_db", 2.5)

func _indoor_duck_db() -> float:
	return _lvl("audio.levels.indoor_duck_db", 2.0)

func _resolve_season_stream_path() -> String:
	if not GameManager:
		return ""
	var s: String = str(GameManager.player_data.get("season", "spring")).to_lower()
	var path: String = ImmersionConfig.get_season_audio_path(s) if ImmersionConfig else ""
	if path.is_empty():
		path = _FB_SEASON.get(s, _FB_SEASON["spring"])
	return path

func _apply_season_bed() -> void:
	var path: String = _resolve_season_stream_path()
	if path.is_empty():
		return
	_play_loop_stream(_season_player, path)
	_apply_season_volume_mix()

func _kill_season_crossfade_tween() -> void:
	if _season_crossfade_tween and is_instance_valid(_season_crossfade_tween):
		_season_crossfade_tween.kill()
	_season_crossfade_tween = null
	if _season_crossfade_active:
		_season_crossfade_active = false
		call_deferred("_apply_season_volume_mix")

func _begin_season_crossfade_if_needed() -> void:
	_kill_season_crossfade_tween()
	if not _season_player or not GameManager:
		return
	var fade_out: float = _lvl("audio.season_crossfade.fade_out_sec", 0.28)
	var fade_in: float = _lvl("audio.season_crossfade.fade_in_sec", 0.42)
	var path: String = _resolve_season_stream_path()
	if path.is_empty():
		return
	if fade_out <= 0.0 and fade_in <= 0.0:
		_apply_season_bed()
		return
	if _season_player.stream == null:
		_apply_season_bed()
		return
	var duck_db: float = _lvl("audio.season_crossfade.duck_db_during", -38.0)
	_season_crossfade_active = true
	var tw: Tween = create_tween()
	_season_crossfade_tween = tw
	tw.set_parallel(false)
	tw.tween_property(_season_player, "volume_db", duck_db, fade_out).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_season_crossfade_swap_stream.bind(path, duck_db))
	var target_db: float = _compute_season_final_output_db()
	tw.tween_property(_season_player, "volume_db", target_db, fade_in).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_on_season_crossfade_complete)

func _season_crossfade_swap_stream(path: String, duck_db: float) -> void:
	_play_loop_stream(_season_player, path)
	if _season_player:
		_season_player.volume_db = duck_db

func _on_season_crossfade_complete() -> void:
	_season_crossfade_active = false
	_season_crossfade_tween = null
	_apply_season_volume_mix()

func _compute_season_volume_db() -> float:
	if not GameManager:
		return _season_db_day() + _weather_music_offset_db()
	var t: float = GameManager.current_time
	var sday: float = _season_db_day()
	var snight: float = _season_db_night()
	var base: float
	if _is_night_hours(t):
		base = snight
	elif t >= 6.0 and t < 7.5:
		var k: float = clampf((t - 6.0) / 1.5, 0.0, 1.0)
		base = lerpf(snight, sday, k)
	elif t >= 19.0 and t < 20.0:
		var k2: float = clampf((t - 19.0) / 1.0, 0.0, 1.0)
		base = lerpf(sday, snight, k2)
	else:
		base = sday
	return base + _weather_music_offset_db()

func _weather_music_offset_db() -> float:
	if not WeatherSystem or not ImmersionConfig:
		return 0.0
	return ImmersionConfig.get_music_offset_db_for_weather(WeatherSystem.current_weather)

func _weather_music_pitch() -> float:
	if not WeatherSystem or not ImmersionConfig:
		return 1.0
	return ImmersionConfig.get_music_pitch_for_weather(WeatherSystem.current_weather)

func _compute_season_final_output_db() -> float:
	var db: float = _compute_season_volume_db()
	var pos: Vector2 = _get_player_position()
	if GameZones.is_indoor_station(pos):
		db -= _indoor_duck_db()
	if _activity_duck_sec > 0.0:
		db -= _activity_duck_db()
	return db

func _apply_season_volume_mix() -> void:
	if _season_crossfade_active:
		return
	if not _season_player:
		return
	if _season_player.stream == null:
		return
	var db: float = _compute_season_final_output_db()
	_season_player.volume_db = db
	_season_player.pitch_scale = _weather_music_pitch()

func _apply_ambient_volume_modifiers() -> void:
	if not GameManager:
		return
	var night: bool = _is_night_hours(GameManager.current_time)
	var base_r: float = _region_db_night() if night else _region_db_day()
	var pos: Vector2 = _get_player_position()
	if GameZones.is_indoor_station(pos):
		base_r -= _indoor_duck_db()
	if _activity_duck_sec > 0.0:
		base_r -= _activity_duck_db()
	if _region_player.playing:
		_region_player.volume_db = base_r
	if _weather_player.playing:
		var vb: float = float(_weather_player.get_meta("wa_vol_base", -14.0))
		if GameZones.is_indoor_station(pos):
			vb -= _indoor_duck_db()
		if _activity_duck_sec > 0.0:
			vb -= _activity_duck_db()
		_weather_player.volume_db = vb
	if _windy_player.playing:
		var vbw: float = float(_windy_player.get_meta("wa_vol_base", -14.5))
		if GameZones.is_indoor_station(pos):
			vbw -= _indoor_duck_db()
		if _activity_duck_sec > 0.0:
			vbw -= _activity_duck_db()
		_windy_player.volume_db = vbw

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
	var path_m: String = ImmersionConfig.get_one_shot_path("morning_birds") if ImmersionConfig else ""
	if path_m.is_empty():
		path_m = "res://assets/audio/ambience_extended/birds_morning.wav"
	if not ResourceLoader.exists(path_m):
		return
	if _morning_player.playing:
		return
	var stream: AudioStream = load(path_m) as AudioStream
	if stream == null:
		return
	# Use an uncached copy for one-shot playback to avoid lingering shared refs at shutdown.
	stream = stream.duplicate(true)
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_last_morning_chirp_key = k
	_morning_player.stop()
	_morning_player.stream = null
	_morning_player.stream = stream
	_morning_player.volume_db = -13.5
	_morning_player.play()

func _apply_weather_layer() -> void:
	if not WeatherSystem:
		return
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.RAIN:
			_stop_stream(_windy_player)
			var pr: String = ImmersionConfig.get_weather_audio_path("rain") if ImmersionConfig else ""
			if pr.is_empty():
				pr = "res://assets/audio/ambience_extended/rain_light.wav"
			_play_loop_stream(_weather_player, pr)
			var vbr: float = ImmersionConfig.get_weather_vol_base_db("rain") if ImmersionConfig else -13.5
			_weather_player.set_meta("wa_vol_base", vbr)
		WeatherSystem.WeatherType.STORM:
			_stop_stream(_windy_player)
			var ps: String = ImmersionConfig.get_weather_audio_path("storm") if ImmersionConfig else ""
			if ps.is_empty():
				ps = "res://assets/audio/ambience_extended/rain_heavy.wav"
			_play_loop_stream(_weather_player, ps)
			var vbs: float = ImmersionConfig.get_weather_vol_base_db("storm") if ImmersionConfig else -11.5
			_weather_player.set_meta("wa_vol_base", vbs)
		WeatherSystem.WeatherType.SNOW:
			_stop_stream(_windy_player)
			var psw: String = ImmersionConfig.get_weather_audio_path("snow_wind") if ImmersionConfig else ""
			if psw.is_empty():
				psw = "res://assets/audio/ambience_extended/wind_trees.wav"
			_play_loop_stream(_weather_player, psw)
			var vbws: float = ImmersionConfig.get_weather_vol_base_db("snow") if ImmersionConfig else -14.0
			_weather_player.set_meta("wa_vol_base", vbws)
		WeatherSystem.WeatherType.WINDY:
			_stop_stream(_weather_player)
			var pw: String = ImmersionConfig.get_weather_audio_path("windy") if ImmersionConfig else ""
			if pw.is_empty():
				pw = "res://assets/audio/ambience_extended/leaves_rustle.wav"
			_play_loop_stream(_windy_player, pw)
			var vbwy: float = ImmersionConfig.get_weather_vol_base_db("windy") if ImmersionConfig else -14.5
			_windy_player.set_meta("wa_vol_base", vbwy)
		_:
			_stop_stream(_weather_player)
			_stop_stream(_windy_player)
	_apply_ambient_volume_modifiers()

func _sync_ambience_lowpass() -> void:
	if not ImmersionConfig or not WeatherSystem:
		return
	var w: int = WeatherSystem.current_weather
	var precip: bool = (
		w == WeatherSystem.WeatherType.RAIN
		or w == WeatherSystem.WeatherType.STORM
		or w == WeatherSystem.WeatherType.SNOW
	)
	ImmersionConfig.apply_ambience_lowpass_for_precipitation(precip)

func _apply_region_layer(pos: Vector2, force: bool = false) -> void:
	var key: String = _resolve_region_ambient_key(pos)
	if not force and key == _last_region_key:
		return
	_last_region_key = key
	if key == "default":
		_stop_stream(_region_player)
		return
	var path: String = ImmersionConfig.get_region_audio_path(key) if ImmersionConfig else ""
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
	if GameZones.can_open_shop_at(pos):
		return "town"
	if GameZones.contains_farm_upgrade_zone(pos):
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
		var path_n: String = ImmersionConfig.get_one_shot_path("night_crickets") if ImmersionConfig else ""
		if path_n.is_empty():
			path_n = "res://assets/audio/ambience_extended/crickets_night.wav"
		_play_loop_stream(_night_player, path_n)
	else:
		_stop_stream(_night_player)

func _play_loop_stream(player: AudioStreamPlayer, path: String) -> void:
	if path.is_empty():
		_stop_stream(player)
		return
	if player.get_meta("wa_path", "") == path and player.playing:
		return
	# Guard both the import map and the source file to avoid noisy load errors.
	if not ResourceLoader.exists(path) or not FileAccess.file_exists(path):
		push_warning("[WorldAmbient] Missing audio: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("[WorldAmbient] Failed to decode audio stream: %s" % path)
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
	# Fully detach previous playback first to prevent lingering WAV playback refs.
	player.stop()
	player.stream = null
	player.set_meta("wa_path", path)
	player.stream = stream
	player.play()

func _stop_stream(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
	if player.has_meta("wa_path"):
		player.remove_meta("wa_path")
	if (player == _weather_player or player == _windy_player) and player.has_meta("wa_vol_base"):
		player.remove_meta("wa_vol_base")
