extends Node2D

## B3: town shell — Pierre + shop (B key), portals, Esc save.

const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")

const SHOP_PROXIMITY: float = 112.0

@onready var _player: CharacterBody2D = $Player as CharacterBody2D
@onready var _shop_ui: ShopUI = get_node_or_null("TownHud/ShopUI") as ShopUI
@onready var _hud_msg: Label = get_node_or_null("TownHud/TownMessage") as Label

var _msg_timer: Timer


func _ready() -> void:
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.timeout.connect(_on_msg_timeout)
	add_child(_msg_timer)

	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()

	var banner: CanvasLayer = WorldRegionBanner.new()
	banner.title_text = "鹈鹕镇"
	add_child(banner)

	if _shop_ui:
		if not _shop_ui.purchase_confirmed.is_connected(_on_shop_purchase):
			_shop_ui.purchase_confirmed.connect(_on_shop_purchase)

	if _player and _player.has_signal("interacted"):
		_player.interacted.connect(_on_player_interacted)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_shop"):
		_try_toggle_shop()
		return
	if event.is_action_pressed("ui_cancel"):
		if GameSaveService and GameManager:
			GameSaveService.commit_save(
				GameSaveService.build_runtime_bundle(
					FarmStateCache.get_snapshot() if FarmStateCache else {},
					GameManager.journal_world_event_feed,
					GameManager.journal_active_story_hotspot
				)
			)


func _nearest_villager_npc() -> NPC:
	var best: NPC = null
	var best_d: float = 88.0
	if _player == null:
		return null
	for n in get_tree().get_nodes_in_group("npc_villager"):
		if not (n is NPC):
			continue
		var npc: NPC = n as NPC
		var d: float = npc.global_position.distance_to(_player.global_position)
		if d < best_d:
			best_d = d
			best = npc
	return best


func _player_near_pierre_shop() -> bool:
	if _player == null:
		return false
	for n in get_tree().get_nodes_in_group("npc_villager"):
		if not (n is NPC):
			continue
		var npc: NPC = n as NPC
		if npc.npc_id == "pierre":
			return npc.global_position.distance_to(_player.global_position) <= SHOP_PROXIMITY
	return false


func _try_toggle_shop() -> void:
	if _shop_ui == null:
		return
	if _shop_ui.visible:
		_shop_ui.close_shop()
		return
	if not _player_near_pierre_shop():
		_show_message(UITextCatalog.get_text("quick_tip", "shop_open_near_pierre") if UITextCatalog else "Stand near Pierre to shop.", 2.0)
		return
	_shop_ui.open_shop()
	if GatheringSfx:
		GatheringSfx.play_shop_enter()


func _show_message(text: String, seconds: float = 3.0) -> void:
	if _hud_msg:
		_hud_msg.text = text
		_hud_msg.visible = true
	_msg_timer.stop()
	_msg_timer.start(seconds)


func _on_msg_timeout() -> void:
	if _hud_msg:
		_hud_msg.visible = false


func _on_shop_purchase(item_id: String, quantity: int) -> void:
	if not ShopSystem:
		return
	if ShopSystem.purchase_item(item_id, quantity):
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		var nm: String = str(tpl.get("name", item_id)) if not tpl.is_empty() else item_id
		_show_message(UITextCatalog.format_text("quick_tip", "shop_bought_item", {"item": nm}) if UITextCatalog else "Bought: %s" % nm, 2.2)
		if AIEconomySystem:
			var market_note: String = AIEconomySystem.get_market_brief(item_id)
			if not market_note.is_empty() and GameManager:
				GameManager.journal_world_event_feed.append("Market: %s" % market_note)
		if _shop_ui:
			_shop_ui.populate_shop_items()
			_shop_ui.update_gold_display()
	else:
		_show_message(UITextCatalog.get_text("quick_tip", "shop_purchase_failed") if UITextCatalog else "Purchase failed.", 1.8)


func _on_player_interacted(_tile_position: Vector2) -> void:
	var npc: NPC = _nearest_villager_npc()
	if npc == null:
		return
	var dialogue: String = npc.interact()
	if not dialogue.is_empty() and dialogue != "...":
		_show_message("%s: %s" % [npc.npc_name, dialogue], 4.0)
	if QuestSystem:
		QuestSystem.track_event("talk", {"npc_id": npc.npc_id, "count": 1})
	if AIQuestSystem:
		AIQuestSystem.track_event("talk", {"npc_id": npc.npc_id, "count": 1})
