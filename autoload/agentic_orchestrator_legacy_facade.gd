extends Node

## Thin compatibility facade for orchestrator callers.
## Callers should depend on this stable surface during refactor migration.
signal generation_started(reason: String)
signal generation_published(chain_id: String, mode: String)
signal generation_failed(reason: String)
signal generation_degraded(reason: String)
signal runtime_status_updated(snapshot: Dictionary)
signal guardrail_blocked(reason: String, snapshot: Dictionary)

func _ready() -> void:
	var orchestrator := _orchestrator()
	if orchestrator == null:
		return
	if orchestrator.has_signal("generation_started"):
		orchestrator.generation_started.connect(_on_generation_started)
	if orchestrator.has_signal("generation_published"):
		orchestrator.generation_published.connect(_on_generation_published)
	if orchestrator.has_signal("generation_failed"):
		orchestrator.generation_failed.connect(_on_generation_failed)
	if orchestrator.has_signal("generation_degraded"):
		orchestrator.generation_degraded.connect(_on_generation_degraded)
	if orchestrator.has_signal("runtime_status_updated"):
		orchestrator.runtime_status_updated.connect(_on_runtime_status_updated)
	if orchestrator.has_signal("guardrail_blocked"):
		orchestrator.guardrail_blocked.connect(_on_guardrail_blocked)

func _orchestrator() -> Node:
	return get_node_or_null("/root/AgenticContentOrchestrator")

func maybe_generate_for_day(narrative: Dictionary = {}) -> void:
	var orchestrator := _orchestrator()
	if orchestrator and orchestrator.has_method("maybe_generate_for_day"):
		await orchestrator.maybe_generate_for_day(narrative)

func get_status_line() -> String:
	var orchestrator := _orchestrator()
	if orchestrator and orchestrator.has_method("get_status_line"):
		return str(orchestrator.get_status_line())
	return ""

func get_recovery_hint(reason: String) -> String:
	var orchestrator := _orchestrator()
	if orchestrator and orchestrator.has_method("get_recovery_hint"):
		return str(orchestrator.get_recovery_hint(reason))
	return ""

# Legacy aliases kept for transition. Prefer get_status_line/get_recovery_hint.
func get_runtime_status_line() -> String:
	return get_status_line()

func get_recovery_guidance(reason: String) -> String:
	return get_recovery_hint(reason)

func _on_generation_started(reason: String) -> void:
	emit_signal("generation_started", reason)

func _on_generation_published(chain_id: String, mode: String) -> void:
	emit_signal("generation_published", chain_id, mode)

func _on_generation_failed(reason: String) -> void:
	emit_signal("generation_failed", reason)

func _on_generation_degraded(reason: String) -> void:
	emit_signal("generation_degraded", reason)

func _on_runtime_status_updated(snapshot: Dictionary) -> void:
	emit_signal("runtime_status_updated", snapshot)

func _on_guardrail_blocked(reason: String, snapshot: Dictionary) -> void:
	emit_signal("guardrail_blocked", reason, snapshot)

