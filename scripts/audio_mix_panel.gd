extends CanvasLayer

## F10 — per-bus volume (dB). Saves to `user://audio_mix.json` via `AudioMixSettings`.

const BUS_NAMES: PackedStringArray = ["Master", "Music", "Ambience", "SFX", "Voice"]
const DB_MIN := -50.0
const DB_MAX := 6.0

var _sliders: Dictionary = {}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := Panel.new()
	panel.position = Vector2(380, 72)
	panel.custom_minimum_size = Vector2(520, 268)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.94)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.42, 0.5, 0.85)
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Audio mix (dB) — saved automatically"
	vbox.add_child(title)
	for bus_name in BUS_NAMES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)
		var lab := Label.new()
		lab.text = "%-10s" % bus_name
		lab.custom_minimum_size = Vector2(100, 0)
		row.add_child(lab)
		var sl := HSlider.new()
		sl.min_value = DB_MIN
		sl.max_value = DB_MAX
		sl.step = 0.5
		sl.custom_minimum_size = Vector2(280, 24)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			sl.value = AudioServer.get_bus_volume_db(idx)
		sl.value_changed.connect(_on_slider_changed.bind(bus_name))
		row.add_child(sl)
		_sliders[bus_name] = sl
	var hint := Label.new()
	hint.text = "F10 close · Esc close · settings: user://audio_mix.json"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78, 0.95))
	vbox.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = not visible
	if visible:
		_sync_sliders_from_buses()

func _sync_sliders_from_buses() -> void:
	for bus_name in _sliders.keys():
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		var sl: HSlider = _sliders[bus_name] as HSlider
		if sl:
			sl.set_value_no_signal(AudioServer.get_bus_volume_db(idx))

func _on_slider_changed(value: float, bus_name: String) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, value)
	if AudioMixSettings:
		AudioMixSettings.save_current()
