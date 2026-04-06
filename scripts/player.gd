extends CharacterBody2D

const SPEED = 100.0

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var interaction_area = $InteractionArea

var facing_direction = Vector2.DOWN
var is_moving = false

signal interacted(tile_position)

func _ready():
	pass

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

	# Update animation
	if is_moving:
		animation_player.play("walk")
		# Flip sprite based on direction
		if facing_direction == Vector2.LEFT:
			sprite.flip_h = true
		elif facing_direction == Vector2.RIGHT:
			sprite.flip_h = false
	else:
		animation_player.play("idle")

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
