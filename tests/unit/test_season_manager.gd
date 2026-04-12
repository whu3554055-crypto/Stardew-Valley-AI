# tests/unit/test_season_manager.gd
extends GutTest
## SeasonManager单元测试套件

var _season_sig_received: bool = false
var _season_sig_old: String = ""
var _season_sig_new: String = ""

var _day_sig_received: bool = false
var _day_sig_day: int = 0

func _on_season_changed_for_test(old_s: String, new_s: String) -> void:
	_season_sig_received = true
	_season_sig_old = old_s
	_season_sig_new = new_s

func _on_day_progressed_for_test(day: int, _season: String, _year: int) -> void:
	_day_sig_received = true
	_day_sig_day = day

func before_all():
	"""测试套件初始化"""
	print("=== SeasonManager Test Suite Starting ===")

func before_each():
	"""每个测试前重置内置表（与 autoload 单例配合；preload 脚本已注册为单例时无法 .new()）。"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_index = 0
	SeasonManager._current_season_day = 1
	SeasonManager._current_total_day = 1
	SeasonManager._current_year = 1

# ============================================
# 配置加载测试
# ============================================

func test_load_default_seasons():
	"""测试默认季节配置加载"""
	SeasonManager.reset_builtin_season_data()

	assert_eq(SeasonManager._season_configs.size(), 4, "Should load 4 seasons")
	assert_true(SeasonManager._season_configs.has("spring"), "Should have spring")
	assert_true(SeasonManager._season_configs.has("summer"), "Should have summer")
	assert_true(SeasonManager._season_configs.has("fall"), "Should have fall")
	assert_true(SeasonManager._season_configs.has("winter"), "Should have winter")

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

	assert_push_error(2, "expected validation push_error calls")

# ============================================
# 状态查询测试
# ============================================

func test_get_current_season_initial():
	"""测试初始季节状态"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_index = 0

	assert_eq(SeasonManager.get_current_season(), "spring", "Initial season should be spring")
	assert_eq(SeasonManager.get_current_season_index(), 0, "Initial index should be 0")

func test_get_season_day():
	"""测试季节天数查询"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_day = 15

	assert_eq(SeasonManager.get_season_day(), 15, "Season day should be 15")

func test_get_days_until_next_season():
	"""测试距离下一季节的天数"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_day = 10

	var days_left = SeasonManager.get_days_until_next_season()
	assert_eq(days_left, 18, "Should have 18 days left (28-10)")

func test_is_season():
	"""测试季节检查"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_index = 1  # Summer

	assert_true(SeasonManager.is_season("summer"), "Should be summer")
	assert_false(SeasonManager.is_season("winter"), "Should not be winter")

# ============================================
# 季节修正系数测试
# ============================================

func test_get_season_modifier_crop_growth():
	"""测试作物生长修正系数"""
	SeasonManager.reset_builtin_season_data()

	# Spring
	SeasonManager._current_season_index = 0
	assert_eq(SeasonManager.get_season_modifier("crop_growth"), 1.0, "Spring growth should be 1.0x")

	# Summer
	SeasonManager._current_season_index = 1
	assert_eq(SeasonManager.get_season_modifier("crop_growth"), 1.5, "Summer growth should be 1.5x")

	# Winter
	SeasonManager._current_season_index = 3
	assert_eq(SeasonManager.get_season_modifier("crop_growth"), 0.0, "Winter growth should be 0.0x")

func test_get_temperature_range():
	"""测试温度范围查询"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_index = 0  # Spring

	var temp_rng: Vector2 = SeasonManager.get_temperature_range()
	assert_eq(temp_rng.x, 10, "Spring min temp should be 10")
	assert_eq(temp_rng.y, 25, "Spring max temp should be 25")

# ============================================
# 时间推进测试
# ============================================

func test_advance_day_same_season():
	"""测试同季节内推进一天"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_day = 10
	SeasonManager._current_total_day = 10

	SeasonManager.advance_day()

	assert_eq(SeasonManager._current_season_day, 11, "Season day should increment")
	assert_eq(SeasonManager._current_total_day, 11, "Total day should increment")

func test_advance_day_season_change():
	"""测试跨季节推进"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_index = 0  # Spring
	SeasonManager._current_season_day = 28  # Last day of spring

	var old_season = SeasonManager.get_current_season()
	SeasonManager.advance_day()

	assert_eq(SeasonManager.get_current_season(), "summer", "Should change to summer")
	assert_eq(SeasonManager._current_season_day, 1, "New season should start at day 1")

func test_set_season_valid():
	"""测试有效季节设置"""
	SeasonManager.reset_builtin_season_data()

	var result = SeasonManager.set_season("winter")
	assert_true(result, "Setting valid season should succeed")
	assert_eq(SeasonManager.get_current_season(), "winter", "Season should be winter")
	assert_eq(SeasonManager._current_season_day, 1, "Season day should reset to 1")

func test_set_season_invalid():
	"""测试无效季节设置"""
	SeasonManager.reset_builtin_season_data()

	var result = SeasonManager.set_season("invalid_season")
	assert_false(result, "Setting invalid season should fail")

	assert_push_error(1, "expected invalid season push_error")

# ============================================
# 信号测试
# ============================================

func test_season_changed_signal():
	"""测试季节切换信号"""
	SeasonManager.reset_builtin_season_data()

	_season_sig_received = false
	_season_sig_old = ""
	_season_sig_new = ""
	SeasonManager.season_changed.connect(_on_season_changed_for_test)

	SeasonManager._current_season_index = 0
	SeasonManager._current_season_day = 28
	SeasonManager.advance_day()

	assert_true(_season_sig_received, "season_changed signal should be emitted")
	assert_eq(_season_sig_old, "spring", "Old season should be spring")
	assert_eq(_season_sig_new, "summer", "New season should be summer")
	SeasonManager.season_changed.disconnect(_on_season_changed_for_test)

func test_day_progressed_signal():
	"""测试日推进信号"""
	SeasonManager.reset_builtin_season_data()

	_day_sig_received = false
	_day_sig_day = 0
	SeasonManager.day_progressed.connect(_on_day_progressed_for_test)

	SeasonManager._current_total_day = 5
	SeasonManager.advance_day()

	assert_true(_day_sig_received, "day_progressed signal should be emitted")
	assert_eq(_day_sig_day, 6, "Day should be 6")
	SeasonManager.day_progressed.disconnect(_on_day_progressed_for_test)

# ============================================
# 边界情况测试
# ============================================

func test_year_advance():
	"""测试年份推进"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_year = 1
	SeasonManager._current_season_index = 3  # Winter
	SeasonManager._current_season_day = 28

	SeasonManager.advance_day()  # Should trigger new year

	assert_eq(SeasonManager._current_year, 2, "Year should advance to 2")
	assert_eq(SeasonManager.get_current_season(), "spring", "Should reset to spring")

func test_get_days_until_next_season_last_day():
	"""测试季节最后一天的剩余天数"""
	SeasonManager.reset_builtin_season_data()
	SeasonManager._current_season_day = 28

	var days_left = SeasonManager.get_days_until_next_season()
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
	SeasonManager.reset_builtin_season_data()

	var start_time = Time.get_ticks_msec()

	for i in range(100):
		SeasonManager.advance_day()

	var elapsed = Time.get_ticks_msec() - start_time

	assert_lt(elapsed, 1000, "100 day advances should take less than 1 second")
	print("Performance: 100 advances took %d ms" % elapsed)
