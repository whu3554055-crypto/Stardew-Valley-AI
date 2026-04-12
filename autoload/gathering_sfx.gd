extends Node

const PATH_FISH_CAST := "res://assets/audio/activities/fish_cast.wav"
const PATH_FISH_CATCH := "res://assets/audio/activities/farming_harvest.wav"
const PATH_MINE := "res://assets/audio/activities/mine_pickaxe.wav"
const PATH_CHOP := "res://assets/audio/activities/chop_wood.wav"
const PATH_SMELT := "res://assets/audio/ui/confirm.wav"
const PATH_COOK := "res://assets/audio/activities/farming_plant.wav"
const PATH_CRAFT := "res://assets/audio/ui/notification.wav"
const PATH_WATER := "res://assets/audio/activities/farming_water.wav"
const PATH_WALK_GRASS := "res://assets/audio/activities/walking_grass.wav"
const PATH_SHOP_BELL_FALLBACK := "res://assets/audio/locations/shop_bell.wav"
const PATH_SHOP_DOOR_FALLBACK := "res://assets/audio/locations/shop_enter.wav"
const PATH_SHOP_EXIT_FALLBACK := "res://assets/audio/ui/cancel.wav"

var _player: AudioStreamPlayer
var _door_player: AudioStreamPlayer
var _foot_player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX"
	add_child(_player)
	_door_player = AudioStreamPlayer.new()
	_door_player.bus = "SFX"
	_door_player.volume_db = -8.0
	add_child(_door_player)
	_foot_player = AudioStreamPlayer.new()
	_foot_player.bus = "SFX"
	_foot_player.volume_db = -18.0
	add_child(_foot_player)
	call_deferred("_connect_world_router_for_sfx_cut")


func _connect_world_router_for_sfx_cut() -> void:
	if WorldRouter and not WorldRouter.world_changed.is_connected(_on_world_changed_stop_oneshots):
		WorldRouter.world_changed.connect(_on_world_changed_stop_oneshots)


func _on_world_changed_stop_oneshots(_scene_path: String) -> void:
	stop_active_one_shots()


func stop_active_one_shots() -> void:
	if _player:
		_player.stop()
	if _door_player:
		_door_player.stop()
	if _foot_player:
		_foot_player.stop()

func _shop_bell_after_door_sec() -> float:
	return ImmersionConfig.get_shop_bell_after_door_sec() if ImmersionConfig else 0.18

func play_fish_cast() -> void:
	_play_path(PATH_FISH_CAST)

func play_fish_catch() -> void:
	_play_path(PATH_FISH_CATCH)

func play_mine_swing() -> void:
	_play_path(PATH_MINE)

func play_smelt() -> void:
	_play_path(PATH_SMELT)

func play_cook() -> void:
	_play_path(PATH_COOK)

func play_chop() -> void:
	_play_path(PATH_CHOP)

func play_craft() -> void:
	_play_path(PATH_CRAFT)

func play_water() -> void:
	_play_path(PATH_WATER)

func play_shop_bell() -> void:
	var p: String = ImmersionConfig.get_one_shot_path("shop_bell") if ImmersionConfig else ""
	if p.is_empty():
		p = PATH_SHOP_BELL_FALLBACK
	_play_path(p)

func play_shop_door_open() -> void:
	var p: String = ImmersionConfig.get_one_shot_path("shop_door") if ImmersionConfig else ""
	if p.is_empty():
		p = PATH_SHOP_DOOR_FALLBACK
	_play_path_on(_door_player, p)

func play_season_change() -> void:
	var p: String = ImmersionConfig.get_one_shot_path("season_change") if ImmersionConfig else ""
	if p.is_empty():
		p = "res://assets/audio/ui/level_up.wav"
	_play_path(p)

func play_stamina_low() -> void:
	var p: String = ""
	if ImmersionConfig:
		var cfg: Dictionary = ImmersionConfig.get_stamina_low_config()
		p = str(cfg.get("sound_path", ""))
	if p.is_empty():
		p = "res://assets/audio/ui/error.wav"
	_play_path(p)

func play_shop_exit() -> void:
	var p: String = ImmersionConfig.get_one_shot_path("shop_exit") if ImmersionConfig else ""
	if p.is_empty():
		p = PATH_SHOP_EXIT_FALLBACK
	_play_path_on(_door_player, p)

## Door opens first, then greeting bell (overlapping players). Delay from `immersion_config` → `audio.levels.shop_bell_after_door_sec`.
func play_shop_enter() -> void:
	play_shop_door_open()
	if not is_inside_tree():
		return
	get_tree().create_timer(_shop_bell_after_door_sec()).timeout.connect(_deferred_shop_bell, CONNECT_ONE_SHOT)

func _deferred_shop_bell() -> void:
	play_shop_bell()

func play_footstep_grass(pitch_scale: float = 1.0) -> void:
	play_footstep_surface("grass", pitch_scale)

## `kind`: grass | wood | mine — paths from `audio.paths.footsteps` in `immersion_config.json`.
func play_footstep_surface(kind: String, pitch_scale: float = 1.0) -> void:
	if _foot_player == null:
		return
	var path: String = _footstep_path_for(kind)
	var st: Resource = load(path)
	if st is AudioStream:
		_foot_player.stream = st as AudioStream
		_foot_player.pitch_scale = clampf(pitch_scale, 0.55, 1.15)
		_foot_player.play()

func _footstep_path_for(kind: String) -> String:
	if ImmersionConfig:
		var p: String = ImmersionConfig.get_footstep_path(kind)
		if not p.is_empty() and ResourceLoader.exists(p):
			return p
	match kind:
		"wood":
			return "res://assets/audio/ui/hover.wav"
		"mine":
			return "res://assets/audio/ui/click.wav"
		_:
			return PATH_WALK_GRASS

func _play_path(path: String) -> void:
	_play_path_on(_player, path)

func _play_path_on(stream_player: AudioStreamPlayer, path: String) -> void:
	var st: Resource = load(path)
	if st is AudioStream and stream_player:
		stream_player.stream = st
		stream_player.play()
