extends CharacterBody2D

const SPEED = 100.0

@onready var sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
var _animation_player: AnimationPlayer

var facing_direction = Vector2.DOWN
var is_moving = false
var _footstep_cooldown: float = 0.0
const FOOTSTEP_INTERVAL := 0.38

signal interacted(tile_position)

func _ready():
	add_to_group("player")
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 4

func _physics_process(delta):
	var velocity_input = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		velocity_input.y -= 1
		facing_direction = Vector2.UP
	if Input.is_action_pressed("move_down"):
		velocity_input.y += 1
		facing_direction = Vector2.DOWN
	if Input.is_action_pressed("move_left"):
		velocity_input.x -= 1
		facing_direction = Vector2.LEFT
	if Input.is_action_pressed("move_right"):
		velocity_input.x += 1
		facing_direction = Vector2.RIGHT

	velocity = velocity_input.normalized() * SPEED
	is_moving = velocity_input.length() > 0

	if is_moving:
		_footstep_cooldown -= delta
		if _footstep_cooldown <= 0.0:
			_footstep_cooldown = FOOTSTEP_INTERVAL
			if GatheringSfx:
				GatheringSfx.play_footstep_grass(randf_range(0.94, 1.08))
	else:
		_footstep_cooldown = 0.0

	# Flip sprite; optional AnimationPlayer if present in scene
	if is_moving:
		if _animation_player and _animation_player.has_animation("walk"):
			_animation_player.play("walk")
		if facing_direction == Vector2.LEFT:
			sprite.flip_h = true
		elif facing_direction == Vector2.RIGHT:
			sprite.flip_h = false
	else:
		if _animation_player and _animation_player.has_animation("idle"):
			_animation_player.play("idle")

	move_and_slide()

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		var interact_pos = global_position + facing_direction * 32
		interacted.emit(interact_pos)

	if event.is_action_pressed("inventory"):
		# Toggle inventory UI (to be implemented)
		pass

func get_facing_tile() -> Vector2i:
	var tile_pos = global_position / 32
	return Vector2i(tile_pos.x + facing_direction.x, tile_pos.y + facing_direction.y)
