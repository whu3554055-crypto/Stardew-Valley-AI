extends SceneTree

## One-shot: generates `res://assets/tiles/playground_tileset.tres` for world_playground TileMapLayer pilot.
## Run: Godot --headless --path <repo> -s res://tools/gen_playground_tileset.gd


func _init() -> void:
	var ts := TileSet.new()
	var tex: Texture2D = load("res://assets/tiles/terrain_atlas_32.png") as Texture2D
	if tex == null:
		push_error("gen_playground_tileset: missing terrain_atlas_32.png")
		quit(1)
		return
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	var sid: int = ts.add_source(src)
	if sid < 0:
		push_error("gen_playground_tileset: add_source failed")
		quit(1)
		return
	var err: Error = ResourceSaver.save(ts, "res://assets/tiles/playground_tileset.tres")
	if err != OK:
		push_error("gen_playground_tileset: save failed %s" % str(err))
		quit(1)
		return
	print("gen_playground_tileset: wrote playground_tileset.tres")
	quit(0)
