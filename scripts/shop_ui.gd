extends Control

class_name ShopUI

@onready var shop_items_container = $ShopItemsContainer
@onready var player_gold_label = $PlayerGoldLabel
@onready var total_label = $TotalLabel
@onready var title_label = $TitleLabel
@onready var season_label = $SeasonLabel
@onready var close_button = $CloseButton
@onready var season_border: Panel = $SeasonBorder

var current_total = 0
var cart = {}
var show_unavailable_seasonal_items := true
var _season_accent: Color = Color(0.38, 0.34, 0.24)

signal shop_closed
signal purchase_confirmed(item_id, quantity)

func _ready():
	visible = false
	if season_border:
		var sbb := StyleBoxFlat.new()
		sbb.bg_color = Color(0, 0, 0, 0)
		sbb.set_border_width_all(2)
		sbb.border_color = Color(0.35, 0.32, 0.22)
		season_border.add_theme_stylebox_override("panel", sbb)
		season_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_shop_chrome()
	update_gold_display()

func _apply_shop_chrome() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		title_label.add_theme_constant_override("shadow_offset_x", 1)
		title_label.add_theme_constant_override("shadow_offset_y", 1)
	if player_gold_label:
		player_gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		player_gold_label.add_theme_constant_override("shadow_offset_x", 1)
		player_gold_label.add_theme_constant_override("shadow_offset_y", 1)
	if total_label:
		total_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		total_label.add_theme_constant_override("shadow_offset_x", 1)
		total_label.add_theme_constant_override("shadow_offset_y", 1)
	if season_label:
		season_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		season_label.add_theme_constant_override("shadow_offset_x", 1)
		season_label.add_theme_constant_override("shadow_offset_y", 1)
	if close_button:
		_apply_close_button_style()

func _apply_close_button_style() -> void:
	if not close_button:
		return
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.14, 0.13, 0.12, 0.95)
	csb.set_border_width_all(1)
	csb.border_color = _season_accent
	close_button.add_theme_stylebox_override("normal", csb)
	close_button.add_theme_stylebox_override("hover", csb)
	close_button.add_theme_stylebox_override("pressed", csb)
	close_button.flat = true


func apply_seasonal_accent(accent: Color) -> void:
	_season_accent = accent
	_apply_close_button_style()
	if visible:
		populate_shop_items()


func _shop_item_button_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.14, 0.12, 0.96)
	sb.set_border_width_all(1)
	sb.border_color = _season_accent
	return sb

func open_shop():
	visible = true
	_update_season_header()
	populate_shop_items()
	update_gold_display()

func close_shop():
	visible = false
	shop_closed.emit()

func populate_shop_items():
	# Clear existing
	for child in shop_items_container.get_children():
		child.queue_free()

	var shop_stock: Dictionary = ShopSystem.get_display_stock(show_unavailable_seasonal_items) if ShopSystem else {}
	var chain_focus_items: Array = QuestSystem.get_chain_focus_items() if QuestSystem and QuestSystem.has_method("get_chain_focus_items") else []

	for item_id in shop_stock:
		var item_data = shop_stock[item_id]
		var item_template = ItemDatabase.get_item(item_id)
		if item_template.is_empty():
			continue
		var live_price: int = ShopSystem.get_buy_price(item_id)
		var available: bool = bool(item_data.get("available", true))
		var market_note: String = ""
		var market_tag: String = ""
		if AIEconomySystem:
			market_note = str(AIEconomySystem.get_market_brief(item_id))
			market_tag = str(AIEconomySystem.get_market_tag(item_id))

		var item_button = Button.new()
		item_button.text = "%s - %dg (Stock: %d)%s%s" % [
			item_template.name,
			live_price,
			item_data.stock,
			"" if available else " [Out of season]",
			("  [%s%s%s]" % [market_note, " | " if not market_note.is_empty() and not market_tag.is_empty() else "", market_tag]) if (not market_note.is_empty() or not market_tag.is_empty()) else ""
		]
		if chain_focus_items.has(item_id):
			item_button.text += " [Chain Focus]"
		item_button.custom_minimum_size = Vector2(200, 40)
		item_button.flat = true
		item_button.disabled = not available
		var row := _shop_item_button_style()
		if not available:
			row.bg_color = Color(0.11, 0.11, 0.11, 0.86)
			row.border_color = Color(0.26, 0.26, 0.26, 0.85)
		item_button.add_theme_stylebox_override("normal", row)
		item_button.add_theme_stylebox_override("hover", _shop_item_button_style())
		item_button.add_theme_stylebox_override("pressed", _shop_item_button_style())
		item_button.pressed.connect(_on_item_selected.bind(item_id, live_price))
		shop_items_container.add_child(item_button)

func _on_item_selected(item_id: String, price: int):
	current_total = price
	total_label.text = "Total: %dg" % current_total
	purchase_confirmed.emit(item_id, 1)

func update_gold_display():
	player_gold_label.text = "Your Gold: %dg" % GameManager.player_data.gold


func _update_season_header() -> void:
	if not season_label or not GameManager:
		return
	var season: String = str(GameManager.player_data.get("season", "spring")).capitalize()
	var strategy: String = ShopSystem.get_weekly_strategy_label() if ShopSystem and ShopSystem.has_method("get_weekly_strategy_label") else "balanced"
	season_label.text = "Season: %s | Weekly: %s" % [season, strategy]

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close_shop()
