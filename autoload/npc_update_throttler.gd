extends Node
## NPCUpdateThrottler - Intelligent update frequency management for NPCs.
## Reduces CPU usage by updating distant/offscreen NPCs less frequently.
##
## Update priorities:
## - HIGH (0.1s): Player nearby, visible on screen
## - MEDIUM (0.5s): Same zone as player
## - LOW (2.0s): Different zone but not too far
## - IDLE (5.0s): Far away or offscreen

# === 常量 ===

const UPDATE_PRIORITY_HIGH: float = 0.1    # 10 updates/sec (player nearby)
const UPDATE_PRIORITY_MEDIUM: float = 0.5  # 2 updates/sec (same zone)
const UPDATE_PRIORITY_LOW: float = 2.0     # Once every 2 sec (different zone)
const UPDATE_PRIORITY_IDLE: float = 5.0    # Once every 5 sec (off-screen)

const DISTANCE_THRESHOLD_HIGH: float = 300.0   # pixels
const DISTANCE_THRESHOLD_MEDIUM: float = 600.0 # pixels
const DISTANCE_THRESHOLD_LOW: float = 1000.0   # pixels

# === 成员变量 ===

var npc_update_timers: Dictionary = {}  # {npc_id: Timer}
var npc_last_positions: Dictionary = {} # {npc_id: Vector2}
var _player_position: Vector2 = Vector2.ZERO

# === 信号 ===

signal npc_update_priority_changed(npc_id: String, old_priority: float, new_priority: float)

# === 生命周期方法 ===

func _ready() -> void:
	_initialize_throttler()

func _initialize_throttler() -> void:
	"""Initialize the throttler system"""
	if OS.is_debug_build():
		print("[NPCUpdateThrottler] Initialized with distance-based throttling")

# === 公共方法 ===

## Register an NPC for update throttling
func register_npc(npc_id: String, npc_node: Node2D) -> void:
	if npc_update_timers.has(npc_id):
		return
	
	# Create update timer for this NPC
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func(): _update_npc_if_needed(npc_id))
	add_child(timer)
	npc_update_timers[npc_id] = timer
	
	# Store initial position
	if npc_node:
		npc_last_positions[npc_id] = npc_node.global_position
	
	# Start with appropriate priority
	_update_npc_priority(npc_id, npc_node)

## Unregister an NPC from throttling
func unregister_npc(npc_id: String) -> void:
	if npc_update_timers.has(npc_id):
		var timer: Timer = npc_update_timers[npc_id]
		timer.stop()
		timer.queue_free()
		npc_update_timers.erase(npc_id)
		npc_last_positions.erase(npc_id)

## Update player position (call when player moves)
func set_player_position(position: Vector2) -> void:
	_player_position = position
	# Re-evaluate all NPC priorities
	for npc_id in npc_update_timers.keys():
		var npc_node = _get_npc_node(npc_id)
		if npc_node:
			_update_npc_priority(npc_id, npc_node)

## Get current update priority for an NPC
func get_npc_priority(npc_id: String) -> float:
	if not npc_update_timers.has(npc_id):
		return UPDATE_PRIORITY_IDLE
	
	var timer: Timer = npc_update_timers[npc_id]
	return timer.wait_time

## Manually trigger an NPC update (bypass throttling)
func force_update_npc(npc_id: String) -> void:
	_perform_npc_update(npc_id)
	# Restart timer with current priority
	if npc_update_timers.has(npc_id):
		var npc_node = _get_npc_node(npc_id)
		_update_npc_priority(npc_id, npc_node)

# === 私有方法 ===

func _update_npc_priority(npc_id: String, npc_node: Node2D) -> void:
	"""Calculate and set update priority based on distance to player"""
	if not npc_node or not is_instance_valid(npc_node):
		return
	
	var npc_pos: Vector2 = npc_node.global_position
	var distance: float = npc_pos.distance_to(_player_position)
	
	var new_priority: float = UPDATE_PRIORITY_IDLE
	
	if distance < DISTANCE_THRESHOLD_HIGH:
		new_priority = UPDATE_PRIORITY_HIGH
	elif distance < DISTANCE_THRESHOLD_MEDIUM:
		new_priority = UPDATE_PRIORITY_MEDIUM
	elif distance < DISTANCE_THRESHOLD_LOW:
		new_priority = UPDATE_PRIORITY_LOW
	else:
		new_priority = UPDATE_PRIORITY_IDLE
	
	# Check if NPC is visible on screen (if we have visibility controller)
	var visibility_controller = npc_node.get_node_or_null("VisibilityController")
	if visibility_controller and visibility_controller.has_method("is_currently_visible"):
		if not visibility_controller.is_currently_visible():
			# Offscreen NPCs get lower priority
			new_priority = max(new_priority, UPDATE_PRIORITY_LOW)
	
	# Apply new priority if changed
	if npc_update_timers.has(npc_id):
		var timer: Timer = npc_update_timers[npc_id]
		var old_priority: float = timer.wait_time
		
		if abs(old_priority - new_priority) > 0.01:
			timer.wait_time = new_priority
			emit_signal("npc_update_priority_changed", npc_id, old_priority, new_priority)
			
			if OS.is_debug_build():
				print("[NPCUpdateThrottler] %s priority: %.1f -> %.1f (distance: %.0f)" % [
					npc_id, old_priority, new_priority, distance
				])
		
		# Restart timer with new priority
		if timer.is_stopped():
			timer.start(new_priority)

func _update_npc_if_needed(npc_id: String) -> void:
	"""Called by timer - decides whether to update NPC"""
	if not npc_update_timers.has(npc_id):
		return
	
	# Perform the actual update
	_perform_npc_update(npc_id)
	
	# Restart timer with current priority
	var npc_node = _get_npc_node(npc_id)
	if npc_node:
		_update_npc_priority(npc_id, npc_node)

func _perform_npc_update(npc_id: String) -> void:
	"""Perform actual NPC behavior update"""
	# This would integrate with your existing NPC behavior system
	# For now, it's a placeholder that can be connected to your behavior controller
	
	# Example integration points:
	# - Call NPCBehaviorController.update_npc_behavior(npc_id)
	# - Update NPC schedule
	# - Process social interactions
	# - Update emotions/mood
	
	pass

func _get_npc_node(npc_id: String) -> Node2D:
	"""Find NPC node by ID"""
	# Try to find NPC in the scene tree
	var root = get_tree().current_scene
	if root:
		# Search for NPC by name or custom property
		for child in root.get_children():
			if child is Node2D and child.has_meta("npc_id"):
				if child.get_meta("npc_id") == npc_id:
					return child as Node2D
	return null

## Get performance statistics
func get_throttler_stats() -> Dictionary:
	var stats = {
		"total_npcs": npc_update_timers.size(),
		"high_priority": 0,
		"medium_priority": 0,
		"low_priority": 0,
		"idle_priority": 0
	}
	
	for timer in npc_update_timers.values():
		var priority = timer.wait_time
		if priority <= UPDATE_PRIORITY_HIGH + 0.01:
			stats.high_priority += 1
		elif priority <= UPDATE_PRIORITY_MEDIUM + 0.01:
			stats.medium_priority += 1
		elif priority <= UPDATE_PRIORITY_LOW + 0.01:
			stats.low_priority += 1
		else:
			stats.idle_priority += 1
	
	return stats
