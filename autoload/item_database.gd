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

	items["corn_seeds"] = {
		"id": "corn_seeds",
		"name": "Corn Seeds",
		"description": "Summer crop — tall stalks that keep producing after the first harvest.",
		"type": "seed",
		"crop_id": "corn",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 150,
		"sell_price": 75
	}

	items["basic_fertilizer"] = {
		"id": "basic_fertilizer",
		"name": "Basic Fertilizer",
		"description": "Use on empty tilled soil before planting — the next crop matures one day sooner (min 2 days).",
		"type": "fertilizer",
		"stack": 1,
		"max_stack": 99,
		"buy_price": 35,
		"sell_price": 12
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

	items["corn"] = {
		"id": "corn",
		"name": "Corn",
		"description": "Sweet summer corn — harvest repeats the stalk after the first pick.",
		"type": "crop",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 55,
		"stamina_restore": 20.0
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

	items["grilled_tuna"] = {
		"id": "grilled_tuna",
		"name": "Grilled Tuna",
		"description": "Hearty ocean flavor from the kitchen counter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 155,
		"stamina_restore": 48.0
	}

	items["grilled_catfish"] = {
		"id": "grilled_catfish",
		"name": "Grilled Catfish",
		"description": "River catch, simple grill.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 98,
		"stamina_restore": 36.0
	}

	items["grilled_mackerel"] = {
		"id": "grilled_mackerel",
		"name": "Grilled Mackerel",
		"description": "Oily and satisfying.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 92,
		"stamina_restore": 34.0
	}

	items["grilled_pike"] = {
		"id": "grilled_pike",
		"name": "Grilled Pike",
		"description": "Firm white meat from a river hunter.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 118,
		"stamina_restore": 40.0
	}

	items["grilled_halibut"] = {
		"id": "grilled_halibut",
		"name": "Grilled Halibut",
		"description": "Thick flakes — worth the long fight.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 158,
		"stamina_restore": 44.0
	}

	items["fish_stew"] = {
		"id": "fish_stew",
		"name": "Fish Stew",
		"description": "Carp and potato in one warm bowl.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 175,
		"stamina_restore": 58.0
	}

	items["field_stir_fry"] = {
		"id": "field_stir_fry",
		"name": "Field Stir-Fry",
		"description": "Parsnip and potato — simple farm comfort food.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 130,
		"stamina_restore": 44.0
	}

	items["hearty_braise"] = {
		"id": "hearty_braise",
		"name": "Hearty River Braise",
		"description": "Carp, perch, and potato — three ingredients, one filling meal.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 240,
		"stamina_restore": 72.0
	}

	items["garden_pot_pie"] = {
		"id": "garden_pot_pie",
		"name": "Garden Pot Pie",
		"description": "Parsnip, potato, and cauliflower under a crust of hope.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 380,
		"stamina_restore": 68.0
	}

	items["ocean_skillet"] = {
		"id": "ocean_skillet",
		"name": "Ocean Skillet",
		"description": "Sardine and mackerel on bread — salty harbor lunch.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 210,
		"stamina_restore": 58.0
	}

	items["tuna_bowl"] = {
		"id": "tuna_bowl",
		"name": "Tuna Harvest Bowl",
		"description": "Tuna with cauliflower and potato — a full plate from sea and soil.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 420,
		"stamina_restore": 78.0
	}

	items["sap_glazed_toast"] = {
		"id": "sap_glazed_toast",
		"name": "Sap-Glazed Toast",
		"description": "Shop bread brushed with tree sap from the forest — sweet and filling.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 95,
		"stamina_restore": 52.0
	}

	items["sap_glazed_catfish"] = {
		"id": "sap_glazed_catfish",
		"name": "Sap-Glazed Catfish",
		"description": "River catfish with a sticky sap glaze — forest meets the river.",
		"type": "food",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 128,
		"stamina_restore": 48.0
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
		"description": "Equip and press E in the forest (west) to chop wood.",
		"type": "tool",
		"stack": 1,
		"max_stack": 1,
		"sell_price": 0,
		"max_durability": 100
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

	items["fish_tuna"] = {
		"id": "fish_tuna",
		"name": "Tuna",
		"description": "A hefty ocean fish — rarest toward the south sea at night.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 95,
		"stamina_restore": 28.0
	}

	items["fish_catfish"] = {
		"id": "fish_catfish",
		"name": "Catfish",
		"description": "Whiskered river dweller — more active after dark.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 62,
		"stamina_restore": 22.0
	}

	items["fish_mackerel"] = {
		"id": "fish_mackerel",
		"name": "Mackerel",
		"description": "Striped and oily — common in open water by day.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 58,
		"stamina_restore": 20.0
	}

	items["fish_pike"] = {
		"id": "fish_pike",
		"name": "Northern Pike",
		"description": "River predator — more common at night, in winter, and when the water churns.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 78,
		"stamina_restore": 24.0
	}

	items["fish_halibut"] = {
		"id": "fish_halibut",
		"name": "Halibut",
		"description": "Flat ocean fish — favors mornings and cold seasons.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 105,
		"stamina_restore": 26.0
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

	items["junk_seaweed"] = {
		"id": "junk_seaweed",
		"name": "Seaweed Clump",
		"description": "Ocean junk. Not worth much.",
		"type": "fish",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 1
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

	items["silver_ore"] = {
		"id": "silver_ore",
		"name": "Silver Ore",
		"description": "Found in the lowest mine band with an iron pick — smelt into bars.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 88
	}

	items["quartz"] = {
		"id": "quartz",
		"name": "Quartz",
		"description": "A clear shard from deep rock — sells for a little extra.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 85
	}

	items["geode"] = {
		"id": "geode",
		"name": "Geode",
		"description": "A lumpy stone from the upper mine — crack it open… or sell it.",
		"type": "mineral",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 95
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

	items["silver_bar"] = {
		"id": "silver_bar",
		"name": "Silver Bar",
		"description": "Refined silver — between iron and gold in value.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 420
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

	items["wood_log"] = {
		"id": "wood_log",
		"name": "Wood",
		"description": "Logs from chopping trees.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 5
	}

	items["tree_sap"] = {
		"id": "tree_sap",
		"name": "Tree Sap",
		"description": "Sticky sap from forest trees; sometimes drops when chopping.",
		"type": "resource",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 15
	}

	items["sprinkler_basic"] = {
		"id": "sprinkler_basic",
		"name": "Basic Sprinkler",
		"description": "Place on empty tilled soil (E). Waters four ortho neighbors daily. Use pickaxe on the tile to pick it back up.",
		"type": "tool",
		"stack": 1,
		"max_stack": 99,
		"sell_price": 420
	}

func resolve_icon_path(item_id: String) -> String:
	var id: String = item_id.strip_edges()
	if id.is_empty():
		return ""
	# Seed bags: reuse harvested crop icon when available (e.g. parsnip_seeds → parsnip.png).
	if id.ends_with("_seeds"):
		var crop_id: String = id.trim_suffix("_seeds")
		var seed_crop: String = "res://assets/sprites/items/crops/%s.png" % crop_id
		if ResourceLoader.exists(seed_crop):
			return seed_crop
	var candidates: PackedStringArray = PackedStringArray([
		"res://assets/sprites/items/crops/%s.png" % id,
		"res://assets/sprites/items/tools/%s.png" % id,
		"res://assets/sprites/items/resources/%s.png" % id,
		"res://assets/sprites/items/consumables/%s.png" % id,
	])
	for p in candidates:
		if ResourceLoader.exists(p):
			return p
	var it: Dictionary = get_item(id)
	if not it.is_empty() and str(it.get("type", "")) == "fish":
		if ResourceLoader.exists("res://assets/sprites/environment/water/fish_small.png"):
			return "res://assets/sprites/environment/water/fish_small.png"
	# Tools / misc without dedicated inventory art yet
	match id:
		"fishing_rod":
			if ResourceLoader.exists("res://assets/sprites/environment/water/fish_small.png"):
				return "res://assets/sprites/environment/water/fish_small.png"
		"pickaxe", "pickaxe_iron":
			if ResourceLoader.exists("res://assets/sprites/items/resources/stone.png"):
				return "res://assets/sprites/items/resources/stone.png"
		"worm_bait":
			if ResourceLoader.exists("res://assets/sprites/environment/greenery/grass_clump.png"):
				return "res://assets/sprites/environment/greenery/grass_clump.png"
		"sprinkler_basic":
			if ResourceLoader.exists("res://assets/sprites/items/tools/watering_can.png"):
				return "res://assets/sprites/items/tools/watering_can.png"
		"basic_fertilizer":
			if ResourceLoader.exists("res://assets/sprites/environment/greenery/grass_clump.png"):
				return "res://assets/sprites/environment/greenery/grass_clump.png"
		"tree_sap":
			if ResourceLoader.exists("res://assets/sprites/items/resources/wood.png"):
				return "res://assets/sprites/items/resources/wood.png"
		"sap_glazed_toast":
			if ResourceLoader.exists("res://assets/sprites/items/consumables/bread.png"):
				return "res://assets/sprites/items/consumables/bread.png"
		"sap_glazed_catfish":
			if ResourceLoader.exists("res://assets/sprites/environment/water/fish_small.png"):
				return "res://assets/sprites/environment/water/fish_small.png"
	return ""

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func get_item_by_id(item_id: String) -> Dictionary:
	return get_item(item_id)

func get_all_item_ids() -> Array:
	return items.keys()

func get_all_items() -> Array:
	return items.values()
