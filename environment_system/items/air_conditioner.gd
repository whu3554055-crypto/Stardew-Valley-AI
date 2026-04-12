## Air Conditioner Environment Item
## Provides cooling and humidity control with energy consumption

extends EnvironmentItem
class_name AirConditioner


func _ready() -> void:
	"""Initialize air conditioner with default configuration."""
	item_id = "air_conditioner" if item_id.is_empty() else item_id
	item_name = "Air Conditioner" if item_name.is_empty() else item_name
	description = "An air conditioner that cools and dehumidifies the air"
	category = "cooling"

	# Base environmental effects
	temperature_delta = -6.0
	humidity_delta = -5.0
	light_radius = 0.0
	light_intensity = 0.0
	comfort_bonus = 5.0
	aesthetic_value = 2.0

	# Operational parameters
	requires_energy = true
	energy_consumption_rate = 3.5  # Energy units per hour (high consumption)
	max_energy_capacity = 100.0
	current_energy = 100.0

	# Durability system
	has_durability = true
	max_durability = 800
	current_durability = 800
	durability_degradation_rate = 0.3  # Per hour of use

	# Proximity detection
	proximity_radius = 250.0
	triggers_on_proximity = true  # Auto-activate when player nearby

	# Seasonal modifiers (more effective in summer, less needed in winter)
	_season_modifiers = {
		"summer": {
			"temperature_multiplier": 1.4,
			"comfort_multiplier": 1.3,
			"efficiency_multiplier": 1.2
		},
		"spring": {
			"temperature_multiplier": 1.0,
			"comfort_multiplier": 1.0
		},
		"fall": {
			"temperature_multiplier": 0.9,
			"comfort_multiplier": 0.9
		},
		"winter": {
			"temperature_multiplier": 0.6,
			"comfort_multiplier": 0.7
		}
	}

	# Weather modifiers
	_weather_modifiers = {
		"sunny": {
			"temperature_modifier": -1.0,
			"efficiency_multiplier": 1.1
		},
		"cloudy": {
			"efficiency_multiplier": 1.0
		},
		"rainy": {
			"temperature_modifier": 1.0,
			"efficiency_multiplier": 0.9
		},
		"foggy": {
			"humidity_reduction_bonus": -2.0
		}
	}

	super._ready()


func get_mode() -> String:
	"""Get current operating mode based on temperature needs."""
	var current_temp_delta = get_current_effects()["temperature_delta"]

	if current_temp_delta < -4.0:
		return "cooling"
	elif current_temp_delta > 4.0:
		return "heating"
	else:
		return "fan_only"


func set_target_temperature(temp_celsius: float) -> void:
	"""Set target temperature and adjust cooling accordingly."""
	# Calculate required temperature delta based on ambient
	var ambient_temp = _get_ambient_temperature()
	var required_delta = temp_celsius - ambient_temp

	# Clamp to reasonable range
	required_delta = clamp(required_delta, -10.0, 10.0)

	var old_delta = temperature_delta
	temperature_delta = required_delta

	if abs(old_delta - temperature_delta) > 0.1:
		emit_signal("effect_changed", item_id, "temperature_delta", old_delta, temperature_delta)

	print("[AirConditioner] Target temperature set to %.1f°C (delta: %.1f)" % [temp_celsius, temperature_delta])


func _get_ambient_temperature() -> float:
	"""Get ambient temperature based on season."""
	if not Engine.has_singleton("SeasonManager"):
		return 20.0  # Default room temperature

	var sm = Engine.get_singleton("SeasonManager")
	var config = sm.get_current_season_config()
	if config:
		# Use average of min and max temperature
		return (config.temperature_range.x + config.temperature_range.y) / 2.0

	return 20.0


func get_energy_efficiency_ratio() -> float:
	"""Calculate energy efficiency ratio (EER) based on conditions."""
	var base_eer = 2.5  # Base efficiency

	# Season affects efficiency
	if Engine.has_singleton("SeasonManager"):
		var season = Engine.get_singleton("SeasonManager").get_current_season()
		match season:
			"summer":
				base_eer *= 0.9  # Less efficient in extreme heat
			"winter":
				base_eer *= 1.1  # More efficient in cold

	# Weather affects efficiency
	if Engine.has_singleton("WeatherController"):
		var weather = Engine.get_singleton("WeatherController").get_current_weather_name()
		if weather == "sunny":
			base_eer *= 0.95
		elif weather in ["rainy", "cloudy"]:
			base_eer *= 1.05

	return base_eer


func enter_eco_mode() -> void:
	"""Enter eco-friendly mode with reduced power consumption."""
	energy_consumption_rate *= 0.6
	temperature_delta *= 0.7
	humidity_delta *= 0.7

	print("[AirConditioner] Eco mode activated")


func exit_eco_mode() -> void:
	"""Exit eco mode and restore normal operation."""
	# Restore original values (would need to store originals for proper implementation)
	energy_consumption_rate = 3.5
	temperature_delta = -6.0
	humidity_delta = -5.0

	print("[AirConditioner] Eco mode deactivated")


func clean_filter() -> void:
	"""Clean the air filter to restore efficiency."""
	repair(50)  # Restore some durability
	print("[AirConditioner] Filter cleaned, durability restored")
