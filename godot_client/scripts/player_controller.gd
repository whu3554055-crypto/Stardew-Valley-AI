extends CharacterBody2D

# 玩家控制器
# 处理移动、动画、与世界的交互

const SPEED = 150.0
const RUN_SPEED = 250.0

var direction = Vector2.ZERO

@onready var sprite = $PlayerSprite

func _ready():
	print("玩家初始化完成")
	setup_animation()

func setup_animation():
	# TODO: 加载玩家精灵动画
	# 暂时使用占位符
	pass

func _physics_process(delta):
	handle_input()
	move_and_slide()

func handle_input():
	direction = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1

	direction = direction.normalized()

	var current_speed = SPEED
	if Input.is_action_pressed("run"):  # Shift键跑步
		current_speed = RUN_SPEED

	velocity = direction * current_speed

	# 更新朝向和动画
	if direction.length() > 0:
		update_animation(direction)

func update_animation(move_dir: Vector2):
	# TODO: 根据移动方向切换动画
	# 简化版：只记录朝向
	if abs(move_dir.x) > abs(move_dir.y):
		# 水平移动
		if move_dir.x > 0:
			sprite.flip_h = false  # 朝右
		else:
			sprite.flip_h = true   # 朝左
	# 这里应该播放行走动画

func stop_animation():
	# TODO: 切换到待机动画
	pass
