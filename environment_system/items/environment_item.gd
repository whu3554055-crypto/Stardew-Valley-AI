## Environment Item Base Class
## Provides environmental effects (temperature, humidity, lighting, comfort) with seasonal and weather modifiers
## Extends Node2D for placement in game world with spatial awareness

extends Node2D
class_name EnvironmentItem

# Signals for event-driven integration
signal effect_changed(item_id: String, effect_type: String, old_value: float, new_value: float)
signal player_proximity_entered(player: Node2D, distance: float)
signal player_proximity_exited(player: Node2D)
signal item_activated()
signal item_deactivated()
signal durability_changed(current_durability: int, max_durability: int)
signal energy_consumed(amount: float)

# Core item properties
@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var category: String = "environmental"  # heating, cooling, decoration, lighting, etc.

# Environmental effects (base values)
@export var temperature_delta: float = 0.0  # Temperature modification in Celsius
@export var humidity_delta: float = 0.0     # Humidity modification percentage
@export var light_radius: float = 0.0       # Light emission radius in pixels
@export var light_intensity: float = 1.0    # Light intensity (0.0 - 2.0)
@export var comfort_bonus: float = 0.0      # Comfort level bonus for NPCs
@export var aesthetic_value: float = 0.0    # Aesthetic contribution to area

# Operational parameters
@export var is_active: bool = true
@export var requires_energy: bool = false
@export var energy_consumption_rate: float = 0.0  # Energy units per hour
@export var current_energy: float = 0.0
@export var max_energy_capacity: float = 100.0

# Durability system
@export var has_durability: bool = false
@export var current_durability: int = 100
@export var max_durability: int = 100
@export var durability_degradation_rate: float = 0.0  # Per hour of operation

# Proximity detection
@export var proximity_radius: float = 100.0
@export var triggers_on_proximity: bool = false
var _players_in_range: Array[Node2D] = []

# Modifiers
var _season_modifiers: Dictionary = {}
var _weather_modifiers: Dictionary = {}
var _active_effects: Dictionary = {}

# Performance tracking
var _total_operating_hours: float = 0.0
var _last_update_time: float = 0.0

# Configuration path
const CONFIG_BASE_PATH = "data/environment_configs/items/"


func _ready() -> void:
	"""Initialize the environment item on node ready."""
	_initialize_item()


func _process(delta: float) -> void:
	"""Process item updates each frame."""
	if not is_active:
		return

	_total_operating_hours += delta / 3600.0

	# Update operational systems
	if requires_energy:
		_process_energy_consumption(delta)

	if has_durability:
		_process_durability_degradation(delta)

	# Update active effects
	_update_active_effects(delta)

	_last_update_time = delta


func _initialize_item() -> void:
	"""Initialize item with default configuration and load external config if available."""
	if item_id.is_empty():
		push_warning("[EnvironmentItem] Item initialized without item_id. Using node name.")
		item_id = name

	if item_name.is_empty():
		item_name = item_id.capitalize()

	# Load external configuration if exists
	_load_external_config()

	# Initialize energy if required
	if requires_energy:
		current_energy = max_energy_capacity

	# Validate initial state
	if not _validate_configuration():
		push_error("[EnvironmentItem] Invalid configuration for item: %s" % item_id)
		set_process(false)
		return

	print("[EnvironmentItem] Initialized: %s (%s)" % [item_name, item_id])


func _load_external_config() -> void:
	"""Load item configuration from external JSON file."""
	var config_path = CONFIG_BASE_PATH + item_id + ".json"
	var file = FileAccess.open(config_path, FileAccess.READ)

	if not file:
		print("[EnvironmentItem] No external config found for %s, using defaults" % item_id)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("[EnvironmentItem] Failed to parse config for %s: %s" % [item_id, json.get_error_message()])
		return

	var data = json.data

	# Apply configuration values
	if data.has("temperature_delta"):
		temperature_delta = float(data["temperature_delta"])
	if data.has("humidity_delta"):
		humidity_delta = float(data["humidity_delta"])
	if data.has("light_radius"):
		light_radius = float(data["light_radius"])
	if data.has("light_intensity"):
		light_intensity = float(data["light_intensity"])
	if data.has("comfort_bonus"):
		comfort_bonus = float(data["comfort_bonus"])
	if data.has("aesthetic_value"):
		aesthetic_value = float(data["aesthetic_value"])
	if data.has("energy_consumption_rate"):
		energy_consumption_rate = float(data["energy_consumption_rate"])
	if data.has("max_energy_capacity"):
		max_energy_capacity = float(data["max_energy_capacity"])
	if data.has("durability_degradation_rate"):
		durability_degradation_rate = float(data["durability_degradation_rate"])
	if data.has("max_durability"):
		max_durability = int(data["max_durability"])
		current_durability = max_durability
	if data.has("proximity_radius"):
		proximity_radius = float(data["proximity_radius"])
	if data.has("season_modifiers"):
		_season_modifiers = data["season_modifiers"]
	if data.has("weather_modifiers"):
		_weather_modifiers = data["weather_modifiers"]

	print("[EnvironmentItem] Loaded external config for %s" % item_id)


func _validate_configuration() -> bool:
	"""Validate item configuration for correctness."""
	if item_id.is_empty():
		push_error("[EnvironmentItem] Validation failed: item_id is empty")
		return false

	if temperature_delta == 0.0 and humidity_delta == 0.0 and light_radius == 0.0 and comfort_bonus == 0.0:
		push_warning("[EnvironmentItem] Item %s has no environmental effects defined" % item_id)

	if requires_energy and energy_consumption_rate <= 0.0:
		push_warning("[EnvironmentItem] Item %s requires energy but consumption rate is not set" % item_id)

	if has_durability and durability_degradation_rate <= 0.0:
		push_warning("[EnvironmentItem] Item %s has durability but degradation rate is not set" % item_id)

	return true


func get_current_effects() -> Dictionary:
	"""
	Get the current effective environmental effects after applying all modifiers.

	Returns:
		Dictionary containing current effect values:
		- temperature_delta: Current temperature modification
		- humidity_delta: Current humidity modification
		- light_radius: Current light radius
		- light_intensity: Current light intensity
		- comfort_bonus: Current comfort bonus
		- aesthetic_value: Current aesthetic value
	"""
	var effects = {
		"temperature_delta": temperature_delta,
		"humidity_delta": humidity_delta,
		"light_radius": light_radius,
		"light_intensity": light_intensity,
		"comfort_bonus": comfort_bonus,
		"aesthetic_value": aesthetic_value
	}

	# Apply season modifiers
	_apply_season_modifiers(effects)

	# Apply weather modifiers
	_apply_weather_modifiers(effects)

	# Apply operational state modifiers
	if not is_active:
		for key in effects.keys():
			effects[key] = 0.0

	if requires_energy and current_energy <= 0.0:
		# Reduce effectiveness when energy is low
		var energy_ratio = current_energy / max_energy_capacity
		for key in effects.keys():
			effects[key] *= energy_ratio

	_active_effects = effects
	return effects


func _apply_season_modifiers(effects: Dictionary) -> void:
	"""Apply seasonal modifiers to effects based on current season."""
	if not Engine.has_singleton("SeasonManager"):
		return

	var current_season = Engine.get_singleton("SeasonManager").get_current_season()
	if not _season_modifiers.has(current_season):
		return

	var season_mods = _season_modifiers[current_season]

	if season_mods.has("temperature_multiplier"):
		var old_temp = effects["temperature_delta"]
		effects["temperature_delta"] *= float(season_mods["temperature_multiplier"])
		if abs(old_temp - effects["temperature_delta"]) > 0.01:
			emit_signal("effect_changed", item_id, "temperature_delta", old_temp, effects["temperature_delta"])

	if season_mods.has("humidity_multiplier"):
		var old_humidity = effects["humidity_delta"]
		effects["humidity_delta"] *= float(season_mods["humidity_multiplier"])
		if abs(old_humidity - effects["humidity_delta"]) > 0.01:
			emit_signal("effect_changed", item_id, "humidity_delta", old_humidity, effects["humidity_delta"])

	if season_mods.has("comfort_multiplier"):
		var old_comfort = effects["comfort_bonus"]
		effects["comfort_bonus"] *= float(season_mods["comfort_multiplier"])
		if abs(old_comfort - effects["comfort_bonus"]) > 0.01:
			emit_signal("effect_changed", item_id, "comfort_bonus", old_comfort, effects["comfort_bonus"])


func _apply_weather_modifiers(effects: Dictionary) -> void:
	"""Apply weather modifiers to effects based on current weather."""
	if not Engine.has_singleton("WeatherController"):
		return

	var current_weather = Engine.get_singleton("WeatherController").get_current_weather_name()
	if not _weather_modifiers.has(current_weather):
		return

	var weather_mods = _weather_modifiers[current_weather]

	if weather_mods.has("temperature_modifier"):
		var old_temp = effects["temperature_delta"]
		effects["temperature_delta"] += float(weather_mods["temperature_modifier"])
		if abs(old_temp - effects["temperature_delta"]) > 0.01:
			emit_signal("effect_changed", item_id, "temperature_delta", old_temp, effects["temperature_delta"])

	if weather_mods.has("efficiency_multiplier"):
		for key in ["temperature_delta", "humidity_delta", "comfort_bonus"]:
			var old_value = effects[key]
			effects[key] *= float(weather_mods["efficiency_multiplier"])
			if abs(old_value - effects[key]) > 0.01:
				emit_signal("effect_changed", item_id, key, old_value, effects[key])


func _process_energy_consumption(delta: float) -> void:
	"""Process energy consumption over time."""
	if not requires_energy or not is_active:
		return

	var energy_used = energy_consumption_rate * (delta / 3600.0)
	current_energy = max(0.0, current_energy - energy_used)

	if energy_used > 0.0:
		emit_signal("energy_consumed", energy_used)

	# Auto-deactivate when energy depleted
	if current_energy <= 0.0 and is_active:
		deactivate_item()
		push_warning("[EnvironmentItem] Item %s deactivated due to energy depletion" % item_id)


func _process_durability_degradation(delta: float) -> void:
	"""Process durability degradation over time."""
	if not has_durability or not is_active:
		return

	var degradation = durability_degradation_rate * (delta / 3600.0)
	var old_durability = current_durability
	current_durability = max(0, current_durability - int(ceil(degradation)))

	if current_durability != old_durability:
		emit_signal("durability_changed", current_durability, max_durability)

	# Deactivate when durability reaches zero
	if current_durability <= 0 and is_active:
		deactivate_item()
		push_warning("[EnvironmentItem] Item %s broken (durability depleted)" % item_id)


func _update_active_effects(delta: float) -> void:
	"""Update and recalculate active effects periodically."""
	# Recalculate effects every second for performance
	if _total_operating_hours - floor(_total_operating_hours) < delta / 3600.0:
		get_current_effects()


func activate_item() -> void:
	"""Activate the environment item."""
	if is_active:
		return

	is_active = true
	emit_signal("item_activated")
	print("[EnvironmentItem] Activated: %s" % item_id)


func deactivate_item() -> void:
	"""Deactivate the environment item."""
	if not is_active:
		return

	is_active = false
	emit_signal("item_deactivated")
	print("[EnvironmentItem] Deactivated: %s" % item_id)


func toggle_active() -> void:
	"""Toggle item active state."""
	if is_active:
		deactivate_item()
	else:
		activate_item()


func add_energy(amount: float) -> void:
	"""Add energy to the item."""
	if not requires_energy:
		push_warning("[EnvironmentItem] Item %s does not require energy" % item_id)
		return

	var old_energy = current_energy
	current_energy = min(max_energy_capacity, current_energy + amount)

	if current_energy != old_energy and current_energy > 0.0 and not is_active:
		activate_item()


func repair(amount: int) -> void:
	"""Repair the item's durability."""
	if not has_durability:
		push_warning("[EnvironmentItem] Item %s does not have durability system" % item_id)
		return

	var old_durability = current_durability
	current_durability = min(max_durability, current_durability + amount)

	if current_durability != old_durability:
		emit_signal("durability_changed", current_durability, max_durability)

	if current_durability > 0 and not is_active:
		activate_item()


func set_season_modifiers(modifiers: Dictionary) -> void:
	"""Set seasonal modifiers for this item."""
	_season_modifiers = modifiers.duplicate(true)
	get_current_effects()  # Recalculate effects


func set_weather_modifiers(modifiers: Dictionary) -> void:
	"""Set weather modifiers for this item."""
	_weather_modifiers = modifiers.duplicate(true)
	get_current_effects()  # Recalculate effects


func get_players_in_proximity() -> Array[Node2D]:
	"""Get list of players currently within proximity range."""
	return _players_in_range.duplicate()


func on_player_proximity_entered(player: Node2D) -> void:
	"""Called when a player enters proximity range."""
	if not _players_in_range.has(player):
		_players_in_range.append(player)
		var distance = global_position.distance_to(player.global_position)
		emit_signal("player_proximity_entered", player, distance)

		if triggers_on_proximity and not is_active:
			activate_item()


func on_player_proximity_exited(player: Node2D) -> void:
	"""Called when a player exits proximity range."""
	if _players_in_range.has(player):
		_players_in_range.erase(player)
		emit_signal("player_proximity_exited", player)

		if triggers_on_proximity and _players_in_range.is_empty():
			deactivate_item()


func check_proximity() -> void:
	"""Check for players within proximity radius."""
	var tree = get_tree()
	if not tree:
		return

	# Get all nodes in group "players"
	var players = tree.get_nodes_in_group("players")
	for player in players:
		if player is Node2D:
			var distance = global_position.distance_to(player.global_position)
			if distance <= proximity_radius:
				on_player_proximity_entered(player)
			else:
				on_player_proximity_exited(player)


func get_effectiveness_ratio() -> float:
	"""Get the current effectiveness ratio (0.0 - 1.0) based on energy and durability."""
	if not requires_energy and not has_durability:
		return 1.0

	var ratios = []

	if requires_energy:
		ratios.append(current_energy / max_energy_capacity)

	if has_durability:
		ratios.append(float(current_durability) / float(max_durability))

	if ratios.is_empty():
		return 1.0

	return ratios.min()


func get_operating_cost_per_hour() -> float:
	"""Calculate the operating cost per hour (energy + durability degradation)."""
	var cost = 0.0

	if requires_energy:
		cost += energy_consumption_rate

	if has_durability:
		# Convert durability degradation to equivalent cost
		cost += durability_degradation_rate

	return cost


func get_total_operating_hours() -> float:
	"""Get total hours this item has been operational."""
	return _total_operating_hours


func reset_statistics() -> void:
	"""Reset all operational statistics."""
	_total_operating_hours = 0.0
	_last_update_time = 0.0
	current_energy = max_energy_capacity if requires_energy else 0.0
	current_durability = max_durability if has_durability else 100


func save_state() -> Dictionary:
	"""Save item state for persistence."""
	return {
		"item_id": item_id,
		"is_active": is_active,
		"current_energy": current_energy,
		"current_durability": current_durability,
		"total_operating_hours": _total_operating_hours,
		"position": {"x": global_position.x, "y": global_position.y},
		"season_modifiers": _season_modifiers,
		"weather_modifiers": _weather_modifiers
	}


func load_state(state: Dictionary) -> void:
	"""Load item state from persistence."""
	if state.has("is_active"):
		is_active = state["is_active"]
	if state.has("current_energy"):
		current_energy = float(state["current_energy"])
	if state.has("current_durability"):
		current_durability = int(state["current_durability"])
	if state.has("total_operating_hours"):
		_total_operating_hours = float(state["total_operating_hours"])
	if state.has("season_modifiers"):
		_season_modifiers = state["season_modifiers"]
	if state.has("weather_modifiers"):
		_weather_modifiers = state["weather_modifiers"]

	# Restore position if provided
	if state.has("position"):
		var pos = state["position"]
		global_position = Vector2(float(pos["x"]), float(pos["y"]))

	print("[EnvironmentItem] Loaded state for %s" % item_id)


func _to_string() -> String:
	"""String representation for debugging."""
	return "[EnvironmentItem: %s (%s) | Active: %s | Effects: temp=%.1f, humid=%.1f, light=%.1f]" % [
		item_name,
		item_id,
		is_active,
		temperature_delta,
		humidity_delta,
		light_radius
	]
