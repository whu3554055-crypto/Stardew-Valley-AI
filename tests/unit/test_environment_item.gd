## Unit Tests for EnvironmentItem System
## Comprehensive test coverage for base class and example items

extends Node

var environment_item: EnvironmentItem
var fireplace: Fireplace
var air_conditioner: AirConditioner
var decorative_plant: DecorativePlant


func _ready() -> void:
	"""Run all tests when scene is ready."""
	print("\n=== Running EnvironmentItem Unit Tests ===\n")

	run_all_tests()

	print("\n=== All Tests Completed ===\n")


func run_all_tests() -> void:
	"""Execute all test suites."""
	test_base_item_initialization()
	test_base_item_effects()
	test_energy_system()
	test_durability_system()
	test_proximity_detection()
	test_season_modifiers()
	test_weather_modifiers()
	test_activation_deactivation()
	test_state_persistence()
	test_fireplace_specific()
	test_air_conditioner_specific()
	test_decorative_plant_specific()
	test_edge_cases()
	test_performance()


# ============================================================================
# Base Item Initialization Tests
# ============================================================================

func test_base_item_initialization() -> void:
	print("--- Test: Base Item Initialization ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "test_item"
	environment_item.item_name = "Test Item"
	environment_item._initialize_item()

	assert_eq(environment_item.item_id, "test_item", "Item ID should be set")
	assert_eq(environment_item.item_name, "Test Item", "Item name should be set")
	assert_true(environment_item.is_active, "Item should be active by default")
	assert_false(environment_item.requires_energy, "Item should not require energy by default")

	environment_item.queue_free()
	print("PASS: Base item initialization\n")


# ============================================================================
# Base Item Effects Tests
# ============================================================================

func test_base_item_effects() -> void:
	print("--- Test: Base Item Effects ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "effects_test"
	environment_item.temperature_delta = 3.0
	environment_item.humidity_delta = 2.0
	environment_item.light_radius = 100.0
	environment_item.comfort_bonus = 5.0

	var effects = environment_item.get_current_effects()

	assert_eq(effects["temperature_delta"], 3.0, "Temperature delta should match")
	assert_eq(effects["humidity_delta"], 2.0, "Humidity delta should match")
	assert_eq(effects["light_radius"], 100.0, "Light radius should match")
	assert_eq(effects["comfort_bonus"], 5.0, "Comfort bonus should match")

	environment_item.queue_free()
	print("PASS: Base item effects calculation\n")


# ============================================================================
# Energy System Tests
# ============================================================================

func test_energy_system() -> void:
	print("--- Test: Energy System ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "energy_test"
	environment_item.requires_energy = true
	environment_item.max_energy_capacity = 100.0
	environment_item.current_energy = 100.0
	environment_item.energy_consumption_rate = 10.0  # 10 units per hour

	# Test energy addition
	environment_item.add_energy(50.0)
	assert_eq(environment_item.current_energy, 100.0, "Energy should cap at max capacity")

	# Test energy consumption simulation
	environment_item.current_energy = 50.0
	environment_item._process_energy_consumption(3600.0)  # Simulate 1 hour
	assert_eq(environment_item.current_energy, 40.0, "Energy should decrease by consumption rate")

	# Test energy depletion deactivation
	environment_item.current_energy = 0.0
	environment_item._process_energy_consumption(3600.0)
	assert_false(environment_item.is_active, "Item should deactivate when energy depleted")

	environment_item.queue_free()
	print("PASS: Energy system\n")


# ============================================================================
# Durability System Tests
# ============================================================================

func test_durability_system() -> void:
	print("--- Test: Durability System ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "durability_test"
	environment_item.has_durability = true
	environment_item.max_durability = 100
	environment_item.current_durability = 100
	environment_item.durability_degradation_rate = 5.0  # 5 per hour

	# Test repair
	environment_item.current_durability = 50
	environment_item.repair(30)
	assert_eq(environment_item.current_durability, 80, "Durability should increase after repair")

	# Test repair cap
	environment_item.repair(50)
	assert_eq(environment_item.current_durability, 100, "Durability should cap at max")

	# Test degradation simulation
	environment_item._process_durability_degradation(3600.0)  # Simulate 1 hour
	assert_eq(environment_item.current_durability, 95, "Durability should decrease")

	# Test durability depletion
	environment_item.current_durability = 3
	environment_item._process_durability_degradation(3600.0)
	assert_eq(environment_item.current_durability, 0, "Durability should reach zero")
	assert_false(environment_item.is_active, "Item should deactivate when durability depleted")

	environment_item.queue_free()
	print("PASS: Durability system\n")


# ============================================================================
# Proximity Detection Tests
# ============================================================================

func test_proximity_detection() -> void:
	print("--- Test: Proximity Detection ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "proximity_test"
	environment_item.proximity_radius = 100.0
	environment_item.global_position = Vector2(0, 0)

	# Create mock player
	var player = Node2D.new()
	player.global_position = Vector2(50, 0)  # Within range

	# Test proximity entry
	environment_item.on_player_proximity_entered(player)
	var players_in_range = environment_item.get_players_in_proximity()
	assert_eq(players_in_range.size(), 1, "Should have 1 player in range")

	# Test proximity exit
	environment_item.on_player_proximity_exited(player)
	players_in_range = environment_item.get_players_in_proximity()
	assert_eq(players_in_range.size(), 0, "Should have 0 players after exit")

	player.queue_free()
	environment_item.queue_free()
	print("PASS: Proximity detection\n")


# ============================================================================
# Season Modifiers Tests
# ============================================================================

func test_season_modifiers() -> void:
	print("--- Test: Season Modifiers ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "season_test"
	environment_item.temperature_delta = 10.0
	environment_item._season_modifiers = {
		"winter": {"temperature_multiplier": 1.5},
		"summer": {"temperature_multiplier": 0.5}
	}

	# Without SeasonManager, modifiers shouldn't apply
	var effects = environment_item.get_current_effects()
	assert_eq(effects["temperature_delta"], 10.0, "Base value without season manager")

	environment_item.queue_free()
	print("PASS: Season modifiers\n")


# ============================================================================
# Weather Modifiers Tests
# ============================================================================

func test_weather_modifiers() -> void:
	print("--- Test: Weather Modifiers ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "weather_test"
	environment_item.temperature_delta = 5.0
	environment_item._weather_modifiers = {
		"rainy": {"temperature_modifier": 2.0},
		"sunny": {"efficiency_multiplier": 0.8}
	}

	# Without WeatherController, modifiers shouldn't apply
	var effects = environment_item.get_current_effects()
	assert_eq(effects["temperature_delta"], 5.0, "Base value without weather controller")

	environment_item.queue_free()
	print("PASS: Weather modifiers\n")


# ============================================================================
# Activation/Deactivation Tests
# ============================================================================

func test_activation_deactivation() -> void:
	print("--- Test: Activation/Deactivation ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "activation_test"

	# Test deactivation
	environment_item.deactivate_item()
	assert_false(environment_item.is_active, "Item should be deactivated")

	var effects = environment_item.get_current_effects()
	assert_eq(effects["temperature_delta"], 0.0, "Effects should be zero when inactive")

	# Test reactivation
	environment_item.activate_item()
	assert_true(environment_item.is_active, "Item should be activated")

	# Test toggle
	environment_item.toggle_active()
	assert_false(environment_item.is_active, "Item should be toggled off")

	environment_item.toggle_active()
	assert_true(environment_item.is_active, "Item should be toggled on")

	environment_item.queue_free()
	print("PASS: Activation/Deactivation\n")


# ============================================================================
# State Persistence Tests
# ============================================================================

func test_state_persistence() -> void:
	print("--- Test: State Persistence ---")

	environment_item = EnvironmentItem.new()
	environment_item.item_id = "persistence_test"
	environment_item.is_active = false
	environment_item.current_energy = 75.0
	environment_item.current_durability = 80
	environment_item._total_operating_hours = 12.5

	# Save state
	var state = environment_item.save_state()
	assert_eq(state["item_id"], "persistence_test", "State should include item_id")
	assert_eq(state["is_active"], false, "State should include active state")
	assert_eq(state["current_energy"], 75.0, "State should include energy")
	assert_eq(state["current_durability"], 80, "State should include durability")

	# Load state into new item
	var new_item = EnvironmentItem.new()
	new_item.item_id = "new_item"
	new_item.load_state(state)

	assert_eq(new_item.is_active, false, "Loaded state should restore active state")
	assert_eq(new_item.current_energy, 75.0, "Loaded state should restore energy")
	assert_eq(new_item.current_durability, 80, "Loaded state should restore durability")

	environment_item.queue_free()
	new_item.queue_free()
	print("PASS: State persistence\n")


# ============================================================================
# Fireplace Specific Tests
# ============================================================================

func test_fireplace_specific() -> void:
	print("--- Test: Fireplace Specific ---")

	fireplace = Fireplace.new()
	fireplace.item_id = "fireplace_test"
	fireplace._ready()

	assert_eq(fireplace.category, "heating", "Fireplace should be heating category")
	assert_gt(fireplace.temperature_delta, 0.0, "Fireplace should increase temperature")
	assert_gt(fireplace.comfort_bonus, 0.0, "Fireplace should provide comfort")
	assert_true(fireplace.requires_energy, "Fireplace should require energy")
	assert_true(fireplace.has_durability, "Fireplace should have durability")

	# Test fuel efficiency
	var efficiency = fireplace.get_fuel_efficiency()
	assert_gt(efficiency, 0.0, "Fuel efficiency should be positive")

	# Test extinguish
	fireplace.extinguish()
	assert_false(fireplace.is_active, "Fireplace should be extinguished")

	fireplace.queue_free()
	print("PASS: Fireplace specific functionality\n")


# ============================================================================
# Air Conditioner Specific Tests
# ============================================================================

func test_air_conditioner_specific() -> void:
	print("--- Test: Air Conditioner Specific ---")

	air_conditioner = AirConditioner.new()
	air_conditioner.item_id = "ac_test"
	air_conditioner._ready()

	assert_eq(air_conditioner.category, "cooling", "AC should be cooling category")
	assert_lt(air_conditioner.temperature_delta, 0.0, "AC should decrease temperature")
	assert_lt(air_conditioner.humidity_delta, 0.0, "AC should decrease humidity")
	assert_true(air_conditioner.triggers_on_proximity, "AC should auto-activate on proximity")

	# Test mode detection
	var mode = air_conditioner.get_mode()
	assert_true(mode in ["cooling", "heating", "fan_only"], "Mode should be valid")

	# Test eco mode
	air_conditioner.enter_eco_mode()
	assert_lt(air_conditioner.energy_consumption_rate, 3.5, "Eco mode should reduce consumption")

	air_conditioner.exit_eco_mode()
	assert_eq(air_conditioner.energy_consumption_rate, 3.5, "Normal mode should restore consumption")

	air_conditioner.queue_free()
	print("PASS: Air conditioner specific functionality\n")


# ============================================================================
# Decorative Plant Specific Tests
# ============================================================================

func test_decorative_plant_specific() -> void:
	print("--- Test: Decorative Plant Specific ---")

	decorative_plant = DecorativePlant.new()
	decorative_plant.item_id = "plant_test"
	decorative_plant._ready()

	assert_eq(decorative_plant.category, "decoration", "Plant should be decoration category")
	assert_gt(decorative_plant.humidity_delta, 0.0, "Plant should increase humidity")
	assert_gt(decorative_plant.aesthetic_value, 0.0, "Plant should have aesthetic value")
	assert_false(decorative_plant.requires_energy, "Plant should not require energy")

	# Test health system
	var health = decorative_plant.get_plant_health()
	assert_eq(health, 1.0, "New plant should have full health")

	# Test watering
	decorative_plant.current_durability = 50
	decorative_plant.water_plant()
	assert_gt(decorative_plant.current_durability, 50, "Watering should restore health")

	# Test needs water
	decorative_plant.current_durability = 30
	assert_true(decorative_plant.needs_water(), "Plant should need water at low health")

	# Test death and revival
	decorative_plant.current_durability = 0
	assert_true(decorative_plant.is_dead(), "Plant should be dead at zero health")

	decorative_plant.revive()
	assert_false(decorative_plant.is_dead(), "Plant should be revived")

	decorative_plant.queue_free()
	print("PASS: Decorative plant specific functionality\n")


# ============================================================================
# Edge Cases Tests
# ============================================================================

func test_edge_cases() -> void:
	print("--- Test: Edge Cases ---")

	# Test item with no effects
	environment_item = EnvironmentItem.new()
	environment_item.item_id = "empty_item"
	environment_item._initialize_item()

	var effects = environment_item.get_current_effects()
	assert_eq(effects["temperature_delta"], 0.0, "Empty item should have zero effects")

	# Test effectiveness ratio
	var ratio = environment_item.get_effectiveness_ratio()
	assert_eq(ratio, 1.0, "Item without energy/durability should have full effectiveness")

	# Test operating cost
	var cost = environment_item.get_operating_cost_per_hour()
	assert_eq(cost, 0.0, "Item without consumption should have zero cost")

	# Test statistics reset
	environment_item.reset_statistics()
	assert_eq(environment_item._total_operating_hours, 0.0, "Statistics should reset")

	environment_item.queue_free()
	print("PASS: Edge cases\n")


# ============================================================================
# Performance Tests
# ============================================================================

func test_performance() -> void:
	print("--- Test: Performance ---")

	var start_time = Time.get_ticks_msec()

	# Create and process multiple items
	for i in range(50):
		var item = EnvironmentItem.new()
		item.item_id = "perf_test_%d" % i
		item._initialize_item()
		item._process(1.0)  # Simulate 1 second
		item.get_current_effects()
		item.queue_free()

	var elapsed = Time.get_ticks_msec() - start_time
	assert_lt(elapsed, 500, "50 items should process in under 500ms")

	print("PASS: Performance (%d ms for 50 items)\n" % elapsed)


# ============================================================================
# Helper Functions
# ============================================================================

func assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		push_error("ASSERTION FAILED: %s | Expected: %s, Got: %s" % [message, str(expected), str(actual)])
	else:
		print("  ✓ %s" % message)


func assert_ne(actual, expected, message: String) -> void:
	if actual == expected:
		push_error("ASSERTION FAILED: %s | Expected not: %s, Got: %s" % [message, str(expected), str(actual)])
	else:
		print("  ✓ %s" % message)


func assert_gt(actual, expected, message: String) -> void:
	if actual <= expected:
		push_error("ASSERTION FAILED: %s | Expected > %s, Got: %s" % [message, str(expected), str(actual)])
	else:
		print("  ✓ %s" % message)


func assert_lt(actual, expected, message: String) -> void:
	if actual >= expected:
		push_error("ASSERTION FAILED: %s | Expected < %s, Got: %s" % [message, str(expected), str(actual)])
	else:
		print("  ✓ %s" % message)


func assert_true(value, message: String) -> void:
	if not value:
		push_error("ASSERTION FAILED: %s | Expected true, Got: %s" % [message, str(value)])
	else:
		print("  ✓ %s" % message)


func assert_false(value, message: String) -> void:
	if value:
		push_error("ASSERTION FAILED: %s | Expected false, Got: true" % message)
	else:
		print("  ✓ %s" % message)
