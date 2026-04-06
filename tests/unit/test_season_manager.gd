# tests/unit/test_season_manager.gd
extends GutTest
## SeasonManager单元测试套件

var season_manager = null

func before_all():
	"""测试套件初始化"""
	print("=== SeasonManager Test Suite Starting ===")

func before_each():
	"""每个测试前的设置"""
	# 创建SeasonManager实例进行测试
	season_manager = preload("res://autoload/season_manager.gd").new()

func after_each():
	"""每个测试后的清理"""
	if season_manager:
		season_manager.queue_free()
		season_manager = null

# ============================================
# 配置加载测试
# ============================================

func test_load_default_seasons():
	"""测试默认季节配置加载"""
	season_manager._load_default_seasons()

	assert_eq(season_manager._season_configs.size(), 4, "Should load 4 seasons")
	assert_true(season_manager._season_configs.has("spring"), "Should have spring")
	assert_true(season_manager._season_configs.has("summer"), "Should have summer")
	assert_true(season_manager._season_configs.has("fall"), "Should have fall")
	assert_true(season_manager._season_configs.has("winter"), "Should have winter")

func test_season_config_validation():
	"""测试季节配置验证"""
	var config = SeasonConfig.new()
	config.season_name = "test_season"
	config.duration_days = 28
	config.temperature_range = Vector2(10, 25)

	assert_true(config.validate(), "Valid config should pass validation")

	# 测试无效配置
	var invalid_config = SeasonConfig.new()
	invalid_config.season_name = ""  # Empty name
	assert_false(invalid_config.validate(), "Empty name should fail validation")

	invalid_config.season_name = "test"
	invalid_config.temperature_range = Vector2(30, 20)  # Invalid range
	assert_false(invalid_config.validate(), "Invalid temp range should fail validation")

# ============================================
# 状态查询测试
# ============================================

func test_get_current_season_initial():
	"""测试初始季节状态"""
	season_manager._load_default_seasons()
	season_manager._current_season_index = 0

	assert_eq(season_manager.get_current_season(), "spring", "Initial season should be spring")
	assert_eq(season_manager.get_current_season_index(), 0, "Initial index should be 0")

func test_get_season_day():
	"""测试季节天数查询"""
	season_manager._load_default_seasons()
	season_manager._current_season_day = 15

	assert_eq(season_manager.get_season_day(), 15, "Season day should be 15")

func test_get_days_until_next_season():
	"""测试距离下一季节的天数"""
	season_manager._load_default_seasons()
	season_manager._current_season_day = 10

	var days_left = season_manager.get_days_until_next_season()
	assert_eq(days_left, 18, "Should have 18 days left (28-10)")

func test_is_season():
	"""测试季节检查"""
	season_manager._load_default_seasons()
	season_manager._current_season_index = 1  # Summer

	assert_true(season_manager.is_season("summer"), "Should be summer")
	assert_false(season_manager.is_season("winter"), "Should not be winter")

# ============================================
# 季节修正系数测试
# ============================================

func test_get_season_modifier_crop_growth():
	"""测试作物生长修正系数"""
	season_manager._load_default_seasons()

	# Spring
	season_manager._current_season_index = 0
	assert_eq(season_manager.get_season_modifier("crop_growth"), 1.0, "Spring growth should be 1.0x")

	# Summer
	season_manager._current_season_index = 1
	assert_eq(season_manager.get_season_modifier("crop_growth"), 1.5, "Summer growth should be 1.5x")

	# Winter
	season_manager._current_season_index = 3
	assert_eq(season_manager.get_season_modifier("crop_growth"), 0.0, "Winter growth should be 0.0x")

func test_get_temperature_range():
	"""测试温度范围查询"""
	season_manager._load_default_seasons()
	season_manager._current_season_index = 0  # Spring

	var range = season_manager.get_temperature_range()
	assert_eq(range.x, 10, "Spring min temp should be 10")
	assert_eq(range.y, 25, "Spring max temp should be 25")

# ============================================
# 时间推进测试
# ============================================

func test_advance_day_same_season():
	"""测试同季节内推进一天"""
	season_manager._load_default_seasons()
	season_manager._current_season_day = 10
	season_manager._current_total_day = 10

	season_manager.advance_day()

	assert_eq(season_manager._current_season_day, 11, "Season day should increment")
	assert_eq(season_manager._current_total_day, 11, "Total day should increment")

func test_advance_day_season_change():
	"""测试跨季节推进"""
	season_manager._load_default_seasons()
	season_manager._current_season_index = 0  # Spring
	season_manager._current_season_day = 28  # Last day of spring

	var old_season = season_manager.get_current_season()
	season_manager.advance_day()

	assert_eq(season_manager.get_current_season(), "summer", "Should change to summer")
	assert_eq(season_manager._current_season_day, 1, "New season should start at day 1")

func test_set_season_valid():
	"""测试有效季节设置"""
	season_manager._load_default_seasons()

	var result = season_manager.set_season("winter")
	assert_true(result, "Setting valid season should succeed")
	assert_eq(season_manager.get_current_season(), "winter", "Season should be winter")
	assert_eq(season_manager._current_season_day, 1, "Season day should reset to 1")

func test_set_season_invalid():
	"""测试无效季节设置"""
	season_manager._load_default_seasons()

	var result = season_manager.set_season("invalid_season")
	assert_false(result, "Setting invalid season should fail")

# ============================================
# 信号测试
# ============================================

func test_season_changed_signal():
	"""测试季节切换信号"""
	season_manager._load_default_seasons()

	var signal_received = false
	var old_season_received = ""
	var new_season_received = ""

	season_manager.season_changed.connect(func(old_s, new_s):
		signal_received = true
		old_season_received = old_s
		new_season_received = new_s
	)

	season_manager._current_season_index = 0
	season_manager._current_season_day = 28
	season_manager.advance_day()

	assert_true(signal_received, "season_changed signal should be emitted")
	assert_eq(old_season_received, "spring", "Old season should be spring")
	assert_eq(new_season_received, "summer", "New season should be summer")

func test_day_progressed_signal():
	"""测试日推进信号"""
	season_manager._load_default_seasons()

	var signal_received = false
	var day_received = 0

	season_manager.day_progressed.connect(func(day, season, year):
		signal_received = true
		day_received = day
	)

	season_manager._current_total_day = 5
	season_manager.advance_day()

	assert_true(signal_received, "day_progressed signal should be emitted")
	assert_eq(day_received, 6, "Day should be 6")

# ============================================
# 边界情况测试
# ============================================

func test_year_advance():
	"""测试年份推进"""
	season_manager._load_default_seasons()
	season_manager._current_year = 1
	season_manager._current_season_index = 3  # Winter
	season_manager._current_season_day = 28

	season_manager.advance_day()  # Should trigger new year

	assert_eq(season_manager._current_year, 2, "Year should advance to 2")
	assert_eq(season_manager.get_current_season(), "spring", "Should reset to spring")

func test_get_days_until_next_season_last_day():
	"""测试季节最后一天的剩余天数"""
	season_manager._load_default_seasons()
	season_manager._current_season_day = 28

	var days_left = season_manager.get_days_until_next_season()
	assert_eq(days_left, 0, "Should have 0 days left on last day")

# ============================================
# JSON序列化测试
# ============================================

func test_season_config_to_json():
	"""测试季节配置JSON序列化"""
	var config = SeasonConfig.new()
	config.season_name = "spring"
	config.duration_days = 28
	config.temperature_range = Vector2(10, 25)
	config.crop_growth_multiplier = 1.5

	var json_data = config.to_json()

	assert_eq(json_data.name, "spring", "Name should serialize correctly")
	assert_eq(json_data.duration_days, 28, "Duration should serialize correctly")
	assert_eq(json_data.temp_min, 10, "Min temp should serialize correctly")
	assert_eq(json_data.crop_growth_multiplier, 1.5, "Growth multiplier should serialize correctly")

func test_season_config_from_json():
	"""测试从JSON创建季节配置"""
	var json_data = {
		"name": "summer",
		"duration_days": 30,
		"temp_min": 20,
		"temp_max": 35,
		"crop_growth_multiplier": 1.8
	}

	var config = SeasonConfig.from_json(json_data)

	assert_eq(config.season_name, "summer", "Name should deserialize correctly")
	assert_eq(config.duration_days, 30, "Duration should deserialize correctly")
	assert_eq(config.temperature_range.x, 20, "Min temp should deserialize correctly")
	assert_eq(config.temperature_range.y, 35, "Max temp should deserialize correctly")
	assert_eq(config.crop_growth_multiplier, 1.8, "Growth multiplier should deserialize correctly")

# ============================================
# 性能测试
# ============================================

func test_performance_multiple_advances():
	"""测试多次推进的性能"""
	season_manager._load_default_seasons()

	var start_time = Time.get_ticks_msec()

	for i in range(100):
		season_manager.advance_day()

	var elapsed = Time.get_ticks_msec() - start_time

	assert_lt(elapsed, 1000, "100 day advances should take less than 1 second")
	print("Performance: 100 advances took %d ms" % elapsed)
