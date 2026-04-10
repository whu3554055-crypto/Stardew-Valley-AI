extends Node2D

class_name EnemyMelee

@export var enemy_id: String = "mine_slime"
@export var max_hp: int = 24
@export var move_speed: float = 46.0
@export var contact_damage: float = 8.0
@export var contact_interval_sec: float = 0.9
@export var detection_range: float = 300.0
@export var leash_range: float = 520.0
@export var despawn_range: float = 860.0
@export var hit_stun_sec: float = 0.14
@export var no_contact_after_spawn_sec: float = 0.6
@export var contact_windup_sec: float = 0.22
@export var drop_item_id: String = "stone_chunk"
@export var drop_count_min: int = 1
@export var drop_count_max: int = 2

var hp: int = 24
var _contact_cd: float = 0.0
var _flash_t: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _hit_stun_t: float = 0.0
var _spawned_at_sec: float = 0.0
var _attack_windup_t: float = 0.0
var _base_move_speed: float = 0.0
var _base_contact_damage: float = 0.0

signal contact_hit(enemy: EnemyMelee, damage: float)
signal enemy_killed(enemy: EnemyMelee)

func _ready() -> void:
	hp = max_hp
	_spawned_at_sec = Time.get_ticks_msec() / 1000.0
	_base_move_speed = move_speed
	_base_contact_damage = contact_damage
	add_to_group("enemy")
	if get_node_or_null("Body") == null:
		var body := ColorRect.new()
		body.name = "Body"
		body.color = Color(0.44, 0.77, 0.52, 0.95)
		body.position = Vector2(-10, -10)
		body.size = Vector2(20, 20)
		add_child(body)

func _process(delta: float) -> void:
	_contact_cd = maxf(0.0, _contact_cd - delta)
	_flash_t = maxf(0.0, _flash_t - delta)
	_hit_stun_t = maxf(0.0, _hit_stun_t - delta)
	_attack_windup_t = maxf(0.0, _attack_windup_t - delta)
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 520.0 * delta)
	if _knockback_vel.length() > 1.0:
		global_position += _knockback_vel * delta
	var body: ColorRect = get_node_or_null("Body") as ColorRect
	if body:
		if _flash_t > 0.0:
			body.color = Color(1.0, 0.62, 0.62, 1.0)
		elif _attack_windup_t > 0.0:
			body.color = Color(0.95, 0.86, 0.38, 1.0)
		else:
			body.color = Color(0.44, 0.77, 0.52, 0.95)
	var p: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	if _hit_stun_t > 0.0:
		return
	var dv: Vector2 = p.global_position - global_position
	var d: float = dv.length()
	if d >= despawn_range:
		queue_free()
		return
	if d >= leash_range:
		return
	if d <= detection_range and d > 1.0 and _knockback_vel.length() < 28.0:
		global_position += dv.normalized() * move_speed * delta
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if d <= 22.0 and _contact_cd <= 0.0 and (now_sec - _spawned_at_sec) >= no_contact_after_spawn_sec:
		if _attack_windup_t <= 0.0:
			_attack_windup_t = contact_windup_sec
	if _attack_windup_t <= 0.0 and d <= 24.0 and _contact_cd <= 0.0 and (now_sec - _spawned_at_sec) >= no_contact_after_spawn_sec:
		_contact_cd = contact_interval_sec
		contact_hit.emit(self, contact_damage)
	var hp_ratio: float = float(hp) / maxf(1.0, float(max_hp))
	if hp_ratio <= 0.35:
		move_speed = _base_move_speed * 1.18
		contact_damage = _base_contact_damage * 1.15
	else:
		move_speed = _base_move_speed
		contact_damage = _base_contact_damage

func take_damage(amount: int) -> bool:
	if amount <= 0:
		return false
	hp -= amount
	_flash_t = 0.12
	_hit_stun_t = maxf(_hit_stun_t, hit_stun_sec)
	_attack_windup_t = 0.0
	if hp <= 0:
		enemy_killed.emit(self)
		queue_free()
		return true
	return false

func roll_drop_count() -> int:
	return randi_range(drop_count_min, drop_count_max)


func apply_knockback(dir: Vector2, force: float) -> void:
	var n: Vector2 = dir.normalized()
	if n.length() <= 0.001:
		return
	_knockback_vel += n * maxf(0.0, force)


func set_body_color(c: Color) -> void:
	var body: ColorRect = get_node_or_null("Body") as ColorRect
	if body:
		body.color = c
