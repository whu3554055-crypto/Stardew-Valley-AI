extends Node
## AgenticPerformanceMonitor - Tracks generation performance and manages circuit breaker.
## Monitors success/failure rates and prevents cascading failures.
##
## Responsibilities:
## - Generation statistics tracking
## - Failure rate monitoring
## - Circuit breaker pattern implementation
## - Performance reporting

# === 常量 ===

const MAX_CONSECUTIVE_FAILURES := 5
const BREAKER_REOPEN_DAYS := 2
const STATS_RESET_INTERVAL := 86400  # 24 hours in seconds

# === 成员变量 ===

var _stats: Dictionary = {
	"attempted": 0,
	"published": 0,
	"failed": 0,
	"last_reset": Time.get_unix_time_from_system()
}

var _consecutive_failures: int = 0
var _breaker_state: String = "open"  # open | half_open | closed
var _breaker_last_closed_day: int = -1
var _failure_pressure: Dictionary = {"streak": 0, "last_day": -1}
var _last_block_reason: String = ""

# === 信号 ===

signal success_recorded()
signal failure_recorded(reason: String)
signal breaker_state_changed(old_state: String, new_state: String)
signal stats_updated(stats: Dictionary)

# === 生命周期方法 ===

func _ready() -> void:
	_check_stats_reset()

func _process(_delta: float) -> void:
	# Periodic stats reset check
	_check_stats_reset()

# === 公共方法 ===

## Record a successful generation
func record_success() -> void:
	"""Record successful chain generation"""
	_stats["attempted"] += 1
	_stats["published"] += 1
	_consecutive_failures = 0
	
	# Reset failure pressure
	var today = _get_day_number()
	if _failure_pressure.last_day != today:
		_failure_pressure.streak = 0
		_failure_pressure.last_day = today
	
	# Open breaker if it was closed
	if _breaker_state == "half_open":
		_set_breaker_state("open")
	
	emit_signal("success_recorded")
	_emit_stats_update()

## Record a failed generation
func record_failure(reason: String = "unknown") -> void:
	"""Record failed chain generation"""
	_stats["attempted"] += 1
	_stats["failed"] += 1
	_consecutive_failures += 1
	
	# Update failure pressure
	var today = _get_day_number()
	if _failure_pressure.last_day == today:
		_failure_pressure.streak += 1
	else:
		_failure_pressure.streak = 1
		_failure_pressure.last_day = today
	
	_last_block_reason = reason
	
	# Check if breaker should close
	if _consecutive_failures >= MAX_CONSECUTIVE_FAILURES:
		_set_breaker_state("closed")
	
	emit_signal("failure_recorded", reason)
	_emit_stats_update()

## Check if circuit breaker allows generation
func should_allow_generation() -> bool:
	"""Check if circuit breaker permits generation"""
	_maybe_reopen_breaker()
	return _breaker_state != "closed"

## Get current breaker state
func get_breaker_state() -> String:
	return _breaker_state

## Get performance statistics
func get_stats() -> Dictionary:
	"""Get current performance statistics"""
	var success_rate = 0.0
	if _stats.attempted > 0:
		success_rate = float(_stats.published) / float(_stats.attempted) * 100.0
	
	return {
		"attempted": _stats.attempted,
		"published": _stats.published,
		"failed": _stats.failed,
		"success_rate": success_rate,
		"consecutive_failures": _consecutive_failures,
		"breaker_state": _breaker_state,
		"failure_pressure": _failure_pressure.duplicate()
	}

## Get last block reason
func get_last_block_reason() -> String:
	return _last_block_reason

## Reset statistics (use with caution)
func reset_stats() -> void:
	_stats = {
		"attempted": 0,
		"published": 0,
		"failed": 0,
		"last_reset": Time.get_unix_time_from_system()
	}
	_consecutive_failures = 0
	_set_breaker_state("open")
	_emit_stats_update()

# === 私有方法 ===

func _set_breaker_state(new_state: String) -> void:
	"""Change circuit breaker state"""
	var old_state = _breaker_state
	
	if old_state == new_state:
		return
	
	_breaker_state = new_state
	
	if new_state == "closed":
		_breaker_last_closed_day = _get_day_number()
	
	emit_signal("breaker_state_changed", old_state, new_state)
	
	if OS.is_debug_build():
		print("[AgenticPerformanceMonitor] Breaker: %s -> %s" % [old_state, new_state])

func _maybe_reopen_breaker() -> void:
	"""Check if closed breaker should reopen"""
	if _breaker_state != "closed":
		return
	
	var days_since_closed = _get_day_number() - _breaker_last_closed_day
	
	if days_since_closed >= BREAKER_REOPEN_DAYS:
		_set_breaker_state("half_open")
		
		if OS.is_debug_build():
			print("[AgenticPerformanceMonitor] Breaker half-open after %d days" % days_since_closed)

func _check_stats_reset() -> void:
	"""Reset stats if interval has passed"""
	var now = Time.get_unix_time_from_system()
	var elapsed = now - _stats.last_reset
	
	if elapsed >= STATS_RESET_INTERVAL:
		reset_stats()

func _get_day_number() -> int:
	"""Get current day number for tracking"""
	# Use GameManager if available, otherwise use system time
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_player_data"):
			return gm.player_data.get("day", 1)
	
	# Fallback to Unix day
	return int(Time.get_unix_time_from_system() / 86400)

func _emit_stats_update() -> void:
	"""Emit stats update signal"""
	emit_signal("stats_updated", get_stats())
