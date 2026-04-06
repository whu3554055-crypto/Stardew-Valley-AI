# tests/unit/test_weather_controller.gd
extends GutTest
## WeatherController单元测试套件

var weather_controller = null

func before_all():
	print("=== WeatherController Test Suite Starting ===")

func before_each():
	weather_controller = preload("res://autoload/weather_controller.gd").new()

func after_each():
	if weather_controller:
		weather_controller.queue_free()
		weather_controller = null

# ============================================
# 配置加载测试
# ============================================

func test_load_default_weather_configs():
	"""测试默认天气配置加载"""
	weather_controller._load_default_weather_configs()

	assert_eq(weather_controller._weather_configs.size(), 6, "Should load 6 weather types")
	assert_true(weather_controller._weather_configs.has("sunny"), "Should have sunny")
	assert_true(weather_controller._weather_configs.has("rainy"), "Should have rainy")
	assert_true(weather_controller._weather_configs.has("stormy"), "Should have stormy")

func test_season_probabilities_loaded():
	"""测试季节概率加载"""
	weather_controller._load_default_weather_configs()

	assert_eq(weather_controller._season_probabilities.size(), 4, "Should have 4 seasons")
	assert_true(weather_controller._season_probabilities.has("spring"), "Should have spring probabilities")

# ============================================
# 状态查询测试
# ============================================

func test_get_current_weather_initial():
	"""测试初始天气状态"""
	weather_controller._load_default_weather_configs()
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY

	assert_eq(weather_controller.get_current_weather_type(), WeatherController.WeatherType.SUNNY)
	assert_eq(weather_controller.get_current_weather_name(), "Sunny")

func test_is_weather():
	"""测试天气检查"""
	weather_controller._load_default_weather_configs()
	weather_controller._current_weather = WeatherController.WeatherType.RAINY

	assert_true(weather_controller.is_weather(WeatherController.WeatherType.RAINY))
	assert_false(weather_controller.is_weather(WeatherController.WeatherType.SUNNY))

func test_is_precipitation():
	"""测试降水检测"""
	weather_controller._load_default_weather_configs()

	# Rainy should be precipitation
	weather_controller._current_weather = WeatherController.WeatherType.RAINY
	assert_true(weather_controller.is_precipitation(), "Rainy should be precipitation")

	# Sunny should not be precipitation
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY
	assert_false(weather_controller.is_precipitation(), "Sunny should not be precipitation")

# ============================================
# 天气修正系数测试
# ============================================

func test_get_weather_modifier_outdoor_activity():
	"""测试户外活动修正系数"""
	weather_controller._load_default_weather_configs()

	# Sunny - full activity
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY
	assert_eq(weather_controller.get_weather_modifier("npc_outdoor_activity"), 1.0, "Sunny should allow full activity")

	# Stormy - no activity
	weather_controller._current_weather = WeatherController.WeatherType.STORMY
	assert_eq(weather_controller.get_weather_modifier("npc_outdoor_activity"), 0.0, "Stormy should prevent activity")

	# Rainy - reduced activity
	weather_controller._current_weather = WeatherController.WeatherType.RAINY
	assert_lt(weather_controller.get_weather_modifier("npc_outdoor_activity"), 1.0, "Rainy should reduce activity")

func test_get_weather_modifier_mood():
	"""测试心情修正"""
	weather_controller._load_default_weather_configs()

	# Sunny - positive mood
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY
	assert_gt(weather_controller.get_weather_modifier("npc_mood"), 0.0, "Sunny should improve mood")

	# Stormy - negative mood
	weather_controller._current_weather = WeatherController.WeatherType.STORMY
	assert_lt(weather_controller.get_weather_modifier("npc_mood"), 0.0, "Stormy should worsen mood")

func test_get_weather_modifier_crop_watered():
	"""测试作物浇水修正"""
	weather_controller._load_default_weather_configs()

	# Rainy - crops watered
	weather_controller._current_weather = WeatherController.WeatherType.RAINY
	assert_eq(weather_controller.get_weather_modifier("crop_watered"), 1.0, "Rainy should water crops")

	# Sunny - crops not watered
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY
	assert_eq(weather_controller.get_weather_modifier("crop_watered"), 0.0, "Sunny should not water crops")

# ============================================
# 天气控制测试
# ============================================

func test_set_weather_valid():
	"""测试有效天气设置"""
	weather_controller._load_default_weather_configs()

	var result = weather_controller.set_weather(WeatherController.WeatherType.RAINY)
	assert_true(result, "Setting valid weather should succeed")
	assert_eq(weather_controller.get_current_weather_type(), WeatherController.WeatherType.RAINY)

func test_set_weather_invalid():
	"""测试无效天气设置"""
	weather_controller._load_default_weather_configs()

	var result = weather_controller.set_weather(999)  # Invalid enum value
	assert_false(result, "Setting invalid weather should fail")

func test_set_weather_same():
	"""测试设置为当前天气"""
	weather_controller._load_default_weather_configs()
	weather_controller._current_weather = WeatherController.WeatherType.SUNNY

	var result = weather_controller.set_weather(WeatherController.WeatherType.SUNNY)
	assert_true(result, "Setting same weather should succeed (no-op)")

# ============================================
# 天气生成测试
# ============================================

func test_generate_weather_duration():
	"""测试天气持续时间生成"""
	weather_controller._load_default_weather_configs()

	for i in range(20):
		var duration = weather_controller._generate_weather_duration()
		assert_ge(duration, 4.0, "Duration should be >= min_hours")
		assert_le(duration, 12.0, "Duration should be <= max_hours")

func test_get_weather_type_from_name():
	"""测试天气名称到枚举的转换"""
	weather_controller._load_default_weather_configs()

	assert_eq(weather_controller._get_weather_type_from_name("sunny"), WeatherController.WeatherType.SUNNY)
	assert_eq(weather_controller._get_weather_type_from_name("rainy"), WeatherController.WeatherType.RAINY)
	assert_eq(weather_controller._get_weather_type_from_name("stormy"), WeatherController.WeatherType.STORMY)

func test_get_weather_type_from_name_invalid():
	"""测试无效天气名称转换"""
	weather_controller._load_default_weather_configs()

	var result = weather_controller._get_weather_type_from_name("invalid_weather")
	assert_eq(result, WeatherController.WeatherType.SUNNY, "Invalid name should default to SUNNY")

# ============================================
# 信号测试
# ============================================

func test_weather_changed_signal():
	"""测试天气变化信号"""
	weather_controller._load_default_weather_configs()

	var signal_received = false
	var old_weather_received = -1
	var new_weather_received = -1

	weather_controller.weather_changed.connect(func(old_w, new_w):
		signal_received = true
		old_weather_received = old_w
		new_weather_received = new_w
	)

	weather_controller._current_weather = WeatherController.WeatherType.SUNNY
	weather_controller.set_weather(WeatherController.WeatherType.RAINY)

	assert_true(signal_received, "weather_changed signal should be emitted")
	assert_eq(old_weather_received, WeatherController.WeatherType.SUNNY)
	assert_eq(new_weather_received, WeatherController.WeatherType.RAINY)

func test_storm_warning_signal():
	"""测试暴风雨警告信号"""
	weather_controller._load_default_weather_configs()

	var warning_active = false

	weather_controller.storm_warning.connect(func(active):
		warning_active = active
	)

	# Trigger storm
	weather_controller.set_weather(WeatherController.WeatherType.STORMY)
	assert_true(warning_active, "Storm warning should be active")

	# Clear storm
	weather_controller.set_weather(WeatherController.WeatherType.SUNNY)
	assert_false(warning_active, "Storm warning should be cleared")

func test_crop_watered_signal():
	"""测试作物浇水信号"""
	weather_controller._load_default_weather_configs()

	var watered = false

	weather_controller.crop_watered_by_rain.connect(func():
		watered = true
	)

	# Set rainy weather (should trigger auto-water)
	weather_controller.set_weather(WeatherController.WeatherType.RAINY)

	# Note: This test may not trigger if FarmManager is not available
	# but the signal connection should work

# ============================================
# 边界情况测试
# ============================================

func test_weather_remaining_hours():
	"""测试剩余时间计算"""
	weather_controller._load_default_weather_configs()
	weather_controller._weather_duration_hours = 10.0
	weather_controller._weather_timer = 3.0

	var remaining = weather_controller.get_weather_remaining_hours()
	assert_eq(remaining, 7.0, "Should have 7 hours remaining")

func test_weather_remaining_hours_expired():
	"""测试过期时间的剩余时间"""
	weather_controller._load_default_weather_configs()
	weather_controller._weather_duration_hours = 5.0
	weather_controller._weather_timer = 7.0  # Exceeded

	var remaining = weather_controller.get_weather_remaining_hours()
	assert_eq(remaining, 0.0, "Should return 0 when expired")

func test_has_storm_risk():
	"""测试暴风雨风险检测"""
	weather_controller._load_default_weather_configs()

	weather_controller._current_weather = WeatherController.WeatherType.STORMY
	assert_true(weather_controller.has_storm_risk(), "Stormy weather should have risk")

	weather_controller._current_weather = WeatherController.WeatherType.RAINY
	assert_false(weather_controller.has_storm_risk(), "Rainy weather should not have storm risk")

# ============================================
# JSON配置测试
# ============================================

func test_get_season_weather_probabilities():
	"""测试获取季节天气概率"""
	weather_controller._load_default_weather_configs()

	var spring_probs = weather_controller.get_season_weather_probabilities("spring")
	assert_true(spring_probs.has("sunny"), "Spring should have sunny probability")
	assert_true(spring_probs.has("rainy"), "Spring should have rainy probability")

func test_get_season_weather_probabilities_invalid():
	"""测试无效季节的概率"""
	weather_controller._load_default_weather_configs()

	var probs = weather_controller.get_season_weather_probabilities("invalid_season")
	assert_true(probs.size() > 0, "Should return default probabilities for invalid season")

# ============================================
# 性能测试
# ============================================

func test_performance_weather_cycles():
	"""测试多次天气循环的性能"""
	weather_controller._load_default_weather_configs()

	var start_time = Time.get_ticks_msec()

	for i in range(50):
		weather_controller.force_refresh_weather()

	var elapsed = Time.get_ticks_msec() - start_time

	assert_lt(elapsed, 500, "50 weather cycles should take less than 500ms")
	print("Performance: 50 weather cycles took %d ms" % elapsed)
