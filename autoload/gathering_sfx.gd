extends Node

const PATH_FISH_CAST := "res://assets/audio/activities/fish_cast.wav"
const PATH_FISH_CATCH := "res://assets/audio/activities/farming_harvest.wav"
const PATH_MINE := "res://assets/audio/activities/mine_pickaxe.wav"
const PATH_CHOP := "res://assets/audio/activities/chop_wood.wav"
const PATH_SMELT := "res://assets/audio/ui/confirm.wav"
const PATH_COOK := "res://assets/audio/activities/farming_plant.wav"
const PATH_CRAFT := "res://assets/audio/ui/notification.wav"
const PATH_WATER := "res://assets/audio/activities/farming_water.wav"

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

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

func _play_path(path: String) -> void:
	var st: Resource = load(path)
	if st is AudioStream and _player:
		_player.stream = st
		_player.play()
