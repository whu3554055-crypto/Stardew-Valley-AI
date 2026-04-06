extends Node

class_name ItemDatabase

# Item database singleton
var items = {}

func _ready():
	initialize_items()

func initialize_items():
	# Seeds
	items["parsnip_seeds"] = {
		"id": "parsnip_seeds",
		"name": "Parsnip Seeds",
		"description": "Plant these to grow parsnips.",
		"type": "seed",
		"crop_id": "parsnip",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 20,
		"sell_price": 10
	}

	items["cauliflower_seeds"] = {
		"id": "cauliflower_seeds",
		"name": "Cauliflower Seeds",
		"description": "Plant these to grow cauliflower.",
		"type": "seed",
		"crop_id": "cauliflower",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 80,
		"sell_price": 40
	}

	items["potato_seeds"] = {
		"id": "potato_seeds",
		"name": "Potato Seeds",
		"description": "Plant these to grow potatoes.",
		"type": "seed",
		"crop_id": "potato",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 50,
		"sell_price": 25
	}

	# Crops (harvested)
	items["parsnip"] = {
		"id": "parsnip",
		"name": "Parsnip",
		"description": "A root vegetable that tastes sweet and earthy.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 35
	}

	items["cauliflower"] = {
		"id": "cauliflower",
		"name": "Cauliflower",
		"description": "A valuable crop that takes a while to grow.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 175
	}

	items["potato"] = {
		"id": "potato",
		"name": "Potato",
		"description": "A versatile crop with a chance for extra yield.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 80
	}

	# Tools
	items["hoe"] = {
		"id": "hoe",
		"name": "Hoe",
		"description": "Used to till soil for planting.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0
	}

	items["watering_can"] = {
		"id": "watering_can",
		"name": "Watering Can",
		"description": "Used to water your crops.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0
	}

	items["axe"] = {
		"id": "axe",
		"name": "Axe",
		"description": "Used to chop wood.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0
	}

	items["pickaxe"] = {
		"id": "pickaxe",
		"name": "Pickaxe",
		"description": "Used to break stones.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0
	}

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_all_items() -> Array:
	return items.values()
