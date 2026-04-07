extends Control

class_name AIAgentConfigUI

@onready var base_url_input = $VBoxContainer/BaseUrlInput
@onready var model_input = $VBoxContainer/ModelInput
@onready var temperature_slider = $VBoxContainer/TemperatureSlider
@onready var temperature_label = $VBoxContainer/TemperatureLabel
@onready var max_tokens_input = $VBoxContainer/MaxTokensInput
@onready var status_label = $VBoxContainer/StatusLabel
@onready var test_button = $VBoxContainer/TestButton
@onready var save_button = $VBoxContainer/SaveButton
@onready var close_button = $VBoxContainer/CloseButton
@onready var title_label = $VBoxContainer/TitleLabel

var is_connected = false

func _ready():
	_apply_config_chrome()
	load_current_config()
	
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
	for node in [base_url_input, model_input, max_tokens_input]:
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
		base_url_input.text = AIAgentManager.api_config.base_url
		model_input.text = AIAgentManager.api_config.model
		temperature_slider.value = AIAgentManager.api_config.temperature
		max_tokens_input.text = str(AIAgentManager.api_config.max_tokens)
		update_temperature_label()

func _on_temperature_changed(value: float):
	AIAgentManager.api_config.temperature = value
	update_temperature_label()

func update_temperature_label():
	temperature_label.text = "Temperature: %.2f" % temperature_slider.value

func _on_test_connection():
	status_label.text = "Testing connection..."
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
	status_label.text = "Connection test completed"
	status_label.modulate = Color.WHITE

func _on_save_config():
	AIAgentManager.configure_api(
		base_url_input.text,
		model_input.text,
		temperature_slider.value
	)
	
	AIAgentManager.api_config.max_tokens = int(max_tokens_input.text)
	AIAgentManager.save_config()
	
	status_label.text = "Configuration saved!"
	status_label.modulate = Color.GREEN
	
	await get_tree().create_timer(2.0).timeout
	status_label.modulate = Color.WHITE

func open_config():
	visible = true
	load_current_config()

func close_config():
	visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close_config()
