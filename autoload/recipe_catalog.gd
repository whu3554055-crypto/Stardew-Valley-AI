extends Node

## Loads res://data/recipes/*.json — edit JSON to tune recipes without code changes.

var cooking_recipes: Array = []
var crafting_recipes: Array = []
var smelting_recipes: Array = []

func _ready() -> void:
	cooking_recipes = _load_path("res://data/recipes/cooking.json", _default_cooking())
	crafting_recipes = _load_path("res://data/recipes/crafting.json", _default_crafting())
	smelting_recipes = _load_path("res://data/recipes/smelting.json", _default_smelting())

func _load_path(path: String, fallback: Array) -> Array:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("RecipeCatalog: cannot read %s — using embedded defaults" % path)
		return _normalize_array(fallback)
	var txt: String = f.get_as_text()
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("RecipeCatalog: JSON parse error in %s" % path)
		return _normalize_array(fallback)
	var data = json.data
	if data is Array:
		return _normalize_array(data)
	return _normalize_array(fallback)

func _normalize_array(arr: Array) -> Array:
	var out: Array = []
	for r in arr:
		if r is Dictionary:
			out.append(_normalize_recipe(r))
	return out

func _normalize_recipe(r: Dictionary) -> Dictionary:
	var d: Dictionary = r.duplicate(true)
	if not d.has("inputs") and d.has("in"):
		d["inputs"] = d["in"]
	if not d.has("output_id") and d.has("out"):
		d["output_id"] = str(d["out"])
	if not d.has("output_qty") and d.has("qty"):
		d["output_qty"] = int(d["qty"])
	return d

func _default_cooking() -> Array:
	return [
		{"id": "fish_sandwich", "output_id": "fish_sandwich", "output_qty": 1, "inputs": {"bread": 1, "fish_sardine": 1}, "stamina": 2},
		{"id": "grilled_sardine", "output_id": "grilled_sardine", "output_qty": 1, "inputs": {"fish_sardine": 1}, "stamina": 2},
		{"id": "grilled_pike", "output_id": "grilled_pike", "output_qty": 1, "inputs": {"fish_pike": 1}, "stamina": 2},
		{"id": "grilled_halibut", "output_id": "grilled_halibut", "output_qty": 1, "inputs": {"fish_halibut": 1}, "stamina": 2},
	]

func _default_crafting() -> Array:
	return [
		{"id": "worm_bait_bundle", "output_id": "worm_bait", "output_qty": 5, "inputs": {"wood_log": 2, "coal": 1}, "stamina": 3},
	]

func _default_smelting() -> Array:
	return [
		{"id": "copper_bar", "output_id": "copper_bar", "output_qty": 1, "inputs": {"copper_ore": 5, "coal": 1}, "stamina": 3},
		{"id": "silver_bar", "output_id": "silver_bar", "output_qty": 1, "inputs": {"silver_ore": 5, "coal": 1}, "stamina": 3},
	]
