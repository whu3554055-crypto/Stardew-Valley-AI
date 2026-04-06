extends Control

class_name DailyNarrativeAdminUI

# ============================================
# Daily Narrative System Admin Interface
# Allows management of themes, scenarios, and configuration
# ============================================

# UI References
@onready var theme_list: ItemList = $VBoxContainer/HSplitContainer/ThemePanel/ThemeList
@onready var scenario_list: ItemList = $VBoxContainer/HSplitContainer/ScenarioPanel/ScenarioList
@onready var config_panel: VBoxContainer = $VBoxContainer/HSplitContainer/ConfigPanel
@onready var preview_panel: VBoxContainer = $VBoxContainer/HSplitContainer2/PreviewPanel

# Theme controls
@onready var theme_toggle_btn: Button = $VBoxContainer/HSplitContainer/ThemePanel/VBoxContainer/ToggleThemeBtn
@onready var theme_pref_btn: Button = $VBoxContainer/HSplitContainer/ThemePanel/VBoxContainer/PreferThemeBtn

# Scenario controls
@onready var add_scenario_btn: Button = $VBoxContainer/HSplitContainer/ScenarioPanel/VBoxContainer/AddScenarioBtn
@onready var remove_scenario_btn: Button = $VBoxContainer/HSplitContainer/ScenarioPanel/VBoxContainer/RemoveScenarioBtn
@onready var scenario_editor: TextEdit = $VBoxContainer/HSplitContainer/ScenarioPanel/ScenarioEditor

# Config controls
@onready var enabled_check: CheckBox = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/EnabledCheck
@onready var auto_generate_check: CheckBox = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/AutoGenerateCheck
@onready var immersive_check: CheckBox = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/ImmersiveCheck
@onready var rotation_check: CheckBox = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/RotationCheck
@onready var generate_now_btn: Button = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/GenerateNowBtn
@onready var test_presentation_btn: Button = $VBoxContainer/HSplitContainer/ConfigPanel/VBoxContainer/TestPresentationBtn

# Preview controls
@onready var narrative_title: Label = $VBoxContainer/HSplitContainer2/PreviewPanel/VBoxContainer/NarrativeTitle
@onready var narrative_theme: Label = $VBoxContainer/HSplitContainer2/PreviewPanel/VBoxContainer/NarrativeTheme
@onready var cast_list: TextEdit = $VBoxContainer/HSplitContainer2/PreviewPanel/VBoxContainer/CastList
@onready var script_preview: TextEdit = $VBoxContainer/HSplitContainer2/PreviewPanel/VBoxContainer/ScriptPreview

var selected_theme_index = -1
var selected_scenario_index = -1

func _ready():
	initialize_ui()
	connect_signals()
	refresh_data()

func initialize_ui():
	"""Initialize UI elements"""
	print("[DailyNarrativeAdminUI] Initializing...")
	
	# Set initial checkbox states
	if DailyNarrativeSystem:
		enabled_check.button_pressed = DailyNarrativeSystem.config.enabled
		auto_generate_check.button_pressed = DailyNarrativeSystem.config.auto_generate_daily
		immersive_check.button_pressed = DailyNarrativeSystem.config.immersive_transitions
		rotation_check.button_pressed = DailyNarrativeSystem.config.theme_rotation

func connect_signals():
	"""Connect UI signals"""
	theme_list.item_selected.connect(_on_theme_selected)
	scenario_list.item_selected.connect(_on_scenario_selected)
	
	theme_toggle_btn.pressed.connect(_on_toggle_theme_pressed)
	theme_pref_btn.pressed.connect(_on_prefer_theme_pressed)
	
	add_scenario_btn.pressed.connect(_on_add_scenario_pressed)
	remove_scenario_btn.pressed.connect(_on_remove_scenario_pressed)
	
	enabled_check.toggled.connect(_on_enabled_toggled)
	auto_generate_check.toggled.connect(_on_auto_generate_toggled)
	immersive_check.toggled.connect(_on_immersive_toggled)
	rotation_check.toggled.connect(_on_rotation_toggled)
	
	generate_now_btn.pressed.connect(_on_generate_now_pressed)
	test_presentation_btn.pressed.connect(_on_test_presentation_pressed)

func refresh_data():
	"""Refresh all UI data"""
	refresh_themes()
	refresh_scenarios()
	refresh_preview()

# ============================================
# THEME MANAGEMENT
# ============================================

func refresh_themes():
	"""Refresh theme list display"""
	theme_list.clear()
	
	if not DailyNarrativeSystem:
		return
	
	var themes = DailyNarrativeSystem.get_available_themes()
	
	for i in range(themes.size()):
		var theme = themes[i]
		var status_text = ""
		if theme.blocked:
			status_text = " [BLOCKED]"
		elif theme.id in DailyNarrativeSystem.config.preferred_themes:
			status_text = " [PREFERRED]"
		
		theme_list.add_item("{name}{status}".format({
			"name": theme.name,
			"status": status_text
		}))
		
		# Store theme ID as metadata
		theme_list.set_item_metadata(i, theme.id)

func _on_theme_selected(index: int):
	"""Handle theme selection"""
	selected_theme_index = index

func _on_toggle_theme_pressed():
	"""Toggle theme blocked status"""
	if selected_theme_index < 0 or not DailyNarrativeSystem:
		return
	
	var theme_id = theme_list.get_item_metadata(selected_theme_index)
	var currently_blocked = theme_id in DailyNarrativeSystem.config.blocked_themes
	
	DailyNarrativeSystem.toggle_theme_availability(theme_id, !currently_blocked)
	refresh_themes()

func _on_prefer_theme_pressed():
	"""Toggle theme preference"""
	if selected_theme_index < 0 or not DailyNarrativeSystem:
		return
	
	var theme_id = theme_list.get_item_metadata(selected_theme_index)
	var currently_preferred = theme_id in DailyNarrativeSystem.config.preferred_themes
	
	DailyNarrativeSystem.set_theme_preference(theme_id, !currently_preferred)
	refresh_themes()

# ============================================
# SCENARIO MANAGEMENT
# ============================================

func refresh_scenarios():
	"""Refresh scenario list display"""
	scenario_list.clear()
	
	if not DailyNarrativeSystem:
		return
	
	var scenarios = DailyNarrativeSystem.get_scenario_library_summary()
	
	for i in range(scenarios.size()):
		var scenario = scenarios[i]
		scenario_list.add_item("{title} ({theme})".format({
			"title": scenario.title,
			"theme": scenario.theme
		}))
		
		scenario_list.set_item_metadata(i, scenario.id)

func _on_scenario_selected(index: int):
	"""Handle scenario selection"""
	selected_scenario_index = index
	
	if not DailyNarrativeSystem:
		return
	
	var scenario_id = scenario_list.get_item_metadata(index)
	var scenario = DailyNarrativeSystem.scenario_library.get(scenario_id, {})
	
	# Display scenario JSON in editor
	scenario_editor.text = JSON.stringify(scenario, "  ")

func _on_add_scenario_pressed():
	"""Open scenario editor for new scenario"""
	scenario_editor.text = """{
  "id": "custom_scenario_1",
  "theme": "magical",
  "title_template": "My Custom Story",
  "description": "A custom narrative scenario",
  "trope": "custom_trope",
  "roles": {
    "protagonist": {"traits": ["brave"], "count": 1}
  },
  "scenes": [
    {"location": "town", "action": "beginning"}
  ],
  "ai_prompt_additions": "Custom instructions for AI"
}"""

func _on_remove_scenario_pressed():
	"""Remove selected scenario"""
	if selected_scenario_index < 0 or not DailyNarrativeSystem:
		return
	
	var scenario_id = scenario_list.get_item_metadata(selected_scenario_index)
	
	if DailyNarrativeSystem.remove_scenario(scenario_id):
		refresh_scenarios()
		scenario_editor.text = ""

# ============================================
# CONFIGURATION MANAGEMENT
# ============================================

func _on_enabled_toggled(toggled: bool):
	"""Toggle system enabled state"""
	if DailyNarrativeSystem:
		DailyNarrativeSystem.config.enabled = toggled
		DailyNarrativeSystem.save_config()

func _on_auto_generate_toggled(toggled: bool):
	"""Toggle auto-generation"""
	if DailyNarrativeSystem:
		DailyNarrativeSystem.config.auto_generate_daily = toggled
		DailyNarrativeSystem.save_config()

func _on_immersive_toggled(toggled: bool):
	"""Toggle immersive transitions"""
	if DailyNarrativeSystem:
		DailyNarrativeSystem.config.immersive_transitions = toggled
		DailyNarrativeSystem.save_config()

func _on_rotation_toggled(toggled: bool):
	"""Toggle theme rotation"""
	if DailyNarrativeSystem:
		DailyNarrativeSystem.config.theme_rotation = toggled
		DailyNarrativeSystem.save_config()

func _on_generate_now_pressed():
	"""Manually trigger narrative generation"""
	if not DailyNarrativeSystem:
		return
	
	print("[DailyNarrativeAdminUI] Generating narrative now...")
	var narrative = DailyNarrativeSystem.generate_daily_narrative()
	
	if narrative:
		print("[DailyNarrativeAdminUI] Generated: ", narrative.title)
		refresh_preview()
	else:
		push_error("[DailyNarrativeAdminUI] Failed to generate narrative")

func _on_test_presentation_pressed():
	"""Test narrative presentation"""
	if not DailyNarrativeSystem:
		return
	
	if DailyNarrativeSystem.current_narrative.is_empty():
		push_warning("[DailyNarrativeAdminUI] No narrative to test. Generate one first.")
		return
	
	DailyNarrativeSystem.start_narrative_presentation()

# ============================================
# PREVIEW PANEL
# ============================================

func refresh_preview():
	"""Refresh narrative preview"""
	if not DailyNarrativeSystem:
		return
	
	var narrative = DailyNarrativeSystem.get_current_narrative()
	
	if narrative.is_empty():
		narrative_title.text = "No Active Narrative"
		narrative_theme.text = ""
		cast_list.text = ""
		script_preview.text = ""
		return
	
	narrative_title.text = narrative.title
	narrative_theme.text = "Theme: {theme} | Date: {date}".format({
		"theme": DailyNarrativeSystem.NARRATIVE_THEMES[narrative.theme].name,
		"date": narrative.date
	})
	
	# Format cast list
	var cast_text = "CAST:\n\n"
	for role in narrative.cast.keys():
		var actor = narrative.cast[role]
		cast_text += "{role}: {name}\n".format({
			"role": role.capitalize(),
			"name": actor.npc_name
		})
		if not actor.matched_traits.is_empty():
			cast_text += "  Matched traits: {traits}\n".format({
				"traits": ", ".join(actor.matched_traits)
			})
		cast_text += "  Fit score: {score:.0%}\n\n".format({"score": actor.match_score})
	
	cast_list.text = cast_text
	
	# Format script preview
	var script_text = "SCRIPT PREVIEW:\n\n"
	if narrative.script.has("scenes"):
		for scene in narrative.script.scenes:
			script_text += "Scene {num} - {location}\n".format({
				"num": scene.scene_number,
				"location": scene.location.capitalize()
			})
			script_text += "Action: {action}\n\n".format({
				"action": scene.action.replace("_", " ").capitalize()
			})
			
			if scene.has("dialogue"):
				for line in scene.dialogue:
					script_text += "  {character}: {line}\n".format({
						"character": line.character.capitalize(),
						"line": line.line
					})
			
			script_text += "\n"
	
	script_preview.text = script_text
