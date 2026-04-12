extends Node2D

## B4/B5/B6 thin shell: one scene script with region override + gather interactions (E).

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")
const WorldTileBackdrop := preload("res://scripts/world/world_tile_backdrop.gd")

enum Kind { FOREST, BEACH, MINE }

@export var region_kind: Kind = Kind.FOREST
@export var banner_title: String = "户外区域"

@export var forest_chop_rect: Rect2 = Rect2(160, 100, 704, 520)
@export var beach_ocean_rect: Rect2 = Rect2(0, 380, 1024, 340)
@export var mine_bounds_rect: Rect2 = Rect2(140, 80, 744, 560)

@onready var _player: CharacterBody2D = $Player as CharacterBody2D
@onready var _hud_msg: Label = get_node_or_null("RegionHud/RegionMessage") as Label

var _msg_timer: Timer


func _ready() -> void:
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.timeout.connect(_on_msg_timeout)
	add_child(_msg_timer)

	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()

	_apply_region_override()
	_paint_world_tile_pilot()

	if not banner_title.is_empty():
		var b: CanvasLayer = WorldRegionBanner.new()
		b.title_text = banner_title
		add_child(b)

	if _player and _player.has_signal("interacted"):
		_player.interacted.connect(_on_player_interacted)


func _apply_region_override() -> void:
	match region_kind:
		Kind.FOREST:
			if ChoppingSystem:
				ChoppingSystem.set_forest_bounds_override(forest_chop_rect)
		Kind.BEACH:
			if FishingSystem:
				FishingSystem.set_ocean_bounds_override(beach_ocean_rect)
		Kind.MINE:
			if MiningSystem:
				MiningSystem.set_mine_bounds_override(mine_bounds_rect)


## F1 试点：`world_beach` 铺沙、`world_forest` 铺草（与 playground 同源 TileSet），隐藏纯色 Ground。
func _paint_world_tile_pilot() -> void:
	var layer: TileMapLayer = get_node_or_null("TileLayers/LayerGround") as TileMapLayer
	if layer == null or layer.tile_set == null:
		return
	match region_kind:
		Kind.BEACH:
			WorldTileBackdrop.paint_beach(layer, 0)
			WorldTileBackdrop.hide_polygon_ground(self)
		Kind.FOREST:
			WorldTileBackdrop.paint_forest(layer, 0)
			WorldTileBackdrop.hide_polygon_ground(self)
		_:
			pass


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if GameSaveService and GameManager:
		GameSaveService.commit_save(
			GameSaveService.build_runtime_bundle(
				FarmStateCache.get_snapshot() if FarmStateCache else {},
				GameManager.journal_world_event_feed,
				GameManager.journal_active_story_hotspot
			)
		)


func _show_message(text: String, seconds: float = 3.2) -> void:
	if _hud_msg:
		_hud_msg.text = text
		_hud_msg.visible = true
	_msg_timer.stop()
	_msg_timer.start(seconds)


func _on_msg_timeout() -> void:
	if _hud_msg:
		_hud_msg.visible = false


func _on_player_interacted(_tile_position: Vector2) -> void:
	if _player == null:
		return
	var selected_item = InventoryManager.get_selected_item()

	if selected_item and str(selected_item.get("id", "")) == "fishing_rod" and FishingSystem:
		if FishingSystem.can_fish_here(_player.global_position):
			var catch_result: Dictionary = FishingSystem.handle_fish_input(_player.global_position)
			if str(catch_result.get("phase", "")) == "hook_prompt":
				_show_message(str(catch_result.get("message", "Press E!")), 2.0)
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(0.85)
				return
			var fish_msg: String = str(catch_result.get("message", ""))
			if catch_result.get("ok", false):
				_show_message(fish_msg, 3.8)
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.15)
				return
			if not fish_msg.is_empty():
				_show_message(fish_msg, 2.8)
				return

	if selected_item and str(selected_item.get("id", "")) in ["pickaxe", "pickaxe_iron"] and MiningSystem:
		if MiningSystem.can_mine_here(_player.global_position):
			var mine_result: Dictionary = MiningSystem.try_swing(
				_player.global_position,
				str(selected_item.get("id", ""))
			)
			var mine_msg: String = str(mine_result.get("message", ""))
			if mine_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				_show_message(mine_msg, 3.8)
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.0)
				var mine_hint: String = str(mine_result.get("hint", ""))
				if not mine_hint.is_empty():
					_show_message(mine_hint, 2.2)
				return
			if not mine_msg.is_empty():
				_show_message(mine_msg, 2.6)
				return

	if selected_item and str(selected_item.get("id", "")) == "axe" and ChoppingSystem:
		if ChoppingSystem.can_chop_here(_player.global_position):
			var chop_result: Dictionary = ChoppingSystem.try_chop_one()
			var ch_msg: String = str(chop_result.get("message", ""))
			if chop_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				_show_message(ch_msg, 3.5)
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.0)
				return
			if not ch_msg.is_empty():
				_show_message(ch_msg, 2.4)
				return
