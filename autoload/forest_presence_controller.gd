extends Node

## Rare ambient chirp when walking the forest (not during rain/storm). Cooldown + config in `immersion_config.json` → `audio.forest_presence`.

var _cooldown_sec: float = 0.0
var _chirp_player: AudioStreamPlayer

func _ready() -> void:
	_chirp_player = AudioStreamPlayer.new()
	_chirp_player.bus = "Ambience"
	_chirp_player.volume_db = -16.0
	add_child(_chirp_player)

func _process(delta: float) -> void:
	_cooldown_sec = maxf(0.0, _cooldown_sec - delta)
	if _cooldown_sec > 0.0:
		return
	if not ImmersionConfig or not bool(ImmersionConfig.get_forest_presence().get("enabled", true)):
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var pl: Node = scene.get_node_or_null("Player")
	if pl == null:
		return
	if not GameZones.contains_forest(pl.global_position):
		return
	if WeatherSystem:
		if WeatherSystem.is_raining():
			return
		var w: int = WeatherSystem.current_weather
		if w == WeatherSystem.WeatherType.STORM or w == WeatherSystem.WeatherType.SNOW:
			return
	var cfg: Dictionary = ImmersionConfig.get_forest_presence()
	var mn: float = float(cfg.get("cooldown_min_sec", 20.0))
	var mx: float = float(cfg.get("cooldown_max_sec", 48.0))
	_cooldown_sec = randf_range(mn, mx)
	var path: String = str(cfg.get("chirp_path", "res://assets/audio/ambience_extended/birds_forest.wav"))
	if not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path) as AudioStream
	if st == null:
		return
	if st is AudioStreamWAV:
		(st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_chirp_player.stream = st
	_chirp_player.pitch_scale = randf_range(
		float(cfg.get("pitch_min", 0.92)),
		float(cfg.get("pitch_max", 1.08))
	)
	_chirp_player.play()
