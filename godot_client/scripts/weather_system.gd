extends Node

# 天气系统
# 管理天气变化、视觉效果、对游戏的影响

signal weather_changed(weather_type: String)

enum WeatherType {
	SUNNY,
	RAINY,
	STORMY,
	SNOWY,
	WINDY
}

var current_weather = WeatherType.SUNNY
var weather_duration = 0.0
var weather_timer = 0.0

var weather_data = {
	WeatherType.SUNNY: {
		"name": "晴天",
		"duration_range": [3, 7],  # 持续3-7天
		"effects": {
			"crop_growth_speed": 1.0,
			"npc_mood": "happy",
			"ambient_sound": "birds_morning"
		}
	},
	WeatherType.RAINY: {
		"name": "雨天",
		"duration_range": [1, 3],
		"effects": {
			"crop_watered": true,
			"npc_outdoor": false,
			"ambient_sound": "rain_light"
		}
	},
	WeatherType.STORMY: {
		"name": "暴风雨",
		"duration_range": [1, 2],
		"effects": {
			"npc_stay_indoor": true,
			"fishing_difficulty": 1.5,
			"ambient_sound": "rain_heavy"
		}
	},
	WeatherType.SNOWY: {
		"name": "雪天",
		"duration_range": [2, 4],
		"effects": {
			"crop_growth_speed": 0.0,
			"player_energy_drain": 1.2,
			"ambient_sound": "wind_trees"
		}
	},
	WeatherType.WINDY: {
		"name": "大风",
		"duration_range": [1, 2],
		"effects": {
			"tree_shake": true,
			"windmill_spin": true,
			"ambient_sound": "wind_trees"
		}
	}
}

@onready var rain_particles = null
@onready var snow_particles = null
@onready var wind_audio = null

func _ready():
	print("天气系统初始化")
	initialize_weather_effects()
	start_weather_cycle()

func initialize_weather_effects():
	"""初始化天气视觉效果"""
	# 创建雨粒子系统
	rain_particles = GPUParticles2D.new()
	rain_particles.name = "RainParticles"
	rain_particles.visible = false
	add_child(rain_particles)

	# 创建雪粒子系统
	snow_particles = GPUParticles2D.new()
	snow_particles.name = "SnowParticles"
	snow_particles.visible = false
	add_child(snow_particles)

	# 风声音频
	wind_audio = AudioStreamPlayer.new()
	wind_audio.name = "WindAudio"
	wind_audio.volume_db = -20
	add_child(wind_audio)

func start_weather_cycle():
	"""启动天气循环"""
	# 每天检查一次天气变化
	var daily_timer = Timer.new()
	daily_timer.wait_time = 60.0  # 测试用：每60秒模拟一天
	daily_timer.timeout.connect(on_new_day)
	add_child(daily_timer)
	daily_timer.start()

func on_new_day():
	"""新的一天，可能改变天气"""
	weather_timer += 1

	if weather_timer >= weather_duration:
		change_weather()

func change_weather(new_weather: WeatherType = -1):
	"""改变天气"""
	if new_weather == -1:
		# 随机选择新天气（晴天概率更高）
		var rand = randf()
		if rand < 0.5:
			new_weather = WeatherType.SUNNY
		elif rand < 0.7:
			new_weather = WeatherType.RAINY
		elif rand < 0.8:
			new_weather = WeatherType.CLOUDY if has_enum("CLOUDY") else WeatherType.SUNNY
		elif rand < 0.9:
			new_weather = WeatherType.WINDY
		else:
			new_weather = WeatherType.STORMY

	current_weather = new_weather
	var data = weather_data[current_weather]

	# 设置持续时间
	var duration_range = data["duration_range"]
	weather_duration = randi_range(duration_range[0], duration_range[1])
	weather_timer = 0

	# 应用天气效果
	apply_weather_effects()

	# 发射信号
	emit_signal("weather_changed", data["name"])

	print("天气变更: ", data["name"], " (持续", weather_duration, "天)")

func apply_weather_effects():
	"""应用当前天气的视觉效果"""
	var data = weather_data[current_weather]

	# 隐藏所有粒子
	if rain_particles:
		rain_particles.visible = false
	if snow_particles:
		snow_particles.visible = false

	match current_weather:
		WeatherType.SUNNY:
			# 晴天：无特殊效果
			set_global_color_modulate(Color(1, 1, 1, 1))

		WeatherType.RAINY:
			# 雨天：显示雨粒子
			if rain_particles:
				rain_particles.visible = true
				setup_rain_particles()
			set_global_color_modulate(Color(0.9, 0.9, 1, 1))

		WeatherType.STORMY:
			# 暴风雨：更强的雨+闪电效果
			if rain_particles:
				rain_particles.visible = true
				setup_storm_particles()
			set_global_color_modulate(Color(0.7, 0.7, 0.8, 1))
			start_lightning_effect()

		WeatherType.SNOWY:
			# 雪天：显示雪粒子
			if snow_particles:
				snow_particles.visible = true
				setup_snow_particles()
			set_global_color_modulate(Color(0.95, 0.95, 1, 1))

		WeatherType.WINDY:
			# 大风：摇晃树木效果
			set_global_color_modulate(Color(1, 1, 0.95, 1))
			start_wind_effect()

	# 播放环境音
	play_ambient_sound(data["effects"].get("ambient_sound", ""))

func setup_rain_particles():
	"""设置雨粒子"""
	# 简化版：实际应使用ParticleProcessMaterial
	rain_particles.amount = 100
	rain_particles.lifetime = 2.0

func setup_storm_particles():
	"""设置暴风雨粒子"""
	rain_particles.amount = 200
	rain_particles.lifetime = 1.5

func setup_snow_particles():
	"""设置雪粒子"""
	snow_particles.amount = 80
	snow_particles.lifetime = 3.0

func set_global_color_modulate(color: Color):
	"""设置全局颜色调制（模拟天气光照）"""
	var canvas_modulate = get_tree().root.get_node_or_null("Main")
	if canvas_modulate and canvas_modulate.has_method("set_modulate"):
		canvas_modulate.modulate = color

func start_lightning_effect():
	"""启动闪电效果"""
	var lightning_timer = Timer.new()
	lightning_timer.wait_time = 5.0 + randf() * 10.0
	lightning_timer.timeout.connect(func():
		# 闪烁效果
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
		lightning_timer.queue_free()
	)
	add_child(lightning_timer)
	lightning_timer.start()

func start_wind_effect():
	"""启动风吹效果"""
	if wind_audio:
		var sound_path = "res://assets/audio/ambience_extended/wind_trees.wav"
		if ResourceLoader.exists(sound_path):
			wind_audio.stream = load(sound_path)
			wind_audio.play()

func play_ambient_sound(sound_name: String):
	"""播放环境音效"""
	if sound_name.is_empty():
		return

	var sound_path = "res://assets/audio/ambience_extended/" + sound_name + ".wav"
	if ResourceLoader.exists(sound_path):
		# 切换环境音
		var main_node = get_tree().root.get_node_or_null("Main/TownSquare")
		if main_node and main_node.has_node("AmbientAudio"):
			var audio = main_node.get_node("AmbientAudio")
			audio.stream = load(sound_path)
			audio.play()

func get_current_weather_name() -> String:
	"""获取当前天气名称"""
	return weather_data[current_weather]["name"]

func is_raining() -> bool:
	"""是否在下雨"""
	return current_weather in [WeatherType.RAINY, WeatherType.STORMY]

func is_snowing() -> bool:
	"""是否在下雪"""
	return current_weather == WeatherType.SNOWY

func has_enum(value: int) -> bool:
	"""检查枚举值是否存在"""
	return value in WeatherType.values()
