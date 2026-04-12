extends Node

## Shared save bundle build + disk write (Main hub and `world_farm` after B2 split).

const GAME_SAVE_BUNDLE_PATH := "user://game_save.bundle"
const GAME_SAVE_SLOT_A_PATH := "user://game_save_a.bundle"
const GAME_SAVE_SLOT_B_PATH := "user://game_save_b.bundle"
const GAME_SAVE_META_PATH := "user://game_save_meta.json"
const TAMPER_LOG_PATH := "user://tamper_events.log"
const SAVE_BUNDLE_VERSION := 6
const SAVE_SIGN_SECRET := "sv_save_sign_v1_local_pepper"


func build_runtime_bundle(
	farm: Dictionary,
	world_event_feed: Array,
	active_story_hotspot: Dictionary
) -> Dictionary:
	var world_dict: Dictionary = {}
	if WorldRouter:
		world_dict = WorldRouter.build_world_save_dict()
	return {
		"version": SAVE_BUNDLE_VERSION,
		"player": GameManager.player_data.duplicate(true),
		"farm": farm.duplicate(true),
		"inventory": InventoryManager.save_snapshot(),
		"quests": QuestSystem.save_snapshot(),
		"world_event_feed": world_event_feed.duplicate(),
		"active_story_hotspot": active_story_hotspot.duplicate(true),
		"gathering_almanac": GatheringAlmanac.get_snapshot() if GatheringAlmanac else {},
		"world": world_dict
	}


func commit_save(bundle_without_seq: Dictionary) -> bool:
	var bundle: Dictionary = bundle_without_seq.duplicate(true)
	var meta: Dictionary = read_save_meta()
	var next_seq: int = int(meta.get("last_seq", 0)) + 1
	bundle["save_seq"] = next_seq
	bundle["saved_at_unix"] = Time.get_unix_time_from_system()
	bundle["signature"] = compute_bundle_signature(bundle)
	var slot_path: String = GAME_SAVE_SLOT_A_PATH if (next_seq % 2 == 1) else GAME_SAVE_SLOT_B_PATH
	var temp_path: String = "%s.tmp" % slot_path
	var bf: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if bf == null:
		push_warning("GameSaveService: failed to open save path for writing: %s" % temp_path)
		log_tamper_event("save_write_failed", {"path": temp_path})
		return false
	bf.store_var(bundle)
	bf.close()
	var rn_ok: Error = DirAccess.rename_absolute(temp_path, slot_path)
	if rn_ok != OK:
		log_tamper_event("save_rename_failed", {"from": temp_path, "to": slot_path, "code": int(rn_ok)})
		return false
	write_save_meta({
		"last_seq": next_seq,
		"last_slot": "a" if slot_path == GAME_SAVE_SLOT_A_PATH else "b",
		"last_saved_at_unix": int(bundle.get("saved_at_unix", 0))
	})
	var legacy: FileAccess = FileAccess.open(GAME_SAVE_BUNDLE_PATH, FileAccess.WRITE)
	if legacy:
		legacy.store_var(bundle)
		legacy.close()
	if NPCMemorySystem:
		NPCMemorySystem.save_memories()
	if NPCEmotionSystem:
		NPCEmotionSystem.save_emotion_state()
	print("Game saved!")
	return true


func bundle_signing_payload(bundle: Dictionary) -> Dictionary:
	return {
		"version": int(bundle.get("version", 0)),
		"save_seq": int(bundle.get("save_seq", 0)),
		"player": bundle.get("player", {}),
		"farm": bundle.get("farm", {}),
		"inventory": bundle.get("inventory", {}),
		"quests": bundle.get("quests", {})
	}


func canonicalize_value(v: Variant) -> Variant:
	if v is Dictionary:
		var d: Dictionary = v
		var ks: Array = d.keys()
		ks.sort()
		var out: Dictionary = {}
		for k in ks:
			out[k] = canonicalize_value(d[k])
		return out
	if v is Array:
		var arr: Array = v
		var out_arr: Array = []
		for e in arr:
			out_arr.append(canonicalize_value(e))
		return out_arr
	return v


func compute_bundle_signature(bundle: Dictionary) -> String:
	var payload: Dictionary = bundle_signing_payload(bundle)
	var normalized: Variant = canonicalize_value(payload)
	var msg: PackedByteArray = JSON.stringify(normalized).to_utf8_buffer()
	var key: PackedByteArray = SAVE_SIGN_SECRET.to_utf8_buffer()
	var crypto := Crypto.new()
	var digest: PackedByteArray = crypto.hmac_digest(HashingContext.HASH_SHA256, key, msg)
	return digest.hex_encode()


func verify_bundle_signature(bundle: Dictionary) -> bool:
	var sig: String = str(bundle.get("signature", "")).strip_edges()
	if sig.is_empty():
		return false
	return sig == compute_bundle_signature(bundle)


func read_save_meta() -> Dictionary:
	if not FileAccess.file_exists(GAME_SAVE_META_PATH):
		return {}
	var f: FileAccess = FileAccess.open(GAME_SAVE_META_PATH, FileAccess.READ)
	if f == null:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}


func write_save_meta(meta: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(GAME_SAVE_META_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()


func log_tamper_event(event_name: String, data: Dictionary = {}) -> void:
	var row: Dictionary = {
		"ts": Time.get_unix_time_from_system(),
		"event": event_name,
		"day": int(GameManager.player_data.get("day", 1)) if GameManager else 1,
		"season": str(GameManager.player_data.get("season", "spring")) if GameManager else "spring",
		"year": int(GameManager.player_data.get("year", 1)) if GameManager else 1
	}
	if not data.is_empty():
		row["data"] = data
	var f: FileAccess = FileAccess.open(TAMPER_LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()
