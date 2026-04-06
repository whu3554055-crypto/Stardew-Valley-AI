extends Node

# Save/Load System
# Manages game state persistence using JSON files

signal game_saved(save_slot: int)
signal game_loaded(save_slot: int)
signal save_failed(error: String)

const SAVE_DIR = "user://saves"
const MAX_SAVE_SLOTS = 3

var current_save_slot = 1

func _ready():
	_ensure_save_directory()
	print("Save system initialized")

func _ensure_save_directory():
	"""Ensure save directory exists"""
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
		print("Created save directory: ", SAVE_DIR)

func get_save_path(slot: int) -> String:
	"""Get file path for save slot"""
	return "%s/save_%d.json" % [SAVE_DIR, slot]

func save_game(slot: int = -1) -> bool:
	"""Save current game state"""
	var save_slot = slot if slot > 0 else current_save_slot

	if save_slot < 1 or save_slot > MAX_SAVE_SLOTS:
		emit_signal("save_failed", "Invalid save slot: %d" % save_slot)
		return false

	var save_data = collect_save_data()
	var json_string = JSON.stringify(save_data, "  ")

	var file_path = get_save_path(save_slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		var error = "Failed to open file for writing: " + file_path
		emit_signal("save_failed", error)
		print(error)
		return false

	file.store_string(json_string)
	file.close()

	current_save_slot = save_slot
	emit_signal("game_saved", save_slot)
	print("Game saved to slot ", save_slot)
	return true

func load_game(slot: int = -1) -> Dictionary:
	"""Load game state from save slot"""
	var load_slot = slot if slot > 0 else current_save_slot

	var file_path = get_save_path(load_slot)

	if not FileAccess.file_exists(file_path):
		var error = "Save file not found: " + file_path
		emit_signal("save_failed", error)
		print(error)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		var error = "Failed to open file for reading: " + file_path
		emit_signal("save_failed", error)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		var error = "JSON parse error: " + str(parse_error)
		emit_signal("save_failed", error)
		print(error)
		return {}

	var save_data = json.data
	current_save_slot = load_slot

	emit_signal("game_loaded", load_slot)
	print("Game loaded from slot ", load_slot)
	return save_data

func collect_save_data() -> Dictionary:
	"""Collect all game state data for saving"""
	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		return {}

	var town_square = main_node.get_node_or_null("TownSquare")

	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": {},
		"inventory": {},
		"farming": {},
		"quests": {},
		"npc_data": {}
	}

	# Game state
	if main_node.has_node("game_state") or main_node.get("game_state"):
		save_data["game_state"] = {
			"season": main_node.game_state.season,
			"day": main_node.game_state.day,
			"year": main_node.game_state.year,
			"time": main_node.game_state.time,
			"weather": main_node.game_state.weather
		}

	# Inventory
	if town_square and town_square.has_node("InventorySystem"):
		var inv_system = town_square.get_node("InventorySystem")
		save_data["inventory"] = {
			"gold": inv_system.player_gold,
			"items": inv_system.inventory
		}

	# Farming
	if town_square and town_square.has_node("FarmingSystem"):
		var farm_system = town_square.get_node("FarmingSystem")
		save_data["farming"] = {
			"plots": farm_system.farm_plots,
			"current_day": farm_system.current_day,
			"current_season": farm_system.current_season
		}

	# Quests
	if town_square and town_square.has_node("QuestSystem"):
		var quest_system = town_square.get_node("QuestSystem")
		save_data["quests"] = {
			"active_quests": quest_system.active_quests,
			"completed_quests": quest_system.completed_quests,
			"current_day": quest_system.current_day
		}

	# NPC data (positions, relationships, etc.)
	if town_square and town_square.has_node("NPCs"):
		var npcs = town_square.get_node("NPCs")
		var npc_data = {}
		for npc in npcs.get_children():
			if npc.has_method("get_npc_id"):
				npc_data[npc.get_npc_id()] = {
					"position": {"x": npc.position.x, "y": npc.position.y}
				}
		save_data["npc_data"] = npc_data

	return save_data

func apply_save_data(save_data: Dictionary) -> bool:
	"""Apply loaded save data to game systems"""
	if save_data.is_empty():
		return false

	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		return false

	var town_square = main_node.get_node_or_null("TownSquare")

	# Apply game state
	if save_data.has("game_state"):
		var gs = save_data["game_state"]
		main_node.game_state.season = gs.get("season", "spring")
		main_node.game_state.day = gs.get("day", 1)
		main_node.game_state.year = gs.get("year", 1)
		main_node.game_state.time = gs.get("time", 8.0)
		main_node.game_state.weather = gs.get("weather", "sunny")
		main_node.update_time_display()

	# Apply inventory
	if save_data.has("inventory") and town_square:
		var inv_data = save_data["inventory"]
		if town_square.has_node("InventorySystem"):
			var inv_system = town_square.get_node("InventorySystem")
			inv_system.player_gold = inv_data.get("gold", 500)
			inv_system.inventory = inv_data.get("items", {})
			inv_system.emit_signal("gold_changed", inv_system.player_gold)
			inv_system.emit_signal("inventory_updated")

	# Apply farming
	if save_data.has("farming") and town_square:
		var farm_data = save_data["farming"]
		if town_square.has_node("FarmingSystem"):
			var farm_system = town_square.get_node("FarmingSystem")
			farm_system.farm_plots = farm_data.get("plots", {})
			farm_system.current_day = farm_data.get("current_day", 1)
			farm_system.current_season = farm_data.get("current_season", "spring")

	# Apply quests
	if save_data.has("quests") and town_square:
		var quest_data = save_data["quests"]
		if town_square.has_node("QuestSystem"):
			var quest_system = town_square.get_node("QuestSystem")
			quest_system.active_quests = quest_data.get("active_quests", {})
			quest_system.completed_quests = quest_data.get("completed_quests", [])
			quest_system.current_day = quest_data.get("current_day", 1)

	print("Save data applied successfully")
	return true

func get_save_info(slot: int) -> Dictionary:
	"""Get basic info about a save file without loading it"""
	var file_path = get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		return {"exists": false}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {"exists": false}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		return {"exists": true, "valid": false, "error": "Invalid JSON"}

	var data = json.data
	return {
		"exists": true,
		"valid": true,
		"version": data.get("version", "unknown"),
		"timestamp": data.get("timestamp", "unknown"),
		"season": data.get("game_state", {}).get("season", "unknown"),
		"day": data.get("game_state", {}).get("day", 0),
		"gold": data.get("inventory", {}).get("gold", 0)
	}

func delete_save(slot: int) -> bool:
	"""Delete a save file"""
	var file_path = get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		return false

	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.remove(file_path.get_file())
		print("Deleted save slot ", slot)
		return true

	return false

func has_save(slot: int) -> bool:
	"""Check if save file exists"""
	var file_path = get_save_path(slot)
	return FileAccess.file_exists(file_path)

func get_available_saves() -> Array:
	"""Get list of available save slots with info"""
	var saves = []
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var info = get_save_info(slot)
		info["slot"] = slot
		saves.append(info)
	return saves
