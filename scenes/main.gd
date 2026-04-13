extends Node2D

@onready var player = $Player
@onready var tilemap: TileMap = get_node_or_null("TileMap") as TileMap
@onready var farm_manager: FarmManager = get_node_or_null("FarmManager") as FarmManager
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
@onready var world_event_feed_label = $UILayer/RightJournalTabs/Events/EventScroll/Content
@onready var quick_tip_label = $UILayer/QuickTipLabel
@onready var quick_tip_timer = $UILayer/QuickTipTimer
@onready var activity_zone_label = $UILayer/ActivityZoneLabel
@onready var fx_fish = $FXLayer/FishSplash
@onready var fx_mine = $FXLayer/MineSpark
@onready var fx_chop = $FXLayer/ChopLeaves
@onready var almanac_panel = $UILayer/AlmanacPanel
@onready var recipe_picker = $UILayer/RecipePicker
@onready var shop_ui = $UILayer/ShopUI
@onready var quest_log_label = $UILayer/RightJournalTabs/Quests/QuestLogScroll/QuestLogLabel
@onready var right_journal_tabs: TabContainer = $UILayer/RightJournalTabs

var current_npc = null
var ai_config_scene = preload("res://scenes/ai_config_ui.tscn")
var ai_config_instance = null
var world_event_feed: Array[String] = []
var managed_chain_status_banner: String = ""
var active_story_hotspot: Dictionary = {}
const WEATHER_OVERLAY_SCENE := preload("res://scenes/weather_overlay.tscn")
const AUDIO_MIX_PANEL_SCENE := preload("res://scenes/audio_mix_panel.tscn")
const PLAYER_CREATION_SCENE := preload("res://scenes/player_creation_panel.tscn")
const PLAYER_JOURNAL_SCENE := preload("res://scenes/player_journal_panel.tscn")
const PERF_OVERLAY_SCENE := preload("res://scripts/world/perf_overlay.gd")
const ALIGNMENT_PROFILE_PATH := "res://data/presentation/stardew_alignment_profile.json"
var audio_mix_panel: CanvasLayer = null
var player_creation_panel: CanvasLayer = null
var player_journal_panel: CanvasLayer = null
var _had_savegame: bool = false
var _boot_finished: bool = false
var _stamina_low_latched: bool = false
var daily_event_budget: Dictionary = {"narrative": 1, "chain_activation": 1, "recovery_hint": 1}
var _combat_quest_chain: int = 0
const WORLD_EVENT_FEED_MAX := 6
const BASE_STAMINA_MAX := 100.0
## Throttle keys: "memory", "market", "em_<npc_id>", "rel", "pref"
var _visible_feed_last: Dictionary = {}
var _dialogue_hide_timer: Timer
var _journal_modal_dim: ColorRect = null
var _journal_popup_open: bool = false
var _alignment_profile: Dictionary = {}

func _ready():
	# Connect signals
	player.interacted.connect(_on_player_interact)
	if GameManager:
		if GameManager.has_signal("time_changed") and not GameManager.time_changed.is_connected(_on_time_changed):
			GameManager.time_changed.connect(_on_time_changed)
		if GameManager.has_signal("day_changed") and not GameManager.day_changed.is_connected(_on_day_changed):
			GameManager.day_changed.connect(_on_day_changed)
		if GameManager.has_signal("season_changed") and not GameManager.season_changed.is_connected(_on_season_changed):
			GameManager.season_changed.connect(_on_season_changed)
	if LocaleSettings:
		LocaleSettings.locale_changed.connect(_on_locale_changed)
	if AchievementSystem:
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked_history)
	
	# Connect farming signals for quest tracking (farm lives in `world_farm.tscn` after B2)
	if farm_manager:
		farm_manager.crop_planted.connect(_on_crop_planted)
		farm_manager.crop_harvested.connect(_on_crop_harvested)

	_dialogue_hide_timer = Timer.new()
	_dialogue_hide_timer.one_shot = true
	_dialogue_hide_timer.timeout.connect(_on_dialogue_hide_timeout)
	add_child(_dialogue_hide_timer)
	
	# Single save file: `game_save.bundle` (see `save_game` / `_build_save_bundle`)
	_had_savegame = _try_load_save_bundle()
	_ensure_profile_defaults()
	_refresh_world_event_feed_ui()
	if not _had_savegame:
		_ensure_house_level_default()
	if QuestSystem:
		QuestSystem.quest_started.connect(_on_quest_log_changed)
		QuestSystem.quest_updated.connect(_on_quest_log_changed)
		if QuestSystem.has_signal("quest_journal_refresh_requested"):
			QuestSystem.quest_journal_refresh_requested.connect(_on_quest_log_changed)
		QuestSystem.quest_completed.connect(_on_quest_completed)
		if QuestSystem.has_signal("quest_failed"):
			QuestSystem.quest_failed.connect(_on_quest_failed)
		if QuestSystem.has_signal("quest_impact_applied"):
			QuestSystem.quest_impact_applied.connect(_on_quest_impact_applied)
		if QuestSystem.has_signal("managed_chain_resolved"):
			QuestSystem.managed_chain_resolved.connect(_on_managed_chain_resolved)
	if NPCMemorySystem and NPCMemorySystem.has_signal("memory_added"):
		NPCMemorySystem.memory_added.connect(_on_visible_memory_added)
	if NPCEmotionSystem and NPCEmotionSystem.has_signal("emotion_changed"):
		NPCEmotionSystem.emotion_changed.connect(_on_visible_emotion_changed)
	if AIEconomySystem and AIEconomySystem.has_signal("player_visible_market_note"):
		AIEconomySystem.player_visible_market_note.connect(_on_player_visible_market_note)
	if AIEventSystem:
		if AIEventSystem.has_signal("event_started"):
			AIEventSystem.event_started.connect(_on_ai_world_event_started)
		if AIEventSystem.has_signal("world_state_changed"):
			AIEventSystem.world_state_changed.connect(_on_ai_world_state_changed)
	if NPCTraitSystem and NPCTraitSystem.has_signal("relationship_evolved"):
		NPCTraitSystem.relationship_evolved.connect(_on_relationship_evolved)
	if NPCMemorySystem and NPCMemorySystem.has_signal("preference_learned"):
		NPCMemorySystem.preference_learned.connect(_on_preference_learned_memory)
	if NPCPersonalitySystem and NPCPersonalitySystem.has_signal("preference_learned"):
		NPCPersonalitySystem.preference_learned.connect(_on_preference_learned_personality)
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
	add_child(WEATHER_OVERLAY_SCENE.instantiate())
	audio_mix_panel = AUDIO_MIX_PANEL_SCENE.instantiate() as CanvasLayer
	add_child(audio_mix_panel)
	player_creation_panel = PLAYER_CREATION_SCENE.instantiate() as CanvasLayer
	add_child(player_creation_panel)
	player_journal_panel = PLAYER_JOURNAL_SCENE.instantiate() as CanvasLayer
	add_child(player_journal_panel)
	if player_creation_panel.has_signal("creation_finished"):
		player_creation_panel.creation_finished.connect(_on_player_creation_done)
	
	# Setup AI config button
	if ai_config_button and not ai_config_button.pressed.is_connected(_on_ai_config_pressed):
		ai_config_button.pressed.connect(_on_ai_config_pressed)
	if quick_tip_timer:
		quick_tip_timer.timeout.connect(_on_quick_tip_timeout)
	if OS.is_debug_build():
		add_child(PERF_OVERLAY_SCENE.new())

	_load_alignment_profile()
	_apply_a3_ui_polish()
	_apply_alignment_profile()
	_connect_mine_bands_toggle()
	_set_journal_popup_visible(false)

	if not GameManager.player_data.get("profile", {}).get("confirmed", false):
		call_deferred("_open_player_creation")
		return
	
	_finish_boot_after_profile()
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	call_deferred("_refresh_story_hotspot_hud")


func _open_player_creation() -> void:
	if player_creation_panel and player_creation_panel.has_method("begin"):
		player_creation_panel.begin()


func _on_player_creation_done() -> void:
	_record_history("game_start", {})
	save_game()
	_finish_boot_after_profile()
	if WorldRouter:
		WorldRouter.apply_pending_spawn_and_clear()
	call_deferred("_refresh_story_hotspot_hud")


func _finish_boot_after_profile() -> void:
	if _boot_finished:
		return
	_boot_finished = true
	if not _had_savegame:
		give_starter_items()
	update_ui()
	initialize_playable_first_loop()
	_apply_rc_beginner_guidance()
	_print_boot_banner()
	if WorldRouter:
		WorldRouter.call_deferred("consume_saved_world_after_boot")


func _print_boot_banner() -> void:
	print("======================================")
	print("  Stardew Valley Clone - AI Edition")
	print("======================================")
	print("AI Model: ", AIAgentManager.api_config.model if AIAgentManager else "Not loaded")
	print("NPCs with AI: Pierre, Abigail, Lewis")
	print("Press E: NPCs | harvest | kitchen/smelter/workbench | fish | mine | chop | eat | V barn | L events/quests | O journal | F10 audio")
	print("======================================")


func _exit_tree() -> void:
	if GameManager:
		GameManager.journal_world_event_feed.clear()
		for s in world_event_feed:
			GameManager.journal_world_event_feed.append(str(s))
		GameManager.journal_active_story_hotspot = active_story_hotspot.duplicate(true)
	if farm_manager and FarmStateCache:
		FarmStateCache.sync_from_manager(farm_manager)


func _record_history(event_key: String, params: Dictionary = {}) -> void:
	if not GameManager:
		return
	if not GameManager.player_data.has("history_log"):
		GameManager.player_data["history_log"] = []
	var log: Array = GameManager.player_data["history_log"]
	var entry: Dictionary = {
		"key": event_key,
		"params": params,
		"day": int(GameManager.player_data.get("day", 1)),
		"season": str(GameManager.player_data.get("season", "spring")),
		"year": int(GameManager.player_data.get("year", 1)),
	}
	log.append(entry)
	while log.size() > 140:
		log.pop_front()


func _on_achievement_unlocked_history(achievement_id: String) -> void:
	_record_history("achievement_unlocked", {"achievement_id": achievement_id})


func _ensure_profile_defaults() -> void:
	if not GameManager:
		return
	GameManager.ensure_progression_subtrees()
	if not GameManager.player_data.has("history_log"):
		GameManager.player_data["history_log"] = []
	if not GameManager.player_data.has("profile"):
		GameManager.player_data["profile"] = {
			"display_name": "",
			"gender": "neutral",
			"personality": "kind",
			"hobbies": [],
			"avatar_id": 0,
			"body_type": 0,
			"hairstyle_id": 0,
			"outfit_id": 0,
			"confirmed": false
		}


func _on_locale_changed(_code: String) -> void:
	update_ui()
	_apply_journal_tab_titles()
	_refresh_mine_area_locale()
	_refresh_quest_log()
	if audio_mix_panel and audio_mix_panel.has_method("refresh_locale_text"):
		audio_mix_panel.refresh_locale_text()
	if recipe_picker and recipe_picker.has_method("refresh_locale"):
		recipe_picker.refresh_locale()
	if ai_config_instance and ai_config_instance.has_method("refresh_locale_text"):
		ai_config_instance.refresh_locale_text()


func _process(_delta: float) -> void:
	_update_activity_zone_label()
	_check_stamina_low_feedback()


func _load_alignment_profile() -> void:
	_alignment_profile = {}
	var f: FileAccess = FileAccess.open(ALIGNMENT_PROFILE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		_alignment_profile = (parsed as Dictionary).duplicate(true)


func _apply_alignment_profile() -> void:
	var visual: Dictionary = _alignment_profile.get("visual", {})
	var ui_cfg: Dictionary = _alignment_profile.get("ui", {})
	if bool(visual.get("hide_placeholder_zone_overlays", true)):
		for p: String in [
			"SmelterArea/Slab",
			"KitchenArea/Counter",
			"WorkbenchArea/BenchTop",
			"ForestArea/ForestFloor",
			"MineArea/MineLayerSurface",
			"MineArea/MineLayerIron",
			"MineArea/MineLayerDeep",
			"RiverZone/RiverWater",
			"OceanZone/OceanWater",
			"FarmUpgradeArea/Overlay",
			"HouseUpgradeArea/Overlay",
		]:
			var n: CanvasItem = get_node_or_null(p) as CanvasItem
			if n:
				n.visible = false
	if bool(visual.get("hide_zone_hint_labels", true)):
		for p: String in [
			"SmelterArea/SmelterHint",
			"KitchenArea/KitchenHint",
			"WorkbenchArea/WorkbenchHint",
			"ForestArea/ForestHint",
			"MineArea/MineHint",
			"RiverZone/RiverHint",
			"OceanZone/OceanHint",
			"FarmUpgradeArea/FarmUpgradeHint",
			"HouseUpgradeArea/HouseUpgradeHint",
		]:
			var n: CanvasItem = get_node_or_null(p) as CanvasItem
			if n:
				n.visible = false
	var mine_toggle: CanvasItem = get_node_or_null("MineArea/MineBandsToggle") as CanvasItem
	if mine_toggle:
		mine_toggle.visible = false
	if ui_cfg.get("hide_ai_config_button", true) and ai_config_button:
		ai_config_button.visible = false
	if ui_cfg.get("hide_activity_zone_label", true) and activity_zone_label:
		activity_zone_label.visible = false
	_apply_minimal_hud_mode(ui_cfg)


func _apply_minimal_hud_mode(ui_cfg: Dictionary) -> void:
	if not bool(ui_cfg.get("minimal_hud_default", true)):
		return
	if season_label:
		season_label.visible = false
	if weather_label:
		weather_label.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	# Keep essentials only: time / gold / stamina / day.
	var minimizable_paths: Array[String] = [
		"UILayer/AlmanacPanel",
		"UILayer/InventoryUI",
		"UILayer/RecipePicker",
		"UILayer/ShopUI",
	]
	for p: String in minimizable_paths:
		var n: CanvasItem = get_node_or_null(p) as CanvasItem
		if n:
			n.visible = false

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
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color(0.05, 0.06, 0.08, 0.88)
	wsb.set_border_width_all(1)
	wsb.border_color = Color(0.35, 0.32, 0.22)
	wsb.content_margin_left = 6
	wsb.content_margin_top = 6
	wsb.content_margin_right = 6
	wsb.content_margin_bottom = 6
	for tab_panel_name: String in ["Events", "Quests"]:
		var tp: Panel = ui_layer.get_node_or_null("RightJournalTabs/%s" % tab_panel_name) as Panel
		if tp:
			tp.add_theme_stylebox_override("panel", wsb.duplicate() as StyleBoxFlat)
	if world_event_feed_label:
		world_event_feed_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		world_event_feed_label.add_theme_constant_override("shadow_offset_x", 1)
		world_event_feed_label.add_theme_constant_override("shadow_offset_y", 1)
	if ai_config_button:
		ai_config_button.tooltip_text = "L: events / quests log"
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
		hud_bg.offset_right = 432.0
		hud_bg.offset_bottom = 124.0
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
		q_bg.visible = false
		q_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q_bg.z_index = 51
		q_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		q_bg.offset_left = 924.0
		q_bg.offset_top = 44.0
		q_bg.offset_right = 1276.0
		q_bg.offset_bottom = 632.0
		var qsb := StyleBoxFlat.new()
		qsb.bg_color = Color(0.04, 0.06, 0.08, 0.56)
		qsb.set_border_width_all(1)
		qsb.border_color = Color(0.26, 0.34, 0.32, 0.92)
		q_bg.add_theme_stylebox_override("panel", qsb)
		ui_layer.add_child(q_bg)
		ui_layer.move_child(q_bg, 0)
	if ui_layer and _journal_modal_dim == null:
		var dim := ColorRect.new()
		dim.name = "JournalModalDim"
		dim.visible = false
		dim.color = Color(0.02, 0.03, 0.05, 0.58)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.z_index = 50
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.offset_left = 0.0
		dim.offset_top = 0.0
		dim.offset_right = 0.0
		dim.offset_bottom = 0.0
		dim.gui_input.connect(_on_journal_modal_dim_gui_input)
		ui_layer.add_child(dim)
		ui_layer.move_child(dim, 0)
		_journal_modal_dim = dim
	if right_journal_tabs:
		right_journal_tabs.z_index = 52
	if ui_layer and ui_layer.get_node_or_null("StoryHotspotHud") == null:
		var spot_lbl := Label.new()
		spot_lbl.name = "StoryHotspotHud"
		spot_lbl.visible = false
		spot_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spot_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		spot_lbl.offset_left = -300.0
		spot_lbl.offset_top = 130.0
		spot_lbl.offset_right = -10.0
		spot_lbl.offset_bottom = 196.0
		spot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		spot_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spot_lbl.add_theme_font_size_override("font_size", 11)
		spot_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 0.96))
		spot_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		spot_lbl.add_theme_constant_override("shadow_offset_x", 1)
		spot_lbl.add_theme_constant_override("shadow_offset_y", 1)
		ui_layer.add_child(spot_lbl)
	if ui_layer and ui_layer.get_node_or_null("ActivityZoneBackdrop") == null:
		var a_bg := Panel.new()
		a_bg.name = "ActivityZoneBackdrop"
		a_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
		a_bg.offset_left = 8.0
		a_bg.offset_top = 128.0
		a_bg.offset_right = 416.0
		a_bg.offset_bottom = 158.0
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
	_apply_journal_tab_titles()
	_apply_seasonal_hud_tint()
	_sync_hud_backdrop_layout()


func _sync_hud_backdrop_layout() -> void:
	if not ui_layer:
		return
	var h: Panel = ui_layer.get_node_or_null("HUDBackdrop") as Panel
	if h:
		h.offset_left = 4.0
		h.offset_top = 4.0
		h.offset_right = 432.0
		h.offset_bottom = 124.0
	var qb: Panel = ui_layer.get_node_or_null("QuestLogBackdrop") as Panel
	if qb:
		qb.offset_left = 924.0
		qb.offset_top = 44.0
		qb.offset_right = 1276.0
		qb.offset_bottom = 632.0
	var ab: Panel = ui_layer.get_node_or_null("ActivityZoneBackdrop") as Panel
	if ab:
		ab.offset_left = 8.0
		ab.offset_top = 128.0
		ab.offset_right = 416.0
		ab.offset_bottom = 158.0


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
	var mine_tb: Button = get_node_or_null("MineArea/MineBandsToggle") as Button
	if mine_tb:
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color(0.11, 0.12, 0.15, 0.92)
		msb.set_border_width_all(1)
		msb.border_color = Color(0.38, 0.34, 0.24)
		mine_tb.flat = true
		for st: String in ["normal", "hover", "pressed"]:
			mine_tb.add_theme_stylebox_override(st, msb.duplicate() as StyleBoxFlat)
	_refresh_mine_area_locale()


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
	if WeatherSystem and ImmersionConfig:
		var wm: Color = ImmersionConfig.get_ui_weather_accent_mult(WeatherSystem.current_weather)
		accent = Color(
			clampf(accent.r * wm.r, 0.0, 1.0),
			clampf(accent.g * wm.g, 0.0, 1.0),
			clampf(accent.b * wm.b, 0.0, 1.0),
			clampf(accent.a * wm.a, 0.0, 1.0)
		)

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
	for tab_panel_name: String in ["Events", "Quests"]:
		var tp: Panel = ui_layer.get_node_or_null("RightJournalTabs/%s" % tab_panel_name) as Panel
		if tp:
			_panel_set_season_border(tp, accent)
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
	var mine_band_btn: Button = get_node_or_null("MineArea/MineBandsToggle") as Button
	_button_set_season_border(mine_band_btn, accent)
	var quick_tip_bg: Panel = ui_layer.get_node_or_null("QuickTipBackdrop") as Panel
	if quick_tip_bg:
		var qtp: StyleBoxFlat = quick_tip_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if qtp:
			qtp.border_color = accent
			quick_tip_bg.add_theme_stylebox_override("panel", qtp)
	if quest_log_label:
		quest_log_label.add_theme_color_override("font_color", Color(text_col.r, text_col.g, text_col.b, 0.92))
	if day_label:
		day_label.add_theme_color_override("font_color", Color(text_col.r, text_col.g, text_col.b, 0.95))
	var inv_ui_accent = ui_layer.get_node_or_null("InventoryUI")
	if inv_ui_accent and inv_ui_accent.has_method("set_seasonal_accent"):
		inv_ui_accent.set_seasonal_accent(accent)
	if season_label:
		season_label.add_theme_color_override("font_color", text_col)
	_sync_hud_backdrop_layout()

func _record_barn_collect_line(entry: Dictionary) -> void:
	var item_id: String = str(entry.get("item_id", ""))
	var qty: int = int(entry.get("qty", 1))
	var animal_type: String = str(entry.get("animal_type", ""))
	var tpl: Dictionary = ItemDatabase.get_item(item_id) if ItemDatabase else {}
	var item_name: String = str(tpl.get("name", item_id))
	var animal_label: String = UITextCatalog.get_text("barn", animal_type)
	if animal_label.is_empty():
		animal_label = animal_type
	record_world_event(UITextCatalog.format_text("history", "barn_collected", {
		"item": item_name,
		"qty": qty,
		"animal": animal_label
	}))


func _handle_barn_interact() -> void:
	if not LivestockManager or not player:
		return
	var col: Dictionary = LivestockManager.try_collect_all()
	if bool(col.get("inventory_full", false)):
		var tip_inv: String = UITextCatalog.get_text("quick_tip", "barn_inventory_full")
		if not tip_inv.is_empty():
			show_quick_tip(tip_inv)
		for ent in col.get("collected", []):
			if ent is Dictionary:
				_record_barn_collect_line(ent as Dictionary)
		return
	if bool(col.get("ok", false)):
		for ent2 in col.get("collected", []):
			if ent2 is Dictionary:
				_record_barn_collect_line(ent2 as Dictionary)
		var tip_parts: PackedStringArray = col.get("tips", PackedStringArray())
		if tip_parts.size() > 0:
			show_quick_tip(", ".join(tip_parts))
		return
	if bool(col.get("empty", false)):
		var buy: Dictionary = LivestockManager.try_buy_next_type()
		var why: String = str(buy.get("message", ""))
		if bool(buy.get("ok", false)):
			var tid: String = str(buy.get("type", ""))
			var animal_label2: String = UITextCatalog.get_text("barn", tid)
			if animal_label2.is_empty():
				animal_label2 = tid
			var cost: int = int(buy.get("cost", 0))
			record_world_event(UITextCatalog.format_text("history", "barn_bought", {
				"animal": animal_label2,
				"cost": cost
			}))
			show_quick_tip(UITextCatalog.format_text("quick_tip", "barn_bought", {
				"animal": animal_label2,
				"cost": cost
			}))
		elif why == "cant_afford":
			show_quick_tip(UITextCatalog.format_text("quick_tip", "barn_cant_afford", {
				"cost": int(buy.get("cost", 0))
			}))
		elif why == "all_full":
			var tip_full: String = UITextCatalog.get_text("quick_tip", "barn_all_full")
			if not tip_full.is_empty():
				show_quick_tip(tip_full)
		return
	var tip_wait: String = UITextCatalog.get_text("quick_tip", "barn_nothing_ready")
	if not tip_wait.is_empty():
		show_quick_tip(tip_wait)


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
	if GameZones.contains_barn(player.global_position):
		activity_zone_label.text = UITextCatalog.get_activity_text("barn")
		return
	if farm_manager and FarmTierCatalog:
		var fr: Rect2 = GameZones.rect_farm_upgrade()
		if fr.has_point(player.global_position):
			var ft: int = farm_manager.farm_tier
			var nm: String = FarmTierCatalog.localized_display_name(ft)
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
		var hr: Rect2 = GameZones.rect_house_upgrade()
		if hr.has_point(player.global_position):
			var lv: int = int(GameManager.player_data.get("house_level", 1))
			var cur: Dictionary = BuildingUpgradeCatalog.level_def(lv)
			var nm: String = BuildingUpgradeCatalog.localized_level_name(lv)
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
	var best: Dictionary = _pick_best_valid_bundle()
	if not best.is_empty():
		_apply_save_bundle(best["bundle"])
		return true
	# Legacy fallback: migrate old single-file save on next write.
	if FileAccess.file_exists(GameSaveService.GAME_SAVE_BUNDLE_PATH):
		var f: FileAccess = FileAccess.open(GameSaveService.GAME_SAVE_BUNDLE_PATH, FileAccess.READ)
		if f:
			var legacy: Variant = f.get_var()
			f.close()
			if legacy is Dictionary and int(legacy.get("version", 0)) >= 2:
				_log_tamper_event("legacy_load_unsigned", {"path": GameSaveService.GAME_SAVE_BUNDLE_PATH})
				_apply_save_bundle(legacy)
				return true
	return false


func _pick_best_valid_bundle() -> Dictionary:
	var best_seq: int = -1
	var best: Dictionary = {}
	for p in [GameSaveService.GAME_SAVE_SLOT_A_PATH, GameSaveService.GAME_SAVE_SLOT_B_PATH]:
		if not FileAccess.file_exists(p):
			continue
		var f: FileAccess = FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		var raw: Variant = f.get_var()
		f.close()
		if not (raw is Dictionary):
			continue
		var b: Dictionary = raw
		if int(b.get("version", 0)) < 2:
			continue
		if not GameSaveService.verify_bundle_signature(b):
			_log_tamper_event("signature_mismatch", {"path": p})
			continue
		var seq: int = int(b.get("save_seq", 0))
		if seq >= best_seq:
			best_seq = seq
			best = {"path": p, "bundle": b, "seq": seq}
	return best


func _log_tamper_event(event_name: String, data: Dictionary = {}) -> void:
	if GameSaveService:
		GameSaveService.log_tamper_event(event_name, data)


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
		_clamp_player_stamina_and_gold()
	if bundle.get("farm") is Dictionary:
		var fd: Dictionary = bundle["farm"]
		if farm_manager:
			farm_manager.load_farm_data(fd)
		elif FarmStateCache:
			FarmStateCache.set_from_dict(fd)
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
	if GameManager:
		GameManager.journal_world_event_feed.clear()
		for item in world_event_feed:
			GameManager.journal_world_event_feed.append(str(item))
		GameManager.journal_active_story_hotspot = active_story_hotspot.duplicate(true)
	if bundle.get("gathering_almanac") is Dictionary and GatheringAlmanac:
		GatheringAlmanac.apply_save_snapshot(bundle["gathering_almanac"])
	if bundle.get("npc_traits") is Dictionary and NPCTraitSystem:
		NPCTraitSystem.load_snapshot(bundle["npc_traits"])
	if WorldRouter:
		WorldRouter.set_world_state_from_bundle(bundle.get("world", {}))
	_validate_loaded_state()
	call_deferred("_refresh_story_hotspot_hud")

func _clamp_player_stamina_and_gold() -> void:
	if not GameManager:
		return
	var smax: float = maxf(1.0, float(GameManager.player_data.get("stamina_max", 100.0)))
	GameManager.player_data["stamina_max"] = smax
	var scur: float = float(GameManager.player_data.get("stamina", smax))
	GameManager.player_data["stamina"] = clampf(scur, 0.0, smax)
	var g: int = int(GameManager.player_data.get("gold", 0))
	GameManager.player_data["gold"] = maxi(0, g)
	var hpmax: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
	GameManager.player_data["hp_max"] = hpmax
	var hp: float = float(GameManager.player_data.get("hp", hpmax))
	GameManager.player_data["hp"] = clampf(hp, 0.0, hpmax)


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
	if src_version < 4:
		if not GameManager.player_data.has("history_log"):
			GameManager.player_data["history_log"] = []
		if not GameManager.player_data.has("profile"):
			GameManager.player_data["profile"] = {
				"display_name": "",
				"gender": "neutral",
				"personality": "kind",
				"hobbies": [],
				"avatar_id": 0,
				"body_type": 0,
				"hairstyle_id": 0,
				"outfit_id": 0,
				"confirmed": true
			}
	if src_version < 5:
		if not GameManager.player_data.has("reward_ledger"):
			GameManager.player_data["reward_ledger"] = {}
	if src_version < 6:
		if not GameManager.player_data.has("last_spawn_id"):
			GameManager.player_data["last_spawn_id"] = "default"


func _build_save_bundle() -> Dictionary:
	var farm_block: Dictionary = {}
	if farm_manager:
		farm_block = farm_manager.save_farm_data()
	elif FarmStateCache:
		farm_block = FarmStateCache.get_snapshot()
	return GameSaveService.build_runtime_bundle(
		farm_block,
		world_event_feed,
		active_story_hotspot
	)


func _validate_loaded_state() -> void:
	if not GameManager:
		return
	_clamp_player_stamina_and_gold()
	if not GameManager.player_data.has("reward_ledger") or not (GameManager.player_data.get("reward_ledger") is Dictionary):
		GameManager.player_data["reward_ledger"] = {}
		_log_tamper_event("repair_reward_ledger_missing")
	if farm_manager and FarmTierCatalog:
		var old_tier: int = int(farm_manager.farm_tier)
		farm_manager.farm_tier = clampi(old_tier, 1, maxi(1, FarmTierCatalog.max_tier()))
		if old_tier != farm_manager.farm_tier:
			_log_tamper_event("repair_farm_tier", {"from": old_tier, "to": farm_manager.farm_tier})
	if BuildingUpgradeCatalog:
		var old_house: int = int(GameManager.player_data.get("house_level", 1))
		var fixed_house: int = clampi(old_house, 1, BuildingUpgradeCatalog.max_level())
		GameManager.player_data["house_level"] = fixed_house
		if old_house != fixed_house:
			_log_tamper_event("repair_house_level", {"from": old_house, "to": fixed_house})
	if InventoryManager and ItemDatabase:
		var repaired_slots: int = 0
		for i in range(InventoryManager.INVENTORY_SIZE):
			var it = InventoryManager.inventory[i]
			if it == null:
				continue
			if not (it is Dictionary):
				InventoryManager.inventory[i] = null
				repaired_slots += 1
				continue
			var d: Dictionary = it
			var iid: String = str(d.get("id", "")).strip_edges()
			var tpl: Dictionary = ItemDatabase.get_item(iid)
			if iid.is_empty() or tpl.is_empty():
				InventoryManager.inventory[i] = null
				repaired_slots += 1
				continue
			var st: int = int(d.get("stack", 0))
			var mx: int = maxi(1, int(tpl.get("max_stack", 99)))
			var fixed_st: int = clampi(st, 1, mx)
			if fixed_st != st:
				d["stack"] = fixed_st
				InventoryManager.inventory[i] = d
				repaired_slots += 1
		if repaired_slots > 0:
			InventoryManager.inventory_updated.emit()
			_log_tamper_event("repair_inventory_slots", {"count": repaired_slots})
	if QuestSystem:
		var repaired: int = 0
		for qid in QuestSystem.completed_quests:
			if QuestSystem.active_quests.has(qid):
				QuestSystem.active_quests.erase(qid)
				repaired += 1
			if QuestSystem.quests.has(qid):
				QuestSystem.quests[qid]["status"] = QuestSystem.QuestStatus.COMPLETED
		if repaired > 0:
			_log_tamper_event("repair_quest_state_overlap", {"count": repaired})


func _is_headless_runtime() -> bool:
	return DisplayServer.get_name().to_lower().contains("headless")


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
		QuestSystem.start_quest("intro_combat")
		QuestSystem.start_quest("earn_gold")
	
	if DailyNarrativeSystem and not _is_headless_runtime():
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		if not is_inside_tree():
			return
		if not narrative.is_empty():
			var nt: String = str(narrative.get("title", "A new day begins"))
			var nd: String = "Today's story: " + nt
			if UITextCatalog:
				nd = UITextCatalog.format_text("history", "narrative_seed", {"title": nt})
			show_dialogue(nd)
			_record_history("narrative_seed", {"title": nt})
			_apply_narrative_daily_quest(narrative)
			if QuestSystem and QuestSystem.has_method("activate_chain_for_narrative"):
				QuestSystem.activate_chain_for_narrative(narrative)
			if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("maybe_generate_for_day"):
				await AgenticContentOrchestrator.maybe_generate_for_day(narrative)
				if is_inside_tree() and AgenticContentOrchestrator.has_method("get_runtime_status_line"):
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
	var nm: String = UITextCatalog.get_item_display_name(item_id) if UITextCatalog else str(item.get("name", "Food"))
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
	if GameManager:
		GameManager.player_data["harvest_count_today"] = int(GameManager.player_data.get("harvest_count_today", 0)) + count
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
	var tile_coords: Vector2i = Vector2i.ZERO
	if tilemap:
		tile_coords = tilemap.local_to_map(tile_position)

	# Check for NPC interaction first
	if current_npc:
		var dialogue = current_npc.interact()
		show_dialogue(dialogue)
		if GameManager:
			GameManager.player_data["talk_count_today"] = int(GameManager.player_data.get("talk_count_today", 0)) + 1
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
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(0.85)
				_play_fx_fish()
				return
			var fish_msg: String = str(catch_result.get("message", ""))
			if catch_result.get("ok", false):
				show_dialogue(fish_msg)
				record_world_event(fish_msg)
				if GameManager:
					GameManager.player_data["fish_count_today"] = int(GameManager.player_data.get("fish_count_today", 0)) + 1
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.15)
				_play_fx_fish()
				return
			if not fish_msg.is_empty():
				show_dialogue(fish_msg)
				record_world_event("Fish: %s" % fish_msg)
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
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.0)
				var mine_hint: String = str(mine_result.get("hint", ""))
				if not mine_hint.is_empty():
					show_quick_tip(mine_hint)
				_play_fx_mine()
				return
			if not mine_msg.is_empty():
				show_dialogue(mine_msg)
				record_world_event("Mine: %s" % mine_msg)
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
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(1.0)
				_play_fx_chop()
				return
			if not ch_msg.is_empty():
				show_dialogue(ch_msg)
				record_world_event("Chop: %s" % ch_msg)
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

	# Farming interactions (tilemap + FarmManager live in `world_farm.tscn` after B2)
	if selected_item and farm_manager:
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
	_writeback_player_behavior_digest(new_day)
	_apply_rc_beginner_guidance()
	if GameManager:
		var defeats_today: int = int(GameManager.player_data.get("daily_defeats", 0))
		var daily_kills: int = int(GameManager.player_data.get("combat_kills_today", 0))
		var daily_elites: int = int(GameManager.player_data.get("combat_elites_today", 0))
		var peak_streak: int = int(GameManager.player_data.get("combat_peak_streak_today", 0))
		var rating: String = _combat_daily_rating(daily_kills, daily_elites, peak_streak, defeats_today)
		if GameManager:
			if rating == "S":
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + 55
				show_quick_tip("Daily S rating reward +55g", 1.0)
				record_world_event("Daily combat S reward claimed (+55g).")
			elif rating == "A":
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + 30
				show_quick_tip("Daily A rating reward +30g", 0.9)
				record_world_event("Daily combat A reward claimed (+30g).")
		if daily_kills >= 12 and defeats_today == 0 and not bool(GameManager.player_data.get("combat_badge_flawless_day", false)):
			GameManager.player_data["combat_badge_flawless_day"] = true
			record_world_event("Badge unlocked: Flawless Combat Day.")
			show_quick_tip("Badge: Flawless Combat Day", 1.2)
		record_world_event("Combat recap: kills %d, elites %d, peak streak %d." % [daily_kills, daily_elites, peak_streak])
		record_world_event("Combat rating today: %s" % rating)
		show_quick_tip("Daily combat rating: %s" % rating, 1.0)
		GameManager.player_data["combat_kills_today"] = 0
		GameManager.player_data["combat_elites_today"] = 0
		GameManager.player_data["daily_defeats"] = 0
		GameManager.player_data["combat_peak_streak_today"] = 0
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
	if DailyNarrativeSystem and _consume_daily_budget("narrative") and not _is_headless_runtime():
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		if not is_inside_tree():
			return
		record_world_event("New day, new story seed is ready.")
		_apply_narrative_daily_quest(narrative)
		if QuestSystem and QuestSystem.has_method("activate_chain_for_narrative") and _consume_daily_budget("chain_activation"):
			QuestSystem.activate_chain_for_narrative(narrative)
		if AgenticContentOrchestrator and AgenticContentOrchestrator.has_method("maybe_generate_for_day"):
			await AgenticContentOrchestrator.maybe_generate_for_day(narrative)
			if is_inside_tree() and AgenticContentOrchestrator.has_method("get_runtime_status_line"):
				record_world_event(AgenticContentOrchestrator.get_runtime_status_line())


func _apply_rc_beginner_guidance() -> void:
	if not GameManager:
		return
	var day: int = int(GameManager.player_data.get("day", 1))
	if day > 3:
		return
	var shown_key: String = "rc_guidance_day_%d" % day
	if bool(GameManager.player_data.get(shown_key, false)):
		return
	GameManager.player_data[shown_key] = true
	var line: String = ""
	match day:
		1:
			line = "Day 1 goal: talk to 2 villagers, plant seeds, sleep before midnight."
		2:
			line = "Day 2 goal: earn 200g and visit one extra region portal."
		3:
			line = "Day 3 goal: finish one quest and trigger one world event."
		_:
			line = ""
	if line.is_empty():
		return
	record_world_event(line)
	show_quick_tip(line, 2.2)


func _writeback_player_behavior_digest(new_day: int) -> void:
	if not GameManager:
		return
	var kills: int = int(GameManager.player_data.get("combat_kills_today", 0))
	var harvests: int = int(GameManager.player_data.get("harvest_count_today", 0))
	var talks: int = int(GameManager.player_data.get("talk_count_today", 0))
	var fish: int = int(GameManager.player_data.get("fish_count_today", 0))
	var style: String = "balanced"
	if kills >= 8 and kills >= harvests:
		style = "combat_focused"
	elif harvests >= 6 and harvests >= kills:
		style = "farming_focused"
	elif talks >= 6:
		style = "social_focused"
	elif fish >= 4:
		style = "fishing_focused"
	GameManager.player_data["player_style_last_day"] = style
	var line: String = "Yesterday style: %s (kills %d / harvest %d / talk %d / fish %d)." % [style, kills, harvests, talks, fish]
	record_world_event(line)
	if AIQuestSystem:
		AIQuestSystem.track_event("player_style_digest", {
			"day": int(new_day) - 1,
			"style": style,
			"kills": kills,
			"harvests": harvests,
			"talks": talks,
			"fish": fish
		})
	if NPCMemorySystem:
		for npc_id in ["pierre", "abigail", "lewis"]:
			NPCMemorySystem.record_event(npc_id, line, 0.72, "curious", [style])
	GameManager.player_data["harvest_count_today"] = 0
	GameManager.player_data["talk_count_today"] = 0
	GameManager.player_data["fish_count_today"] = 0

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
	var qtitle: String = "Quests"
	var qnone: String = "(none active)"
	var qchains: String = "-- Chains --"
	if UITextCatalog:
		qtitle = UITextCatalog.get_text("hud", "quest_title")
		qnone = UITextCatalog.get_text("hud", "quest_none")
		qchains = UITextCatalog.get_text("hud", "quest_chains_header")
	if QuestSystem.active_quests.is_empty():
		var idle_text: String = "%s\n%s" % [qtitle, qnone]
		if not managed_chain_status_banner.is_empty():
			idle_text += "\n" + managed_chain_status_banner
		quest_log_label.text = idle_text
		_fit_quest_log_content_height()
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
			if UITextCatalog:
				suffix = " " + UITextCatalog.format_text("hud", "quest_steps_multi", {"n": obj_list.size()})
			else:
				suffix = " (%d steps)" % obj_list.size()
		var tag: String = ""
		if str(q.get("source", "")) == "daily_narrative":
			var ndk: String = str(q.get("narrative_day_key", ""))
			if UITextCatalog:
				if not ndk.is_empty():
					tag = UITextCatalog.format_text("hud", "quest_tag_story_day", {"ndk": ndk})
				else:
					tag = UITextCatalog.get_text("hud", "quest_tag_story")
			else:
				if not ndk.is_empty():
					tag = " [Story %s]" % ndk
				else:
					tag = " [Story]"
		elif str(q.get("source", "")) == "managed_story_chain":
			var st: String = QuestSystem.get_managed_chain_status_tag(str(qid)) if QuestSystem and QuestSystem.has_method("get_managed_chain_status_tag") else ""
			if UITextCatalog:
				if st == "urgent":
					tag = UITextCatalog.get_text("hud", "quest_tag_chain_urgent")
				elif st == "failed":
					tag = UITextCatalog.get_text("hud", "quest_tag_chain_failed")
				else:
					tag = UITextCatalog.get_text("hud", "quest_tag_chain_active")
			else:
				if st == "urgent":
					tag = " [Chain: Urgent]"
				elif st == "failed":
					tag = " [Chain: Failed]"
				else:
					tag = " [Chain: Active]"
		elif str(q.get("source", "")) == "managed_recovery":
			tag = UITextCatalog.get_text("hud", "quest_tag_recovery") if UITextCatalog else " [Recovery]"
		var out_line: String = "• %s%s%s" % [title, suffix, tag]
		if str(q.get("source", "")) == "managed_story_chain":
			chain_lines.append(out_line)
		else:
			regular_lines.append(out_line)
	lines.append_array(regular_lines)
	if not chain_lines.is_empty():
		lines.append(qchains)
		lines.append_array(chain_lines)
	var title_text: String = qtitle + "\n"
	if not managed_chain_status_banner.is_empty():
		title_text += managed_chain_status_banner + "\n"
	quest_log_label.text = title_text + "\n".join(lines)
	_fit_quest_log_content_height()


func _fit_quest_log_content_height() -> void:
	if not quest_log_label:
		return
	var line_h: int = maxi(12, quest_log_label.get_line_height())
	var lines: int = maxi(1, quest_log_label.text.split("\n").size())
	var pad: int = 20
	quest_log_label.custom_minimum_size.y = mini(520, maxi(120, lines * line_h + pad))


func _try_farm_tier_upgrade() -> void:
	if not farm_manager or not FarmTierCatalog or not player:
		return
	var fr: Rect2 = GameZones.rect_farm_upgrade()
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
	var hr: Rect2 = GameZones.rect_house_upgrade()
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
	var nm: String = BuildingUpgradeCatalog.localized_level_name(lv + 1)
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
	if not GameZones.can_open_shop_at(player.global_position):
		show_quick_tip(UITextCatalog.get_text("quick_tip", "shop_open_near_pierre"))
		return
	shop_ui.open_shop()
	if GatheringSfx:
		GatheringSfx.play_shop_enter()


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
		var done_msg: String = "Quest completed: " + str(title)
		if UITextCatalog:
			done_msg = UITextCatalog.format_text("hud", "quest_completed", {"title": str(title)})
		show_dialogue(done_msg)
		var reward_line: String = _format_quest_material_rewards_line(quest_id, quest_data)
		if not reward_line.is_empty():
			record_world_event(reward_line)
			show_quick_tip(reward_line, 1.75)
		if _is_combat_quest(quest_data):
			play_screen_shake(4.8)
			show_quick_tip("Combat objective complete!", 1.0)
			record_world_event("Combat triumph: %s." % str(quest_data.get("title", quest_id)))
			_combat_quest_chain += 1
			if GameManager and _combat_quest_chain >= 2:
				var chain_bonus: int = 25 + (_combat_quest_chain - 2) * 10
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + chain_bonus
				show_quick_tip("Combat chain x%d +%dg" % [_combat_quest_chain, chain_bonus], 1.0)
				record_world_event("Combat quest chain reward: +%dg." % chain_bonus)
		_apply_story_completion_feedback(quest_data)
		if quest_id == "intro_combat":
			QuestSystem.start_quest("deep_mine_hunt")
			record_world_event("New combat contract unlocked: Deep Mine Hunt.")
		elif quest_id == "deep_mine_hunt":
			QuestSystem.start_quest("elite_slayer")
			record_world_event("New combat contract unlocked: Elite Slayer.")
		elif quest_id == "elite_slayer":
			QuestSystem.start_quest("streak_hunter")
			record_world_event("New combat contract unlocked: Streak Hunter.")
		elif quest_id == "streak_hunter":
			QuestSystem.start_quest("elite_slayer_ii")
			record_world_event("New combat contract unlocked: Elite Slayer II.")
		elif quest_id == "elite_slayer_ii":
			QuestSystem.start_quest("combat_mastery")
			record_world_event("New combat contract unlocked: Combat Mastery.")
		elif quest_id == "combat_mastery":
			QuestSystem.start_quest("flawless_miner")
			record_world_event("New combat contract unlocked: Flawless Miner.")
	_refresh_quest_log()


func _is_combat_quest(quest_data: Dictionary) -> bool:
	var objectives: Array = quest_data.get("objectives", [])
	for o in objectives:
		if not (o is Dictionary):
			continue
		var t: String = str((o as Dictionary).get("type", ""))
		if t == "enemy_kill":
			return true
	return false


func _on_quest_failed(quest_id: String, reason: String) -> void:
	_combat_quest_chain = 0
	var rs: String = reason if not reason.is_empty() else "unknown"
	var line: String = "Quest failed: %s (%s)" % [quest_id, rs]
	if UITextCatalog:
		line = UITextCatalog.format_text("hud", "quest_failed_line", {"id": quest_id, "reason": rs})
	record_world_event(line)
	var tip: String = "Quest failed: " + quest_id
	if UITextCatalog:
		tip = UITextCatalog.format_text("hud", "quest_failed_tip", {"id": quest_id})
	show_quick_tip(tip, 1.8)
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

func _format_quest_material_rewards_line(quest_id: String, quest_data: Dictionary) -> String:
	var reward_data: Variant = quest_data.get("reward", {})
	if not (reward_data is Dictionary):
		return ""
	var rd: Dictionary = reward_data as Dictionary
	var parts: Array[String] = []
	if rd.has("gold"):
		var g: int = int(rd.get("gold", 0))
		if g > 0:
			parts.append("+%dg" % g)
	if rd.has("items"):
		var raw_items: Variant = rd.get("items", [])
		if raw_items is Array:
			for item_str in raw_items:
				var ps: PackedStringArray = str(item_str).split(":")
				var item_id: String = str(ps[0]).strip_edges()
				if item_id.is_empty():
					continue
				var count: int = int(ps[1]) if ps.size() > 1 else 1
				var nm: String = item_id
				if ItemDatabase:
					var tpl: Dictionary = ItemDatabase.get_item(item_id)
					if not tpl.is_empty():
						nm = str(tpl.get("name", item_id))
				parts.append("%s x%d" % [nm, count])
	if parts.is_empty():
		return ""
	return "Quest loot [%s]: %s" % [str(quest_data.get("id", quest_id)), ", ".join(parts)]

func _on_relationship_evolved(npc_id: String, other_id: String, new_level: int) -> void:
	if str(other_id) != "player":
		return
	var now: float = float(Time.get_unix_time_from_system())
	var last: float = float(_visible_feed_last.get("rel", 0.0))
	if now - last < 4.0:
		return
	_visible_feed_last["rel"] = now
	var who: String = _resolve_npc_display_name(npc_id)
	var line: String = "Bond · %s → tier %d." % [who, clampi(int(new_level), 0, 10)]
	record_world_event(line)
	show_quick_tip(line, 1.8)

func _on_preference_learned_memory(npc_id: String, preference_key: String) -> void:
	var now: float = float(Time.get_unix_time_from_system())
	var last: float = float(_visible_feed_last.get("pref", 0.0))
	if now - last < 5.0:
		return
	_visible_feed_last["pref"] = now
	var who: String = _resolve_npc_display_name(npc_id)
	var pk: String = str(preference_key).replace("_", " ").strip_edges()
	if pk.is_empty():
		pk = "something about you"
	var line: String = "Noted · %s picked up: %s." % [who, pk]
	record_world_event(line)
	show_quick_tip(line, 1.7)

func _on_preference_learned_personality(npc_id: String, category: String, item: String) -> void:
	var now: float = float(Time.get_unix_time_from_system())
	var last: float = float(_visible_feed_last.get("pref", 0.0))
	if now - last < 5.0:
		return
	_visible_feed_last["pref"] = now
	var who: String = _resolve_npc_display_name(npc_id)
	var item_id: String = str(item).strip_edges()
	var label: String = item_id
	if ItemDatabase and not item_id.is_empty():
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		if not tpl.is_empty():
			label = str(tpl.get("name", item_id))
	var cat: String = str(category).strip_edges()
	if cat.is_empty():
		cat = "gift"
	var line: String = "Preference · %s favors %s (%s)." % [who, label, cat]
	record_world_event(line)
	show_quick_tip(line, 1.7)

func _on_player_visible_market_note(line: String) -> void:
	if line.is_empty():
		return
	var now: float = float(Time.get_unix_time_from_system())
	var last: float = float(_visible_feed_last.get("market", 0.0))
	if now - last < 1.8:
		return
	_visible_feed_last["market"] = now
	record_world_event(line)
	show_quick_tip(line, 2.0)
	if AIQuestSystem:
		AIQuestSystem.track_event("market_note", {"line": line})


func _on_ai_world_event_started(event_id: String, event_info: Dictionary) -> void:
	var title: String = str(event_info.get("name", event_id)).strip_edges()
	var cat: String = str(event_info.get("category", "world")).strip_edges()
	if title.is_empty():
		title = event_id
	var line: String = "World event · %s [%s]" % [title, cat]
	record_world_event(line)
	show_quick_tip(line, 1.7)
	if AIQuestSystem:
		AIQuestSystem.track_event("world_event_started", {
			"event_id": event_id,
			"category": cat,
			"name": title
		})


func _on_ai_world_state_changed(change_type: String, change_data: Dictionary) -> void:
	var line: String = "World state shift · %s." % str(change_type)
	record_world_event(line)
	if AIQuestSystem:
		AIQuestSystem.track_event("world_state_changed", {
			"type": change_type,
			"data": change_data.duplicate(true)
		})

func _on_visible_memory_added(npc_id: String, memory: Variant) -> void:
	if memory == null:
		return
	var importance: float = 0.5
	var content: String = ""
	if memory is NPCMemorySystem.Memory:
		var mem: NPCMemorySystem.Memory = memory
		importance = float(mem.importance)
		content = str(mem.content)
	else:
		return
	if importance < 0.62:
		return
	var now2: float = float(Time.get_unix_time_from_system())
	var last2: float = float(_visible_feed_last.get("memory", 0.0))
	if now2 - last2 < 5.0:
		return
	_visible_feed_last["memory"] = now2
	if content.length() > 96:
		content = content.substr(0, 93) + "..."
	var who: String = _resolve_npc_display_name(npc_id)
	var mem_line: String = "Memory · %s: %s" % [who, content]
	record_world_event(mem_line)
	show_quick_tip(mem_line, 1.85)

func _on_visible_emotion_changed(npc_id: String, new_emotion: int, intensity: float) -> void:
	var key: String = "em_%s" % npc_id
	var now3: float = float(Time.get_unix_time_from_system())
	var last3: float = float(_visible_feed_last.get(key, 0.0))
	if now3 - last3 < 6.0:
		return
	_visible_feed_last[key] = now3
	var label: String = _basic_emotion_label(new_emotion)
	var who2: String = _resolve_npc_display_name(npc_id)
	var pct: int = clampi(int(round(intensity * 100.0)), 0, 100)
	var em_line: String = "Mood · %s feels %s (%d%%)." % [who2, label, pct]
	record_world_event(em_line)
	show_quick_tip(em_line, 1.75)
	if NPCAudioManager:
		NPCAudioManager.play_basic_emotion_sting(npc_id, new_emotion, intensity)

func _resolve_npc_display_name(npc_id: String) -> String:
	var nid: String = str(npc_id).strip_edges()
	if nid.is_empty():
		return "Someone"
	if EnhancedPersonalitySystem and EnhancedPersonalitySystem.has_method("get_npc_complete_profile"):
		var profile: Dictionary = EnhancedPersonalitySystem.get_npc_complete_profile(nid)
		if profile.has("basic_info"):
			var nm: String = str((profile["basic_info"] as Dictionary).get("name", "")).strip_edges()
			if not nm.is_empty():
				return nm
	return nid.capitalize()

func _basic_emotion_label(emotion: int) -> String:
	match emotion:
		NPCEmotionSystem.BasicEmotion.NEUTRAL:
			return "neutral"
		NPCEmotionSystem.BasicEmotion.HAPPY:
			return "happier"
		NPCEmotionSystem.BasicEmotion.SAD:
			return "sadder"
		NPCEmotionSystem.BasicEmotion.ANGRY:
			return "tense"
		NPCEmotionSystem.BasicEmotion.EXCITED:
			return "excited"
		NPCEmotionSystem.BasicEmotion.CALM:
			return "calm"
		NPCEmotionSystem.BasicEmotion.ANXIOUS:
			return "anxious"
		NPCEmotionSystem.BasicEmotion.GRATEFUL:
			return "grateful"
		NPCEmotionSystem.BasicEmotion.LONELY:
			return "lonely"
		NPCEmotionSystem.BasicEmotion.CONFIDENT:
			return "confident"
		NPCEmotionSystem.BasicEmotion.SHY:
			return "shy"
		NPCEmotionSystem.BasicEmotion.PLAYFUL:
			return "playful"
		NPCEmotionSystem.BasicEmotion.SERIOUS:
			return "serious"
		NPCEmotionSystem.BasicEmotion.ROMANTIC:
			return "warm"
		NPCEmotionSystem.BasicEmotion.NOSTALGIC:
			return "nostalgic"
	return "different"


func _combat_daily_rating(kills: int, elites: int, peak_streak: int, defeats: int) -> String:
	var score: int = kills + elites * 4 + peak_streak * 2 - defeats * 6
	if score >= 40:
		return "S"
	if score >= 26:
		return "A"
	if score >= 14:
		return "B"
	return "C"


func _season_index_from_name(season: String) -> int:
	match season.strip_edges().to_lower():
		"spring":
			return 0
		"summer":
			return 1
		"fall":
			return 2
		"winter":
			return 3
		_:
			return 0


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
		world_event_feed_label.text = UITextCatalog.get_text("hud", "world_feed_empty") if UITextCatalog else "No events yet."
	else:
		world_event_feed_label.text = "\n".join(world_event_feed)
	_fit_world_event_feed_content_height()


func _fit_world_event_feed_content_height() -> void:
	if not world_event_feed_label:
		return
	var line_h: int = maxi(12, world_event_feed_label.get_line_height())
	var lines: int = maxi(1, world_event_feed_label.text.split("\n").size())
	world_event_feed_label.custom_minimum_size.y = mini(900, maxi(120, lines * line_h + 20))


func _set_journal_popup_visible(open: bool) -> void:
	_journal_popup_open = open
	if _journal_modal_dim:
		_journal_modal_dim.visible = open
	var q_bg: Panel = ui_layer.get_node_or_null("QuestLogBackdrop") as Panel if ui_layer else null
	if q_bg:
		q_bg.visible = open
	if right_journal_tabs:
		right_journal_tabs.visible = open


func _toggle_event_quest_journal_popup() -> void:
	_set_journal_popup_visible(not _journal_popup_open)


func _on_journal_modal_dim_gui_input(event: InputEvent) -> void:
	if not _journal_popup_open:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_journal_popup_visible(false)


func _apply_journal_tab_titles() -> void:
	if not ui_layer:
		return
	var tabs: TabContainer = ui_layer.get_node_or_null("RightJournalTabs") as TabContainer
	if tabs == null or tabs.get_tab_count() < 2:
		return
	if UITextCatalog:
		tabs.set_tab_title(0, UITextCatalog.get_text("hud", "tab_events"))
		tabs.set_tab_title(1, UITextCatalog.get_text("hud", "tab_quests"))
	else:
		tabs.set_tab_title(0, "Events")
		tabs.set_tab_title(1, "Quests")


func _connect_mine_bands_toggle() -> void:
	var mbt: Button = get_node_or_null("MineArea/MineBandsToggle") as Button
	if mbt == null:
		return
	for p: String in ["MineArea/MineLabelSurface", "MineArea/MineLabelIron", "MineArea/MineLabelDeep", "MineArea/MineDivider1", "MineArea/MineDivider2"]:
		var n: Node = get_node_or_null(p)
		if n:
			n.visible = false
	mbt.set_block_signals(true)
	mbt.button_pressed = false
	mbt.set_block_signals(false)
	_refresh_mine_bands_button_text(false)
	if not mbt.toggled.is_connected(_on_mine_bands_toggled):
		mbt.toggled.connect(_on_mine_bands_toggled)


func _refresh_mine_bands_button_text(details_on: bool) -> void:
	var mbt: Button = get_node_or_null("MineArea/MineBandsToggle") as Button
	if mbt == null:
		return
	if UITextCatalog:
		mbt.text = UITextCatalog.get_text("hud", "mine_bands_hide") if details_on else UITextCatalog.get_text("hud", "mine_bands_show")
	else:
		mbt.text = "Hide ore labels" if details_on else "Show ore labels"


func _on_mine_bands_toggled(pressed: bool) -> void:
	for p: String in ["MineArea/MineLabelSurface", "MineArea/MineLabelIron", "MineArea/MineLabelDeep", "MineArea/MineDivider1", "MineArea/MineDivider2"]:
		var n: Node = get_node_or_null(p)
		if n:
			n.visible = pressed
	_refresh_mine_bands_button_text(pressed)


func _refresh_mine_area_locale() -> void:
	var mh: Label = get_node_or_null("MineArea/MineHint") as Label
	if mh and UITextCatalog:
		mh.text = UITextCatalog.get_text("hud", "mine_hint_short")
	var mbt: Button = get_node_or_null("MineArea/MineBandsToggle") as Button
	if mbt:
		_refresh_mine_bands_button_text(mbt.button_pressed)

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
	if GameManager:
		GameManager.ensure_progression_subtrees()
		GameManager.player_data["daily_narrative_snapshot"] = {
			"title": title,
			"summary": summary,
			"source": source,
			"id": nid,
			"day_key": "%d-%s-%d" % [
				int(GameManager.player_data.get("year", 1)),
				str(GameManager.player_data.get("season", "spring")),
				int(GameManager.player_data.get("day", 1))
			]
		}
	_emit_narrative_hotspot_hint(narrative_data)

func _on_narrative_backend_fallback(reason: String) -> void:
	_record_ai_fallback_event("daily_narrative", reason, "local_generator")

func _emit_narrative_hotspot_hint(narrative_data: Dictionary) -> void:
	var hotspot: Dictionary = _resolve_narrative_hotspot(narrative_data)
	if hotspot.is_empty():
		return
	active_story_hotspot = hotspot.duplicate(true)
	if GameManager and GameManager.player_data.get("daily_narrative_snapshot") is Dictionary:
		var snap: Dictionary = GameManager.player_data["daily_narrative_snapshot"] as Dictionary
		snap["hotspot_location"] = str(hotspot.get("location", ""))
		snap["hotspot_npc_id"] = str(hotspot.get("npc_id", ""))
		snap["hotspot_npc_name"] = str(hotspot.get("npc_name", ""))
	var place: String = str(hotspot.get("location", "town_square"))
	var npc_name: String = str(hotspot.get("npc_name", ""))
	var line: String = "Story clue: check %s." % place
	if not npc_name.is_empty():
		line = "Story clue: check %s and talk to %s." % [place, npc_name]
	record_world_event(line)
	show_quick_tip(line, 2.0)
	_refresh_story_hotspot_hud()


func _refresh_story_hotspot_hud() -> void:
	if not ui_layer:
		return
	var sh: Label = ui_layer.get_node_or_null("StoryHotspotHud") as Label
	if sh == null:
		return
	if active_story_hotspot.is_empty():
		sh.visible = false
		sh.text = ""
		return
	var loc: String = str(active_story_hotspot.get("location", ""))
	var nn: String = str(active_story_hotspot.get("npc_name", ""))
	var dayk: String = str(active_story_hotspot.get("day_key", ""))
	var line: String = ""
	if UITextCatalog:
		line = UITextCatalog.format_text("journal", "hotspot_hud_line", {
			"location": loc,
			"npc": nn,
			"day": dayk
		})
	if line.is_empty():
		line = "Story · %s" % loc
		if not nn.is_empty():
			line += " · %s" % nn
	sh.text = line
	sh.visible = true

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
	if not farm_manager:
		return
	for position in farm_manager.planted_crops:
		farm_manager.water_plant(position)

func _on_crop_planted(position, crop_id):
	QuestSystem.track_event("plant", {"crop_id": crop_id, "count": 1})

func _on_crop_harvested(position, crop_id, quantity):
	QuestSystem.track_event("harvest", {"crop_id": crop_id, "count": quantity})

func update_ui():
	var loc: String = LocaleSettings.get_locale() if LocaleSettings else "zh_CN"
	time_label.text = GameManager.get_time_string_localized(loc)
	if UITextCatalog:
		gold_label.text = UITextCatalog.format_text("hud", "gold", {"gold": GameManager.player_data.gold})
		if stamina_label:
			var s: float = float(GameManager.player_data.get("stamina", 100.0))
			var sm: float = float(GameManager.player_data.get("stamina_max", 100.0))
			var hp: float = float(GameManager.player_data.get("hp", 100.0))
			var hpm: float = float(GameManager.player_data.get("hp_max", 100.0))
			stamina_label.text = "%s | HP: %d / %d" % [
				UITextCatalog.format_text("hud", "stamina", {"cur": int(s), "max": int(sm)}),
				int(hp), int(hpm)
			]
		var wname: String = WeatherSystem.get_weather_name() if WeatherSystem else ""
		var wdisp: String = UITextCatalog.localized_weather_name(wname)
		if weather_label:
			weather_label.text = UITextCatalog.format_text("hud", "weather", {"name": wdisp})
		var season_key: String = str(GameManager.player_data.get("season", "spring"))
		if season_label:
			season_label.text = UITextCatalog.format_text("hud", "season", {"name": UITextCatalog.localized_season_name(season_key)})
		var day_part: String = UITextCatalog.format_text("hud", "day_year", {
			"day": GameManager.player_data.day,
			"year": GameManager.player_data.year
		})
		day_label.text = "%s  ·  %s  ·  %s" % [day_part, UITextCatalog.localized_season_name(season_key), wdisp]
	else:
		gold_label.text = "Gold: %d" % GameManager.player_data.gold
		if stamina_label:
			var s2: float = float(GameManager.player_data.get("stamina", 100.0))
			var sm2: float = float(GameManager.player_data.get("stamina_max", 100.0))
			var hp2: float = float(GameManager.player_data.get("hp", 100.0))
			var hpm2: float = float(GameManager.player_data.get("hp_max", 100.0))
			stamina_label.text = "Stamina: %d / %d | HP: %d / %d" % [int(s2), int(sm2), int(hp2), int(hpm2)]
		if weather_label:
			weather_label.text = "Weather: %s" % WeatherSystem.get_weather_name()
		if season_label:
			season_label.text = "Season: %s" % GameManager.player_data.season.capitalize()
		var wn2: String = WeatherSystem.get_weather_name() if WeatherSystem else ""
		day_label.text = "Day %d, Year %d  ·  %s  ·  %s" % [
			GameManager.player_data.day,
			GameManager.player_data.year,
			str(GameManager.player_data.season).capitalize(),
			wn2
		]
	_refresh_quest_log()

func show_dialogue(text: String):
	if dialogue_label:
		dialogue_label.text = text
	if dialogue_box:
		dialogue_box.visible = true
	if _dialogue_hide_timer:
		_dialogue_hide_timer.stop()
		_dialogue_hide_timer.start(3.0)


func _on_dialogue_hide_timeout() -> void:
	if dialogue_box:
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

func _play_fx_chop() -> void:
	if fx_chop:
		fx_chop.global_position = player.global_position
		fx_chop.restart()
		fx_chop.emitting = true

## Called from `WeatherOverlay` during storms (`visual.screen_shake.strength_px` in `immersion_config.json`).
func play_screen_shake(strength_px: float = 5.5) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
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

func _check_stamina_low_feedback() -> void:
	if not GameManager:
		return
	var smax: float = float(GameManager.player_data.get("stamina_max", BASE_STAMINA_MAX))
	if smax <= 0.0:
		return
	var s: float = float(GameManager.player_data.get("stamina", BASE_STAMINA_MAX))
	var ratio: float = s / smax
	var thr: float = 0.22
	var reset: float = 0.38
	var tip_sec: float = 2.4
	if ImmersionConfig:
		var cfg: Dictionary = ImmersionConfig.get_stamina_low_config()
		thr = float(cfg.get("ratio_threshold", 0.22))
		reset = float(cfg.get("ratio_reset_above", 0.38))
		tip_sec = float(cfg.get("tip_duration_sec", 2.4))
	if ratio >= reset:
		_stamina_low_latched = false
		return
	if ratio > thr:
		return
	if _stamina_low_latched:
		return
	_stamina_low_latched = true
	if GatheringSfx:
		GatheringSfx.play_stamina_low()
	var msg: String = "Low stamina — eat food or rest."
	if UITextCatalog:
		var t: String = UITextCatalog.get_text("quick_tip", "stamina_low")
		if not t.is_empty():
			msg = t
	show_quick_tip(msg, tip_sec)

func _unhandled_input(event):
	if event.is_action_pressed("toggle_event_quest_journal"):
		_toggle_event_quest_journal_popup()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_player_journal"):
		if player_journal_panel and player_journal_panel.has_method("toggle_panel"):
			player_journal_panel.toggle_panel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_audio_mix"):
		if audio_mix_panel:
			audio_mix_panel.toggle()
		get_viewport().set_input_as_handled()
		return
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
	if event.is_action_pressed("barn_interact") and player and GameZones.contains_barn(player.global_position):
		_handle_barn_interact()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_cancel"):
		if _journal_popup_open:
			_set_journal_popup_visible(false)
			get_viewport().set_input_as_handled()
			return
		save_game()

func toggle_inventory():
	var inventory_ui = $UILayer/InventoryUI
	inventory_ui.visible = not inventory_ui.visible

func save_game() -> bool:
	if GameSaveService:
		return GameSaveService.commit_save(_build_save_bundle())
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func _on_ai_config_pressed():
	if not ai_config_instance:
		ai_config_instance = ai_config_scene.instantiate()
		add_child(ai_config_instance)
	
	ai_config_instance.open_config()
