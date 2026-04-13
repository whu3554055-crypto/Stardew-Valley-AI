extends Area2D
class_name ForegroundOcclusionArea

## When player enters, fade sprite a bit to simulate walking behind foreground.
@export_range(0.35, 1.0) var player_alpha_inside: float = 0.62
@export_range(0.35, 1.0) var player_alpha_outside: float = 1.0

var _inside_count: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_inside_count += 1
	_apply_player_alpha(body, player_alpha_inside)


func _on_body_exited(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_inside_count = maxi(0, _inside_count - 1)
	if _inside_count == 0:
		_apply_player_alpha(body, player_alpha_outside)


func _apply_player_alpha(player: Node, alpha: float) -> void:
	var sprite: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate.a = clampf(alpha, 0.35, 1.0)
