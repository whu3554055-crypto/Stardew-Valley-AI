extends Node

func can_chop_here(player_pos: Vector2) -> bool:
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
