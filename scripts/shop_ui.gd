extends Control

class_name ShopUI

@onready var shop_items_container = $ShopItemsContainer
@onready var player_gold_label = $PlayerGoldLabel
@onready var total_label = $TotalLabel

var current_total = 0
var cart = {}

signal shop_closed
signal purchase_confirmed(item_id, quantity)

func _ready():
	visible = false
	update_gold_display()

func open_shop():
	visible = true
	populate_shop_items()
	update_gold_display()

func close_shop():
	visible = false
	shop_closed.emit()

func populate_shop_items():
	# Clear existing
	for child in shop_items_container.get_children():
		child.queue_free()

	var shop_stock = ShopSystem.open_shop()

	for item_id in shop_stock:
		var item_data = shop_stock[item_id]
		var item_template = ItemDatabase.get_item(item_id)

		var item_button = Button.new()
		item_button.text = "%s - %dg (Stock: %d)" % [item_template.name, item_data.price, item_data.stock]
		item_button.custom_minimum_size = Vector2(200, 40)
		item_button.pressed.connect(_on_item_selected.bind(item_id, item_data.price))
		shop_items_container.add_child(item_button)

func _on_item_selected(item_id: String, price: int):
	current_total = price
	total_label.text = "Total: %dg" % current_total
	purchase_confirmed.emit(item_id, 1)

func update_gold_display():
	player_gold_label.text = "Your Gold: %dg" % GameManager.player_data.gold

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close_shop()
