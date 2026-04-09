extends Control

class_name AIAgentConfigUI

@onready var provider_label = $VBoxContainer/LlmProviderLabel
@onready var provider_option = $VBoxContainer/LlmProviderOption
@onready var base_url_label = $VBoxContainer/BaseUrlLabel
@onready var base_url_input = $VBoxContainer/BaseUrlInput
@onready var api_key_label = $VBoxContainer/ApiKeyLabel
@onready var api_key_input = $VBoxContainer/ApiKeyInput
@onready var model_label = $VBoxContainer/ModelLabel
@onready var model_input = $VBoxContainer/ModelInput
@onready var max_tokens_label = $VBoxContainer/MaxTokensLabel
@onready var temperature_slider = $VBoxContainer/TemperatureSlider
@onready var temperature_label = $VBoxContainer/TemperatureLabel
@onready var max_tokens_input = $VBoxContainer/MaxTokensInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var test_button = $VBoxContainer/TestButton
@onready var save_button = $VBoxContainer/SaveButton
@onready var close_button = $VBoxContainer/CloseButton
@onready var title_label = $VBoxContainer/TitleLabel
@onready var info_label = $InfoLabel

var is_connected = false

func _ready():
	if provider_option:
		provider_option.clear()
		provider_option.add_item("Ollama")
		provider_option.add_item("OpenAI-compatible")
	_apply_config_chrome()
	if LocaleSettings and LocaleSettings.has_signal("locale_changed"):
		LocaleSettings.locale_changed.connect(_on_locale_changed_ai)
	_apply_static_labels()
	load_current_config()


func _on_locale_changed_ai(_code: String) -> void:
	refresh_locale_text()


func _t(key: String, vars: Dictionary = {}) -> String:
	if UITextCatalog:
		return UITextCatalog.format_text("ai_config", key, vars)
	return ""


func refresh_locale_text() -> void:
	_apply_static_labels()
	update_temperature_label()
	if status_label:
		status_label.text = UITextCatalog.get_text("ai_config", "status_disconnected") if UITextCatalog else "Status: Not connected"


func _apply_static_labels() -> void:
	if not UITextCatalog:
		return
	if title_label:
		title_label.text = UITextCatalog.get_text("ai_config", "title")
	if provider_label:
		provider_label.text = UITextCatalog.get_text("ai_config", "provider_label")
	if provider_option and provider_option.item_count >= 2:
		provider_option.set_item_text(0, UITextCatalog.get_text("ai_config", "provider_ollama"))
		provider_option.set_item_text(1, UITextCatalog.get_text("ai_config", "provider_openai"))
	if base_url_label:
		base_url_label.text = UITextCatalog.get_text("ai_config", "base_url_label")
	if base_url_input:
		base_url_input.placeholder_text = UITextCatalog.get_text("ai_config", "base_url_placeholder")
	if api_key_label:
		api_key_label.text = UITextCatalog.get_text("ai_config", "api_key_label")
	if api_key_input:
		api_key_input.placeholder_text = UITextCatalog.get_text("ai_config", "api_key_placeholder")
	if model_label:
		model_label.text = UITextCatalog.get_text("ai_config", "model_label")
	if model_input:
		model_input.placeholder_text = UITextCatalog.get_text("ai_config", "model_placeholder")
	if max_tokens_label:
		max_tokens_label.text = UITextCatalog.get_text("ai_config", "max_tokens_label")
	if test_button:
		test_button.text = UITextCatalog.get_text("ai_config", "test_button")
	if save_button:
		save_button.text = UITextCatalog.get_text("ai_config", "save_button")
	if close_button:
		close_button.text = UITextCatalog.get_text("ai_config", "close_button")
	if info_label:
		info_label.text = UITextCatalog.get_text("ai_config", "info_help")
	
	# Connect signals
	temperature_slider.value_changed.connect(_on_temperature_changed)
	test_button.pressed.connect(_on_test_connection)
	save_button.pressed.connect(_on_save_config)
	
	# Hide initially
	visible = false

func _config_btn_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.15, 0.2, 0.95)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.38, 0.36, 0.28)
	return sb

func _config_lineedit_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.28, 0.28, 0.32)
	sb.content_margin_left = 8
	sb.content_margin_top = 6
	sb.content_margin_right = 8
	sb.content_margin_bottom = 6
	return sb

func _apply_config_chrome() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", 20)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		title_label.add_theme_constant_override("shadow_offset_x", 1)
		title_label.add_theme_constant_override("shadow_offset_y", 1)
	if status_label:
		status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		status_label.add_theme_constant_override("shadow_offset_x", 1)
		status_label.add_theme_constant_override("shadow_offset_y", 1)
	for node in [base_url_input, api_key_input, model_input, max_tokens_input]:
		if node:
			node.add_theme_stylebox_override("normal", _config_lineedit_style())
			var f := _config_lineedit_style()
			f.border_color = Color(0.42, 0.48, 0.58)
			f.set_border_width_all(2)
			node.add_theme_stylebox_override("focus", f)
	for b in [test_button, save_button, close_button]:
		if b:
			b.flat = true
			b.add_theme_stylebox_override("normal", _config_btn_style())
			var bh := _config_btn_style()
			bh.bg_color = Color(0.18, 0.2, 0.28)
			b.add_theme_stylebox_override("hover", bh)
			b.add_theme_stylebox_override("pressed", _config_btn_style())

func load_current_config():
	if AIAgentManager:
		if provider_option:
			var lp: String = str(AIAgentManager.api_config.get("llm_provider", "ollama"))
			provider_option.selected = 1 if lp == "openai_compatible" else 0
		base_url_input.text = AIAgentManager.api_config.base_url
		if api_key_input:
			api_key_input.text = str(AIAgentManager.api_config.get("api_key", ""))
		model_input.text = AIAgentManager.api_config.model
		temperature_slider.value = AIAgentManager.api_config.temperature
		max_tokens_input.text = str(AIAgentManager.api_config.max_tokens)
		update_temperature_label()

func _on_temperature_changed(value: float):
	AIAgentManager.api_config.temperature = value
	update_temperature_label()

func update_temperature_label():
	if UITextCatalog:
		temperature_label.text = UITextCatalog.format_text("ai_config", "temperature_line", {
			"value": "%.2f" % temperature_slider.value
		})
	else:
		temperature_label.text = "Temperature: %.2f" % temperature_slider.value

func _on_test_connection():
	status_label.text = UITextCatalog.get_text("ai_config", "status_testing") if UITextCatalog else "Testing connection..."
	status_label.modulate = Color.YELLOW
	
	var test_prompt = "Say hello in one word."
	AIAgentManager.quick_chat(
		"test_npc",
		"Test",
		"Hello",
		{},
		{}
	)
	
	# Wait for response or timeout
	await get_tree().create_timer(5.0).timeout
	status_label.text = UITextCatalog.get_text("ai_config", "status_test_done") if UITextCatalog else "Connection test completed"
	status_label.modulate = Color.WHITE

func _on_save_config():
	AIAgentManager.configure_api(
		base_url_input.text.strip_edges(),
		model_input.text.strip_edges(),
		temperature_slider.value
	)
	AIAgentManager.api_config.max_tokens = int(max_tokens_input.text)
	if provider_option:
		AIAgentManager.api_config.llm_provider = (
			"openai_compatible" if provider_option.selected == 1 else "ollama"
		)
	if api_key_input:
		AIAgentManager.api_config.api_key = api_key_input.text.strip_edges()
	AIAgentManager.save_config()
	
	status_label.text = UITextCatalog.get_text("ai_config", "status_saved") if UITextCatalog else "Configuration saved!"
	status_label.modulate = Color.GREEN
	
	await get_tree().create_timer(2.0).timeout
	status_label.modulate = Color.WHITE

func open_config():
	visible = true
	_apply_static_labels()
	load_current_config()

func close_config():
	visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close_config()
