extends Node

## E2: data-driven idle lines + one quest-hint line per NPC (`data/npc/dialogue_pools.json`).

const POOLS_PATH := "res://data/npc/dialogue_pools.json"

var _pools: Dictionary = {}


func _ready() -> void:
	_load_pools()


func _load_pools() -> void:
	_pools.clear()
	var f: FileAccess = FileAccess.open(POOLS_PATH, FileAccess.READ)
	if f == null:
		push_warning("NpcDialogueCatalog: missing %s" % POOLS_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_pools = parsed


func has_npc(npc_id: String) -> bool:
	return _pools.has(npc_id)


func pick_random_line(npc_id: String) -> String:
	var block: Variant = _pools.get(npc_id, {})
	if not block is Dictionary:
		return ""
	var lines: Variant = (block as Dictionary).get("lines", [])
	if not lines is Array or (lines as Array).is_empty():
		return ""
	var arr: Array = lines as Array
	var s: String = str(arr[randi() % arr.size()])
	return s


func pick_quest_hint(npc_id: String) -> String:
	var block: Variant = _pools.get(npc_id, {})
	if not block is Dictionary:
		return ""
	return str((block as Dictionary).get("quest_line", "")).strip_edges()


func pick_line_for_interact(npc_id: String) -> String:
	if not has_npc(npc_id):
		return ""
	if QuestSystem and _active_quest_mentions_npc(npc_id):
		var qh: String = pick_quest_hint(npc_id)
		if not qh.is_empty() and randf() < 0.35:
			return qh
	return pick_random_line(npc_id)


func _active_quest_mentions_npc(npc_id: String) -> bool:
	for qid in QuestSystem.active_quests:
		if not QuestSystem.quests.has(qid):
			continue
		var q: Dictionary = QuestSystem.quests[qid]
		var st: int = int(q.get("status", -1))
		if st != int(QuestSystem.QuestStatus.IN_PROGRESS):
			continue
		if str(q.get("story_npc_id", "")) == npc_id:
			return true
		var obj: Variant = q.get("objective", {})
		if obj is Dictionary and str((obj as Dictionary).get("npc_id", "")) == npc_id:
			return true
	return false
