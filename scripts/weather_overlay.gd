extends CanvasLayer

## Full-screen rain / snow + optional lightning flash during storms.

var _rain: CPUParticles2D
var _snow: CPUParticles2D
var _flash: ColorRect
var _storm_timer: Timer

func _ready() -> void:
	layer = 85
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_rain = _make_rain()
	_snow = _make_snow()
	add_child(_rain)
	add_child(_snow)
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	call_deferred("_sync_weather")

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
			_rain.amount = 920 if storm else 560
			_rain.initial_velocity_min = 420.0 if storm else 300.0
			_rain.initial_velocity_max = 680.0 if storm else 520.0
			_snow.emitting = false
		WeatherSystem.WeatherType.SNOW:
			_rain.emitting = false
			_snow.emitting = true
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
	if WeatherSystem and WeatherSystem.current_weather == WeatherSystem.WeatherType.STORM:
		_storm_timer.start(randf_range(1.2, 4.0))

func _make_rain() -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(640, 360)
	p.z_index = 1
	p.emitting = false
	p.amount = 560
	p.lifetime = 0.7
	p.one_shot = false
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(660, 380)
	p.direction = Vector2(0.15, 1)
	p.spread = 12.0
	p.initial_velocity_min = 300.0
	p.initial_velocity_max = 520.0
	p.angular_velocity_min = 0.0
	p.angular_velocity_max = 0.0
	p.gravity = Vector2(140, 0)
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
	p.gravity = Vector2(18, 12)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.15
	p.color = Color(1, 1, 1, 0.78)
	return p
