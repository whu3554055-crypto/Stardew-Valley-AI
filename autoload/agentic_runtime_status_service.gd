extends RefCounted
class_name AgenticRuntimeStatusService

## Builds status lines and recovery hints for orchestrator/UI.
## Keeping this separate avoids policy text living in orchestration flow.

static func build_status_line(
	breaker_state: String,
	queue_size: int,
	chain_count: int,
	published: int,
	failed: int,
	last_block_reason: String
) -> String:
	var top_block := last_block_reason if not last_block_reason.is_empty() else "-"
	return "Agentic runtime | breaker=%s | queued=%d | chains=%d | ok=%d fail=%d | top_block=%s" % [
		breaker_state,
		queue_size,
		chain_count,
		published,
		failed,
		top_block
	]

static func recovery_hint_for_reason(reason: String) -> String:
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
			if reason.begins_with("llm_request_failed:"):
				return "Check AI endpoint/model/api_key and network connectivity."
			return "Use manual override chain for today and keep runtime in canary mode."

