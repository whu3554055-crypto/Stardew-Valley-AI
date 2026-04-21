extends Node

## Scene transitions + spawn_id alignment for multi-world workflow.
## See `scenes/world/ARCHITECTURE.md`.

const MAIN_SCENE := "res://scenes/main.tscn"
const WORLD_FARM_SCENE := "res://scenes/world/world_farm.tscn"
const WORLD_TOWN_SCENE := "res://scenes/world/world_town.tscn"
const WORLD_FOREST_SCENE := "res://scenes/world/world_forest.tscn"
const WORLD_BEACH_SCENE := "res://scenes/world/world_beach.tscn"
const WORLD_MINE_SCENE := "res://scenes/world/world_mine.tscn"
const WORLD_CAVE_SCENE := "res://scenes/world/world_cave.tscn"
const PLAYGROUND_SCENE := "res://scenes/world/world_playground.tscn"
const FARM_STUB_SCENE := "res://scenes/world/world_farm_stub.tscn"
const TOWN_STUB_SCENE := "res://scenes/world/world_town_stub.tscn"
const FOREST_STUB_SCENE := "res://scenes/world/world_forest_stub.tscn"
const BEACH_STUB_SCENE := "res://scenes/world/world_beach_stub.tscn"
const MINE_STUB_SCENE := "res://scenes/world/world_mine_stub.tscn"

var pending_spawn_id: String = ""

var _bundle_world_path: String = ""
var _bundle_spawn_id: String = ""
var _saved_world_consumed_at_boot: bool = false

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
	if _saved_world_consumed_at_boot:
		return
	_saved_world_consumed_at_boot = true
	var target: String = _bundle_world_path
	var spawn: String = _bundle_spawn_id
	_bundle_world_path = ""
	_bundle_spawn_id = "default"
	if spawn.is_empty():
		spawn = "default"
	if target.is_empty():
		target = MAIN_SCENE
	if target == MAIN_SCENE:
		# Legacy saves may point to hub/main; route to the playable farm world.
		target = WORLD_FARM_SCENE
		if spawn == "default":
			spawn = "from_main"
	pending_spawn_id = spawn
	var current: String = ""
	if get_tree() and get_tree().current_scene:
		current = get_tree().current_scene.scene_file_path
	if current == target:
		_apply_spawn_to_player()
		pending_spawn_id = ""
		return
	_autosave_before_leave_if_needed()
	var err: Error = get_tree().change_scene_to_file(target)
	if err != OK:
		push_error("WorldRouter: change_scene_to_file failed: %s (err %d)" % [target, err])
		pending_spawn_id = ""
		return
	world_changed.emit(target)


func change_world(scene_path: String, spawn_id: String = "default") -> void:
	print("[WorldRouter] change_world called: scene=", scene_path, ", spawn=", spawn_id)
	_autosave_before_leave_if_needed()
	var resolved_scene: String = scene_path
	var resolved_spawn: String = spawn_id
	if resolved_scene == MAIN_SCENE:
		# Keep main as a technical hub, but route gameplay transitions to farm.
		resolved_scene = WORLD_FARM_SCENE
		if resolved_spawn == "default":
			resolved_spawn = "from_main"
	print("[WorldRouter] Resolved: scene=", resolved_scene, ", spawn=", resolved_spawn)
	if GameManager and GameManager.player_data:
		GameManager.player_data["last_spawn_id"] = resolved_spawn
	pending_spawn_id = resolved_spawn
	print("[WorldRouter] Calling get_tree().change_scene_to_file(", resolved_scene, ")")
	
	# 检查场景文件是否存在
	if not FileAccess.file_exists(resolved_scene):
		push_error("WorldRouter: Scene file does not exist: " + resolved_scene)
		pending_spawn_id = ""
		return
	
	var err: Error = get_tree().change_scene_to_file(resolved_scene)
	print("[WorldRouter] change_scene_to_file returned error code: ", err)
	
	# 提供错误代码的详细解释
	if err != OK:
		var error_msg = ""
		match err:
			19:
				error_msg = "ERR_FILE_CORRUPT - 场景文件解析错误，可能是依赖资源有问题"
				print("[WorldRouter] 建议：尝试在编辑器中打开并重新保存该场景")
				print("[WorldRouter] 建议：检查场景依赖的所有脚本是否有语法错误")
			23:
				error_msg = "ERR_FILE_NOT_FOUND - 场景文件不存在"
				print("[WorldRouter] 请确认文件路径正确: " + resolved_scene)
			_:
				error_msg = "Unknown error code"
		
		push_error("WorldRouter: change_world failed: %s (err %d - %s)" % [resolved_scene, err, error_msg])
		pending_spawn_id = ""
		return
	
	print("[WorldRouter] Scene change initiated successfully, emitting world_changed signal")
	world_changed.emit(resolved_scene)


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


func _autosave_before_leave_if_needed() -> void:
	var cur: Node = get_tree().current_scene
	if cur == null:
		return
	var fm: FarmManager = cur.get_node_or_null("FarmManager") as FarmManager
	if fm == null:
		return
	if FarmStateCache:
		FarmStateCache.sync_from_manager(fm)
	if GameSaveService and GameManager:
		GameSaveService.commit_save(
			GameSaveService.build_runtime_bundle(
				FarmStateCache.get_snapshot(),
				GameManager.journal_world_event_feed,
				GameManager.journal_active_story_hotspot
			)
		)


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
