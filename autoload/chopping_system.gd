extends Node

## When set (world_forest scene), overrides hub `GameZones.rect_forest` hit-test.
var _forest_bounds_override: Rect2 = Rect2(0.0, 0.0, -1.0, -1.0)


func _ready() -> void:
	call_deferred("_hook_world_router")


func _hook_world_router() -> void:
	if WorldRouter and not WorldRouter.world_changed.is_connected(_on_world_changed_clear_forest):
		WorldRouter.world_changed.connect(_on_world_changed_clear_forest)


func _on_world_changed_clear_forest(scene_path: String) -> void:
	if not String(scene_path).ends_with("world_forest.tscn"):
		clear_forest_bounds_override()


func set_forest_bounds_override(r: Rect2) -> void:
	_forest_bounds_override = r


func clear_forest_bounds_override() -> void:
	_forest_bounds_override = Rect2(0.0, 0.0, -1.0, -1.0)


func can_chop_here(player_pos: Vector2) -> bool:
	if _forest_bounds_override.size.x > 0.0 and _forest_bounds_override.size.y > 0.0:
		return _forest_bounds_override.has_point(player_pos)
	return GameZones.contains_forest(player_pos)

func try_chop_one() -> Dictionary:
	var template: Dictionary = ItemDatabase.get_item("wood_log")
	if template.is_empty():
		return {"ok": false, "message": "Missing wood item data."}
	if not InventoryManager.can_add_quantity(template, 2):
		return {"ok": false, "message": "Inventory full — need room for up to 2 Wood."}
	if GameManager and not GameManager.try_consume_stamina(4.0):
		return {"ok": false, "message": "Too tired to swing the axe."}

	var n: int = 1 + (randi() % 2)
	for i in range(n):
		if not InventoryManager.add_item(template.duplicate(true)):
			return {"ok": false, "message": "Inventory full."}
	var msg: String = "Chopped %d wood." % n
	var sap_tpl: Dictionary = ItemDatabase.get_item("tree_sap")
	if not sap_tpl.is_empty() and randf() < 0.12:
		if InventoryManager.can_add_quantity(sap_tpl, 1) and InventoryManager.add_item(sap_tpl.duplicate(true)):
			msg += " Also found tree sap!"
	if QuestSystem:
		QuestSystem.track_event("chop_wood", {"count": 1})
	if GatheringSfx:
		GatheringSfx.play_chop()
	return {"ok": true, "message": msg}
