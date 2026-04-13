extends CanvasLayer
class_name PerfOverlay

var _label: Label
var _accum: float = 0.0
var _visible_state: bool = true


func _ready() -> void:
	_label = Label.new()
	_label.name = "PerfLabel"
	_label.offset_left = 12.0
	_label.offset_top = 680.0
	_label.offset_right = 520.0
	_label.offset_bottom = 710.0
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)
	_refresh_text()


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.5:
		_accum = 0.0
		_refresh_text()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_perf_hud"):
		_visible_state = not _visible_state
		visible = _visible_state


func _refresh_text() -> void:
	if _label == null:
		return
	var fps: int = int(Engine.get_frames_per_second())
	var nodes: int = get_tree().get_node_count() if get_tree() else 0
	var mem_mb: float = float(OS.get_static_memory_usage()) / 1024.0 / 1024.0
	_label.text = "Perf FPS:%d | Nodes:%d | Mem:%.1fMB | F8 toggle" % [fps, nodes, mem_mb]
