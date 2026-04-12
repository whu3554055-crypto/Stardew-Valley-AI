extends Node2D

## Applies `WorldRouter.pending_spawn_id` after `Main` hands off via `change_scene_to_file`.


func _ready() -> void:
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
