from pathlib import Path

src = Path("scripts/world/world_mine_root.gd").read_text(encoding="utf-8")

# State: same block as world_mine (combat-only vars + tuning consts)
v0 = src.find("var _combat_invuln_until")
v1 = src.find("const HYPE_STEP := 18")
state_end = src.find("\n", v1) + 1
state_block = src[v0:src.find("\n", v1) + 1]

# Combat logic only (no world_mine _ready / interact / hud)
c0 = src.find("func _maintain_combat_spawns()")
combat_tail = src[c0:]

replacements = [
    ("_show_message(", "_tip("),
    ("_mine_journal_event(", "_journal("),
    ("_mine_ui_refresh()", "_ui_refresh()"),
    ("_play_screen_shake(", "feedback_shake.emit("),
    ("func _on_player_attack_requested", "func handle_attack_requested"),
]
for a, b in replacements:
    combat_tail = combat_tail.replace(a, b)

header = r"""extends Node
class_name MineCombatController

## Shared hub (`main`) + `world_mine` mine combat. Uses `MiningSystem.can_mine_here` / `depth_from_global_y` / `get_effective_mine_rect()`.

const EnemyMelee := preload("res://scripts/enemies/enemy_melee.gd")

const COMBAT_WEAPONS_CFG_PATH := "res://data/combat/weapons.json"
const COMBAT_ENEMIES_CFG_PATH := "res://data/combat/enemies.json"

signal feedback_tip(text: String, duration: float)
signal feedback_dialog(text: String)
signal feedback_journal(text: String)
signal feedback_shake(strength_px: float)
signal feedback_fx_mine()
signal feedback_fx_chop()
signal feedback_ui_refresh()

@export var defeat_respawn: Vector2 = Vector2(640, 360)
@export var defeat_message_charged: String = "You collapsed and woke up at the farmhouse. Lost 60g."
@export var defeat_message_insured: String = "You collapsed and woke up at the farmhouse. Daily rescue covered the loss."

var _player: Node2D = null
var _enemy_layer: Node2D = null


"""

boot = r"""
func _ready() -> void:
	_enemy_layer = Node2D.new()
	_enemy_layer.name = "EnemyLayer"
	_enemy_layer.z_index = 3
	add_child(_enemy_layer)
	_load_combat_weapons_config()
	_load_combat_enemies_config()


func bind_player(p: Node2D) -> void:
	if _player != null and _player.has_signal("attack_requested"):
		if _player.attack_requested.is_connected(handle_attack_requested):
			_player.attack_requested.disconnect(handle_attack_requested)
	_player = p
	if _player != null and _player.has_signal("attack_requested"):
		_player.attack_requested.connect(handle_attack_requested)


func _process(_delta: float) -> void:
	_maintain_combat_spawns()


func _tip(text: String, duration: float = 3.2) -> void:
	feedback_tip.emit(text, duration)


func _journal(text: String) -> void:
	feedback_journal.emit(text)


func _ui_refresh() -> void:
	feedback_ui_refresh.emit()


"""

out = header + boot + "\n" + state_block + "\n" + combat_tail

out = out.replace(
    "\tif charged_gold:\n\t\t_tip(\"You collapsed. Lost 60g.\", 4.0)\n\telse:\n\t\t_tip(\"You collapsed. Daily rescue covered the loss.\", 4.0)",
    "\tif charged_gold:\n\t\tfeedback_dialog.emit(defeat_message_charged)\n\telse:\n\t\tfeedback_dialog.emit(defeat_message_insured)",
)

out = out.replace(
    "\t\tif GatheringSfx:\n\t\t\tGatheringSfx.play_chop()\n\t\t_play_hitstop(hitstop_sec)",
    "\t\tfeedback_fx_chop.emit()\n\t\tif GatheringSfx:\n\t\t\tGatheringSfx.play_chop()\n\t\t_play_hitstop(hitstop_sec)",
)

out = out.replace(
    "\tif GatheringSfx:\n\t\tGatheringSfx.play_mine_swing()\n\tfeedback_shake.emit(3.2)",
    "\tfeedback_fx_mine.emit()\n\tif GatheringSfx:\n\t\tGatheringSfx.play_mine_swing()\n\tfeedback_shake.emit(3.2)",
)

dest = Path("scripts/combat/mine_combat_controller.gd")
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(out, encoding="utf-8")
print("Wrote", dest, "lines", len(out.splitlines()))
