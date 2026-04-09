extends Node

## Weather tint × time-of-day tint on Main; syncs WeatherOverlay particle modulate.
## UI CanvasLayer is not under Node2D modulate chain — labels stay readable.
## Tuning: `data/presentation/immersion_config.json`.

const TINT_SUNNY := Color(1.0, 1.0, 1.0, 1.0)

var _tween: Tween

func _ready() -> void:
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	if GameManager:
		if not GameManager.time_changed.is_connected(_on_game_time_changed):
			GameManager.time_changed.connect(_on_game_time_changed)
	call_deferred("_apply_immediate")

func _tween_sec() -> float:
	return ImmersionConfig.get_float("visual.tween_sec", 1.15) if ImmersionConfig else 1.15

func _on_weather_changed(_w: int) -> void:
	_tween_to_target()

func _on_game_time_changed(_t: float) -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_apply_immediate()

func _apply_immediate() -> void:
	var main: Node2D = _get_main_root()
	if main == null:
		return
	var c: Color = _combined_color()
	main.modulate = c
	_sync_weather_overlay_particles(main, c)

func _tween_to_target() -> void:
	var main: Node2D = _get_main_root()
	if main == null:
		return
	var target: Color = _combined_color()
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	var ts: float = _tween_sec()
	_tween.tween_property(main, "modulate", target, ts)
	_tween.parallel().tween_method(_apply_overlay_modulate.bind(main), main.modulate, target, ts)

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
	if ImmersionConfig:
		return ImmersionConfig.get_weather_tint_color(WeatherSystem.current_weather)
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.SUNNY:
			return TINT_SUNNY
		WeatherSystem.WeatherType.OVERCAST:
			return Color(0.92, 0.92, 0.94, 1.0)
		WeatherSystem.WeatherType.WINDY:
			return Color(0.88, 0.9, 0.92, 1.0)
		WeatherSystem.WeatherType.RAIN:
			return Color(0.76, 0.81, 0.9, 1.0)
		WeatherSystem.WeatherType.STORM:
			return Color(0.58, 0.63, 0.76, 1.0)
		WeatherSystem.WeatherType.SNOW:
			return Color(0.93, 0.96, 1.0, 1.0)
	return TINT_SUNNY

func _time_tint_for_hour(t: float) -> Color:
	var h: Dictionary = ImmersionConfig.get_time_tint_hours() if ImmersionConfig else {}
	var dawn_s: float = float(h.get("dawn_start", 5.0))
	var dawn_e: float = float(h.get("dawn_end", 7.0))
	var dusk_s: float = float(h.get("dusk_start", 17.0))
	var dusk_e: float = float(h.get("dusk_end", 20.0))
	var night_after: float = float(h.get("night_after_hour", 21.0))
	var night_col: Color = ImmersionConfig.get_time_tint_night() if ImmersionConfig else Color(0.86, 0.88, 0.96, 1.0)
	var dusk_tar: Color = ImmersionConfig.get_time_tint_dusk() if ImmersionConfig else Color(0.9, 0.9, 0.97, 1.0)
	if t < dawn_s or t >= night_after:
		return night_col
	if t < dawn_e:
		var k: float = clampf((t - dawn_s) / maxf(0.001, dawn_e - dawn_s), 0.0, 1.0)
		return night_col.lerp(Color(1.0, 1.0, 1.0, 1.0), k)
	if t >= dusk_s and t < dusk_e:
		var k2: float = clampf((t - dusk_s) / maxf(0.001, dusk_e - dusk_s), 0.0, 1.0)
		return Color(1.0, 1.0, 1.0, 1.0).lerp(dusk_tar, k2)
	return Color(1.0, 1.0, 1.0, 1.0)

func _combined_color() -> Color:
	var w: Color = _color_for_current_weather()
	var tt: Color = _time_tint_for_hour(GameManager.current_time if GameManager else 12.0)
	return Color(
		clampf(w.r * tt.r, 0.0, 1.0),
		clampf(w.g * tt.g, 0.0, 1.0),
		clampf(w.b * tt.b, 0.0, 1.0),
		1.0
	)

func _sync_weather_overlay_particles(main: Node, color: Color) -> void:
	var wo: Node = main.get_node_or_null("WeatherOverlay")
	if wo == null:
		return
	for c in wo.get_children():
		if c is CPUParticles2D:
			(c as CPUParticles2D).modulate = color
		elif c is ColorRect:
			var cr: ColorRect = c as ColorRect
			var a: float = cr.color.a
			cr.color = Color(color.r, color.g, color.b, a)
