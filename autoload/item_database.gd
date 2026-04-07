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
		"sell_price": 35,
		"stamina_restore": 18.0
	}

	items["cauliflower"] = {
		"id": "cauliflower",
		"name": "Cauliflower",
		"description": "A valuable crop that takes a while to grow.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 175,
		"stamina_restore": 28.0
	}

	items["potato"] = {
		"id": "potato",
		"name": "Potato",
		"description": "A versatile crop with a chance for extra yield.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 80,
		"stamina_restore": 22.0
	}

	items["bread"] = {
		"id": "bread",
		"name": "Bread",
		"description": "Simple bread. Eat to restore energy.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 50,
		"sell_price": 20,
		"stamina_restore": 45.0
	}

	items["fish_sandwich"] = {
		"id": "fish_sandwich",
		"name": "Fish Sandwich",
		"description": "Bread and grilled fish. Cook at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 95,
		"stamina_restore": 62.0
	}

	items["grilled_sardine"] = {
		"id": "grilled_sardine",
		"name": "Grilled Sardine",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 55,
		"stamina_restore": 28.0
	}

	items["grilled_perch"] = {
		"id": "grilled_perch",
		"name": "Grilled Perch",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 72,
		"stamina_restore": 34.0
	}

	items["grilled_trout"] = {
		"id": "grilled_trout",
		"name": "Grilled Trout",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 85,
		"stamina_restore": 32.0
	}

	items["grilled_carp"] = {
		"id": "grilled_carp",
		"name": "Grilled Carp",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 62,
		"stamina_restore": 30.0
	}

	items["roasted_parsnip"] = {
		"id": "roasted_parsnip",
		"name": "Roasted Parsnip",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 48,
		"stamina_restore": 32.0
	}

	items["baked_potato"] = {
		"id": "baked_potato",
		"name": "Baked Potato",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 98,
		"stamina_restore": 38.0
	}

	items["roasted_cauliflower"] = {
		"id": "roasted_cauliflower",
		"name": "Roasted Cauliflower",
		"description": "Cooked at the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 220,
		"stamina_restore": 42.0
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
		"sell_price": 0,
		"max_durability": 100
	}

	items["pickaxe_iron"] = {
		"id": "pickaxe_iron",
		"name": "Iron Pickaxe",
		"description": "Stronger pick; can reach deep gold veins.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0,
		"max_durability": 140
	}

	items["fishing_rod"] = {
		"id": "fishing_rod",
		"name": "Fishing Rod",
		"description": "Equip and press E at water to fish.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0
	}

	items["worm_bait"] = {
		"id": "worm_bait",
		"name": "Worm Bait",
		"description": "Consumes on a successful catch to improve odds.",
		"type": "bait",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 8,
		"sell_price": 2
	}

	# Fishing (MVP)
	items["fish_sardine"] = {
		"id": "fish_sardine",
		"name": "Sardine",
		"description": "A small silvery fish.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 40,
		"stamina_restore": 16.0
	}

	items["fish_perch"] = {
		"id": "fish_perch",
		"name": "Perch",
		"description": "A freshwater favorite.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 55,
		"stamina_restore": 20.0
	}

	items["fish_trout"] = {
		"id": "fish_trout",
		"name": "Trout",
		"description": "Quick and prized in rivers.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 65,
		"stamina_restore": 18.0
	}

	items["fish_carp"] = {
		"id": "fish_carp",
		"name": "Carp",
		"description": "Common but filling.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 45,
		"stamina_restore": 18.0
	}

	items["junk_boot"] = {
		"id": "junk_boot",
		"name": "Old Boot",
		"description": "Not edible. Maybe recyclable?",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 2
	}

	# Mining (MVP)
	items["stone_chunk"] = {
		"id": "stone_chunk",
		"name": "Stone",
		"description": "Rough stone from the cave wall.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 5
	}

	items["copper_ore"] = {
		"id": "copper_ore",
		"name": "Copper Ore",
		"description": "Can be smelted later.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 25
	}

	items["coal"] = {
		"id": "coal",
		"name": "Coal",
		"description": "Fuel and smelting material.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 18
	}

	items["iron_ore"] = {
		"id": "iron_ore",
		"name": "Iron Ore",
		"description": "Smelt into bars.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 35
	}

	items["gold_ore"] = {
		"id": "gold_ore",
		"name": "Gold Ore",
		"description": "Rare; needs a strong pick at depth.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 120
	}

	items["copper_bar"] = {
		"id": "copper_bar",
		"name": "Copper Bar",
		"description": "Smelted metal for crafting.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 180
	}

	items["iron_bar"] = {
		"id": "iron_bar",
		"name": "Iron Bar",
		"description": "Refined iron.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 250
	}

	items["gold_bar"] = {
		"id": "gold_bar",
		"name": "Gold Bar",
		"description": "Valuable refined gold.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 650
	}

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_item_by_id(item_id: String) -> Dictionary:
	return get_item(item_id)

func get_all_item_ids() -> Array:
	return items.keys()

func get_all_items() -> Array:
	return items.values()
