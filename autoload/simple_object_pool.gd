extends Node
## SimpleObjectPool - Generic object pooling for frequently created/destroyed objects.
## Reduces garbage collection overhead by reusing instances.
##
## Usage:
## ```gdscript
## # Create a pool for a specific scene
## ObjectPool.create_pool("bullet", preload("res://scenes/bullet.tscn"), 20)
##
## # Get an instance from the pool
## var bullet = ObjectPool.get_instance("bullet")
##
## # Return instance to pool when done
## ObjectPool.return_instance("bullet", bullet)
## ```

# === 类型定义 ===

class PoolData:
	var scene: PackedScene
	var available: Array[Node] = []
	var in_use: Array[Node] = []
	var max_size: int = 50
	var auto_expand: bool = true
	
	func _init(p_scene: PackedScene, p_max_size: int = 50):
		scene = p_scene
		max_size = p_max_size

# === 成员变量 ===

var pools: Dictionary = {}  # {pool_name: PoolData}

# === 公共方法 ===

## Create a new object pool
func create_pool(pool_name: String, scene: PackedScene, initial_size: int = 10, max_size: int = 50) -> void:
	if pools.has(pool_name):
		push_warning("[ObjectPool] Pool '%s' already exists" % pool_name)
		return
	
	var pool_data = PoolData.new(scene, max_size)
	pools[pool_name] = pool_data
	
	# Pre-populate pool with instances
	for i in range(initial_size):
		var instance = scene.instantiate()
		instance.set_process(false)
		instance.set_physics_process(false)
		instance.visible = false
		pool_data.available.append(instance)
		add_child(instance)
	
	if OS.is_debug_build():
		print("[ObjectPool] Created pool '%s' with %d instances (max: %d)" % [
			pool_name, initial_size, max_size
		])

## Get an instance from the pool (creates new if empty and auto_expand is true)
func get_instance(pool_name: String) -> Variant:
	if not pools.has(pool_name):
		push_error("[ObjectPool] Pool '%s' does not exist" % pool_name)
		return null
	
	var pool_data: PoolData = pools[pool_name]
	var instance: Node = null
	
	# Try to get from available pool
	if not pool_data.available.is_empty():
		instance = pool_data.available.pop_back()
	else:
		# Auto-expand if enabled and under max size
		if pool_data.auto_expand and pool_data.in_use.size() < pool_data.max_size:
			instance = pool_data.scene.instantiate()
			add_child(instance)
			if OS.is_debug_build():
				print("[ObjectPool] Auto-expanded pool '%s'" % pool_name)
		else:
			push_warning("[ObjectPool] Pool '%s' exhausted (max: %d)" % [pool_name, pool_data.max_size])
			return null
	
	# Configure instance for use
	instance.set_process(true)
	instance.set_physics_process(true)
	instance.visible = true
	pool_data.in_use.append(instance)
	
	return instance

## Return an instance to the pool
func return_instance(pool_name: String, instance: Node) -> void:
	if not pools.has(pool_name):
		push_error("[ObjectPool] Pool '%s' does not exist" % pool_name)
		return
	
	var pool_data: PoolData = pools[pool_name]
	
	# Remove from in_use
	if instance in pool_data.in_use:
		pool_data.in_use.erase(instance)
	else:
		push_warning("[ObjectPool] Instance not found in pool '%s'" % pool_name)
		return
	
	# Reset instance state
	instance.set_process(false)
	instance.set_physics_process(false)
	instance.visible = false
	
	# Add back to available pool
	pool_data.available.append(instance)

## Clear all instances from a pool
func clear_pool(pool_name: String) -> void:
	if not pools.has(pool_name):
		return
	
	var pool_data: PoolData = pools[pool_name]
	
	# Free all instances
	for instance in pool_data.available:
		if is_instance_valid(instance):
			instance.queue_free()
	
	for instance in pool_data.in_use:
		if is_instance_valid(instance):
			instance.queue_free()
	
	pool_data.available.clear()
	pool_data.in_use.clear()
	
	if OS.is_debug_build():
		print("[ObjectPool] Cleared pool '%s'" % pool_name)

## Get pool statistics
func get_pool_stats(pool_name: String) -> Dictionary:
	if not pools.has(pool_name):
		return {}
	
	var pool_data: PoolData = pools[pool_name]
	return {
		"name": pool_name,
		"available": pool_data.available.size(),
		"in_use": pool_data.in_use.size(),
		"total": pool_data.available.size() + pool_data.in_use.size(),
		"max_size": pool_data.max_size,
		"utilization": float(pool_data.in_use.size()) / float(pool_data.max_size) * 100.0
	}

## Get statistics for all pools
func get_all_pool_stats() -> Array[Dictionary]:
	var stats = []
	for pool_name in pools.keys():
		stats.append(get_pool_stats(pool_name))
	return stats

## Clean up inactive instances (call periodically)
func cleanup_inactive_instances(pool_name: String, max_inactive: int = 20) -> void:
	if not pools.has(pool_name):
		return
	
	var pool_data: PoolData = pools[pool_name]
	
	# Only cleanup if we have too many available instances
	while pool_data.available.size() > max_inactive:
		var instance = pool_data.available.pop_back()
		if is_instance_valid(instance):
			instance.queue_free()
	
	if OS.is_debug_build() and pool_data.available.size() < max_inactive:
		print("[ObjectPool] Cleaned up pool '%s', now has %d instances" % [
			pool_name, pool_data.available.size()
		])

# === 生命周期方法 ===

func _exit_tree() -> void:
	# Clean up all pools
	for pool_name in pools.keys():
		clear_pool(pool_name)
