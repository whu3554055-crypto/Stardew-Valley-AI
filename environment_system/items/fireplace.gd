## Fireplace Environment Item
## Provides heating, comfort, and ambient lighting with seasonal variations

extends EnvironmentItem
class_name Fireplace


func _ready() -> void:
	"""Initialize fireplace with default configuration."""
	item_id = "fireplace" if item_id.is_empty() else item_id
	item_name = "Fireplace" if item_name.is_empty() else item_name
	description = "A cozy fireplace that provides warmth and comfort"
	category = "heating"

	# Base environmental effects
	temperature_delta = 5.0
	humidity_delta = -2.0
	light_radius = 150.0
	light_intensity = 1.2
	comfort_bonus = 8.0
	aesthetic_value = 6.0

	# Operational parameters
	requires_energy = true
	energy_consumption_rate = 2.0  # Fuel units per hour
	max_energy_capacity = 50.0
	current_energy = 50.0

	# Durability system
	has_durability = true
	max_durability = 500
	current_durability = 500
	durability_degradation_rate = 0.5  # Per hour of use

	# Proximity detection
	proximity_radius = 200.0
	triggers_on_proximity = false

	# Seasonal modifiers (more effective in winter, less in summer)
	_season_modifiers = {
		"winter": {
			"temperature_multiplier": 1.5,
			"comfort_multiplier": 1.3
		},
		"fall": {
			"temperature_multiplier": 1.2,
			"comfort_multiplier": 1.1
		},
		"spring": {
			"temperature_multiplier": 0.8,
			"comfort_multiplier": 0.9
		},
		"summer": {
			"temperature_multiplier": 0.5,
			"comfort_multiplier": 0.7
		}
	}

	# Weather modifiers (more useful in cold/rainy weather)
	_weather_modifiers = {
		"rainy": {
			"temperature_modifier": 1.0,
			"efficiency_multiplier": 1.1
		},
		"stormy": {
			"temperature_modifier": 1.5,
			"efficiency_multiplier": 1.2
		},
		"snowy": {
			"temperature_modifier": 2.0,
			"efficiency_multiplier": 1.3
		},
		"foggy": {
			"light_intensity_bonus": 0.2
		}
	}

	super._ready()


func get_fire_type() -> String:
	"""Get the type of fire based on season and weather."""
	if Engine.has_singleton("SeasonManager"):
		var season = SeasonManager.get_current_season()
		if season == "winter":
			return "roaring"
		elif season == "fall":
			return "warm"

	return "cozy"


func get_fuel_efficiency() -> float:
	"""Calculate fuel efficiency based on current conditions."""
	var base_efficiency = 1.0

	# Season affects efficiency
	if Engine.has_singleton("SeasonManager"):
		var season = SeasonManager.get_current_season()
		match season:
			"winter":
				base_efficiency *= 1.2  # More efficient in cold
			"summer":
				base_efficiency *= 0.7  # Less efficient in heat

	# Weather affects efficiency
	if Engine.has_singleton("WeatherController"):
		var weather = WeatherController.get_current_weather_name()
		if weather in ["rainy", "stormy", "snowy"]:
			base_efficiency *= 1.1

	return base_efficiency


func extinguish() -> void:
	"""Extinguish the fireplace."""
	deactivate_item()
	current_energy = 0.0
	print("[Fireplace] Extinguished: %s" % item_id)


func stoke_fire() -> void:
	"""Stoke the fire to increase effectiveness temporarily."""
	if not is_active:
		activate_item()

	# Temporary boost to temperature and light
	var effects = get_current_effects()
	effects["temperature_delta"] *= 1.3
	effects["light_intensity"] *= 1.2

	emit_signal("effect_changed", item_id, "temperature_delta", temperature_delta, effects["temperature_delta"])
	print("[Fireplace] Fire stoked: %s" % item_id)
