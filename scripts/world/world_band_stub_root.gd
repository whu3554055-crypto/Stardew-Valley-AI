extends Node2D

## Minimal multi-scene band stub: spawn apply + optional region banner (no TileMap migration).

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")

@export var banner_title: String = "Region (stub)"


func _ready() -> void:
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	if not banner_title.is_empty():
		var banner: CanvasLayer = WorldRegionBanner.new()
		banner.title_text = banner_title
		add_child(banner)
