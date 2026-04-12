## Decorative Plant Environment Item
## Provides humidity, aesthetic value, and mood benefits

extends EnvironmentItem
class_name DecorativePlant


func _ready() -> void:
	"""Initialize decorative plant with default configuration."""
	item_id = "decorative_plant" if item_id.is_empty() else item_id
	item_name = "Decorative Plant" if item_name.is_empty() else item_name
	description = "A beautiful plant that improves air quality and aesthetics"
	category = "decoration"

	# Base environmental effects
	temperature_delta = -0.5  # Slight cooling through transpiration
	humidity_delta = 3.0      # Increases humidity
	light_radius = 0.0
	light_intensity = 0.0
	comfort_bonus = 3.0
	aesthetic_value = 7.0

	# Operational parameters (plants don't consume energy)
	requires_energy = false
	energy_consumption_rate = 0.0
	max_energy_capacity = 0.0
	current_energy = 0.0

	# Health system (instead of durability)
	has_durability = true
	max_durability = 100  # Represents plant health
	current_durability = 100
	durability_degradation_rate = 0.1  # Slow natural degradation

	# Proximity detection
	proximity_radius = 80.0
	triggers_on_proximity = false

	# Seasonal modifiers (plants thrive in certain seasons)
	_season_modifiers = {
		"spring": {
			"humidity_multiplier": 1.3,
			"aesthetic_multiplier": 1.2,
			"health_regeneration": 0.2
		},
		"summer": {
			"humidity_multiplier": 1.1,
			"aesthetic_multiplier": 1.0,
			"health_regeneration": 0.1
		},
		"fall": {
			"humidity_multiplier": 0.9,
			"aesthetic_multiplier": 0.8,
			"health_regeneration": 0.0
		},
		"winter": {
			"humidity_multiplier": 0.6,
			"aesthetic_multiplier": 0.6,
			"health_regeneration": -0.1  # Loses health in winter
		}
	}

	# Weather modifiers
	_weather_modifiers = {
		"sunny": {
			"humidity_multiplier": 0.9,
			"health_effect": 0.05
		},
		"rainy": {
			"humidity_multiplier": 1.2,
			"health_effect": 0.1
		},
		"cloudy": {
			"humidity_multiplier": 1.0,
			"health_effect": 0.0
		},
		"foggy": {
			"humidity_multiplier": 1.3,
			"health_effect": 0.05
		}
	}

	super._ready()


func get_plant_health() -> float:
	"""Get current plant health as percentage (0.0 - 1.0)."""
	return float(current_durability) / float(max_durability)


func water_plant() -> void:
	"""Water the plant to restore health."""
	var old_health = current_durability
	current_durability = min(max_durability, current_durability + 20)

	if current_durability != old_health:
		emit_signal("durability_changed", current_durability, max_durability)
		print("[DecorativePlant] Watered: health %.0f -> %.0f" % [old_health, current_durability])


func fertilize() -> void:
	"""Fertilize the plant for temporary boost."""
	# Temporarily boost aesthetic value and humidity
	var effects = get_current_effects()
	effects["aesthetic_value"] *= 1.5
	effects["humidity_delta"] *= 1.3

	emit_signal("effect_changed", item_id, "aesthetic_value", aesthetic_value, effects["aesthetic_value"])
	print("[DecorativePlant] Fertilized: temporary boost applied")


func prune() -> void:
	"""Prune the plant to remove dead parts and improve appearance."""
	repair(15)  # Restore some health
	aesthetic_value *= 1.1  # Permanent small boost to aesthetics

	print("[DecorativePlant] Pruned: health restored, aesthetics improved")


func get_growth_stage() -> String:
	"""Get the current growth stage based on health."""
	var health_ratio = get_plant_health()

	if health_ratio < 0.3:
		return "withering"
	elif health_ratio < 0.6:
		return "struggling"
	elif health_ratio < 0.9:
		return "healthy"
	else:
		return "thriving"


func calculate_mood_bonus(npc_base_mood: float) -> float:
	"""Calculate mood bonus for NPCs based on plant condition."""
	var base_bonus = comfort_bonus

	# Health affects mood bonus
	var health_ratio = get_plant_health()
	base_bonus *= health_ratio

	# Aesthetic value provides additional bonus
	base_bonus += aesthetic_value * 0.1

	# Season affects mood impact
	if Engine.has_singleton("SeasonManager"):
		var season = Engine.get_singleton("SeasonManager").get_current_season()
		if season == "spring":
			base_bonus *= 1.2  # Spring plants are more uplifting
		elif season == "winter":
			base_bonus *= 0.8  # Less impact in winter

	return base_bonus


func needs_water() -> bool:
	"""Check if the plant needs watering."""
	return current_durability < max_durability * 0.4


func is_dead() -> bool:
	"""Check if the plant has died."""
	return current_durability <= 0


func revive() -> void:
	"""Revive a dead or dying plant."""
	if is_dead():
		current_durability = max_durability * 0.3  # Revive at 30% health
		emit_signal("durability_changed", current_durability, max_durability)
		print("[DecorativePlant] Revived from death")
	else:
		water_plant()


func _process(delta: float) -> void:
	"""Override process to add plant-specific logic."""
	super._process(delta)

	# Apply seasonal health regeneration/degradation
	if Engine.has_singleton("SeasonManager"):
		var season = Engine.get_singleton("SeasonManager").get_current_season()
		if _season_modifiers.has(season) and _season_modifiers[season].has("health_regeneration"):
			var regen = float(_season_modifiers[season]["health_regeneration"])
			if regen != 0.0:
				current_durability = clamp(current_durability + int(regen), 0, max_durability)
