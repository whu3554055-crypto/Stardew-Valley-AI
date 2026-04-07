extends Node

class_name ShopSystem

# Shop inventory
var shop_stock = {}

signal shop_opened
signal item_purchased(item_id, quantity)
signal item_sold(item_id, quantity)

func _ready():
	initialize_shop()

func initialize_shop():
	# Pierre's General Store stock
	shop_stock = {
		"parsnip_seeds": {"price": 20, "stock": 99},
		"cauliflower_seeds": {"price": 80, "stock": 99},
		"potato_seeds": {"price": 50, "stock": 99},
		"bread": {"price": 50, "stock": 99},
		"fishing_rod": {"price": 120, "stock": 10},
		"worm_bait": {"price": 8, "stock": 99},
		"pickaxe_iron": {"price": 800, "stock": 3}
	}

func open_shop():
	shop_opened.emit()
	return shop_stock

func get_buy_price(item_id: String) -> int:
	if not shop_stock.has(item_id):
		return 0
	var catalog: int = int(shop_stock[item_id].price)
	if AIEconomySystem:
		return AIEconomySystem.get_shop_buy_price(item_id, catalog)
	return catalog

func purchase_item(item_id: String, quantity: int = 1) -> bool:
	if not shop_stock.has(item_id):
		return false

	var item_data = shop_stock[item_id]
	var unit = get_buy_price(item_id)
	var total_cost = unit * quantity

	if GameManager.player_data.gold < total_cost:
		return false

	if item_data.stock < quantity:
		return false

	# Process transaction
	GameManager.player_data.gold -= total_cost
	item_data.stock -= quantity

	# Add to player inventory
	var item_template = ItemDatabase.get_item(item_id)
	if item_template.is_empty():
		return false

	for i in range(quantity):
		InventoryManager.add_item(item_template.duplicate(true))

	item_purchased.emit(item_id, quantity)
	return true

func get_sell_price_per_unit(item_id: String) -> int:
	var item_template: Dictionary = ItemDatabase.get_item(item_id)
	var base: int = int(item_template.get("sell_price", 0))
	if base <= 0:
		return 0
	if AIEconomySystem:
		return AIEconomySystem.get_shop_sell_price(item_id, base)
	return base

func sell_item(item_id: String, quantity: int = 1) -> bool:
	var item_template = ItemDatabase.get_item(item_id)
	if item_template.is_empty():
		return false

	var unit: int = get_sell_price_per_unit(item_id)
	var sell_price: int = unit * quantity

	# Remove from inventory and add gold
	for i in range(quantity):
		# Find and remove item from inventory
		for slot in range(InventoryManager.INVENTORY_SIZE):
			var item = InventoryManager.get_item(slot)
			if item and item.id == item_id:
				InventoryManager.remove_item(slot)
				break

	GameManager.player_data.gold += sell_price
	item_sold.emit(item_id, quantity)
	return true

func get_sell_value(item_id: String) -> int:
	return get_sell_price_per_unit(item_id)
