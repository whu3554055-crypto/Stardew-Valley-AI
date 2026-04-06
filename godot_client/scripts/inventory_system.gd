extends Node

# Inventory System
# Manages player items, seeds, and harvested crops

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal gold_changed(new_amount: int)
signal inventory_updated()

# Player inventory: { "item_id": { "name": String, "quantity": int, "type": String, "value": int } }
var inventory = {}
var player_gold = 500

# Item definitions
var item_definitions = {
	# Seeds
	"parsnip_seeds": {
		"name": "防风草种子",
		"type": "seed",
		"crop_type": "parsnip",
		"value": 20,
		"description": "春季作物，4天成熟"
	},
	"potato_seeds": {
		"name": "土豆种子",
		"type": "seed",
		"crop_type": "potato",
		"value": 50,
		"description": "春季作物，6天成熟"
	},
	"cauliflower_seeds": {
		"name": "花椰菜种子",
		"type": "seed",
		"crop_type": "cauliflower",
		"value": 80,
		"description": "春季作物，12天成熟"
	},
	"corn_seeds": {
		"name": "玉米种子",
		"type": "seed",
		"crop_type": "corn",
		"value": 150,
		"description": "夏/秋季作物，14天成熟"
	},

	# Harvested crops
	"parsnip": {
		"name": "防风草",
		"type": "crop",
		"value": 35,
		"description": "新鲜的防风草"
	},
	"potato": {
		"name": "土豆",
		"type": "crop",
		"value": 80,
		"description": "饱满的土豆"
	},
	"cauliflower": {
		"name": "花椰菜",
		"type": "crop",
		"value": 175,
		"description": "巨大的花椰菜"
	},
	"corn": {
		"name": "玉米",
		"type": "crop",
		"value": 50,
		"description": "金黄的玉米"
	},

	# Tools
	"watering_can": {
		"name": "洒水壶",
		"type": "tool",
		"value": 200,
		"description": "用于浇灌作物"
	},
	"hoe": {
		"name": "锄头",
		"type": "tool",
		"value": 150,
		"description": "用于开垦土地"
	}
}

func _ready():
	print("Inventory system initialized")
	# Give player starting items
	add_item("watering_can", 1)
	add_item("parsnip_seeds", 5)
	update_gold(0)  # Initialize with default gold

func add_item(item_id: String, quantity: int = 1) -> bool:
	"""Add item to inventory"""
	if not item_definitions.has(item_id):
		print("Unknown item: ", item_id)
		return false

	if inventory.has(item_id):
		inventory[item_id]["quantity"] += quantity
	else:
		var item_def = item_definitions[item_id]
		inventory[item_id] = {
			"name": item_def["name"],
			"quantity": quantity,
			"type": item_def["type"],
			"value": item_def["value"]
		}

	emit_signal("item_added", item_id, quantity)
	emit_signal("inventory_updated")
	print("Added ", quantity, "x ", item_definitions[item_id]["name"])
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove item from inventory"""
	if not inventory.has(item_id):
		return false

	if inventory[item_id]["quantity"] < quantity:
		print("Not enough ", item_id)
		return false

	inventory[item_id]["quantity"] -= quantity

	if inventory[item_id]["quantity"] <= 0:
		inventory.erase(item_id)

	emit_signal("item_removed", item_id, quantity)
	emit_signal("inventory_updated")
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if player has item"""
	if not inventory.has(item_id):
		return false
	return inventory[item_id]["quantity"] >= quantity

func get_item_quantity(item_id: String) -> int:
	"""Get quantity of specific item"""
	if not inventory.has(item_id):
		return 0
	return inventory[item_id]["quantity"]

func update_gold(amount: int):
	"""Update player gold (positive or negative)"""
	player_gold += amount
	emit_signal("gold_changed", player_gold)
	print("Gold: ", player_gold, "g (", ("+" if amount >= 0 else ""), amount, ")")

func spend_gold(amount: int) -> bool:
	"""Spend gold, returns success/failure"""
	if player_gold < amount:
		print("Not enough gold! Need ", amount, "g, have ", player_gold, "g")
		return false

	update_gold(-amount)
	return true

func sell_item(item_id: String, quantity: int = 1) -> int:
	"""Sell item from inventory"""
	if not has_item(item_id, quantity):
		return 0

	var item_def = item_definitions.get(item_id, {})
	var total_value = item_def.get("value", 0) * quantity

	if remove_item(item_id, quantity):
		update_gold(total_value)
		print("Sold ", quantity, "x ", item_def.get("name", item_id), " for ", total_value, "g")
		return total_value

	return 0

func buy_item(item_id: String, quantity: int = 1) -> bool:
	"""Buy item and add to inventory"""
	if not item_definitions.has(item_id):
		return false

	var item_def = item_definitions[item_id]
	var total_cost = item_def["value"] * quantity

	if spend_gold(total_cost):
		add_item(item_id, quantity)
		return true

	return false

func get_inventory_summary() -> Dictionary:
	"""Get summary of all items in inventory"""
	var summary = {
		"gold": player_gold,
		"items": []
	}

	for item_id in inventory.keys():
		var item = inventory[item_id]
		summary["items"].append({
			"id": item_id,
			"name": item["name"],
			"quantity": item["quantity"],
			"type": item["type"],
			"value": item["value"]
		})

	return summary

func get_seeds_list() -> Array:
	"""Get list of all seed items"""
	var seeds = []
	for item_id in inventory.keys():
		if inventory[item_id]["type"] == "seed":
			seeds.append({
				"id": item_id,
				"name": inventory[item_id]["name"],
				"quantity": inventory[item_id]["quantity"],
				"crop_type": item_definitions[item_id].get("crop_type", "")
			})
	return seeds

func get_crops_list() -> Array:
	"""Get list of all harvested crops"""
	var crops = []
	for item_id in inventory.keys():
		if inventory[item_id]["type"] == "crop":
			crops.append({
				"id": item_id,
				"name": inventory[item_id]["name"],
				"quantity": inventory[item_id]["quantity"],
				"value": inventory[item_id]["value"]
			})
	return crops

func print_inventory():
	"""Debug: Print current inventory"""
	print("\n=== INVENTORY ===")
	print("Gold: ", player_gold, "g")
	for item_id in inventory.keys():
		var item = inventory[item_id]
		print("  ", item["name"], " x", item["quantity"])
	print("=================\n")
