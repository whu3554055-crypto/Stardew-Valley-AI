extends CanvasLayer

class_name DayNightCycle

@export var night_color = Color(0.1, 0.1, 0.3, 0.7)
@export var dusk_color = Color(0.8, 0.5, 0.2, 0.4)
@export var dawn_color = Color(1.0, 0.7, 0.4, 0.3)

@onready var color_rect = $ColorRect

var current_alpha = 0.0
var target_color = Color.TRANSPARENT

func _ready():
	color_rect.color = Color.TRANSPARENT
	GameManager.time_changed.connect(_on_time_changed)

func _on_time_changed(new_time: float):
	# Update overlay based on time of day
	var hour = int(new_time)

	if hour >= 6 and hour < 18:
		# Daytime - clear sky
		target_color = Color.TRANSPARENT
	elif hour >= 18 and hour < 20:
		# Dusk
		var progress = (new_time - 18) / 2.0
		target_color = dusk_color.lerp(night_color, progress)
	elif hour >= 20 or hour < 5:
		# Night
		target_color = night_color
	elif hour >= 5 and hour < 6:
		# Dawn
		var progress = (new_time - 5) / 1.0
		target_color = night_color.lerp(dawn_color, progress).lerp(Color.TRANSPARENT, progress)

	# Smooth transition
	color_rect.color = color_rect.color.lerp(target_color, 0.05)
