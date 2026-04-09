extends Node

## Layered world ambience: seasonal bed + weather overlay (rain / storm / snow wind).
## Uses existing assets under res://assets/audio/ambience/.

const PATH_SEASON := {
	"spring": "res://assets/audio/ambience/spring.ogg",
	"summer": "res://assets/audio/ambience/summer.ogg",
	"fall": "res://assets/audio/ambience/fall.ogg",
	"winter": "res://assets/audio/ambience/winter.ogg",
}

const PATH_WEATHER := {
	"rain": "res://assets/audio/ambience/rain.ogg",
	"storm": "res://assets/audio/ambience/storm.ogg",
	"snow_wind": "res://assets/audio/ambience_extended/wind_trees.wav",
}

var _season_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer

func _ready() -> void:
	_season_player = AudioStreamPlayer.new()
	_weather_player = AudioStreamPlayer.new()
	_season_player.name = "SeasonAmbience"
	_season_player.volume_db = -10.0
	_season_player.bus = "Master"
	_weather_player.name = "WeatherAmbience"
	_weather_player.volume_db = -14.0
	_weather_player.bus = "Master"
	add_child(_season_player)
	add_child(_weather_player)
	if WeatherSystem:
		if not WeatherSystem.weather_changed.is_connected(_on_weather_changed):
			WeatherSystem.weather_changed.connect(_on_weather_changed)
	if GameManager:
		if not GameManager.season_changed.is_connected(_on_season_changed):
			GameManager.season_changed.connect(_on_season_changed)
		if not GameManager.day_changed.is_connected(_on_day_changed):
			GameManager.day_changed.connect(_on_day_changed)
	call_deferred("_refresh_all")

func _on_weather_changed(_new_weather: int) -> void:
	_apply_weather_layer()

func _on_season_changed(_season: String) -> void:
	_apply_season_bed()

func _on_day_changed(_day: int) -> void:
	_apply_season_bed()

func _refresh_all() -> void:
	_apply_season_bed()
	_apply_weather_layer()

func _apply_season_bed() -> void:
	if not GameManager:
		return
	var s: String = str(GameManager.player_data.get("season", "spring")).to_lower()
	var path: String = PATH_SEASON.get(s, PATH_SEASON["spring"])
	_play_loop_stream(_season_player, path)

func _apply_weather_layer() -> void:
	if not WeatherSystem:
		return
	match WeatherSystem.current_weather:
		WeatherSystem.WeatherType.RAIN:
			_play_loop_stream(_weather_player, PATH_WEATHER["rain"])
		WeatherSystem.WeatherType.STORM:
			_play_loop_stream(_weather_player, PATH_WEATHER["storm"])
		WeatherSystem.WeatherType.SNOW:
			_play_loop_stream(_weather_player, PATH_WEATHER["snow_wind"])
		_:
			_weather_player.stop()

func _play_loop_stream(player: AudioStreamPlayer, path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[WorldAmbient] Missing audio: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
	player.stream = stream
	player.play()
