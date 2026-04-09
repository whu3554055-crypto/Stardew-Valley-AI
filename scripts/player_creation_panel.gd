extends CanvasLayer

## First-run character setup: gender, personality, hobbies, appearance presets.

signal creation_finished()

var _panel: Panel
var _title_label: Label
var _name_edit: LineEdit
var _gender: OptionButton
var _personality: OptionButton
var _hobby_checks: Array[CheckBox] = []
var _avatar: HSlider
var _body: HSlider
var _hair: HSlider
var _outfit: HSlider
var _avatar_lbl: Label
var _body_lbl: Label
var _hair_lbl: Label
var _outfit_lbl: Label
var _hobby_title: Label
var _appearance_title: Label
var _confirm_btn: Button


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -340.0
	_panel.offset_top = -280.0
	_panel.offset_right = 340.0
	_panel.offset_bottom = 280.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.45, 0.5, 0.38)
	sb.content_margin_left = 16
	sb.content_margin_top = 14
	sb.content_margin_right = 16
	sb.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	_title_label = Label.new()
	v.add_child(_title_label)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 24
	v.add_child(_name_edit)
	_gender = OptionButton.new()
	v.add_child(_gender)
	_personality = OptionButton.new()
	v.add_child(_personality)
	_hobby_title = Label.new()
	v.add_child(_hobby_title)
	var hg := GridContainer.new()
	hg.columns = 3
	hg.add_theme_constant_override("h_separation", 10)
	hg.add_theme_constant_override("v_separation", 4)
	v.add_child(hg)
	var hobby_keys: Array[String] = ["farming", "fishing", "mining", "foraging", "cooking", "social"]
	for k in hobby_keys:
		var c := CheckBox.new()
		c.name = "hobby_" + k
		hg.add_child(c)
		_hobby_checks.append(c)
	_appearance_title = Label.new()
	v.add_child(_appearance_title)
	_avatar_lbl = Label.new()
	_avatar = _make_slider()
	v.add_child(_row(_avatar_lbl, _avatar))
	_body_lbl = Label.new()
	_body = _make_slider(2)
	v.add_child(_row(_body_lbl, _body))
	_hair_lbl = Label.new()
	_hair = _make_slider(3)
	v.add_child(_row(_hair_lbl, _hair))
	_outfit_lbl = Label.new()
	_outfit = _make_slider(3)
	v.add_child(_row(_outfit_lbl, _outfit))
	_confirm_btn = Button.new()
	_confirm_btn.pressed.connect(_on_confirm)
	v.add_child(_confirm_btn)
	if LocaleSettings:
		LocaleSettings.locale_changed.connect(_refresh_texts)
	call_deferred("_refresh_texts")


func _make_slider(mx: int = 3) -> HSlider:
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = mx
	sl.step = 1
	sl.value = 0
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sl


func _row(lb: Label, sl: HSlider) -> HBoxContainer:
	var row := HBoxContainer.new()
	lb.custom_minimum_size = Vector2(120, 0)
	row.add_child(lb)
	row.add_child(sl)
	return row


func _refresh_texts() -> void:
	if not UITextCatalog:
		return
	_title_label.text = UITextCatalog.get_text("player_creation", "title")
	_name_edit.placeholder_text = UITextCatalog.get_text("player_creation", "name_placeholder")
	_hobby_title.text = UITextCatalog.get_text("player_creation", "hobbies")
	_appearance_title.text = UITextCatalog.get_text("player_creation", "appearance")
	_avatar_lbl.text = UITextCatalog.get_text("player_creation", "avatar")
	_body_lbl.text = UITextCatalog.get_text("player_creation", "body")
	_hair_lbl.text = UITextCatalog.get_text("player_creation", "hair")
	_outfit_lbl.text = UITextCatalog.get_text("player_creation", "outfit")
	_confirm_btn.text = UITextCatalog.get_text("player_creation", "confirm")
	_gender.clear()
	for k in ["male", "female", "neutral"]:
		_gender.add_item(UITextCatalog.get_text("player_creation", "gender_" + k))
	_personality.clear()
	for k in ["kind", "bold", "calm", "curious"]:
		_personality.add_item(UITextCatalog.get_text("player_creation", "personality_" + k))
	var hobby_keys: Array[String] = ["farming", "fishing", "mining", "foraging", "cooking", "social"]
	for i in range(mini(_hobby_checks.size(), hobby_keys.size())):
		_hobby_checks[i].text = UITextCatalog.get_text("player_creation", "hobby_" + hobby_keys[i])


func begin() -> void:
	visible = true
	_refresh_texts()
	if GameManager and GameManager.player_data.has("profile"):
		var p: Dictionary = GameManager.player_data["profile"]
		_name_edit.text = str(p.get("display_name", ""))
		_gender.select(_gender_to_sel(str(p.get("gender", "neutral"))))
		_personality.select(_personality_to_sel(str(p.get("personality", "kind"))))
		_avatar.value = int(p.get("avatar_id", 0))
		_body.value = int(p.get("body_type", 0))
		_hair.value = int(p.get("hairstyle_id", 0))
		_outfit.value = int(p.get("outfit_id", 0))
		var hs: Array = p.get("hobbies", [])
		var hobby_keys: Array[String] = ["farming", "fishing", "mining", "foraging", "cooking", "social"]
		for i in range(_hobby_checks.size()):
			_hobby_checks[i].button_pressed = hs.has(hobby_keys[i])


func _gender_to_sel(g: String) -> int:
	match g:
		"male":
			return 0
		"female":
			return 1
		_:
			return 2


func _personality_to_sel(p: String) -> int:
	var pk: Array = ["kind", "bold", "calm", "curious"]
	var i: int = pk.find(p)
	return clampi(i, 0, 3)


func _on_confirm() -> void:
	if not GameManager:
		return
	var hobby_keys: Array[String] = ["farming", "fishing", "mining", "foraging", "cooking", "social"]
	var picked: Array[String] = []
	for i in range(mini(_hobby_checks.size(), hobby_keys.size())):
		if _hobby_checks[i].button_pressed:
			picked.append(hobby_keys[i])
	var gk: Array = ["male", "female", "neutral"]
	var pk: Array = ["kind", "bold", "calm", "curious"]
	var nm: String = _name_edit.text.strip_edges()
	if nm.is_empty() and UITextCatalog:
		nm = UITextCatalog.get_text("player_creation", "default_name")
	elif nm.is_empty():
		nm = "Farmer"
	GameManager.player_data["profile"] = {
		"display_name": nm,
		"gender": gk[clamp(_gender.selected, 0, 2)],
		"personality": pk[clamp(_personality.selected, 0, 3)],
		"hobbies": picked,
		"avatar_id": int(_avatar.value),
		"body_type": int(_body.value),
		"hairstyle_id": int(_hair.value),
		"outfit_id": int(_outfit.value),
		"confirmed": true
	}
	visible = false
	creation_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
