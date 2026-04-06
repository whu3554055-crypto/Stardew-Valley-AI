# environment_system/data_models/season_config.gd
extends Resource
class_name SeasonConfig

## 季节配置数据模型 - 产品级实现
## 用于定义和管理游戏中的季节属性、效果和视觉配置

# ============================================
# 基础属性
# ============================================
@export_group("Basic Properties")
@export var season_name: String = ""
@export var duration_days: int = 28
@export var temperature_range: Vector2 = Vector2(10, 25)
@export var rain_probability: float = 0.3

# ============================================
# 游戏性影响
# ============================================
@export_group("Gameplay Effects")
@export var crop_growth_multiplier: float = 1.0
@export var npc_energy_regen_modifier: float = 1.0
@export var npc_mood_base_delta: float = 0.0
@export var player_energy_consumption_modifier: float = 1.0

# ============================================
# 视觉配置
# ============================================
@export_group("Visual Configuration")
@export var sky_color: Color = Color(0.7, 0.85, 1.0)
@export var ambient_light_energy: float = 1.0
@export var fog_density: float = 0.0
@export var particle_effect_scene_path: String = ""

# ============================================
# 音频配置
# ============================================
@export_group("Audio Configuration")
@export var ambient_soundtrack_path: String = ""
@export var weather_sound_overrides: Dictionary = {}

# ============================================
# 特殊事件
# ============================================
@export_group("Special Events")
@export var special_events: Array[String] = []

# ============================================
# 验证与工厂方法
# ============================================

## 验证配置的有效性
func validate() -> bool:
	var is_valid = true
	
	if season_name.is_empty():
		push_error("[SeasonConfig] Validation failed: season_name is empty")
		is_valid = false
	
	if duration_days <= 0:
		push_error("[SeasonConfig] Validation failed: duration_days must be positive")
		is_valid = false
	
	if temperature_range.x > temperature_range.y:
		push_error("[SeasonConfig] Validation failed: invalid temperature range (min > max)")
		is_valid = false
	
	if rain_probability < 0.0 or rain_probability > 1.0:
		push_error("[SeasonConfig] Validation failed: rain_probability must be between 0 and 1")
		is_valid = false
	
	if crop_growth_multiplier < 0:
		push_error("[SeasonConfig] Validation failed: crop_growth_multiplier must be non-negative")
		is_valid = false
	
	return is_valid

## 从JSON字典创建SeasonConfig实例
static func from_json(data: Dictionary) -> SeasonConfig:
	var config = SeasonConfig.new()
	
	config.season_name = data.get("name", "")
	config.duration_days = data.get("duration_days", 28)
	config.temperature_range = Vector2(
		data.get("temp_min", 10),
		data.get("temp_max", 25)
	)
	config.rain_probability = data.get("rain_probability", 0.3)
	
	config.crop_growth_multiplier = data.get("crop_growth_multiplier", 1.0)
	config.npc_energy_regen_modifier = data.get("npc_energy_regen_modifier", 1.0)
	config.npc_mood_base_delta = data.get("npc_mood_base_delta", 0.0)
	config.player_energy_consumption_modifier = data.get("player_energy_consumption_modifier", 1.0)
	
	var sky_color_str = data.get("sky_color", "#B3D9FF")
	config.sky_color = Color(sky_color_str)
	config.ambient_light_energy = data.get("ambient_light_energy", 1.0)
	config.fog_density = data.get("fog_density", 0.0)
	
	config.ambient_soundtrack_path = data.get("ambient_soundtrack", "")
	config.special_events = data.get("special_events", [])
	
	return config

## 序列化为JSON字典
func to_json() -> Dictionary:
	return {
		"name": season_name,
		"duration_days": duration_days,
		"temp_min": temperature_range.x,
		"temp_max": temperature_range.y,
		"rain_probability": rain_probability,
		"crop_growth_multiplier": crop_growth_multiplier,
		"npc_energy_regen_modifier": npc_energy_regen_modifier,
		"npc_mood_base_delta": npc_mood_base_delta,
		"player_energy_consumption_modifier": player_energy_consumption_modifier,
		"sky_color": sky_color.to_html(false),
		"ambient_light_energy": ambient_light_energy,
		"fog_density": fog_density,
		"ambient_soundtrack": ambient_soundtrack_path,
		"special_events": special_events
	}

## 获取人类可读的描述
func get_description() -> String:
	return "Season: %s | Days: %d | Temp: %.1f-%.1f°C | Growth: %.1fx" % [
		season_name,
		duration_days,
		temperature_range.x,
		temperature_range.y,
		crop_growth_multiplier
	]
