extends Node

## Tints the 2D world (Main Node2D) by weather; syncs WeatherOverlay particle modulate.
## UI CanvasLayer is not under Node2D modulate chain — labels stay readable.

const TINT_SUNNY := Color(1.0, 1.0, 1.0, 1.0)
const TINT_OVERCAST := Color(0.92, 0.92, 0.94, 1.0)
const TINT_WINDY := Color(0.88, 0.9, 0.92, 1.0)
const TINT_RAIN := Color(0.76, 0.81, 0.9, 1.0)
const TINT_STORM := Color(0.58, 0.63, 0.76, 1.0)
const TINT_SNOW := Color(0.93, 0.96, 1.0, 1.0)

const TWEEN_SEC := 1.15

var _tween: Tween

func _ready() -> void:
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	call_deferred("_apply_immediate")

func _on_weather_changed(_w: int) -> void:
	_tween_to_weather()

func _apply_immediate() -> void:
	var main: Node2D = _get_main_root()
	if main == null:
		return
	var c: Color = _color_for_current_weather()
	main.modulate = c
	_sync_weather_overlay_particles(main, c)

func _tween_to_weather() -> void:
	var main: Node2D = _get_main_root()
	if main == null:
		return
	var target: Color = _color_for_current_weather()
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(main, "modulate", target, TWEEN_SEC)
	_tween.parallel().tween_method(_apply_overlay_modulate.bind(main), main.modulate, target, TWEEN_SEC)

func _apply_overlay_modulate(main: Node, mod: Color) -> void:
	_sync_weather_overlay_particles(main, mod)

func _get_main_root() -> Node2D:
	var scene: Node = get_tree().current_scene
	if scene is Node2D:
		return scene as Node2D
	return null

func _color_for_current_weather() -> Color:
	if not WeatherSystem:
		return TINT_SUNNY
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.SUNNY:
			return TINT_SUNNY
		WeatherSystem.WeatherType.OVERCAST:
			return TINT_OVERCAST
		WeatherSystem.WeatherType.WINDY:
			return TINT_WINDY
		WeatherSystem.WeatherType.RAIN:
			return TINT_RAIN
		WeatherSystem.WeatherType.STORM:
			return TINT_STORM
		WeatherSystem.WeatherType.SNOW:
			return TINT_SNOW
	return TINT_SUNNY

func _sync_weather_overlay_particles(main: Node, color: Color) -> void:
	var wo: Node = main.get_node_or_null("WeatherOverlay")
	if wo == null:
		return
	for c in wo.get_children():
		if c is CPUParticles2D:
			(c as CPUParticles2D).modulate = color
		elif c is ColorRect:
			## Lightning flash rect: keep alpha channel; tint cool-white slightly with weather.
			var cr: ColorRect = c as ColorRect
			var a: float = cr.color.a
			cr.color = Color(color.r, color.g, color.b, a)
