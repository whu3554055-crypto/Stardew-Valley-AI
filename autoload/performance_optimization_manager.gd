extends Node
## PerformanceOptimizationManager - Central manager for all performance optimizations.
## Coordinates NPC throttling, object pooling, and other optimizations.
##
## This is a convenience layer that integrates various optimization systems.

# === 成员变量 ===

var _throttler_enabled: bool = true
var _pooling_enabled: bool = true

# === 信号 ===

signal optimization_applied(type: String, details: Dictionary)

# === 生命周期方法 ===

func _ready() -> void:
	_initialize_optimizations()

func _initialize_optimizations() -> void:
	"""Initialize all performance optimization systems"""
	if OS.is_debug_build():
		print("[PerfOptManager] Initializing performance optimizations...")
	
	# Setup NPC update throttler integration
	if _throttler_enabled and has_node("/root/NPCUpdateThrottler"):
		_setup_npc_throttling()
	
	# Setup object pool templates (common use cases)
	if _pooling_enabled and has_node("/root/SimpleObjectPool"):
		_setup_object_pools()
	
	if OS.is_debug_build():
		print("[PerfOptManager] Performance optimizations initialized")

# === 公共方法 ===

## Enable/disable NPC throttling
func set_npc_throttling(enabled: bool) -> void:
	_throttler_enabled = enabled
	if OS.is_debug_build():
		print("[PerfOptManager] NPC throttling %s" % ("enabled" if enabled else "disabled"))

## Enable/disable object pooling
func set_object_pooling(enabled: bool) -> void:
	_pooling_enabled = enabled
	if OS.is_debug_build():
		print("[PerfOptManager] Object pooling %s" % ("enabled" if enabled else "disabled"))

## Register an NPC for automatic throttling
func register_npc_for_throttling(npc_id: String, npc_node: Node2D) -> void:
	if not _throttler_enabled:
		return
	
	var throttler = get_node_or_null("/root/NPCUpdateThrottler")
	if throttler and throttler.has_method("register_npc"):
		throttler.register_npc(npc_id, npc_node)
		
		emit_signal("optimization_applied", "npc_throttling", {
			"npc_id": npc_id,
			"node": npc_node
		})

## Unregister NPC from throttling
func unregister_npc_from_throttling(npc_id: String) -> void:
	var throttler = get_node_or_null("/root/NPCUpdateThrottler")
	if throttler and throttler.has_method("unregister_npc"):
		throttler.unregister_npc(npc_id)

## Create an object pool for a specific scene type
func create_pool(pool_name: String, scene: PackedScene, initial_size: int = 10, max_size: int = 50) -> void:
	if not _pooling_enabled:
		return
	
	var pool_manager = get_node_or_null("/root/SimpleObjectPool")
	if pool_manager and pool_manager.has_method("create_pool"):
		pool_manager.create_pool(pool_name, scene, initial_size, max_size)
		
		emit_signal("optimization_applied", "object_pool", {
			"pool_name": pool_name,
			"initial_size": initial_size,
			"max_size": max_size
		})

## Get an instance from object pool
func get_pooled_instance(pool_name: String) -> Variant:
	if not _pooling_enabled:
		return null
	
	var pool_manager = get_node_or_null("/root/SimpleObjectPool")
	if pool_manager and pool_manager.has_method("get_instance"):
		return pool_manager.get_instance(pool_name)
	return null

## Return instance to object pool
func return_pooled_instance(pool_name: String, instance: Node) -> void:
	if not _pooling_enabled:
		return
	
	var pool_manager = get_node_or_null("/root/SimpleObjectPool")
	if pool_manager and pool_manager.has_method("return_instance"):
		pool_manager.return_instance(pool_name, instance)

## Update player position for distance-based throttling
func update_player_position(position: Vector2) -> void:
	if not _throttler_enabled:
		return
	
	var throttler = get_node_or_null("/root/NPCUpdateThrottler")
	if throttler and throttler.has_method("set_player_position"):
		throttler.set_player_position(position)

## Get comprehensive performance statistics
func get_performance_stats() -> Dictionary:
	var stats = {
		"npc_throttling": {},
		"object_pools": [],
		"overall": {}
	}
	
	# Get NPC throttler stats
	var throttler = get_node_or_null("/root/NPCUpdateThrottler")
	if throttler and throttler.has_method("get_throttler_stats"):
		stats.npc_throttling = throttler.get_throttler_stats()
	
	# Get object pool stats
	var pool_manager = get_node_or_null("/root/SimpleObjectPool")
	if pool_manager and pool_manager.has_method("get_all_pool_stats"):
		stats.object_pools = pool_manager.get_all_pool_stats()
	
	# Calculate overall metrics
	var total_npcs = stats.npc_throttling.get("total_npcs", 0)
	var high_priority_npcs = stats.npc_throttling.get("high_priority", 0)
	var idle_npcs = stats.npc_throttling.get("idle_priority", 0)
	
	stats.overall = {
		"total_npcs_tracked": total_npcs,
		"active_updates_per_sec": calculate_update_rate(stats.npc_throttling),
		"estimated_cpu_savings": estimate_cpu_savings(total_npcs, high_priority_npcs, idle_npcs),
		"pools_active": stats.object_pools.size(),
		"total_pooled_objects": sum_pooled_objects(stats.object_pools)
	}
	
	return stats

# === 私有方法 ===

func _setup_npc_throttling() -> void:
	"""Setup NPC throttling integration"""
	# Connect to player movement signals if available
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_signal("player_moved"):
		main_scene.player_moved.connect(update_player_position)

func _setup_object_pools() -> void:
	"""Setup common object pools"""
	# Example pools that might be useful:
	# - Particle effects
	# - Temporary UI elements
	# - Projectile/bullet objects
	# - Floating text
	
	# These would be created on-demand by game systems
	pass

func calculate_update_rate(throttler_stats: Dictionary) -> float:
	"""Calculate estimated updates per second based on priority distribution"""
	if throttler_stats.is_empty():
		return 0.0
	
	var rate = 0.0
	rate += throttler_stats.get("high_priority", 0) * 10.0   # 10/sec
	rate += throttler_stats.get("medium_priority", 0) * 2.0  # 2/sec
	rate += throttler_stats.get("low_priority", 0) * 0.5     # 0.5/sec
	rate += throttler_stats.get("idle_priority", 0) * 0.2    # 0.2/sec
	
	return rate

func estimate_cpu_savings(total: int, high: int, idle: int) -> float:
	"""Estimate CPU savings percentage from throttling"""
	if total == 0:
		return 0.0
	
	# Without throttling: all NPCs update at 10/sec
	var baseline_updates = total * 10.0
	
	# With throttling: mixed update rates
	var optimized_updates = calculate_update_rate({
		"high_priority": high,
		"idle_priority": idle,
		"total_npcs": total
	})
	
	if baseline_updates == 0:
		return 0.0
	
	var savings = (1.0 - optimized_updates / baseline_updates) * 100.0
	return clamp(savings, 0.0, 90.0)

func sum_pooled_objects(pool_stats: Array[Dictionary]) -> int:
	"""Sum total pooled objects across all pools"""
	var total = 0
	for stats in pool_stats:
		total += stats.get("total", 0)
	return total
