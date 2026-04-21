extends Node
## AgenticFallbackGenerator - Generates chains via AI or procedural fallback.
## Implements multi-tier generation strategy with graceful degradation.
##
## Responsibilities:
## - AI-based chain generation (primary)
## - Procedural generation (fallback)
## - Safe fallback chains (last resort)
## - Generation strategy coordination

# === 常量 ===

const AI_TIMEOUT := 8.0
const MAX_RETRY_ATTEMPTS := 2

# === 成员变量 ===

var _use_ai_first: bool = true
var _allow_procedural_fallback: bool = true

# === 信号 ===

signal ai_generation_started(theme: String, objective: String)
signal ai_generation_completed(success: bool, chain: Dictionary)
signal procedural_fallback_used(theme: String)
signal safe_fallback_used(theme: String)
signal generation_degraded(reason: String)  # For compatibility with orchestrator

# === 生命周期方法 ===

func _ready() -> void:
	if OS.is_debug_build():
		print("[AgenticFallbackGenerator] Initialized")

# === 公共方法 ===

## Generate chain using best available method
func generate_chain(theme: String, objective: String) -> Dictionary:
	"""
	Generate chain using tiered strategy:
	1. AI generation (if enabled)
	2. Procedural fallback (if enabled)
	3. Safe fallback (always available)
	
	Returns: Chain dictionary or empty if all methods failed
	"""
	var chain_data: Dictionary = {}
	var mode: String = "none"
	
	# Tier 1: AI generation
	if _use_ai_first:
		emit_signal("ai_generation_started", theme, objective)
		chain_data = await _generate_chain_via_ai(theme, objective)
		mode = "ai"
	
	# Tier 2: Procedural fallback
	if chain_data.is_empty() and _allow_procedural_fallback:
		chain_data = _build_procedural_chain(theme, objective)
		mode = "procedural"
		emit_signal("procedural_fallback_used", theme)
	
	# Tier 3: Safe fallback
	if chain_data.is_empty():
		chain_data = _try_safe_fallback_chain(theme)
		mode = "safe_fallback"
		emit_signal("safe_fallback_used", theme)
	
	if not chain_data.is_empty():
		chain_data["generation_mode"] = mode
	
	return chain_data

## Set generation preferences
func set_generation_preferences(use_ai: bool, allow_fallback: bool) -> void:
	"""Configure generation strategy"""
	_use_ai_first = use_ai
	_allow_procedural_fallback = allow_fallback

# === 私有方法 ===

func _generate_chain_via_ai(theme: String, objective: String) -> Dictionary:
	"""
	Generate chain using AI/LLM.
	Returns empty dict on failure.
	"""
	# This would integrate with your AI system
	# For now, return empty to trigger fallback
	
	# Example integration:
	# if has_node("/root/AdvancedAIAgentManager"):
	#     var ai_manager = get_node("/root/AdvancedAIAgentManager")
	#     var prompt = _build_ai_prompt(theme, objective)
	#     var result = await ai_manager.generate_with_timeout(prompt, AI_TIMEOUT)
	#     
	#     if not result.success:
	#         emit_signal("generation_degraded", "llm_request_failed:%s" % result.error)
	#         return {}
	#     
	#     var parsed = _parse_ai_response(result.data)
	#     if parsed.is_empty():
	#         emit_signal("generation_degraded", "llm_invalid_json")
	#         return {}
	#     
	#     return parsed
	
	# Current behavior: AI not implemented, emit degradation and return empty
	emit_signal("generation_degraded", "ai_not_implemented")
	return {}

func _build_procedural_chain(theme: String, objective: String) -> Dictionary:
	"""
	Generate chain procedurally based on templates.
	Fallback when AI is unavailable.
	"""
	var chain_id = "procedural_%s_%d" % [theme, Time.get_unix_time_from_system()]
	
	# Simple procedural generation
	var objectives = _generate_procedural_objectives(objective)
	var rewards = _generate_procedural_rewards(objectives.size())
	
	return {
		"id": chain_id,
		"title": "%s Adventure" % theme.capitalize(),
		"theme": theme,
		"primary_objective": objective,
		"objectives": objectives,
		"rewards": rewards,
		"difficulty": "medium",
		"estimated_duration_hours": 2,
		"generation_mode": "procedural"
	}

func _try_safe_fallback_chain(theme: String) -> Dictionary:
	"""
	Generate minimal safe chain as last resort.
	Guaranteed to succeed.
	"""
	var chain_id = "safe_fallback_%d" % Time.get_unix_time_from_system()
	
	return {
		"id": chain_id,
		"title": "Daily Tasks",
		"theme": theme,
		"primary_objective": "harvest",
		"objectives": [
			{
				"type": "harvest",
				"description": "Harvest 5 crops",
				"target_count": 5
			}
		],
		"rewards": {
			"gold": 50,
			"experience": 10,
			"total_value": 60
		},
		"difficulty": "easy",
		"estimated_duration_hours": 1,
		"generation_mode": "safe_fallback"
	}

func _generate_procedural_objectives(primary_type: String) -> Array[Dictionary]:
	"""Generate objectives based on primary type"""
	var objectives: Array[Dictionary] = []
	
	match primary_type:
		"harvest":
			objectives.append({
				"type": "harvest",
				"description": "Harvest crops",
				"target_count": randi_range(5, 15)
			})
		"mine":
			objectives.append({
				"type": "mine",
				"description": "Explore mines",
				"target_floor": randi_range(10, 40)
			})
		"fish":
			objectives.append({
				"type": "fish",
				"description": "Catch fish",
				"target_count": randi_range(3, 10)
			})
		_:
			objectives.append({
				"type": "general",
				"description": "Complete daily tasks",
				"target_count": 5
			})
	
	return objectives

func _generate_procedural_rewards(objective_count: int) -> Dictionary:
	"""Generate balanced rewards"""
	var base_gold = objective_count * 20
	var base_xp = objective_count * 5
	
	return {
		"gold": base_gold,
		"experience": base_xp,
		"items": [],
		"total_value": base_gold + base_xp
	}

func _build_ai_prompt(theme: String, objective: String) -> String:
	"""Build prompt for AI generation"""
	return """
Generate a quest chain with the following parameters:
- Theme: %s
- Primary Objective: %s

Return JSON with: id, title, objectives (array), rewards (dict), difficulty
""" % [theme, objective]

func _parse_ai_response(response: Variant) -> Dictionary:
	"""Parse AI response into chain structure"""
	if response is Dictionary:
		return response
	
	# If string, try to parse as JSON
	if response is String:
		var parsed = JSON.parse_string(response)
		if parsed is Dictionary:
			return parsed
	
	return {}
