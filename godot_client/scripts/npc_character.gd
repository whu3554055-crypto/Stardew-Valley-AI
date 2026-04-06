extends Area2D

# NPC角色控制器
# 管理NPC外观、行为、对话

@export var npc_id: String = "pierre"
@export var npc_name: String = "Pierre"
@export var schedule_data: Dictionary = {}

var current_activity = "idle"
var target_position = null
var dialogue_cooldown = false

@onready var sprite = $Sprite
@onready var name_label = $NameLabel

func _ready():
	print("NPC加载: ", npc_name, " (", npc_id, ")")
	name_label.text = npc_name
	setup_npc()

func setup_npc():
	"""初始化NPC"""
	load_npc_sprite()
	start_schedule_system()

func load_npc_sprite():
	"""加载NPC精灵"""
	var sprite_path = "res://assets/sprites/characters/npc_" + npc_id + ".png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		print("警告: 找不到NPC精灵 ", sprite_path)
		# 使用占位符颜色
		modulate = Color(randf(), randf(), randf(), 1)

func start_schedule_system():
	"""启动NPC日程系统"""
	# 简化版：随机移动
	var move_timer = Timer.new()
	move_timer.wait_time = 10.0 + randf() * 20.0
	move_timer.timeout.connect(move_to_random_position)
	add_child(move_timer)
	move_timer.start()

func move_to_random_position():
	"""移动到随机位置（模拟日程）"""
	if not is_instance_valid(get_parent()):
		return

	# 在父节点范围内随机移动
	var parent = get_parent()
	if parent.has_method("get_rect"):
		var rect = parent.get_rect()
		target_position = Vector2(
			rect.position.x + randf() * rect.size.x,
			rect.position.y + randf() * rect.size.y
		)

		# 平滑移动
		var tween = create_tween()
		tween.tween_property(self, "position", target_position, 5.0)
		tween.tween_callback(func(): current_activity = "idle")

		current_activity = "moving"

func interact():
	"""与NPC互动"""
	if dialogue_cooldown:
		return

	# 触发对话
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_node("DialogueSystem"):
		var dialogue_system = main_node.get_node("DialogueSystem")
		dialogue_system.start_dialogue(npc_id)

		# 设置冷却时间
		dialogue_cooldown = true
		var cooldown_timer = Timer.new()
		cooldown_timer.wait_time = 5.0
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(func(): dialogue_cooldown = false)
		add_child(cooldown_timer)
		cooldown_timer.start()

func set_emotion(emotion: String):
	"""设置NPC情感状态（改变颜色或动画）"""
	match emotion:
		"happy":
			modulate = Color(1, 1, 0.8, 1)  # 亮黄色调
		"sad":
			modulate = Color(0.8, 0.8, 1, 1)  # 蓝色调
		"angry":
			modulate = Color(1, 0.8, 0.8, 1)  # 红色调
		_:
			modulate = Color(1, 1, 1, 1)  # 正常

func get_npc_id() -> String:
	"""获取NPC ID"""
	return npc_id

func get_npc_info() -> Dictionary:
	"""获取NPC信息"""
	return {
		"id": npc_id,
		"name": npc_name,
		"position": position,
		"activity": current_activity
	}
