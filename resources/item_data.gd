class_name ItemData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var type: String = "misc"  # seed, crop, tool, etc.
@export var stack: int = 1
@export var max_stack: int = 99
@export var sell_price: int = 0
@export var properties: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_type: String = "misc"):
	id = p_id
	name = p_name
	type = p_type
