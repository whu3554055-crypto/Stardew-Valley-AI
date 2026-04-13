extends TileMap

class_name GameTileMap

# ============================================
# Enhanced Town Layout with Functional Zones
# Supports diverse NPC archetypes and activities
# ============================================

# Tile types
enum TileType {
	GRASS = 0,
	DIRT = 1,
	TILLED_SOIL = 2,
	WATER = 3,
	STONE = 4,
	WOOD_FLOOR = 5,
	SAND = 6,
	Cobblestone = 7,
	FLOWER_BED = 8,
	TREE = 9,
	FENCE = 10
}

@export var auto_generate_map: bool = true

# Zone definitions for NPC navigation and scheduling
var town_zones = {
	# RESIDENTIAL ZONES
	"residential": {
		"pierre_house": {"pos": Vector2i(25, 20), "size": Vector2i(6, 5)},
		"thornwood_cottage": {"pos": Vector2i(50, 15), "size": Vector2i(4, 4)},
		"nightingale_manor": {"pos": Vector2i(60, 10), "size": Vector2i(8, 7)},
		"travelers_hostel": {"pos": Vector2i(35, 25), "size": Vector2i(6, 5)},
		"farming_homestead": {"pos": Vector2i(15, 30), "size": Vector2i(5, 5)},
		"fisherman_cabin": {"pos": Vector2i(70, 35), "size": Vector2i(4, 4)},
		"witch_cottage": {"pos": Vector2i(5, 5), "size": Vector2i(4, 4)}
	},
	
	# COMMERCIAL ZONES
	"commercial": {
		"general_store": {"pos": Vector2i(30, 20), "size": Vector2i(5, 4)},
		"bookstore": {"pos": Vector2i(35, 20), "size": Vector2i(5, 4)},
		"cafe": {"pos": Vector2i(40, 20), "size": Vector2i(4, 4)},
		"restaurant": {"pos": Vector2i(45, 20), "size": Vector2i(6, 5)},
		"cinema": {"pos": Vector2i(50, 20), "size": Vector2i(8, 6)},
		"arcade": {"pos": Vector2i(58, 20), "size": Vector2i(6, 5)},
		"supermarket": {"pos": Vector2i(40, 25), "size": Vector2i(8, 6)},
		"hotel": {"pos": Vector2i(30, 25), "size": Vector2i(10, 8)},
		"research_lab": {"pos": Vector2i(55, 12), "size": Vector2i(6, 5)},
		"art_studio": {"pos": Vector2i(65, 20), "size": Vector2i(5, 5)},
		"music_shop": {"pos": Vector2i(70, 20), "size": Vector2i(4, 4)}
	},
	
	# RECREATIONAL/NATURE ZONES
	"recreational": {
		"town_square": {"pos": Vector2i(35, 18), "size": Vector2i(10, 8)},
		"town_square_stage": {"pos": Vector2i(40, 17), "size": Vector2i(4, 2)},
		"park": {"pos": Vector2i(20, 15), "size": Vector2i(10, 8)},
		"forest": {"pos": Vector2i(5, 15), "size": Vector2i(15, 20)},
		"beach": {"pos": Vector2i(65, 30), "size": Vector2i(15, 10)},
		"fishing_spot": {"pos": Vector2i(75, 32), "size": Vector2i(5, 5)},
		"mountains": {"pos": Vector2i(5, 5), "size": Vector2i(20, 10)},
		"community_center": {"pos": Vector2i(25, 15), "size": Vector2i(8, 6)},
		"garden_plots": {"pos": Vector2i(15, 25), "size": Vector2i(8, 6)},
		"campground": {"pos": Vector2i(10, 30), "size": Vector2i(6, 6)}
	},
	
	# SPECIAL/UTILITY ZONES
	"special": {
		"farm_area": {"pos": Vector2i(10, 35), "size": Vector2i(20, 15)},
		"greenhouse": {"pos": Vector2i(18, 38), "size": Vector2i(4, 4)},
		"mine_entrance": {"pos": Vector2i(5, 25), "size": Vector2i(3, 3)},
		"cemetery": {"pos": Vector2i(60, 5), "size": Vector2i(8, 6)},
		"library": {"pos": Vector2i(42, 15), "size": Vector2i(6, 5)},
		"museum": {"pos": Vector2i(48, 15), "size": Vector2i(6, 5)},
		"hospital": {"pos": Vector2i(20, 20), "size": Vector2i(6, 5)},
		"school": {"pos": Vector2i(15, 20), "size": Vector2i(6, 5)}
	}
}

# Path connections between zones (for NPC navigation)
var zone_paths = [
	# Main street (horizontal)
	{"from": "town_square", "to": "general_store", "type": "main_street"},
	{"from": "general_store", "to": "bookstore", "type": "main_street"},
	{"from": "bookstore", "to": "cafe", "type": "main_street"},
	{"from": "cafe", "to": "restaurant", "type": "main_street"},
	{"from": "restaurant", "to": "cinema", "type": "main_street"},
	
	# Vertical paths
	{"from": "town_square", "to": "park", "type": "path"},
	{"from": "park", "to": "forest", "type": "trail"},
	{"from": "town_square", "to": "residential", "type": "residential_street"},
	
	# Recreational connections
	{"from": "park", "to": "beach", "type": "scenic_trail"},
	{"from": "forest", "to": "mountains", "type": "hiking_trail"},
	{"from": "beach", "to": "fishing_spot", "type": "coastal_path"}
]

func _ready():
	if tile_set == null:
		tile_set = _create_main_tileset()
	if auto_generate_map:
		generate_enhanced_map()
		initialize_zone_data()


func _cell_randf(cx: int, cy: int, salt: int = 0) -> float:
	"""Deterministic 0..1 value per tile so maps stay stable across runs."""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cx, cy, salt))
	return rng.randf()


func _create_main_tileset() -> TileSet:
	## 11 tiles in one row (see TileType) — built from `assets/tiles/terrain_atlas_32.png`.
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var tex: Texture2D = load("res://assets/tiles/terrain_atlas_32.png") as Texture2D
	if tex == null:
		push_error("GameTileMap: missing res://assets/tiles/terrain_atlas_32.png")
		return ts
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	for i in range(11):
		var at := Vector2i(i, 0)
		src.create_tile(at)
	ts.add_source(src, 0)
	return ts

func generate_enhanced_map():
	"""Generate comprehensive town map with all zones"""
	var map_size = Vector2i(80, 50)
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var tile_type = determine_tile_type(x, y)
			set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))

func determine_tile_type(x: int, y: int) -> int:
	"""Determine tile type based on zone location"""
	# Check each zone category
	for zone_category in town_zones.keys():
		for zone_name in town_zones[zone_category].keys():
			var zone = town_zones[zone_category][zone_name]
			if is_in_zone(x, y, zone):
				return get_zone_tile_type(zone_name, x, y, zone_category)
	
	# Default to grass for undefined areas
	return TileType.GRASS

func is_in_zone(x: int, y: int, zone: Dictionary) -> bool:
	"""Check if coordinates are within a zone"""
	var pos = zone.pos
	var size = zone.size
	return x >= pos.x and x < pos.x + size.x and y >= pos.y and y < pos.y + size.y

func get_zone_tile_type(zone_name: String, x: int, y: int, category: String) -> int:
	"""Get appropriate tile type for a zone"""
	match category:
		"residential":
			return TileType.WOOD_FLOOR if is_building_interior(x, y, town_zones.residential[zone_name]) else TileType.DIRT
		"commercial":
			return TileType.Cobblestone if is_building_interior(x, y, town_zones.commercial[zone_name]) else TileType.Cobblestone
		"recreational":
			return get_recreational_tile(zone_name, x, y)
		"special":
			return get_special_tile(zone_name, x, y)
		_:
			return TileType.GRASS

func is_building_interior(x: int, y: int, zone: Dictionary) -> bool:
	"""Check if position is inside building (simplified - assumes center 60% is interior)"""
	var pos = zone.pos
	var size = zone.size
	var margin_x = int(size.x * 0.2)
	var margin_y = int(size.y * 0.2)
	
	return x >= pos.x + margin_x and x < pos.x + size.x - margin_x and \
		   y >= pos.y + margin_y and y < pos.y + size.y - margin_y

func get_recreational_tile(zone_name: String, x: int, y: int) -> int:
	"""Get tile type for recreational zones"""
	match zone_name:
		"town_square", "town_square_stage":
			return TileType.Cobblestone
		"park":
			if _cell_randf(x, y, 11) < 0.1:  # 10% flowers
				return TileType.FLOWER_BED
			return TileType.GRASS
		"forest":
			if _cell_randf(x, y, 21) < 0.3:  # 30% trees
				return TileType.TREE
			return TileType.GRASS
		"beach":
			return TileType.SAND
		"fishing_spot":
			if _cell_randf(x, y, 31) < 0.7:  # 70% water
				return TileType.WATER
			return TileType.SAND
		"mountains":
			if _cell_randf(x, y, 41) < 0.4:  # 40% stone
				return TileType.STONE
			return TileType.GRASS
		"garden_plots":
			return TileType.TILLED_SOIL
		_:
			return TileType.GRASS

func get_special_tile(zone_name: String, x: int, y: int) -> int:
	"""Get tile type for special zones"""
	match zone_name:
		"farm_area":
			if is_farm_plot(x, y):
				return TileType.TILLED_SOIL
			return TileType.GRASS
		"greenhouse":
			return TileType.TILLED_SOIL
		"mine_entrance":
			return TileType.STONE
		"cemetery":
			if _cell_randf(x, y, 51) < 0.2:
				return TileType.STONE  # Headstones
			return TileType.GRASS
		"library", "museum", "hospital", "school":
			return TileType.WOOD_FLOOR if is_building_interior(x, y, town_zones.special[zone_name]) else TileType.DIRT
		_:
			return TileType.GRASS

func is_farm_plot(x: int, y: int) -> bool:
	"""Determine if position should be tilled soil"""
	var farm_zone = town_zones.special.farm_area
	var relative_x = x - farm_zone.pos.x
	var relative_y = y - farm_zone.pos.y
	
	# Create organized farm plots
	return (relative_x % 3 != 0) and (relative_y % 3 != 0)

func initialize_zone_data():
	"""Initialize zone metadata for NPC pathfinding"""
	# This would connect to NPCBehaviorController for pathfinding
	print("[GameTileMap] Initialized ", town_zones.keys().size(), " zone categories")
	print("[GameTileMap] Total zones: ", get_total_zone_count())

func get_total_zone_count() -> int:
	"""Get total number of defined zones"""
	var count = 0
	for category in town_zones.keys():
		count += town_zones[category].size()
	return count

# ============================================
# UTILITY FUNCTIONS FOR NPC NAVIGATION
# ============================================

func get_zone_at(position: Vector2i) -> String:
	"""Get zone name at a specific position"""
	for category in town_zones.keys():
		for zone_name in town_zones[category].keys():
			var zone = town_zones[category][zone_name]
			if is_in_zone(position.x, position.y, zone):
				return zone_name
	return "unknown"

func get_zone_center(zone_name: String) -> Vector2i:
	"""Get center position of a zone"""
	for category in town_zones.keys():
		if town_zones[category].has(zone_name):
			var zone = town_zones[category][zone_name]
			return Vector2i(
				zone.pos.x + zone.size.x / 2,
				zone.pos.y + zone.size.y / 2
			)
	return Vector2i(40, 20)  # Default to town square

func get_path_between_zones(from_zone: String, to_zone: String) -> Array:
	"""Get path between two zones (simplified - returns direct line)"""
	var start = get_zone_center(from_zone)
	var end = get_zone_center(to_zone)
	
	var path = []
	var steps = start.distance_to(end) / 2.0
	
	for i in range(int(steps)):
		var t = float(i) / steps
		var x = lerp(start.x, end.x, t)
		var y = lerp(start.y, end.y, t)
		path.append(Vector2i(int(x), int(y)))
	
	return path

func get_tile_at(position: Vector2i) -> int:
	var atlas: Vector2i = get_cell_atlas_coords(0, position)
	if atlas == Vector2i(-1, -1):
		return TileType.GRASS
	return int(atlas.x)

func is_walkable(position: Vector2i) -> bool:
	"""Check if a position is walkable"""
	var tile = get_tile_at(position)
	# Trees, water, and some stone areas are not walkable
	return tile not in [TileType.TREE, TileType.WATER]

func get_random_walkable_position_in_zone(zone_name: String) -> Vector2i:
	"""Get a random walkable position within a zone"""
	for category in town_zones.keys():
		if town_zones[category].has(zone_name):
			var zone = town_zones[category][zone_name]
			for attempt in range(20):
				var x = zone.pos.x + randi() % zone.size.x
				var y = zone.pos.y + randi() % zone.size.y
				var pos = Vector2i(x, y)
				if is_walkable(pos):
					return pos
			# Fallback to center
			return get_zone_center(zone_name)
	
	return Vector2i(40, 20)  # Default fallback
