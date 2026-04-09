extends Node

enum WeatherType {
	SUNNY,
	RAIN,
	STORM,
	SNOW,
	WINDY,
	OVERCAST
}

var current_weather = WeatherType.SUNNY
var weather_duration = 0
var weather_timer = 0

signal weather_changed(new_weather)

var rain_particles: Node = null
var snow_particles: Node = null

func _ready() -> void:
	# Autoload has no scene children; optional RainParticles/SnowParticles from instanced scenes only.
	rain_particles = get_node_or_null("RainParticles")
	snow_particles = get_node_or_null("SnowParticles")
	_set_particles_emitting(rain_particles, false)
	_set_particles_emitting(snow_particles, false)
	randomize_weather()

func _process(delta: float) -> void:
	weather_timer -= delta

	if weather_timer <= 0:
		change_weather()

func randomize_weather() -> void:
	current_weather = randi() % 6
	weather_duration = randf_range(60.0, 300.0)  # 1-5 minutes
	weather_timer = weather_duration
	update_weather_effects()

func change_weather() -> void:
	var old_weather = current_weather
	randomize_weather()

	if current_weather != old_weather:
		weather_changed.emit(current_weather)

func update_weather_effects() -> void:
	match current_weather:
		WeatherType.RAIN:
			_set_particles_emitting(rain_particles, true)
			_set_particles_emitting(snow_particles, false)
		WeatherType.STORM:
			_set_particles_emitting(rain_particles, true)
			_set_particles_emitting(snow_particles, false)
		WeatherType.SNOW:
			_set_particles_emitting(rain_particles, false)
			_set_particles_emitting(snow_particles, true)
		_:
			_set_particles_emitting(rain_particles, false)
			_set_particles_emitting(snow_particles, false)

func _set_particles_emitting(node: Node, on: bool) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is GPUParticles2D:
		(node as GPUParticles2D).emitting = on
	elif node is CPUParticles2D:
		(node as CPUParticles2D).emitting = on

func get_weather_name() -> String:
	match current_weather:
		WeatherType.SUNNY:
			return "Sunny"
		WeatherType.RAIN:
			return "Rain"
		WeatherType.STORM:
			return "Storm"
		WeatherType.SNOW:
			return "Snow"
		WeatherType.WINDY:
			return "Windy"
		WeatherType.OVERCAST:
			return "Overcast"
	return "Unknown"

func is_raining() -> bool:
	return current_weather == WeatherType.RAIN or current_weather == WeatherType.STORM

func affects_crops() -> bool:
	return is_raining()
