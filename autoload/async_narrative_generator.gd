extends Node
## AsyncNarrativeGenerator - Non-blocking narrative generation system.
## Prevents frame freezes during AI calls by using async/await and background processing.
##
## Features:
## - Queue-based async generation
## - Frame-by-frame processing to maintain 60 FPS
## - Timeout handling and fallback mechanisms
## - Progress tracking and cancellation support

# === 常量 ===

const MAX_QUEUE_SIZE: int = 5
const DEFAULT_TIMEOUT: float = 10.0
const FRAME_YIELD_INTERVAL: int = 3  # Yield every 3 frames

# === 类型定义 ===

class GenerationRequest:
	var request_id: String
	var prompt: String
	var theme: String
	var priority: int = 0  # Higher = process first
	var callback: Callable
	var timestamp: float = 0.0
	var timeout: float = DEFAULT_TIMEOUT
	
	func _init(p_request_id: String, p_prompt: String, p_theme: String, p_callback: Callable, p_priority: int = 0):
		request_id = p_request_id
		prompt = p_prompt
		theme = p_theme
		callback = p_callback
		priority = p_priority
		timestamp = Time.get_unix_time_from_system()

# === 成员变量 ===

var _generation_queue: Array[GenerationRequest] = []
var _is_processing: bool = false
var _current_request: GenerationRequest = null
var _frame_counter: int = 0
var _total_generated: int = 0
var _total_failed: int = 0
var _average_generation_time: float = 0.0

# === 信号 ===

signal generation_started(request_id: String, theme: String)
signal generation_completed(request_id: String, result: Dictionary)
signal generation_failed(request_id: String, error: String)
signal generation_cancelled(request_id: String)
signal queue_status_updated(queue_size: int, is_processing: bool)

# === 生命周期方法 ===

func _ready() -> void:
	if OS.is_debug_build():
		print("[AsyncNarrativeGenerator] Initialized")

func _process(_delta: float) -> void:
	_process_queue()

# === 公共方法 ===

## Submit a narrative generation request (non-blocking)
func submit_generation(prompt: String, theme: String, callback: Callable, priority: int = 0) -> String:
	if _generation_queue.size() >= MAX_QUEUE_SIZE:
		push_warning("[AsyncNarrativeGenerator] Queue full (%d/%d)" % [_generation_queue.size(), MAX_QUEUE_SIZE])
		return ""
	
	var request_id = "narrative_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]
	var request = GenerationRequest.new(request_id, prompt, theme, callback, priority)
	
	_generation_queue.append(request)
	_generation_queue.sort_custom(func(a, b): return a.priority > b.priority)
	
	emit_signal("queue_status_updated", _generation_queue.size(), _is_processing)
	
	if OS.is_debug_build():
		print("[AsyncNarrativeGenerator] Queued: %s (theme: %s, priority: %d)" % [request_id, theme, priority])
	
	return request_id

## Cancel a pending generation request
func cancel_generation(request_id: String) -> bool:
	for i in range(_generation_queue.size()):
		if _generation_queue[i].request_id == request_id:
			var cancelled = _generation_queue.pop_at(i)
			emit_signal("generation_cancelled", request_id)
			emit_signal("queue_status_updated", _generation_queue.size(), _is_processing)
			
			if OS.is_debug_build():
				print("[AsyncNarrativeGenerator] Cancelled: %s" % request_id)
			
			return true
	
	# Check if currently processing
	if _current_request and _current_request.request_id == request_id:
		_current_request = null
		_is_processing = false
		emit_signal("generation_cancelled", request_id)
		return true
	
	return false

## Get current queue status
func get_queue_status() -> Dictionary:
	return {
		"queue_size": _generation_queue.size(),
		"is_processing": _is_processing,
		"current_request": _current_request.request_id if _current_request else "",
		"total_generated": _total_generated,
		"total_failed": _total_failed,
		"average_time": _average_generation_time
	}

## Clear all pending requests
func clear_queue() -> void:
	_generation_queue.clear()
	_current_request = null
	_is_processing = false
	emit_signal("queue_status_updated", 0, false)
	
	if OS.is_debug_build():
		print("[AsyncNarrativeGenerator] Queue cleared")

# === 私有方法 ===

func _process_queue() -> void:
	"""Process generation queue in background"""
	if _is_processing:
		return
	
	if _generation_queue.is_empty():
		return
	
	# Dequeue next request
	_current_request = _generation_queue.pop_front()
	_is_processing = true
	
	emit_signal("queue_status_updated", _generation_queue.size(), _is_processing)
	emit_signal("generation_started", _current_request.request_id, _current_request.theme)
	
	# Start async generation
	_generate_narrative_async(_current_request)

func _generate_narrative_async(request: GenerationRequest) -> void:
	"""Generate narrative asynchronously with frame yielding"""
	var start_time = Time.get_unix_time_from_system()
	
	# Simulate async generation (replace with actual AI call)
	var result = await _perform_generation_with_yielding(request.prompt, request.theme, request.timeout)
	
	var elapsed = Time.get_unix_time_from_system() - start_time
	_update_average_time(elapsed)
	
	if result.success:
		_total_generated += 1
		
		# Call callback with result
		if request.callback.is_valid():
			request.callback.call(result.data)
		
		emit_signal("generation_completed", request.request_id, result.data)
		
		if OS.is_debug_build():
			print("[AsyncNarrativeGenerator] Completed: %s (%.2fs)" % [request.request_id, elapsed])
	else:
		_total_failed += 1
		
		# Call callback with error
		if request.callback.is_valid():
			request.callback.call({"error": result.error})
		
		emit_signal("generation_failed", request.request_id, result.error)
		
		if OS.is_debug_build():
			print("[AsyncNarrativeGenerator] Failed: %s - %s" % [request.request_id, result.error])
	
	# Reset state
	_current_request = null
	_is_processing = false
	
	# Process next item in queue
	emit_signal("queue_status_updated", _generation_queue.size(), _is_processing)

func _perform_generation_with_yielding(prompt: String, theme: String, timeout: float) -> Dictionary:
	"""Perform generation with frame yielding to maintain smooth FPS"""
	var elapsed = 0.0
	var start_time = Time.get_unix_time_from_system()
	
	_frame_counter = 0
	
	# Step 1: Prepare context (yield between steps)
	await _yield_if_needed()
	var context = _prepare_generation_context(prompt, theme)
	
	# Step 2: Call AI API (this is where you'd make the actual API call)
	await _yield_if_needed()
	var ai_result = await _call_ai_api_async(context, timeout)
	
	if not ai_result.success:
		return {"success": false, "error": ai_result.error}
	
	# Step 3: Process result
	await _yield_if_needed()
	var processed = _process_ai_response(ai_result.data, theme)
	
	# Step 4: Validate and finalize
	await _yield_if_needed()
	var validated = _validate_narrative(processed)
	
	elapsed = Time.get_unix_time_from_system() - start_time
	
	if elapsed > timeout:
		return {"success": false, "error": "Generation timeout (%.1fs)" % timeout}
	
	return {"success": true, "data": validated}

func _yield_if_needed() -> void:
	"""Yield control to maintain smooth FPS"""
	_frame_counter += 1
	
	if _frame_counter >= FRAME_YIELD_INTERVAL:
		_frame_counter = 0
		await get_tree().process_frame

func _call_ai_api_async(context: Dictionary, timeout: float) -> Dictionary:
	"""Call AI API with timeout handling"""
	# This is a placeholder - replace with your actual AI API call
	# Example integration with AdvancedAIAgentManager or similar
	
	# For now, simulate with a delay
	await get_tree().create_timer(0.5).timeout
	
	# Return mock result (replace with actual API call)
	return {
		"success": true,
		"data": {
			"title": "Sample Narrative",
			"content": "This is a sample narrative generated asynchronously.",
			"theme": context.get("theme", "default"),
			"cast": [],
			"scenes": []
		}
	}

func _prepare_generation_context(prompt: String, theme: String) -> Dictionary:
	"""Prepare context for generation"""
	return {
		"prompt": prompt,
		"theme": theme,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": _get_current_game_state()
	}

func _process_ai_response(raw_data: Dictionary, theme: String) -> Dictionary:
	"""Process and structure AI response"""
	# Add theme-specific metadata
	raw_data["theme"] = theme
	raw_data["generated_at"] = Time.get_unix_time_from_system()
	
	return raw_data

func _validate_narrative(narrative: Dictionary) -> Dictionary:
	"""Validate narrative structure and content"""
	var required_fields = ["title", "content", "theme"]
	
	for field in required_fields:
		if not narrative.has(field):
			push_warning("[AsyncNarrativeGenerator] Missing field: %s" % field)
			narrative[field] = ""
	
	return narrative

func _get_current_game_state() -> Dictionary:
	"""Get current game state for context"""
	var state = {
		"day": 1,
		"season": "spring",
		"time": 8.0,
		"weather": "sunny"
	}
	
	# Integrate with GameManager if available
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_player_data"):
			state.day = gm.player_data.get("day", 1)
	
	return state

func _update_average_time(new_time: float) -> void:
	"""Update running average of generation time"""
	if _average_generation_time == 0.0:
		_average_generation_time = new_time
	else:
		_average_generation_time = (_average_generation_time * 0.9) + (new_time * 0.1)
