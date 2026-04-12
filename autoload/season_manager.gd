# autoload/season_manager.gd
extends Node
## 季节管理器 - 产品级单例实现
## 负责游戏内季节循环、季节效果应用、季节事件触发
##
## 使用示例:
## ```gdscript
## # 获取当前季节
## var season = SeasonManager.get_current_season()
##
## # 推进一天
## SeasonManager.advance_day()
##
## # 连接信号
## SeasonManager.season_changed.connect(_on_season_changed)
## ```

# ============================================
# 信号定义
# ============================================
signal season_will_change(old_season: String, new_season: String, days_remaining: int)
signal season_changed(old_season: String, new_season: String)
signal day_progressed(day: int, season: String, year: int)
signal season_event_triggered(event_name: String, event_data: Dictionary)

# ============================================
# 常量定义
# ============================================
const SEASON_NAMES: Array[String] = ["spring", "summer", "fall", "winter"]
const CONFIG_FILE_PATH: String = "res://data/environment_configs/seasons.json"

# 存档键名
const SAVE_KEY_SEASON: String = "current_season_index"
const SAVE_KEY_DAY: String = "current_total_day"
const SAVE_KEY_YEAR: String = "current_year"
const SAVE_KEY_SEASON_DAY: String = "current_season_day"

# ============================================
# 状态变量 (私有)
# ============================================
var _current_season_index: int = 0
var _current_total_day: int = 1
var _current_year: int = 1
var _current_season_day: int = 1

var _season_configs: Dictionary = {}
var _is_initialized: bool = false

# ============================================
# 生命周期
# ============================================
func _ready() -> void:
	_initialize()

func _initialize() -> void:
	"""初始化季节管理器"""
	if _is_initialized:
		return

	print("[SeasonManager] Initializing...")

	# 加载季节配置
	_load_season_configs()

	# 加载保存的游戏状态
	_load_saved_state()

	# 应用当前季节效果
	_apply_season_effects(false)  # false = 不播放过渡动画

	_is_initialized = true

	# 连接到GameManager的日结束信号（如果存在）
	if Engine.has_singleton("GameManager") and GameManager.has_signal("day_ended"):
		GameManager.day_ended.connect(_on_game_manager_day_ended)

	print("[SeasonManager] Initialized - Current: %s, Day %d, Year %d" % [
		get_current_season(),
		_current_season_day,
		_current_year
	])

# ============================================
# 公共API - 状态查询
# ============================================

## 获取当前季节名称
func get_current_season() -> String:
	if _current_season_index < 0 or _current_season_index >= SEASON_NAMES.size():
		push_error("[SeasonManager] Invalid season index: %d" % _current_season_index)
		return "spring"
	return SEASON_NAMES[_current_season_index]

## 获取当前季节索引 (0-3)
func get_current_season_index() -> int:
	return _current_season_index

## 获取总天数（从游戏开始）
func get_current_total_day() -> int:
	return _current_total_day

## 获取当前年份
func get_current_year() -> int:
	return _current_year

## 获取当前季节的第几天 (1-28)
func get_season_day() -> int:
	return _current_season_day

## 获取当前季节的配置对象
func get_current_season_config() -> SeasonConfig:
	var season_name = get_current_season()
	if not _season_configs.has(season_name):
		push_error("[SeasonManager] No config for season: %s" % season_name)
		return _get_default_season_config()
	return _season_configs[season_name]

## 获取下一个季节的名称
func get_next_season_name() -> String:
	var next_index = (_current_season_index + 1) % SEASON_NAMES.size()
	return SEASON_NAMES[next_index]

## 获取距离下一季节的天数
func get_days_until_next_season() -> int:
	var config = get_current_season_config()
	return max(0, config.duration_days - _current_season_day)

## 检查是否是特定季节
func is_season(season_name: String) -> bool:
	return get_current_season() == season_name

# ============================================
# 公共API - 季节修正系数
# ============================================

## 获取季节对特定属性的修正系数
func get_season_modifier(stat_type: String) -> float:
	var config = get_current_season_config()

	match stat_type:
		"crop_growth":
			return config.crop_growth_multiplier
		"npc_energy_regen":
			return config.npc_energy_regen_modifier
		"npc_mood_base":
			return config.npc_mood_base_delta
		"player_energy_consumption":
			return config.player_energy_consumption_modifier
		"temperature_min":
			return config.temperature_range.x
		"temperature_max":
			return config.temperature_range.y
		"rain_probability":
			return config.rain_probability
		_:
			push_warning("[SeasonManager] Unknown stat type: %s, returning 1.0" % stat_type)
			return 1.0

## 获取当前季节的温度范围
func get_temperature_range() -> Vector2:
	var config = get_current_season_config()
	return config.temperature_range

## 获取当前基础温度（范围中值）
func get_base_temperature() -> float:
	var range = get_temperature_range()
	return (range.x + range.y) / 2.0

# ============================================
# 公共API - 时间推进
# ============================================

## 推进一天
func advance_day() -> void:
	_current_season_day += 1
	_current_total_day += 1

	# 发送日推进信号
	emit_signal("day_progressed", _current_total_day, get_current_season(), _current_year)

	# 检查是否换季
	var config = get_current_season_config()
	if _current_season_day > config.duration_days:
		_change_to_next_season()
	else:
		# 检查是否有今日特殊事件
		_check_daily_events()

	# 保存状态
	_save_state()

## 手动设置季节（用于调试或特殊剧情）
func set_season(season_name: String, notify: bool = true) -> bool:
	if not SEASON_NAMES.has(season_name):
		push_error("[SeasonManager] Cannot set season - invalid name: %s" % season_name)
		return false

	var old_index = _current_season_index
	var new_index = SEASON_NAMES.find(season_name)

	if old_index == new_index:
		return true  # 已经是目标季节

	print("[SeasonManager] Manually setting season: %s -> %s" % [
		SEASON_NAMES[old_index],
		season_name
	])

	if notify:
		emit_signal("season_will_change", SEASON_NAMES[old_index], season_name, 0)

	# 移除旧季节效果
	_remove_season_effects(SEASON_NAMES[old_index])

	# 更新状态
	_current_season_index = new_index
	_current_season_day = 1

	# 应用新季节效果
	_apply_season_effects(notify)

	if notify:
		emit_signal("season_changed", SEASON_NAMES[old_index], season_name)

	_save_state()
	return true

## 推进到下一年
func advance_year() -> void:
	_current_year += 1
	_current_season_index = 0  # 重置到春季
	_current_season_day = 1
	_current_total_day = 1

	print("[SeasonManager] New year started: Year %d" % _current_year)

	_apply_season_effects(true)
	_save_state()

# ============================================
# 私有方法 - 配置加载
# ============================================

func _load_season_configs() -> void:
	"""从JSON文件加载季节配置"""
	var file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)

	if not file:
		push_warning("[SeasonManager] Config file not found: %s. Using defaults." % CONFIG_FILE_PATH)
		_load_default_seasons()
		return

	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)

	if not data or not data.has("seasons"):
		push_error("[SeasonManager] Invalid config file format")
		_load_default_seasons()
		return

	var loaded_count = 0
	for season_data in data.seasons:
		var config = SeasonConfig.from_json(season_data)

		if config.validate():
			_season_configs[config.season_name] = config
			loaded_count += 1
			print("[SeasonManager] Loaded config: %s" % config.get_description())
		else:
			push_error("[SeasonManager] Failed to validate config for: %s" % season_data.get("name", "unknown"))

	if loaded_count != SEASON_NAMES.size():
		push_warning("[SeasonManager] Only loaded %d/%d seasons. Filling missing with defaults." % [
			loaded_count,
			SEASON_NAMES.size()
		])
		_fill_missing_default_seasons()

func reset_builtin_season_data() -> void:
	"""GUT / 工具：清空并载入内置四季表（不依赖 JSON 文件）。"""
	_season_configs.clear()
	_load_default_seasons()


func _load_default_seasons() -> void:
	"""加载默认季节配置（当配置文件缺失时）"""
	print("[SeasonManager] Loading default season configurations")

	var spring = SeasonConfig.new()
	spring.season_name = "spring"
	spring.duration_days = 28
	spring.temperature_range = Vector2(10, 25)
	spring.rain_probability = 0.3
	spring.crop_growth_multiplier = 1.0
	spring.npc_energy_regen_modifier = 1.2
	spring.npc_mood_base_delta = 0.1
	spring.sky_color = Color(0.7, 0.85, 1.0)
	_season_configs["spring"] = spring

	var summer = SeasonConfig.new()
	summer.season_name = "summer"
	summer.duration_days = 28
	summer.temperature_range = Vector2(20, 35)
	summer.rain_probability = 0.2
	summer.crop_growth_multiplier = 1.5
	summer.npc_energy_regen_modifier = 0.8
	summer.npc_mood_base_delta = -0.05
	summer.sky_color = Color(0.9, 0.95, 1.0)
	_season_configs["summer"] = summer

	var fall = SeasonConfig.new()
	fall.season_name = "fall"
	fall.duration_days = 28
	fall.temperature_range = Vector2(8, 22)
	fall.rain_probability = 0.25
	fall.crop_growth_multiplier = 0.8
	fall.npc_energy_regen_modifier = 1.0
	fall.npc_mood_base_delta = 0.05
	fall.sky_color = Color(1.0, 0.85, 0.6)
	_season_configs["fall"] = fall

	var winter = SeasonConfig.new()
	winter.season_name = "winter"
	winter.duration_days = 28
	winter.temperature_range = Vector2(-5, 8)
	winter.rain_probability = 0.15
	winter.crop_growth_multiplier = 0.0
	winter.npc_energy_regen_modifier = 0.7
	winter.npc_mood_base_delta = -0.1
	winter.sky_color = Color(0.8, 0.85, 0.95)
	_season_configs["winter"] = winter

func _fill_missing_default_seasons() -> void:
	"""为缺失的季节填充默认配置"""
	for season_name in SEASON_NAMES:
		if not _season_configs.has(season_name):
			print("[SeasonManager] Creating default config for: %s" % season_name)
			var default = SeasonConfig.new()
			default.season_name = season_name
			_season_configs[season_name] = default

func _get_default_season_config() -> SeasonConfig:
	"""返回一个默认的季节配置（fallback）"""
	var default = SeasonConfig.new()
	default.season_name = "spring"
	return default

# ============================================
# 私有方法 - 状态持久化
# ============================================

func _load_saved_state() -> void:
	"""从存档系统加载季节状态"""
	# 尝试使用GameStateManager（如果存在）
	if Engine.has_singleton("GameStateManager"):
		var gsm = Engine.get_singleton("GameStateManager")
		var save_data = gsm.load_section("season")
		if save_data:
			_current_season_index = save_data.get(SAVE_KEY_SEASON, 0)
			_current_total_day = save_data.get(SAVE_KEY_DAY, 1)
			_current_year = save_data.get(SAVE_KEY_YEAR, 1)
			_current_season_day = save_data.get(SAVE_KEY_SEASON_DAY, 1)
			print("[SeasonManager] Loaded saved state: Year %d, %s Day %d" % [
				_current_year,
				get_current_season(),
				_current_season_day
			])
			return

	# 如果没有存档，使用默认值（新游戏）
	print("[SeasonManager] No saved state found. Starting new game.")
	_current_season_index = 0  # Spring
	_current_total_day = 1
	_current_year = 1
	_current_season_day = 1

func _save_state() -> void:
	"""保存季节状态到存档系统"""
	var save_data = {
		SAVE_KEY_SEASON: _current_season_index,
		SAVE_KEY_DAY: _current_total_day,
		SAVE_KEY_YEAR: _current_year,
		SAVE_KEY_SEASON_DAY: _current_season_day
	}

	if Engine.has_singleton("GameStateManager"):
		Engine.get_singleton("GameStateManager").save_section("season", save_data)
	else:
		# Fallback: 使用ConfigFile
		var config = ConfigFile.new()
		config.set_value("season", SAVE_KEY_SEASON, _current_season_index)
		config.set_value("season", SAVE_KEY_DAY, _current_total_day)
		config.set_value("season", SAVE_KEY_YEAR, _current_year)
		config.set_value("season", SAVE_KEY_SEASON_DAY, _current_season_day)
		config.save("user://season_save.cfg")

# ============================================
# 私有方法 - 季节切换逻辑
# ============================================

func _change_to_next_season() -> void:
	"""切换到下一个季节"""
	var old_season = get_current_season()
	var old_index = _current_season_index

	# 计算新季节
	_current_season_index = (_current_season_index + 1) % SEASON_NAMES.size()
	_current_season_day = 1

	var new_season = get_current_season()

	print("[SeasonManager] Season changing: %s -> %s" % [old_season, new_season])

	# 发送即将切换信号（给UI预留动画时间）
	emit_signal("season_will_change", old_season, new_season, 0)

	# 移除旧季节效果
	_remove_season_effects(old_season)

	# 应用新季节效果
	_apply_season_effects(true)

	# 发送已切换信号
	emit_signal("season_changed", old_season, new_season)

	# 触发季节特殊事件
	_trigger_seasonal_events(new_season)

	# 检查是否需要进入新年
	if _current_season_index == 0:  # 回到春季
		advance_year()

func _apply_season_effects(with_transition: bool = true) -> void:
	"""应用当前季节的全局效果"""
	var config = get_current_season_config()
	var season_name = get_current_season()

	print("[SeasonManager] Applying effects for: %s" % season_name)

	# 1. 更新农场系统生长倍率
	if Engine.has_singleton("FarmManager"):
		var fm = Engine.get_singleton("FarmManager")
		if fm.has_method("set_global_growth_multiplier"):
			fm.set_global_growth_multiplier(config.crop_growth_multiplier)

	# 2. 更新NPC行为控制器
	if Engine.has_singleton("NPCBehaviorController"):
		var npc = Engine.get_singleton("NPCBehaviorController")
		if npc.has_method("update_seasonal_parameters"):
			npc.update_seasonal_parameters({
				"energy_regen": config.npc_energy_regen_modifier,
				"mood_base": config.npc_mood_base_delta
			})

	# 3. 更新视觉效果
	if with_transition:
		_update_visual_effects_smooth(config)
	else:
		_update_visual_effects_instant(config)

	# 4. 更新音频
	_update_audio_effects(config)

func _remove_season_effects(season_name: String) -> void:
	"""移除指定季节的效果"""
	print("[SeasonManager] Removing effects for: %s" % season_name)

	# 重置农场生长倍率
	if Engine.has_singleton("FarmManager"):
		var fm = Engine.get_singleton("FarmManager")
		if fm.has_method("set_global_growth_multiplier"):
			fm.set_global_growth_multiplier(1.0)

	# 注意：其他效果会在应用新季节时自动覆盖，无需显式移除

func _update_visual_effects_smooth(config: SeasonConfig) -> void:
	"""平滑过渡视觉效果"""
	var viewport = get_viewport()
	if not viewport:
		return

	var world_env = viewport.world_3d.environment if viewport.world_3d else null

	if world_env and world_env.sky:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)

		# 天空颜色渐变
		tween.tween_property(world_env.sky, "sky_color", config.sky_color, 2.0)

		# 环境光能量渐变
		if world_env.has_method("set_ambient_light_energy"):
			tween.tween_property(world_env, "ambient_light_energy", config.ambient_light_energy, 2.0)

func _update_visual_effects_instant(config: SeasonConfig) -> void:
	"""立即应用视觉效果（无动画）"""
	var viewport = get_viewport()
	if not viewport:
		return

	var world_env = viewport.world_3d.environment if viewport.world_3d else null

	if world_env and world_env.sky:
		world_env.sky.sky_color = config.sky_color
		if world_env.has_method("set_ambient_light_energy"):
			world_env.ambient_light_energy = config.ambient_light_energy

func _update_audio_effects(config: SeasonConfig) -> void:
	"""更新音频效果"""
	if config.ambient_soundtrack_path.is_empty():
		return

	if Engine.has_singleton("AudioManager"):
		Engine.get_singleton("AudioManager").fade_to_track(config.ambient_soundtrack_path, 3.0)
	else:
		print("[SeasonManager] AudioManager not found. Skipping audio update.")

func _trigger_seasonal_events(season_name: String) -> void:
	"""触发季节特殊事件"""
	var config = get_current_season_config()

	for event_name in config.special_events:
		print("[SeasonManager] Triggering seasonal event: %s" % event_name)

		emit_signal("season_event_triggered", event_name, {
			"season": season_name,
			"day": _current_season_day,
			"year": _current_year
		})

func _check_daily_events() -> void:
	"""检查并触发每日事件"""
	# 这里可以扩展为更复杂的事件系统
	# 目前仅作为占位符
	pass

# ============================================
# 信号处理器
# ============================================

func _on_game_manager_day_ended() -> void:
	"""响应GameManager的日结束信号"""
	advance_day()

# ============================================
# 调试工具
# ============================================

## 打印当前季节状态（用于调试）
func debug_print_status() -> void:
	print("=== SeasonManager Debug Status ===")
	print("Current Season: %s (index: %d)" % [get_current_season(), _current_season_index])
	print("Season Day: %d / %d" % [_current_season_day, get_current_season_config().duration_days])
	print("Total Day: %d" % _current_total_day)
	print("Year: %d" % _current_year)
	print("Days until next season: %d" % get_days_until_next_season())
	print("Temperature Range: %.1f - %.1f °C" % [
		get_current_season_config().temperature_range.x,
		get_current_season_config().temperature_range.y
	])
	print("Crop Growth Multiplier: %.2fx" % get_season_modifier("crop_growth"))
	print("==================================")

## 快速测试：立即切换到下一个季节
func debug_skip_to_next_season() -> void:
	_change_to_next_season()
