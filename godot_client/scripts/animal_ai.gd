extends Node2D

# 动物AI系统
# 管理小动物的行为：兔子跳跃、蝴蝶飞舞、小鸟觅食

signal animal_spawned(animal_type: String, position: Vector2)

var active_animals = []
var max_animals = 15

var animal_types = {
	"rabbit": {
		"sprite": "res://assets/sprites/environment/forest/rabbit.png",
		"behavior": "hop",
		"speed": 80.0,
		"hop_interval": [2.0, 4.0],
		"active_time": [6.0, 20.0]  # 6AM-8PM
	},
	"butterfly": {
		"sprite": "res://assets/sprites/environment/forest/butterfly.png",
		"behavior": "flutter",
		"speed": 40.0,
		"flutter_radius": 30.0,
		"active_time": [8.0, 18.0]
	},
	"bird": {
		"sprite": "res://assets/sprites/environment/forest/bird.png",
		"behavior": "forage",
		"speed": 60.0,
		"peck_interval": [3.0, 6.0],
		"active_time": [6.0, 19.0]
	}
}

func _ready():
	print("动物AI系统初始化")
	start_animal_spawner()

func start_animal_spawner():
	"""启动动物生成定时器"""
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 10.0  # 每10秒尝试生成动物
	spawn_timer.timeout.connect(try_spawn_animal)
	add_child(spawn_timer)
	spawn_timer.start()

	# 立即生成几只
	for i in range(3):
		try_spawn_animal()

func try_spawn_animal():
	"""尝试生成一只动物"""
	if active_animals.size() >= max_animals:
		return

	# 根据当前游戏时间决定是否生成
	var game_time = get_game_time()
	if game_time < 0:
		game_time = 12.0  # 默认中午

	# 随机选择动物类型
	var types = animal_types.keys()
	var chosen_type = types[randi() % types.size()]
	var animal_data = animal_types[chosen_type]

	# 检查是否在活动时间
	var active_hours = animal_data["active_time"]
	if game_time < active_hours[0] or game_time > active_hours[1]:
		return

	# 生成概率（不是每次都成功）
	if randf() > 0.4:
		return

	# 在屏幕范围内随机位置生成
	var viewport_size = get_viewport_rect().size
	var spawn_pos = Vector2(
		randf_range(50, viewport_size.x - 50),
		randf_range(50, viewport_size.y - 50)
	)

	spawn_animal(chosen_type, spawn_pos)

func spawn_animal(animal_type: String, position: Vector2):
	"""生成动物"""
	var animal_data = animal_types[animal_type]

	# 创建动物节点
	var animal = Area2D.new()
	animal.name = animal_type + "_" + str(position).replace(",", "_")

	# 添加精灵
	var sprite = Sprite2D.new()
	if ResourceLoader.exists(animal_data["sprite"]):
		sprite.texture = load(animal_data["sprite"])
	else:
		# 占位符
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(randf(), randf(), randf(), 1))
		sprite.texture = ImageTexture.create_from_image(img)

	sprite.scale = Vector2(0.6, 0.6)
	animal.add_child(sprite)

	# 添加碰撞区域
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	animal.add_child(collision)

	# 设置位置
	animal.position = position

	# 存储动物数据
	animal.set_meta("type", animal_type)
	animal.set_meta("data", animal_data)
	animal.set_meta("state", "idle")
	animal.set_meta("timer", 0.0)

	add_child(animal)
	active_animals.append(animal)

	# 启动AI行为
	match animal_data["behavior"]:
		"hop":
			setup_rabbit_ai(animal)
		"flutter":
			setup_butterfly_ai(animal)
		"forage":
			setup_bird_ai(animal)

	emit_signal("animal_spawned", animal_type, position)
	print("生成动物: ", animal_type, " at ", position)

func setup_rabbit_ai(rabbit):
	"""设置兔子AI：随机跳跃"""
	rabbit.set_meta("state", "hopping")

	var hop_timer = Timer.new()
	var interval = rabbit.get_meta("data")["hop_interval"]
	hop_timer.wait_time = randf_range(interval[0], interval[1])
	hop_timer.timeout.connect(func(): rabbit_hop(rabbit))
	rabbit.add_child(hop_timer)
	hop_timer.start()

	# 立即跳一次
	await get_tree().create_timer(0.5).timeout
	rabbit_hop(rabbit)

func rabbit_hop(rabbit):
	"""兔子跳跃"""
	if not is_instance_valid(rabbit):
		return

	var data = rabbit.get_meta("data")
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var distance = randf_range(50, 120)
	var target_pos = rabbit.position + direction * distance

	# 限制在屏幕内
	var viewport = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 20, viewport.x - 20)
	target_pos.y = clamp(target_pos.y, 20, viewport.y - 20)

	# 跳跃动画（抛物线）
	var tween = rabbit.create_tween()
	tween.tween_property(rabbit, "position", target_pos, 1.0).set_trans(Tween.TRANS_SINE)

	# 缩放模拟跳跃高度
	tween.parallel().tween_property(rabbit, "scale", Vector2(0.7, 0.5), 0.5)
	tween.parallel().tween_property(rabbit, "scale", Vector2(0.6, 0.6), 0.5).set_delay(0.5)

	rabbit.set_meta("state", "hopping")

func setup_butterfly_ai(butterfly):
	"""设置蝴蝶AI：盘旋飞行"""
	butterfly.set_meta("state", "fluttering")

	var flutter_timer = Timer.new()
	flutter_timer.wait_time = 0.1
	flutter_timer.timeout.connect(func(): butterfly_flutter(butterfly))
	butterfly.add_child(flutter_timer)
	flutter_timer.start()

	# 随机移动目标
	change_butterfly_target(butterfly)

func butterfly_flutter(butterfly):
	"""蝴蝶盘旋"""
	if not is_instance_valid(butterfly):
		return

	var data = butterfly.get_meta("data")
	var time = Time.get_ticks_msec() / 1000.0
	var radius = data["flutter_radius"]

	# 正弦波运动
	var offset_x = sin(time * 2.0) * radius
	var offset_y = cos(time * 1.5) * radius

	butterfly.position += Vector2(offset_x * 0.1, offset_y * 0.1)

	# 旋转朝向移动方向
	var velocity = Vector2(offset_x, offset_y)
	if velocity.length() > 0.1:
		var angle = velocity.angle()
		butterfly.rotation = angle

func change_butterfly_target(butterfly):
	"""改变蝴蝶飞行目标"""
	if not is_instance_valid(butterfly):
		return

	var viewport = get_viewport_rect().size
	var target = Vector2(
		randf_range(50, viewport.x - 50),
		randf_range(50, viewport.y - 50)
	)

	var tween = butterfly.create_tween()
	tween.tween_property(butterfly, "position", target, 5.0).set_trans(Tween.TRANS_QUAD)

	# 循环
	tween.tween_callback(func(): change_butterfly_target(butterfly))

func setup_bird_ai(bird):
	"""设置小鸟AI：觅食行为"""
	bird.set_meta("state", "foraging")

	# 觅食-飞走循环
	var behavior_timer = Timer.new()
	behavior_timer.wait_time = 5.0
	behavior_timer.timeout.connect(func(): bird_behavior_cycle(bird))
	bird.add_child(behavior_timer)
	behavior_timer.start()

	# 开始觅食
	bird_peck(bird)

func bird_behavior_cycle(bird):
	"""小鸟行为循环"""
	if not is_instance_valid(bird):
		return

	var state = bird.get_meta("state")

	if state == "foraging":
		# 飞走
		bird_fly_away(bird)
	elif state == "flying":
		# 降落到新位置觅食
		var viewport = get_viewport_rect().size
		var new_pos = Vector2(
			randf_range(50, viewport.x - 50),
			randf_range(50, viewport.y - 50)
		)
		var tween = bird.create_tween()
		tween.tween_property(bird, "position", new_pos, 2.0)
		tween.tween_callback(func(): bird_peck(bird))
		bird.set_meta("state", "landing")

func bird_peck(bird):
	"""小鸟啄食"""
	if not is_instance_valid(bird):
		return

	bird.set_meta("state", "foraging")

	# 啄食动画
	var tween = bird.create_tween()
	tween.tween_property(bird, "rotation_degrees", 20, 0.3)
	tween.tween_property(bird, "rotation_degrees", 0, 0.3)

	# 重复啄食
	var peck_timer = bird.get_tree().create_timer(2.0)
	peck_timer.timeout.connect(func():
		if is_instance_valid(bird):
			bird_peck(bird)
	)

func bird_fly_away(bird):
	"""小鸟飞走"""
	if not is_instance_valid(bird):
		return

	bird.set_meta("state", "flying")

	# 飞向屏幕外
	var viewport = get_viewport_rect().size
	var exit_pos = Vector2(
		randf_range(-100, viewport.x + 100),
		randf_range(-100, -50)
	)

	var tween = bird.create_tween()
	tween.tween_property(bird, "position", exit_pos, 3.0)
	tween.tween_callback(func(): remove_animal(bird))

func remove_animal(animal):
	"""移除动物"""
	if not is_instance_valid(animal):
		return

	active_animals.erase(animal)
	animal.queue_free()
	print("动物消失: ", animal.get_meta("type"))

func get_game_time() -> float:
	"""获取当前游戏时间"""
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has("game_state"):
		return main_node.game_state.get("time", 12.0)
	return 12.0

func cleanup_all_animals():
	"""清理所有动物"""
	for animal in active_animals:
		if is_instance_valid(animal):
			animal.queue_free()
	active_animals.clear()
