extends Node2D

class_name FarmManager

# Crop data database
var crops_db = {}

# Planted crops: Dictionary with key as Vector2i position and value as crop data
var planted_crops = {}

# Tilled soil positions
var tilled_soil = {}

## Placed basic sprinklers: tile under the sprinkler (must be tilled, no crop). Waters 4 ortho neighbors each morning.
var sprinkler_tiles: Dictionary = {}

signal crop_planted(position, crop_id)
signal crop_harvested(position, crop_id, quantity)
signal soil_tilled(position)

var _sprinkler_layer: Node2D

func _ready():
	_sprinkler_layer = Node2D.new()
	_sprinkler_layer.name = "SprinklerVisuals"
	_sprinkler_layer.z_index = 2
	add_child(_sprinkler_layer)
	load_crop_database()

	# Connect to game manager day change signal
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _tilemap() -> TileMap:
	var p: Node = get_parent()
	if p:
		return p.get_node_or_null("TileMap") as TileMap
	return null

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
	if sprinkler_tiles.has(position):
		return false
	if not tilled_soil.has(position):
		tilled_soil[position] = true
		soil_tilled.emit(position)
		return true
	return false

func plant_seed(position: Vector2i, crop_id: String) -> bool:
	if not tilled_soil.has(position):
		return false

	if sprinkler_tiles.has(position):
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
	_sprinkler_water_neighbor_tiles()
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
	return tilled_soil.has(position) and not planted_crops.has(position) and not sprinkler_tiles.has(position)

func try_place_sprinkler(position: Vector2i) -> Dictionary:
	if not tilled_soil.has(position):
		return {"ok": false, "reason": "not_tilled"}
	if planted_crops.has(position):
		return {"ok": false, "reason": "has_crop"}
	if sprinkler_tiles.has(position):
		return {"ok": false, "reason": "has_sprinkler"}
	sprinkler_tiles[position] = true
	_water_ortho_neighbors(position)
	_refresh_sprinkler_visuals()
	return {"ok": true}

func has_sprinkler_at(position: Vector2i) -> bool:
	return sprinkler_tiles.has(position)

func remove_sprinkler(position: Vector2i) -> bool:
	if not sprinkler_tiles.has(position):
		return false
	sprinkler_tiles.erase(position)
	_refresh_sprinkler_visuals()
	return true

func _refresh_sprinkler_visuals() -> void:
	if _sprinkler_layer == null:
		return
	for c in _sprinkler_layer.get_children():
		c.queue_free()
	var tm: TileMap = _tilemap()
	if tm == null:
		return
	var cell: Vector2 = Vector2(32, 32)
	if tm.tile_set:
		cell = Vector2(tm.tile_set.tile_size)
	# Full tile, centered on the cell; TileMap → world → SprinklerVisuals local (siblings can differ in transform).
	var half: float = minf(cell.x, cell.y) * 0.5
	for pos in sprinkler_tiles.keys():
		var poly := Polygon2D.new()
		poly.color = Color(0.35, 0.65, 0.95, 0.4)
		var center_world: Vector2 = tm.to_global(tm.map_to_local(pos))
		var top_left: Vector2 = _sprinkler_layer.to_local(center_world) - Vector2(half, half)
		poly.position = top_left
		var s: float = half * 2.0
		poly.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(s, 0), Vector2(s, s), Vector2(0, s)
		])
		_sprinkler_layer.add_child(poly)

func _water_ortho_neighbors(origin: Vector2i) -> void:
	var dirs: Array = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for d in dirs:
		water_plant(origin + d)

func _sprinkler_water_neighbor_tiles() -> void:
	for sp in sprinkler_tiles.keys():
		_water_ortho_neighbors(sp)

func save_farm_data():
	var save_data = {
		"tilled_soil": tilled_soil,
		"planted_crops": planted_crops,
		"sprinkler_tiles": sprinkler_tiles
	}
	return save_data

func load_farm_data(data: Dictionary):
	tilled_soil = data.get("tilled_soil", {})
	planted_crops = data.get("planted_crops", {})
	sprinkler_tiles = _deserialize_sprinklers(data.get("sprinkler_tiles", {}))
	call_deferred("_refresh_sprinkler_visuals")

func _deserialize_sprinklers(raw) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for k in raw.keys():
			if k is Vector2i:
				out[k] = true
			elif k is String:
				var s: String = str(k).strip_edges().replace("(", "").replace(")", "")
				var parts: PackedStringArray = s.split(",")
				if parts.size() >= 2:
					out[Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))] = true
	return out
