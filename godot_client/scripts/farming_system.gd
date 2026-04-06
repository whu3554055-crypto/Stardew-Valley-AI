extends Node2D

# Farming System - Core Gameplay Loop
# Manages planting, growing, harvesting, and selling crops

signal crop_planted(tile_position: Vector2i, crop_type: String)
signal crop_grown(tile_position: Vector2i, crop_type: String)
signal crop_harvested(tile_position: Vector2i, crop_type: String, quantity: int)
signal crop_sold(crop_type: String, quantity: int, gold: int)

# Crop definitions
var crop_types = {
	"parsnip": {
		"name": "防风草",
		"grow_time": 3.0,  # days
		"seed_cost": 20,
		"harvest_value": 35,
		"harvest_quantity": 1,
		"seasons": ["spring"],
		"stages": 4
	},
	"potato": {
		"name": "土豆",
		"grow_time": 5.0,
		"seed_cost": 50,
		"harvest_value": 80,
		"harvest_quantity": 1,
		"seasons": ["spring"],
		"stages": 5
	},
	"cauliflower": {
		"name": "花椰菜",
		"grow_time": 10.0,
		"seed_cost": 80,
		"harvest_value": 175,
		"harvest_quantity": 1,
		"seasons": ["spring"],
		"stages": 6
	},
	"corn": {
		"name": "玉米",
		"grow_time": 12.0,
		"seed_cost": 150,
		"harvest_value": 50,
		"harvest_quantity": 2,
		"seasons": ["summer", "fall"],
		"stages": 7
	}
}

# Farm plot data: { "x_y": { "crop_type": String, "planted_day": int, "current_stage": int, "watered": bool } }
var farm_plots = {}

@onready var tilemap = $FarmTileMap
@onready var crop_sprites = $CropSprites

var current_season = "spring"
var current_day = 1

func _ready():
	print("Farming system initialized")
	setup_farm_area()

func setup_farm_area():
	"""Setup the farm area with tillable soil"""
	if tilemap:
		# Create a simple 8x8 farm grid
		for x in range(8):
			for y in range(8):
				var pos = Vector2i(x, y)
				tilemap.set_cell(pos, 0, Vector2i(0, 0))  # Soil tile

func plant_seed(tile_position: Vector2i, crop_type: String) -> bool:
	"""Plant a seed at the specified tile"""
	if not crop_types.has(crop_type):
		print("Unknown crop type: ", crop_type)
		return false

	var key = "%d_%d" % [tile_position.x, tile_position.y]

	# Check if tile is already occupied
	if farm_plots.has(key):
		print("Tile already occupied")
		return false

	var crop_data = crop_types[crop_type]

	# Check season compatibility
	if not current_season in crop_data["seasons"]:
		print("Wrong season for ", crop_data["name"])
		return false

	# Plant the seed
	farm_plots[key] = {
		"crop_type": crop_type,
		"planted_day": current_day,
		"current_stage": 0,
		"watered": false,
		"position": tile_position
	}

	# Create visual representation
	create_crop_sprite(tile_position, crop_type, 0)

	emit_signal("crop_planted", tile_position, crop_type)
	print("Planted ", crop_data["name"], " at ", tile_position)
	return true

func update_crop_growth():
	"""Update all crop growth stages (called daily)"""
	for key in farm_plots.keys():
		var plot = farm_plots[key]
		var crop_data = crop_types[plot["crop_type"]]

		# Check if crop should grow
		if plot["current_stage"] < crop_data["stages"]:
			# Watered crops grow faster
			var growth_rate = 1.0 if plot["watered"] else 0.5

			# Calculate if crop should advance stage
			var days_since_plant = current_day - plot["planted_day"]
			var expected_stage = int((days_since_plant / crop_data["grow_time"]) * crop_data["stages"] * growth_rate)
			expected_stage = min(expected_stage, crop_data["stages"])

			if expected_stage > plot["current_stage"]:
				plot["current_stage"] = expected_stage
				update_crop_visual(Vector2i(plot["position"].x, plot["position"].y), plot["crop_type"], expected_stage)

				# Check if fully grown
				if expected_stage >= crop_data["stages"]:
					emit_signal("crop_grown", plot["position"], plot["crop_type"])
					print("Crop fully grown: ", crop_data["name"])

		# Reset watered status for new day
		plot["watered"] = false

func water_crop(tile_position: Vector2i) -> bool:
	"""Water a crop at the specified tile"""
	var key = "%d_%d" % [tile_position.x, tile_position.y]

	if not farm_plots.has(key):
		return false

	farm_plots[key]["watered"] = true
	print("Watered crop at ", tile_position)

	# Visual feedback
	show_water_effect(tile_position)
	return true

func harvest_crop(tile_position: Vector2i) -> Dictionary:
	"""Harvest a crop at the specified tile"""
	var key = "%d_%d" % [tile_position.x, tile_position.y]

	if not farm_plots.has(key):
		return {"success": false, "reason": "No crop here"}

	var plot = farm_plots[key]
	var crop_data = crop_types[plot["crop_type"]]

	# Check if crop is fully grown
	if plot["current_stage"] < crop_data["stages"]:
		return {"success": false, "reason": "Crop not ready"}

	# Harvest the crop
	var quantity = crop_data["harvest_quantity"]
	var value = crop_data["harvest_value"] * quantity

	# Remove from farm plots
	farm_plots.erase(key)

	# Remove visual
	remove_crop_visual(tile_position)

	emit_signal("crop_harvested", tile_position, plot["crop_type"], quantity)
	print("Harvested ", quantity, "x ", crop_data["name"], " worth ", value, "g")

	return {
		"success": true,
		"crop_type": plot["crop_type"],
		"quantity": quantity,
		"value": value
	}

func sell_crop(crop_type: String, quantity: int) -> int:
	"""Sell harvested crops"""
	if not crop_types.has(crop_type):
		return 0

	var crop_data = crop_types[crop_type]
	var total_value = crop_data["harvest_value"] * quantity

	emit_signal("crop_sold", crop_type, quantity, total_value)
	print("Sold ", quantity, "x ", crop_data["name"], " for ", total_value, "g")

	return total_value

func create_crop_sprite(position: Vector2i, crop_type: String, stage: int):
	"""Create visual sprite for crop"""
	if not crop_sprites:
		return

	var sprite = Sprite2D.new()
	sprite.name = "crop_%d_%d" % [position.x, position.y]
	sprite.position = Vector2(position.x * 64 + 32, position.y * 64 + 32)
	sprite.scale = Vector2(0.5, 0.5)

	# Load crop texture based on type and stage
	var texture_path = "res://assets/sprites/crops/%s_stage_%d.png" % [crop_type, stage]
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		# Fallback: colored rectangle
		var color = get_stage_color(stage)
		sprite.modulate = color

	crop_sprites.add_child(sprite)

func update_crop_visual(position: Vector2i, crop_type: String, stage: int):
	"""Update crop visual when it grows"""
	var sprite_name = "crop_%d_%d" % [position.x, position.y]
	if crop_sprites.has_node(sprite_name):
		var sprite = crop_sprites.get_node(sprite_name)
		var texture_path = "res://assets/sprites/crops/%s_stage_%d.png" % [crop_type, stage]
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
		else:
			sprite.modulate = get_stage_color(stage)

func remove_crop_visual(position: Vector2i):
	"""Remove crop visual after harvest"""
	var sprite_name = "crop_%d_%d" % [position.x, position.y]
	if crop_sprites.has_node(sprite_name):
		crop_sprites.get_node(sprite_name).queue_free()

func show_water_effect(position: Vector2i):
	"""Show watering effect"""
	if not crop_sprites:
		return

	var effect = Sprite2D.new()
	effect.position = Vector2(position.x * 64 + 32, position.y * 64 + 32)
	effect.scale = Vector2(0.5, 0.5)

	# Blue tint for water
	effect.modulate = Color(0.5, 0.5, 1.0, 0.5)

	crop_sprites.add_child(effect)

	# Fade out
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect.queue_free)

func get_stage_color(stage: int) -> Color:
	"""Get color representation for growth stage"""
	match stage:
		0: return Color(0.6, 0.4, 0.2, 1)  # Seed (brown)
		1: return Color(0.4, 0.7, 0.2, 1)  # Sprout (light green)
		2: return Color(0.3, 0.6, 0.2, 1)  # Growing (green)
		3: return Color(0.2, 0.5, 0.2, 1)  # Maturing (dark green)
		_: return Color(0.2, 0.4, 0.2, 1)  # Mature (very dark green)

func get_plot_info(tile_position: Vector2i) -> Dictionary:
	"""Get information about a farm plot"""
	var key = "%d_%d" % [tile_position.x, tile_position.y]
	if farm_plots.has(key):
		return farm_plots[key]
	return {}

func advance_day():
	"""Called when a new day starts"""
	current_day += 1
	update_crop_growth()
	print("Day advanced to ", current_day)

func set_season(season: String):
	"""Set current season"""
	current_season = season
	print("Season changed to ", season)
