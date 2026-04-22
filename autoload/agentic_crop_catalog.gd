extends Node
## AgenticCropCatalog - Manages crop data and season mappings.
## Provides quick lookup for crop-related information.
##
## Responsibilities:
## - Load crop catalog from JSON
## - Map crops to seasons
## - Validate crop-season combinations
## - Provide crop queries

# === 常量 ===

const CROP_DATA_PATH := "res://data/farm/crops.json"

# === 成员变量 ===

var _crop_seasons_by_id: Dictionary = {}
var _crop_data_by_id: Dictionary = {}
var _is_loaded: bool = false

# === 信号 ===

signal catalog_loaded(crop_count: int)
signal catalog_load_failed(error: String)

# === 生命周期方法 ===

func _ready() -> void:
	_load_crop_catalog()

# === 公共方法 ===

## Load crop catalog from file
func load_catalog() -> bool:
	"""Load or reload crop catalog"""
	return _load_crop_catalog()

## Get season for a specific crop
func get_crop_season(crop_id: String) -> String:
	"""
	Get the growing season for a crop.
	Returns: season string or empty if not found
	"""
	return _crop_seasons_by_id.get(crop_id, "")

## Check if crop is valid for a season
func is_crop_valid_for_season(crop_id: String, season: String) -> bool:
	"""Check if crop can grow in specified season"""
	var crop_season = get_crop_season(crop_id)
	
	if crop_season.is_empty():
		return false
	
	# Some crops may grow in multiple seasons
	if crop_season is Array:
		return season in crop_season
	
	return crop_season == season

## Get all crops for a specific season
func get_crops_for_season(season: String) -> Array[String]:
	"""Get list of crop IDs that grow in given season"""
	var crops: Array[String] = []
	
	for crop_id in _crop_seasons_by_id.keys():
		var crop_season = _crop_seasons_by_id[crop_id]
		
		if crop_season is Array:
			if season in crop_season:
				crops.append(crop_id)
		elif crop_season == season:
			crops.append(crop_id)
	
	return crops

## Get detailed crop data
func get_crop_data(crop_id: String) -> Dictionary:
	"""Get full crop data dictionary"""
	return _crop_data_by_id.get(crop_id, {})

## Get all crop IDs
func get_all_crop_ids() -> Array[String]:
	"""Get list of all known crop IDs"""
	return _crop_seasons_by_id.keys()

## Check if crop exists
func has_crop(crop_id: String) -> bool:
	"""Check if crop is in catalog"""
	return _crop_seasons_by_id.has(crop_id)

## Get catalog statistics
func get_catalog_stats() -> Dictionary:
	"""Get statistics about loaded catalog"""
	var season_counts: Dictionary = {}
	
	for crop_id in _crop_seasons_by_id.keys():
		var season = _crop_seasons_by_id[crop_id]
		
		if season is Array:
			for s in season:
				if not season_counts.has(s):
					season_counts[s] = 0
				season_counts[s] += 1
		else:
			if not season_counts.has(season):
				season_counts[season] = 0
			season_counts[season] += 1
	
	return {
		"total_crops": _crop_seasons_by_id.size(),
		"is_loaded": _is_loaded,
		"crops_by_season": season_counts
	}

# === 私有方法 ===

func _load_crop_catalog() -> bool:
	"""Load crop data from JSON file"""
	if not FileAccess.file_exists(CROP_DATA_PATH):
		push_warning("[AgenticCropCatalog] Crop data file not found: %s" % CROP_DATA_PATH)
		emit_signal("catalog_load_failed", "File not found")
		return false
	
	var file = FileAccess.open(CROP_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("[AgenticCropCatalog] Failed to open crop data file")
		emit_signal("catalog_load_failed", "Cannot open file")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data == null:
		push_error("[AgenticCropCatalog] Failed to parse crop data JSON")
		emit_signal("catalog_load_failed", "Invalid JSON")
		return false
	
	if not (data is Dictionary or data is Array):
		push_error("[AgenticCropCatalog] Crop data must be dictionary or array")
		emit_signal("catalog_load_failed", "Invalid format")
		return false
	
	# Process crop data
	_process_crop_data(data)
	
	_is_loaded = true
	emit_signal("catalog_loaded", _crop_seasons_by_id.size())
	
	if OS.is_debug_build():
		print("[AgenticCropCatalog] Loaded %d crops" % _crop_seasons_by_id.size())
	
	return true

func _process_crop_data(data: Variant) -> void:
	"""Process raw crop data into optimized structures"""
	_crop_seasons_by_id.clear()
	_crop_data_by_id.clear()
	
	# Handle different data formats
	var crops: Variant = data
	
	# If data has a "crops" key, use that
	if data is Dictionary and data.has("crops") and data.crops is Dictionary:
		crops = data.crops

	if crops is Dictionary:
		for crop_id in crops.keys():
			var crop_info: Variant = crops[crop_id]
			if crop_info is Dictionary:
				_register_crop_data(String(crop_id), crop_info)
	elif crops is Array:
		for crop_info in crops:
			if crop_info is Dictionary:
				var crop_id: String = String(crop_info.get("id", ""))
				if crop_id.is_empty():
					continue
				_register_crop_data(crop_id, crop_info)

func _register_crop_data(crop_id: String, crop_info: Dictionary) -> void:
	var season: Variant = crop_info.get("season", "")
	if season is String and season.is_empty():
		season = crop_info.get("growing_season", "")
	if season is String and season.is_empty():
		season = crop_info.get("seasons", [])

	if season is String and not season.is_empty():
		_crop_seasons_by_id[crop_id] = season
	elif season is Array and not season.is_empty():
		_crop_seasons_by_id[crop_id] = season

	_crop_data_by_id[crop_id] = crop_info
