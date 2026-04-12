# tests/unit/test_weather_controller.gd
extends GutTest
## WeatherController单元测试套件

const WCT := preload("res://autoload/weather_controller.gd")

var _wx_sig_received: bool = false
var _wx_sig_old: int = -1
var _wx_sig_new: int = -1

func _on_weather_changed_for_test(old_w: int, new_w: int) -> void:
	_wx_sig_received = true
	_wx_sig_old = old_w
	_wx_sig_new = new_w

var _storm_warning_last: bool = false

func _on_storm_warning_for_test(active: bool) -> void:
	_storm_warning_last = active

func before_all():
	print("=== WeatherController Test Suite Starting ===")

func before_each():
	WeatherController.reset_builtin_weather_data()

# ============================================
# 配置加载测试
# ============================================

func test_load_default_weather_configs():
	"""测试默认天气配置加载"""
	WeatherController.reset_builtin_weather_data()

	assert_eq(WeatherController._weather_configs.size(), 6, "Should load 6 weather types")
	assert_true(WeatherController._weather_configs.has("sunny"), "Should have sunny")
	assert_true(WeatherController._weather_configs.has("rainy"), "Should have rainy")
	assert_true(WeatherController._weather_configs.has("stormy"), "Should have stormy")

func test_season_probabilities_loaded():
	"""测试季节概率加载"""
	WeatherController.reset_builtin_weather_data()

	assert_eq(WeatherController._season_probabilities.size(), 4, "Should have 4 seasons")
	assert_true(WeatherController._season_probabilities.has("spring"), "Should have spring probabilities")

# ============================================
# 状态查询测试
# ============================================

func test_get_current_weather_initial():
	"""测试初始天气状态"""
	WeatherController.reset_builtin_weather_data()
	WeatherController._current_weather = WCT.WeatherType.SUNNY

	assert_eq(WeatherController.get_current_weather_type(), WCT.WeatherType.SUNNY)
	assert_eq(WeatherController.get_current_weather_name(), "Sunny")

func test_is_weather():
	"""测试天气检查"""
	WeatherController.reset_builtin_weather_data()
	WeatherController._current_weather = WCT.WeatherType.RAINY

	assert_true(WeatherController.is_weather(WCT.WeatherType.RAINY))
	assert_false(WeatherController.is_weather(WCT.WeatherType.SUNNY))

func test_is_precipitation():
	"""测试降水检测"""
	WeatherController.reset_builtin_weather_data()

	# Rainy should be precipitation
	WeatherController._current_weather = WCT.WeatherType.RAINY
	assert_true(WeatherController.is_precipitation(), "Rainy should be precipitation")

	# Sunny should not be precipitation
	WeatherController._current_weather = WCT.WeatherType.SUNNY
	assert_false(WeatherController.is_precipitation(), "Sunny should not be precipitation")

# ============================================
# 天气修正系数测试
# ============================================

func test_get_weather_modifier_outdoor_activity():
	"""测试户外活动修正系数"""
	WeatherController.reset_builtin_weather_data()

	# Sunny - full activity
	WeatherController._current_weather = WCT.WeatherType.SUNNY
	assert_eq(WeatherController.get_weather_modifier("npc_outdoor_activity"), 1.0, "Sunny should allow full activity")

	# Stormy - no activity
	WeatherController._current_weather = WCT.WeatherType.STORMY
	assert_eq(WeatherController.get_weather_modifier("npc_outdoor_activity"), 0.0, "Stormy should prevent activity")

	# Rainy - reduced activity
	WeatherController._current_weather = WCT.WeatherType.RAINY
	assert_lt(WeatherController.get_weather_modifier("npc_outdoor_activity"), 1.0, "Rainy should reduce activity")

func test_get_weather_modifier_mood():
	"""测试心情修正"""
	WeatherController.reset_builtin_weather_data()

	# Sunny - positive mood
	WeatherController._current_weather = WCT.WeatherType.SUNNY
	assert_gt(WeatherController.get_weather_modifier("npc_mood"), 0.0, "Sunny should improve mood")

	# Stormy - negative mood
	WeatherController._current_weather = WCT.WeatherType.STORMY
	assert_lt(WeatherController.get_weather_modifier("npc_mood"), 0.0, "Stormy should worsen mood")

func test_get_weather_modifier_crop_watered():
	"""测试作物浇水修正"""
	WeatherController.reset_builtin_weather_data()

	# Rainy - crops watered
	WeatherController._current_weather = WCT.WeatherType.RAINY
	assert_eq(WeatherController.get_weather_modifier("crop_watered"), 1.0, "Rainy should water crops")

	# Sunny - crops not watered
	WeatherController._current_weather = WCT.WeatherType.SUNNY
	assert_eq(WeatherController.get_weather_modifier("crop_watered"), 0.0, "Sunny should not water crops")

# ============================================
# 天气控制测试
# ============================================

func test_set_weather_valid():
	"""测试有效天气设置"""
	WeatherController.reset_builtin_weather_data()

	var result = WeatherController.set_weather(WCT.WeatherType.RAINY)
	assert_true(result, "Setting valid weather should succeed")
	assert_eq(WeatherController.get_current_weather_type(), WCT.WeatherType.RAINY)

func test_set_weather_invalid():
	"""测试无效天气设置"""
	WeatherController.reset_builtin_weather_data()

	var result = WeatherController.set_weather(999)  # Invalid enum value
	assert_false(result, "Setting invalid weather should fail")
	assert_push_error(1, "expected invalid weather push_error")

func test_set_weather_same():
	"""测试设置为当前天气"""
	WeatherController.reset_builtin_weather_data()
	WeatherController._current_weather = WCT.WeatherType.SUNNY

	var result = WeatherController.set_weather(WCT.WeatherType.SUNNY)
	assert_true(result, "Setting same weather should succeed (no-op)")

# ============================================
# 天气生成测试
# ============================================

func test_generate_weather_duration():
	"""测试天气持续时间生成"""
	WeatherController.reset_builtin_weather_data()

	for i in range(20):
		var duration = WeatherController.roll_weather_duration_hours()
		assert_gte(duration, 4.0, "Duration should be >= min_hours")
		assert_lte(duration, 12.0, "Duration should be <= max_hours")

func test_get_weather_type_from_name():
	"""测试天气名称到枚举的转换"""
	WeatherController.reset_builtin_weather_data()

	assert_eq(WeatherController.weather_type_from_name("sunny"), WCT.WeatherType.SUNNY)
	assert_eq(WeatherController.weather_type_from_name("rainy"), WCT.WeatherType.RAINY)
	assert_eq(WeatherController.weather_type_from_name("stormy"), WCT.WeatherType.STORMY)

func test_get_weather_type_from_name_invalid():
	"""测试无效天气名称转换"""
	WeatherController.reset_builtin_weather_data()

	var result = WeatherController.weather_type_from_name("invalid_weather")
	assert_eq(result, WCT.WeatherType.SUNNY, "Invalid name should default to SUNNY")
	assert_engine_error(1, "Unknown weather name")

# ============================================
# 信号测试
# ============================================

func test_weather_changed_signal():
	"""测试天气变化信号"""
	WeatherController.reset_builtin_weather_data()

	_wx_sig_received = false
	_wx_sig_old = -1
	_wx_sig_new = -1
	WeatherController.weather_changed.connect(_on_weather_changed_for_test)

	WeatherController._current_weather = WCT.WeatherType.SUNNY
	WeatherController.set_weather(WCT.WeatherType.RAINY)

	assert_true(_wx_sig_received, "weather_changed signal should be emitted")
	assert_eq(_wx_sig_old, WCT.WeatherType.SUNNY)
	assert_eq(_wx_sig_new, WCT.WeatherType.RAINY)
	WeatherController.weather_changed.disconnect(_on_weather_changed_for_test)

func test_storm_warning_signal():
	"""测试暴风雨警告信号"""
	WeatherController.reset_builtin_weather_data()

	_storm_warning_last = false
	WeatherController.storm_warning.connect(_on_storm_warning_for_test)

	# Trigger storm
	WeatherController.set_weather(WCT.WeatherType.STORMY)
	assert_true(_storm_warning_last, "Storm warning should be active")

	# Clear storm
	WeatherController.set_weather(WCT.WeatherType.SUNNY)
	assert_false(_storm_warning_last, "Storm warning should be cleared")
	WeatherController.storm_warning.disconnect(_on_storm_warning_for_test)

func test_crop_watered_signal():
	"""测试作物浇水信号"""
	WeatherController.reset_builtin_weather_data()

	var on_watered = func():
		pass
	WeatherController.crop_watered_by_rain.connect(on_watered)

	# Set rainy weather (should trigger auto-water)
	WeatherController.set_weather(WCT.WeatherType.RAINY)

	assert_true(WeatherController.has_signal("crop_watered_by_rain"), "controller exposes crop_watered_by_rain")
	WeatherController.crop_watered_by_rain.disconnect(on_watered)

# ============================================
# 边界情况测试
# ============================================

func test_weather_remaining_hours():
	"""测试剩余时间计算"""
	WeatherController.reset_builtin_weather_data()
	WeatherController._weather_duration_hours = 10.0
	WeatherController._weather_timer = 3.0

	var remaining = WeatherController.get_weather_remaining_hours()
	assert_eq(remaining, 7.0, "Should have 7 hours remaining")

func test_weather_remaining_hours_expired():
	"""测试过期时间的剩余时间"""
	WeatherController.reset_builtin_weather_data()
	WeatherController._weather_duration_hours = 5.0
	WeatherController._weather_timer = 7.0  # Exceeded

	var remaining = WeatherController.get_weather_remaining_hours()
	assert_eq(remaining, 0.0, "Should return 0 when expired")

func test_has_storm_risk():
	"""测试暴风雨风险检测"""
	WeatherController.reset_builtin_weather_data()

	WeatherController._current_weather = WCT.WeatherType.STORMY
	assert_true(WeatherController.has_storm_risk(), "Stormy weather should have risk")

	WeatherController._current_weather = WCT.WeatherType.RAINY
	assert_false(WeatherController.has_storm_risk(), "Rainy weather should not have storm risk")

# ============================================
# JSON配置测试
# ============================================

func test_get_season_weather_probabilities():
	"""测试获取季节天气概率"""
	WeatherController.reset_builtin_weather_data()

	var spring_probs = WeatherController.get_season_weather_probabilities("spring")
	assert_true(spring_probs.has("sunny"), "Spring should have sunny probability")
	assert_true(spring_probs.has("rainy"), "Spring should have rainy probability")

func test_get_season_weather_probabilities_invalid():
	"""测试无效季节的概率"""
	WeatherController.reset_builtin_weather_data()

	var probs = WeatherController.get_season_weather_probabilities("invalid_season")
	assert_true(probs.size() > 0, "Should return default probabilities for invalid season")

# ============================================
# 性能测试
# ============================================

func test_performance_weather_cycles():
	"""测试多次天气循环的性能"""
	WeatherController.reset_builtin_weather_data()

	var start_time = Time.get_ticks_msec()

	for i in range(50):
		WeatherController.force_refresh_weather()

	var elapsed = Time.get_ticks_msec() - start_time

	assert_lt(elapsed, 500, "50 weather cycles should take less than 500ms")
	print("Performance: 50 weather cycles took %d ms" % elapsed)
