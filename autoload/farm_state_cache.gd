extends Node

## Holds farm tile/crop state when `FarmManager` is not in the current scene (B2 hub split).

var _farm: Dictionary = {}


func clear() -> void:
	_farm.clear()


func is_empty() -> bool:
	return _farm.is_empty()


func set_from_dict(d: Dictionary) -> void:
	_farm = _dup_farm_slice(d)


func get_snapshot() -> Dictionary:
	return _dup_farm_slice(_farm)


func sync_from_manager(fm: FarmManager) -> void:
	if fm == null:
		return
	set_from_dict(fm.save_farm_data())


func push_to_manager(fm: FarmManager) -> void:
	if fm == null:
		return
	fm.load_farm_data(_dup_farm_slice(_farm))


func _dup_farm_slice(d: Dictionary) -> Dictionary:
	return {
		"tilled_soil": (d.get("tilled_soil", {}) as Dictionary).duplicate(true),
		"planted_crops": (d.get("planted_crops", {}) as Dictionary).duplicate(true),
		"sprinkler_tiles": (d.get("sprinkler_tiles", {}) as Dictionary).duplicate(true),
		"pending_fertilizer": (d.get("pending_fertilizer", {}) as Dictionary).duplicate(true),
		"farm_tier": int(d.get("farm_tier", 1)),
	}
