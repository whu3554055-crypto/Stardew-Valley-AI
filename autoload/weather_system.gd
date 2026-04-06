extends Node2D

class_name WeatherSystem

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

@onready var rain_particles = $RainParticles
@onready var snow_particles = $SnowParticles

func _ready():
	rain_particles.emitting = false
	snow_particles.emitting = false
	randomize_weather()

func _process(delta):
	weather_timer -= delta

	if weather_timer <= 0:
		change_weather()

func randomize_weather():
	current_weather = randi() % 6
	weather_duration = randf_range(60.0, 300.0)  # 1-5 minutes
	weather_timer = weather_duration
	update_weather_effects()

func change_weather():
	var old_weather = current_weather
	randomize_weather()

	if current_weather != old_weather:
		weather_changed.emit(current_weather)

func update_weather_effects():
	match current_weather:
		WeatherType.RAIN:
			rain_particles.emitting = true
			snow_particles.emitting = false
		WeatherType.STORM:
			rain_particles.emitting = true
			snow_particles.emitting = false
		WeatherType.SNOW:
			rain_particles.emitting = false
			snow_particles.emitting = true
		_:
			rain_particles.emitting = false
			snow_particles.emitting = false

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
	# Rain automatically waters crops
	return is_raining()
