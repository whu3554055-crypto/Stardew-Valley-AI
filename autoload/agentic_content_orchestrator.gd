extends Node

class_name AgenticContentOrchestrator

signal generation_started(reason)
signal generation_published(chain_id, mode)
signal generation_failed(reason)
signal generation_degraded(reason)
signal runtime_status_updated(snapshot)
signal guardrail_blocked(reason, snapshot)

const RUNTIME_STORE_PATH := "user://runtime_chain_templates.json"
const MANUAL_INBOX_PATH := "user://manual_chain_inbox.json"
const MANUAL_OVERRIDE_RES_PATH := "res://data/quests/manual_chain_overrides.json"
const CROP_DATA_PATH := "res://data/farm/crops.json"
const CHAIN_ID_PREFIX := "runtime_chain_"

var config: Dictionary = {
	"enabled": true,
	"max_runtime_chains": 12,
	"target_total_chains_min": 24,
	"max_generations_per_day": 1,
	"max_consecutive_failures": 3,
	"breaker_reopen_days": 2,
	"default_cooldown_days": 1,
	"max_chain_expected_value": 760,
	"max_runtime_value_budget": 2200,
	"safe_fallback_daily_cap": 1,
	"safe_fallback_weekly_cap": 3,
	"use_ai_first": true,
	"allow_procedural_fallback": true
}

var _runtime_chain_ids: Array = []
var _consecutive_failures: int = 0
var _manual_queue: Array = []
var _performance: Dictionary = {}
var _crop_seasons_by_id: Dictionary = {}
var _recent_signatures: Array = []
var _failure_pressure: Dictionary = {"streak": 0, "last_day": -1}
var _recent_reward_profiles: Array = []
var _daily_rejects: Dictionary = {}
var _safe_fallback_history: Array = []
var _reject_reason_counts: Dictionary = {}
var _last_block_reason: String = ""
var _breaker_state: String = "open" # open | half_open | closed
var _breaker_last_closed_day: int = -1
var _stats: Dictionary = {
	"attempted": 0,
	"published": 0,
	"failed": 0
}

func _ready() -> void:
	_load_crop_catalog()
	_load_runtime_store()
	_load_manual_inbox()
	if QuestSystem and QuestSystem.has_signal("managed_chain_resolved"):
		QuestSystem.managed_chain_resolved.connect(_on_managed_chain_resolved)

func maybe_generate_for_day(narrative: Dictionary = {}) -> void:
	if not bool(config.get("enabled", true)):
		return
	if QuestSystem == null:
		return
	_maybe_reopen_breaker()
	if _breaker_state == "closed":
		_emit_runtime_status()
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
	_stats["attempted"] = int(_stats.get("attempted", 0)) + 1
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
				_stats["published"] = int(_stats.get("published", 0)) + 1
				_breaker_state = "open"
				_record_today_objective_signature(manual_take)
				_record_recent_signature(manual_take)
				_record_reward_profile(manual_take)
				_emit_runtime_status()
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
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		if chain_data.is_empty():
			return
	if _is_near_duplicate_chain(chain_data):
		_on_generation_failure("near_duplicate_chain")
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		if chain_data.is_empty():
			return
	if _is_short_window_repetition(chain_data):
		_on_generation_failure("short_window_repetition")
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		if chain_data.is_empty():
			return
	var v: Dictionary = _validate_chain_template(chain_data)
	if not bool(v.get("ok", false)):
		_on_generation_failure(str(v.get("error", "validation_failed")))
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		if chain_data.is_empty():
			return
		v = _validate_chain_template(chain_data)
		if not bool(v.get("ok", false)):
			_on_generation_failure(str(v.get("error", "safe_fallback_invalid")))
			return
	if _conflicts_with_today_objective_mix(chain_data):
		_on_generation_failure("daily_objective_mix_conflict")
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		if chain_data.is_empty():
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
	_stats["published"] = int(_stats.get("published", 0)) + 1
	_breaker_state = "open"
	_record_today_objective_signature(chain_data)
	_record_recent_signature(chain_data)
	_record_reward_profile(chain_data)
	if mode == "safe_fallback":
		_safe_fallback_history.append({
			"day_key": _day_key(),
			"day_index": _current_day_index(),
			"chain_id": chain_id
		})
		while _safe_fallback_history.size() > 24:
			_safe_fallback_history.pop_front()
	_check_rollout_promotions_and_offline()
	_emit_runtime_status()

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

func get_runtime_status() -> Dictionary:
	var top_block: Dictionary = _top_block_reason()
	return {
		"breaker_state": _breaker_state,
		"consecutive_failures": _consecutive_failures,
		"manual_queue_size": _manual_queue.size(),
		"runtime_chain_count": _runtime_chain_ids.size(),
		"attempted": int(_stats.get("attempted", 0)),
		"published": int(_stats.get("published", 0)),
		"failed": int(_stats.get("failed", 0)),
		"last_block_reason": _last_block_reason,
		"top_block_reason": str(top_block.get("reason", "")),
		"top_block_count": int(top_block.get("count", 0))
	}

func get_runtime_status_line() -> String:
	var s: Dictionary = get_runtime_status()
	var top_block: String = str(s.get("top_block_reason", ""))
	return "Agentic runtime | breaker=%s | queued=%d | chains=%d | ok=%d fail=%d | top_block=%s" % [
		str(s.get("breaker_state", "open")),
		int(s.get("manual_queue_size", 0)),
		int(s.get("runtime_chain_count", 0)),
		int(s.get("published", 0)),
		int(s.get("failed", 0)),
		(top_block if not top_block.is_empty() else "-")
	]

func get_recovery_guidance(reason: String) -> String:
	match reason:
		"daily_objective_mix_conflict":
			return "Try a different objective theme tomorrow (e.g., harvest -> talk/fish)."
		"near_duplicate_chain":
			return "Adjust chain theme and step text to increase novelty."
		"duration_over_timeout_budget":
			return "Lower step counts or increase timeout budget before publishing."
		"economy_route_unreachable":
			return "Add supply-gathering steps before earn-gold objectives."
		"missing_basic_tool:fishing_rod":
			return "Grant fishing rod first or avoid fish objectives this day."
		"missing_basic_tool:pickaxe":
			return "Grant pickaxe first or avoid mining objectives this day."
		"too_many_failures_breaker_closed":
			return "Runtime is paused; wait for half-open retry window or enqueue a curated manual chain."
		_:
			return "Use manual override chain for today and keep runtime in canary mode."

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
		if str(sd.get("title", "")).strip_edges().is_empty():
			return {"ok": false, "error": "missing_step_title"}
		if str(sd.get("description", "")).strip_edges().is_empty():
			return {"ok": false, "error": "missing_step_description"}
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
		if ot == "earn_gold" and (cnt < 60 or cnt > 280):
			return {"ok": false, "error": "earn_gold_out_of_range"}
		if ot == "talk":
			var npc_id: String = str(objective.get("npc_id", "")).strip_edges()
			if npc_id.is_empty() or not _is_known_npc(npc_id):
				return {"ok": false, "error": "unknown_talk_npc"}
		if ot == "harvest":
			var crop_id: String = str(objective.get("crop_id", "")).strip_edges()
			if not crop_id.is_empty() and not _is_crop_in_current_season(crop_id):
				return {"ok": false, "error": "crop_out_of_season"}
		var reward: Dictionary = sd.get("reward", {})
		if not (reward.get("items", []) is Array):
			return {"ok": false, "error": "reward_items_not_array"}
		for item_spec in reward.get("items", []):
			if not _is_valid_item_spec(str(item_spec)):
				return {"ok": false, "error": "invalid_reward_item"}
		total_gold += int(reward.get("gold", 0))
	if total_gold < 150 or total_gold > 520:
		return {"ok": false, "error": "gold_out_of_range"}
	if not _has_sellable_economy_route(steps):
		return {"ok": false, "error": "economy_route_unreachable"}
	var dep: Dictionary = _check_dependency_coherence(steps)
	if not bool(dep.get("ok", false)):
		return dep
	var prog: Dictionary = _check_new_player_reachability(steps)
	if not bool(prog.get("ok", false)):
		return prog
	var timing: Dictionary = _check_duration_feasibility(steps)
	if not bool(timing.get("ok", false)):
		return timing
	var inflation: Dictionary = _check_reward_inflation(chain_data, steps)
	if not bool(inflation.get("ok", false)):
		return inflation
	var semantic: Dictionary = _check_objective_semantic_coherence(steps)
	if not bool(semantic.get("ok", false)):
		return semantic
	var state_guard: Dictionary = _check_current_player_state_fit(steps)
	if not bool(state_guard.get("ok", false)):
		return state_guard
	var spiral: Dictionary = _check_failure_spiral_protection(steps)
	if not bool(spiral.get("ok", false)):
		return spiral
	var reward_mix: Dictionary = _check_reward_structure_diversity(steps)
	if not bool(reward_mix.get("ok", false)):
		return reward_mix
	var map_guard: Dictionary = _check_map_reachability_constraints(steps)
	if not bool(map_guard.get("ok", false)):
		return map_guard
	var granularity: Dictionary = _check_objective_granularity_balance(steps)
	if not bool(granularity.get("ok", false)):
		return granularity
	var temporal: Dictionary = _check_temporal_stability_constraints(steps)
	if not bool(temporal.get("ok", false)):
		return temporal
	var action_semantic: Dictionary = _check_objective_action_semantics(steps)
	if not bool(action_semantic.get("ok", false)):
		return action_semantic
	var reward_timing: Dictionary = _check_reward_timing_alignment(steps)
	if not bool(reward_timing.get("ok", false)):
		return reward_timing
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
	_stats["failed"] = int(_stats.get("failed", 0)) + 1
	_last_block_reason = reason
	_reject_reason_counts[reason] = int(_reject_reason_counts.get(reason, 0)) + 1
	_record_daily_reject(reason)
	generation_failed.emit(reason)
	guardrail_blocked.emit(reason, get_runtime_status())
	if _consecutive_failures >= int(config.get("max_consecutive_failures", 3)):
		_breaker_state = "closed"
		_breaker_last_closed_day = _current_day_index()
		generation_degraded.emit("too_many_failures_breaker_closed")
	_emit_runtime_status()

func _maybe_reopen_breaker() -> void:
	if _breaker_state != "closed":
		return
	var now_day: int = _current_day_index()
	var reopen_after: int = int(config.get("breaker_reopen_days", 2))
	if now_day - _breaker_last_closed_day >= reopen_after:
		_breaker_state = "half_open"
		_consecutive_failures = 0

func _emit_runtime_status() -> void:
	runtime_status_updated.emit(get_runtime_status())

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
		_failure_pressure["streak"] = int(_failure_pressure.get("streak", 0)) + 1
		_failure_pressure["last_day"] = _current_day_index()
	else:
		row["success"] = int(row.get("success", 0)) + 1
		_failure_pressure["streak"] = 0
		_failure_pressure["last_day"] = _current_day_index()
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
	var signatures: Array = root.get("recent_signatures", [])
	if signatures is Array:
		_recent_signatures = signatures.duplicate()
	_breaker_state = str(root.get("breaker_state", _breaker_state))
	_breaker_last_closed_day = int(root.get("breaker_last_closed_day", _breaker_last_closed_day))
	var stats: Dictionary = root.get("stats", {})
	if stats is Dictionary:
		_stats = stats.duplicate(true)
	var fp: Dictionary = root.get("failure_pressure", {})
	if fp is Dictionary:
		_failure_pressure = fp.duplicate(true)
	var reward_profiles: Array = root.get("recent_reward_profiles", [])
	if reward_profiles is Array:
		_recent_reward_profiles = reward_profiles.duplicate()
	var daily_rejects: Dictionary = root.get("daily_rejects", {})
	if daily_rejects is Dictionary:
		_daily_rejects = daily_rejects.duplicate(true)
	var rrc: Dictionary = root.get("reject_reason_counts", {})
	if rrc is Dictionary:
		_reject_reason_counts = rrc.duplicate(true)
	_last_block_reason = str(root.get("last_block_reason", ""))
	var sfh: Array = root.get("safe_fallback_history", [])
	if sfh is Array:
		_safe_fallback_history = sfh.duplicate(true)

func _save_runtime_store() -> void:
	var rows: Array = []
	if QuestSystem:
		for chain_id in _runtime_chain_ids:
			if QuestSystem.chain_templates.has(chain_id):
				rows.append((QuestSystem.chain_templates[chain_id] as Dictionary).duplicate(true))
	var root: Dictionary = {
		"version": 1,
		"chains": rows,
		"performance": _performance.duplicate(true),
		"recent_signatures": _recent_signatures.duplicate(),
		"failure_pressure": _failure_pressure.duplicate(),
		"recent_reward_profiles": _recent_reward_profiles.duplicate(),
		"daily_rejects": _daily_rejects.duplicate(),
		"safe_fallback_history": _safe_fallback_history.duplicate(),
		"reject_reason_counts": _reject_reason_counts.duplicate(true),
		"last_block_reason": _last_block_reason,
		"breaker_state": _breaker_state,
		"breaker_last_closed_day": _breaker_last_closed_day,
		"stats": _stats.duplicate(true)
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

func _current_day_index() -> int:
	if not GameManager or not GameManager.player_data:
		return 0
	var season: String = str(GameManager.player_data.get("season", "spring"))
	var season_idx: int = 0
	match season:
		"spring":
			season_idx = 0
		"summer":
			season_idx = 1
		"fall":
			season_idx = 2
		"winter":
			season_idx = 3
		_:
			season_idx = 0
	var year: int = int(GameManager.player_data.get("year", 1))
	var day: int = int(GameManager.player_data.get("day", 1))
	return (year - 1) * 112 + season_idx * 28 + day

func _is_known_npc(npc_id: String) -> bool:
	var id: String = npc_id.strip_edges().to_lower()
	if id.is_empty():
		return false
	if NPCBehaviorController and NPCBehaviorController.has_method("get_all_npc_ids"):
		var ids: Array = NPCBehaviorController.get_all_npc_ids()
		for row in ids:
			if str(row).to_lower() == id:
				return true
	# Safe fallback for current playable roster.
	return id in ["pierre", "abigail", "lewis"]

func _is_valid_item_spec(spec: String) -> bool:
	var s: String = spec.strip_edges()
	if s.is_empty():
		return false
	var parts: PackedStringArray = s.split(":")
	var item_id: String = str(parts[0]).strip_edges()
	if item_id.is_empty():
		return false
	var count: int = int(parts[1]) if parts.size() > 1 else 1
	if count <= 0:
		return false
	if ItemDatabase and ItemDatabase.has_method("get_item"):
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		return not tpl.is_empty()
	return true

func _load_crop_catalog() -> void:
	_crop_seasons_by_id.clear()
	var f: FileAccess = FileAccess.open(CROP_DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Array):
		return
	for row in (json.data as Array):
		if not (row is Dictionary):
			continue
		var d: Dictionary = row
		var cid: String = str(d.get("id", "")).strip_edges()
		if cid.is_empty():
			continue
		var seasons: Array = d.get("seasons", [])
		_crop_seasons_by_id[cid] = seasons.duplicate()

func _is_crop_in_current_season(crop_id: String) -> bool:
	if _crop_seasons_by_id.is_empty():
		return true
	var cid: String = crop_id.strip_edges()
	if cid.is_empty():
		return true
	if not _crop_seasons_by_id.has(cid):
		return false
	var seasons: Array = _crop_seasons_by_id[cid]
	if seasons.is_empty():
		return true
	var cur: String = "spring"
	if GameManager and GameManager.player_data:
		cur = str(GameManager.player_data.get("season", "spring"))
	return seasons.has(cur)

func _has_sellable_economy_route(steps: Array) -> bool:
	var earn_gold_steps: int = 0
	var sum_target_gold: int = 0
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var obj: Dictionary = sd.get("objective", {})
		if str(obj.get("type", "")) == "earn_gold":
			earn_gold_steps += 1
			sum_target_gold += int(obj.get("count", 0))
	if earn_gold_steps <= 0:
		return true
	# Minimal economy feasibility: enough sellable catalog and no unrealistic target.
	var sellable_items: int = 0
	var best_sell_price: int = 0
	if ItemDatabase and ItemDatabase.has_method("get_all_item_ids") and ItemDatabase.has_method("get_item"):
		for item_id in ItemDatabase.get_all_item_ids():
			var tpl: Dictionary = ItemDatabase.get_item(str(item_id))
			var sp: int = int(tpl.get("sell_price", 0))
			if sp > 0:
				sellable_items += 1
				if sp > best_sell_price:
					best_sell_price = sp
	if sellable_items < 8:
		return false
	# One chain should not demand extreme liquidation.
	var hard_cap: int = maxi(220, best_sell_price * 4)
	return sum_target_gold <= hard_cap

func _check_dependency_coherence(steps: Array) -> Dictionary:
	# Prevent chains that ask for selling before any plausible acquisition path appears.
	var earned_before: int = 0
	var seen_gathering_source: bool = false
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", ""))
		if ot in ["harvest", "fish_caught", "mine_ore"]:
			seen_gathering_source = true
		if ot == "earn_gold":
			var need_gold: int = int(objective.get("count", 0))
			if need_gold <= 0:
				continue
			# If no gathering path exists yet, only allow modest sell targets.
			if not seen_gathering_source and need_gold > 120:
				return {"ok": false, "error": "missing_preceding_supply_path"}
			if earned_before < int(round(float(need_gold) * 0.35)) and need_gold > 140:
				return {"ok": false, "error": "insufficient_preceding_reward_path"}
		var reward: Dictionary = sd.get("reward", {})
		earned_before += int(reward.get("gold", 0))
		var items: Array = reward.get("items", [])
		for item_spec in items:
			earned_before += _estimate_item_spec_sell_value(str(item_spec))
	return {"ok": true}

func _estimate_item_spec_sell_value(item_spec: String) -> int:
	var s: String = item_spec.strip_edges()
	if s.is_empty():
		return 0
	var parts: PackedStringArray = s.split(":")
	var item_id: String = str(parts[0]).strip_edges()
	var count: int = int(parts[1]) if parts.size() > 1 else 1
	if count <= 0:
		return 0
	if ItemDatabase and ItemDatabase.has_method("get_item"):
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		return max(0, int(tpl.get("sell_price", 0))) * count
	return 0

func _check_new_player_reachability(steps: Array) -> Dictionary:
	var day: int = int(GameManager.player_data.get("day", 1)) if GameManager and GameManager.player_data else 1
	var has_rod: bool = InventoryManager != null and _has_item_anywhere("fishing_rod")
	var has_pickaxe: bool = InventoryManager != null and (_has_item_anywhere("pickaxe") or _has_item_anywhere("pickaxe_iron"))
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", ""))
		var cnt: int = int(objective.get("count", 1))
		if ot == "fish_caught":
			if not has_rod:
				return {"ok": false, "error": "missing_basic_tool:fishing_rod"}
			if day <= 3 and cnt > 2:
				return {"ok": false, "error": "early_game_fishing_too_heavy"}
		elif ot == "mine_ore":
			if not has_pickaxe:
				return {"ok": false, "error": "missing_basic_tool:pickaxe"}
			if day <= 3 and cnt > 3:
				return {"ok": false, "error": "early_game_mining_too_heavy"}
		elif ot == "harvest":
			if day <= 2 and cnt > 3:
				return {"ok": false, "error": "early_game_harvest_too_heavy"}
	return {"ok": true}

func _has_item_anywhere(item_id: String) -> bool:
	if InventoryManager == null:
		return false
	for i in range(int(InventoryManager.INVENTORY_SIZE)):
		var it = InventoryManager.get_item(i)
		if it == null:
			continue
		if str(it.get("id", "")) == item_id:
			return true
	return false

func _check_duration_feasibility(steps: Array) -> Dictionary:
	var timeout_days: int = 1
	if QuestSystem and QuestSystem.managed_chain_failure is Dictionary:
		timeout_days = maxi(1, int(QuestSystem.managed_chain_failure.get("timeout_days", 1)))
	var budget_minutes: float = float(timeout_days) * 35.0
	var estimated_minutes: float = 0.0
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", ""))
		var cnt: int = maxi(1, int(objective.get("count", 1)))
		match ot:
			"talk":
				estimated_minutes += 3.0
			"harvest":
				estimated_minutes += 4.0 + float(cnt) * 2.0
			"fish_caught":
				estimated_minutes += 5.0 + float(cnt) * 3.0
			"mine_ore":
				estimated_minutes += 6.0 + float(cnt) * 3.0
			"earn_gold":
				estimated_minutes += 8.0 + float(cnt) / 24.0
			_:
				estimated_minutes += 6.0
	if estimated_minutes > budget_minutes:
		return {
			"ok": false,
			"error": "duration_over_timeout_budget",
			"estimated_minutes": estimated_minutes,
			"budget_minutes": budget_minutes
		}
	return {"ok": true}

func _check_reward_inflation(chain_data: Dictionary, steps: Array) -> Dictionary:
	var expected_value: int = _estimate_chain_expected_value(steps)
	var chain_cap: int = int(config.get("max_chain_expected_value", 760))
	if expected_value > chain_cap:
		return {
			"ok": false,
			"error": "chain_expected_value_too_high",
			"expected_value": expected_value,
			"cap": chain_cap
		}
	var runtime_budget: int = int(config.get("max_runtime_value_budget", 2200))
	var projected_total: int = expected_value
	if QuestSystem:
		for chain_id in _runtime_chain_ids:
			if not QuestSystem.chain_templates.has(chain_id):
				continue
			var cd: Dictionary = QuestSystem.chain_templates[chain_id]
			projected_total += _estimate_chain_expected_value(cd.get("steps", []))
	if projected_total > runtime_budget:
		return {
			"ok": false,
			"error": "runtime_value_budget_exceeded",
			"projected_total": projected_total,
			"budget": runtime_budget
		}
	# Optional dynamic baseline vs built-in template average value.
	var baseline_avg: float = _estimate_existing_chain_value_baseline()
	if baseline_avg > 0.0 and float(expected_value) > baseline_avg * 1.45:
		return {
			"ok": false,
			"error": "expected_value_far_above_baseline",
			"expected_value": expected_value,
			"baseline_avg": baseline_avg
		}
	return {"ok": true}

func _estimate_chain_expected_value(steps: Array) -> int:
	var total: int = 0
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var reward: Dictionary = sd.get("reward", {})
		total += int(reward.get("gold", 0))
		var items: Array = reward.get("items", [])
		for item_spec in items:
			total += _estimate_item_spec_sell_value(str(item_spec))
		var pool: Dictionary = reward.get("pool", {})
		var entries: Array = pool.get("entries", [])
		var draws: int = maxi(0, int(pool.get("count", 1)))
		total += int(round(_estimate_pool_expected_value(entries) * float(draws)))
	return total

func _estimate_pool_expected_value(entries: Array) -> float:
	var total_w: float = 0.0
	var weighted_v: float = 0.0
	for e in entries:
		if not (e is Dictionary):
			continue
		var ed: Dictionary = e
		var w: float = maxf(0.0, float(ed.get("weight", 0.0)))
		if w <= 0.0:
			continue
		total_w += w
		weighted_v += float(_estimate_item_spec_sell_value(str(ed.get("item", "")))) * w
	if total_w <= 0.0:
		return 0.0
	return weighted_v / total_w

func _estimate_existing_chain_value_baseline() -> float:
	if QuestSystem == null:
		return 0.0
	var total: float = 0.0
	var n: int = 0
	for chain_id in QuestSystem.chain_templates.keys():
		var cd: Dictionary = QuestSystem.chain_templates[chain_id]
		total += float(_estimate_chain_expected_value(cd.get("steps", [])))
		n += 1
	if n <= 0:
		return 0.0
	return total / float(n)

func _check_objective_semantic_coherence(steps: Array) -> Dictionary:
	# Guard against "talk to X" objective while text implies "talk to Y".
	var known_npcs: Dictionary = {
		"pierre": "Pierre",
		"abigail": "Abigail",
		"lewis": "Lewis"
	}
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", ""))
		if ot != "talk":
			continue
		var target_id: String = str(objective.get("npc_id", "")).to_lower().strip_edges()
		if target_id.is_empty():
			return {"ok": false, "error": "talk_missing_npc"}
		var text_blob: String = "%s %s" % [str(sd.get("title", "")), str(sd.get("description", ""))]
		var lower_blob: String = text_blob.to_lower()
		for npc_id in known_npcs.keys():
			var npc_name: String = str(known_npcs[npc_id]).to_lower()
			if lower_blob.find(npc_name) >= 0 and npc_id != target_id:
				return {"ok": false, "error": "talk_npc_semantic_mismatch"}
	return {"ok": true}

func _chain_primary_objective_type(chain_data: Dictionary) -> String:
	var steps: Array = chain_data.get("steps", [])
	for s in steps:
		if not (s is Dictionary):
			continue
		var ot: String = str((s as Dictionary).get("objective", {}).get("type", "")).strip_edges()
		if ot.is_empty():
			continue
		if ot == "talk":
			continue
		return ot
	if steps.size() > 0 and steps[0] is Dictionary:
		return str((steps[0] as Dictionary).get("objective", {}).get("type", "")).strip_edges()
	return ""

func _today_mix_key() -> String:
	return "agentic_runtime_mix_%s" % _day_key()

func _conflicts_with_today_objective_mix(chain_data: Dictionary) -> bool:
	if not GameManager or not GameManager.player_data:
		return false
	var primary: String = _chain_primary_objective_type(chain_data)
	if primary.is_empty():
		return false
	var mix: Dictionary = GameManager.player_data.get(_today_mix_key(), {})
	if not (mix is Dictionary):
		return false
	var count_same: int = int((mix as Dictionary).get(primary, 0))
	return count_same >= 1

func _record_today_objective_signature(chain_data: Dictionary) -> void:
	if not GameManager or not GameManager.player_data:
		return
	var primary: String = _chain_primary_objective_type(chain_data)
	if primary.is_empty():
		return
	var key: String = _today_mix_key()
	var mix: Dictionary = GameManager.player_data.get(key, {})
	if not (mix is Dictionary):
		mix = {}
	mix[primary] = int(mix.get(primary, 0)) + 1
	GameManager.player_data[key] = mix

func _chain_signature(chain_data: Dictionary) -> String:
	var theme: String = ""
	var preferred: Array = chain_data.get("preferred_themes", [])
	if not preferred.is_empty():
		theme = str(preferred[0]).to_lower()
	var seq: PackedStringArray = []
	var steps: Array = chain_data.get("steps", [])
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var ot: String = str(sd.get("objective", {}).get("type", "")).to_lower()
		var cnt: int = int(sd.get("objective", {}).get("count", 1))
		seq.append("%s:%d" % [ot, cnt])
	return "%s|%s" % [theme, ",".join(seq)]

func _is_short_window_repetition(chain_data: Dictionary) -> bool:
	var sig: String = _chain_signature(chain_data)
	if sig.is_empty():
		return false
	for row in _recent_signatures:
		if str(row) == sig:
			return true
	return false

func _record_recent_signature(chain_data: Dictionary) -> void:
	var sig: String = _chain_signature(chain_data)
	if sig.is_empty():
		return
	_recent_signatures.append(sig)
	while _recent_signatures.size() > 8:
		_recent_signatures.pop_front()

func _check_current_player_state_fit(steps: Array) -> Dictionary:
	var stamina_ratio: float = 1.0
	if GameManager and GameManager.has_method("get_stamina_ratio"):
		stamina_ratio = float(GameManager.get_stamina_ratio())
	var free_slots: int = _estimate_free_inventory_slots()
	var effort_score: int = 0
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", ""))
		var cnt: int = maxi(1, int(objective.get("count", 1)))
		match ot:
			"mine_ore":
				effort_score += 3 * cnt
			"fish_caught":
				effort_score += 3 * cnt
			"harvest":
				effort_score += 2 * cnt
			"earn_gold":
				effort_score += 2
			_:
				effort_score += 1
	# Low stamina: avoid heavy objectives for the current day.
	if stamina_ratio < 0.35 and effort_score >= 12:
		return {"ok": false, "error": "player_state_low_stamina_for_heavy_chain"}
	# Low inventory headroom: avoid item-generating routes.
	if free_slots <= 2:
		for s in steps:
			if not (s is Dictionary):
				continue
			var ot2: String = str((s as Dictionary).get("objective", {}).get("type", ""))
			if ot2 in ["harvest", "fish_caught", "mine_ore"]:
				return {"ok": false, "error": "player_state_low_inventory_for_gather_chain"}
	return {"ok": true}

func _check_failure_spiral_protection(steps: Array) -> Dictionary:
	var streak: int = int(_failure_pressure.get("streak", 0))
	if streak < 2:
		return {"ok": true}
	for s in steps:
		if not (s is Dictionary):
			continue
		var objective: Dictionary = (s as Dictionary).get("objective", {})
		if str(objective.get("type", "")) != "earn_gold":
			continue
		var need: int = int(objective.get("count", 0))
		if need > 110:
			return {"ok": false, "error": "failure_spiral_earn_gold_too_high"}
	if not _has_recovery_supply_reward(steps):
		return {"ok": false, "error": "failure_spiral_missing_supply_reward"}
	return {"ok": true}

func _has_recovery_supply_reward(steps: Array) -> bool:
	var recovery_items: Dictionary = {
		"bread": true,
		"worm_bait": true,
		"basic_fertilizer": true,
		"parsnip_seeds": true,
		"potato_seeds": true,
		"corn_seeds": true,
		"pumpkin_seeds": true
	}
	for s in steps:
		if not (s is Dictionary):
			continue
		var reward: Dictionary = (s as Dictionary).get("reward", {})
		for item_spec in reward.get("items", []):
			var item_id: String = str(item_spec).split(":")[0]
			if recovery_items.has(item_id):
				return true
	return false

func _check_reward_structure_diversity(steps: Array) -> Dictionary:
	var gold_total: int = 0
	var item_value_total: int = 0
	var type_set: Dictionary = {}
	for s in steps:
		if not (s is Dictionary):
			continue
		var reward: Dictionary = (s as Dictionary).get("reward", {})
		gold_total += int(reward.get("gold", 0))
		for item_spec in reward.get("items", []):
			item_value_total += _estimate_item_spec_sell_value(str(item_spec))
			var item_id: String = str(item_spec).split(":")[0]
			var item_type: String = _item_type(item_id)
			if not item_type.is_empty():
				type_set[item_type] = true
		var pool: Dictionary = reward.get("pool", {})
		for e in pool.get("entries", []):
			if e is Dictionary:
				var item_id2: String = str((e as Dictionary).get("item", "")).split(":")[0]
				var item_type2: String = _item_type(item_id2)
				if not item_type2.is_empty():
					type_set[item_type2] = true
	var total_value: int = maxi(1, gold_total + item_value_total)
	var gold_ratio: float = float(gold_total) / float(total_value)
	var type_diversity: int = type_set.size()
	if gold_ratio > 0.88 and type_diversity < 2:
		return {"ok": false, "error": "reward_structure_too_gold_heavy"}
	if _recent_gold_heavy_run(3) and gold_ratio > 0.82:
		return {"ok": false, "error": "reward_structure_monotony_streak"}
	return {"ok": true}

func _recent_gold_heavy_run(k: int) -> bool:
	if _recent_reward_profiles.size() < k:
		return false
	for i in range(_recent_reward_profiles.size() - k, _recent_reward_profiles.size()):
		var row: Dictionary = _recent_reward_profiles[i] if _recent_reward_profiles[i] is Dictionary else {}
		if float(row.get("gold_ratio", 0.0)) <= 0.8:
			return false
	return true

func _record_reward_profile(chain_data: Dictionary) -> void:
	var steps: Array = chain_data.get("steps", [])
	var gold_total: int = 0
	var item_value_total: int = 0
	var type_set: Dictionary = {}
	for s in steps:
		if not (s is Dictionary):
			continue
		var reward: Dictionary = (s as Dictionary).get("reward", {})
		gold_total += int(reward.get("gold", 0))
		for item_spec in reward.get("items", []):
			item_value_total += _estimate_item_spec_sell_value(str(item_spec))
			var item_id: String = str(item_spec).split(":")[0]
			var t: String = _item_type(item_id)
			if not t.is_empty():
				type_set[t] = true
	var total_value: int = maxi(1, gold_total + item_value_total)
	_recent_reward_profiles.append({
		"gold_ratio": float(gold_total) / float(total_value),
		"type_diversity": type_set.size()
	})
	while _recent_reward_profiles.size() > 12:
		_recent_reward_profiles.pop_front()

func _item_type(item_id: String) -> String:
	if ItemDatabase and ItemDatabase.has_method("get_item"):
		var tpl: Dictionary = ItemDatabase.get_item(item_id)
		return str(tpl.get("type", "")).strip_edges()
	return ""

func _check_map_reachability_constraints(steps: Array) -> Dictionary:
	var day: int = int(GameManager.player_data.get("day", 1)) if GameManager and GameManager.player_data else 1
	var hour: int = int(GameManager.current_time) if GameManager else 12
	var weather_name: String = str(WeatherSystem.get_weather_name()).to_lower() if WeatherSystem else "sunny"
	var has_iron_pick: bool = _has_item_anywhere("pickaxe_iron")
	for s in steps:
		if not (s is Dictionary):
			continue
		var objective: Dictionary = (s as Dictionary).get("objective", {})
		var ot: String = str(objective.get("type", ""))
		var cnt: int = maxi(1, int(objective.get("count", 1)))
		if ot == "mine_ore":
			# Early days: avoid deep-mine style quotas.
			if day <= 2 and cnt > 2:
				return {"ok": false, "error": "map_reachability_early_mine_quota"}
			# High ore counts imply deeper routing; require stronger pick access.
			if cnt >= 5 and not has_iron_pick:
				return {"ok": false, "error": "map_reachability_missing_iron_pickaxe"}
			# Late hour: mine-trip tasks should stay light.
			if hour >= 20 and cnt > 2:
				return {"ok": false, "error": "map_reachability_late_hour_mining"}
		elif ot == "fish_caught":
			# Harsh weather + high catch quota tends to be unreliable.
			if (weather_name == "storm" or weather_name == "snow") and cnt > 2:
				return {"ok": false, "error": "map_reachability_weather_fishing"}
			if hour >= 20 and cnt > 2:
				return {"ok": false, "error": "map_reachability_late_hour_fishing"}
	return {"ok": true}

func _check_objective_granularity_balance(steps: Array) -> Dictionary:
	# Normalize counts by objective effort so equal "count" does not imply wildly different workload.
	var effort_weights: Dictionary = {
		"talk": 1.0,
		"harvest": 1.8,
		"fish_caught": 2.6,
		"mine_ore": 2.8,
		"earn_gold": 0.025 # count is in gold units
	}
	var normalized: Array = []
	for s in steps:
		if not (s is Dictionary):
			continue
		var objective: Dictionary = (s as Dictionary).get("objective", {})
		var ot: String = str(objective.get("type", "")).strip_edges()
		var cnt: int = maxi(1, int(objective.get("count", 1)))
		var w: float = float(effort_weights.get(ot, 2.0))
		var unit: float = float(cnt) * w
		if ot == "earn_gold":
			unit = maxf(1.0, float(cnt) * w)
		normalized.append(unit)
		# Per-type cap to avoid inflated counts under same objective family.
		if ot == "talk" and cnt > 2:
			return {"ok": false, "error": "granularity_talk_count_too_high"}
		if ot == "harvest" and cnt > 5:
			return {"ok": false, "error": "granularity_harvest_count_too_high"}
		if ot == "fish_caught" and cnt > 4:
			return {"ok": false, "error": "granularity_fishing_count_too_high"}
		if ot == "mine_ore" and cnt > 4:
			return {"ok": false, "error": "granularity_mining_count_too_high"}
	if normalized.size() <= 1:
		return {"ok": true}
	normalized.sort()
	var min_u: float = float(normalized[0])
	var max_u: float = float(normalized[normalized.size() - 1])
	if max_u > min_u * 3.2:
		return {"ok": false, "error": "granularity_effort_imbalance"}
	return {"ok": true}

func _check_temporal_stability_constraints(steps: Array) -> Dictionary:
	var day: int = int(GameManager.player_data.get("day", 1)) if GameManager and GameManager.player_data else 1
	var season: String = str(GameManager.player_data.get("season", "spring")) if GameManager and GameManager.player_data else "spring"
	var week_boundary: bool = (day % 7) == 1
	var season_boundary: bool = day == 1
	var weather_name: String = str(WeatherSystem.get_weather_name()).to_lower() if WeatherSystem else "sunny"
	var volatility_score: int = 0
	for s in steps:
		if not (s is Dictionary):
			continue
		var objective: Dictionary = (s as Dictionary).get("objective", {})
		var ot: String = str(objective.get("type", ""))
		match ot:
			"mine_ore", "fish_caught":
				volatility_score += 2
			"earn_gold":
				volatility_score += 2
			"harvest":
				volatility_score += 1
			_:
				volatility_score += 1
	# On system-shift days (new week/season), keep runtime chains gentle.
	if (week_boundary or season_boundary) and volatility_score >= 6:
		return {"ok": false, "error": "temporal_stability_shift_day_overload"}
	# During harsh weather windows, avoid high-volatility mixed objectives.
	if (weather_name == "storm" or weather_name == "snow") and volatility_score >= 5:
		return {"ok": false, "error": "temporal_stability_weather_overload"}
	# First day of a new season should avoid stacked sell-pressure chains.
	if season_boundary and _count_objective_type(steps, "earn_gold") >= 2:
		return {"ok": false, "error": "temporal_stability_season_reset_sell_pressure"}
	return {"ok": true}

func _count_objective_type(steps: Array, objective_type: String) -> int:
	var n: int = 0
	for s in steps:
		if not (s is Dictionary):
			continue
		var ot: String = str((s as Dictionary).get("objective", {}).get("type", ""))
		if ot == objective_type:
			n += 1
	return n

func _check_objective_action_semantics(steps: Array) -> Dictionary:
	# Catch subtle "semantic drift": objective type says one action, text implies another.
	var hint_words: Dictionary = {
		"talk": ["talk", "speak", "ask", "meet", "report"],
		"harvest": ["harvest", "pick", "gather", "collect crops"],
		"fish_caught": ["fish", "catch", "reel", "hook"],
		"mine_ore": ["mine", "ore", "dig", "pickaxe"],
		"earn_gold": ["sell", "gold", "trade", "market", "cargo"]
	}
	for s in steps:
		if not (s is Dictionary):
			continue
		var sd: Dictionary = s
		var objective: Dictionary = sd.get("objective", {})
		var ot: String = str(objective.get("type", "")).strip_edges()
		if ot.is_empty() or not hint_words.has(ot):
			continue
		var blob: String = ("%s %s" % [str(sd.get("title", "")), str(sd.get("description", ""))]).to_lower()
		var target_hints: Array = hint_words[ot]
		var matched_target: bool = false
		for w in target_hints:
			if blob.find(str(w)) >= 0:
				matched_target = true
				break
		if not matched_target:
			return {"ok": false, "error": "semantic_drift_missing_target_action_hint"}
		# If text strongly hints another action family, reject as ambiguous.
		for other_type in hint_words.keys():
			if str(other_type) == ot:
				continue
			for ow in (hint_words[other_type] as Array):
				if blob.find(str(ow)) >= 0:
					return {"ok": false, "error": "semantic_drift_cross_action_hint"}
	return {"ok": true}

func _check_reward_timing_alignment(steps: Array) -> Dictionary:
	# If later steps demand higher effort, earlier steps should grant at least one practical supply/tool reward.
	var supportive_item_types: Dictionary = {
		"bait": true,
		"fertilizer": true,
		"seed": true,
		"food": true,
		"resource": true
	}
	var early_support: bool = false
	for i in range(mini(2, steps.size())):
		if not (steps[i] is Dictionary):
			continue
		var reward: Dictionary = (steps[i] as Dictionary).get("reward", {})
		for item_spec in reward.get("items", []):
			var item_id: String = str(item_spec).split(":")[0]
			var t: String = _item_type(item_id)
			if supportive_item_types.has(t):
				early_support = true
				break
		if early_support:
			break
	var late_heavy: bool = false
	for i in range(1, steps.size()):
		if not (steps[i] is Dictionary):
			continue
		var objective: Dictionary = (steps[i] as Dictionary).get("objective", {})
		var ot: String = str(objective.get("type", ""))
		var cnt: int = int(objective.get("count", 1))
		if (ot == "mine_ore" and cnt >= 3) or (ot == "fish_caught" and cnt >= 3) or (ot == "earn_gold" and cnt >= 120):
			late_heavy = true
			break
	if late_heavy and not early_support:
		return {"ok": false, "error": "reward_timing_missing_early_support"}
	return {"ok": true}

func _record_daily_reject(_reason: String) -> void:
	var key: String = _day_key()
	_daily_rejects[key] = int(_daily_rejects.get(key, 0)) + 1

func _today_reject_count() -> int:
	return int(_daily_rejects.get(_day_key(), 0))

func _try_safe_fallback_chain(theme: String) -> Dictionary:
	if _today_reject_count() < 3:
		return {}
	if _safe_fallback_count_today() >= int(config.get("safe_fallback_daily_cap", 1)):
		return {}
	if _safe_fallback_count_recent_week() >= int(config.get("safe_fallback_weekly_cap", 3)):
		return {}
	return _build_safe_recovery_chain(theme)

func _build_safe_recovery_chain(theme: String) -> Dictionary:
	var stamp: int = int(Time.get_unix_time_from_system())
	var cid: String = "%srecovery_%s_%d" % [CHAIN_ID_PREFIX, theme, stamp]
	return {
		"id": cid,
		"display_name": "Recovery Relief Chain",
		"cooldown_days": 1,
		"preferred_themes": [theme, "joyful"],
		"steps": [
			{
				"id": "%s_s1" % cid,
				"title": "Recovery I: Check In",
				"description": "Talk to Pierre to receive a practical recovery plan.",
				"objective": {"type": "talk", "npc_id": "pierre", "count": 1},
				"reward": {"gold": 52, "items": ["bread:1", "worm_bait:2"]}
			},
			{
				"id": "%s_s2" % cid,
				"title": "Recovery II: Gather Basics",
				"description": "Harvest 2 crops to stabilize today's supplies.",
				"objective": {"type": "harvest", "count": 2},
				"reward": {"gold": 64, "items": ["basic_fertilizer:1"]}
			},
			{
				"id": "%s_s3" % cid,
				"title": "Recovery III: Light Trade",
				"description": "Sell goods worth 90g to close the recovery loop.",
				"objective": {"type": "earn_gold", "count": 90},
				"reward": {"gold": 86, "items": ["parsnip_seeds:2"]}
			}
		]
	}

func _top_block_reason() -> Dictionary:
	var best_reason: String = ""
	var best_count: int = 0
	for k in _reject_reason_counts.keys():
		var c: int = int(_reject_reason_counts.get(k, 0))
		if c > best_count:
			best_count = c
			best_reason = str(k)
	return {"reason": best_reason, "count": best_count}

func _safe_fallback_count_today() -> int:
	var dk: String = _day_key()
	var n: int = 0
	for row in _safe_fallback_history:
		if row is Dictionary and str((row as Dictionary).get("day_key", "")) == dk:
			n += 1
	return n

func _safe_fallback_count_recent_week() -> int:
	var now_idx: int = _current_day_index()
	var n: int = 0
	for row in _safe_fallback_history:
		if not (row is Dictionary):
			continue
		var d: Dictionary = row
		var idx: int = int(d.get("day_index", -9999))
		if now_idx - idx <= 6:
			n += 1
	return n

func _estimate_free_inventory_slots() -> int:
	if InventoryManager == null:
		return 99
	var free: int = 0
	for i in range(int(InventoryManager.INVENTORY_SIZE)):
		if InventoryManager.get_item(i) == null:
			free += 1
	return free
