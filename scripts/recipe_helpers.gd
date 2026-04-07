class_name RecipeHelpers
extends RefCounted

## Lists only materials where have < need: "Coal 0/1, Wood 1/2"
static func format_material_gap(costs: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var keys: Array = costs.keys()
	keys.sort()
	for k in keys:
		var need: int = int(costs[k])
		var have: int = InventoryManager.count_item(str(k))
		if have >= need:
			continue
		var nm: String = str(ItemDatabase.get_item(str(k)).get("name", str(k)))
		parts.append("%s %d/%d" % [nm, have, need])
	if parts.is_empty():
		return ""
	return ", ".join(parts)

## First recipe in list the player cannot afford — for failure hints.
static func hint_first_unaffordable(recipes: Array) -> String:
	for r in recipes:
		var cost: Dictionary = r.get("in", {})
		var affordable := true
		for k in cost.keys():
			if InventoryManager.count_item(str(k)) < int(cost[k]):
				affordable = false
				break
		if affordable:
			continue
		var out_id: String = str(r.get("out", ""))
		var label: String = str(ItemDatabase.get_item(out_id).get("name", out_id))
		var gap: String = format_material_gap(cost)
		if gap.is_empty():
			return "Check ingredients for %s." % label
		return "%s — need: %s" % [label, gap]
	return ""
