extends Control

class_name InventoryUI

const SLOT_SIZE = 48
const SLOTS_PER_ROW = 9

@onready var grid_container = $GridContainer
@onready var item_preview = $ItemPreview

var slot_buttons = []

signal item_selected(slot_index)

func _ready():
	create_inventory_grid()
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	InventoryManager.selected_slot_changed.connect(_on_selected_slot_changed)
	_on_inventory_updated()

func create_inventory_grid():
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()

	slot_buttons.clear()

	# Create inventory slots
	for row in range(4):
		for col in range(SLOTS_PER_ROW):
			var slot_index = row * SLOTS_PER_ROW + col
			var button = Button.new()
			button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			button.name = "Slot%d" % slot_index
			button.pressed.connect(_on_slot_pressed.bind(slot_index))
			grid_container.add_child(button)
			slot_buttons.append(button)

func _on_inventory_updated():
	for i in range(slot_buttons.size()):
		var item = InventoryManager.get_item(i)
		var button = slot_buttons[i]

		if item:
			button.text = "%s\nx%d" % [item.name, item.stack]
		else:
			button.text = ""

		# Highlight selected slot
		if i == InventoryManager.selected_slot:
			button.modulate = Color(1, 1, 0.5)
		else:
			button.modulate = Color.WHITE

func _on_selected_slot_changed(slot: int):
	_on_inventory_updated()

func _on_slot_pressed(slot_index: int):
	InventoryManager.set_selected_slot(slot_index)
	item_selected.emit(slot_index)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
