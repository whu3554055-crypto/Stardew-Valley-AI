extends Node2D

@onready var player = $Player
@onready var tilemap = $TileMap
@onready var farm_manager = $FarmManager
@onready var ui_layer = $UILayer
@onready var time_label = $UILayer/TimeLabel
@onready var gold_label = $UILayer/GoldLabel
@onready var dialogue_box = $UILayer/DialogueBox
@onready var dialogue_label = $UILayer/DialogueBox/Label
@onready var weather_label = $UILayer/WeatherLabel
@onready var season_label = $UILayer/SeasonLabel
@onready var day_label = $UILayer/DayLabel
@onready var stamina_label = $UILayer/StaminaLabel
@onready var ai_config_button = $UILayer/AIConfigButton
@onready var world_event_feed_label = $UILayer/WorldEventFeed/Content
@onready var quick_tip_label = $UILayer/QuickTipLabel
@onready var quick_tip_timer = $UILayer/QuickTipTimer
@onready var activity_zone_label = $UILayer/ActivityZoneLabel
@onready var fx_fish = $FXLayer/FishSplash
@onready var fx_mine = $FXLayer/MineSpark
@onready var almanac_panel = $UILayer/AlmanacPanel
@onready var recipe_picker = $UILayer/RecipePicker
@onready var shop_ui = $UILayer/ShopUI
@onready var quest_log_label = $UILayer/QuestLogLabel

var current_npc = null
var ai_config_scene = preload("res://scenes/ai_config_ui.tscn")
var ai_config_instance = null
var world_event_feed: Array[String] = []
var managed_chain_status_banner: String = ""
var active_story_hotspot: Dictionary = {}
var daily_event_budget: Dictionary = {"narrative": 1, "chain_activation": 1, "recovery_hint": 1}
const WORLD_EVENT_FEED_MAX := 6
const GAME_SAVE_BUNDLE_PATH := "user://game_save.bundle"
const SAVE_BUNDLE_VERSION := 3
const PIERRE_SHOP_RADIUS_PX := 140.0
const BASE_STAMINA_MAX := 100.0

func _ready():
	# Connect signals
	player.interacted.connect(_on_player_interact)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.season_changed.connect(_on_season_changed)
	
	# Connect farming signals for quest tracking
	farm_manager.crop_planted.connect(_on_crop_planted)
	farm_manager.crop_harvested.connect(_on_crop_harvested)
	
	# Single save file: `game_save.bundle` (see `save_game` / `_build_save_bundle`)
	var had_savegame: bool = _try_load_save_bundle()
	_refresh_world_event_feed_ui()
	if not had_savegame:
		give_starter_items()
		_ensure_house_level_default()
	if QuestSystem:
		QuestSystem.quest_started.connect(_on_quest_log_changed)
		QuestSystem.quest_updated.connect(_on_quest_log_changed)
		QuestSystem.quest_completed.connect(_on_quest_completed)
		if QuestSystem.has_signal("quest_failed"):
			QuestSystem.quest_failed.connect(_on_quest_failed)
		if QuestSystem.has_signal("quest_impact_applied"):
			QuestSystem.quest_impact_applied.connect(_on_quest_impact_applied)
		if QuestSystem.has_signal("managed_chain_resolved"):
			QuestSystem.managed_chain_resolved.connect(_on_managed_chain_resolved)
	if DailyNarrativeSystem:
		DailyNarrativeSystem.narrative_generated.connect(_on_daily_narrative_generated)
		if DailyNarrativeSystem.has_signal("backend_generation_fallback"):
			DailyNarrativeSystem.backend_generation_fallback.connect(_on_narrative_backend_fallback)
	if AIQuestSystem:
		AIQuestSystem.ai_quest_request_failed.connect(_on_ai_quest_generation_failed)
	if AgenticContentOrchestrator:
		AgenticContentOrchestrator.generation_started.connect(_on_agentic_chain_generation_started)
		AgenticContentOrchestrator.generation_published.connect(_on_agentic_chain_generation_published)
		AgenticContentOrchestrator.generation_failed.connect(_on_agentic_chain_generation_failed)
		AgenticContentOrchestrator.generation_degraded.connect(_on_agentic_chain_generation_degraded)
		if AgenticContentOrchestrator.has_signal("runtime_status_updated"):
			AgenticContentOrchestrator.runtime_status_updated.connect(_on_agentic_runtime_status_updated)
		if AgenticContentOrchestrator.has_signal("guardrail_blocked"):
			AgenticContentOrchestrator.guardrail_blocked.connect(_on_agentic_guardrail_blocked)
	if shop_ui:
		shop_ui.purchase_confirmed.connect(_on_shop_purchase)
	update_ui()
	initialize_playable_first_loop()
	
	# Setup AI config button
	if ai_config_button:
		ai_config_button.pressed.connect(_on_ai_config_pressed)
	if quick_tip_timer:
		quick_tip_timer.timeout.connect(_on_quick_tip_timeout)
	_apply_a3_ui_polish()
	
	print("======================================")
	print("  Stardew Valley Clone - AI Edition")
	print("======================================")
	print("AI Model: ", AIAgentManager.api_config.model if AIAgentManager else "Not loaded")
	print("NPCs with AI: Pierre, Abigail, Lewis")
	print("Press E: NPCs | harvest | kitchen/smelter/workbench (配方) | fish | mine | chop | eat | place sprinkler (tilled empty tile) | J = collection | Y = sell selected | B = shop near Pierre | U = farm tier | H = house upgrade")
	print("======================================")

func _process(_delta: float) -> void:
	_update_activity_zone_label()

func _apply_a3_ui_polish() -> void:
	## Readability + panel chrome (A3 presentation pass).
	if dialogue_box:
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color(0.06, 0.07, 0.1, 0.94)
		dsb.set_border_width_all(1)
		dsb.border_color = Color(0.42, 0.38, 0.26)
		dsb.content_margin_left = 18
		dsb.content_margin_top = 14
		dsb.content_margin_right = 18
		dsb.content_margin_bottom = 14
		dialogue_box.add_theme_stylebox_override("panel", dsb)
	if dialogue_label:
		dialogue_label.add_theme_font_size_override("font_size", 17)
		dialogue_label.add_theme_color_override("font_color", Color(0.94, 0.93, 0.88))
		dialogue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		dialogue_label.add_theme_constant_override("shadow_offset_x", 1)
		dialogue_label.add_theme_constant_override("shadow_offset_y", 1)
	var hud_labels: Array[Node] = [
		time_label, gold_label, stamina_label, day_label, season_label, weather_label
	]
	for n in hud_labels:
		if n is Label:
			var lb: Label = n as Label
			lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
			lb.add_theme_constant_override("shadow_offset_x", 1)
			lb.add_theme_constant_override("shadow_offset_y", 1)
	if quick_tip_label:
		quick_tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		quick_tip_label.add_theme_constant_override("shadow_offset_x", 1)
		quick_tip_label.add_theme_constant_override("shadow_offset_y", 1)
	if activity_zone_label:
		activity_zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		activity_zone_label.add_theme_constant_override("shadow_offset_x", 1)
		activity_zone_label.add_theme_constant_override("shadow_offset_y", 1)
	var wef: Panel = ui_layer.get_node_or_null("WorldEventFeed") as Panel
	if wef:
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.05, 0.06, 0.08, 0.88)
		wsb.set_border_width_all(1)
		wsb.border_color = Color(0.35, 0.32, 0.22)
		wsb.content_margin_left = 8
		wsb.content_margin_top = 6
		wsb.content_margin_right = 8
		wsb.content_margin_bottom = 6
		wef.add_theme_stylebox_override("panel", wsb)
	if world_event_feed_label:
		world_event_feed_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		world_event_feed_label.add_theme_constant_override("shadow_offset_x", 1)
		world_event_feed_label.add_theme_constant_override("shadow_offset_y", 1)
	var wef_title: Label = ui_layer.get_node_or_null("WorldEventFeed/Title") as Label
	if wef_title:
		wef_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		wef_title.add_theme_constant_override("shadow_offset_x", 1)
		wef_title.add_theme_constant_override("shadow_offset_y", 1)
	if ai_config_button:
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.11, 0.12, 0.16, 0.92)
		bsb.set_border_width_all(1)
		bsb.border_color = Color(0.38, 0.34, 0.24)
		ai_config_button.add_theme_stylebox_override("normal", bsb)
		ai_config_button.add_theme_stylebox_override("hover", bsb)
		ai_config_button.add_theme_stylebox_override("pressed", bsb)
		ai_config_button.flat = true
	if quest_log_label:
		quest_log_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		quest_log_label.add_theme_constant_override("shadow_offset_x", 1)
		quest_log_label.add_theme_constant_override("shadow_offset_y", 1)
	if ui_layer and ui_layer.get_node_or_null("HUDBackdrop") == null:
		var hud_bg := Panel.new()
		hud_bg.name = "HUDBackdrop"
		hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		hud_bg.offset_left = 4.0
		hud_bg.offset_top = 4.0
		hud_bg.offset_right = 428.0
		hud_bg.offset_bottom = 188.0
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(0.04, 0.05, 0.075, 0.58)
		hsb.set_border_width_all(1)
		hsb.border_color = Color(0.22, 0.24, 0.3)
		hud_bg.add_theme_stylebox_override("panel", hsb)
		ui_layer.add_child(hud_bg)
		ui_layer.move_child(hud_bg, 0)
	if ui_layer and ui_layer.get_node_or_null("QuestLogBackdrop") == null:
		var q_bg := Panel.new()
		q_bg.name = "QuestLogBackdrop"
		q_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		q_bg.offset_left = 924.0
		q_bg.offset_top = 262.0
		q_bg.offset_right = 1266.0
		q_bg.offset_bottom = 436.0
		var qsb := StyleBoxFlat.new()
		qsb.bg_color = Color(0.04, 0.06, 0.08, 0.56)
		qsb.set_border_width_all(1)
		qsb.border_color = Color(0.26, 0.34, 0.32, 0.92)
		q_bg.add_theme_stylebox_override("panel", qsb)
		ui_layer.add_child(q_bg)
		ui_layer.move_child(q_bg, 0)
	if ui_layer and ui_layer.get_node_or_null("ActivityZoneBackdrop") == null:
		var a_bg := Panel.new()
		a_bg.name = "ActivityZoneBackdrop"
		a_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		a_bg.offset_left = 8.0
		a_bg.offset_top = 194.0
		a_bg.offset_right = 270.0
		a_bg.offset_bottom = 224.0
		var asb := StyleBoxFlat.new()
		asb.bg_color = Color(0.03, 0.05, 0.075, 0.54)
		asb.set_border_width_all(1)
		asb.border_color = Color(0.22, 0.28, 0.36, 0.88)
		a_bg.add_theme_stylebox_override("panel", asb)
		ui_layer.add_child(a_bg)
		ui_layer.move_child(a_bg, 0)
	if ui_layer and quick_tip_label and ui_layer.get_node_or_null("QuickTipBackdrop") == null:
		var qtb := Panel.new()
		qtb.name = "QuickTipBackdrop"
		qtb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		qtb.visible = false
		qtb.set_anchors_preset(Control.PRESET_TOP_LEFT)
		qtb.offset_left = quick_tip_label.offset_left
		qtb.offset_top = quick_tip_label.offset_top
		qtb.offset_right = quick_tip_label.offset_right
		qtb.offset_bottom = quick_tip_label.offset_bottom
		var qtsb := StyleBoxFlat.new()
		qtsb.bg_color = Color(0.04, 0.05, 0.08, 0.62)
		qtsb.set_border_width_all(1)
		qtsb.border_color = Color(0.22, 0.24, 0.3)
		qtb.add_theme_stylebox_override("panel", qtsb)
		ui_layer.add_child(qtb)
		ui_layer.move_child(qtb, quick_tip_label.get_index())
	_style_world_zone_presentation()
	_apply_seasonal_hud_tint()


func _style_world_zone_presentation() -> void:
	# Unify in-world area hints (mine/river/ocean/workstations/upgrades) for readability.
	var hint_paths: PackedStringArray = [
		"SmelterArea/SmelterHint",
		"KitchenArea/KitchenHint",
		"WorkbenchArea/WorkbenchHint",
		"ForestArea/ForestHint",
		"MineArea/MineHint",
		"RiverZone/RiverHint",
		"OceanZone/OceanHint",
		"FarmUpgradeArea/FarmUpgradeHint",
		"HouseUpgradeArea/HouseUpgradeHint"
	]
	for p in hint_paths:
		var lb: Label = get_node_or_null(p) as Label
		if lb:
			lb.add_theme_font_size_override("font_size", 11)
			lb.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
			lb.add_theme_constant_override("shadow_offset_x", 1)
			lb.add_theme_constant_override("shadow_offset_y", 1)

	var farm_overlay: Polygon2D = get_node_or_null("FarmUpgradeArea/Overlay") as Polygon2D
	if farm_overlay:
		farm_overlay.color = Color(0.35, 0.62, 0.32, 0.26)
	var house_overlay: Polygon2D = get_node_or_null("HouseUpgradeArea/Overlay") as Polygon2D
	if house_overlay:
		house_overlay.color = Color(0.66, 0.52, 0.34, 0.24)


func _panel_set_season_border(panel: Panel, accent: Color) -> void:
	if not panel:
		return
	var sb: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not sb:
		return
	sb.border_color = accent
	panel.add_theme_stylebox_override("panel", sb)


func _button_set_season_border(btn: Button, accent: Color) -> void:
	if not btn:
		return
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBoxFlat = btn.get_theme_stylebox(state) as StyleBoxFlat
		if sb:
			sb.border_color = accent
			btn.add_theme_stylebox_override(state, sb)


func _season_hud_colors(season_name: String) -> Dictionary:
	match season_name:
		"spring":
			return {"accent": Color(0.54, 0.84, 0.62, 0.95), "text": Color(0.86, 0.95, 0.88, 1.0)}
		"summer":
			return {"accent": Color(0.56, 0.82, 0.9, 0.95), "text": Color(0.86, 0.94, 0.98, 1.0)}
		"fall":
			return {"accent": Color(0.9, 0.72, 0.48, 0.95), "text": Color(0.98, 0.92, 0.84, 1.0)}
		"winter":
			return {"accent": Color(0.7, 0.8, 0.96, 0.95), "text": Color(0.9, 0.94, 1.0, 1.0)}
		_:
			return {"accent": Color(0.72, 0.8, 0.88, 0.95), "text": Color(0.9, 0.92, 0.96, 1.0)}


func _apply_seasonal_hud_tint() -> void:
	if not ui_layer or not GameManager:
		return
	var season_name: String = str(GameManager.player_data.get("season", "spring"))
	var palette: Dictionary = _season_hud_colors(season_name)
	var accent: Color = palette.get("accent", Color(0.72, 0.8, 0.88, 0.95))
	var text_col: Color = palette.get("text", Color(0.9, 0.92, 0.96, 1.0))

	var hud_bg: Panel = ui_layer.get_node_or_null("HUDBackdrop") as Panel
	if hud_bg:
		var sb: StyleBoxFlat = hud_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = accent
			hud_bg.add_theme_stylebox_override("panel", sb)
	var q_bg: Panel = ui_layer.get_node_or_null("QuestLogBackdrop") as Panel
	if q_bg:
		var qsb: StyleBoxFlat = q_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if qsb:
			qsb.border_color = accent
			q_bg.add_theme_stylebox_override("panel", qsb)
	var a_bg: Panel = ui_layer.get_node_or_null("ActivityZoneBackdrop") as Panel
	if a_bg:
		var asb: StyleBoxFlat = a_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if asb:
			asb.border_color = accent
			a_bg.add_theme_stylebox_override("panel", asb)
	var wef_season: Panel = ui_layer.get_node_or_null("WorldEventFeed") as Panel
	if wef_season:
		var wsb2: StyleBoxFlat = wef_season.get_theme_stylebox("panel") as StyleBoxFlat
		if wsb2:
			wsb2.border_color = accent
			wef_season.add_theme_stylebox_override("panel", wsb2)
	_panel_set_season_border(dialogue_box, accent)
	var inv_panel: Panel = ui_layer.get_node_or_null("InventoryUI") as Panel
	_panel_set_season_border(inv_panel, accent)
	if almanac_panel:
		almanac_panel.set_seasonal_accent(accent, text_col)
	if recipe_picker:
		recipe_picker.set_seasonal_accent(accent, text_col)
	if shop_ui:
		var shop_frame: Panel = shop_ui.get_node_or_null("SeasonBorder") as Panel
		_panel_set_season_border(shop_frame, accent)
		shop_ui.apply_seasonal_accent(accent)
	_button_set_season_border(ai_config_button, accent)
	var quick_tip_bg: Panel = ui_layer.get_node_or_null("QuickTipBackdrop") as Panel
	if quick_tip_bg:
		var qtp: StyleBoxFlat = quick_tip_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if qtp:
			qtp.border_color = accent
			quick_tip_bg.add_theme_stylebox_override("panel", qtp)
	if quest_log_label:
		quest_log_label.add_theme_color_override("font_color", Color(text_col.r, text_col.g, text_col.b, 0.92))
	var wef_title_season: Label = ui_layer.get_node_or_null("WorldEventFeed/Title") as Label
	if wef_title_season:
		wef_title_season.add_theme_color_override("font_color", text_col)
	var inv_ui_accent: InventoryUI = ui_layer.get_node_or_null("InventoryUI") as InventoryUI
	if inv_ui_accent:
		inv_ui_accent.set_seasonal_accent(accent)
	if season_label:
		season_label.add_theme_color_override("font_color", text_col)

func _update_activity_zone_label() -> void:
	if not activity_zone_label or not player:
		return
	if not InventoryManager:
		activity_zone_label.text = ""
		return
	var item = InventoryManager.get_item(InventoryManager.selected_slot)
	var sid: String = str(item.get("id", "")) if item else ""
	if sid == "fishing_rod" and FishingSystem and FishingSystem.can_fish_here(player.global_position):
		var z: String = FishingSystem.get_fish_zone(player.global_position)
		if z == "river":
			activity_zone_label.text = UITextCatalog.get_activity_text("fish_river")
		elif z == "ocean":
			activity_zone_label.text = UITextCatalog.get_activity_text("fish_ocean")
		else:
			activity_zone_label.text = ""
		return
	if sid in ["pickaxe", "pickaxe_iron"] and MiningSystem and MiningSystem.can_mine_here(player.global_position):
		var d: int = MiningSystem.depth_from_global_y(player.global_position.y)
		var band_key: String = "mine_band_%d" % d
		var band_name: String = UITextCatalog.get_activity_text(band_key)
		if not band_name.is_empty():
			activity_zone_label.text = UITextCatalog.format_activity_text("mine_prefix", {"band": band_name})
		else:
			activity_zone_label.text = ""
		return
	if sid == "axe" and ChoppingSystem and ChoppingSystem.can_chop_here(player.global_position):
		activity_zone_label.text = UITextCatalog.get_activity_text("chop_forest")
		return
	if farm_manager and FarmTierCatalog:
		var fr: Rect2 = FarmTierCatalog.get_farm_upgrade_rect()
		if fr.has_point(player.global_position):
			var ft: int = farm_manager.farm_tier
			var td: Dictionary = FarmTierCatalog.tier_def(ft)
			var nm: String = str(td.get("display_name", "?"))
			var gmult: float = FarmTierCatalog.growth_speed_multiplier(ft)
			var hch: float = FarmTierCatalog.harvest_bonus_chance(ft)
			var hmax: int = FarmTierCatalog.harvest_bonus_max(ft)
			var speed_pct: int = int(round((gmult - 1.0) * 100.0))
			var bonus_text: String = FarmTierCatalog.format_message("hud_bonus", {
				"bonus_pct": int(round(hch * 100.0)),
				"bonus_max": hmax
			})
			var speed_text: String = FarmTierCatalog.format_message("hud_speed", {
				"speed_pct": speed_pct
			})
			if FarmTierCatalog.next_tier_def(ft).is_empty():
				activity_zone_label.text = FarmTierCatalog.format_message("hud_line_max", {
					"tier": ft,
					"tier_name": nm,
					"speed_text": speed_text,
					"bonus_text": bonus_text
				})
			else:
				activity_zone_label.text = FarmTierCatalog.format_message("hud_line_upgradable", {
					"tier": ft,
					"tier_name": nm,
					"speed_text": speed_text,
					"bonus_text": bonus_text
				})
			return
	if player and BuildingUpgradeCatalog:
		var hr: Rect2 = BuildingUpgradeCatalog.get_house_rect()
		if hr.has_point(player.global_position):
			var lv: int = int(GameManager.player_data.get("house_level", 1))
			var cur: Dictionary = BuildingUpgradeCatalog.level_def(lv)
			var nm: String = str(cur.get("name", "Cabin"))
			var bonus: int = int(cur.get("stamina_max_bonus", 0))
			var regen_pct: int = int(round((float(cur.get("stamina_regen_multiplier", 1.0)) - 1.0) * 100.0))
			var next: Dictionary = BuildingUpgradeCatalog.next_level_def(lv)
			if next.is_empty():
				activity_zone_label.text = BuildingUpgradeCatalog.format_message("hud_line_max", {"level": lv, "name": nm, "stamina_bonus": bonus, "regen_pct": regen_pct})
			else:
				activity_zone_label.text = BuildingUpgradeCatalog.format_message("hud_line_upgradable", {"level": lv, "name": nm, "stamina_bonus": bonus, "regen_pct": regen_pct})
			return
	activity_zone_label.text = ""

func _try_load_save_bundle() -> bool:
	if not FileAccess.file_exists(GAME_SAVE_BUNDLE_PATH):
		return false
	var f: FileAccess = FileAccess.open(GAME_SAVE_BUNDLE_PATH, FileAccess.READ)
	if f == null:
		return false
	var bundle: Variant = f.get_var()
	f.close()
	if bundle is Dictionary and int(bundle.get("version", 0)) >= 2:
		_apply_save_bundle(bundle)
		return true
	return false


func _apply_save_bundle(bundle: Dictionary) -> void:
	var src_version: int = int(bundle.get("version", 0))
	if bundle.get("player") is Dictionary:
		GameManager.player_data = bundle["player"].duplicate(true)
		_migrate_player_data_if_needed(src_version)
		_ensure_house_level_default()
		if not GameManager.player_data.has("stamina"):
			GameManager.player_data["stamina"] = 100.0
		if not GameManager.player_data.has("stamina_max"):
			GameManager.player_data["stamina_max"] = 100.0
		_apply_house_stamina_bonus()
	if bundle.get("farm") is Dictionary and farm_manager:
		farm_manager.load_farm_data(bundle["farm"])
	if bundle.get("inventory") is Dictionary and InventoryManager:
		InventoryManager.load_snapshot(bundle["inventory"])
	if bundle.get("quests") is Dictionary and QuestSystem:
		QuestSystem.load_snapshot(bundle["quests"])
	if bundle.get("world_event_feed") is Array:
		world_event_feed.clear()
		for item in bundle["world_event_feed"]:
			world_event_feed.append(str(item))
			if world_event_feed.size() >= WORLD_EVENT_FEED_MAX:
				break
	if bundle.get("active_story_hotspot") is Dictionary:
		active_story_hotspot = (bundle["active_story_hotspot"] as Dictionary).duplicate(true)
	if bundle.get("gathering_almanac") is Dictionary and GatheringAlmanac:
		GatheringAlmanac.apply_save_snapshot(bundle["gathering_almanac"])

func _migrate_player_data_if_needed(src_version: int) -> void:
	if not GameManager:
		return
	if src_version < 3:
		if not GameManager.player_data.has("chain_last_selected"):
			GameManager.player_data["chain_last_selected"] = ""
		if not GameManager.player_data.has("chain_last_selected_day"):
			GameManager.player_data["chain_last_selected_day"] = -1
		if not GameManager.player_data.has("managed_chain_streak"):
			GameManager.player_data["managed_chain_streak"] = 0


func _build_save_bundle() -> Dictionary:
	return {
		"version": SAVE_BUNDLE_VERSION,
		"player": GameManager.player_data.duplicate(true),
		"farm": farm_manager.save_farm_data(),
		"inventory": InventoryManager.save_snapshot(),
		"quests": QuestSystem.save_snapshot(),
		"world_event_feed": world_event_feed.duplicate(),
		"active_story_hotspot": active_story_hotspot.duplicate(true),
		"gathering_almanac": GatheringAlmanac.get_snapshot() if GatheringAlmanac else {}
	}


func initialize_playable_first_loop():
	"""
	Playable-first bootstrap:
	- Start one beginner quest immediately
	- Generate one daily narrative seed
	"""
	if QuestSystem:
		QuestSystem.start_quest("tutorial_plant")
		QuestSystem.start_quest("intro_fish")
		QuestSystem.start_quest("intro_mine")
		QuestSystem.start_quest("intro_smelt")
		QuestSystem.start_quest("intro_eat")
		QuestSystem.start_quest("intro_cook")
		QuestSystem.start_quest("intro_chop")
		QuestSystem.start_quest("intro_craft")
		QuestSystem.start_quest("earn_gold")
	
	if DailyNarrativeSystem:
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		if not narrative.is_empty():
			show_dialogue("Today's story: " + str(narrative.get("title", "A new day begins")))
			_apply_narrative_daily_quest(narrative)
			if QuestSystem and QuestSystem.has_method("activate_chain_for_narrative"):
				QuestSystem.activate_chain_for_narrative(narrative)
			if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("maybe_generate_for_day"):
				await AgenticContentOrchestrator.maybe_generate_for_day(narrative)
				if AgenticContentOrchestrator.has_method("get_runtime_status_line"):
					record_world_event(AgenticContentOrchestrator.get_runtime_status_line())

func give_starter_items():
	var hoe_item = ItemDatabase.get_item("hoe")
	var watering_item = ItemDatabase.get_item("watering_can")
	var parsnip_seeds = ItemDatabase.get_item("parsnip_seeds")
	
	if not hoe_item.is_empty():
		InventoryManager.add_item(hoe_item.duplicate(true))
	if not watering_item.is_empty():
		InventoryManager.add_item(watering_item.duplicate(true))
	if not parsnip_seeds.is_empty():
		for i in range(5):
			InventoryManager.add_item(parsnip_seeds.duplicate(true))
	var pickaxe_item = ItemDatabase.get_item("pickaxe")
	if not pickaxe_item.is_empty():
		InventoryManager.add_item(pickaxe_item.duplicate(true))
	var rod = ItemDatabase.get_item("fishing_rod")
	if not rod.is_empty():
		InventoryManager.add_item(rod.duplicate(true))
	var bait = ItemDatabase.get_item("worm_bait")
	if not bait.is_empty():
		for i in range(5):
			InventoryManager.add_item(bait.duplicate(true))
	var bread = ItemDatabase.get_item("bread")
	if not bread.is_empty():
		InventoryManager.add_item(bread.duplicate(true))
	var fert = ItemDatabase.get_item("basic_fertilizer")
	if not fert.is_empty():
		InventoryManager.add_item(fert.duplicate(true))
	var axe_item = ItemDatabase.get_item("axe")
	if not axe_item.is_empty():
		InventoryManager.add_item(axe_item.duplicate(true))

func _try_eat_selected_food() -> bool:
	var slot: int = InventoryManager.selected_slot
	var item = InventoryManager.get_item(slot)
	if item == null or float(item.get("stamina_restore", 0.0)) <= 0.0:
		return false
	var amt: float = float(item.get("stamina_restore", 0.0))
	var item_id: String = str(item.get("id", ""))
	var nm: String = str(item.get("name", "Food"))
	if GameManager:
		GameManager.restore_stamina(amt)
	InventoryManager.remove_item(slot, 1)
	show_quick_tip(UITextCatalog.format_text("quick_tip", "eat_food_energy", {
		"item": nm,
		"energy": int(ceil(amt))
	}))
	update_ui()
	if QuestSystem:
		QuestSystem.track_event("consume_food", {"item_id": item_id, "count": 1})
	return true

func _try_harvest_facing_tile(tile_coords: Vector2i) -> bool:
	if not farm_manager:
		return false
	var h: Dictionary = farm_manager.harvest_crop(tile_coords)
	if h.is_empty() or not h.has("product"):
		return false
	var product_id: String = str(h.get("product", ""))
	if product_id.is_empty():
		return false
	var count: int = int(h.get("count", 1))
	var template: Dictionary = ItemDatabase.get_item(product_id)
	if template.is_empty():
		show_dialogue("Harvest failed (unknown crop).")
		return true
	for i in range(count):
		if not InventoryManager.add_item(template.duplicate(true)):
			show_dialogue("Inventory full.")
			return true
	var pnm: String = str(template.get("name", product_id))
	show_dialogue("Harvested: %s ×%d" % [pnm, count])
	if int(h.get("tier_bonus", 0)) > 0:
		show_quick_tip(UITextCatalog.format_text("quick_tip", "farm_tier_bonus_yield", {
			"yield": int(h.get("tier_bonus", 0))
		}))
	record_world_event("Harvested %s ×%d" % [product_id, count])
	update_ui()
	return true

func _on_recipe_chosen(recipe: Dictionary, mode: String) -> void:
	var result: Dictionary = {}
	match mode:
		"cooking":
			result = CookingSystem.try_recipe(recipe)
		"smelting":
			result = SmeltingSystem.try_recipe(recipe)
		"crafting":
			result = CraftingSystem.try_recipe(recipe)
	var msg: String = str(result.get("message", ""))
	if result.get("ok", false):
		show_dialogue(msg)
		record_world_event(msg)
	else:
		if not msg.is_empty():
			show_dialogue(msg)
	update_ui()

func _on_player_interact(tile_position: Vector2):
	var tile_coords = tilemap.local_to_map(tile_position)

	# Check for NPC interaction first
	if current_npc:
		var dialogue = current_npc.interact()
		show_dialogue(dialogue)
		if QuestSystem:
			QuestSystem.track_event("talk", {"npc_id": current_npc.npc_id, "count": 1})
		if AIQuestSystem:
			AIQuestSystem.track_event("talk", {"npc_id": current_npc.npc_id, "count": 1})
		return

	if recipe_picker and recipe_picker.visible:
		recipe_picker.close_picker()
		return

	var selected_item = InventoryManager.get_selected_item()

	# Harvest ripe crop (empty hands only — avoids conflict with eating while holding food)
	if selected_item == null and _try_harvest_facing_tile(tile_coords):
		return

	# Kitchen / cooking — recipe picker (empty hands)
	if selected_item == null and CookingSystem and recipe_picker and CookingSystem.can_cook_here(player.global_position):
		recipe_picker.open_picker("cooking", CookingSystem.get_recipe_list())
		return

	# Furnace / smelting — recipe picker
	if selected_item == null and SmeltingSystem and recipe_picker and SmeltingSystem.can_smelt_here(player.global_position):
		recipe_picker.open_picker("smelting", SmeltingSystem.get_recipe_list())
		return

	# Workbench / crafting — recipe picker
	if selected_item == null and CraftingSystem and recipe_picker and CraftingSystem.can_craft_here(player.global_position):
		recipe_picker.open_picker("crafting", CraftingSystem.get_recipe_list())
		return

	# Fishing: equip rod; ocean (south) or river (right); bite QTE — second E in time window
	if selected_item and str(selected_item.get("id", "")) == "fishing_rod" and FishingSystem:
		if FishingSystem.can_fish_here(player.global_position):
			var catch_result: Dictionary = FishingSystem.handle_fish_input(player.global_position)
			if str(catch_result.get("phase", "")) == "hook_prompt":
				show_quick_tip(str(catch_result.get("message", "Press E!")))
				return
			var fish_msg: String = str(catch_result.get("message", ""))
			if catch_result.get("ok", false):
				show_dialogue(fish_msg)
				record_world_event(fish_msg)
				_play_fx_fish()
				return
			if not fish_msg.is_empty():
				show_dialogue(fish_msg)
				return

	# Pickaxe on farm: pick up basic sprinkler from facing tile (before mining)
	if selected_item and str(selected_item.get("id", "")) in ["pickaxe", "pickaxe_iron"] and farm_manager:
		if farm_manager.has_sprinkler_at(tile_coords):
			var tpl_pick: Dictionary = ItemDatabase.get_item("sprinkler_basic")
			if not tpl_pick.is_empty() and InventoryManager.can_add_quantity(tpl_pick, 1):
				if farm_manager.remove_sprinkler(tile_coords):
					InventoryManager.add_item(tpl_pick.duplicate(true))
					if GatheringSfx:
						GatheringSfx.play_mine_swing()
					show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_pickup_success"))
					update_ui()
					return
			show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_pickup_inventory_full"))
			return

	# Mining: pickaxe (basic or iron), Y band = depth; iron pick for deep gold
	if selected_item and str(selected_item.get("id", "")) in ["pickaxe", "pickaxe_iron"] and MiningSystem:
		if MiningSystem.can_mine_here(player.global_position):
			var mine_result: Dictionary = MiningSystem.try_swing(
				player.global_position,
				str(selected_item.get("id", ""))
			)
			var mine_msg: String = str(mine_result.get("message", ""))
			if mine_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				show_dialogue(mine_msg)
				record_world_event(mine_msg)
				var mine_hint: String = str(mine_result.get("hint", ""))
				if not mine_hint.is_empty():
					show_quick_tip(mine_hint)
				_play_fx_mine()
				return
			if not mine_msg.is_empty():
				show_dialogue(mine_msg)
				return

	# Chopping: axe in forest (west, below mine entrance)
	if selected_item and str(selected_item.get("id", "")) == "axe" and ChoppingSystem:
		if ChoppingSystem.can_chop_here(player.global_position):
			var chop_result: Dictionary = ChoppingSystem.try_chop_one()
			var ch_msg: String = str(chop_result.get("message", ""))
			if chop_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				show_dialogue(ch_msg)
				record_world_event(ch_msg)
				return
			if not ch_msg.is_empty():
				show_dialogue(ch_msg)
				return

	# Basic sprinkler — place on empty tilled tile; waters 4 ortho neighbors each morning (+ once on place)
	if selected_item and str(selected_item.get("id", "")) == "sprinkler_basic":
		if not farm_manager:
			return
		if GameManager:
			var sc: float = float(GameManager.player_data.get("stamina", 0.0))
			if sc < 5.0:
				show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_no_stamina"))
				return
		var sp_res: Dictionary = farm_manager.try_place_sprinkler(tile_coords)
		if sp_res.get("ok", false):
			if GameManager:
				GameManager.try_consume_stamina(5.0)
			InventoryManager.remove_item(InventoryManager.selected_slot, 1)
			if GatheringSfx:
				GatheringSfx.play_water()
			show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_success"))
			update_ui()
			return
		match str(sp_res.get("reason", "")):
			"not_tilled":
				show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_not_tilled"))
			"has_crop":
				show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_has_crop"))
			"has_sprinkler":
				show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_has_sprinkler"))
			_:
				show_quick_tip(UITextCatalog.get_text("quick_tip", "sprinkler_place_failed"))
		return

	# Fertilizer — empty tilled tile only; next successful plant gets −1 growth day (see FarmManager).
	if selected_item and str(selected_item.get("type", "")) == "fertilizer" and farm_manager:
		if farm_manager.can_fertilize_here(tile_coords):
			var fert_res: Dictionary = farm_manager.try_apply_fertilizer(tile_coords)
			if fert_res.get("ok", false):
				InventoryManager.remove_item(InventoryManager.selected_slot, 1)
				show_quick_tip(UITextCatalog.get_text("quick_tip", "fertilizer_apply_success"))
				update_ui()
				return
			if str(fert_res.get("reason", "")) == "already_fertilized":
				show_quick_tip(UITextCatalog.get_text("quick_tip", "fertilizer_apply_already"))
				return
		elif farm_manager.is_tile_tilled(tile_coords):
			show_quick_tip(UITextCatalog.get_text("quick_tip", "fertilizer_apply_needs_empty_tilled"))
		else:
			show_quick_tip(UITextCatalog.get_text("quick_tip", "fertilizer_apply_needs_tilled"))
		return

	# Eat food / crops / fish with stamina_restore (select item, press E)
	if selected_item and _try_eat_selected_food():
		return

	# Farming interactions
	if selected_item:
		if selected_item.type == "seed":
			if farm_manager.can_plant_here(tile_coords):
				var crop_id: String = str(selected_item.get("crop_id", ""))
				if crop_id.is_empty():
					return
				var plant_res: Dictionary = farm_manager.plant_seed(tile_coords, crop_id)
				if plant_res.get("ok", false):
					InventoryManager.remove_item(InventoryManager.selected_slot)
					if QuestSystem:
						QuestSystem.track_event("plant", {"crop_id": crop_id, "count": 1})
				else:
					match str(plant_res.get("reason", "")):
						"wrong_season":
							show_quick_tip(UITextCatalog.get_text("quick_tip", "plant_wrong_season"))
						_:
							pass
		elif selected_item.id == "hoe":
			farm_manager.till_soil(tile_coords)
		elif selected_item.id == "watering_can":
			farm_manager.water_plant(tile_coords)
			if GatheringSfx:
				GatheringSfx.play_water()

func _on_time_changed(new_time):
	update_ui()

func _on_day_changed(new_day):
	_reset_daily_event_budget()
	update_ui()
	if QuestSystem and QuestSystem.has_method("on_day_passed"):
		QuestSystem.on_day_passed()
	if AIEconomySystem and AIEconomySystem.has_method("on_day_passed"):
		AIEconomySystem.on_day_passed()
	# Auto-water crops if raining
	if WeatherSystem.is_raining():
		auto_water_crops()
	if AIEconomySystem:
		var market_line: String = AIEconomySystem.get_daily_shop_brief()
		if not market_line.is_empty():
			record_world_event(market_line)
	
	# Lightweight daily refresh keeps the game feeling alive.
	if DailyNarrativeSystem and _consume_daily_budget("narrative"):
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		record_world_event("New day, new story seed is ready.")
		_apply_narrative_daily_quest(narrative)
		if QuestSystem and QuestSystem.has_method("activate_chain_for_narrative") and _consume_daily_budget("chain_activation"):
			QuestSystem.activate_chain_for_narrative(narrative)
		if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("maybe_generate_for_day"):
			await AgenticContentOrchestrator.maybe_generate_for_day(narrative)
			if AgenticContentOrchestrator.has_method("get_runtime_status_line"):
				record_world_event(AgenticContentOrchestrator.get_runtime_status_line())

func _on_quest_log_changed(_a = null, _b = null) -> void:
	_refresh_quest_log()


func _quest_objective_goal(o: Dictionary) -> int:
	if o.has("count"):
		return int(o["count"])
	if o.has("amount"):
		return int(o["amount"])
	return 1


func _refresh_quest_log() -> void:
	if not quest_log_label or not QuestSystem:
		return
	if QuestSystem.active_quests.is_empty():
		var idle_text: String = "Quests\n(none active)"
		if not managed_chain_status_banner.is_empty():
			idle_text += "\n" + managed_chain_status_banner
		quest_log_label.text = idle_text
		return
	var lines: PackedStringArray = []
	var regular_lines: PackedStringArray = []
	var chain_lines: PackedStringArray = []
	for qid in QuestSystem.active_quests:
		var q: Dictionary = QuestSystem.quests.get(qid, {})
		if q.is_empty():
			continue
		var title: String = str(q.get("title", qid))
		var obj_list: Array = q.get("objectives", [])
		var suffix: String = ""
		if obj_list.size() == 1:
			var od: Dictionary = obj_list[0]
			var cur: int = int(od.get("current", 0))
			var goal: int = _quest_objective_goal(od)
			suffix = " %d/%d" % [cur, goal]
		elif obj_list.size() > 1:
			suffix = " (%d steps)" % obj_list.size()
		var tag: String = ""
		if str(q.get("source", "")) == "daily_narrative":
			var ndk: String = str(q.get("narrative_day_key", ""))
			if not ndk.is_empty():
				tag = " [Story %s]" % ndk
			else:
				tag = " [Story]"
		elif str(q.get("source", "")) == "managed_story_chain":
			var st: String = QuestSystem.get_managed_chain_status_tag(str(qid)) if QuestSystem and QuestSystem.has_method("get_managed_chain_status_tag") else ""
			if st == "urgent":
				tag = " [Chain: Urgent]"
			elif st == "failed":
				tag = " [Chain: Failed]"
			else:
				tag = " [Chain: Active]"
		elif str(q.get("source", "")) == "managed_recovery":
			tag = " [Recovery]"
		var out_line: String = "• %s%s%s" % [title, suffix, tag]
		if str(q.get("source", "")) == "managed_story_chain":
			chain_lines.append(out_line)
		else:
			regular_lines.append(out_line)
	lines.append_array(regular_lines)
	if not chain_lines.is_empty():
		lines.append("-- Chains --")
		lines.append_array(chain_lines)
	var title_text: String = "Quests\n"
	if not managed_chain_status_banner.is_empty():
		title_text += managed_chain_status_banner + "\n"
	quest_log_label.text = title_text + "\n".join(lines)


func _is_near_pierre() -> bool:
	var pierre = get_node_or_null("Pierre")
	if not pierre or not player:
		return false
	return player.global_position.distance_to(pierre.global_position) <= PIERRE_SHOP_RADIUS_PX


func _try_farm_tier_upgrade() -> void:
	if not farm_manager or not FarmTierCatalog or not player:
		return
	var fr: Rect2 = FarmTierCatalog.get_farm_upgrade_rect()
	if not fr.has_point(player.global_position):
		show_quick_tip(UITextCatalog.get_text("quick_tip", "farm_upgrade_stand_on_field"))
		return
	var res: Dictionary = farm_manager.try_upgrade_next_tier()
	if res.get("ok", false):
		show_dialogue(str(res.get("message", "Farm upgraded.")))
		record_world_event(str(res.get("message", "Farm upgraded.")))
		update_ui()
		return
	var m: String = str(res.get("message", ""))
	if not m.is_empty():
		show_quick_tip(m)


func _ensure_house_level_default() -> void:
	if not GameManager:
		return
	if not GameManager.player_data.has("house_level"):
		GameManager.player_data["house_level"] = 1
	_apply_house_stamina_bonus()


func _apply_house_stamina_bonus() -> void:
	if not GameManager:
		return
	var lv: int = int(GameManager.player_data.get("house_level", 1))
	var d: Dictionary = BuildingUpgradeCatalog.level_def(lv) if BuildingUpgradeCatalog else {}
	var bonus: float = float(d.get("stamina_max_bonus", 0.0))
	var regen_mult: float = float(d.get("stamina_regen_multiplier", 1.0))
	var smax: float = BASE_STAMINA_MAX + bonus
	GameManager.player_data["stamina_max"] = smax
	GameManager.player_data["stamina_regen_mult"] = maxf(0.1, regen_mult)
	var scur: float = float(GameManager.player_data.get("stamina", smax))
	GameManager.player_data["stamina"] = minf(scur, smax)


func _try_house_upgrade() -> void:
	if not BuildingUpgradeCatalog or not GameManager or not player:
		return
	var hr: Rect2 = BuildingUpgradeCatalog.get_house_rect()
	if not hr.has_point(player.global_position):
		show_quick_tip(BuildingUpgradeCatalog.format_message("tip_outside"))
		return
	var lv: int = int(GameManager.player_data.get("house_level", 1))
	var next: Dictionary = BuildingUpgradeCatalog.next_level_def(lv)
	if next.is_empty():
		show_quick_tip(BuildingUpgradeCatalog.format_message("tip_max"))
		return
	var cost_gold: int = int(next.get("upgrade_cost_gold", 0))
	var costs: Dictionary = next.get("upgrade_cost_items", {})
	if int(GameManager.player_data.get("gold", 0)) < cost_gold:
		show_quick_tip(BuildingUpgradeCatalog.format_message("tip_not_enough_gold", {"gold": cost_gold}))
		return
	for k in costs.keys():
		var need: int = int(costs[k])
		if InventoryManager.count_item(str(k)) < need:
			show_quick_tip(BuildingUpgradeCatalog.format_message("tip_missing_materials"))
			return
	GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) - cost_gold
	for k in costs.keys():
		InventoryManager.consume_item_by_id(str(k), int(costs[k]))
	GameManager.player_data["house_level"] = lv + 1
	_apply_house_stamina_bonus()
	var now_def: Dictionary = BuildingUpgradeCatalog.level_def(lv + 1)
	var nm: String = str(now_def.get("name", "House"))
	var bonus: int = int(now_def.get("stamina_max_bonus", 0))
	var regen_pct: int = int(round((float(now_def.get("stamina_regen_multiplier", 1.0)) - 1.0) * 100.0))
	var msg: String = BuildingUpgradeCatalog.format_message("tip_upgraded", {"name": nm, "stamina_bonus": bonus, "regen_pct": regen_pct})
	show_dialogue(msg)
	record_world_event(msg)
	update_ui()


func _try_open_shop_near_pierre() -> void:
	if not shop_ui:
		return
	if shop_ui.visible:
		shop_ui.close_shop()
		return
	if not _is_near_pierre():
		show_quick_tip(UITextCatalog.get_text("quick_tip", "shop_open_near_pierre"))
		return
	shop_ui.open_shop()


func _try_sell_selected_inventory() -> bool:
	if not ShopSystem:
		return false
	var slot: int = InventoryManager.selected_slot
	var item = InventoryManager.get_item(slot)
	if item == null:
		show_quick_tip(UITextCatalog.get_text("quick_tip", "sell_nothing_selected"))
		return false
	var item_id: String = str(item.get("id", ""))
	if item_id.is_empty():
		return false
	if ShopSystem.get_sell_price_per_unit(item_id) <= 0:
		show_quick_tip(UITextCatalog.get_text("quick_tip", "sell_item_cannot"))
		return false
	if ShopSystem.sell_from_slot(slot, 1):
		update_ui()
		if shop_ui and shop_ui.visible:
			shop_ui.update_gold_display()
		var unit: int = ShopSystem.get_sell_price_per_unit(item_id)
		show_quick_tip(UITextCatalog.format_text("quick_tip", "sell_success_gold", {"gold": unit}))
		if AIEconomySystem:
			var market_note: String = AIEconomySystem.get_market_brief(item_id)
			if not market_note.is_empty():
				record_world_event("Market shift after selling %s: %s" % [item_id, market_note])
		return true
	return false


func _on_shop_purchase(item_id: String, quantity: int) -> void:
	if not ShopSystem:
		return
	if ShopSystem.purchase_item(item_id, quantity):
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		var nm: String = str(tpl.get("name", item_id)) if not tpl.is_empty() else item_id
		show_quick_tip(UITextCatalog.format_text("quick_tip", "shop_bought_item", {"item": nm}))
		if AIEconomySystem:
			var market_note: String = AIEconomySystem.get_market_brief(item_id)
			if not market_note.is_empty():
				record_world_event("Market shift after buying %s: %s" % [nm, market_note])
		update_ui()
		if shop_ui:
			shop_ui.populate_shop_items()
			shop_ui.update_gold_display()
	else:
		show_quick_tip(UITextCatalog.get_text("quick_tip", "shop_purchase_failed"))


func _on_quest_completed(quest_id: String):
	if QuestSystem and QuestSystem.quests.has(quest_id):
		var quest_data: Dictionary = QuestSystem.quests[quest_id]
		var title = quest_data.get("title", quest_id)
		show_dialogue("Quest completed: " + str(title))
		_apply_story_completion_feedback(quest_data)
	_refresh_quest_log()

func _on_quest_failed(quest_id: String, reason: String) -> void:
	var line: String = "Quest failed: %s (%s)" % [quest_id, reason if not reason.is_empty() else "unknown"]
	record_world_event(line)
	show_quick_tip("Quest failed: " + quest_id, 1.8)
	_refresh_quest_log()

func _on_quest_impact_applied(quest_id: String, impact: Dictionary) -> void:
	var social_delta: int = int(impact.get("social_delta", 0))
	var growth_xp: int = int(impact.get("growth_xp", 0))
	var parts: Array[String] = []
	if social_delta != 0:
		parts.append("social %s%d" % ["+" if social_delta > 0 else "", social_delta])
	if growth_xp != 0:
		parts.append("growth_xp %s%d" % ["+" if growth_xp > 0 else "", growth_xp])
	if parts.is_empty():
		return
	var line: String = "Quest impact [%s]: %s" % [quest_id, ", ".join(parts)]
	record_world_event(line)
	show_quick_tip(line, 1.9)

func _apply_story_completion_feedback(quest_data: Dictionary) -> void:
	if quest_data.get("source", "") != "daily_narrative":
		return

	var story_npc_id: String = str(quest_data.get("story_npc_id", ""))
	if story_npc_id.is_empty():
		return
	var quest_id: String = str(quest_data.get("id", ""))
	var narrative_id: String = str(quest_data.get("narrative_id", ""))

	# Immediate "world reacts to player action" feedback.
	if NPCEmotionSystem:
		NPCEmotionSystem.set_emotion(
			story_npc_id,
			NPCEmotionSystem.BasicEmotion.HAPPY,
			0.8,
			120.0,
			"player_story_help"
		)
		var spread_results: Array = NPCEmotionSystem.propagate_emotion_to_social_circle(
			story_npc_id,
			NPCEmotionSystem.BasicEmotion.HAPPY,
			0.6,
			"story_emotion_spread"
		)
		for result in spread_results:
			var neighbor_id: String = str(result.get("npc_id", ""))
			if not neighbor_id.is_empty():
				record_world_event("%s was uplifted after hearing about your help to %s." % [neighbor_id.capitalize(), story_npc_id.capitalize()])
				if NPCMemorySystem:
					NPCMemorySystem.record_event(
						neighbor_id,
						"I heard the player helped %s with today's story. People are talking about it." % story_npc_id.capitalize(),
						0.78,
						"happy",
						["player", story_npc_id, neighbor_id, "daily_narrative", quest_id]
					)
		if NPCMemorySystem:
			NPCMemorySystem.record_event(
				story_npc_id,
				"The player helped me with today's story quest. I'm grateful.",
				0.82,
				"happy",
				["player", story_npc_id, "daily_narrative", quest_id]
			)

	if NPCAudioManager:
		NPCAudioManager.speak(story_npc_id, "Thanks! Today's story moved forward because of you.", "happy")

	var feedback_line := "%s now feels encouraged by your help." % story_npc_id.capitalize()
	if not narrative_id.is_empty():
		feedback_line += " [Narrative: %s]" % narrative_id
	record_world_event(feedback_line)
	show_dialogue(feedback_line)

func record_world_event(event_text: String) -> void:
	var timestamp := ""
	if GameManager:
		timestamp = str(GameManager.get_time_string())
	var line := "[%s] %s" % [timestamp if not timestamp.is_empty() else "--:--", event_text]
	world_event_feed.push_front(line)
	if world_event_feed.size() > WORLD_EVENT_FEED_MAX:
		world_event_feed.resize(WORLD_EVENT_FEED_MAX)
	_refresh_world_event_feed_ui()

func _refresh_world_event_feed_ui() -> void:
	if not world_event_feed_label:
		return
	if world_event_feed.is_empty():
		world_event_feed_label.text = "No events yet."
		return
	world_event_feed_label.text = "\n".join(world_event_feed)

func _apply_narrative_daily_quest(narrative: Dictionary):
	if narrative.is_empty():
		return
	if not QuestSystem:
		return
	var events = narrative.get("events", [])
	if events is Array and events.size() > 0:
		var evt: Dictionary = events[0].duplicate(true) if events[0] is Dictionary else {}
		evt["narrative_id"] = str(narrative.get("id", ""))
		evt["narrative_day_key"] = "%d-%s-%d" % [
			int(GameManager.player_data.get("year", 1)),
			str(GameManager.player_data.get("season", "spring")),
			int(GameManager.player_data.get("day", 1))
		]
		evt["narrative_source"] = str(narrative.get("source", "local"))
		QuestSystem.add_story_daily_quest(evt)

func _on_daily_narrative_generated(_narrative_id: String, narrative_data: Dictionary) -> void:
	if narrative_data.is_empty():
		return
	var title: String = str(narrative_data.get("title", "A new day begins"))
	var source: String = str(narrative_data.get("source", "local"))
	var nid: String = str(narrative_data.get("id", ""))
	var summary: String = str(narrative_data.get("description", "")).strip_edges()
	var line: String = "Daily story (%s/%s): %s" % [source, nid, title]
	if not summary.is_empty():
		line += " — " + summary
	record_world_event(line)
	_emit_narrative_hotspot_hint(narrative_data)

func _on_narrative_backend_fallback(reason: String) -> void:
	_record_ai_fallback_event("daily_narrative", reason, "local_generator")

func _emit_narrative_hotspot_hint(narrative_data: Dictionary) -> void:
	var hotspot: Dictionary = _resolve_narrative_hotspot(narrative_data)
	if hotspot.is_empty():
		return
	active_story_hotspot = hotspot.duplicate(true)
	var place: String = str(hotspot.get("location", "town_square"))
	var npc_name: String = str(hotspot.get("npc_name", ""))
	var line: String = "Story clue: check %s." % place
	if not npc_name.is_empty():
		line = "Story clue: check %s and talk to %s." % [place, npc_name]
	record_world_event(line)
	show_quick_tip(line, 2.0)

func _resolve_narrative_hotspot(narrative_data: Dictionary) -> Dictionary:
	var events: Array = narrative_data.get("events", [])
	if events.is_empty():
		return {}
	var first_evt: Dictionary = events[0] if events[0] is Dictionary else {}
	if first_evt.is_empty():
		return {}
	var location: String = str(first_evt.get("location", first_evt.get("zone", "town_square"))).strip_edges()
	if location.is_empty():
		location = "town_square"
	var npc_id: String = str(first_evt.get("npc_id", "")).strip_edges()
	var npc_name: String = npc_id
	if not npc_id.is_empty() and EnhancedPersonalitySystem and EnhancedPersonalitySystem.has_method("get_npc_complete_profile"):
		var profile: Dictionary = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
		if profile.has("basic_info"):
			npc_name = str((profile["basic_info"] as Dictionary).get("name", npc_id))
	return {
		"location": location,
		"npc_id": npc_id,
		"npc_name": npc_name,
		"narrative_id": str(narrative_data.get("id", "")),
		"day_key": "%d-%s-%d" % [
			int(GameManager.player_data.get("year", 1)),
			str(GameManager.player_data.get("season", "spring")),
			int(GameManager.player_data.get("day", 1))
		]
	}

func _on_ai_quest_generation_failed(npc_id: String, reason: String) -> void:
	var source: String = "ai_quest:%s" % (npc_id if not npc_id.is_empty() else "unknown_npc")
	_record_ai_fallback_event(source, reason, "procedural_quest")

func _on_managed_chain_resolved(outcome: Dictionary) -> void:
	var result: String = str(outcome.get("result", "success"))
	var pace: String = str(outcome.get("pace", "steady"))
	var bonus: int = int(outcome.get("bonus_gold", 0))
	var elapsed_sec: int = int(outcome.get("elapsed_sec", 0))
	var line: String = "Village supply chain resolved [%s] +%dg (elapsed %ds)" % [pace, bonus, elapsed_sec]
	if result == "failed":
		line = "Village supply chain failed (%s) %ds" % [str(outcome.get("reason", "unknown")), elapsed_sec]
		managed_chain_status_banner = "[Chain: Failed]"
	elif result == "recovered":
		line = "Village supply chain recovered and restarted."
		managed_chain_status_banner = "[Chain: Recovered]"
	elif pace == "fast":
		managed_chain_status_banner = "[Chain: Completed Fast]"
	elif pace == "slow":
		managed_chain_status_banner = "[Chain: Completed Slow]"
	else:
		managed_chain_status_banner = "[Chain: Completed Steady]"
	record_world_event(line)
	show_quick_tip(line, 2.1)
	if result == "failed":
		show_dialogue("Town response: The request expired, and market confidence dipped.")
		if NPCAudioManager:
			NPCAudioManager.speak("pierre", "The town needs steadier deliveries...", "sad")
		if NPCMemorySystem:
			NPCMemorySystem.record_event(
				"pierre",
				"The player missed the delivery chain deadline. Market confidence dropped.",
				0.78,
				"sad",
				["player", "chain_failed", str(outcome.get("chain_id", ""))]
			)
	elif result == "recovered":
		show_dialogue("Town response: Recovery accepted. The village trust is restored.")
		if NPCAudioManager:
			NPCAudioManager.speak("pierre", "Thanks, this recovery came right in time.", "happy")
		if NPCMemorySystem:
			NPCMemorySystem.record_event(
				"pierre",
				"The player completed a recovery task and restored trust.",
				0.72,
				"happy",
				["player", "chain_recovered", str(outcome.get("chain_id", ""))]
			)
		if _consume_daily_budget("recovery_hint"):
			record_world_event("Budget note: recovery path consumed one daily recovery slot.")
	elif pace == "fast":
		show_dialogue("Town response: Fast completion boosted trade confidence today.")
		if NPCAudioManager:
			NPCAudioManager.speak("pierre", "Excellent pace! The whole town felt that momentum.", "excited")
	elif pace == "slow":
		show_dialogue("Town response: Delayed completion softened market momentum.")
		if NPCAudioManager:
			NPCAudioManager.speak("pierre", "We made it, but the market cooled a little.", "neutral")
	else:
		show_dialogue("Town response: Stable completion keeps the market moving.")
		if NPCAudioManager:
			NPCAudioManager.speak("pierre", "Steady work keeps this town alive.", "happy")
	_refresh_quest_log()

func _record_ai_fallback_event(source: String, reason: String, degraded_to: String) -> void:
	var line: String = "AI fallback source=%s degraded_to=%s reason=%s" % [
		source,
		degraded_to,
		reason if not reason.is_empty() else "unknown"
	]
	record_world_event(line)
	show_quick_tip("AI fallback: " + degraded_to, 1.6)

func _on_agentic_chain_generation_started(reason: String) -> void:
	record_world_event("Agentic runtime generation started: %s" % reason)

func _on_agentic_chain_generation_published(chain_id: String, mode: String) -> void:
	record_world_event("Agentic runtime chain published: %s (mode=%s)" % [chain_id, mode])
	show_quick_tip("New runtime chain online", 1.6)

func _on_agentic_chain_generation_failed(reason: String) -> void:
	record_world_event("Agentic runtime generation failed: %s" % reason)
	if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("get_recovery_guidance"):
		var hint: String = str(AgenticContentOrchestrator.get_recovery_guidance(reason))
		if not hint.is_empty():
			record_world_event("Recovery hint: %s" % hint)
			show_quick_tip("Recovery: " + hint, 2.1)

func _on_agentic_chain_generation_degraded(reason: String) -> void:
	_record_ai_fallback_event("agentic_runtime", reason, "static_chain_templates")
	if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("get_recovery_guidance"):
		var hint2: String = str(AgenticContentOrchestrator.get_recovery_guidance(reason))
		if not hint2.is_empty():
			record_world_event("Recovery hint: %s" % hint2)

func _on_agentic_runtime_status_updated(snapshot: Dictionary) -> void:
	var breaker: String = str(snapshot.get("breaker_state", "open"))
	if breaker == "closed":
		show_quick_tip("Agentic runtime paused (breaker closed)", 1.8)
	elif breaker == "half_open":
		show_quick_tip("Agentic runtime retrying (half-open)", 1.6)

func _on_agentic_guardrail_blocked(reason: String, snapshot: Dictionary) -> void:
	var top_reason: String = str(snapshot.get("top_block_reason", ""))
	record_world_event("Agentic guardrail blocked: %s (top=%s)" % [reason, top_reason if not top_reason.is_empty() else "-"])

func _reset_daily_event_budget() -> void:
	daily_event_budget["narrative"] = 1
	daily_event_budget["chain_activation"] = 1
	daily_event_budget["recovery_hint"] = 1

func _consume_daily_budget(key: String) -> bool:
	var left: int = int(daily_event_budget.get(key, 0))
	if left <= 0:
		return false
	daily_event_budget[key] = left - 1
	return true

func _on_season_changed(new_season):
	_apply_seasonal_hud_tint()
	update_ui()

func auto_water_crops():
	for position in farm_manager.planted_crops:
		farm_manager.water_plant(position)

func _on_crop_planted(position, crop_id):
	QuestSystem.track_event("plant", {"crop_id": crop_id, "count": 1})

func _on_crop_harvested(position, crop_id, quantity):
	QuestSystem.track_event("harvest", {"crop_id": crop_id, "count": quantity})

func update_ui():
	time_label.text = GameManager.get_time_string()
	gold_label.text = "Gold: %d" % GameManager.player_data.gold
	if stamina_label:
		var s: float = float(GameManager.player_data.get("stamina", 100.0))
		var sm: float = float(GameManager.player_data.get("stamina_max", 100.0))
		stamina_label.text = "Stamina: %d / %d" % [int(s), int(sm)]
	weather_label.text = "Weather: %s" % WeatherSystem.get_weather_name()
	season_label.text = "Season: %s" % GameManager.player_data.season.capitalize()
	day_label.text = "Day %d, Year %d" % [GameManager.player_data.day, GameManager.player_data.year]
	_refresh_quest_log()

func show_dialogue(text: String):
	if dialogue_label:
		dialogue_label.text = text
	dialogue_box.visible = true
	await get_tree().create_timer(3.0).timeout
	dialogue_box.visible = false

func show_quick_tip(text: String, duration: float = 1.35) -> void:
	if not quick_tip_label or not quick_tip_timer:
		return
	quick_tip_label.text = text
	quick_tip_label.visible = true
	var qtb: Panel = ui_layer.get_node_or_null("QuickTipBackdrop") as Panel if ui_layer else null
	if qtb:
		qtb.visible = true
	quick_tip_timer.stop()
	quick_tip_timer.wait_time = duration
	quick_tip_timer.start()

func _on_quick_tip_timeout() -> void:
	if quick_tip_label:
		quick_tip_label.visible = false
	var qtb: Panel = ui_layer.get_node_or_null("QuickTipBackdrop") as Panel if ui_layer else null
	if qtb:
		qtb.visible = false

func _play_fx_fish() -> void:
	if fx_fish:
		fx_fish.global_position = player.global_position
		fx_fish.restart()
		fx_fish.emitting = true

func _play_fx_mine() -> void:
	if fx_mine:
		fx_mine.global_position = player.global_position
		fx_mine.restart()
		fx_mine.emitting = true

func _unhandled_input(event):
	if event.is_action_pressed("toggle_almanac") and almanac_panel:
		almanac_panel.visible = not almanac_panel.visible
		return
	if event.is_action_pressed("sell_selected"):
		_try_sell_selected_inventory()
		return
	if event.is_action_pressed("open_shop"):
		_try_open_shop_near_pierre()
		return
	if event.is_action_pressed("farm_upgrade"):
		_try_farm_tier_upgrade()
		return
	if event.is_action_pressed("house_upgrade"):
		_try_house_upgrade()
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_cancel"):
		save_game()

func toggle_inventory():
	var inventory_ui = $UILayer/InventoryUI
	inventory_ui.visible = not inventory_ui.visible

func save_game():
	var bundle: Dictionary = _build_save_bundle()
	var bf: FileAccess = FileAccess.open(GAME_SAVE_BUNDLE_PATH, FileAccess.WRITE)
	if bf:
		bf.store_var(bundle)
		bf.close()
	if NPCMemorySystem:
		NPCMemorySystem.save_memories()
	if NPCEmotionSystem:
		NPCEmotionSystem.save_emotion_state()
	print("Game saved!")

func _on_ai_config_pressed():
	if not ai_config_instance:
		ai_config_instance = ai_config_scene.instantiate()
		add_child(ai_config_instance)
	
	ai_config_instance.open_config()

