class_name CropData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var seed_item_id: String = ""
@export var growth_days: int = 3
@export var harvest_product: String = ""
@export var harvest_count: int = 1
@export var regrows: bool = false
@export var regrow_days: int = 0
@export var seasons: Array = ["spring"]
@export var sprite_frames: Array  # Growth stage sprites

func get_growth_stage(days_grown: int) -> int:
	var stage = int(float(days_grown) / growth_days * 4)
	return clamp(stage, 0, 4)
