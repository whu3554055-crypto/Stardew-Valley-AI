extends Node2D

## B2: farm field scene root — TileMap + FarmManager + player; hub is `main.tscn`.

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")
const PerfOverlay := preload("res://scripts/world/perf_overlay.gd")

@onready var _player: CharacterBody2D = $Player as CharacterBody2D
@onready var _tilemap: TileMap = $TileMap as TileMap
@onready var _tilemap_deco: TileMap = get_node_or_null("TileMapDeco") as TileMap
@onready var _tilemap_occlusion: TileMap = get_node_or_null("TileMapOcclusion") as TileMap
@onready var _farm_manager: FarmManager = $FarmManager as FarmManager
@onready var _farm_message: Label = get_node_or_null("FarmHud/FarmMessage") as Label
@onready var _farmhouse_sprite: Sprite2D = get_node_or_null("FarmBackdrop/FarmhouseSprite") as Sprite2D

var _farm_msg_timer: Timer
var _perf_overlay: CanvasLayer
var _region_banner: CanvasLayer
var _screenshot_mode_enabled: bool = false

const _GRASS_ATLAS := Vector2i(0, 0)
const _PATH_ATLAS_VARIANTS := [Vector2i(1, 0)]
const _TILLED_ATLAS_VARIANTS := [Vector2i(2, 0)]


func _ready() -> void:
	_farm_msg_timer = Timer.new()
	_farm_msg_timer.one_shot = true
	_farm_msg_timer.timeout.connect(_on_farm_message_timeout)
	add_child(_farm_msg_timer)

	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	if FarmStateCache and _farm_manager:
		FarmStateCache.push_to_manager(_farm_manager)
	if QuestSystem and _farm_manager:
		if not _farm_manager.crop_planted.is_connected(_on_crop_planted):
			_farm_manager.crop_planted.connect(_on_crop_planted)
		if not _farm_manager.crop_harvested.is_connected(_on_crop_harvested):
			_farm_manager.crop_harvested.connect(_on_crop_harvested)
	if _player:
		_player.interacted.connect(_on_player_interact)
	_paint_farm_deco_tiles()
	_apply_farm_palette_profile()
	_apply_farmhouse_texture()
	_region_banner = WorldRegionBanner.new()
	_region_banner.title_text = "农场"
	add_child(_region_banner)
	if OS.is_debug_build():
		_perf_overlay = PerfOverlay.new()
		add_child(_perf_overlay)
	# Startup value can be controlled by env var for capture automation.
	if str(OS.get_environment("SV_CAPTURE_MODE")).to_lower() in ["1", "true", "yes", "on"]:
		_apply_screenshot_mode(true)


func _exit_tree() -> void:
	if FarmStateCache and _farm_manager:
		FarmStateCache.sync_from_manager(_farm_manager)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_apply_screenshot_mode(not _screenshot_mode_enabled)
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if FarmStateCache and _farm_manager:
		FarmStateCache.sync_from_manager(_farm_manager)
	if GameSaveService:
		GameSaveService.commit_save(
			GameSaveService.build_runtime_bundle(
				FarmStateCache.get_snapshot(),
				GameManager.journal_world_event_feed,
				GameManager.journal_active_story_hotspot
			)
		)


func _farm_show_message(text: String, seconds: float = 3.0) -> void:
	if _farm_message:
		_farm_message.text = text
		_farm_message.visible = true
	_farm_msg_timer.stop()
	_farm_msg_timer.start(seconds)


func _on_farm_message_timeout() -> void:
	if _farm_message:
		_farm_message.visible = false


func _paint_farm_deco_tiles() -> void:
	if _tilemap == null or _tilemap_deco == null:
		return
	_paint_farm_base_tiles()
	_tilemap_deco.tile_set = _tilemap.tile_set
	if _tilemap_occlusion:
		_tilemap_occlusion.tile_set = _tilemap.tile_set
	if _tilemap_deco.tile_set == null:
		return
	# Keep deco layer neutral until dedicated farm props atlas is imported.
	_tilemap_deco.clear()
	if _tilemap_occlusion:
		_tilemap_occlusion.clear()


func _paint_farm_base_tiles() -> void:
	if _tilemap == null:
		return
	for x in range(32):
		for y in range(23):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _GRASS_ATLAS)
	for x in range(14, 20):
		for y in range(9, 18):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _pick_atlas_variant(_PATH_ATLAS_VARIANTS, x, y))
	for x in range(3, 17):
		for y in range(11, 13):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _pick_atlas_variant(_PATH_ATLAS_VARIANTS, x, y))
	for x in range(20, 30):
		for y in range(11, 13):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _pick_atlas_variant(_PATH_ATLAS_VARIANTS, x, y))
	for x in range(6, 13):
		for y in range(16, 21):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _pick_atlas_variant(_TILLED_ATLAS_VARIANTS, x, y))
	for x in range(20, 27):
		for y in range(16, 21):
			_tilemap.set_cell(0, Vector2i(x, y), 0, _pick_atlas_variant(_TILLED_ATLAS_VARIANTS, x, y))


func _pick_atlas_variant(variants: Array, x: int, y: int) -> Vector2i:
	if variants.is_empty():
		return Vector2i.ZERO
	var idx: int = int(abs(hash(Vector3i(x, y, 97)))) % variants.size()
	return variants[idx] as Vector2i


func _apply_farm_palette_profile() -> void:
	var hint: Label = get_node_or_null("Hint") as Label
	if hint:
		hint.add_theme_color_override("font_color", Color(0.84, 0.93, 0.82, 0.95))
		hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))


func _set_farmhouse_fallback_visible(visible_value: bool) -> void:
	for node_name in [
		"FarmBackdrop/FarmhouseWalls",
		"FarmBackdrop/FarmhouseRoof",
		"FarmBackdrop/FarmhouseDoor",
		"FarmBackdrop/FarmhouseWindowL",
		"FarmBackdrop/FarmhouseWindowR",
		"FarmBackdrop/FarmhouseRoofTrim",
		"FarmBackdrop/FarmhouseChimney",
		"FarmBackdrop/FarmhouseShadow"
	]:
		var ci: CanvasItem = get_node_or_null(node_name) as CanvasItem
		if ci:
			ci.visible = visible_value


func _apply_farmhouse_texture() -> void:
	if _farmhouse_sprite == null:
		return
	# Keep farmhouse in top-down fallback style to avoid projection mismatch
	# with the current farm ground tiles.
	_farmhouse_sprite.visible = false
	_set_farmhouse_fallback_visible(true)


func _apply_screenshot_mode(enabled: bool) -> void:
	_screenshot_mode_enabled = enabled
	var hint: CanvasItem = get_node_or_null("Hint") as CanvasItem
	if hint:
		hint.visible = not enabled
	var portal_main_label: CanvasItem = get_node_or_null("PortalToMain/PortalLabel") as CanvasItem
	if portal_main_label:
		portal_main_label.visible = not enabled
	var portal_town_label: CanvasItem = get_node_or_null("PortalToTown/PortalLabel") as CanvasItem
	if portal_town_label:
		portal_town_label.visible = not enabled
	if _farm_message:
		_farm_message.visible = false if enabled else _farm_message.visible
	if _perf_overlay:
		_perf_overlay.visible = not enabled
	if _region_banner:
		_region_banner.visible = not enabled


func _try_harvest(tile_coords: Vector2i) -> bool:
	if not _farm_manager:
		return false
	var h: Dictionary = _farm_manager.harvest_crop(tile_coords)
	if h.is_empty() or not h.has("product"):
		return false
	var product_id: String = str(h.get("product", ""))
	if product_id.is_empty():
		return false
	var count: int = int(h.get("count", 1))
	var template: Dictionary = ItemDatabase.get_item(product_id)
	if template.is_empty():
		_farm_show_message("Harvest failed (unknown crop).")
		return true
	for i in range(count):
		if not InventoryManager.add_item(template.duplicate(true)):
			_farm_show_message("Inventory full.")
			return true
	var pnm: String = str(template.get("name", product_id))
	_farm_show_message("Harvested: %s ×%d" % [pnm, count])
	return true


func _try_eat_selected_food() -> bool:
	var slot: int = InventoryManager.selected_slot
	var item = InventoryManager.get_item(slot)
	if item == null or float(item.get("stamina_restore", 0.0)) <= 0.0:
		return false
	var amt: float = float(item.get("stamina_restore", 0.0))
	var item_id: String = str(item.get("id", ""))
	if GameManager:
		GameManager.restore_stamina(amt)
	InventoryManager.remove_item(slot, 1)
	if QuestSystem:
		QuestSystem.track_event("consume_food", {"item_id": item_id, "count": 1})
	_farm_show_message("+%d energy" % int(ceil(amt)), 1.35)
	return true


func _on_player_interact(tile_position: Vector2) -> void:
	if _tilemap == null or _farm_manager == null:
		return
	var tile_coords: Vector2i = _tilemap.local_to_map(tile_position)
	var selected_item = InventoryManager.get_selected_item()

	if selected_item == null and _try_harvest(tile_coords):
		return

	if selected_item and str(selected_item.get("id", "")) in ["pickaxe", "pickaxe_iron"]:
		if _farm_manager.has_sprinkler_at(tile_coords):
			var tpl_pick: Dictionary = ItemDatabase.get_item("sprinkler_basic")
			if not tpl_pick.is_empty() and InventoryManager.can_add_quantity(tpl_pick, 1):
				if _farm_manager.remove_sprinkler(tile_coords):
					InventoryManager.add_item(tpl_pick.duplicate(true))
					if GatheringSfx:
						GatheringSfx.play_mine_swing()
					_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_pickup_success"), 1.35)
					return
			_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_pickup_inventory_full"), 1.6)
			return

	if selected_item and str(selected_item.get("id", "")) == "sprinkler_basic":
		if GameManager:
			var sc: float = float(GameManager.player_data.get("stamina", 0.0))
			if sc < 5.0:
				_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_no_stamina"), 1.4)
				return
		var sp_res: Dictionary = _farm_manager.try_place_sprinkler(tile_coords)
		if sp_res.get("ok", false):
			if GameManager:
				GameManager.try_consume_stamina(5.0)
			InventoryManager.remove_item(InventoryManager.selected_slot, 1)
			if GatheringSfx:
				GatheringSfx.play_water()
			_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_success"), 1.35)
			return
		match str(sp_res.get("reason", "")):
			"not_tilled":
				_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_not_tilled"), 1.4)
			"has_crop":
				_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_has_crop"), 1.4)
			"has_sprinkler":
				_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_has_sprinkler"), 1.4)
			_:
				_farm_show_message(UITextCatalog.get_text("quick_tip", "sprinkler_place_failed"), 1.4)
		return

	if selected_item and str(selected_item.get("type", "")) == "fertilizer":
		if _farm_manager.can_fertilize_here(tile_coords):
			var fert_res: Dictionary = _farm_manager.try_apply_fertilizer(tile_coords)
			if fert_res.get("ok", false):
				InventoryManager.remove_item(InventoryManager.selected_slot, 1)
				_farm_show_message(UITextCatalog.get_text("quick_tip", "fertilizer_apply_success"), 1.35)
				return
			if str(fert_res.get("reason", "")) == "already_fertilized":
				_farm_show_message(UITextCatalog.get_text("quick_tip", "fertilizer_apply_already"), 1.4)
				return
		elif _farm_manager.is_tile_tilled(tile_coords):
			_farm_show_message(UITextCatalog.get_text("quick_tip", "fertilizer_apply_needs_empty_tilled"), 1.4)
		else:
			_farm_show_message(UITextCatalog.get_text("quick_tip", "fertilizer_apply_needs_tilled"), 1.4)
		return

	if selected_item and _try_eat_selected_food():
		return

	if selected_item:
		if selected_item.type == "seed":
			if _farm_manager.can_plant_here(tile_coords):
				var crop_id: String = str(selected_item.get("crop_id", ""))
				if crop_id.is_empty():
					return
				var plant_res: Dictionary = _farm_manager.plant_seed(tile_coords, crop_id)
				if plant_res.get("ok", false):
					InventoryManager.remove_item(InventoryManager.selected_slot)
				else:
					match str(plant_res.get("reason", "")):
						"wrong_season":
							_farm_show_message(UITextCatalog.get_text("quick_tip", "plant_wrong_season"), 1.4)
						_:
							pass
		elif selected_item.id == "hoe":
			_farm_manager.till_soil(tile_coords)
		elif selected_item.id == "watering_can":
			_farm_manager.water_plant(tile_coords)
			if GatheringSfx:
				GatheringSfx.play_water()


func _on_crop_planted(_position, crop_id: String) -> void:
	if QuestSystem:
		QuestSystem.track_event("plant", {"crop_id": crop_id, "count": 1})


func _on_crop_harvested(_position, crop_id: String, quantity: int) -> void:
	if QuestSystem:
		QuestSystem.track_event("harvest", {"crop_id": crop_id, "count": quantity})
