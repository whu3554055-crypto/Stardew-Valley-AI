extends CharacterBody2D

const SPEED = 100.0

## 横向条带帧数：0=整张贴图 + 左右 flip；**3**=列顺序 **下、上、侧**（侧列 + `flip_h` 表示左）。
@export_range(0, 8) var walk_direction_columns: int = 0
## 运行时 `Image.load_from_file`，**不依赖** `.import`；可用 `tools/_make_player_walk_strip.ps1` 生成。
@export var walk_strip_res_path: String = "res://assets/sprites/characters/player_walk_3.png"

@onready var sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
var _animation_player: AnimationPlayer

var facing_direction = Vector2.DOWN
var is_moving = false
var _footstep_cooldown: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _knockback_decay: float = 850.0
const FOOTSTEP_INTERVAL := 0.38

signal interacted(tile_position)
signal attack_requested(origin: Vector2, facing: Vector2)

func _ready():
	add_to_group("player")
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 4
	if walk_direction_columns >= 3:
		_try_load_walk_strip_texture()
		_apply_directional_sprite_strip()

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
	if _knockback_vel.length() > 0.1:
		velocity += _knockback_vel
		_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, _knockback_decay * delta)
	is_moving = velocity_input.length() > 0

	if is_moving:
		_footstep_cooldown -= delta
		if _footstep_cooldown <= 0.0:
			_footstep_cooldown = FOOTSTEP_INTERVAL
			if GatheringSfx:
				var surf: String = _footstep_surface_kind()
				GatheringSfx.play_footstep_surface(surf, _footstep_pitch_for_surface(surf))
	else:
		_footstep_cooldown = 0.0

	# Flip / 朝向条带；可选 AnimationPlayer
	if walk_direction_columns >= 3:
		_apply_directional_sprite_strip()
	else:
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


func _try_load_walk_strip_texture() -> void:
	if sprite == null:
		return
	var p: String = walk_strip_res_path.strip_edges()
	if p.is_empty():
		return
	if not FileAccess.file_exists(p):
		push_warning("Player: walk strip not found: %s (run tools/_make_player_walk_strip.ps1)" % p)
		walk_direction_columns = 0
		return
	var fa: FileAccess = FileAccess.open(p, FileAccess.READ)
	if fa == null:
		push_warning("Player: cannot open walk strip: %s" % p)
		walk_direction_columns = 0
		return
	var buf: PackedByteArray = fa.get_buffer(fa.get_length())
	fa.close()
	var img := Image.new()
	var err: Error = img.load_png_from_buffer(buf)
	if err != OK:
		push_warning("Player: walk strip not valid PNG %s err=%s" % [p, str(err)])
		walk_direction_columns = 0
		return
	sprite.texture = ImageTexture.create_from_image(img)


func _apply_directional_sprite_strip() -> void:
	if sprite == null or sprite.texture == null:
		return
	var tex: Texture2D = sprite.texture
	var tw: int = tex.get_width()
	var th: int = tex.get_height()
	var col_w: int = int(round(float(tw) / float(walk_direction_columns)))
	col_w = maxi(1, col_w)
	var idx: int = 0
	if facing_direction == Vector2.UP:
		idx = 1
	elif facing_direction.x != 0:
		idx = 2
	else:
		idx = 0
	idx = clampi(idx, 0, walk_direction_columns - 1)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(idx * col_w, 0, col_w, th)
	sprite.flip_h = facing_direction == Vector2.LEFT
	if is_moving:
		if _animation_player and _animation_player.has_animation("walk"):
			_animation_player.play("walk")
	else:
		if _animation_player and _animation_player.has_animation("idle"):
			_animation_player.play("idle")

func _footstep_surface_kind() -> String:
	if MiningSystem and MiningSystem.can_mine_here(global_position):
		return "mine"
	if GameZones.is_indoor_station(global_position):
		return "wood"
	return "grass"

func _footstep_pitch_for_surface(surf: String) -> float:
	match surf:
		"mine":
			return randf_range(0.72, 0.9)
		"wood":
			return randf_range(0.88, 1.02)
		_:
			return randf_range(0.94, 1.08)

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		var interact_pos = global_position + facing_direction * 32
		interacted.emit(interact_pos)
	if event.is_action_pressed("attack"):
		attack_requested.emit(global_position, facing_direction)

	if event.is_action_pressed("inventory"):
		# Toggle inventory UI (to be implemented)
		pass

func get_facing_tile() -> Vector2i:
	var tile_pos = global_position / 32
	return Vector2i(tile_pos.x + facing_direction.x, tile_pos.y + facing_direction.y)


func apply_knockback(dir: Vector2, force: float, decay_per_sec: float = 850.0) -> void:
	var n: Vector2 = dir.normalized()
	if n.length() <= 0.001:
		return
	_knockback_vel += n * maxf(0.0, force)
	_knockback_decay = maxf(160.0, decay_per_sec)
