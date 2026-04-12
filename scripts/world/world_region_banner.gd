extends CanvasLayer

## Lightweight region title (F4): fades in, holds, fades out.

@export var title_text: String = "Area"
@export var hold_sec: float = 1.2
@export var fade_sec: float = 0.4


func _ready() -> void:
	layer = 20
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_top = 28.0
	margin.offset_bottom = 72.0
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lab := Label.new()
	lab.text = title_text
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 18)
	panel.add_child(lab)
	margin.add_child(panel)
	add_child(margin)
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 1.0, fade_sec)
	tw.tween_interval(hold_sec)
	tw.tween_property(self, "modulate:a", 0.0, fade_sec)
	tw.finished.connect(queue_free)
