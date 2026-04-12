extends CanvasLayer

## Player journal: achievements + history (localized).

var _panel: Panel
var _tabs: TabContainer
var _ach_scroll: ScrollContainer
var _ach_list: VBoxContainer
var _hist_scroll: ScrollContainer
var _hist_list: VBoxContainer
var _daily_scroll: ScrollContainer
var _daily_list: VBoxContainer


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -380.0
	_panel.offset_top = -300.0
	_panel.offset_right = 380.0
	_panel.offset_bottom = 300.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.96)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.42, 0.38, 0.26)
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	_panel.add_child(root)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_ach_scroll = ScrollContainer.new()
	_ach_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ach_list = VBoxContainer.new()
	_ach_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ach_list.add_theme_constant_override("separation", 6)
	_ach_scroll.add_child(_ach_list)
	_tabs.add_child(_ach_scroll)
	_hist_scroll = ScrollContainer.new()
	_hist_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hist_list = VBoxContainer.new()
	_hist_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hist_list.add_theme_constant_override("separation", 4)
	_hist_scroll.add_child(_hist_list)
	_tabs.add_child(_hist_scroll)
	_daily_scroll = ScrollContainer.new()
	_daily_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_daily_list = VBoxContainer.new()
	_daily_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daily_list.add_theme_constant_override("separation", 6)
	_daily_scroll.add_child(_daily_list)
	_tabs.add_child(_daily_scroll)
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.pressed.connect(_on_close)
	close_row.add_child(close_btn)
	root.add_child(close_row)
	if LocaleSettings:
		LocaleSettings.locale_changed.connect(_refresh_all)
	if AchievementSystem:
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(_id: String) -> void:
	if visible:
		_refresh_achievements()


func _on_close() -> void:
	visible = false


func toggle_panel() -> void:
	visible = not visible
	if visible:
		_refresh_all()


func _refresh_all() -> void:
	if UITextCatalog:
		_tabs.set_tab_title(0, UITextCatalog.get_text("journal", "tab_achievements"))
		_tabs.set_tab_title(1, UITextCatalog.get_text("journal", "tab_history"))
		_tabs.set_tab_title(2, UITextCatalog.get_text("journal", "tab_daily_story"))
		var cb: Button = find_child("CloseBtn", true, false) as Button
		if cb:
			cb.text = UITextCatalog.get_text("journal", "close")
	_refresh_achievements()
	_refresh_history()
	_refresh_daily_story()


func _refresh_achievements() -> void:
	for c in _ach_list.get_children():
		c.queue_free()
	if not AchievementSystem or not UITextCatalog:
		return
	var ids: Array = []
	for k in AchievementSystem.achievements:
		ids.append(k)
	ids.sort()
	for aid in ids:
		var a: Dictionary = AchievementSystem.achievements[aid]
		var row := VBoxContainer.new()
		var t := Label.new()
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var title: String = UITextCatalog.get_achievement_field(str(aid), "title")
		if title.is_empty():
			title = str(a.get("title", aid))
		var desc: String = UITextCatalog.get_achievement_field(str(aid), "description")
		if desc.is_empty():
			desc = str(a.get("description", ""))
		var mark: String = "✓ " if a.get("unlocked", false) else "○ "
		t.text = mark + title + "\n  " + desc
		t.add_theme_font_size_override("font_size", 13)
		row.add_child(t)
		_ach_list.add_child(row)


func _refresh_daily_story() -> void:
	for c in _daily_list.get_children():
		c.queue_free()
	if not GameManager or not UITextCatalog:
		return
	var snap: Variant = GameManager.player_data.get("daily_narrative_snapshot", {})
	if not snap is Dictionary or (snap as Dictionary).is_empty():
		var empty := Label.new()
		empty.text = UITextCatalog.get_text("journal", "daily_story_empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_daily_list.add_child(empty)
		return
	var d: Dictionary = snap as Dictionary
	var title_l := Label.new()
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_l.add_theme_font_size_override("font_size", 14)
	title_l.text = str(d.get("title", ""))
	_daily_list.add_child(title_l)
	var meta := Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.add_theme_font_size_override("font_size", 11)
	meta.modulate = Color(0.85, 0.88, 0.92, 1.0)
	meta.text = UITextCatalog.format_text("journal", "daily_story_meta", {
		"source": str(d.get("source", "")),
		"day": str(d.get("day_key", ""))
	})
	_daily_list.add_child(meta)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 12)
	body.text = str(d.get("summary", ""))
	_daily_list.add_child(body)
	var loc: String = str(d.get("hotspot_location", "")).strip_edges()
	if not loc.is_empty():
		var hot := Label.new()
		hot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hot.add_theme_font_size_override("font_size", 12)
		hot.text = UITextCatalog.format_text("journal", "daily_story_hotspot", {
			"location": loc,
			"npc": str(d.get("hotspot_npc_name", ""))
		})
		_daily_list.add_child(hot)


func _refresh_history() -> void:
	for c in _hist_list.get_children():
		c.queue_free()
	if not GameManager or not UITextCatalog:
		return
	var log: Array = GameManager.player_data.get("history_log", [])
	if log.is_empty():
		var empty := Label.new()
		empty.text = UITextCatalog.get_text("journal", "history_empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_hist_list.add_child(empty)
		return
	for i in range(log.size() - 1, -1, -1):
		var e = log[i]
		if e is Dictionary:
			var line := Label.new()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_font_size_override("font_size", 12)
			line.text = UITextCatalog.format_history_line(e as Dictionary)
			_hist_list.add_child(line)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
