extends Node2D

## S0.5-1: Farm TileSet builder — creates TileSet from farm32 ground assets and assigns to TileMap.

## Tile type constants (match atlas column indices)
const TILE_GRASS := Vector2i(0, 0)
const TILE_PATH := Vector2i(1, 0)
const TILE_TILLED := Vector2i(2, 0)
const TILE_WATERED := Vector2i(3, 0)
const TILE_TRANSITION_GRASS_FARMLAND := Vector2i(4, 0)
const TILE_TRANSITION_GRASS_PATH := Vector2i(5, 0)

func _ready() -> void:
	_setup_farm_tileset()

func _setup_farm_tileset() -> void:
	# FarmTileSetBuilder is a child of TileMap, so get_parent() IS the TileMap
	var tm: TileMap = get_parent() as TileMap
	if tm == null:
		push_error("FarmTileSetBuilder: parent is not a TileMap")
		return

	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	# Load individual tile textures and create separate sources for each
	var tile_configs = [
		{"key": TILE_GRASS, "path": "res://assets/tiles/farm32/ground/grass_base_v01.png", "name": "grass"},
		{"key": TILE_PATH, "path": "res://assets/tiles/farm32/ground/path_dirt_base_v02.png", "name": "path"},
		{"key": TILE_TILLED, "path": "res://assets/tiles/farm32/ground/farmland_base_v01.png", "name": "tilled"},
		{"key": TILE_WATERED, "path": "res://assets/tiles/farm32/ground/farmland_watered_v01.png", "name": "watered"},
		{"key": TILE_TRANSITION_GRASS_FARMLAND, "path": "res://assets/tiles/farm32/ground/transition_grass_to_farmland_v02.png", "name": "transition_farmland"},
		{"key": TILE_TRANSITION_GRASS_PATH, "path": "res://assets/tiles/farm32/ground/transition_grass_to_path_v02.png", "name": "transition_path"},
	]

	for i in range(tile_configs.size()):
		var config = tile_configs[i]
		var tex: Texture2D = load(config.path) as Texture2D
		if tex == null:
			push_warning("FarmTileSetBuilder: failed to load %s" % config.path)
			continue

		# Create a source for this tile
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(32, 32)
		src.create_tile(Vector2i(0, 0))
		# NOTE: TileSetAtlasSource has no 'name' property in Godot 4.x; using tile index to identify.

		ts.add_source(src, i)

	tm.tile_set = ts

	# Now paint the base tiles (grass everywhere, paths and tilled soil in specific zones)
	_paint_farm_ground(tm)

	print("[FarmTileSetBuilder] TileSet created with %d tile types, farm ground painted." % tile_configs.size())

func _paint_farm_ground(tm: TileMap) -> void:
	# Full farm area: 32x23 tiles, fill with grass (source 0)
	for x in range(32):
		for y in range(23):
			tm.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

	# Paths (horizontal roads, source 1)
	for x in range(14, 20):
		for y in range(9, 18):
			tm.set_cell(0, Vector2i(x, y), 1, Vector2i(0, 0))
	for x in range(3, 17):
		for y in range(11, 13):
			tm.set_cell(0, Vector2i(x, y), 1, Vector2i(0, 0))
	for x in range(20, 30):
		for y in range(11, 13):
			tm.set_cell(0, Vector2i(x, y), 1, Vector2i(0, 0))

	# Tilled soil (farm plots, source 2)
	for x in range(6, 13):
		for y in range(16, 21):
			tm.set_cell(0, Vector2i(x, y), 2, Vector2i(0, 0))
	for x in range(20, 27):
		for y in range(16, 21):
			tm.set_cell(0, Vector2i(x, y), 2, Vector2i(0, 0))
