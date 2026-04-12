extends Node

## Loads optional JSON patches from `user://data_overrides/*.json` (sorted by filename).
## H1: read-only overlay for future tables; invalid files are logged and skipped.

const OVERRIDE_DIR := "user://data_overrides"

var files_loaded: PackedStringArray = []
var parse_errors: PackedStringArray = []
var documents: Array = []


func _ready() -> void:
	_load_all_json_overrides()


func _load_all_json_overrides() -> void:
	files_loaded = PackedStringArray()
	parse_errors = PackedStringArray()
	documents.clear()
	var da: DirAccess = DirAccess.open(OVERRIDE_DIR)
	if da == null:
		return
	var names: Array[String] = []
	da.list_dir_begin()
	var entry: String = da.get_next()
	while entry != "":
		if not da.current_is_dir() and entry.ends_with(".json"):
			names.append(entry)
		entry = da.get_next()
	da.list_dir_end()
	names.sort()
	for fname in names:
		var path: String = OVERRIDE_DIR.path_join(fname)
		var txt: String = FileAccess.get_file_as_string(path)
		if txt.is_empty() and not FileAccess.file_exists(path):
			parse_errors.append("%s: read failed" % fname)
			continue
		var parsed: Variant = JSON.parse_string(txt)
		if parsed == null:
			parse_errors.append("%s: JSON parse error" % fname)
			continue
		if not parsed is Dictionary:
			parse_errors.append("%s: root must be object" % fname)
			continue
		files_loaded.append(fname)
		documents.append(parsed)
	for err in parse_errors:
		push_warning("DataOverrides: %s" % err)


func get_document(index: int) -> Dictionary:
	if index < 0 or index >= documents.size():
		return {}
	return documents[index] as Dictionary


func get_merged_root() -> Dictionary:
	var out: Dictionary = {}
	for d in documents:
		if d is Dictionary:
			out.merge(d as Dictionary, true)
	return out
