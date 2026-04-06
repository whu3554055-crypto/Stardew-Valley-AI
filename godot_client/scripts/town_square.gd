extends Node2D

# 小镇广场场景控制器
# 管理环境互动、音效、动态元素

@onready var player = $Player
@onready var interactables = $Interactables
@onready var ambient_audio = $AmbientAudio
@onready var birds_audio = $BirdsAudio

var nearby_interactable = null

func _ready():
	print("小镇广场加载完成")
	setup_ground()
	play_ambient_sounds()
	setup_living_world()

func setup_ground():
	# 这里应该用TileMap铺设鹅卵石地面
	# 简化版：暂时留空，等待美术资源完善
	pass

func play_ambient_sounds():
	# 播放环境音
	# 注意：实际音频文件需要转换為 Godot 支持的格式 (.ogg 或 .wav)
	if ResourceLoader.exists("res://assets/audio/ambience_extended/birds_morning.wav"):
		birds_audio.stream = load("res://assets/audio/ambience_extended/birds_morning.wav")
		birds_audio.play()

func setup_living_world():
	# 添加动态元素
	add_floating_bubbles()
	add_flying_birds()

func add_floating_bubbles():
	# 在河边添加气泡动画
	var river = $River
	for i in range(3):
		var bubble_timer = Timer.new()
		bubble_timer.wait_time = 2.0 + randf() * 3.0
		bubble_timer.timeout.connect(func(): spawn_bubble())
		river.add_child(bubble_timer)
		bubble_timer.start()

func spawn_bubble():
	# 创建气泡粒子效果（简化版）
	var bubble = Sprite2D.new()
	bubble.texture = load("res://assets/sprites/environment/water/bubble.png") if ResourceLoader.exists("res://assets/sprites/environment/water/bubble.png") else null
	if bubble.texture:
		bubble.position = Vector2(100 + randi() % 500, 450)
		bubble.modulate.a = 0.7
		$River.add_child(bubble)

		# 气泡上浮动画
		var tween = create_tween()
		tween.tween_property(bubble, "position:y", bubble.position.y - 50, 2.0)
		tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
		tween.tween_callback(bubble.queue_free)

func add_flying_birds():
	# 随机飞过的小鸟
	var bird_timer = Timer.new()
	bird_timer.wait_time = 15.0 + randf() * 20.0
	bird_timer.timeout.connect(spawn_bird)
	add_child(bird_timer)
	bird_timer.start()

func spawn_bird():
	if ResourceLoader.exists("res://assets/sprites/environment/forest/bird.png"):
		var bird = Sprite2D.new()
		bird.texture = load("res://assets/sprites/environment/forest/bird.png")
		bird.position = Vector2(-50, 50 + randi() % 100)
		bird.scale = Vector2(0.8, 0.8)
		add_child(bird)

		# 飞行动画
		var tween = create_tween()
		tween.tween_property(bird, "position:x", 1350, 8.0)
		tween.tween_callback(bird.queue_free)

func _process(delta):
	check_nearby_interactables()

func check_nearby_interactables():
	# 检测玩家附近是否有可互动对象
	var min_distance = 60.0
	var closest = null

	for child in interactables.get_children():
		if child == player:
			continue
		var distance = player.global_position.distance_to(child.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = child

	if closest != nearby_interactable:
		nearby_interactable = closest
		if closest:
			get_parent().show_interaction_prompt(closest.interaction_text)
		else:
			get_parent().hide_interaction_prompt()

func _input(event):
	if event.is_action_pressed("interact") and nearby_interactable:
		interact_with_object(nearby_interactable)

func interact_with_object(obj):
	print("互动: ", obj.interact_name, " (", obj.interact_type, ")")

	match obj.interact_type:
		"bench":
			print("你坐在长椅上休息，恢复了少量体力")
			# TODO: 恢复体力逻辑
		"trash_can":
			print("垃圾桶里有一些废纸和空瓶子")
		"flower":
			print("花朵散发着淡淡的清香")
		_:
			print("未知互动类型")

	# 播放互动音效
	play_interaction_sound()

func play_interaction_sound():
	# TODO: 播放 UI 点击音效
	pass
