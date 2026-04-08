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

## Tilled empty tiles prepped with fertilizer — next successful plant on this cell gets −1 `growth_days` (min 2).
var pending_fertilizer: Dictionary = {}

## Unlocked farm tier (1 = Homestead). Costs and multipliers: `data/farm/tiers.json` via `FarmTierCatalog`.
var farm_tier: int = 1

signal crop_planted(position, crop_id)
signal crop_harvested(position, crop_id, quantity)
signal soil_tilled(position)

var _sprinkler_layer: Node2D
var _fertilizer_layer: Node2D
var _crop_layer: Node2D

## Matches `TileType.TILLED_SOIL` atlas column in `terrain_atlas_32.png` / GameTileMap.
const _TILLED_ATLAS := Vector2i(2, 0)

func _ready():
	_sprinkler_layer = Node2D.new()
	_sprinkler_layer.name = "SprinklerVisuals"
	_sprinkler_layer.z_index = 2
	add_child(_sprinkler_layer)
	_fertilizer_layer = Node2D.new()
	_fertilizer_layer.name = "FertilizerMarkers"
	_fertilizer_layer.z_index = 1
	add_child(_fertilizer_layer)
	_crop_layer = Node2D.new()
	_crop_layer.name = "CropVisuals"
	_crop_layer.z_index = 3
	add_child(_crop_layer)
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

	# Summer — multi-harvest (first full grow, then shorter regrow)
	crops_db["corn"] = {
		"id": "corn",
		"name": "Corn",
		"growth_days": 14,
		"regrow_days": 4,
		"harvest_product": "corn",
		"harvest_count": 1,
		"regrows": true,
		"seasons": ["summer"]
	}

func till_soil(position: Vector2i):
	if sprinkler_tiles.has(position):
		return false
	if not tilled_soil.has(position):
		tilled_soil[position] = true
		soil_tilled.emit(position)
		_paint_tilled_cell(position)
		return true
	return false

func plant_seed(position: Vector2i, crop_id: String) -> Dictionary:
	if not tilled_soil.has(position):
		return {"ok": false, "reason": "not_tilled"}
	if sprinkler_tiles.has(position):
		return {"ok": false, "reason": "sprinkler_tile"}
	if not crops_db.has(crop_id):
		return {"ok": false, "reason": "unknown_crop"}
	if planted_crops.has(position):
		return {"ok": false, "reason": "occupied"}

	var def: Dictionary = crops_db[crop_id]
	var seasons: Array = def.get("seasons", [])
	if seasons.size() > 0 and GameManager:
		var cur: String = str(GameManager.player_data.get("season", "spring"))
		if not cur in seasons:
			return {"ok": false, "reason": "wrong_season"}

	var crop_data = def.duplicate(true)
	crop_data["days_grown"] = 0
	crop_data["planted_day"] = GameManager.player_data.day
	_apply_tier_growth_days(crop_data)
	if pending_fertilizer.has(position):
		pending_fertilizer.erase(position)
		crop_data["growth_days"] = maxi(2, int(crop_data["growth_days"]) - 1)
		crop_data["fertilized"] = true

	planted_crops[position] = crop_data
	crop_planted.emit(position, crop_id)
	_refresh_fertilizer_visuals()
	_refresh_crop_visuals()

	return {"ok": true}

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
	_apply_tier_harvest_bonus(harvest_data)

	crop_harvested.emit(position, crop.id, harvest_data.count)

	# Remove crop or mark for regrowth (optional `regrow_days` vs full `growth_days`)
	if crop.regrows:
		var gd: int = int(crop.growth_days)
		var rr: int = int(crop.get("regrow_days", gd))
		crop.days_grown = maxi(0, gd - rr)
	else:
		planted_crops.erase(position)

	_refresh_crop_visuals()
	return harvest_data


func _apply_tier_harvest_bonus(harvest_data: Dictionary) -> void:
	if not FarmTierCatalog:
		return
	var chance: float = FarmTierCatalog.harvest_bonus_chance(farm_tier)
	var max_bonus: int = FarmTierCatalog.harvest_bonus_max(farm_tier)
	if max_bonus <= 0:
		return
	if randf() > chance:
		return
	var bonus: int = 1 if max_bonus == 1 else (1 + (randi() % max_bonus))
	harvest_data["count"] = int(harvest_data.get("count", 1)) + bonus
	harvest_data["tier_bonus"] = bonus

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
	_refresh_crop_visuals()

func get_growth_stage(crop: Dictionary) -> int:
	var progress = float(crop.days_grown) / crop.growth_days
	var stage = int(progress * 4)
	return clamp(stage, 0, 4)

func _apply_tier_growth_days(crop_data: Dictionary) -> void:
	var mult: float = 1.0
	if FarmTierCatalog:
		mult = FarmTierCatalog.growth_speed_multiplier(farm_tier)
	if mult <= 0.01:
		mult = 1.0
	var gd0: int = int(crop_data.get("growth_days", 1))
	crop_data["growth_days"] = _effective_growth_days(gd0, mult, false)
	if bool(crop_data.get("regrows", false)):
		var rr0: int = int(crop_data.get("regrow_days", gd0))
		crop_data["regrow_days"] = _effective_growth_days(rr0, mult, true)


func _effective_growth_days(base: int, mult: float, is_regrow: bool) -> int:
	if base <= 0:
		return base
	var v: float = float(base) / mult
	if is_regrow:
		return maxi(1, int(round(v)))
	return maxi(2, int(round(v)))


func try_upgrade_next_tier() -> Dictionary:
	if not FarmTierCatalog:
		return {"ok": false, "message": "Farm tiers unavailable."}
	var next_def: Dictionary = FarmTierCatalog.next_tier_def(farm_tier)
	if next_def.is_empty():
		return {"ok": false, "message": FarmTierCatalog.get_message("max_tier")}
	var cost_g: int = int(next_def.get("upgrade_cost_gold", 0))
	var items_cost: Dictionary = next_def.get("upgrade_cost_items", {})
	if GameManager:
		if int(GameManager.player_data.get("gold", 0)) < cost_g:
			var gold_msg: String = FarmTierCatalog.get_message("not_enough_gold")
			gold_msg = gold_msg.replace("{gold}", str(cost_g))
			return {"ok": false, "message": gold_msg}
	for k in items_cost.keys():
		var need: int = int(items_cost[k])
		if InventoryManager.count_item(str(k)) < need:
			return {"ok": false, "message": FarmTierCatalog.get_message("missing_materials")}
	if GameManager:
		GameManager.player_data.gold = int(GameManager.player_data.get("gold", 0)) - cost_g
	for k in items_cost.keys():
		var need: int = int(items_cost[k])
		InventoryManager.consume_item_by_id(str(k), need)
	farm_tier += 1
	var nm: String = str(FarmTierCatalog.tier_def(farm_tier).get("display_name", str(farm_tier)))
	var ok_msg: String = FarmTierCatalog.get_message("upgraded")
	ok_msg = ok_msg.replace("{tier_name}", nm)
	return {"ok": true, "message": ok_msg}


func is_tile_tilled(position: Vector2i) -> bool:
	return tilled_soil.has(position)

func can_plant_here(position: Vector2i) -> bool:
	return tilled_soil.has(position) and not planted_crops.has(position) and not sprinkler_tiles.has(position)

func can_fertilize_here(position: Vector2i) -> bool:
	return can_plant_here(position)

func try_apply_fertilizer(position: Vector2i) -> Dictionary:
	if not can_fertilize_here(position):
		return {"ok": false, "reason": "cannot_fertilize"}
	if pending_fertilizer.has(position):
		return {"ok": false, "reason": "already_fertilized"}
	pending_fertilizer[position] = true
	_refresh_fertilizer_visuals()
	return {"ok": true}

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

func _refresh_fertilizer_visuals() -> void:
	if _fertilizer_layer == null:
		return
	for c in _fertilizer_layer.get_children():
		c.queue_free()
	var tm: TileMap = _tilemap()
	if tm == null:
		return
	var cell: Vector2 = Vector2(32, 32)
	if tm.tile_set:
		cell = Vector2(tm.tile_set.tile_size)
	var half: float = minf(cell.x, cell.y) * 0.5
	for pos in pending_fertilizer.keys():
		var poly := Polygon2D.new()
		poly.color = Color(0.55, 0.42, 0.18, 0.28)
		var center_world: Vector2 = tm.to_global(tm.map_to_local(pos))
		var top_left: Vector2 = _fertilizer_layer.to_local(center_world) - Vector2(half, half)
		poly.position = top_left
		var s: float = half * 2.0
		poly.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(s, 0), Vector2(s, s), Vector2(0, s)
		])
		_fertilizer_layer.add_child(poly)

func _crop_stage_texture_path(crop_id: String, growth_stage: int) -> String:
	var g: int = clampi(growth_stage, 0, 4)
	match crop_id:
		"parsnip":
			return "res://assets/sprites/crops/parsnip_stage_%d.png" % mini(g, 3)
		"potato":
			return "res://assets/sprites/crops/potato_stage_%d.png" % mini(g, 4)
		"cauliflower":
			var idx: int = clampi(int(round(float(g) * 5.0 / 4.0)), 0, 5)
			return "res://assets/sprites/crops/cauliflower_stage_%d.png" % idx
		"corn":
			var cidx: int = clampi(int(round(float(g) * 6.0 / 4.0)), 0, 6)
			return "res://assets/sprites/crops/corn_stage_%d.png" % cidx
		_:
			return ""

func _refresh_crop_visuals() -> void:
	if _crop_layer == null:
		return
	for c in _crop_layer.get_children():
		c.queue_free()
	var tm: TileMap = _tilemap()
	if tm == null:
		return
	var cell: Vector2 = Vector2(32, 32)
	if tm.tile_set:
		cell = Vector2(tm.tile_set.tile_size)
	for pos in planted_crops.keys():
		var crop: Dictionary = planted_crops[pos]
		var st: int = get_growth_stage(crop)
		var path: String = _crop_stage_texture_path(str(crop.get("id", "")), st)
		if path.is_empty():
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		var center_world: Vector2 = tm.to_global(tm.map_to_local(pos))
		spr.position = _crop_layer.to_local(center_world)
		var sc: float = minf(cell.x / float(tex.get_width()), cell.y / float(tex.get_height())) * 0.88
		spr.scale = Vector2(sc, sc)
		_crop_layer.add_child(spr)

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
		"sprinkler_tiles": sprinkler_tiles,
		"pending_fertilizer": pending_fertilizer,
		"farm_tier": farm_tier
	}
	return save_data

func load_farm_data(data: Dictionary):
	tilled_soil = _deserialize_vec2i_key_dict(data.get("tilled_soil", {}))
	planted_crops = _deserialize_vec2i_key_dict(data.get("planted_crops", {}))
	sprinkler_tiles = _deserialize_sprinklers(data.get("sprinkler_tiles", {}))
	pending_fertilizer = _deserialize_sprinklers(data.get("pending_fertilizer", {}))
	farm_tier = int(data.get("farm_tier", 1))
	if FarmTierCatalog:
		farm_tier = clampi(farm_tier, 1, maxi(1, FarmTierCatalog.max_tier()))
	call_deferred("_refresh_sprinkler_visuals")
	call_deferred("_refresh_fertilizer_visuals")
	call_deferred("_refresh_crop_visuals")
	call_deferred("_refresh_tilled_tilemap")

func _deserialize_vec2i_key_dict(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for k in raw.keys():
			if k is Vector2i:
				out[k] = raw[k]
			elif k is String:
				var s: String = str(k).strip_edges().replace("(", "").replace(")", "")
				var parts: PackedStringArray = s.split(",")
				if parts.size() >= 2:
					out[Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))] = raw[k]
	return out

func _paint_tilled_cell(pos: Vector2i) -> void:
	var tm: TileMap = _tilemap()
	if tm == null:
		return
	tm.set_cell(0, pos, 0, _TILLED_ATLAS)

func _refresh_tilled_tilemap() -> void:
	var tm: TileMap = _tilemap()
	if tm == null:
		return
	for k in tilled_soil.keys():
		if k is Vector2i:
			tm.set_cell(0, k, 0, _TILLED_ATLAS)

func _deserialize_sprinklers(raw: Variant) -> Dictionary:
	var base: Dictionary = _deserialize_vec2i_key_dict(raw)
	var out: Dictionary = {}
	for k in base.keys():
		out[k] = true
	return out
