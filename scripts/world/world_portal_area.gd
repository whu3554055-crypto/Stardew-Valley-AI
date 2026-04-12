extends Area2D
class_name WorldPortalArea

## Triggers `WorldRouter.change_world` when the player body enters this area.

@export var target_scene: String = ""
@export var target_spawn_id: String = "default"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if target_scene.is_empty():
		return
	if WorldRouter:
		WorldRouter.change_world(target_scene, target_spawn_id)
