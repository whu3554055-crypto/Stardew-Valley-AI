extends Node2D

## B6 + G2: mine shell — shared `MineCombatController` combat + pickaxe / fish / axe gather.
## Same script drives `world_cave.tscn` via exports (`use_deep_cave_tiles`, combat tuning).

const MineCombatControllerT := preload("res://scripts/combat/mine_combat_controller.gd")
const WorldRegionBanner := preload("res://scripts/world/world_region_banner.gd")
const WorldTileBackdrop := preload("res://scripts/world/world_tile_backdrop.gd")

const WORLD_EVENT_FEED_MAX := 6

@export var banner_title: String = "矿口"
@export var mine_bounds_rect: Rect2 = Rect2(140, 80, 744, 560)
@export var defeat_respawn: Vector2 = Vector2(512, 360)
@export var use_deep_cave_tiles: bool = false
@export var combat_fixed_depth: int = -1
@export var combat_spawn_interval_scale: float = 1.0
@export var combat_journal_zone: String = "Mine"
@export var combat_elite_journal_line: String = "An elite foe appears in the mine!"
@export var defeat_message_charged: String = "You blacked out and woke at the mine mouth. Lost 60g."
@export var defeat_message_insured: String = "You blacked out at the mine. Daily rescue covered the gold loss."

@onready var _player: CharacterBody2D = $Player as CharacterBody2D
@onready var _hud_msg: Label = get_node_or_null("RegionHud/RegionMessage") as Label

var _msg_timer: Timer
var _mine_combat: MineCombatControllerT = null


func _ready() -> void:
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.timeout.connect(_on_msg_timeout)
	add_child(_msg_timer)

	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()

	if MiningSystem:
		MiningSystem.set_mine_bounds_override(mine_bounds_rect)

	var tile_ground: TileMapLayer = get_node_or_null("TileLayers/LayerGround") as TileMapLayer
	if tile_ground:
		if use_deep_cave_tiles:
			WorldTileBackdrop.paint_deep_cave(tile_ground, 0)
		else:
			WorldTileBackdrop.paint_mine_cavern(tile_ground, 0)
		WorldTileBackdrop.hide_polygon_ground(self)

	if not banner_title.is_empty():
		var b: CanvasLayer = WorldRegionBanner.new()
		b.title_text = banner_title
		add_child(b)

	if GameManager and GameManager.has_signal("day_changed") and not GameManager.day_changed.is_connected(_on_game_day_changed_mine):
		GameManager.day_changed.connect(_on_game_day_changed_mine)

	_mine_combat = MineCombatControllerT.new()
	_mine_combat.name = "MineCombatController"
	_mine_combat.defeat_respawn = defeat_respawn
	_mine_combat.defeat_message_charged = defeat_message_charged
	_mine_combat.defeat_message_insured = defeat_message_insured
	_mine_combat.fixed_combat_depth = combat_fixed_depth
	_mine_combat.spawn_interval_scale = combat_spawn_interval_scale
	_mine_combat.journal_zone_name = combat_journal_zone
	_mine_combat.elite_spawn_journal_line = combat_elite_journal_line
	add_child(_mine_combat)
	_mine_combat.feedback_tip.connect(_show_message)
	_mine_combat.feedback_dialog.connect(_on_defeat_dialog)
	_mine_combat.feedback_journal.connect(_mine_journal_event)
	_mine_combat.feedback_shake.connect(_play_screen_shake)
	_mine_combat.feedback_ui_refresh.connect(_mine_ui_refresh)
	_mine_combat.bind_player(_player)

	if _player:
		if _player.has_signal("interacted"):
			_player.interacted.connect(_on_player_interacted)


func _on_game_day_changed_mine() -> void:
	if _mine_combat:
		_mine_combat.on_game_day_advanced()


func _on_defeat_dialog(text: String) -> void:
	_show_message(text, 4.8)


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


func _mine_journal_event(event_text: String) -> void:
	if not GameManager:
		return
	var timestamp: String = str(GameManager.get_time_string()) if GameManager.has_method("get_time_string") else ""
	var line: String = "[%s] %s" % [timestamp if not timestamp.is_empty() else "--:--", event_text]
	GameManager.journal_world_event_feed.push_front(line)
	if GameManager.journal_world_event_feed.size() > WORLD_EVENT_FEED_MAX:
		GameManager.journal_world_event_feed.resize(WORLD_EVENT_FEED_MAX)


func _mine_ui_refresh() -> void:
	pass


func _play_screen_shake(strength_px: float = 5.5) -> void:
	if _player == null:
		return
	var cam: Camera2D = _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var s: float = strength_px
	if ImmersionConfig:
		s = ImmersionConfig.get_float("visual.screen_shake.strength_px", strength_px)
	cam.offset = Vector2.ZERO
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	var shake: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * s
	tw.tween_property(cam, "offset", shake, 0.07)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.16)


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
