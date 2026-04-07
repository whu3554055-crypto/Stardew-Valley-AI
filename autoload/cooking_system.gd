extends Node

func can_cook_here(player_pos: Vector2) -> bool:
	return GameZones.contains_kitchen(player_pos)

func get_recipe_list() -> Array:
	if RecipeCatalog:
		return RecipeCatalog.cooking_recipes
	return []

func try_recipe(recipe: Dictionary) -> Dictionary:
	var cost: Dictionary = RecipeHelpers.recipe_cost(recipe)
	if not _can_afford(cost):
		return {"ok": false, "message": "Not enough ingredients."}
	var out_id: String = RecipeHelpers.recipe_output_id(recipe)
	var template: Dictionary = ItemDatabase.get_item(out_id)
	if template.is_empty():
		return {"ok": false, "message": "Recipe output missing."}
	var qty: int = int(recipe.get("output_qty", recipe.get("qty", 1)))
	var stamina_cost: float = float(recipe.get("stamina", 2.0))
	if not InventoryManager.can_add_quantity(template, qty):
		var nm: String = str(template.get("name", out_id))
		return {"ok": false, "message": "Inventory full — need room for %s ×%d." % [nm, qty]}
	if GameManager and not GameManager.try_consume_stamina(stamina_cost):
		return {"ok": false, "message": "Too tired to cook."}
	for i in range(qty):
		if not InventoryManager.add_item(template.duplicate(true)):
			return {"ok": false, "message": "Inventory full."}
	_consume(cost)
	if QuestSystem:
		QuestSystem.track_event("cook_meal", {"dish_id": out_id, "count": 1})
	if GatheringAlmanac:
		GatheringAlmanac.record_meal(out_id)
	if GatheringSfx:
		GatheringSfx.play_cook()
	var nm2: String = str(template.get("name", out_id))
	return {"ok": true, "message": "Cooked: %s" % nm2}

func _can_afford(costs: Dictionary) -> bool:
	for k in costs.keys():
		if InventoryManager.count_item(str(k)) < int(costs[k]):
			return false
	return true

func _consume(costs: Dictionary) -> void:
	for k in costs.keys():
		InventoryManager.consume_item_by_id(str(k), int(costs[k]))
