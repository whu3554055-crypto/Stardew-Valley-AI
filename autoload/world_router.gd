extends Node

## Scene transitions + spawn_id alignment for multi-world workflow.
## See `scenes/world/ARCHITECTURE.md`.

const MAIN_SCENE := "res://scenes/main.tscn"
const PLAYGROUND_SCENE := "res://scenes/world/world_playground.tscn"

var pending_spawn_id: String = ""

var _bundle_world_path: String = ""
var _bundle_spawn_id: String = ""

signal world_changed(scene_path: String)


func set_world_state_from_bundle(world: Variant) -> void:
	_bundle_world_path = ""
	_bundle_spawn_id = "default"
	if not world is Dictionary:
		return
	var d: Dictionary = world
	_bundle_world_path = str(d.get("path", "")).strip_edges()
	_bundle_spawn_id = str(d.get("spawn_id", "default")).strip_edges()


func build_world_save_dict() -> Dictionary:
	var scene_path: String = MAIN_SCENE
	if get_tree() and get_tree().current_scene:
		var p: String = get_tree().current_scene.scene_file_path
		if not p.is_empty():
			scene_path = p
	var sid: String = "default"
	if GameManager and GameManager.player_data:
		sid = str(GameManager.player_data.get("last_spawn_id", "default"))
	return {"path": scene_path, "spawn_id": sid}


func consume_saved_world_after_boot() -> void:
	var target: String = _bundle_world_path
	var spawn: String = _bundle_spawn_id
	_bundle_world_path = ""
	_bundle_spawn_id = "default"
	if target.is_empty():
		target = MAIN_SCENE
	pending_spawn_id = spawn
	var current: String = ""
	if get_tree() and get_tree().current_scene:
		current = get_tree().current_scene.scene_file_path
	if current == target:
		_apply_spawn_to_player()
		pending_spawn_id = ""
		return
	var err: Error = get_tree().change_scene_to_file(target)
	if err != OK:
		push_error("WorldRouter: change_scene_to_file failed: %s (err %d)" % [target, err])
		pending_spawn_id = ""
		return
	world_changed.emit(target)


func change_world(scene_path: String, spawn_id: String = "default") -> void:
	if GameManager and GameManager.player_data:
		GameManager.player_data["last_spawn_id"] = spawn_id
	pending_spawn_id = spawn_id
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("WorldRouter: change_world failed: %s" % scene_path)
		pending_spawn_id = ""
		return
	world_changed.emit(scene_path)


func apply_pending_spawn_to_player() -> void:
	_apply_spawn_to_player()


func _apply_spawn_to_player() -> void:
	if pending_spawn_id.is_empty():
		return
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node2D):
		return
	var sp: Node2D = find_spawn_point(pending_spawn_id)
	if sp:
		(pl as Node2D).global_position = sp.global_position
	if GameManager and GameManager.player_data:
		GameManager.player_data["last_spawn_id"] = pending_spawn_id


func apply_pending_spawn_and_clear() -> void:
	_apply_spawn_to_player()
	pending_spawn_id = ""


func find_spawn_point(spawn_id: String) -> Node2D:
	if spawn_id.is_empty():
		return null
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	for n in get_tree().get_nodes_in_group("world_spawn"):
		if not (n is Node2D):
			continue
		var sid: String = str(n.get_meta("spawn_id", ""))
		if sid == spawn_id:
			return n as Node2D
	return null
