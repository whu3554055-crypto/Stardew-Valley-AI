extends Node

# Inventory system
const INVENTORY_SIZE = 36

var inventory = []
var selected_slot = 0

signal inventory_updated
signal selected_slot_changed(slot)

func _ready():
	# Initialize empty inventory
	for i in range(INVENTORY_SIZE):
		inventory.append(null)

func add_item(item_data: Dictionary) -> bool:
	# Try to stack with existing items first
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i].id == item_data.id:
			if inventory[i].stack < inventory[i].max_stack:
				inventory[i].stack += 1
				inventory_updated.emit()
				return true

	# Find empty slot
	for i in range(INVENTORY_SIZE):
		if inventory[i] == null:
			inventory[i] = item_data.duplicate()
			inventory[i].stack = 1
			if inventory[i].has("max_durability") and not inventory[i].has("durability"):
				inventory[i].durability = int(inventory[i].max_durability)
			inventory_updated.emit()
			return true

	return false  # Inventory full

func remove_item(slot: int, amount: int = 1) -> bool:
	if slot >= 0 and slot < INVENTORY_SIZE and inventory[slot] != null:
		inventory[slot].stack -= amount
		if inventory[slot].stack <= 0:
			inventory[slot] = null
		inventory_updated.emit()
		return true
	return false

func get_item(slot: int) -> Dictionary:
	if slot >= 0 and slot < INVENTORY_SIZE:
		return inventory[slot]
	return null

func set_selected_slot(slot: int):
	if slot >= 0 and slot < INVENTORY_SIZE:
		selected_slot = slot
		selected_slot_changed.emit(slot)

func get_selected_item() -> Dictionary:
	return get_item(selected_slot)

func count_item(item_id: String) -> int:
	var n := 0
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i].id == item_id:
			n += inventory[i].stack
	return n

func damage_tool_slot(slot: int, amount: int = 1) -> bool:
	if slot < 0 or slot >= INVENTORY_SIZE:
		return false
	var item = inventory[slot]
	if item == null or not item.has("max_durability"):
		return true
	if not item.has("durability"):
		item.durability = int(item.max_durability)
	item.durability = int(item.durability) - amount
	if item.durability <= 0:
		inventory[slot] = null
	inventory_updated.emit()
	return true

func consume_item_by_id(item_id: String, amount: int = 1) -> bool:
	if count_item(item_id) < amount:
		return false
	var remaining: int = amount
	for i in range(INVENTORY_SIZE):
		if remaining <= 0:
			break
		if inventory[i] == null or inventory[i].id != item_id:
			continue
		var take: int = mini(remaining, inventory[i].stack)
		inventory[i].stack -= take
		remaining -= take
		if inventory[i].stack <= 0:
			inventory[i] = null
	inventory_updated.emit()
	return true

func clear_inventory():
	for i in range(INVENTORY_SIZE):
		inventory[i] = null
	inventory_updated.emit()
