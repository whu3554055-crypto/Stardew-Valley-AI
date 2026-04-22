extends Node
## AIContentCache - Intelligent caching system for AI-generated content.
## Reduces redundant AI calls by caching results with TTL and invalidation strategies.
##
## Features:
## - Multi-level caching (memory + optional disk)
## - TTL-based expiration
## - Smart invalidation (time-based, event-based)
## - Cache statistics and monitoring
## - Memory usage management

# === 类型定义 ===

class CacheEntry:
	var key: String
	var data: Variant
	var created_at: float = 0.0
	var expires_at: float = 0.0
	var access_count: int = 0
	var last_accessed: float = 0.0
	var size_bytes: int = 0
	
	func _init(p_key: String, p_data: Variant, ttl_seconds: float):
		key = p_key
		data = p_data
		created_at = Time.get_unix_time_from_system()
		expires_at = created_at + ttl_seconds
		access_count = 1
		last_accessed = created_at
		size_bytes = _estimate_size(p_data)
	
	func is_expired() -> bool:
		return Time.get_unix_time_from_system() > expires_at
	
	func touch():
		access_count += 1
		last_accessed = Time.get_unix_time_from_system()
	
	static func _estimate_size(data: Variant) -> int:
		"""Rough estimate of data size in bytes"""
		if data is String:
			return data.length() * 2  # UTF-8 approximation
		elif data is Dictionary:
			var size = 0
			for k in data.keys():
				size += str(k).length() * 2
				size += _estimate_size(data[k])
			return size
		elif data is Array:
			var size = 0
			for item in data:
				size += _estimate_size(item)
			return size
		else:
			return 64  # Default estimate

# === 常量 ===

const DEFAULT_TTL: float = 3600.0  # 1 hour
const MAX_CACHE_SIZE_MB: float = 50.0  # 50 MB max
const CLEANUP_THRESHOLD: float = 0.8  # Cleanup at 80% capacity
const STATS_UPDATE_INTERVAL: float = 60.0  # Update stats every 60 seconds

# === 成员变量 ===

var cache: Dictionary = {}  # {key: CacheEntry}
var total_hits: int = 0
var total_misses: int = 0
var total_evictions: int = 0
var current_size_bytes: int = 0
var _last_stats_update: float = 0.0

# === 信号 ===

signal cache_hit(key: String, entry: CacheEntry)
signal cache_miss(key: String)
signal cache_eviction(key: String, reason: String)
signal cache_cleared()

# === 生命周期方法 ===

func _ready() -> void:
	_last_stats_update = Time.get_unix_time_from_system()
	
	if OS.is_debug_build():
		print("[AIContentCache] Initialized with %.1f MB limit" % (MAX_CACHE_SIZE_MB))

func _process(_delta: float) -> void:
	# Periodic cleanup and stats update
	var now = Time.get_unix_time_from_system()
	
	if now - _last_stats_update >= STATS_UPDATE_INTERVAL:
		_cleanup_expired()
		_check_memory_limit()
		_last_stats_update = now

# === 公共方法 ===

## Get cached content (returns null if not found or expired)
func get_cached(key: String) -> Variant:
	if not cache.has(key):
		total_misses += 1
		emit_signal("cache_miss", key)
		return null
	
	var entry: CacheEntry = cache[key]
	
	# Check expiration
	if entry.is_expired():
		_evict_entry(key, "expired")
		total_misses += 1
		emit_signal("cache_miss", key)
		return null
	
	# Cache hit
	entry.touch()
	total_hits += 1
	current_size_bytes = max(0, current_size_bytes - entry.size_bytes)
	entry.size_bytes = CacheEntry._estimate_size(entry.data)
	current_size_bytes += entry.size_bytes
	
	emit_signal("cache_hit", key, entry)
	
	return entry.data

## Store content in cache with optional TTL
func set_cached(key: String, data: Variant, ttl_seconds: float = DEFAULT_TTL) -> void:
	# Remove existing entry if present
	if cache.has(key):
		_evict_entry(key, "replaced")
	
	# Create new entry
	var entry = CacheEntry.new(key, data, ttl_seconds)
	cache[key] = entry
	current_size_bytes += entry.size_bytes
	
	# Check memory limit
	_check_memory_limit()
	
	if OS.is_debug_build():
		print("[AIContentCache] Cached: %s (%.1f KB, TTL: %.0fs)" % [
			key, entry.size_bytes / 1024.0, ttl_seconds
		])

## Check if key exists and is valid
func has_cached(key: String) -> bool:
	if not cache.has(key):
		return false
	
	var entry: CacheEntry = cache[key]
	if entry.is_expired():
		_evict_entry(key, "expired")
		return false
	
	return true

## Remove specific entry from cache
func remove_cached(key: String) -> bool:
	if cache.has(key):
		_evict_entry(key, "manual_removal")
		return true
	return false

## Clear entire cache
func clear() -> void:
	var keys = cache.keys()
	for key in keys:
		_evict_entry(key, "clear_all")
	
	cache.clear()
	current_size_bytes = 0
	emit_signal("cache_cleared")
	
	if OS.is_debug_build():
		print("[AIContentCache] Cache cleared")

## Get cache statistics
func get_stats() -> Dictionary:
	var hit_rate = 0.0
	var total_requests = total_hits + total_misses
	if total_requests > 0:
		hit_rate = float(total_hits) / float(total_requests) * 100.0
	
	return {
		"total_entries": cache.size(),
		"current_size_mb": current_size_bytes / (1024.0 * 1024.0),
		"max_size_mb": MAX_CACHE_SIZE_MB,
		"utilization_percent": (current_size_bytes / (MAX_CACHE_SIZE_MB * 1024.0 * 1024.0)) * 100.0,
		"total_hits": total_hits,
		"total_misses": total_misses,
		"total_evictions": total_evictions,
		"hit_rate_percent": hit_rate,
		"average_entry_size_kb": (current_size_bytes / max(1, cache.size())) / 1024.0
	}

## Get all keys in cache
func get_keys() -> Array[String]:
	return cache.keys()

## Pre-warm cache with common content
func prewarm(common_keys: Array[String], fetch_func: Callable) -> void:
	for key in common_keys:
		if not has_cached(key):
			var data = fetch_func.call(key)
			if data != null:
				set_cached(key, data)
	
	if OS.is_debug_build():
		print("[AIContentCache] Pre-warmed with %d entries" % common_keys.size())

# === 私有方法 ===

func _evict_entry(key: String, reason: String) -> void:
	"""Remove entry from cache"""
	if cache.has(key):
		var entry: CacheEntry = cache[key]
		current_size_bytes -= entry.size_bytes
		cache.erase(key)
		total_evictions += 1
		
		emit_signal("cache_eviction", key, reason)

func _cleanup_expired() -> void:
	"""Remove all expired entries"""
	var expired_keys = []
	
	for key in cache.keys():
		var entry: CacheEntry = cache[key]
		if entry.is_expired():
			expired_keys.append(key)
	
	for key in expired_keys:
		_evict_entry(key, "expired_cleanup")
	
	if OS.is_debug_build() and not expired_keys.is_empty():
		print("[AIContentCache] Cleaned up %d expired entries" % expired_keys.size())

func _check_memory_limit() -> void:
	"""Enforce memory limit by evicting least recently used entries"""
	var max_bytes = MAX_CACHE_SIZE_MB * 1024.0 * 1024.0
	
	if current_size_bytes <= max_bytes * CLEANUP_THRESHOLD:
		return  # Under threshold
	
	# Sort by last accessed (LRU)
	var sorted_entries = cache.values()
	sorted_entries.sort_custom(func(a, b): return a.last_accessed < b.last_accessed)
	
	# Evict until under threshold
	for entry in sorted_entries:
		if current_size_bytes <= max_bytes * 0.7:  # Target 70%
			break
		
		_evict_entry(entry.key, "memory_limit")
	
	if OS.is_debug_build():
		print("[AIContentCache] Memory cleanup: %.1f MB -> %.1f MB" % [
			max_bytes / (1024.0 * 1024.0),
			current_size_bytes / (1024.0 * 1024.0)
		])

## Generate cache key from parameters
static func generate_key(prefix: String, params: Dictionary) -> String:
	var key_str = prefix
	for param_key in params.keys():
		key_str += "_%s=%s" % [param_key, str(params[param_key])]
	return key_str.md5_text()  # Use hash to keep keys short
