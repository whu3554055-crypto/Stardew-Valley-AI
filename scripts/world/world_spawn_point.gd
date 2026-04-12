extends Marker2D
class_name WorldSpawnPoint

## Registers this position as a named spawn for `WorldRouter`.

@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group("world_spawn")
	set_meta("spawn_id", spawn_id)
