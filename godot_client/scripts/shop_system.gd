extends CanvasLayer

# Shop System - Buy seeds and sell crops
# UI for Pierre's General Store

signal shop_opened()
signal shop_closed()
signal transaction_completed(item_id: String, quantity: int, total_cost: int)

var is_shop_open = false
var current_tab = "buy"  # "buy" or "sell"

@onready var shop_panel = $ShopPanel
@onready var shop_title = $ShopPanel/ShopTitle
@onready var tab_buy = $ShopPanel/Tabs/BuyTab
@onready var tab_sell = $ShopPanel/SellTab
@onready var gold_display = $ShopPanel/GoldDisplay
@onready var item_list = $ShopPanel/ItemList
@onready var close_button = $ShopPanel/CloseButton

var inventory_system = null
var farming_system = null

# Shop inventory (items available for purchase)
var shop_items = {
	"parsnip_seeds": { "price": 20, "stock": 999 },
	"potato_seeds": { "price": 50, "stock": 999 },
	"cauliflower_seeds": { "price": 80, "stock": 999 },
	"corn_seeds": { "price": 150, "stock": 999 },
	"watering_can": { "price": 200, "stock": 5 },
	"hoe": { "price": 150, "stock": 5 }
}

func _ready():
	shop_panel.visible = false
	close_button.pressed.connect(close_shop)
	find_systems()
	update_gold_display()

func find_systems():
	"""Find required systems"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		if main.has_node("TownSquare/InventorySystem"):
			inventory_system = main.get_node("TownSquare/InventorySystem")
			inventory_system.gold_changed.connect(update_gold_display)
		if main.has_node("TownSquare/FarmingSystem"):
			farming_system = main.get_node("TownSquare/FarmingSystem")

func open_shop(mode: String = "buy"):
	"""Open the shop UI"""
	is_shop_open = true
	current_tab = mode
	shop_panel.visible = true
	update_shop_display()
	emit_signal("shop_opened")
	print("Shop opened")

func close_shop():
	"""Close the shop UI"""
	is_shop_open = false
	shop_panel.visible = false
	emit_signal("shop_closed")
	print("Shop closed")

func update_shop_display():
	"""Update the shop UI based on current tab"""
	item_list.clear()

	if current_tab == "buy":
		display_buy_items()
	else:
		display_sell_items()

func display_buy_items():
	"""Display items available for purchase"""
	shop_title.text = "皮埃尔杂货店 - 购买"

	for item_id in shop_items.keys():
		var item_data = shop_items[item_id]
		var item_def = inventory_system.item_definitions.get(item_id, {})

		if item_def.is_empty():
			continue

		var text = "%s - %dg (库存: %d)" % [
			item_def["name"],
			item_data["price"],
			item_data["stock"]
		]

		var idx = item_list.add_item(text)
		item_list.set_item_metadata(idx, {
			"id": item_id,
			"price": item_data["price"],
			"type": "buy"
		})

func display_sell_items():
	"""Display items player can sell"""
	shop_title.text = "皮埃尔杂货店 - 出售"

	var inventory_summary = inventory_system.get_inventory_summary()

	if inventory_summary["items"].is_empty():
		item_list.add_item("背包是空的")
		return

	for item in inventory_summary["items"]:
		# Don't allow selling tools
		if item["type"] == "tool":
			continue

		var text = "%s x%d - %dg" % [
			item["name"],
			item["quantity"],
			item["value"] * item["quantity"]
		]

		var idx = item_list.add_item(text)
		item_list.set_item_metadata(idx, {
			"id": item["id"],
			"quantity": item["quantity"],
			"value": item["value"],
			"type": "sell"
		})

func update_gold_display():
	"""Update gold display in shop"""
	if inventory_system:
		gold_display.text = "金钱: %dg" % inventory_system.player_gold

func _on_item_selected(index: int):
	"""Handle item selection"""
	var metadata = item_list.get_item_metadata(index)

	if not metadata:
		return

	if metadata["type"] == "buy":
		buy_item(metadata["id"])
	else:
		sell_item(metadata["id"], metadata["quantity"])

func buy_item(item_id: String):
	"""Buy an item from the shop"""
	var item_data = shop_items.get(item_id, {})

	if item_data.is_empty():
		return

	if item_data["stock"] <= 0:
		print("Out of stock!")
		return

	if inventory_system.buy_item(item_id, 1):
		shop_items[item_id]["stock"] -= 1
		emit_signal("transaction_completed", item_id, 1, item_data["price"])
		update_shop_display()
		print("Bought ", item_id)
	else:
		print("Purchase failed - not enough gold")

func sell_item(item_id: String, quantity: int):
	"""Sell an item to the shop"""
	var earnings = inventory_system.sell_item(item_id, quantity)

	if earnings > 0:
		emit_signal("transaction_completed", item_id, quantity, earnings)
		update_shop_display()
		print("Sold ", quantity, "x ", item_id, " for ", earnings, "g")

func _input(event):
	"""Handle input when shop is open"""
	if event.is_action_pressed("ui_cancel") and is_shop_open:
		close_shop()
		get_viewport().set_input_as_handled()
