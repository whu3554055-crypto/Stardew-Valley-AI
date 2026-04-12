extends Node2D

## Applies `WorldRouter.pending_spawn_id` after `Main` hands off via `change_scene_to_file`.

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")


func _ready() -> void:
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	var banner: CanvasLayer = WorldRegionBanner.new()
	banner.title_text = "试验田 · Playground"
	add_child(banner)
