extends Node2D
## NPCVisibilityController - Manages NPC update throttling based on screen visibility.
## Automatically pauses processing for off-screen NPCs to improve performance.

@export var npc_parent: Node2D = null
@export var update_when_offscreen: bool = false  # If true, still update but less frequently

var _visibility_notifier: VisibleOnScreenNotifier2D = null
var _was_visible: bool = true
var _offscreen_update_timer: Timer = null

func _ready() -> void:
	_setup_visibility_tracking()

func _setup_visibility_tracking() -> void:
	# Create VisibleOnScreenNotifier2D if not exists
	if not _visibility_notifier:
		_visibility_notifier = VisibleOnScreenNotifier2D.new()
		add_child(_visibility_notifier)
		
		# Connect signals
		_visibility_notifier.screen_entered.connect(_on_screen_entered)
		_visibility_notifier.screen_exited.connect(_on_screen_exited)
	
	# Setup offscreen update timer (for periodic updates when offscreen)
	if not update_when_offscreen:
		return
	
	if not _offscreen_update_timer:
		_offscreen_update_timer = Timer.new()
		_offscreen_update_timer.wait_time = 2.0  # Update every 2 seconds when offscreen
		_offscreen_update_timer.one_shot = false
		_offscreen_update_timer.timeout.connect(_on_offscreen_update)
		add_child(_offscreen_update_timer)

func _on_screen_entered() -> void:
	"""Called when NPC enters the screen"""
	_was_visible = true
	
	# Resume all processing
	if is_inside_tree():
		set_process(true)
		set_physics_process(true)
	
	# Stop offscreen timer
	if _offscreen_update_timer and _offscreen_update_timer.is_stopped() == false:
		_offscreen_update_timer.stop()
	
	# Debug logging (only in debug builds)
	if OS.is_debug_build():
		print("[NPCVisibility] %s is now VISIBLE" % name)

func _on_screen_exited() -> void:
	"""Called when NPC exits the screen"""
	_was_visible = false
	
	if not update_when_offscreen:
		# Pause all processing when offscreen
		if is_inside_tree():
			set_process(false)
			set_physics_process(false)
	else:
		# Start periodic updates when offscreen
		if _offscreen_update_timer:
			_offscreen_update_timer.start()
	
	# Debug logging (only in debug builds)
	if OS.is_debug_build():
		print("[NPCVisibility] %s is now OFFSCREEN" % name)

func _on_offscreen_update() -> void:
	"""Periodic update for offscreen NPCs (if enabled)"""
	if not _was_visible and update_when_offscreen:
		# Perform lightweight update
		_perform_lightweight_update()

func _perform_lightweight_update() -> void:
	"""Perform minimal updates for offscreen NPCs"""
	# Override this method in NPC scripts to handle offscreen updates
	# Examples: advance schedule, update emotion decay, etc.
	pass

func is_currently_visible() -> bool:
	"""Check if NPC is currently visible on screen"""
	if _visibility_notifier:
		return _visibility_notifier.is_on_screen()
	return _was_visible

func get_visibility_status() -> Dictionary:
	"""Get detailed visibility status for debugging"""
	return {
		"name": name,
		"is_visible": is_currently_visible(),
		"was_visible": _was_visible,
		"update_when_offscreen": update_when_offscreen,
		"processing": is_processing() if is_inside_tree() else false
	}
