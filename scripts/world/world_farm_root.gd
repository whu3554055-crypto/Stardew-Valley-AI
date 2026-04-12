extends Node2D

## B2: farm field scene root — TileMap + FarmManager + player; hub is `main.tscn`.

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")

@onready var _player: CharacterBody2D = $Player as CharacterBody2D
@onready var _tilemap: TileMap = $TileMap as TileMap
@onready var _farm_manager: FarmManager = $FarmManager as FarmManager
@onready var _farm_message: Label = get_node_or_null("FarmHud/FarmMessage") as Label

var _farm_msg_timer: Timer


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
	var banner: CanvasLayer = WorldRegionBanner.new()
	banner.title_text = "农场"
	add_child(banner)


func _exit_tree() -> void:
	if FarmStateCache and _farm_manager:
		FarmStateCache.sync_from_manager(_farm_manager)


func _unhandled_input(event: InputEvent) -> void:
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
