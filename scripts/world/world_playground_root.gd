extends Node2D

## Applies `WorldRouter.pending_spawn_id` after `Main` hands off via `change_scene_to_file`.

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")


func _ready() -> void:
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	_paint_tile_pilot()
	var banner: CanvasLayer = WorldRegionBanner.new()
	banner.title_text = "试验田 · Playground"
	add_child(banner)


func _paint_tile_pilot() -> void:
	var ground: TileMapLayer = get_node_or_null("TileLayers/LayerGround") as TileMapLayer
	var deco: TileMapLayer = get_node_or_null("TileLayers/LayerDeco") as TileMapLayer
	if ground and ground.tile_set:
		var src := 0
		var atlas := Vector2i(0, 0)
		for x in range(0, 32):
			for y in range(0, 23):
				ground.set_cell(Vector2i(x, y), src, atlas)
	if deco and deco.tile_set:
		deco.set_cell(Vector2i(8, 6), 0, Vector2i(1, 0))
		deco.set_cell(Vector2i(24, 14), 0, Vector2i(1, 0))
		deco.set_cell(Vector2i(16, 18), 0, Vector2i(2, 0))
