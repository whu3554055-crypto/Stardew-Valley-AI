extends Node2D
const EnemyMelee := preload("res://scripts/enemies/enemy_melee.gd")

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
@onready var fx_chop = $FXLayer/ChopLeaves
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
const WEATHER_OVERLAY_SCENE := preload("res://scenes/weather_overlay.tscn")
const AUDIO_MIX_PANEL_SCENE := preload("res://scenes/audio_mix_panel.tscn")
const PLAYER_CREATION_SCENE := preload("res://scenes/player_creation_panel.tscn")
const PLAYER_JOURNAL_SCENE := preload("res://scenes/player_journal_panel.tscn")
const COMBAT_WEAPONS_CFG_PATH := "res://data/combat/weapons.json"
const COMBAT_ENEMIES_CFG_PATH := "res://data/combat/enemies.json"
var audio_mix_panel: CanvasLayer = null
var player_creation_panel: CanvasLayer = null
var player_journal_panel: CanvasLayer = null
var _had_savegame: bool = false
var _boot_finished: bool = false
var _stamina_low_latched: bool = false
var daily_event_budget: Dictionary = {"narrative": 1, "chain_activation": 1, "recovery_hint": 1}
var _enemy_layer: Node2D = null
var _combat_invuln_until: float = 0.0
var _last_attack_ms: int = -99999
var _combat_weapons_cfg: Dictionary = {}
var _combat_enemies_cfg: Dictionary = {}
var _active_weapon_id: String = "starter_sword"
var _hitstop_active: bool = false
var _next_mine_spawn_at: float = 0.0
var _combo_hits: int = 0
var _combo_expire_at: float = 0.0
var _kill_streak: int = 0
var _kill_streak_expire_at: float = 0.0
var _revenge_buff_until: float = 0.0
var _no_ore_kill_streak: int = 0
var _attack_speed_buff_until: float = 0.0
var _no_elite_kill_streak: int = 0
var _shield_charges: int = 0
var _daily_peak_streak: int = 0
var _crit_chain: int = 0
var _momentum_score: int = 0
var _no_hit_kill_streak: int = 0
var _was_in_mine_last_frame: bool = false
var _run_kills: int = 0
var _run_elites: int = 0
var _run_bonus_gold: int = 0
var _perfect_guard_chain: int = 0
var _last_stand_used_run: bool = false
var _perfect_guard_chain_best: int = 0
var _hype_points: int = 0
var _hype_rank: String = "Rookie"
var _quest_near_done_latched: Dictionary = {}
var _streak_medal_awarded: Dictionary = {}
var _run_best_tag: String = "None"
var _combat_quest_chain: int = 0
var _last_stand_redeem_until: float = 0.0
const PLAYER_ATTACK_COOLDOWN_MS := 340
const PLAYER_ATTACK_RANGE := 56.0
const PLAYER_ATTACK_DAMAGE := 12
const PLAYER_ATTACK_KNOCKBACK := 220.0
const PLAYER_ATTACK_HITSTOP_SEC := 0.04
const PLAYER_ATTACK_CRIT_CHANCE := 0.1
const PLAYER_ATTACK_CRIT_MULT := 1.6
const PLAYER_RESPAWN_HEAL_RATIO := 0.65
const MAX_MINE_ENEMIES := 5
const MINE_SPAWN_MIN_INTERVAL_SEC := 1.2
const MINE_SPAWN_MAX_INTERVAL_SEC := 2.1
const MINE_SPAWN_MIN_PLAYER_DIST := 84.0
const MINE_SPAWN_MAX_PLAYER_DIST := 320.0
const COMBO_WINDOW_SEC := 1.2
const COMBO_BONUS_PER_STACK := 0.08
const COMBO_MAX_STACKS := 5
const KILL_STREAK_WINDOW_SEC := 6.0
const KILL_STREAK_STEP := 5
const ELITE_BASE_CHANCE := 0.08
const ATTACK_GUARD_WINDOW_SEC := 0.22
const ATTACK_GUARD_DAMAGE_REDUCTION := 0.35
const KILL_HEAL_BASE := 2.0
const KILL_MILESTONES := [25, 60, 120]
const REVENGE_BUFF_SEC := 2.6
const REVENGE_DAMAGE_MULT := 1.22
const ORE_PITY_KILL_THRESHOLD := 6
const EXECUTE_THRESHOLD_RATIO := 0.25
const EXECUTE_BONUS_MULT := 1.35
const PANIC_HP_RATIO := 0.2
const PANIC_DAMAGE_REDUCTION := 0.2
const PANIC_INVULN_SEC := 0.85
const ELITE_BOUNTY_GOLD_BASE := 36
const ATTACK_STAMINA_COST := 4.0
const STREAK_HASTE_SEC := 2.2
const STREAK_HASTE_COOLDOWN_MULT := 0.72
const CRIT_STAMINA_REFUND := 2.0
const KILL_SPLASH_RANGE := 46.0
const KILL_SPLASH_DAMAGE := 6
const ATTACK_CONE_DOT_MIN := 0.2
const BACKSTAB_DOT_MAX := -0.45
const BACKSTAB_BONUS_MULT := 1.25
const ELITE_PITY_KILLS := 14
const SHIELD_MAX_CHARGES := 3
const COMBO_FEEDBACK_MIN_STACK := 2
const BIG_HIT_THRESHOLD := 24
const CLUTCH_HP_RATIO := 0.2
const CLUTCH_BONUS_GOLD := 22
const MOMENTUM_STEP := 20
const NO_HIT_STREAK_GOAL := 8
const HYPE_STEP := 18
const WORLD_EVENT_FEED_MAX := 6
const GAME_SAVE_BUNDLE_PATH := "user://game_save.bundle" # legacy fallback path
const GAME_SAVE_SLOT_A_PATH := "user://game_save_a.bundle"
const GAME_SAVE_SLOT_B_PATH := "user://game_save_b.bundle"
const GAME_SAVE_META_PATH := "user://game_save_meta.json"
const TAMPER_LOG_PATH := "user://tamper_events.log"
const SAVE_BUNDLE_VERSION := 5
const SAVE_SIGN_SECRET := "sv_save_sign_v1_local_pepper"
const BASE_STAMINA_MAX := 100.0
## Throttle keys: "memory", "market", "em_<npc_id>", "rel", "pref"
var _visible_feed_last: Dictionary = {}

func _ready():
	# Connect signals
	player.interacted.connect(_on_player_interact)
	if player.has_signal("attack_requested"):
		player.attack_requested.connect(_on_player_attack_requested)
	if GameManager:
		if not GameManager.time_changed.is_connected(_on_time_changed):
			GameManager.time_changed.connect(_on_time_changed)
		if not GameManager.day_changed.is_connected(_on_day_changed):
			GameManager.day_changed.connect(_on_day_changed)
		if not GameManager.season_changed.is_connected(_on_season_changed):
			GameManager.season_changed.connect(_on_season_changed)
	if LocaleSettings:
		LocaleSettings.locale_changed.connect(_on_locale_changed)
	if AchievementSystem:
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked_history)
	
	# Connect farming signals for quest tracking
	farm_manager.crop_planted.connect(_on_crop_planted)
	farm_manager.crop_harvested.connect(_on_crop_harvested)
	
	# Single save file: `game_save.bundle` (see `save_game` / `_build_save_bundle`)
	_had_savegame = _try_load_save_bundle()
	_ensure_profile_defaults()
	_refresh_world_event_feed_ui()
	if not _had_savegame:
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
	if NPCMemorySystem and NPCMemorySystem.has_signal("memory_added"):
		NPCMemorySystem.memory_added.connect(_on_visible_memory_added)
	if NPCEmotionSystem and NPCEmotionSystem.has_signal("emotion_changed"):
		NPCEmotionSystem.emotion_changed.connect(_on_visible_emotion_changed)
	if AIEconomySystem and AIEconomySystem.has_signal("player_visible_market_note"):
		AIEconomySystem.player_visible_market_note.connect(_on_player_visible_market_note)
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
	_enemy_layer = Node2D.new()
	_enemy_layer.name = "EnemyLayer"
	_enemy_layer.z_index = 3
	add_child(_enemy_layer)
	_load_combat_weapons_config()
	_load_combat_enemies_config()
	_apply_a3_ui_polish()
	
	if not GameManager.player_data.get("profile", {}).get("confirmed", false):
		call_deferred("_open_player_creation")
		return
	
	_finish_boot_after_profile()


func _open_player_creation() -> void:
	if player_creation_panel and player_creation_panel.has_method("begin"):
		player_creation_panel.begin()


func _on_player_creation_done() -> void:
	_record_history("game_start", {})
	save_game()
	_finish_boot_after_profile()


func _finish_boot_after_profile() -> void:
	if _boot_finished:
		return
	_boot_finished = true
	if not _had_savegame:
		give_starter_items()
	update_ui()
	initialize_playable_first_loop()
	_print_boot_banner()


func _print_boot_banner() -> void:
	print("======================================")
	print("  Stardew Valley Clone - AI Edition")
	print("======================================")
	print("AI Model: ", AIAgentManager.api_config.model if AIAgentManager else "Not loaded")
	print("NPCs with AI: Pierre, Abigail, Lewis")
	print("Press E: NPCs | harvest | kitchen/smelter/workbench | fish | mine | chop | eat | O journal | F10 audio")
	print("======================================")


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
	_maintain_combat_spawns()

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
	var inv_ui_accent = ui_layer.get_node_or_null("InventoryUI")
	if inv_ui_accent and inv_ui_accent.has_method("set_seasonal_accent"):
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
	if FileAccess.file_exists(GAME_SAVE_BUNDLE_PATH):
		var f: FileAccess = FileAccess.open(GAME_SAVE_BUNDLE_PATH, FileAccess.READ)
		if f:
			var legacy: Variant = f.get_var()
			f.close()
			if legacy is Dictionary and int(legacy.get("version", 0)) >= 2:
				_log_tamper_event("legacy_load_unsigned", {"path": GAME_SAVE_BUNDLE_PATH})
				_apply_save_bundle(legacy)
				return true
	return false


func _pick_best_valid_bundle() -> Dictionary:
	var best_seq: int = -1
	var best: Dictionary = {}
	for p in [GAME_SAVE_SLOT_A_PATH, GAME_SAVE_SLOT_B_PATH]:
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
		if not _verify_bundle_signature(b):
			_log_tamper_event("signature_mismatch", {"path": p})
			continue
		var seq: int = int(b.get("save_seq", 0))
		if seq >= best_seq:
			best_seq = seq
			best = {"path": p, "bundle": b, "seq": seq}
	return best


func _bundle_signing_payload(bundle: Dictionary) -> Dictionary:
	return {
		"version": int(bundle.get("version", 0)),
		"save_seq": int(bundle.get("save_seq", 0)),
		"player": bundle.get("player", {}),
		"farm": bundle.get("farm", {}),
		"inventory": bundle.get("inventory", {}),
		"quests": bundle.get("quests", {})
	}


func _canonicalize_value(v: Variant) -> Variant:
	if v is Dictionary:
		var d: Dictionary = v
		var ks: Array = d.keys()
		ks.sort()
		var out: Dictionary = {}
		for k in ks:
			out[k] = _canonicalize_value(d[k])
		return out
	if v is Array:
		var arr: Array = v
		var out_arr: Array = []
		for e in arr:
			out_arr.append(_canonicalize_value(e))
		return out_arr
	return v


func _compute_bundle_signature(bundle: Dictionary) -> String:
	var payload: Dictionary = _bundle_signing_payload(bundle)
	var normalized: Variant = _canonicalize_value(payload)
	var msg: PackedByteArray = JSON.stringify(normalized).to_utf8_buffer()
	var key: PackedByteArray = SAVE_SIGN_SECRET.to_utf8_buffer()
	var crypto := Crypto.new()
	var digest: PackedByteArray = crypto.hmac_digest(HashingContext.HASH_SHA256, key, msg)
	return digest.hex_encode()


func _verify_bundle_signature(bundle: Dictionary) -> bool:
	var sig: String = str(bundle.get("signature", "")).strip_edges()
	if sig.is_empty():
		return false
	return sig == _compute_bundle_signature(bundle)


func _log_tamper_event(event_name: String, data: Dictionary = {}) -> void:
	var row: Dictionary = {
		"ts": Time.get_unix_time_from_system(),
		"event": event_name,
		"day": int(GameManager.player_data.get("day", 1)) if GameManager else 1,
		"season": str(GameManager.player_data.get("season", "spring")) if GameManager else "spring",
		"year": int(GameManager.player_data.get("year", 1)) if GameManager else 1
	}
	if not data.is_empty():
		row["data"] = data
	var f: FileAccess = FileAccess.open(TAMPER_LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()


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
	_validate_loaded_state()

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


func _maintain_combat_spawns() -> void:
	if _enemy_layer == null:
		return
	var in_mine_now: bool = GameZones.can_mine_here(player.global_position)
	if _was_in_mine_last_frame and not in_mine_now and (_run_kills > 0 or _run_bonus_gold > 0):
		var run_stars: int = _run_star_rating(_run_kills, _run_elites, _run_bonus_gold, _perfect_guard_chain_best)
		var mvp: String = _run_mvp_tag()
		record_world_event("Mine run recap: %d★, kills %d, elites %d, bonus +%dg, MVP %s." % [run_stars, _run_kills, _run_elites, _run_bonus_gold, mvp])
		show_quick_tip("Run recap %d★ · MVP %s" % [run_stars, mvp], 1.2)
		_run_kills = 0
		_run_elites = 0
		_run_bonus_gold = 0
		_last_stand_used_run = false
		_perfect_guard_chain_best = 0
		_hype_points = 0
		_hype_rank = "Rookie"
		_run_best_tag = "None"
	_was_in_mine_last_frame = in_mine_now
	if not GameZones.can_mine_here(player.global_position):
		if _enemy_layer.get_child_count() > 0:
			for c in _enemy_layer.get_children():
				c.queue_free()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _next_mine_spawn_at:
		return
	var alive: int = 0
	for c in _enemy_layer.get_children():
		if c is EnemyMelee:
			alive += 1
	var depth: int = GameZones.mine_depth_from_global_y(player.global_position.y)
	var depth_cap: int = mini(MAX_MINE_ENEMIES + 2, MAX_MINE_ENEMIES + maxi(0, depth))
	var hp_ratio: float = 1.0
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		hp_ratio = hp_cur / hp_max
	if hp_ratio <= 0.35:
		depth_cap = maxi(2, depth_cap - 2)
	if alive >= depth_cap:
		return
	if _spawn_mine_enemy():
		var interval: float = lerpf(MINE_SPAWN_MAX_INTERVAL_SEC, MINE_SPAWN_MIN_INTERVAL_SEC, clampf(float(depth) / 3.0, 0.0, 1.0))
		if hp_ratio <= 0.35:
			interval += 0.9
		_next_mine_spawn_at = now + interval
	else:
		_next_mine_spawn_at = now + 0.25


func _spawn_mine_enemy() -> bool:
	if _enemy_layer == null:
		return false
	var mine: Rect2 = GameZones.mine_world_rect()
	var depth: int = GameZones.mine_depth_from_global_y(player.global_position.y)
	var e := EnemyMelee.new()
	var profile: Dictionary = _pick_enemy_profile_for_depth(depth)
	e.profile_id = str(profile.get("id", ""))
	var hp_base: int = int(profile.get("max_hp_base", 20))
	var hp_scale: int = int(profile.get("max_hp_depth_scale", 8))
	e.enemy_id = str(profile.get("enemy_id", "mine_slime"))
	e.max_hp = hp_base + depth * hp_scale + randi_range(0, 10)
	e.hp = e.max_hp
	e.move_speed = randf_range(float(profile.get("speed_min", 40.0 + depth * 2.5)), float(profile.get("speed_max", 55.0 + depth * 3.0)))
	e.contact_damage = randf_range(float(profile.get("damage_min", 7.0 + depth * 1.5)), float(profile.get("damage_max", 11.0 + depth * 2.0)))
	e.contact_interval_sec = maxf(0.42, 0.9 - float(depth) * 0.08)
	e.drop_count_min = maxi(1, int(profile.get("drop_count_min", 1)))
	e.drop_count_max = maxi(e.drop_count_min, int(profile.get("drop_count_max", 2)))
	e.drop_item_id = _pick_weighted_drop_item(profile.get("drop_pool", []), "stone_chunk")
	var elite_chance: float = clampf(float(profile.get("elite_chance", ELITE_BASE_CHANCE + float(depth) * 0.02)), 0.0, 0.45)
	if randf() < elite_chance or _no_elite_kill_streak >= ELITE_PITY_KILLS:
		var hp_mult: float = maxf(1.1, float(profile.get("elite_hp_mult", 1.55)))
		var dmg_mult: float = maxf(1.1, float(profile.get("elite_damage_mult", 1.3)))
		var extra_drop: int = maxi(1, int(profile.get("elite_drop_bonus", 1)))
		e.max_hp = int(round(float(e.max_hp) * hp_mult))
		e.hp = e.max_hp
		e.contact_damage = float(e.contact_damage) * dmg_mult
		e.drop_count_max += extra_drop
		e.enemy_id = "%s_elite" % e.enemy_id
		e.set_body_color(Color(0.78, 0.45, 0.86, 0.96))
		record_world_event("An elite foe appears in the mine!")
		show_quick_tip("Elite incoming!", 0.95)
		play_screen_shake(4.2)
		if GatheringSfx:
			GatheringSfx.play_mine_swing()
	var spawn_pos: Vector2 = Vector2.ZERO
	var found_pos: bool = false
	for _i in range(12):
		var cand := Vector2(
			randf_range(mine.position.x + 14.0, mine.end.x - 14.0),
			randf_range(mine.position.y + 14.0, mine.end.y - 14.0)
		)
		var dist_to_player: float = cand.distance_to(player.global_position)
		if dist_to_player >= MINE_SPAWN_MIN_PLAYER_DIST and dist_to_player <= MINE_SPAWN_MAX_PLAYER_DIST:
			spawn_pos = cand
			found_pos = true
			break
	if not found_pos:
		return false
	e.global_position = spawn_pos
	e.contact_hit.connect(_on_enemy_contact_hit)
	e.enemy_killed.connect(_on_enemy_killed)
	_enemy_layer.add_child(e)
	return true


func _on_player_attack_requested(origin: Vector2, facing: Vector2) -> void:
	var w: Dictionary = _weapon_profile()
	if GameManager and not GameManager.try_consume_stamina(ATTACK_STAMINA_COST):
		show_quick_tip("Not enough stamina to attack.", 0.65)
		return
	var now_ms: int = Time.get_ticks_msec()
	var cd_ms: int = int(w.get("cooldown_ms", PLAYER_ATTACK_COOLDOWN_MS))
	var now_sec: float = float(now_ms) / 1000.0
	if now_sec <= _attack_speed_buff_until:
		cd_ms = maxi(80, int(round(float(cd_ms) * STREAK_HASTE_COOLDOWN_MULT)))
	if now_ms - _last_attack_ms < cd_ms:
		return
	_last_attack_ms = now_ms
	var center: Vector2 = origin + facing.normalized() * 30.0
	var range_v: float = float(w.get("range", PLAYER_ATTACK_RANGE))
	var dmg: int = int(w.get("damage", PLAYER_ATTACK_DAMAGE))
	var kb: float = float(w.get("knockback", PLAYER_ATTACK_KNOCKBACK))
	var hitstop_sec: float = float(w.get("hitstop_sec", PLAYER_ATTACK_HITSTOP_SEC))
	var crit_chance: float = clampf(float(w.get("crit_chance", PLAYER_ATTACK_CRIT_CHANCE)), 0.0, 1.0)
	var crit_mult: float = maxf(1.0, float(w.get("crit_mult", PLAYER_ATTACK_CRIT_MULT)))
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if now_sec > _combo_expire_at:
		if _combo_hits >= 2:
			show_quick_tip("Combo dropped.", 0.35)
		_combo_hits = 0
	_combo_expire_at = now_sec + COMBO_WINDOW_SEC
	var combo_stack: int = mini(_combo_hits, COMBO_MAX_STACKS)
	var combo_mult: float = 1.0 + COMBO_BONUS_PER_STACK * float(combo_stack)
	var revenge_mult: float = REVENGE_DAMAGE_MULT if now_sec <= _revenge_buff_until else 1.0
	var hit_any: bool = false
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = maxi(1, int(round(float(dmg) * combo_mult * revenge_mult * (crit_mult if is_crit else 1.0))))
	var facing_n: Vector2 = facing.normalized()
	for c in _enemy_layer.get_children():
		if not (c is EnemyMelee):
			continue
		var e: EnemyMelee = c
		var to_enemy: Vector2 = (e.global_position - origin).normalized()
		if e.global_position.distance_to(center) <= range_v and facing_n.dot(to_enemy) >= ATTACK_CONE_DOT_MIN:
			var dmg_to_apply: int = final_dmg
			var special_tag: String = ""
			var enemy_to_player: Vector2 = (player.global_position - e.global_position).normalized()
			if enemy_to_player.dot(to_enemy) <= BACKSTAB_DOT_MAX:
				dmg_to_apply = maxi(1, int(round(float(dmg_to_apply) * BACKSTAB_BONUS_MULT)))
				special_tag = "Backstab!"
			if e.max_hp > 0 and float(e.hp) / float(e.max_hp) <= EXECUTE_THRESHOLD_RATIO:
				dmg_to_apply = maxi(1, int(round(float(final_dmg) * EXECUTE_BONUS_MULT)))
				special_tag = "Execute!"
			var hp_before: int = int(e.hp)
			var killed: bool = e.take_damage(dmg_to_apply)
			if not special_tag.is_empty():
				show_quick_tip(special_tag, 0.45)
			elif dmg_to_apply >= BIG_HIT_THRESHOLD:
				show_quick_tip("Heavy hit %d!" % dmg_to_apply, 0.4)
			if killed:
				var overkill: int = maxi(0, dmg_to_apply - maxi(0, hp_before))
				if overkill >= 10 and GameManager:
					var overkill_bonus: int = mini(25, overkill / 2)
					GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + overkill_bonus
					show_quick_tip("Overkill +%dg" % overkill_bonus, 0.55)
					record_world_event("Overkill payout: +%dg." % overkill_bonus)
			var dir: Vector2 = e.global_position - origin
			if not killed:
				e.apply_knockback(dir, kb)
			hit_any = true
	if hit_any:
		_combo_hits = mini(COMBO_MAX_STACKS, _combo_hits + 1)
		_combo_expire_at = now_sec + COMBO_WINDOW_SEC
		if _combo_hits >= COMBO_FEEDBACK_MIN_STACK:
			var combo_label: String = "Combo x%d!" % (_combo_hits + 1)
			show_quick_tip(combo_label, 0.45)
			if _combo_hits == COMBO_MAX_STACKS:
				record_world_event("Combo peak reached!")
		_play_fx_chop()
		if GatheringSfx:
			GatheringSfx.play_chop()
		_play_hitstop(hitstop_sec)
		if is_crit:
			_crit_chain += 1
			if GameManager and GameManager.has_method("restore_stamina"):
				GameManager.restore_stamina(CRIT_STAMINA_REFUND)
			show_quick_tip("Critical hit!", 0.55)
			if _crit_chain >= 3 and GameManager:
				var crit_bonus: int = 18
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + crit_bonus
				record_world_event("Critical chain x%d (+%dg)." % [_crit_chain, crit_bonus])
				show_quick_tip("Critical chain x%d!" % _crit_chain, 0.8)
				_crit_chain = 0
		else:
			_crit_chain = 0
	else:
		if _combo_hits >= 2:
			show_quick_tip("Combo missed.", 0.35)
		_combo_hits = 0
		_crit_chain = 0


func _on_enemy_contact_hit(_enemy: EnemyMelee, damage: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _combat_invuln_until:
		return
	if _shield_charges > 0:
		_shield_charges -= 1
		_combat_invuln_until = now + 0.45
		show_quick_tip("Shield blocked the hit!", 0.45)
		return
	var guarded: bool = (now - (float(_last_attack_ms) / 1000.0)) <= ATTACK_GUARD_WINDOW_SEC
	var final_damage: float = damage
	var panic_mode: bool = false
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		panic_mode = (hp_cur / hp_max) <= PANIC_HP_RATIO
	if guarded:
		final_damage = damage * (1.0 - ATTACK_GUARD_DAMAGE_REDUCTION)
	if panic_mode:
		final_damage *= (1.0 - PANIC_DAMAGE_REDUCTION)
	_combat_invuln_until = now + (PANIC_INVULN_SEC if panic_mode else 0.55)
	if player and player.has_method("apply_knockback"):
		var kb_dir: Vector2 = player.global_position - _enemy.global_position
		player.apply_knockback(kb_dir, 240.0, 920.0)
	if guarded and _enemy and _enemy.has_method("apply_knockback"):
		_perfect_guard_chain += 1
		_perfect_guard_chain_best = maxi(_perfect_guard_chain_best, _perfect_guard_chain)
		show_quick_tip("Perfect guard x%d" % _perfect_guard_chain, 0.45)
		if _perfect_guard_chain % 3 == 0 and GameManager:
			var guard_bonus: int = 12
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + guard_bonus
			record_world_event("Perfect guard chain bonus +%dg." % guard_bonus)
		var rebound_dir: Vector2 = _enemy.global_position - player.global_position
		_enemy.apply_knockback(rebound_dir, 360.0)
	else:
		_perfect_guard_chain = 0
	if not GameManager:
		return
	var hp_cur_check: float = float(GameManager.player_data.get("hp", 100.0))
	if hp_cur_check - final_damage <= 0.0 and not _last_stand_used_run:
		_last_stand_used_run = true
		GameManager.player_data["hp"] = 1.0
		_combat_invuln_until = now + 1.35
		_last_stand_redeem_until = now + 8.0
		record_world_event("Last Stand triggered! You survived with 1 HP.")
		show_quick_tip("Last Stand!", 0.9)
		update_ui()
		return
	var alive: bool = GameManager.apply_damage(final_damage)
	_no_hit_kill_streak = 0
	play_screen_shake(3.8 if panic_mode else 2.6)
	_revenge_buff_until = now + REVENGE_BUFF_SEC
	if guarded:
		show_quick_tip("Guarded hit!", 0.4)
	elif panic_mode:
		show_quick_tip("Panic guard activated!", 0.5)
	else:
		show_quick_tip("You were hit!", 0.35)
	update_ui()
	if not alive:
		_handle_player_defeat()


func _handle_player_defeat() -> void:
	var home: Vector2 = Vector2(640, 360)
	player.global_position = home
	var charged_gold: bool = false
	if GameManager:
		var hpmax: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		var heal_to: float = hpmax * PLAYER_RESPAWN_HEAL_RATIO
		GameManager.player_data["hp"] = heal_to
		GameManager.player_data["daily_defeats"] = int(GameManager.player_data.get("daily_defeats", 0)) + 1
		var day_idx: int = int(GameManager.player_data.get("year", 1)) * 1000 + int(GameManager.player_data.get("day", 1))
		var insured_day: int = int(GameManager.player_data.get("defeat_insurance_day", -1))
		if insured_day == day_idx:
			var gold: int = int(GameManager.player_data.get("gold", 0))
			GameManager.player_data["gold"] = maxi(0, gold - 60)
			charged_gold = true
		else:
			GameManager.player_data["defeat_insurance_day"] = day_idx
	_combat_invuln_until = Time.get_ticks_msec() / 1000.0 + 1.2
	if charged_gold:
		show_dialogue("You collapsed and woke up at the farmhouse. Lost 60g.")
	else:
		show_dialogue("You collapsed and woke up at the farmhouse. Daily rescue covered the loss.")
	update_ui()


func _on_enemy_killed(enemy: EnemyMelee) -> void:
	var depth_now: int = GameZones.mine_depth_from_global_y(enemy.global_position.y)
	var is_elite: bool = str(enemy.enemy_id).find("_elite") >= 0
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if _last_stand_redeem_until > 0.0 and now_sec <= _last_stand_redeem_until and GameManager:
		var redeem_gold: int = 35
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + redeem_gold
		record_world_event("Redemption! Last Stand converted to victory (+%dg)." % redeem_gold)
		show_quick_tip("Redemption +%dg" % redeem_gold, 1.0)
		_last_stand_redeem_until = 0.0
	if now_sec > _kill_streak_expire_at:
		_kill_streak = 0
	_kill_streak += 1
	_kill_streak_expire_at = now_sec + KILL_STREAK_WINDOW_SEC
	_daily_peak_streak = maxi(_daily_peak_streak, _kill_streak)
	_try_award_streak_medal(_kill_streak)
	if GameManager:
		var best_streak: int = int(GameManager.player_data.get("combat_best_streak", 0))
		if _kill_streak > best_streak:
			GameManager.player_data["combat_best_streak"] = _kill_streak
			record_world_event("New personal best streak: %d." % _kill_streak)
			show_quick_tip("New PB streak: %d" % _kill_streak, 0.85)
	var dropped_ore: bool = false
	_hype_points += 3 + (4 if is_elite else 0)
	var hype_now: String = _hype_rank_from_points(_hype_points)
	if hype_now != _hype_rank:
		_hype_rank = hype_now
		show_quick_tip("Hype rank: %s" % _hype_rank, 0.85)
		record_world_event("Combat hype advanced to %s." % _hype_rank)
	var template: Dictionary = ItemDatabase.get_item(enemy.drop_item_id)
	if not template.is_empty():
		var n: int = enemy.roll_drop_count()
		for _i in range(n):
			InventoryManager.add_item(template.duplicate(true))
		dropped_ore = str(enemy.drop_item_id).ends_with("_ore")
	if dropped_ore:
		_no_ore_kill_streak = 0
	else:
		_no_ore_kill_streak += 1
		if _no_ore_kill_streak >= ORE_PITY_KILL_THRESHOLD:
			var pity_item_id: String = "silver_ore" if depth_now >= 2 else ("iron_ore" if depth_now >= 1 else "copper_ore")
			var pity_tpl: Dictionary = ItemDatabase.get_item(pity_item_id)
			if not pity_tpl.is_empty():
				InventoryManager.add_item(pity_tpl.duplicate(true))
				_no_ore_kill_streak = 0
				show_quick_tip("Ore pity drop: %s" % pity_item_id, 0.9)
	if QuestSystem:
		QuestSystem.track_event("enemy_kill", {
			"enemy_id": enemy.enemy_id,
			"count": 1,
			"mine_depth": depth_now,
				"kill_streak": _kill_streak,
				"daily_defeats": int(GameManager.player_data.get("daily_defeats", 0)) if GameManager else 0
		})
		var q_progress: String = _combat_quest_progress_line()
		if not q_progress.is_empty():
			show_quick_tip(q_progress, 0.8)
	if GameManager and GameManager.has_method("heal_hp"):
		GameManager.heal_hp(KILL_HEAL_BASE + float(depth_now) * 0.5)
	_run_kills += 1
	_no_hit_kill_streak += 1
	if _no_hit_kill_streak == NO_HIT_STREAK_GOAL and GameManager:
		var no_hit_bonus: int = 45
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + no_hit_bonus
		_run_bonus_gold += no_hit_bonus
		record_world_event("No-hit streak achieved! +%dg." % no_hit_bonus)
		show_quick_tip("No-hit streak x%d!" % NO_HIT_STREAK_GOAL, 1.0)
	_momentum_score += 3 + (2 if is_elite else 0)
	if _momentum_score >= MOMENTUM_STEP:
		var momentum_tiers: int = _momentum_score / MOMENTUM_STEP
		_momentum_score = _momentum_score % MOMENTUM_STEP
		var momentum_bonus: int = 10 * momentum_tiers
		if GameManager:
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + momentum_bonus
		_run_bonus_gold += momentum_bonus
		show_quick_tip("Momentum surge! +%dg" % momentum_bonus, 0.8)
		record_world_event("Momentum payout: +%dg." % momentum_bonus)
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		if hp_cur / hp_max <= CLUTCH_HP_RATIO:
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + CLUTCH_BONUS_GOLD
			record_world_event("Clutch kill! +%dg bonus." % CLUTCH_BONUS_GOLD)
			show_quick_tip("Clutch kill!", 0.8)
	if GameManager:
		GameManager.player_data["combat_kills_today"] = int(GameManager.player_data.get("combat_kills_today", 0)) + 1
		if is_elite:
			GameManager.player_data["combat_elites_today"] = int(GameManager.player_data.get("combat_elites_today", 0)) + 1
			var elite_today: int = int(GameManager.player_data.get("combat_elites_today", 0))
			show_quick_tip("Elite progress today: %d / 5" % mini(elite_today, 5), 0.9)
			if elite_today == 5:
				record_world_event("Daily elite hunter target reached (5/5).")
				show_quick_tip("Daily elite target complete!", 1.0)
			if not bool(GameManager.player_data.get("combat_badge_first_elite", false)):
				GameManager.player_data["combat_badge_first_elite"] = true
				record_world_event("Badge unlocked: First Elite Down.")
				show_quick_tip("Badge: First Elite Down", 1.2)
	if is_elite:
		show_quick_tip("Elite defeated!", 0.8)
	else:
		show_quick_tip("Enemy defeated.", 0.35)
	if GameManager and is_elite:
		_no_elite_kill_streak = 0
		_run_elites += 1
		var bounty_gold: int = ELITE_BOUNTY_GOLD_BASE + depth_now * 10
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bounty_gold
		_run_bonus_gold += bounty_gold
		record_world_event("Elite bounty claimed (+%dg)." % bounty_gold)
		show_quick_tip("Elite bounty +%dg" % bounty_gold, 0.9)
		var elite_profile: Dictionary = _find_enemy_profile_by_id(enemy.profile_id)
		var bonus_item_id: String = _pick_weighted_drop_item(elite_profile.get("elite_bonus_drop_pool", []), "")
		if not bonus_item_id.is_empty():
			var bonus_tpl: Dictionary = ItemDatabase.get_item(bonus_item_id)
			if not bonus_tpl.is_empty():
				InventoryManager.add_item(bonus_tpl.duplicate(true))
				show_quick_tip("Elite bonus drop: %s" % bonus_item_id, 0.8)
	else:
		_no_elite_kill_streak += 1
	var splash_hits: int = 0
	for c in _enemy_layer.get_children():
		if not (c is EnemyMelee):
			continue
		var near_enemy: EnemyMelee = c
		if near_enemy == enemy:
			continue
		if near_enemy.global_position.distance_to(enemy.global_position) <= KILL_SPLASH_RANGE:
			near_enemy.take_damage(KILL_SPLASH_DAMAGE)
			splash_hits += 1
	if splash_hits > 0:
		show_quick_tip("Cleave hit x%d" % splash_hits, 0.45)
	if GameManager:
		var total_kills: int = int(GameManager.player_data.get("combat_kills_total", 0)) + 1
		GameManager.player_data["combat_kills_total"] = total_kills
		var milestone_idx: int = int(GameManager.player_data.get("combat_kill_milestone_idx", 0))
		if milestone_idx >= 0 and milestone_idx < KILL_MILESTONES.size():
			var target: int = int(KILL_MILESTONES[milestone_idx])
			if total_kills >= target:
				var milestone_gold: int = 80 + milestone_idx * 70
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + milestone_gold
				GameManager.player_data["combat_kill_milestone_idx"] = milestone_idx + 1
				record_world_event("Combat milestone %d kills reached (+%dg)." % [target, milestone_gold])
				show_quick_tip("Milestone reached: %d kills!" % target, 1.3)
	if _kill_streak > 0 and _kill_streak % KILL_STREAK_STEP == 0 and GameManager:
		var depth_bonus: int = maxi(0, GameZones.mine_depth_from_global_y(enemy.global_position.y))
		var bonus_gold: int = 14 + depth_bonus * 4
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus_gold
		_attack_speed_buff_until = now_sec + STREAK_HASTE_SEC
		_shield_charges = mini(SHIELD_MAX_CHARGES, _shield_charges + 1)
		var tier: String = _streak_tier_label(_kill_streak)
		show_quick_tip("%s streak %d! +%dg" % [tier, _kill_streak, bonus_gold], 1.1)
		record_world_event("Combat bonus: %s streak %d (+%dg)." % [tier, _kill_streak, bonus_gold])
		if _kill_streak >= 10 and not bool(GameManager.player_data.get("combat_badge_streak_10", false)):
			GameManager.player_data["combat_badge_streak_10"] = true
			record_world_event("Badge unlocked: Streak x10.")
			show_quick_tip("Badge: Streak x10", 1.2)
	_play_fx_mine()
	if GatheringSfx:
		GatheringSfx.play_mine_swing()
	play_screen_shake(3.2)
	record_world_event("Defeated %s." % enemy.enemy_id)
	update_ui()


func _load_combat_weapons_config() -> void:
	_combat_weapons_cfg = {
		"starter_sword": {
			"damage": PLAYER_ATTACK_DAMAGE,
			"range": PLAYER_ATTACK_RANGE,
			"cooldown_ms": PLAYER_ATTACK_COOLDOWN_MS,
			"knockback": PLAYER_ATTACK_KNOCKBACK,
			"hitstop_sec": PLAYER_ATTACK_HITSTOP_SEC,
			"crit_chance": PLAYER_ATTACK_CRIT_CHANCE,
			"crit_mult": PLAYER_ATTACK_CRIT_MULT
		}
	}
	var f: FileAccess = FileAccess.open(COMBAT_WEAPONS_CFG_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		var dd: Dictionary = parsed
		if dd.get("weapons") is Dictionary:
			_combat_weapons_cfg = (dd["weapons"] as Dictionary).duplicate(true)


func _load_combat_enemies_config() -> void:
	_combat_enemies_cfg = {"mine_profiles": []}
	var f: FileAccess = FileAccess.open(COMBAT_ENEMIES_CFG_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		var dd: Dictionary = parsed
		if dd.get("mine_profiles") is Array:
			_combat_enemies_cfg = dd.duplicate(true)


func _pick_enemy_profile_for_depth(depth: int) -> Dictionary:
	var profiles: Array = _combat_enemies_cfg.get("mine_profiles", [])
	for p in profiles:
		if not (p is Dictionary):
			continue
		var d: Dictionary = p
		var dmin: int = int(d.get("depth_min", 0))
		var dmax: int = int(d.get("depth_max", 999))
		if depth >= dmin and depth <= dmax:
			return d
	return {}


func _find_enemy_profile_by_id(profile_id: String) -> Dictionary:
	var pid: String = profile_id.strip_edges()
	if pid.is_empty():
		return {}
	var profiles: Array = _combat_enemies_cfg.get("mine_profiles", [])
	for p in profiles:
		if not (p is Dictionary):
			continue
		var d: Dictionary = p
		if str(d.get("id", "")).strip_edges() == pid:
			return d
	return {}


func _pick_weighted_drop_item(entries: Variant, fallback: String) -> String:
	if not (entries is Array):
		return fallback
	var arr: Array = entries
	var total: float = 0.0
	for e in arr:
		if e is Dictionary:
			total += maxf(0.0, float((e as Dictionary).get("weight", 0.0)))
	if total <= 0.0:
		return fallback
	var roll: float = randf() * total
	var acc: float = 0.0
	for e in arr:
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		acc += maxf(0.0, float(d.get("weight", 0.0)))
		if roll <= acc:
			var item_id: String = str(d.get("item", fallback)).strip_edges()
			return item_id if not item_id.is_empty() else fallback
	return fallback


func _weapon_profile() -> Dictionary:
	var w: Dictionary = _combat_weapons_cfg.get(_active_weapon_id, {})
	if w.is_empty():
		w = {
			"damage": PLAYER_ATTACK_DAMAGE,
			"range": PLAYER_ATTACK_RANGE,
			"cooldown_ms": PLAYER_ATTACK_COOLDOWN_MS,
			"knockback": PLAYER_ATTACK_KNOCKBACK,
			"hitstop_sec": PLAYER_ATTACK_HITSTOP_SEC,
			"crit_chance": PLAYER_ATTACK_CRIT_CHANCE,
			"crit_mult": PLAYER_ATTACK_CRIT_MULT
		}
	return w


func _play_hitstop(sec: float) -> void:
	var dur: float = clampf(sec, 0.0, 0.09)
	if dur <= 0.0 or _hitstop_active:
		return
	_hitstop_active = true
	var old_scale: float = Engine.time_scale
	Engine.time_scale = minf(old_scale, 0.18)
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = old_scale
	_hitstop_active = false


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
	
	if DailyNarrativeSystem:
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
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
				if WorldAmbientController:
					WorldAmbientController.request_activity_duck(0.85)
				_play_fx_fish()
				return
			var fish_msg: String = str(catch_result.get("message", ""))
			if catch_result.get("ok", false):
				show_dialogue(fish_msg)
				record_world_event(fish_msg)
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
	if GameManager:
		var defeats_today: int = int(GameManager.player_data.get("daily_defeats", 0))
		var daily_kills: int = int(GameManager.player_data.get("combat_kills_today", 0))
		var daily_elites: int = int(GameManager.player_data.get("combat_elites_today", 0))
		var rating: String = _combat_daily_rating(daily_kills, daily_elites, _daily_peak_streak, defeats_today)
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
		record_world_event("Combat recap: kills %d, elites %d, peak streak %d." % [daily_kills, daily_elites, _daily_peak_streak])
		record_world_event("Combat rating today: %s" % rating)
		show_quick_tip("Daily combat rating: %s" % rating, 1.0)
		GameManager.player_data["combat_kills_today"] = 0
		GameManager.player_data["combat_elites_today"] = 0
		GameManager.player_data["daily_defeats"] = 0
		_daily_peak_streak = 0
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


func _combat_quest_progress_line() -> String:
	if not QuestSystem:
		return ""
	for qid in QuestSystem.active_quests:
		var q: Dictionary = QuestSystem.quests.get(qid, {})
		if q.is_empty():
			continue
		var objectives: Array = q.get("objectives", [])
		for o in objectives:
			if not (o is Dictionary):
				continue
			var od: Dictionary = o
			if str(od.get("type", "")) != "enemy_kill":
				continue
			var cur: int = int(od.get("current", 0))
			var goal: int = int(od.get("count", 1))
			if goal > 0 and cur < goal and float(cur) / float(goal) >= 0.8:
				if not bool(_quest_near_done_latched.get(str(qid), false)):
					_quest_near_done_latched[str(qid)] = true
					show_quick_tip("Almost done: %s" % str(q.get("title", qid)), 0.65)
			return "Quest %s: %d/%d" % [str(q.get("title", qid)), cur, goal]
		_quest_near_done_latched[str(qid)] = false
	return ""

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


func _streak_tier_label(streak: int) -> String:
	if streak >= 20:
		return "Legend"
	if streak >= 15:
		return "Gold"
	if streak >= 10:
		return "Silver"
	return "Bronze"


func _try_award_streak_medal(streak: int) -> void:
	var medals: Dictionary = {
		5: {"name": "Bronze Medal", "gold": 10},
		10: {"name": "Silver Medal", "gold": 18},
		15: {"name": "Gold Medal", "gold": 28},
		20: {"name": "Mythic Medal", "gold": 45}
	}
	if not medals.has(streak):
		return
	if bool(_streak_medal_awarded.get(streak, false)):
		return
	_streak_medal_awarded[streak] = true
	var d: Dictionary = medals[streak]
	var bonus: int = int(d.get("gold", 0))
	if GameManager:
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus
	show_quick_tip("%s unlocked! +%dg" % [str(d.get("name", "Medal")), bonus], 1.0)
	record_world_event("Streak medal unlocked: %s (+%dg)." % [str(d.get("name", "Medal")), bonus])
	_run_best_tag = str(d.get("name", "Medal"))


func _run_mvp_tag() -> String:
	if _run_elites >= 3:
		return "Elite Hunter"
	if _perfect_guard_chain_best >= 5:
		return "Iron Wall"
	if _daily_peak_streak >= 12:
		return "Combo Master"
	if not _run_best_tag.is_empty() and _run_best_tag != "None":
		return _run_best_tag
	return "Steady"


func _hype_rank_from_points(points: int) -> String:
	if points >= HYPE_STEP * 4:
		return "Mythic"
	if points >= HYPE_STEP * 3:
		return "Legend"
	if points >= HYPE_STEP * 2:
		return "Heroic"
	if points >= HYPE_STEP:
		return "Hot"
	return "Rookie"


func _run_star_rating(kills: int, elites: int, bonus_gold: int, guard_best: int) -> int:
	var score: int = kills + elites * 4 + bonus_gold / 18 + guard_best * 2
	if score >= 48:
		return 5
	if score >= 34:
		return 4
	if score >= 22:
		return 3
	if score >= 12:
		return 2
	return 1

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
		weather_label.text = UITextCatalog.format_text("hud", "weather", {"name": wdisp})
		var season_key: String = str(GameManager.player_data.get("season", "spring"))
		season_label.text = UITextCatalog.format_text("hud", "season", {"name": UITextCatalog.localized_season_name(season_key)})
		day_label.text = UITextCatalog.format_text("hud", "day_year", {
			"day": GameManager.player_data.day,
			"year": GameManager.player_data.year
		})
	else:
		gold_label.text = "Gold: %d" % GameManager.player_data.gold
		if stamina_label:
			var s2: float = float(GameManager.player_data.get("stamina", 100.0))
			var sm2: float = float(GameManager.player_data.get("stamina_max", 100.0))
			var hp2: float = float(GameManager.player_data.get("hp", 100.0))
			var hpm2: float = float(GameManager.player_data.get("hp_max", 100.0))
			stamina_label.text = "Stamina: %d / %d | HP: %d / %d" % [int(s2), int(sm2), int(hp2), int(hpm2)]
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
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_cancel"):
		save_game()

func toggle_inventory():
	var inventory_ui = $UILayer/InventoryUI
	inventory_ui.visible = not inventory_ui.visible

func save_game() -> bool:
	var bundle: Dictionary = _build_save_bundle()
	var meta: Dictionary = _read_save_meta()
	var next_seq: int = int(meta.get("last_seq", 0)) + 1
	bundle["save_seq"] = next_seq
	bundle["saved_at_unix"] = Time.get_unix_time_from_system()
	bundle["signature"] = _compute_bundle_signature(bundle)
	var slot_path: String = GAME_SAVE_SLOT_A_PATH if (next_seq % 2 == 1) else GAME_SAVE_SLOT_B_PATH
	var temp_path: String = "%s.tmp" % slot_path
	var bf: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if bf == null:
		push_warning("Main: failed to open save path for writing: %s" % temp_path)
		_log_tamper_event("save_write_failed", {"path": temp_path})
		return false
	bf.store_var(bundle)
	bf.close()
	var rn_ok: Error = DirAccess.rename_absolute(temp_path, slot_path)
	if rn_ok != OK:
		_log_tamper_event("save_rename_failed", {"from": temp_path, "to": slot_path, "code": int(rn_ok)})
		return false
	_write_save_meta({
		"last_seq": next_seq,
		"last_slot": "a" if slot_path == GAME_SAVE_SLOT_A_PATH else "b",
		"last_saved_at_unix": int(bundle.get("saved_at_unix", 0))
	})
	# Keep writing legacy path for compatibility/migration safety.
	var legacy: FileAccess = FileAccess.open(GAME_SAVE_BUNDLE_PATH, FileAccess.WRITE)
	if legacy:
		legacy.store_var(bundle)
		legacy.close()
	if NPCMemorySystem:
		NPCMemorySystem.save_memories()
	if NPCEmotionSystem:
		NPCEmotionSystem.save_emotion_state()
	print("Game saved!")
	return true


func _read_save_meta() -> Dictionary:
	if not FileAccess.file_exists(GAME_SAVE_META_PATH):
		return {}
	var f: FileAccess = FileAccess.open(GAME_SAVE_META_PATH, FileAccess.READ)
	if f == null:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}


func _write_save_meta(meta: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(GAME_SAVE_META_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func _on_ai_config_pressed():
	if not ai_config_instance:
		ai_config_instance = ai_config_scene.instantiate()
		add_child(ai_config_instance)
	
	ai_config_instance.open_config()

