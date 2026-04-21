extends Node
## AgenticContentOrchestrator - Main coordinator for agentic content generation.
## Orchestrates chain generation using specialized modules.
##
## This is the refactored version that delegates to:
## - AgenticChainStorage: Storage management
## - AgenticChainValidator: Validation and guardrails
## - AgenticThemeManager: Theme selection
## - AgenticCropCatalog: Crop data
## - AgenticPerformanceMonitor: Performance tracking
## - AgenticFallbackGenerator: Multi-tier generation

# === 常量 ===

const CONFIG_PATH := "user://agentic_content_config.json"

# === 成员变量 ===

var config: Dictionary = {
	"enabled": true,
	"max_runtime_chains": 24,
	"max_generations_per_day": 1,
	"use_ai_first": true,
	"allow_procedural_fallback": true
}

# Module references (injected)
var chain_storage: Node = null
var chain_validator: Node = null
var theme_manager: Node = null
var crop_catalog: Node = null
var performance_monitor: Node = null
var fallback_generator: Node = null

# Internal state
var _last_block_reason: String = ""
var _continuity_hint: String = ""

# === 信号 ===

signal generation_started(reason: String)
signal generation_published(chain_id: String, mode: String)
signal generation_failed(reason: String)
signal generation_degraded(reason: String)
signal runtime_status_updated(snapshot: Dictionary)
signal guardrail_blocked(reason: String, snapshot: Dictionary)

# === 生命周期方法 ===

func _ready() -> void:
	_load_config()
	_initialize_modules()
	_connect_signals()

func _initialize_modules() -> void:
	"""Initialize module references"""
	# Try to get modules from Autoloads
	chain_storage = get_node_or_null("/root/AgenticChainStorage")
	chain_validator = get_node_or_null("/root/AgenticChainValidator")
	theme_manager = get_node_or_null("/root/AgenticThemeManager")
	crop_catalog = get_node_or_null("/root/AgenticCropCatalog")
	performance_monitor = get_node_or_null("/root/AgenticPerformanceMonitor")
	fallback_generator = get_node_or_null("/root/AgenticFallbackGenerator")
	
	# Verify all modules are available
	var missing = []
	if not chain_storage: missing.append("AgenticChainStorage")
	if not chain_validator: missing.append("AgenticChainValidator")
	if not theme_manager: missing.append("AgenticThemeManager")
	if not crop_catalog: missing.append("AgenticCropCatalog")
	if not performance_monitor: missing.append("AgenticPerformanceMonitor")
	if not fallback_generator: missing.append("AgenticFallbackGenerator")
	
	if not missing.is_empty():
		push_error("[AgenticContentOrchestrator] Missing modules: %s" % ", ".join(missing))

func _connect_signals() -> void:
	"""Connect to module signals"""
	if performance_monitor:
		performance_monitor.breaker_state_changed.connect(_on_breaker_state_changed)
	
	if fallback_generator:
		fallback_generator.generation_degraded.connect(_on_generation_degraded)
	
	if chain_validator:
		chain_validator.guardrail_triggered.connect(_on_guardrail_triggered)

# === 公共方法 ===

## Main entry point: generate content for the day
func maybe_generate_for_day(narrative: Dictionary = {}) -> void:
	"""
	Main orchestration method. Coordinates all modules to generate daily content.
	"""
	# Check if enabled
	if not config.enabled:
		return
	
	# Check dependencies
	if not _check_dependencies():
		return
	
	# Check circuit breaker
	if performance_monitor and not performance_monitor.should_allow_generation():
		_emit_runtime_status()
		return
	
	# Check if already generated today
	var today_key = _day_key()
	if _already_generated_today(today_key):
		return
	
	# Compute generation reason
	var reason = _compute_generation_reason(narrative)
	if not reason.get("should_generate", false):
		return
	
	# Check daily limit
	if not _check_daily_limit(today_key):
		return
	
	# Record attempt
	if performance_monitor:
		performance_monitor.record_success()  # Will be adjusted if fails
	
	emit_signal("generation_started", reason.get("reason", "unknown"))
	
	# Try manual chains first
	if _try_manual_chain(today_key):
		return
	
	# Generate via AI or fallback
	await _generate_and_publish_chain(reason, today_key)

## Set continuity hint for next generation
func set_continuity_hint(hint: String) -> void:
	_continuity_hint = hint
	if theme_manager:
		theme_manager.set_continuity_hint(hint)

## Get current status
func get_status() -> Dictionary:
	var status = {
		"enabled": config.enabled,
		"modules_loaded": _check_modules_loaded(),
		"breaker_state": performance_monitor.get_breaker_state() if performance_monitor else "unknown"
	}
	
	if performance_monitor:
		status.merge(performance_monitor.get_stats())
	
	return status

# === 私有方法 ===

func _check_dependencies() -> bool:
	"""Check if required systems are available"""
	if not has_node("/root/QuestSystem"):
		push_warning("[AgenticContentOrchestrator] QuestSystem not available")
		return false
	
	if not has_node("/root/GameManager"):
		push_warning("[AgenticContentOrchestrator] GameManager not available")
		return false
	
	return true

func _check_modules_loaded() -> bool:
	"""Check if all modules are loaded"""
	return (
		chain_storage != null and
		chain_validator != null and
		theme_manager != null and
		crop_catalog != null and
		performance_monitor != null and
		fallback_generator != null
	)

func _already_generated_today(today_key: String) -> bool:
	"""Check if content was already generated today"""
	var gm = get_node("/root/GameManager")
	if not gm or not gm.player_data:
		return false
	
	var generated_key = "agentic_runtime_generated_%s" % today_key
	return bool(gm.player_data.get(generated_key, false))

func _check_daily_limit(today_key: String) -> bool:
	"""Check if daily generation limit reached"""
	var gm = get_node("/root/GameManager")
	if not gm or not gm.player_data:
		return true
	
	var daily_count_key = "agentic_runtime_gen_count_%s" % today_key
	var daily_count = int(gm.player_data.get(daily_count_key, 0))
	var max_per_day = int(config.get("max_generations_per_day", 1))
	
	return daily_count < max_per_day

func _try_manual_chain(today_key: String) -> bool:
	"""Try to use a manual chain from queue"""
	if not chain_storage:
		return false
	
	var manual_chain = chain_storage.take_manual_chain()
	if manual_chain.is_empty():
		return false
	
	# Validate manual chain
	if chain_validator:
		var validation = chain_validator.validate_chain_template(manual_chain)
		if not validation.ok:
			_on_generation_failure("manual_chain_invalid")
			return false
	
	# Register with QuestSystem
	var qs = get_node("/root/QuestSystem")
	var reg_result = qs.register_runtime_chain_template(manual_chain, "manual_override")
	
	if not reg_result.get("ok", false):
		_on_generation_failure("manual_chain_register_failed")
		return false
	
	var chain_id = str(reg_result.get("chain_id", ""))
	if chain_id.is_empty():
		return false
	
	# Track in storage
	if chain_storage:
		chain_storage.add_runtime_chain(chain_id)
	
	# Update game state
	_update_generation_state(today_key, 1)
	
	# Record success
	if performance_monitor:
		performance_monitor.record_success()
	
	emit_signal("generation_published", chain_id, "manual")
	_emit_runtime_status()
	
	return true

func _generate_and_publish_chain(reason: Dictionary, today_key: String) -> void:
	"""Generate chain via AI/fallback and publish"""
	var theme = reason.get("theme", "joyful")
	var objective = reason.get("preferred_objective", "harvest")
	
	# Use theme manager if available
	if theme_manager:
		theme = theme_manager.select_theme(reason)
	
	# Generate chain using fallback generator
	if not fallback_generator:
		_on_generation_failure("fallback_generator_not_available")
		return
	
	var chain_data = await fallback_generator.generate_chain(theme, objective)
	
	if chain_data.is_empty():
		_on_generation_failure("all_generation_methods_failed")
		return
	
	# Validate generated chain
	if chain_validator:
		var validation = chain_validator.validate_chain_template(chain_data)
		if not validation.ok:
			_on_generation_failure("validation_failed: " + str(validation.errors))
			return
	
	# Register with QuestSystem
	var qs = get_node("/root/QuestSystem")
	var mode = chain_data.get("generation_mode", "unknown")
	var reg_result = qs.register_runtime_chain_template(chain_data, "runtime_agentic")
	
	if not reg_result.get("ok", false):
		_on_generation_failure("register_failed: " + str(reg_result.get("error", "")))
		return
	
	var chain_id = str(reg_result.get("chain_id", ""))
	if chain_id.is_empty():
		_on_generation_failure("missing_chain_id")
		return
	
	# Track in storage
	if chain_storage:
		chain_storage.add_runtime_chain(chain_id)
	
	# Update game state
	_update_generation_state(today_key, 1)
	
	# Record success
	if performance_monitor:
		performance_monitor.record_success()
	
	# Record theme usage
	if theme_manager:
		theme_manager.record_theme_usage(theme, true)
	
	emit_signal("generation_published", chain_id, mode)
	_emit_runtime_status()

func _update_generation_state(today_key: String, increment: int) -> void:
	"""Update GameManager state for generation tracking"""
	var gm = get_node("/root/GameManager")
	if not gm or not gm.player_data:
		return
	
	var generated_key = "agentic_runtime_generated_%s" % today_key
	var daily_count_key = "agentic_runtime_gen_count_%s" % today_key
	
	gm.player_data[generated_key] = true
	gm.player_data[daily_count_key] = int(gm.player_data.get(daily_count_key, 0)) + increment

func _on_generation_failure(reason: String) -> void:
	"""Handle generation failure"""
	_last_block_reason = reason
	
	if performance_monitor:
		performance_monitor.record_failure(reason)
	
	emit_signal("generation_failed", reason)
	
	if OS.is_debug_build():
		print("[AgenticContentOrchestrator] Generation failed: %s" % reason)

func _emit_runtime_status() -> void:
	"""Emit runtime status update"""
	var status = get_status()
	emit_signal("runtime_status_updated", status)

func _on_breaker_state_changed(old_state: String, new_state: String) -> void:
	"""Handle circuit breaker state changes"""
	if OS.is_debug_build():
		print("[AgenticContentOrchestrator] Breaker: %s -> %s" % [old_state, new_state])
	
	if new_state == "open":
		_last_block_reason = ""

func _on_generation_degraded(reason: String) -> void:
	"""Relay generation degradation signal"""
	emit_signal("generation_degraded", reason)
	
	if OS.is_debug_build():
		print("[AgenticContentOrchestrator] Generation degraded: %s" % reason)

func _on_guardrail_triggered(chain_id: String, rule: String) -> void:
	"""Handle guardrail trigger and emit compatibility signal"""
	var snapshot = get_status()
	emit_signal("guardrail_blocked", rule, snapshot)
	
	if OS.is_debug_build():
		print("[AgenticContentOrchestrator] Guardrail triggered: %s for chain %s" % [rule, chain_id])

func _compute_generation_reason(narrative: Dictionary) -> Dictionary:
	"""Compute why we should generate content"""
	# Simplified logic - can be enhanced
	return {
		"should_generate": true,
		"reason": "daily_generation",
		"theme": narrative.get("theme", "joyful"),
		"preferred_objective": narrative.get("objective", "harvest")
	}

func _day_key() -> String:
	"""Get current day key"""
	var gm = get_node("/root/GameManager")
	if gm and gm.player_data:
		return "day_%d" % gm.player_data.get("day", 1)
	
	# Fallback to date
	return Time.get_date_string_from_system()

func _load_config() -> void:
	"""Load configuration from file"""
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data is Dictionary:
		config.merge(data)
		
		if OS.is_debug_build():
			print("[AgenticContentOrchestrator] Config loaded")
