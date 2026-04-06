extends Node2D

# 主场景控制器
# 管理游戏状态、时间系统、场景切换

var game_state = {
	"season": "spring",
	"day": 1,
	"year": 1,
	"time": 8.0,  # 24小时制，8.0 = 08:00
	"weather": "sunny",
	"player_gold": 500,
	"player_energy": 100
}

@onready var time_display = $UI/TimeDisplay
@onready var interaction_prompt = $UI/InteractionPrompt

func _ready():
	print("Cyber Town - 游戏启动")
	update_time_display()
	start_time_system()

func _process(delta):
	# 更新交互提示位置（跟随玩家）
	if has_node("TownSquare/Player"):
		var player = $TownSquare/Player
		var screen_pos = get_viewport().get_camera_2d().unproject_position(player.global_position)
		interaction_prompt.position = Vector2(screen_pos.x, screen_pos.y - 60)

func start_time_system():
	# 简单的时间流逝系统（测试用）
	var timer = Timer.new()
	timer.wait_time = 10.0  # 每10秒游戏时间过1小时
	timer.timeout.connect(on_time_passed)
	add_child(timer)
	timer.start()

func on_time_passed():
	game_state.time += 1.0
	if game_state.time >= 24.0:
		game_state.time = 6.0
		game_state.day += 1
		if game_state.day > 28:
			game_state.day = 1
			next_season()

	update_time_display()
	update_living_world_systems()

func next_season():
	var seasons = ["spring", "summer", "fall", "winter"]
	var current_idx = seasons.find(game_state.season)
	game_state.season = seasons[(current_idx + 1) % 4]
	game_state.year += 1
	print("季节变更: ", game_state.season)

func update_time_display():
	var hour = int(game_state.time)
	var minute = int((game_state.time - hour) * 60)
	var time_str = "%02d:%02d" % [hour, minute]
	time_display.text = "%s 第%d天 %s" % [
		translate_season(game_state.season),
		game_state.day,
		time_str
	]

func translate_season(season: String) -> String:
	match season:
		"spring": return "春季"
		"summer": return "夏季"
		"fall": return "秋季"
		"winter": return "冬季"
	return season

func show_interaction_prompt(text: String = "按 E 互动"):
	interaction_prompt.text = text
	interaction_prompt.modulate.a = 1.0

func hide_interaction_prompt():
	interaction_prompt.modulate.a = 0.0

func update_living_world_systems():
	# 更新NPC日程系统
	if has_node("TownSquare/NPCScheduleSystem"):
		$TownSquare/NPCScheduleSystem.update_time(game_state.time)

	# 更新天气系统（每30分钟检查一次）
	if has_node("TownSquare/WeatherSystem") and int(game_state.time * 2) % 1 == 0:
		$TownSquare/WeatherSystem.check_weather_change()

	# 更新动物AI（根据时间生成/移除）
	if has_node("TownSquare/AnimalAI"):
		$TownSquare/AnimalAI.update_game_time(game_state.time)
