extends Area2D

# Farm Plot - Interactive tile for planting/harvesting
# Attached to each farmable tile

@export var tile_position: Vector2i = Vector2i(0, 0)
var is_tilled = true
var has_crop = false

@onready var sprite = $Sprite
@onready var interaction_label = $InteractionLabel

var farming_system = null
var inventory_system = null

func _ready():
	interaction_label.visible = false
	find_systems()

func find_systems():
	"""Find farming and inventory systems"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		if main.has_node("TownSquare/FarmingSystem"):
			farming_system = main.get_node("TownSquare/FarmingSystem")
		if main.has_node("TownSquare/InventorySystem"):
			inventory_system = main.get_node("TownSquare/InventorySystem")

func _on_mouse_entered():
	"""Show interaction hint when hovering"""
	if is_tilled:
		update_interaction_label()
		interaction_label.visible = true

func _on_mouse_exited():
	"""Hide interaction hint"""
	interaction_label.visible = false

func update_interaction_label():
	"""Update the interaction prompt based on plot state"""
	if not farming_system:
		return

	var plot_info = farming_system.get_plot_info(tile_position)

	if plot_info.is_empty():
		interaction_label.text = "点击种植"
	elif plot_info.get("current_stage", 0) < get_crop_stages(plot_info.get("crop_type", "")):
		interaction_label.text = "点击浇水"
	else:
		interaction_label.text = "点击收获"

func get_crop_stages(crop_type: String) -> int:
	"""Get number of growth stages for crop"""
	if farming_system and farming_system.crop_types.has(crop_type):
		return farming_system.crop_types[crop_type]["stages"]
	return 4

func interact(player_message: String = ""):
	"""Handle player interaction with this plot"""
	if not farming_system or not inventory_system:
		print("Systems not found!")
		return

	var plot_info = farming_system.get_plot_info(tile_position)

	if plot_info.is_empty():
		# Try to plant a seed
		try_plant()
	elif plot_info.get("current_stage", 0) >= get_crop_stages(plot_info.get("crop_type", "")):
		# Harvest mature crop
		try_harvest()
	else:
		# Water the crop
		try_water()

func try_plant():
	"""Plant a seed if player has one"""
	var seeds = inventory_system.get_seeds_list()

	if seeds.is_empty():
		print("No seeds in inventory!")
		show_feedback("没有种子了！")
		return

	# Use first available seed (simplified - should show selection UI)
	var seed = seeds[0]
	var crop_type = seed.get("crop_type", "")

	if crop_type.is_empty():
		return

	if inventory_system.remove_item(seed["id"], 1):
		if farming_system.plant_seed(tile_position, crop_type):
			show_feedback("种植了 " + farming_system.crop_types[crop_type]["name"])
		else:
			# Refund seed if planting failed
			inventory_system.add_item(seed["id"], 1)

func try_water():
	"""Water the crop"""
	if farming_system.water_crop(tile_position):
		show_feedback("已浇水")

func try_harvest():
	"""Harvest mature crop"""
	var result = farming_system.harvest_crop(tile_position)

	if result["success"]:
		var crop_type = result["crop_type"]
		var quantity = result["quantity"]

		# Add harvested crop to inventory
		if inventory_system.add_item(crop_type, quantity):
			show_feedback("收获了 " + str(quantity) + "x " + farming_system.crop_types[crop_type]["name"])
	else:
		show_feedback(result.get("reason", "无法收获"))

func show_feedback(text: String):
	"""Show temporary feedback text"""
	interaction_label.text = text
	interaction_label.visible = true

	var timer = get_tree().create_timer(1.5)
	await timer.timeout
	interaction_label.visible = false
	update_interaction_label()

func _input_event(viewport, event, shape_idx):
	"""Handle mouse click on plot"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact()
		get_viewport().set_input_as_handled()
