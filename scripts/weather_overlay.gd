extends CanvasLayer

## Full-screen rain / snow + optional lightning flash during storms.
## Particle numbers: `data/presentation/immersion_config.json` → `particles`.

var _rain: CPUParticles2D
var _snow: CPUParticles2D
var _flash: ColorRect
var _storm_timer: Timer
var _thunder_player: AudioStreamPlayer

func _ready() -> void:
	layer = 85
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 12
	add_child(_flash)
	_storm_timer = Timer.new()
	_storm_timer.one_shot = true
	_storm_timer.timeout.connect(_on_storm_lightning_tick)
	add_child(_storm_timer)
	_thunder_player = AudioStreamPlayer.new()
	_thunder_player.bus = "SFX"
	_thunder_player.volume_db = -8.0
	add_child(_thunder_player)
	_rain = _make_rain()
	_snow = _make_snow()
	add_child(_rain)
	add_child(_snow)
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	call_deferred("_sync_weather")

func _pfloat(key: String, fb: float) -> float:
	return ImmersionConfig.get_particle(key, fb) if ImmersionConfig else fb

func _pint(key: String, fb: int) -> int:
	return ImmersionConfig.get_particle_int(key, fb) if ImmersionConfig else fb

func _on_weather_changed(_w: int) -> void:
	_sync_weather()

func _sync_weather() -> void:
	if not WeatherSystem:
		return
	var w = WeatherSystem.current_weather
	var storm: bool = w == WeatherSystem.WeatherType.STORM
	match w:
		WeatherSystem.WeatherType.RAIN, WeatherSystem.WeatherType.STORM:
			_rain.emitting = true
			var amt_n: int = _pint("particles.rain.amount_normal", 560)
			var amt_s: int = _pint("particles.rain.amount_storm", 920)
			_rain.amount = amt_s if storm else amt_n
			_rain.initial_velocity_min = _pfloat("particles.rain.vel_min_storm", 420.0) if storm else _pfloat("particles.rain.vel_min_normal", 300.0)
			_rain.initial_velocity_max = _pfloat("particles.rain.vel_max_storm", 680.0) if storm else _pfloat("particles.rain.vel_max_normal", 520.0)
			var dx_n: float = _pfloat("particles.rain.dir_x_normal", 0.15)
			var dx_s: float = _pfloat("particles.rain.dir_x_storm", 0.32)
			_rain.direction = Vector2(dx_s, 1.0) if storm else Vector2(dx_n, 1.0)
			var gx_n: float = _pfloat("particles.rain.grav_x_normal", 140.0)
			var gx_s: float = _pfloat("particles.rain.grav_x_storm", 220.0)
			_rain.gravity = Vector2(gx_s, 0.0) if storm else Vector2(gx_n, 0.0)
			var sp_n: float = _pfloat("particles.rain.spread_normal", 12.0)
			var sp_s: float = _pfloat("particles.rain.spread_storm", 18.0)
			_rain.spread = sp_s if storm else sp_n
			_snow.emitting = false
		WeatherSystem.WeatherType.SNOW:
			_rain.emitting = false
			_snow.emitting = true
			var sg: float = _pfloat("particles.snow.grav_x", 22.0)
			var sgy: float = _pfloat("particles.snow.grav_y", 14.0)
			var sdx: float = _pfloat("particles.snow.dir_x", 0.12)
			_snow.gravity = Vector2(sg, sgy)
			_snow.direction = Vector2(sdx, 1.0)
		_:
			_rain.emitting = false
			_snow.emitting = false
	if w == WeatherSystem.WeatherType.STORM:
		_start_storm_lightning()
	else:
		_stop_storm_lightning()

func _start_storm_lightning() -> void:
	if not _storm_timer.is_stopped():
		return
	_storm_timer.start(randf_range(1.4, 3.2))

func _stop_storm_lightning() -> void:
	_storm_timer.stop()
	if _flash:
		_flash.color = Color(1, 1, 1, 0)

func _on_storm_lightning_tick() -> void:
	if not WeatherSystem or WeatherSystem.current_weather != WeatherSystem.WeatherType.STORM:
		return
	_flash.color = Color(0.82, 0.88, 1.0, 0.22)
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_flash, "color", Color(1, 1, 1, 0), 0.11)
	var par: Node = get_parent()
	if par and par.has_method("play_screen_shake"):
		var st: float = 5.5
		if ImmersionConfig:
			st = ImmersionConfig.get_float("visual.screen_shake.strength_px", 5.5)
		par.play_screen_shake(st)
	_schedule_thunder_rumble()
	if WeatherSystem and WeatherSystem.current_weather == WeatherSystem.WeatherType.STORM:
		_storm_timer.start(randf_range(1.2, 4.0))

func _schedule_thunder_rumble() -> void:
	var cfg: Dictionary = ImmersionConfig.get_storm_sfx() if ImmersionConfig else {}
	var dmin: float = float(cfg.get("thunder_delay_min_sec", 0.08))
	var dmax: float = float(cfg.get("thunder_delay_max_sec", 0.42))
	var delay: float = randf_range(dmin, dmax)
	get_tree().create_timer(delay).timeout.connect(_play_thunder_rumble, CONNECT_ONE_SHOT)

func _play_thunder_rumble() -> void:
	if not WeatherSystem or WeatherSystem.current_weather != WeatherSystem.WeatherType.STORM:
		return
	if _thunder_player == null:
		return
	var cfg: Dictionary = ImmersionConfig.get_storm_sfx() if ImmersionConfig else {}
	var path: String = str(cfg.get("thunder_path", "res://assets/audio/ambience_extended/rain_heavy.wav"))
	if not ResourceLoader.exists(path):
		return
	var st: Resource = load(path)
	if not (st is AudioStream):
		return
	_thunder_player.stream = st as AudioStream
	if _thunder_player.stream is AudioStreamWAV:
		(_thunder_player.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_thunder_player.volume_db = float(cfg.get("thunder_volume_db", -8.0))
	var pmn: float = float(cfg.get("thunder_pitch_min", 0.82))
	var pmx: float = float(cfg.get("thunder_pitch_max", 1.05))
	_thunder_player.pitch_scale = randf_range(pmn, pmx)
	_thunder_player.play()

func _make_rain() -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(640, 360)
	p.z_index = 1
	p.emitting = false
	p.amount = _pint("particles.rain.amount_normal", 560)
	p.lifetime = 0.7
	p.one_shot = false
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(660, 380)
	var dx: float = _pfloat("particles.rain.dir_x_normal", 0.15)
	p.direction = Vector2(dx, 1)
	p.spread = _pfloat("particles.rain.spread_normal", 12.0)
	p.initial_velocity_min = _pfloat("particles.rain.vel_min_normal", 300.0)
	p.initial_velocity_max = _pfloat("particles.rain.vel_max_normal", 520.0)
	p.angular_velocity_min = 0.0
	p.angular_velocity_max = 0.0
	p.gravity = Vector2(_pfloat("particles.rain.grav_x_normal", 140.0), 0)
	p.scale_amount_min = 0.45
	p.scale_amount_max = 1.0
	p.color = Color(0.72, 0.82, 1.0, 0.55)
	return p

func _make_snow() -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(640, 360)
	p.z_index = 1
	p.emitting = false
	p.amount = 420
	p.lifetime = 2.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(660, 380)
	p.direction = Vector2(0.1, 1)
	p.spread = 68.0
	p.initial_velocity_min = 35.0
	p.initial_velocity_max = 90.0
	var gx: float = _pfloat("particles.snow.grav_x", 22.0)
	var gy: float = _pfloat("particles.snow.grav_y", 14.0)
	p.gravity = Vector2(gx, gy)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.15
	p.color = Color(1, 1, 1, 0.78)
	return p
