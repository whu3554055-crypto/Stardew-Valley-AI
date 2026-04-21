extends Area2D
class_name WorldPortalArea

## Triggers `WorldRouter.change_world` when the player body enters this area.

@export var target_scene: String = ""
@export var target_spawn_id: String = "default"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	print("[WorldPortalArea] Body entered: ", body.name, " | Groups: ", body.get_groups())
	if not body.is_in_group("player"):
		print("[WorldPortalArea] Body is not in 'player' group, ignoring")
		return
	if target_scene.is_empty():
		print("[WorldPortalArea] target_scene is empty, ignoring")
		return
	print("[WorldPortalArea] Triggering scene change to: ", target_scene, " with spawn_id: ", target_spawn_id)
	if WorldRouter:
		print("[WorldPortalArea] Calling WorldRouter.change_world...")
		WorldRouter.change_world(target_scene, target_spawn_id)
	else:
		print("[WorldPortalArea] ERROR: WorldRouter is null!")
