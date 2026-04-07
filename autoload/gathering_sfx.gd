extends Node

const PATH_FISH_CAST := "res://assets/audio/activities/fish_cast.wav"
const PATH_FISH_CATCH := "res://assets/audio/activities/farming_harvest.wav"
const PATH_MINE := "res://assets/audio/activities/mine_pickaxe.wav"
const PATH_SMELT := "res://assets/audio/ui/confirm.wav"

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

func _play_path(path: String) -> void:
	var st: Resource = load(path)
	if st is AudioStream and _player:
		_player.stream = st
		_player.play()
