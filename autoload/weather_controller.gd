# autoload/weather_controller.gd
extends Node
## 天气控制器 - 产品级单例实现
## 负责动态天气系统、天气概率、天气效果应用
##
## 使用示例:
## ```gdscript
## # 获取当前天气
## var weather = WeatherController.get_current_weather()
##
## # 手动设置天气
## WeatherController.set_weather(WeatherController.WeatherType.RAINY)
##
## # 连接信号
## WeatherController.weather_changed.connect(_on_weather_changed)
## ```

# ============================================
# 枚举定义
# ============================================
enum WeatherType {
	SUNNY,
	CLOUDY,
	RAINY,
	STORMY,
	SNOWY,
	FOGGY
}

const WEATHER_TYPE_NAMES: Dictionary = {
	WeatherType.SUNNY: "sunny",
	WeatherType.CLOUDY: "cloudy",
	WeatherType.RAINY: "rainy",
	WeatherType.STORMY: "stormy",
	WeatherType.SNOWY: "snowy",
	WeatherType.FOGGY: "foggy"
}

# ============================================
# 信号定义
# ============================================
signal weather_changed(old_weather: int, new_weather: int)
signal weather_updated(weather_data: Dictionary)
signal storm_warning(active: bool)
signal crop_watered_by_rain()

# ============================================
# 常量定义
# ============================================
const CONFIG_FILE_PATH: String = "res://data/environment_configs/weather.json"
const SAVE_KEY_WEATHER: String = "current_weather_type"
const SAVE_KEY_WEATHER_TIMER: String = "weather_timer"

# ============================================
# 状态变量 (私有)
# ============================================
var _current_weather: WeatherType = WeatherType.SUNNY
var _weather_timer: float = 0.0
var _weather_duration_hours: float = 6.0

var _weather_configs: Dictionary = {}
var _season_probabilities: Dictionary = {}
var _duration_range: Dictionary = {"min_hours": 4.0, "max_hours": 12.0}

var _is_initialized: bool = false
var _storm_active: bool = false

# ============================================
# 生命周期
# ============================================
func _ready() -> void:
	_initialize()

func _process(delta: float) -> void:
	if not _is_initialized:
		return

	# 更新天气计时器
	_weather_timer += delta / 3600.0  # 转换为游戏小时

	# 检查是否需要切换天气
	if _weather_timer >= _weather_duration_hours:
		_generate_new_weather()
		_weather_timer = 0.0

func _initialize() -> void:
	"""初始化天气控制器"""
	if _is_initialized:
		return

	print("[WeatherController] Initializing...")

	# 加载天气配置
	_load_weather_configs()

	# 加载保存的状态
	_load_saved_state()

	# 应用当前天气效果
	_apply_weather_effects(false)

	_is_initialized = true

	# 连接到季节管理器（如果存在）
	if Engine.has_singleton("SeasonManager"):
		Engine.get_singleton("SeasonManager").day_progressed.connect(_on_new_day)

	print("[WeatherController] Initialized - Current: %s" % get_weather_name(_current_weather))

# ============================================
# 公共API - 状态查询
# ============================================

## 获取当前天气类型枚举值
func get_current_weather_type() -> WeatherType:
	return _current_weather

## 获取当前天气名称（英文）
func get_current_weather_name() -> String:
	return get_weather_name(_current_weather)

## 获取当前天气配置字典
func get_current_weather_config() -> Dictionary:
	var weather_name = WEATHER_TYPE_NAMES[_current_weather]
	if not _weather_configs.has(weather_name):
		push_error("[WeatherController] No config for weather: %s" % weather_name)
		return {}
	return _weather_configs[weather_name]

## 获取天气的人类可读名称（支持多语言）
func get_weather_name(weather_type: WeatherType) -> String:
	var weather_name = WEATHER_TYPE_NAMES.get(weather_type, "unknown")
	var config = _weather_configs.get(weather_name, {})
	return config.get("name", weather_name.capitalize())

## 获取天气的中文名称
func get_weather_name_zh(weather_type: WeatherType) -> String:
	var weather_name = WEATHER_TYPE_NAMES.get(weather_type, "unknown")
	var config = _weather_configs.get(weather_name, {})
	return config.get("name_zh", weather_name.capitalize())

## 获取剩余天气持续时间（小时）
func get_weather_remaining_hours() -> float:
	return max(0.0, _weather_duration_hours - _weather_timer)

## 检查是否是特定天气
func is_weather(weather_type: WeatherType) -> bool:
	return _current_weather == weather_type

## 检查当前是否下雨/雪（作物自动浇水）
func is_precipitation() -> bool:
	var config = get_current_weather_config()
	return config.get("crop_watering", false)

## 检查是否有暴风雨风险
func has_storm_risk() -> bool:
	return _current_weather == WeatherType.STORMY

# ============================================
# 公共API - 天气修正系数
# ============================================

## 获取天气对特定属性的修正系数
func get_weather_modifier(stat_type: String) -> float:
	var config = get_current_weather_config()

	match stat_type:
		"npc_outdoor_activity":
			return config.get("npc_outdoor_activity_multiplier", 1.0)
		"npc_mood":
			return config.get("npc_mood_delta", 0.0)
		"player_energy":
			return config.get("player_energy_consumption_modifier", 1.0)
		"crop_watered":
			return 1.0 if config.get("crop_watering", false) else 0.0
		"damage_risk":
			return config.get("damage_risk", 0.0)
		"light_intensity":
			var visual = config.get("visual_effects", {})
			return visual.get("light_intensity", 1.0)
		_:
			push_warning("[WeatherController] Unknown stat type: %s" % stat_type)
			return 1.0

## 获取当前天气的视觉效果配置
func get_visual_effects() -> Dictionary:
	var config = get_current_weather_config()
	return config.get("visual_effects", {})

## 获取当前天气的音频覆盖
func get_audio_override() -> String:
	var config = get_current_weather_config()
	return config.get("audio_override", "")

# ============================================
# 公共API - 天气控制
# ============================================

## 手动设置天气（用于调试或特殊事件）
func set_weather(weather_type: WeatherType, notify: bool = true) -> bool:
	if not WEATHER_TYPE_NAMES.has(weather_type):
		push_error("[WeatherController] Invalid weather type: %d" % weather_type)
		return false

	var old_weather = _current_weather

	if old_weather == weather_type:
		return true  # 已经是该天气

	print("[WeatherController] Manually setting weather: %s -> %s" % [
		get_weather_name(old_weather),
		get_weather_name(weather_type)
	])

	if notify:
		emit_signal("weather_changed", old_weather, weather_type)

	# 移除旧天气效果
	_remove_weather_effects(old_weather)

	# 更新状态
	_current_weather = weather_type

	# 应用新天气效果
	_apply_weather_effects(notify)

	# 重置计时器并生成新持续时间
	_weather_timer = 0.0
	_weather_duration_hours = _generate_weather_duration()

	if notify:
		emit_signal("weather_updated", get_current_weather_config())

	_save_state()
	return true

## 强制刷新天气（不等待计时器）
func force_refresh_weather() -> void:
	_generate_new_weather()
	_weather_timer = 0.0

## 获取基于季节的天气概率表
func get_season_weather_probabilities(season: String) -> Dictionary:
	if _season_probabilities.has(season):
		return _season_probabilities[season]

	# 返回默认概率
	return {
		"sunny": 0.4,
		"cloudy": 0.3,
		"rainy": 0.2,
		"stormy": 0.1
	}

# ============================================
# 私有方法 - 配置加载
# ============================================

func _load_weather_configs() -> void:
	"""从JSON文件加载天气配置"""
	var file = FileAccess.open(CONFIG_FILE_PATH, FileAccess.READ)

	if not file:
		push_warning("[WeatherController] Config file not found: %s. Using defaults." % CONFIG_FILE_PATH)
		_load_default_weather_configs()
		return

	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)

	if not data:
		push_error("[WeatherController] Invalid config file format")
		_load_default_weather_configs()
		return

	# 加载天气类型配置
	if data.has("weather_types"):
		_weather_configs = data.weather_types
		print("[WeatherController] Loaded %d weather types" % _weather_configs.size())

	# 加载季节概率
	if data.has("season_probabilities"):
		_season_probabilities = data.season_probabilities
		print("[WeatherController] Loaded season probabilities")

	# 加载持续时间范围
	if data.has("duration_range"):
		_duration_range = data.duration_range

func reset_builtin_weather_data() -> void:
	"""GUT / 工具：载入内置天气表与季节概率。"""
	_load_default_weather_configs()
	_current_weather = WeatherType.SUNNY
	_weather_timer = 0.0
	_storm_active = false


func weather_type_from_name(name: String) -> WeatherType:
	return _get_weather_type_from_name(name)


func roll_weather_duration_hours() -> float:
	return _generate_weather_duration()


func _load_default_weather_configs() -> void:
	"""加载默认天气配置"""
	print("[WeatherController] Loading default weather configurations")

	_weather_configs = {
		"sunny": {
			"name": "Sunny",
			"crop_watering": false,
			"npc_outdoor_activity_multiplier": 1.0,
			"npc_mood_delta": 0.1,
			"visual_effects": {"light_intensity": 1.2}
		},
		"cloudy": {
			"name": "Cloudy",
			"crop_watering": false,
			"npc_outdoor_activity_multiplier": 0.8,
			"npc_mood_delta": 0.0,
			"visual_effects": {"light_intensity": 0.9}
		},
		"rainy": {
			"name": "Rainy",
			"crop_watering": true,
			"npc_outdoor_activity_multiplier": 0.3,
			"npc_mood_delta": -0.05,
			"visual_effects": {"light_intensity": 0.7}
		},
		"stormy": {
			"name": "Stormy",
			"crop_watering": true,
			"npc_outdoor_activity_multiplier": 0.0,
			"npc_mood_delta": -0.2,
			"damage_risk": 0.15,
			"visual_effects": {"light_intensity": 0.4}
		},
		"snowy": {
			"name": "Snowy",
			"crop_watering": false,
			"npc_outdoor_activity_multiplier": 0.2,
			"npc_mood_delta": 0.05,
			"visual_effects": {"light_intensity": 0.9}
		},
		"foggy": {
			"name": "Foggy",
			"crop_watering": false,
			"npc_outdoor_activity_multiplier": 0.5,
			"npc_mood_delta": -0.1,
			"visual_effects": {"light_intensity": 0.6}
		}
	}

	_season_probabilities = {
		"spring": {"sunny": 0.40, "cloudy": 0.25, "rainy": 0.30, "stormy": 0.05},
		"summer": {"sunny": 0.50, "cloudy": 0.20, "rainy": 0.15, "stormy": 0.15},
		"fall": {"sunny": 0.45, "cloudy": 0.30, "rainy": 0.20, "foggy": 0.05},
		"winter": {"sunny": 0.30, "cloudy": 0.30, "snowy": 0.35, "stormy": 0.05}
	}

# ============================================
# 私有方法 - 天气生成逻辑
# ============================================

func _generate_new_weather() -> void:
	"""根据季节概率生成新天气"""
	var season = "spring"
	if Engine.has_singleton("SeasonManager"):
		season = Engine.get_singleton("SeasonManager").get_current_season()

	var probabilities = get_season_weather_probabilities(season)

	# 加权随机选择
	var roll = randf()
	var cumulative = 0.0
	var selected_weather_name = "sunny"

	for weather_name in probabilities.keys():
		cumulative += probabilities[weather_name]
		if roll <= cumulative:
			selected_weather_name = weather_name
			break

	# 转换为枚举值
	var new_weather = _get_weather_type_from_name(selected_weather_name)

	set_weather(new_weather, true)

func _get_weather_type_from_name(name: String) -> WeatherType:
	"""将天气名称转换为枚举值"""
	for type_value in WEATHER_TYPE_NAMES.keys():
		if WEATHER_TYPE_NAMES[type_value] == name:
			return type_value

	push_warning("[WeatherController] Unknown weather name: %s, defaulting to SUNNY" % name)
	return WeatherType.SUNNY

func _generate_weather_duration() -> float:
	"""生成随机的天气持续时间"""
	var min_hours = _duration_range.get("min_hours", 4.0)
	var max_hours = _duration_range.get("max_hours", 12.0)

	return min_hours + randf() * (max_hours - min_hours)

# ============================================
# 私有方法 - 效果应用
# ============================================

func _apply_weather_effects(with_transition: bool = true) -> void:
	"""应用当前天气的全局效果"""
	var config = get_current_weather_config()
	var weather_name = get_weather_name(_current_weather)

	print("[WeatherController] Applying effects for: %s" % weather_name)

	# 1. 如果是降水天气，自动浇水
	if config.get("crop_watering", false):
		_auto_water_crops()

	# 2. 更新NPC行为
	if Engine.has_singleton("NPCBehaviorController"):
		var npc = Engine.get_singleton("NPCBehaviorController")
		if npc.has_method("update_weather_behavior"):
			npc.update_weather_behavior(_current_weather)

	# 3. 更新视觉效果
	if with_transition:
		_update_visual_effects_smooth(config)
	else:
		_update_visual_effects_instant(config)

	# 4. 更新音频
	_update_audio_effects(config)

	# 5. 检查暴风雨警告
	if _current_weather == WeatherType.STORMY:
		if not _storm_active:
			_storm_active = true
			emit_signal("storm_warning", true)
	else:
		if _storm_active:
			_storm_active = false
			emit_signal("storm_warning", false)

func _remove_weather_effects(old_weather: WeatherType) -> void:
	"""移除旧天气的效果"""
	var old_name = get_weather_name(old_weather)
	print("[WeatherController] Removing effects for: %s" % old_name)

	# 重置暴风雨标志
	if old_weather == WeatherType.STORMY:
		_storm_active = false
		emit_signal("storm_warning", false)

func _auto_water_crops() -> void:
	"""自动浇灌所有作物"""
	if Engine.has_singleton("FarmManager"):
		var fm = Engine.get_singleton("FarmManager")
		if fm.has_method("auto_water_all_crops"):
			fm.auto_water_all_crops()
		emit_signal("crop_watered_by_rain")
		print("[WeatherController] Crops watered by rain")

func _update_visual_effects_smooth(config: Dictionary) -> void:
	"""平滑过渡视觉效果"""
	var visual = config.get("visual_effects", {})

	var viewport = get_viewport()
	if not viewport:
		return

	var world_env = viewport.world_3d.environment if viewport.world_3d else null

	if world_env:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)

		# 光照强度渐变
		if visual.has("light_intensity"):
			tween.tween_property(world_env, "ambient_light_energy", visual.light_intensity, 2.0)

		# 雾密度渐变
		if visual.has("fog_density"):
			if world_env.has_method("set_fog_density"):
				tween.tween_property(world_env, "fog_density", visual.fog_density, 2.0)

func _update_visual_effects_instant(config: Dictionary) -> void:
	"""立即应用视觉效果"""
	var visual = config.get("visual_effects", {})

	var viewport = get_viewport()
	if not viewport:
		return

	var world_env = viewport.world_3d.environment if viewport.world_3d else null

	if world_env:
		if visual.has("light_intensity"):
			world_env.ambient_light_energy = visual.light_intensity

func _update_audio_effects(config: Dictionary) -> void:
	"""更新音频效果"""
	var audio_override = config.get("audio_override", "")

	if audio_override.is_empty():
		return

	if Engine.has_singleton("AudioManager"):
		Engine.get_singleton("AudioManager").play_ambient(audio_override)
	else:
		print("[WeatherController] AudioManager not found. Skipping audio update.")

# ============================================
# 私有方法 - 状态持久化
# ============================================

func _load_saved_state() -> void:
	"""加载保存的天气状态"""
	if Engine.has_singleton("GameStateManager"):
		var gsm = Engine.get_singleton("GameStateManager")
		var save_data = gsm.load_section("weather")
		if save_data:
			_current_weather = save_data.get(SAVE_KEY_WEATHER, WeatherType.SUNNY)
			_weather_timer = save_data.get(SAVE_KEY_WEATHER_TIMER, 0.0)
			print("[WeatherController] Loaded saved state: %s" % get_weather_name(_current_weather))
			return

	# 默认状态
	_current_weather = WeatherType.SUNNY
	_weather_timer = 0.0
	_weather_duration_hours = _generate_weather_duration()

func _save_state() -> void:
	"""保存天气状态"""
	var save_data = {
		SAVE_KEY_WEATHER: _current_weather,
		SAVE_KEY_WEATHER_TIMER: _weather_timer
	}

	if Engine.has_singleton("GameStateManager"):
		Engine.get_singleton("GameStateManager").save_section("weather", save_data)

# ============================================
# 信号处理器
# ============================================

func _on_new_day(day: int, season: String, year: int) -> void:
	"""新的一天开始时重新生成天气"""
	print("[WeatherController] New day started, generating new weather")
	_force_generate_weather_for_day(season)

func _force_generate_weather_for_day(season: String) -> void:
	"""为每一天强制生成天气（考虑季节）"""
	var probabilities = get_season_weather_probabilities(season)

	var roll = randf()
	var cumulative = 0.0
	var selected_weather_name = "sunny"

	for weather_name in probabilities.keys():
		cumulative += probabilities[weather_name]
		if roll <= cumulative:
			selected_weather_name = weather_name
			break

	var new_weather = _get_weather_type_from_name(selected_weather_name)
	set_weather(new_weather, true)

# ============================================
# 调试工具
# ============================================

## 打印当前天气状态
func debug_print_status() -> void:
	print("=== WeatherController Debug Status ===")
	print("Current Weather: %s (%d)" % [get_weather_name(_current_weather), _current_weather])
	print("Duration: %.1f hours" % _weather_duration_hours)
	print("Elapsed: %.1f hours" % _weather_timer)
	print("Remaining: %.1f hours" % get_weather_remaining_hours())
	print("Is Precipitation: %s" % ("Yes" if is_precipitation() else "No"))
	print("Storm Active: %s" % ("Yes" if _storm_active else "No"))

	var config = get_current_weather_config()
	if config:
		print("Crop Watering: %s" % ("Yes" if config.get("crop_watering", false) else "No"))
		print("NPC Outdoor Activity: %.1fx" % config.get("npc_outdoor_activity_multiplier", 1.0))
		print("NPC Mood Delta: %.2f" % config.get("npc_mood_delta", 0.0))
	print("=====================================")

## 快速测试：循环遍历所有天气类型
func debug_cycle_through_weathers() -> void:
	var next_weather = (_current_weather + 1) % WEATHER_TYPE_NAMES.size()
	set_weather(next_weather as WeatherType)
