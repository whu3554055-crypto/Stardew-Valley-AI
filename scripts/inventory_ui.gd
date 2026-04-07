extends Control

class_name InventoryUI

const SLOT_SIZE = 48
const SLOTS_PER_ROW = 9

@onready var stamina_bar: ProgressBar = $MarginContainer/VBox/StaminaBar
@onready var grid_container: GridContainer = $MarginContainer/VBox/GridContainer

var slot_buttons = []

signal item_selected(slot_index)

func _ready():
	create_inventory_grid()
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	InventoryManager.selected_slot_changed.connect(_on_selected_slot_changed)
	_on_inventory_updated()

func _process(_delta: float) -> void:
	if not visible or not stamina_bar or not GameManager:
		return
	var s: float = float(GameManager.player_data.get("stamina", 100.0))
	var sm: float = float(GameManager.player_data.get("stamina_max", 100.0))
	stamina_bar.max_value = maxf(1.0, sm)
	stamina_bar.value = clampf(s, 0.0, stamina_bar.max_value)

func create_inventory_grid():
	for child in grid_container.get_children():
		child.queue_free()

	slot_buttons.clear()

	for row in range(4):
		for col in range(SLOTS_PER_ROW):
			var slot_index = row * SLOTS_PER_ROW + col
			var button = Button.new()
			button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			button.name = "Slot%d" % slot_index
			button.add_theme_font_size_override("font_size", 10)
			button.pressed.connect(_on_slot_pressed.bind(slot_index))
			grid_container.add_child(button)
			slot_buttons.append(button)

func _slot_button_text(item: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(str(item.get("name", "?")))
	lines.append("x%d" % int(item.get("stack", 1)))
	if item.has("max_durability"):
		var m: int = int(item.get("max_durability", 0))
		var d: int = int(item.get("durability", m))
		lines.append("%d/%d" % [d, m])
	return "\n".join(lines)

func _slot_compact_text(item: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("x%d" % int(item.get("stack", 1)))
	if item.has("max_durability"):
		var m: int = int(item.get("max_durability", 0))
		var d: int = int(item.get("durability", m))
		lines.append("%d/%d" % [d, m])
	return "\n".join(lines)

func _slot_tooltip(item: Dictionary) -> String:
	var nm: String = str(item.get("name", ""))
	if item.has("max_durability"):
		var m: int = int(item.get("max_durability", 0))
		var d: int = int(item.get("durability", m))
		return "%s — durability %d/%d" % [nm, d, m]
	return nm

func _on_inventory_updated():
	for i in range(slot_buttons.size()):
		var item = InventoryManager.get_item(i)
		var button = slot_buttons[i]

		if item:
			var id: String = str(item.get("id", ""))
			var icon_path: String = ""
			if ItemDatabase:
				icon_path = ItemDatabase.resolve_icon_path(id)
			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				button.icon = load(icon_path) as Texture2D
				button.expand_icon = true
				button.text = _slot_compact_text(item)
				button.tooltip_text = _slot_tooltip(item)
			else:
				button.icon = null
				button.expand_icon = false
				button.text = _slot_button_text(item)
				button.tooltip_text = ""
		else:
			button.icon = null
			button.expand_icon = false
			button.text = ""
			button.tooltip_text = ""

		if i == InventoryManager.selected_slot:
			button.modulate = Color(1, 1, 0.5)
		else:
			button.modulate = Color.WHITE

func _on_selected_slot_changed(_slot: int):
	_on_inventory_updated()

func _on_slot_pressed(slot_index: int):
	InventoryManager.set_selected_slot(slot_index)
	item_selected.emit(slot_index)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
