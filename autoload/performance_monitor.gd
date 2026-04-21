extends Node
## Performance monitoring and debugging tool
## Displays real-time metrics and generates optimization reports

var frame_times = []
var fps_history = []
var memory_samples = []
var show_debug_overlay = false
var debug_label: Label

# Performance thresholds
const WARN_FPS = 45.0
const CRITICAL_FPS = 30.0
const WARN_MEMORY_MB = 400
const CRITICAL_MEMORY_MB = 600

func _ready():
    # Create debug overlay UI
    create_debug_overlay()

    # Monitor performance every second
    var monitor_timer = Timer.new()
    monitor_timer.wait_time = 1.0
    monitor_timer.timeout.connect(take_performance_sample)
    add_child(monitor_timer)
    monitor_timer.start()

func create_debug_overlay():
	# Create on-screen debug display
	var canvas = CanvasLayer.new()
    add_child(canvas)

    debug_label = Label.new()
    debug_label.position = Vector2(10, 10)
    debug_label.add_theme_color_override("font_color", Color.YELLOW)
    debug_label.add_theme_font_size_override("font_size", 14)
    canvas.add_child(debug_label)

    # Toggle with F3 key
    InputMap.add_action("toggle_debug")
    var key_event = InputEventKey.new()
    key_event.keycode = KEY_F3
    InputMap.action_add_event("toggle_debug", key_event)

func _input(event):
    if event.is_action_pressed("toggle_debug"):
        toggle_debug_overlay()

func toggle_debug_overlay():
    show_debug_overlay = not show_debug_overlay
    debug_label.visible = show_debug_overlay

func take_performance_sample():
	# Record current performance metrics
	var current_fps = Engine.get_frames_per_second()
    var current_memory = OS.get_static_memory_usage() / 1_000_000.0  # Convert to MB

    fps_history.append(current_fps)
    memory_samples.append(current_memory)

    # Keep only last 60 samples (1 minute)
    if fps_history.size() > 60:
        fps_history.pop_front()
        memory_samples.pop_front()

    # Check for warnings
    check_performance_warnings(current_fps, current_memory)

    # Update debug display
    if show_debug_overlay:
        update_debug_overlay()

func update_debug_overlay():
	# Update on-screen debug information
	var avg_fps = get_average_fps()
    var current_memory = get_memory_usage_mb()
    var peak_memory = get_peak_memory_mb()

    var status_color = get_status_color(avg_fps, current_memory)

    var info_text = "[color=%s]=== PERFORMANCE MONITOR ===[/color]\n" % status_color
    info_text += "FPS: %.1f (avg: %.1f)\n" % [Engine.get_frames_per_second(), avg_fps]
    info_text += "Memory: %.1f MB (peak: %.1f MB)\n" % [current_memory, peak_memory]
    info_text += "Active NPCs: %d\n" % get_active_npc_count()
    info_text += "AI Cache Size: %d\n" % get_cache_size()
    info_text += "Rendered Chunks: %d\n" % get_rendered_chunks()
    info_text += "\n[color=cyan]System Info:[/color]\n"
    info_text += "GPU: %s\n" % RenderingServer.get_video_adapter_name().substr(0, 30)
    info_text += "VRAM: %d MB\n" % RenderingServer.get_video_adapter_vram_mb()
    info_text += "CPU Cores: %d\n" % OS.get_processor_count()

    debug_label.text = info_text

func check_performance_warnings(fps: float, memory_mb: float):
	# Log warnings when performance drops below thresholds
	if fps < CRITICAL_FPS:
        push_error("CRITICAL: FPS dropped to %.1f (threshold: %d)" % [fps, CRITICAL_FPS])
    elif fps < WARN_FPS:
        push_warning("WARNING: FPS low at %.1f (threshold: %d)" % [fps, WARN_FPS])

    if memory_mb > CRITICAL_MEMORY_MB:
        push_error("CRITICAL: Memory usage %.1f MB exceeds limit (%d MB)" % [memory_mb, CRITICAL_MEMORY_MB])
    elif memory_mb > WARN_MEMORY_MB:
        push_warning("WARNING: Memory usage high at %.1f MB" % memory_mb)

func get_status_color(fps: float, memory_mb: float) -> String:
	# Get color code based on performance status
	if fps < CRITICAL_FPS or memory_mb > CRITICAL_MEMORY_MB:
        return "red"
    elif fps < WARN_FPS or memory_mb > WARN_MEMORY_MB:
        return "yellow"
    else:
        return "lime"

func get_average_fps() -> float:
	# Calculate average FPS over last minute
	if fps_history.is_empty():
        return 0.0
    return fps_history.reduce(func(a, b): return a + b, 0.0) / fps_history.size()

func get_memory_usage_mb() -> float:
	# Get current memory usage in MB
	return OS.get_static_memory_usage() / 1_000_000.0

func get_peak_memory_mb() -> float:
	# Get peak memory usage from samples
	if memory_samples.is_empty():
        return 0.0
    return memory_samples.max()

func get_active_npc_count() -> int:
	# Get number of currently active NPCs
	if Engine.has_singleton("NPCBehaviorController"):
        return NPCBehaviorController.active_npcs.size()
    return 0

func get_cache_size() -> int:
	# Get AI response cache size
	if Engine.has_singleton("AIAgentManager"):
        return AIAgentManager.response_cache.size()
    return 0

func get_rendered_chunks() -> int:
	# Get number of currently rendered tilemap chunks
	if Engine.has_singleton("GameTilemap") and GameTilemap.has_method("get_visible_chunk_count"):
        return GameTilemap.get_visible_chunk_count()
    return 0

func generate_performance_report() -> Dictionary:
	# Generate comprehensive performance report for debugging
	return {
        "fps": {
            "current": Engine.get_frames_per_second(),
            "average": get_average_fps(),
            "min": fps_history.min() if fps_history else 0,
            "max": fps_history.max() if fps_history else 0
        },
        "memory": {
            "current_mb": get_memory_usage_mb(),
            "peak_mb": get_peak_memory_mb(),
            "static_mb": OS.get_static_memory_usage() / 1_000_000.0,
            "heap_mb": OS.get_heap_size() / 1_000_000.0
        },
        "game_state": {
            "active_npcs": get_active_npc_count(),
            "ai_cache_size": get_cache_size(),
            "rendered_chunks": get_rendered_chunks(),
            "current_day": GameManager.current_day if Engine.has_singleton("GameManager") else 0
        },
        "hardware": {
            "gpu": RenderingServer.get_video_adapter_name(),
            "vram_mb": RenderingServer.get_video_adapter_vram_mb(),
            "cpu_cores": OS.get_processor_count(),
            "os": OS.get_name()
        }
    }

func print_performance_report():
	# Print formatted performance report to console
	var report = generate_performance_report()

    print("\n" + "=".repeat(50))
    print("PERFORMANCE REPORT")
    print("=".repeat(50))
    print("FPS: %.1f (avg) | %d (current)" % [report.fps.average, report.fps.current])
    print("Memory: %.1f MB (current) | %.1f MB (peak)" % [report.memory.current_mb, report.memory.peak_mb])
    print("Active NPCs: %d" % report.game_state.active_npcs)
    print("AI Cache: %d entries" % report.game_state.ai_cache_size)
    print("Rendered Chunks: %d" % report.game_state.rendered_chunks)
    print("GPU: %s (%d MB VRAM)" % [report.hardware.gpu, report.hardware.vram_mb])
    print("=".repeat(50) + "\n")

func export_performance_report(filepath: String = "user://performance_report.json"):
	# Export performance report to JSON file
	var report = generate_performance_report()
    var json_string = JSON.stringify(report, "  ")

    var file = FileAccess.open(filepath, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        print("Performance report exported to: " + filepath)
    else:
        push_error("Failed to export performance report")

# Utility: Benchmark specific operations
func benchmark_operation(operation_name: String, callable: Callable) -> float:
	# Measure execution time of an operation
	var start_time = Time.get_ticks_msec()

    callable.call()

    var elapsed = Time.get_ticks_msec() - start_time
    print("[BENCHMARK] %s took %d ms" % [operation_name, elapsed])

    return elapsed

# Utility: Monitor specific metric over time
func monitor_metric(metric_name: String, duration_seconds: float = 10.0, sample_interval: float = 0.1):
	# Monitor a metric over time and print statistics
	var samples = []
    var elapsed = 0.0

    print("[MONITOR] Tracking %s for %.1f seconds..." % [metric_name, duration_seconds])

    while elapsed < duration_seconds:
        var value = 0.0

        # Sample different metrics based on name
        match metric_name.to_lower():
            "fps":
                value = Engine.get_frames_per_second()
            "memory":
                value = get_memory_usage_mb()
            "npc_count":
                value = get_active_npc_count()

        samples.append(value)
        await get_tree().create_timer(sample_interval).timeout
        elapsed += sample_interval

    # Print statistics
    if samples:
        var avg = samples.reduce(func(a, b): return a + b, 0.0) / samples.size()
        var min_val = samples.min()
        var max_val = samples.max()

        print("[MONITOR] %s - Avg: %.2f | Min: %.2f | Max: %.2f" % [metric_name, avg, min_val, max_val])

    return samples
