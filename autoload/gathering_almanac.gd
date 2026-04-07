extends Node

signal collection_updated

## Fish / mineral discovery counts for collection UI and saves.
var fish_caught: Dictionary = {}
var minerals_mined: Dictionary = {}
var smelted_bars: Dictionary = {}
var meals_cooked: Dictionary = {}

const SAVE_PATH := "user://gathering_almanac.save"

func record_fish(fish_id: String) -> void:
	if fish_id.is_empty():
		return
	fish_caught[fish_id] = int(fish_caught.get(fish_id, 0)) + 1
	collection_updated.emit()

func record_mineral(ore_id: String) -> void:
	if ore_id.is_empty():
		return
	minerals_mined[ore_id] = int(minerals_mined.get(ore_id, 0)) + 1
	collection_updated.emit()

func record_smelt(bar_id: String) -> void:
	if bar_id.is_empty():
		return
	smelted_bars[bar_id] = int(smelted_bars.get(bar_id, 0)) + 1
	collection_updated.emit()

func record_meal(dish_id: String) -> void:
	if dish_id.is_empty():
		return
	meals_cooked[dish_id] = int(meals_cooked.get(dish_id, 0)) + 1
	collection_updated.emit()

func get_fish_discovered_count() -> int:
	return fish_caught.size()

func get_unique_fish_ids() -> Array:
	return fish_caught.keys()

func save_data() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		return
	f.store_var({
		"fish": fish_caught,
		"minerals": minerals_mined,
		"smelted": smelted_bars,
		"meals": meals_cooked
	})
	f.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = f.get_var()
	f.close()
	if data is Dictionary:
		if data.get("fish") is Dictionary:
			fish_caught = data.fish
		if data.get("minerals") is Dictionary:
			minerals_mined = data.minerals
		if data.get("smelted") is Dictionary:
			smelted_bars = data.smelted
		if data.get("meals") is Dictionary:
			meals_cooked = data.meals
