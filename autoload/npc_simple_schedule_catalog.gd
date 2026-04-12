extends Node

## 加载 `data/npc/simple_schedules.json`，供对话上下文与 AdvancedAI 日程合并（E1 运行时接入）。

const DATA_PATH := "res://data/npc/simple_schedules.json"

var _policy: String = "current_scene_only"
var _by_id: Dictionary = {}


func get_policy() -> String:
	return _policy


func _ready() -> void:
	_reload()


func _reload() -> void:
	_by_id.clear()
	_policy = "current_scene_only"
	if not FileAccess.file_exists(DATA_PATH):
		return
	var f: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	var root: Dictionary = parsed
	_policy = str(root.get("policy", _policy))
	for entry in root.get("npcs", []):
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		var nid: String = str(e.get("npc_id", "")).strip_edges()
		if nid.is_empty():
			continue
		_by_id[nid] = e


## 当前游戏内钟点（0–24 浮点）所在日程块；无则返回空字典。
func get_active_block(npc_id: String, hour_f: float = -1.0) -> Dictionary:
	if _by_id.is_empty():
		return {}
	var h: float = hour_f
	if h < 0.0:
		h = float(GameManager.current_time) if GameManager else 12.0
	var entry: Variant = _by_id.get(npc_id, {})
	if not (entry is Dictionary):
		return {}
	for blk in (entry as Dictionary).get("blocks", []):
		if not (blk is Dictionary):
			continue
		var b: Dictionary = blk
		var sh: float = float(b.get("start_hour", 0))
		var eh: float = float(b.get("end_hour", 24))
		if h >= sh and h < eh:
			return b
	return {}


## 一行人类可读说明，注入 AI / 静态对话上下文。
func get_activity_line(npc_id: String, hour_f: float = -1.0) -> String:
	var entry: Variant = _by_id.get(npc_id, {})
	if not (entry is Dictionary):
		return ""
	var disp: String = str((entry as Dictionary).get("display_name", npc_id))
	var blk: Dictionary = get_active_block(npc_id, hour_f)
	if blk.is_empty():
		return "%s：当前无表内日程块（表外时间）。" % disp
	var anchor: String = str(blk.get("anchor", ""))
	var note: String = str(blk.get("note", ""))
	if anchor.is_empty():
		return "%s：%s" % [disp, note]
	if note.is_empty():
		return "%s：应在 %s 附近。" % [disp, anchor]
	return "%s：应在 %s — %s" % [disp, anchor, note]


## 转为 `AdvancedAIAgentManager.get_current_activity` 所需的 schedule 字典（小时字符串键）。
func to_advanced_ai_schedule(npc_id: String) -> Dictionary:
	var entry: Variant = _by_id.get(npc_id, {})
	if not (entry is Dictionary):
		return {}
	var out: Dictionary = {}
	for blk in (entry as Dictionary).get("blocks", []):
		if not (blk is Dictionary):
			continue
		var b: Dictionary = blk
		var sh: int = int(b.get("start_hour", 0))
		var anchor: String = str(b.get("anchor", "idle"))
		var note: String = str(b.get("note", ""))
		var key: String = "%d.0" % sh
		out[key] = {
			"action": "at_%s" % anchor,
			"anchor": anchor,
			"note": note
		}
	return out
