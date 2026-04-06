extends Node2D

class_name FarmManager

# Crop data database
var crops_db = {}

# Planted crops: Dictionary with key as Vector2i position and value as crop data
var planted_crops = {}

# Tilled soil positions
var tilled_soil = {}

signal crop_planted(position, crop_id)
signal crop_harvested(position, crop_id, quantity)
signal soil_tilled(position)

func _ready():
	load_crop_database()

	# Connect to game manager day change signal
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func load_crop_database():
	# Example crop definitions
	crops_db["parsnip"] = {
		"id": "parsnip",
		"name": "Parsnip",
		"growth_days": 4,
		"harvest_product": "parsnip",
		"harvest_count": 1,
		"regrows": false,
		"seasons": ["spring"]
	}

	crops_db["cauliflower"] = {
		"id": "cauliflower",
		"name": "Cauliflower",
		"growth_days": 12,
		"harvest_product": "cauliflower",
		"harvest_count": 1,
		"regrows": false,
		"seasons": ["spring"]
	}

	crops_db["potato"] = {
		"id": "potato",
		"name": "Potato",
		"growth_days": 6,
		"harvest_product": "potato",
		"harvest_count": 1,
		"regrows": false,
		"seasons": ["spring"]
	}

func till_soil(position: Vector2i):
	if not tilled_soil.has(position):
		tilled_soil[position] = true
		soil_tilled.emit(position)
		return true
	return false

func plant_seed(position: Vector2i, crop_id: String) -> bool:
	if not tilled_soil.has(position):
		return false

	if not crops_db.has(crop_id):
		return false

	if planted_crops.has(position):
		return false

	var crop_data = crops_db[crop_id].duplicate(true)
	crop_data["days_grown"] = 0
	crop_data["planted_day"] = GameManager.player_data.day

	planted_crops[position] = crop_data
	crop_planted.emit(position, crop_id)

	return true

func harvest_crop(position: Vector2i) -> Dictionary:
	if not planted_crops.has(position):
		return {}

	var crop = planted_crops[position]
	var growth_stage = get_growth_stage(crop)

	# Can only harvest when fully grown
	if growth_stage < 4:
		return {}

	var harvest_data = {
		"product": crop.harvest_product,
		"count": crop.harvest_count
	}

	crop_harvested.emit(position, crop.id, harvest_data.count)

	# Remove crop or mark for regrowth
	if crop.regrows:
		crop.days_grown = 0
	else:
		planted_crops.erase(position)

	return harvest_data

func water_plant(position: Vector2i):
	if planted_crops.has(position):
		planted_crops[position]["watered"] = true

func _on_day_changed(new_day):
	# Grow all crops
	for position in planted_crops:
		var crop = planted_crops[position]
		if crop.watered:
			crop.days_grown += 1
			crop.watered = false  # Reset water status

func get_growth_stage(crop: Dictionary) -> int:
	var progress = float(crop.days_grown) / crop.growth_days
	var stage = int(progress * 4)
	return clamp(stage, 0, 4)

func is_tile_tilled(position: Vector2i) -> bool:
	return tilled_soil.has(position)

func can_plant_here(position: Vector2i) -> bool:
	return tilled_soil.has(position) and not planted_crops.has(position)

func save_farm_data():
	var save_data = {
		"tilled_soil": tilled_soil,
		"planted_crops": planted_crops
	}
	return save_data

func load_farm_data(data: Dictionary):
	tilled_soil = data.get("tilled_soil", {})
	planted_crops = data.get("planted_crops", {})
