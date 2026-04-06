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

var is_connected = false

func _ready():
	load_current_config()
	
	# Connect signals
	temperature_slider.value_changed.connect(_on_temperature_changed)
	test_button.pressed.connect(_on_test_connection)
	save_button.pressed.connect(_on_save_config)
	
	# Hide initially
	visible = false

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
