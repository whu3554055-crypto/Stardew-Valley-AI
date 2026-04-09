extends Node

class_name AgenticContentOrchestrator

signal generation_started(reason)
signal generation_published(chain_id, mode)
signal generation_failed(reason)
signal generation_degraded(reason)

const RUNTIME_STORE_PATH := "user://runtime_chain_templates.json"
const MANUAL_INBOX_PATH := "user://manual_chain_inbox.json"
const MANUAL_OVERRIDE_RES_PATH := "res://data/quests/manual_chain_overrides.json"
const CHAIN_ID_PREFIX := "runtime_chain_"

var config: Dictionary = {
	"enabled": true,
	"max_runtime_chains": 12,
	"target_total_chains_min": 24,
	"max_generations_per_day": 1,
	"max_consecutive_failures": 3,
	"default_cooldown_days": 1,
	"use_ai_first": true,
	"allow_procedural_fallback": true
}

var _runtime_chain_ids: Array = []
var _consecutive_failures: int = 0
var _manual_queue: Array = []
var _performance: Dictionary = {}

func _ready() -> void:
	_load_runtime_store()
	_load_manual_inbox()
	if QuestSystem and QuestSystem.has_signal("managed_chain_resolved"):
		QuestSystem.managed_chain_resolved.connect(_on_managed_chain_resolved)

func maybe_generate_for_day(narrative: Dictionary = {}) -> void:
	if not bool(config.get("enabled", true)):
		return
	if QuestSystem == null:
		return
	var today_key: String = _day_key()
	var generated_key: String = "agentic_runtime_generated_%s" % today_key
	if GameManager and GameManager.player_data and bool(GameManager.player_data.get(generated_key, false)):
		return
	var reason: Dictionary = _compute_generation_reason(narrative)
	if bool(reason.get("should_generate", false)) == false:
		return
	var daily_count_key: String = "agentic_runtime_gen_count_%s" % today_key
	var daily_count: int = int(GameManager.player_data.get(daily_count_key, 0)) if GameManager and GameManager.player_data else 0
	if daily_count >= int(config.get("max_generations_per_day", 1)):
		return
	generation_started.emit(str(reason.get("reason", "unknown")))
	var manual_take: Dictionary = _take_manual_chain()
	if not manual_take.is_empty():
		var vm: Dictionary = _validate_chain_template(manual_take)
		if bool(vm.get("ok", false)):
			var regm: Dictionary = QuestSystem.register_runtime_chain_template(manual_take, "manual_override")
			if bool(regm.get("ok", false)):
				var manual_chain_id: String = str(regm.get("chain_id", ""))
				if not manual_chain_id.is_empty() and not _runtime_chain_ids.has(manual_chain_id):
					_runtime_chain_ids.append(manual_chain_id)
				_save_runtime_store()
				_save_manual_inbox()
				_consecutive_failures = 0
				if GameManager and GameManager.player_data:
					GameManager.player_data[generated_key] = true
					GameManager.player_data[daily_count_key] = daily_count + 1
				generation_published.emit(manual_chain_id, "manual")
				return
		_on_generation_failure("manual_chain_invalid")
		_save_manual_inbox()
		return
	var theme: String = str(reason.get("theme", "joyful"))
	var chain_data: Dictionary = {}
	var mode: String = "none"
	if bool(config.get("use_ai_first", true)):
		chain_data = await _generate_chain_via_ai(theme)
		mode = "ai"
	if chain_data.is_empty() and bool(config.get("allow_procedural_fallback", true)):
		chain_data = _build_procedural_chain(theme)
		mode = "fallback"
	if chain_data.is_empty():
		_on_generation_failure("empty_chain_data")
		return
	if _is_near_duplicate_chain(chain_data):
		_on_generation_failure("near_duplicate_chain")
		return
	var v: Dictionary = _validate_chain_template(chain_data)
	if not bool(v.get("ok", false)):
		_on_generation_failure(str(v.get("error", "validation_failed")))
		return
	_apply_canary_rollout(chain_data)
	var reg: Dictionary = QuestSystem.register_runtime_chain_template(chain_data, "runtime_agentic")
	if not bool(reg.get("ok", false)):
		_on_generation_failure(str(reg.get("error", "register_failed")))
		return
	var chain_id: String = str(reg.get("chain_id", ""))
	if chain_id.is_empty():
		_on_generation_failure("missing_chain_id")
		return
	if not _runtime_chain_ids.has(chain_id):
		_runtime_chain_ids.append(chain_id)
	_save_runtime_store()
	_consecutive_failures = 0
	if GameManager and GameManager.player_data:
		GameManager.player_data[generated_key] = true
		GameManager.player_data[daily_count_key] = daily_count + 1
	generation_published.emit(chain_id, mode)
	_check_rollout_promotions_and_offline()

func enqueue_manual_chain(chain_data: Dictionary) -> Dictionary:
	# Minimal manual intervention API: queue one curated chain for next auto publish window.
	var v: Dictionary = _validate_chain_template(chain_data)
	if not bool(v.get("ok", false)):
		return {"ok": false, "error": str(v.get("error", "invalid_chain"))}
	var cid: String = str(chain_data.get("id", "")).strip_edges()
	if cid.is_empty():
		return {"ok": false, "error": "missing_chain_id"}
	for row in _manual_queue:
		if row is Dictionary and str((row as Dictionary).get("id", "")) == cid:
			return {"ok": false, "error": "already_queued"}
	_manual_queue.append(chain_data.duplicate(true))
	_save_manual_inbox()
	return {"ok": true, "queued_id": cid}

func get_manual_queue_size() -> int:
	return _manual_queue.size()

func get_chain_performance(chain_id: String) -> Dictionary:
	return (_performance.get(chain_id, {}) as Dictionary).duplicate(true)

func _compute_generation_reason(narrative: Dictionary) -> Dictionary:
	var total: int = int(QuestSystem.chain_templates.size()) if QuestSystem else 0
	var max_runtime: int = int(config.get("max_runtime_chains", 12))
	if _runtime_chain_ids.size() >= max_runtime:
		return {"should_generate": false}
	if total < int(config.get("target_total_chains_min", 24)):
		return {
			"should_generate": true,
			"reason": "below_target_total",
			"theme": _pick_theme_from_narrative(narrative)
		}
	var theme: String = _pick_theme_from_narrative(narrative)
	if _count_chains_for_theme(theme) < 2:
		return {
			"should_generate": true,
			"reason": "theme_gap",
			"theme": theme
		}
	return {"should_generate": false}

func _count_chains_for_theme(theme: String) -> int:
	if QuestSystem == null:
		return 0
	var count: int = 0
	for chain_id in QuestSystem.chain_templates.keys():
		var cd: Dictionary = QuestSystem.chain_templates[chain_id]
		var preferred: Array = cd.get("preferred_themes", [])
		for t in preferred:
			if str(t).to_lower() == theme:
				count += 1
				break
	return count

func _pick_theme_from_narrative(narrative: Dictionary) -> String:
	var theme: String = str(narrative.get("theme", "joyful")).to_lower().strip_edges()
	if theme.is_empty():
		return "joyful"
	return theme

func _generate_chain_via_ai(theme: String) -> Dictionary:
	if AIAgentManager == null or not AIAgentManager.has_method("request_text_generation"):
		return {}
	var prompt: String = _build_generation_prompt(theme)
	var gen: Dictionary = await AIAgentManager.request_text_generation({
		"prompt": prompt,
		"temperature": 0.72,
		"max_tokens": 640,
		"source": "runtime_chain:%s" % theme
	})
	if not bool(gen.get("ok", false)):
		return {}
	return _extract_chain_json(str(gen.get("text", "")), theme)

func _build_generation_prompt(theme: String) -> String:
	return """You generate ONE quest chain JSON object for a farming game.
Theme: %s

Return ONLY JSON, no markdown fences.
Schema:
{
  "id": "runtime_chain_slug",
  "display_name": "Chain Name",
  "cooldown_days": 1,
  "preferred_themes": ["%s", "joyful"],
  "steps": [
    {
      "id": "runtime_chain_slug_s1",
      "title": "Step 1 title",
      "description": "Step 1 desc",
      "objective": {"type": "harvest|talk|earn_gold|mine_ore|fish_caught", "count": 1, "npc_id": "pierre(optional)"},
      "reward": {"gold": 60, "items": ["bread:1"]}
    },
    {
      "id": "runtime_chain_slug_s2",
      "title": "Step 2 title",
      "description": "Step 2 desc",
      "objective": {"type": "talk", "npc_id": "pierre", "count": 1},
      "reward": {"gold": 80, "items": ["worm_bait:2"]}
    },
    {
      "id": "runtime_chain_slug_s3",
      "title": "Step 3 title",
      "description": "Step 3 desc",
      "objective": {"type": "earn_gold", "count": 120},
      "reward": {"gold": 120, "items": ["bread:1"]}
    }
  ]
}

Rules:
1) Exactly 3 steps.
2) IDs lowercase snake_case.
3) Keep rewards conservative: total gold 180-420.
4) Avoid special objective keys except type/count/npc_id/crop_id/ore_id/fish_id.
5) Make text concise.
""" % [theme, theme]

func _extract_chain_json(raw_text: String, theme: String) -> Dictionary:
	var text: String = raw_text.strip_edges()
	if text.is_empty():
		return {}
	if text.begins_with("```"):
		var first_brace: int = text.find("{")
		var last_brace: int = text.rfind("}")
		if first_brace >= 0 and last_brace > first_brace:
			text = text.substr(first_brace, last_brace - first_brace + 1)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var cd: Dictionary = (parsed as Dictionary).duplicate(true)
	if str(cd.get("id", "")).is_empty():
		cd["id"] = "%s%s_%d" % [CHAIN_ID_PREFIX, theme, int(Time.get_unix_time_from_system())]
	return cd

func _build_procedural_chain(theme: String) -> Dictionary:
	var stamp: int = int(Time.get_unix_time_from_system())
	var cid: String = "%s%s_%d" % [CHAIN_ID_PREFIX, theme, stamp]
	var s1: Dictionary = {
		"id": "%s_s1" % cid,
		"title": "%s I: Gather Supplies" % theme.capitalize(),
		"description": "Collect materials for today's %s request." % theme,
		"objective": {"type": "harvest", "count": 2},
		"reward": {"gold": 68, "items": ["bread:1"]}
	}
	var s2: Dictionary = {
		"id": "%s_s2" % cid,
		"title": "%s II: Confirm Details" % theme.capitalize(),
		"description": "Talk to Pierre to confirm delivery details.",
		"objective": {"type": "talk", "npc_id": "pierre", "count": 1},
		"reward": {"gold": 88, "items": ["worm_bait:2"]}
	}
	var s3: Dictionary = {
		"id": "%s_s3" % cid,
		"title": "%s III: Sell Final Cargo" % theme.capitalize(),
		"description": "Sell cargo worth 128g to close this chain.",
		"objective": {"type": "earn_gold", "count": 128},
		"reward": {"gold": 128, "items": ["bread:1"]}
	}
	return {
		"id": cid,
		"display_name": "%s Runtime Chain" % theme.capitalize(),
		"cooldown_days": int(config.get("default_cooldown_days", 1)),
		"preferred_themes": [theme, "joyful"],
		"steps": [s1, s2, s3]
	}

func _validate_chain_template(chain_data: Dictionary) -> Dictionary:
	var cid: String = str(chain_data.get("id", "")).strip_edges()
	if cid.is_empty():
		return {"ok": false, "error": "missing_chain_id"}
	if not (chain_data.get("steps") is Array):
		return {"ok": false, "error": "steps_not_array"}
	var steps: Array = chain_data.get("steps", [])
	if steps.size() != 3:
		return {"ok": false, "error": "steps_must_be_3"}
	var allowed_types: Dictionary = {
		"harvest": true,
		"talk": true,
		"earn_gold": true,
		"mine_ore": true,
		"fish_caught": true
	}
	var total_gold: int = 0
	var seen_step_ids: Dictionary = {}
	for s in steps:
		if not (s is Dictionary):
			return {"ok": false, "error": "step_not_dict"}
		var sd: Dictionary = s
		var sid: String = str(sd.get("id", "")).strip_edges()
		if sid.is_empty():
			return {"ok": false, "error": "missing_step_id"}
		if seen_step_ids.has(sid):
			return {"ok": false, "error": "duplicate_step_id"}
		seen_step_ids[sid] = true
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", "")).strip_edges()
		if not allowed_types.has(ot):
			return {"ok": false, "error": "unsupported_objective:%s" % ot}
		var cnt: int = int(objective.get("count", 1))
		if cnt <= 0:
			return {"ok": false, "error": "invalid_count"}
		var reward: Dictionary = sd.get("reward", {})
		total_gold += int(reward.get("gold", 0))
	if total_gold < 150 or total_gold > 520:
		return {"ok": false, "error": "gold_out_of_range"}
	return {"ok": true}

func _normalize_for_similarity(v: String) -> String:
	var lower: String = v.to_lower()
	var chars := PackedStringArray()
	for i in range(lower.length()):
		var code: int = lower.unicode_at(i)
		if (code >= 97 and code <= 122) or (code >= 48 and code <= 57):
			chars.append(char(code))
		else:
			chars.append(" ")
	return " ".join("".join(chars).split(" ", false))

func _collect_chain_text(chain_data: Dictionary) -> String:
	var parts := PackedStringArray()
	parts.append(str(chain_data.get("display_name", "")))
	var steps: Array = chain_data.get("steps", [])
	for s in steps:
		if s is Dictionary:
			var sd: Dictionary = s
			parts.append(str(sd.get("title", "")))
			parts.append(str(sd.get("description", "")))
	return _normalize_for_similarity(" ".join(parts))

func _token_set(text: String) -> Dictionary:
	var out: Dictionary = {}
	for tk in text.split(" ", false):
		if tk.length() >= 3:
			out[tk] = true
	return out

func _jaccard(a: Dictionary, b: Dictionary) -> float:
	if a.is_empty() or b.is_empty():
		return 0.0
	var inter: int = 0
	for k in a.keys():
		if b.has(k):
			inter += 1
	var union: int = a.size() + b.size() - inter
	if union <= 0:
		return 0.0
	return float(inter) / float(union)

func _is_near_duplicate_chain(chain_data: Dictionary) -> bool:
	if QuestSystem == null:
		return false
	var cand_text: String = _collect_chain_text(chain_data)
	if cand_text.is_empty():
		return false
	var cand_tokens: Dictionary = _token_set(cand_text)
	for chain_id in QuestSystem.chain_templates.keys():
		var existing: Dictionary = QuestSystem.chain_templates[chain_id]
		var ex_text: String = _collect_chain_text(existing)
		if ex_text.is_empty():
			continue
		var sim: float = _jaccard(cand_tokens, _token_set(ex_text))
		if sim >= 0.72:
			return true
	return false

func _apply_canary_rollout(chain_data: Dictionary) -> void:
	var rollout: Dictionary = chain_data.get("runtime_rollout", {})
	rollout["stage"] = "canary"
	rollout["ratio"] = 0.2
	rollout["min_samples"] = 3
	rollout["started_day_key"] = _day_key()
	chain_data["runtime_rollout"] = rollout

func _take_manual_chain() -> Dictionary:
	if _manual_queue.is_empty():
		return {}
	var next_row: Dictionary = (_manual_queue[0] as Dictionary).duplicate(true)
	_manual_queue.remove_at(0)
	return next_row

func _on_generation_failure(reason: String) -> void:
	_consecutive_failures += 1
	generation_failed.emit(reason)
	if _consecutive_failures >= int(config.get("max_consecutive_failures", 3)):
		config["enabled"] = false
		generation_degraded.emit("too_many_failures_disable_runtime")

func _ensure_perf_row(chain_id: String) -> Dictionary:
	var row: Dictionary = _performance.get(chain_id, {})
	if row.is_empty():
		row = {
			"success": 0,
			"failed": 0,
			"samples": 0,
			"last_result": ""
		}
		_performance[chain_id] = row
	return row

func _on_managed_chain_resolved(outcome: Dictionary) -> void:
	var chain_id: String = str(outcome.get("chain_id", ""))
	if chain_id.is_empty() or not _runtime_chain_ids.has(chain_id):
		return
	var result: String = str(outcome.get("result", "success"))
	var row: Dictionary = _ensure_perf_row(chain_id)
	if result == "failed":
		row["failed"] = int(row.get("failed", 0)) + 1
	else:
		row["success"] = int(row.get("success", 0)) + 1
	row["samples"] = int(row.get("samples", 0)) + 1
	row["last_result"] = result
	_performance[chain_id] = row
	_check_rollout_promotions_and_offline()
	_save_runtime_store()

func _check_rollout_promotions_and_offline() -> void:
	if QuestSystem == null:
		return
	for chain_id in _runtime_chain_ids:
		if not QuestSystem.chain_templates.has(chain_id):
			continue
		var cd: Dictionary = QuestSystem.chain_templates[chain_id]
		var rollout: Dictionary = cd.get("runtime_rollout", {})
		var stage: String = str(rollout.get("stage", "full"))
		var row: Dictionary = _performance.get(chain_id, {})
		var samples: int = int(row.get("samples", 0))
		var failed: int = int(row.get("failed", 0))
		var success: int = int(row.get("success", 0))
		var success_rate: float = float(success) / float(maxi(1, samples))
		if stage == "canary":
			var min_samples: int = int(rollout.get("min_samples", 3))
			if samples >= min_samples and success_rate >= 0.5:
				rollout["stage"] = "full"
				rollout["ratio"] = 1.0
				cd["runtime_rollout"] = rollout
				QuestSystem.chain_templates[chain_id] = cd
		if samples >= 4 and failed >= 3 and success_rate < 0.4:
			QuestSystem.set_chain_runtime_enabled(chain_id, false)

func _load_runtime_store() -> void:
	if not FileAccess.file_exists(RUNTIME_STORE_PATH):
		return
	if QuestSystem == null:
		return
	var f: FileAccess = FileAccess.open(RUNTIME_STORE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		return
	var root: Dictionary = json.data
	var rows: Array = root.get("chains", [])
	for row in rows:
		if not (row is Dictionary):
			continue
		var reg: Dictionary = QuestSystem.register_runtime_chain_template((row as Dictionary).duplicate(true), "runtime_agentic")
		if bool(reg.get("ok", false)):
			var chain_id: String = str(reg.get("chain_id", ""))
			if not chain_id.is_empty() and not _runtime_chain_ids.has(chain_id):
				_runtime_chain_ids.append(chain_id)
	var perf: Dictionary = root.get("performance", {})
	if perf is Dictionary:
		_performance = perf.duplicate(true)

func _save_runtime_store() -> void:
	var rows: Array = []
	if QuestSystem:
		for chain_id in _runtime_chain_ids:
			if QuestSystem.chain_templates.has(chain_id):
				rows.append((QuestSystem.chain_templates[chain_id] as Dictionary).duplicate(true))
	var root: Dictionary = {
		"version": 1,
		"chains": rows,
		"performance": _performance.duplicate(true)
	}
	var f: FileAccess = FileAccess.open(RUNTIME_STORE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(root, "\t"))
	f.close()

func _load_manual_inbox() -> void:
	_manual_queue.clear()
	# Optional project-shipped override file for festivals/marketing moments.
	if FileAccess.file_exists(MANUAL_OVERRIDE_RES_PATH):
		var rf: FileAccess = FileAccess.open(MANUAL_OVERRIDE_RES_PATH, FileAccess.READ)
		if rf != null:
			var rtxt: String = rf.get_as_text()
			rf.close()
			var rjson := JSON.new()
			if rjson.parse(rtxt) == OK and rjson.data is Dictionary:
				var rroot: Dictionary = rjson.data
				var rrows: Array = rroot.get("chains", [])
				for row in rrows:
					if row is Dictionary:
						_manual_queue.append((row as Dictionary).duplicate(true))
	# User-writable inbox overrides bundled overrides.
	if not FileAccess.file_exists(MANUAL_INBOX_PATH):
		return
	var f: FileAccess = FileAccess.open(MANUAL_INBOX_PATH, FileAccess.READ)
	if f == null:
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		return
	var root: Dictionary = json.data
	var rows: Array = root.get("chains", [])
	for row in rows:
		if row is Dictionary:
			_manual_queue.append((row as Dictionary).duplicate(true))

func _save_manual_inbox() -> void:
	var root: Dictionary = {
		"version": 1,
		"chains": _manual_queue.duplicate(true)
	}
	var f: FileAccess = FileAccess.open(MANUAL_INBOX_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(root, "\t"))
	f.close()

func _day_key() -> String:
	if not GameManager or not GameManager.player_data:
		return "0-spring-0"
	return "%d-%s-%d" % [
		int(GameManager.player_data.get("year", 1)),
		str(GameManager.player_data.get("season", "spring")),
		int(GameManager.player_data.get("day", 1))
	]
