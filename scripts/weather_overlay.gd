extends CanvasLayer

## Full-screen rain / snow driven by WeatherSystem (visual layer only).

var _rain: CPUParticles2D
var _snow: CPUParticles2D

func _ready() -> void:
	layer = 85
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
