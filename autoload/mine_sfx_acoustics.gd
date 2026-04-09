extends Node

## Enables SFX bus reverb when player is in the mine **deep band** (Y ≥ depth_break_2). See `immersion_config` → `audio.sfx_mine_reverb`.

var _sfx_bus: int = -1
var _slot: int = 0

func _ready() -> void:
	_sfx_bus = AudioServer.get_bus_index("SFX")
	if ImmersionConfig:
		var cfg: Dictionary = ImmersionConfig.get_mine_sfx_reverb()
		_slot = int(cfg.get("effect_slot_index", 0))

func _process(_delta: float) -> void:
	if _sfx_bus < 0:
		return
	if not ImmersionConfig or not bool(ImmersionConfig.get_mine_sfx_reverb().get("enabled", true)):
		return
	if AudioServer.get_bus_effect_count(_sfx_bus) <= _slot:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var pl: Node = scene.get_node_or_null("Player")
	if pl == null:
		return
	var pos: Vector2 = pl.global_position
	var want: bool = false
	if GameZones.can_mine_here(pos):
		want = GameZones.mine_depth_from_global_y(pos.y) >= 2
	var now: bool = AudioServer.is_bus_effect_enabled(_sfx_bus, _slot)
	if want == now:
		return
	AudioServer.set_bus_effect_enabled(_sfx_bus, _slot, want)
