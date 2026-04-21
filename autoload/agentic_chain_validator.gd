extends Node
## AgenticChainValidator - Validates agentic chain templates and enforces guardrails.
## Ensures chain quality, prevents duplicates, and maintains balance.
##
## Responsibilities:
## - Chain template structure validation
## - Guardrail checks (content safety, balance)
## - Signature deduplication
## - Value budget enforcement

# === 常量 ===

const MAX_OBJECTIVES_PER_CHAIN := 5
const MAX_REWARD_VALUE := 500
const MIN_REWARD_VALUE := 10
const SIGNATURE_HISTORY_SIZE := 50

# === 成员变量 ===

var _recent_signatures: Array[String] = []
var _reject_reason_counts: Dictionary = {}
var _daily_rejects: Dictionary = {}
var _last_block_reason: String = ""

# === 信号 ===

signal validation_passed(chain_id: String)
signal validation_failed(chain_id: String, reason: String)
signal guardrail_triggered(chain_id: String, rule: String)
signal duplicate_detected(signature: String)

# === 生命周期方法 ===

func _ready() -> void:
	if OS.is_debug_build():
		print("[AgenticChainValidator] Initialized")

# === 公共方法 ===

## Validate a complete chain template
func validate_chain_template(chain: Dictionary) -> Dictionary:
	"""
	Validate chain template structure and content.
	Returns: {"ok": bool, "errors": Array[String]}
	"""
	var errors: Array[String] = []
	
	# Check required fields
	if not _has_required_fields(chain, errors):
		return {"ok": false, "errors": errors}
	
	# Validate objectives
	if not _validate_objectives(chain, errors):
		return {"ok": false, "errors": errors}
	
	# Validate rewards
	if not _validate_rewards(chain, errors):
		return {"ok": false, "errors": errors}
	
	# Check guardrails
	if not _check_guardrails(chain, errors):
		return {"ok": false, "errors": errors}
	
	# Check for duplicates
	if _is_duplicate_signature(chain):
		errors.append("Duplicate signature detected")
		return {"ok": false, "errors": errors}
	
	# All checks passed
	if errors.is_empty():
		_record_signature(chain)
		emit_signal("validation_passed", chain.get("id", "unknown"))
		return {"ok": true, "errors": []}
	
	return {"ok": false, "errors": errors}

## Check if chain passes guardrail rules
func check_guardrails(chain: Dictionary) -> Dictionary:
	"""
	Check content safety and balance rules.
	Returns: {"passed": bool, "violations": Array[String]}
	"""
	var violations: Array[String] = []
	
	# Content safety checks
	if not _check_content_safety(chain, violations):
		emit_signal("guardrail_triggered", chain.get("id", ""), "content_safety")
	
	# Balance checks
	if not _check_balance(chain, violations):
		emit_signal("guardrail_triggered", chain.get("id", ""), "balance")
	
	# Complexity checks
	if not _check_complexity(chain, violations):
		emit_signal("guardrail_triggered", chain.get("id", ""), "complexity")
	
	return {
		"passed": violations.is_empty(),
		"violations": violations
	}

## Record rejection reason for analytics
func record_rejection(reason: String, chain_id: String = "") -> void:
	"""Track why chains are rejected"""
	if not _reject_reason_counts.has(reason):
		_reject_reason_counts[reason] = 0
	
	_reject_reason_counts[reason] += 1
	
	var today = Time.get_date_string_from_system()
	if not _daily_rejects.has(today):
		_daily_rejects[today] = []
	
	_daily_rejects[today].append({
		"chain_id": chain_id,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	_last_block_reason = reason

## Get rejection statistics
func get_rejection_stats() -> Dictionary:
	"""Get analytics on rejection reasons"""
	return {
		"by_reason": _reject_reason_counts.duplicate(),
		"today_count": _daily_rejects.get(Time.get_date_string_from_system(), []).size(),
		"last_block_reason": _last_block_reason
	}

## Clear signature history (use sparingly)
func clear_signature_history() -> void:
	_recent_signatures.clear()

# === 私有方法 ===

func _has_required_fields(chain: Dictionary, errors: Array[String]) -> bool:
	"""Check that all required fields are present"""
	var required = ["id", "title", "theme", "objectives", "rewards"]
	var has_all = true
	
	for field in required:
		if not chain.has(field):
			errors.append("Missing required field: %s" % field)
			has_all = false
	
	return has_all

func _validate_objectives(chain: Dictionary, errors: Array[String]) -> bool:
	"""Validate chain objectives"""
	var objectives = chain.get("objectives", [])
	
	if objectives.is_empty():
		errors.append("Chain must have at least one objective")
		return false
	
	if objectives.size() > MAX_OBJECTIVES_PER_CHAIN:
		errors.append("Too many objectives (%d > %d)" % [objectives.size(), MAX_OBJECTIVES_PER_CHAIN])
		return false
	
	# Validate each objective
	for i in range(objectives.size()):
		var obj = objectives[i]
		if not obj is Dictionary:
			errors.append("Objective %d is not a dictionary" % i)
			return false
		
		if not obj.has("type") or not obj.has("description"):
			errors.append("Objective %d missing type or description" % i)
			return false
	
	return true

func _validate_rewards(chain: Dictionary, errors: Array[String]) -> bool:
	"""Validate reward structure and values"""
	var rewards = chain.get("rewards", {})
	
	if rewards.is_empty():
		errors.append("Chain must have rewards")
		return false
	
	# Check total value
	var total_value = rewards.get("total_value", 0)
	if total_value < MIN_REWARD_VALUE:
		errors.append("Reward value too low (%d < %d)" % [total_value, MIN_REWARD_VALUE])
		return false
	
	if total_value > MAX_REWARD_VALUE:
		errors.append("Reward value too high (%d > %d)" % [total_value, MAX_REWARD_VALUE])
		return false
	
	return true

func _check_guardrails(chain: Dictionary, errors: Array[String]) -> bool:
	"""Apply guardrail rules"""
	# Check for inappropriate content
	var title = chain.get("title", "").to_lower()
	var description = str(chain.get("description", "")).to_lower()
	
	var blocked_terms = ["inappropriate", "blocked", "unsafe"]  # Add actual terms
	for term in blocked_terms:
		if term in title or term in description:
			errors.append("Content safety violation")
			record_rejection("content_safety", chain.get("id", ""))
			return false
	
	return true

func _is_duplicate_signature(chain: Dictionary) -> bool:
	"""Check if chain signature matches recent chains"""
	var signature = _generate_signature(chain)
	
	if signature in _recent_signatures:
		emit_signal("duplicate_detected", signature)
		record_rejection("duplicate_signature", chain.get("id", ""))
		return true
	
	return false

func _generate_signature(chain: Dictionary) -> String:
	"""Generate unique signature for chain"""
	var key_parts = [
		chain.get("theme", ""),
		chain.get("primary_objective", ""),
		str(chain.get("reward_tier", ""))
	]
	
	var signature_str = "|".join(key_parts)
	return signature_str.md5_text().substr(0, 16)

func _record_signature(chain: Dictionary) -> void:
	"""Add signature to history"""
	var signature = _generate_signature(chain)
	
	_recent_signatures.append(signature)
	
	# Keep only recent signatures
	if _recent_signatures.size() > SIGNATURE_HISTORY_SIZE:
		_recent_signatures.pop_front()

func _check_content_safety(chain: Dictionary, violations: Array[String]) -> bool:
	"""Check for inappropriate content"""
	# Implementation would check against content policies
	return true

func _check_balance(chain: Dictionary, violations: Array[String]) -> bool:
	"""Check reward/difficulty balance"""
	var difficulty = chain.get("difficulty", "medium")
	var rewards = chain.get("rewards", {})
	var total_value = rewards.get("total_value", 0)
	
	# Simple balance check
	if difficulty == "easy" and total_value > 300:
		violations.append("Rewards too high for easy difficulty")
		return false
	
	if difficulty == "hard" and total_value < 200:
		violations.append("Rewards too low for hard difficulty")
		return false
	
	return true

func _check_complexity(chain: Dictionary, violations: Array[String]) -> bool:
	"""Check chain complexity is appropriate"""
	var objectives = chain.get("objectives", [])
	
	if objectives.size() > 4:
		violations.append("Chain too complex (%d objectives)" % objectives.size())
		return false
	
	return true
