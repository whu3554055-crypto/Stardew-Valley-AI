extends RefCounted

## F1：`terrain_atlas_32` / `playground_tileset.tres` 坐标与 `game_tilemap.gd` TileType 一致（单行 atlas，y=0）。
## 使用方：`const WorldTileBackdrop := preload("res://scripts/world/world_tile_backdrop.gd")` 后调用静态方法。

const GRID_W := 32
const GRID_H := 23


static func hide_polygon_ground(root: Node) -> void:
	var g: CanvasItem = root.get_node_or_null("Ground") as CanvasItem
	if g:
		g.visible = false


static func fill_uniform(layer: TileMapLayer, atlas: Vector2i, source_id: int = 0) -> void:
	if layer == null or layer.tile_set == null:
		return
	for x in range(GRID_W):
		for y in range(GRID_H):
			layer.set_cell(Vector2i(x, y), source_id, atlas)


static func paint_beach(layer: TileMapLayer, source_id: int = 0) -> void:
	if layer == null or layer.tile_set == null:
		return
	var dry := Vector2i(0, 0)
	var wet := Vector2i(1, 0)
	for x in range(GRID_W):
		for y in range(GRID_H):
			layer.set_cell(Vector2i(x, y), source_id, wet if y >= 12 else dry)


static func paint_forest(layer: TileMapLayer, source_id: int = 0) -> void:
	fill_uniform(layer, Vector2i(0, 0), source_id)
	var deco := Vector2i(2, 0)
	layer.set_cell(Vector2i(10, 8), source_id, deco)
	layer.set_cell(Vector2i(22, 14), source_id, deco)
	layer.set_cell(Vector2i(18, 19), source_id, deco)


static func paint_town(layer: TileMapLayer, source_id: int = 0) -> void:
	fill_uniform(layer, Vector2i(1, 0), source_id)
	var cob := Vector2i(7, 0)
	for y in range(10, 14):
		for x in range(5, 27):
			layer.set_cell(Vector2i(x, y), source_id, cob)


static func paint_mine_cavern(layer: TileMapLayer, source_id: int = 0) -> void:
	fill_uniform(layer, Vector2i(4, 0), source_id)
	var wood := Vector2i(5, 0)
	for x in range(7, 25):
		layer.set_cell(Vector2i(x, GRID_H - 1), source_id, wood)


static func paint_deep_cave(layer: TileMapLayer, source_id: int = 0) -> void:
	fill_uniform(layer, Vector2i(3, 0), source_id)
	var rubble := Vector2i(1, 0)
	for i in range(10):
		layer.set_cell(Vector2i(4 + (i * 3) % 24, 6 + (i % 5)), source_id, rubble)
	var wood := Vector2i(5, 0)
	for x in range(5, 27):
		layer.set_cell(Vector2i(x, GRID_H - 1), source_id, wood)
