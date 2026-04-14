extends Node
class_name MineCombatController

## Mine / cave combat only (`world_mine`, `world_cave`). Uses `MiningSystem.can_mine_here` / `get_effective_mine_rect()`; depth from Y unless `fixed_combat_depth` is set.

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
## If 0–2, spawns and rewards use this depth instead of Y-based bands (`world_cave` uses 2).
@export var fixed_combat_depth: int = -1
## Multiplier on spawn delay after a successful spawn (lower = more pressure).
@export var spawn_interval_scale: float = 1.0
@export var journal_zone_name: String = "Mine"
@export var elite_spawn_journal_line: String = "An elite foe appears in the mine!"

var _player: Node2D = null
var _enemy_layer: Node2D = null

var _combat_invuln_until: float = 0.0
var _last_attack_ms: int = -99999
var _combat_weapons_cfg: Dictionary = {}
var _combat_enemies_cfg: Dictionary = {}
var _active_weapon_id: String = "starter_sword"
var _hitstop_active: bool = false
var _next_mine_spawn_at: float = 0.0
var _combo_hits: int = 0
var _combo_expire_at: float = 0.0
var _kill_streak: int = 0
var _kill_streak_expire_at: float = 0.0
var _revenge_buff_until: float = 0.0
var _no_ore_kill_streak: int = 0
var _attack_speed_buff_until: float = 0.0
var _no_elite_kill_streak: int = 0
var _shield_charges: int = 0
var _daily_peak_streak: int = 0
var _crit_chain: int = 0
var _momentum_score: int = 0
var _no_hit_kill_streak: int = 0
var _was_in_mine_last_frame: bool = false
var _run_kills: int = 0
var _run_elites: int = 0
var _run_bonus_gold: int = 0
var _perfect_guard_chain: int = 0
var _last_stand_used_run: bool = false
var _perfect_guard_chain_best: int = 0
var _hype_points: int = 0
var _hype_rank: String = "Rookie"
var _quest_near_done_latched: Dictionary = {}
var _streak_medal_awarded: Dictionary = {}
var _run_best_tag: String = "None"
var _last_stand_redeem_until: float = 0.0

const PLAYER_ATTACK_COOLDOWN_MS := 340
const PLAYER_ATTACK_RANGE := 56.0
const PLAYER_ATTACK_DAMAGE := 12
const PLAYER_ATTACK_KNOCKBACK := 220.0
const PLAYER_ATTACK_HITSTOP_SEC := 0.04
const PLAYER_ATTACK_CRIT_CHANCE := 0.1
const PLAYER_ATTACK_CRIT_MULT := 1.6
const PLAYER_RESPAWN_HEAL_RATIO := 0.65
const MAX_MINE_ENEMIES := 5
const MINE_SPAWN_MIN_INTERVAL_SEC := 1.2
const MINE_SPAWN_MAX_INTERVAL_SEC := 2.1
const MINE_SPAWN_MIN_PLAYER_DIST := 84.0
const MINE_SPAWN_MAX_PLAYER_DIST := 320.0
const COMBO_WINDOW_SEC := 1.2
const COMBO_BONUS_PER_STACK := 0.08
const COMBO_MAX_STACKS := 5
const KILL_STREAK_WINDOW_SEC := 6.0
const KILL_STREAK_STEP := 5
const ELITE_BASE_CHANCE := 0.08
const ATTACK_GUARD_WINDOW_SEC := 0.22
const ATTACK_GUARD_DAMAGE_REDUCTION := 0.35
const KILL_HEAL_BASE := 2.0
const KILL_MILESTONES := [25, 60, 120]
const REVENGE_BUFF_SEC := 2.6
const REVENGE_DAMAGE_MULT := 1.22
const ORE_PITY_KILL_THRESHOLD := 6
const EXECUTE_THRESHOLD_RATIO := 0.25
const EXECUTE_BONUS_MULT := 1.35
const PANIC_HP_RATIO := 0.2
const PANIC_DAMAGE_REDUCTION := 0.2
const PANIC_INVULN_SEC := 0.85
const ELITE_BOUNTY_GOLD_BASE := 36
const ATTACK_STAMINA_COST := 4.0
const STREAK_HASTE_SEC := 2.2
const STREAK_HASTE_COOLDOWN_MULT := 0.72
const CRIT_STAMINA_REFUND := 2.0
const KILL_SPLASH_RANGE := 46.0
const KILL_SPLASH_DAMAGE := 6
const ATTACK_CONE_DOT_MIN := 0.2
const BACKSTAB_DOT_MAX := -0.45
const BACKSTAB_BONUS_MULT := 1.25
const ELITE_PITY_KILLS := 14
const SHIELD_MAX_CHARGES := 3
const COMBO_FEEDBACK_MIN_STACK := 2
const BIG_HIT_THRESHOLD := 24
const CLUTCH_HP_RATIO := 0.2
const CLUTCH_BONUS_GOLD := 22
const MOMENTUM_STEP := 20
const NO_HIT_STREAK_GOAL := 8
const HYPE_STEP := 18


func _ready() -> void:
	_enemy_layer = Node2D.new()
	_enemy_layer.name = "EnemyLayer"
	_enemy_layer.z_index = 3
	add_child(_enemy_layer)
	_load_combat_weapons_config()
	_load_combat_enemies_config()


func on_game_day_advanced() -> void:
	_daily_peak_streak = 0
	_streak_medal_awarded.clear()


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


func _effective_spawn_depth() -> int:
	if fixed_combat_depth >= 0:
		return clampi(fixed_combat_depth, 0, 2)
	if MiningSystem and _player:
		return MiningSystem.depth_from_global_y(_player.global_position.y)
	return 0


func _kill_reward_depth(_enemy: Node2D) -> int:
	if fixed_combat_depth >= 0:
		return clampi(fixed_combat_depth, 0, 2)
	if MiningSystem:
		return MiningSystem.depth_from_global_y(_enemy.global_position.y)
	return 0


func _maintain_combat_spawns() -> void:
	if _enemy_layer == null or _player == null or MiningSystem == null:
		return
	var in_mine_now: bool = MiningSystem.can_mine_here(_player.global_position)
	if _was_in_mine_last_frame and not in_mine_now and (_run_kills > 0 or _run_bonus_gold > 0):
		var run_stars: int = _run_star_rating(_run_kills, _run_elites, _run_bonus_gold, _perfect_guard_chain_best)
		var mvp: String = _run_mvp_tag()
		_journal("%s run recap: %d★, kills %d, elites %d, bonus +%dg, MVP %s." % [journal_zone_name, run_stars, _run_kills, _run_elites, _run_bonus_gold, mvp])
		_tip("Run recap %d★ · MVP %s" % [run_stars, mvp], 1.2)
		_run_kills = 0
		_run_elites = 0
		_run_bonus_gold = 0
		_last_stand_used_run = false
		_perfect_guard_chain_best = 0
		_hype_points = 0
		_hype_rank = "Rookie"
		_run_best_tag = "None"
	_was_in_mine_last_frame = in_mine_now
	if not MiningSystem.can_mine_here(_player.global_position):
		if _enemy_layer.get_child_count() > 0:
			for c in _enemy_layer.get_children():
				c.queue_free()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _next_mine_spawn_at:
		return
	var alive: int = 0
	for c in _enemy_layer.get_children():
		if c is EnemyMelee:
			alive += 1
	var depth: int = _effective_spawn_depth()
	var depth_cap: int = mini(MAX_MINE_ENEMIES + 2, MAX_MINE_ENEMIES + maxi(0, depth))
	var hp_ratio: float = 1.0
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		hp_ratio = hp_cur / hp_max
	if hp_ratio <= 0.35:
		depth_cap = maxi(2, depth_cap - 2)
	if alive >= depth_cap:
		return
	if _spawn_mine_enemy():
		var interval: float = lerpf(MINE_SPAWN_MAX_INTERVAL_SEC, MINE_SPAWN_MIN_INTERVAL_SEC, clampf(float(depth) / 3.0, 0.0, 1.0))
		interval *= clampf(spawn_interval_scale, 0.3, 4.0)
		interval *= _adaptive_combat_profile().get("spawn_pressure", 1.0)
		if hp_ratio <= 0.35:
			interval += 0.9
		_next_mine_spawn_at = now + interval
	else:
		_next_mine_spawn_at = now + 0.25


func _spawn_mine_enemy() -> bool:
	if _enemy_layer == null or _player == null or MiningSystem == null:
		return false
	var mine: Rect2 = MiningSystem.get_effective_mine_rect()
	var depth: int = _effective_spawn_depth()
	var e := EnemyMelee.new()
	var profile: Dictionary = _pick_enemy_profile_for_depth(depth)
	e.profile_id = str(profile.get("id", ""))
	var hp_base: int = int(profile.get("max_hp_base", 20))
	var hp_scale: int = int(profile.get("max_hp_depth_scale", 8))
	e.enemy_id = str(profile.get("enemy_id", "mine_slime"))
	e.max_hp = hp_base + depth * hp_scale + randi_range(0, 10)
	e.hp = e.max_hp
	e.move_speed = randf_range(float(profile.get("speed_min", 40.0 + depth * 2.5)), float(profile.get("speed_max", 55.0 + depth * 3.0)))
	e.contact_damage = randf_range(float(profile.get("damage_min", 7.0 + depth * 1.5)), float(profile.get("damage_max", 11.0 + depth * 2.0)))
	e.contact_interval_sec = maxf(0.42, 0.9 - float(depth) * 0.08)
	e.drop_count_min = maxi(1, int(profile.get("drop_count_min", 1)))
	e.drop_count_max = maxi(e.drop_count_min, int(profile.get("drop_count_max", 2)))
	e.drop_item_id = _pick_weighted_drop_item(profile.get("drop_pool", []), "stone_chunk")
	var elite_chance: float = clampf(float(profile.get("elite_chance", ELITE_BASE_CHANCE + float(depth) * 0.02)), 0.0, 0.45)
	elite_chance = clampf(elite_chance + float(_adaptive_combat_profile().get("elite_delta", 0.0)), 0.0, 0.5)
	if randf() < elite_chance or _no_elite_kill_streak >= ELITE_PITY_KILLS:
		var hp_mult: float = maxf(1.1, float(profile.get("elite_hp_mult", 1.55)))
		var dmg_mult: float = maxf(1.1, float(profile.get("elite_damage_mult", 1.3)))
		var extra_drop: int = maxi(1, int(profile.get("elite_drop_bonus", 1)))
		e.max_hp = int(round(float(e.max_hp) * hp_mult))
		e.hp = e.max_hp
		e.contact_damage = float(e.contact_damage) * dmg_mult
		e.drop_count_max += extra_drop
		e.enemy_id = "%s_elite" % e.enemy_id
		e.set_body_color(Color(0.78, 0.45, 0.86, 0.96))
		_journal(elite_spawn_journal_line)
		_tip("Elite incoming!", 0.95)
		feedback_shake.emit(4.2)
		if GatheringSfx:
			GatheringSfx.play_mine_swing()
	var spawn_pos: Vector2 = Vector2.ZERO
	var found_pos: bool = false
	for _i in range(12):
		var cand := Vector2(
			randf_range(mine.position.x + 14.0, mine.end.x - 14.0),
			randf_range(mine.position.y + 14.0, mine.end.y - 14.0)
		)
		var dist_to_player: float = cand.distance_to(_player.global_position)
		if dist_to_player >= MINE_SPAWN_MIN_PLAYER_DIST and dist_to_player <= MINE_SPAWN_MAX_PLAYER_DIST:
			spawn_pos = cand
			found_pos = true
			break
	if not found_pos:
		return false
	e.global_position = spawn_pos
	e.contact_hit.connect(_on_enemy_contact_hit)
	e.enemy_killed.connect(_on_enemy_killed)
	_enemy_layer.add_child(e)
	return true


func handle_attack_requested(origin: Vector2, facing: Vector2) -> void:
	if _enemy_layer == null or _player == null:
		return
	var w: Dictionary = _weapon_profile()
	var now_ms: int = Time.get_ticks_msec()
	var cd_ms: int = int(w.get("cooldown_ms", PLAYER_ATTACK_COOLDOWN_MS))
	var now_sec: float = float(now_ms) / 1000.0
	if now_sec <= _attack_speed_buff_until:
		cd_ms = maxi(80, int(round(float(cd_ms) * STREAK_HASTE_COOLDOWN_MULT)))
	if now_ms - _last_attack_ms < cd_ms:
		return
	if GameManager and not GameManager.try_consume_stamina(ATTACK_STAMINA_COST):
		_tip("Not enough stamina to attack.", 0.65)
		return
	_last_attack_ms = now_ms
	var center: Vector2 = origin + facing.normalized() * 30.0
	var range_v: float = float(w.get("range", PLAYER_ATTACK_RANGE))
	var dmg: int = int(w.get("damage", PLAYER_ATTACK_DAMAGE))
	var kb: float = float(w.get("knockback", PLAYER_ATTACK_KNOCKBACK))
	var hitstop_sec: float = float(w.get("hitstop_sec", PLAYER_ATTACK_HITSTOP_SEC))
	var crit_chance: float = clampf(float(w.get("crit_chance", PLAYER_ATTACK_CRIT_CHANCE)), 0.0, 1.0)
	var crit_mult: float = maxf(1.0, float(w.get("crit_mult", PLAYER_ATTACK_CRIT_MULT)))
	now_sec = Time.get_ticks_msec() / 1000.0
	if now_sec > _combo_expire_at:
		if _combo_hits >= 2:
			_tip("Combo dropped.", 0.35)
		_combo_hits = 0
	_combo_expire_at = now_sec + COMBO_WINDOW_SEC
	var combo_stack: int = mini(_combo_hits, COMBO_MAX_STACKS)
	var combo_mult: float = 1.0 + COMBO_BONUS_PER_STACK * float(combo_stack)
	var revenge_mult: float = REVENGE_DAMAGE_MULT if now_sec <= _revenge_buff_until else 1.0
	var hit_any: bool = false
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = maxi(1, int(round(float(dmg) * combo_mult * revenge_mult * (crit_mult if is_crit else 1.0))))
	var facing_n: Vector2 = facing.normalized()
	for c in _enemy_layer.get_children():
		if not (c is EnemyMelee):
			continue
		var e: EnemyMelee = c
		var to_enemy: Vector2 = (e.global_position - origin).normalized()
		if e.global_position.distance_to(center) <= range_v and facing_n.dot(to_enemy) >= ATTACK_CONE_DOT_MIN:
			var dmg_to_apply: int = final_dmg
			var special_tag: String = ""
			var enemy_to_player: Vector2 = (_player.global_position - e.global_position).normalized()
			if enemy_to_player.dot(to_enemy) <= BACKSTAB_DOT_MAX:
				dmg_to_apply = maxi(1, int(round(float(dmg_to_apply) * BACKSTAB_BONUS_MULT)))
				special_tag = "Backstab!"
			if e.max_hp > 0 and float(e.hp) / float(e.max_hp) <= EXECUTE_THRESHOLD_RATIO:
				dmg_to_apply = maxi(1, int(round(float(final_dmg) * EXECUTE_BONUS_MULT)))
				special_tag = "Execute!"
			var hp_before: int = int(e.hp)
			var killed: bool = e.take_damage(dmg_to_apply)
			if not special_tag.is_empty():
				_tip(special_tag, 0.45)
			elif dmg_to_apply >= BIG_HIT_THRESHOLD:
				_tip("Heavy hit %d!" % dmg_to_apply, 0.4)
			if killed:
				var overkill: int = maxi(0, dmg_to_apply - maxi(0, hp_before))
				if overkill >= 10 and GameManager:
					var overkill_bonus: int = mini(25, overkill / 2)
					GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + overkill_bonus
					_tip("Overkill +%dg" % overkill_bonus, 0.55)
					_journal("Overkill payout: +%dg." % overkill_bonus)
			var dir: Vector2 = e.global_position - origin
			if not killed:
				e.apply_knockback(dir, kb)
			hit_any = true
	if hit_any:
		_combo_hits = mini(COMBO_MAX_STACKS, _combo_hits + 1)
		_combo_expire_at = now_sec + COMBO_WINDOW_SEC
		if _combo_hits >= COMBO_FEEDBACK_MIN_STACK:
			var combo_label: String = "Combo x%d!" % _combo_hits
			_tip(combo_label, 0.45)
			if _combo_hits == COMBO_MAX_STACKS:
				_journal("Combo peak reached!")
		feedback_fx_chop.emit()
		if GatheringSfx:
			GatheringSfx.play_chop()
		_play_hitstop(hitstop_sec)
		if is_crit:
			_crit_chain += 1
			if GameManager and GameManager.has_method("restore_stamina"):
				GameManager.restore_stamina(CRIT_STAMINA_REFUND)
			_tip("Critical hit!", 0.55)
			if _crit_chain >= 3 and GameManager:
				var crit_bonus: int = 18
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + crit_bonus
				_journal("Critical chain x%d (+%dg)." % [_crit_chain, crit_bonus])
				_tip("Critical chain x%d!" % _crit_chain, 0.8)
				_crit_chain = 0
		else:
			_crit_chain = 0
	else:
		if _combo_hits >= 2:
			_tip("Combo missed.", 0.35)
		_combo_hits = 0
		_crit_chain = 0


func _on_enemy_contact_hit(_enemy: EnemyMelee, damage: float) -> void:
	if _player == null:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _combat_invuln_until:
		return
	if _shield_charges > 0:
		_shield_charges -= 1
		_combat_invuln_until = now + 0.45
		_tip("Shield blocked the hit!", 0.45)
		return
	var guarded: bool = (now - (float(_last_attack_ms) / 1000.0)) <= ATTACK_GUARD_WINDOW_SEC
	var final_damage: float = damage
	var panic_mode: bool = false
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		panic_mode = (hp_cur / hp_max) <= PANIC_HP_RATIO
	if guarded:
		final_damage = damage * (1.0 - ATTACK_GUARD_DAMAGE_REDUCTION)
	if panic_mode:
		final_damage *= (1.0 - PANIC_DAMAGE_REDUCTION)
	_combat_invuln_until = now + (PANIC_INVULN_SEC if panic_mode else 0.55)
	if _player.has_method("apply_knockback"):
		var kb_dir: Vector2 = _player.global_position - _enemy.global_position
		_player.apply_knockback(kb_dir, 240.0, 920.0)
	if guarded and _enemy and _enemy.has_method("apply_knockback"):
		_perfect_guard_chain += 1
		_perfect_guard_chain_best = maxi(_perfect_guard_chain_best, _perfect_guard_chain)
		_tip("Perfect guard x%d" % _perfect_guard_chain, 0.45)
		if _perfect_guard_chain % 3 == 0 and GameManager:
			var guard_bonus: int = 12
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + guard_bonus
			_journal("Perfect guard chain bonus +%dg." % guard_bonus)
		var rebound_dir: Vector2 = _enemy.global_position - _player.global_position
		_enemy.apply_knockback(rebound_dir, 360.0)
	else:
		_perfect_guard_chain = 0
	if not GameManager:
		return
	var hp_cur_check: float = float(GameManager.player_data.get("hp", 100.0))
	if hp_cur_check - final_damage <= 0.0 and not _last_stand_used_run:
		_last_stand_used_run = true
		GameManager.player_data["hp"] = 1.0
		_combat_invuln_until = now + 1.35
		_last_stand_redeem_until = now + 8.0
		_journal("Last Stand triggered! You survived with 1 HP.")
		_tip("Last Stand!", 0.9)
		_ui_refresh()
		return
	var alive: bool = GameManager.apply_damage(final_damage)
	_no_hit_kill_streak = 0
	feedback_shake.emit(3.8 if panic_mode else 2.6)
	_revenge_buff_until = now + REVENGE_BUFF_SEC
	if guarded:
		_tip("Guarded hit!", 0.4)
	elif panic_mode:
		_tip("Panic guard activated!", 0.5)
	else:
		_tip("You were hit!", 0.35)
	_ui_refresh()
	if not alive:
		_handle_player_defeat()


func _handle_player_defeat() -> void:
	if _player:
		_player.global_position = defeat_respawn
	var charged_gold: bool = false
	if GameManager:
		var hpmax: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		var heal_to: float = hpmax * PLAYER_RESPAWN_HEAL_RATIO
		GameManager.player_data["hp"] = heal_to
		GameManager.player_data["daily_defeats"] = int(GameManager.player_data.get("daily_defeats", 0)) + 1
		var season_idx: int = _season_index_from_name(str(GameManager.player_data.get("season", "spring")))
		var year_idx: int = int(GameManager.player_data.get("year", 1))
		var day_idx: int = year_idx * 1000 + season_idx * 100 + int(GameManager.player_data.get("day", 1))
		var insured_day: int = int(GameManager.player_data.get("defeat_insurance_day", -1))
		if insured_day == day_idx:
			var gold: int = int(GameManager.player_data.get("gold", 0))
			GameManager.player_data["gold"] = maxi(0, gold - 60)
			charged_gold = true
		else:
			GameManager.player_data["defeat_insurance_day"] = day_idx
	_combat_invuln_until = Time.get_ticks_msec() / 1000.0 + 1.2
	if charged_gold:
		feedback_dialog.emit(defeat_message_charged)
	else:
		feedback_dialog.emit(defeat_message_insured)
	_ui_refresh()
	if _enemy_layer:
		for c in _enemy_layer.get_children():
			c.queue_free()


func _on_enemy_killed(enemy: EnemyMelee) -> void:
	var depth_now: int = _kill_reward_depth(enemy)
	var is_elite: bool = str(enemy.enemy_id).find("_elite") >= 0
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if _last_stand_redeem_until > 0.0 and now_sec <= _last_stand_redeem_until and GameManager:
		var redeem_gold: int = 35
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + redeem_gold
		_journal("Redemption! Last Stand converted to victory (+%dg)." % redeem_gold)
		_tip("Redemption +%dg" % redeem_gold, 1.0)
		_last_stand_redeem_until = 0.0
	if now_sec > _kill_streak_expire_at:
		_kill_streak = 0
	_kill_streak += 1
	_kill_streak_expire_at = now_sec + KILL_STREAK_WINDOW_SEC
	_daily_peak_streak = maxi(_daily_peak_streak, _kill_streak)
	if GameManager:
		GameManager.player_data["combat_peak_streak_today"] = _daily_peak_streak
	_try_award_streak_medal(_kill_streak)
	if GameManager:
		var best_streak: int = int(GameManager.player_data.get("combat_best_streak", 0))
		if _kill_streak > best_streak:
			GameManager.player_data["combat_best_streak"] = _kill_streak
			_journal("New personal best streak: %d." % _kill_streak)
			_tip("New PB streak: %d" % _kill_streak, 0.85)
	var dropped_ore: bool = false
	_hype_points += 3 + (4 if is_elite else 0)
	var hype_now: String = _hype_rank_from_points(_hype_points)
	if hype_now != _hype_rank:
		_hype_rank = hype_now
		_tip("Hype rank: %s" % _hype_rank, 0.85)
		_journal("Combat hype advanced to %s." % _hype_rank)
	var template: Dictionary = ItemDatabase.get_item(enemy.drop_item_id)
	if not template.is_empty():
		var n: int = enemy.roll_drop_count()
		for _i in range(n):
			InventoryManager.add_item(template.duplicate(true))
		dropped_ore = str(enemy.drop_item_id).ends_with("_ore")
	if dropped_ore:
		_no_ore_kill_streak = 0
	else:
		_no_ore_kill_streak += 1
		if _no_ore_kill_streak >= ORE_PITY_KILL_THRESHOLD:
			var pity_item_id: String = "silver_ore" if depth_now >= 2 else ("iron_ore" if depth_now >= 1 else "copper_ore")
			var pity_tpl: Dictionary = ItemDatabase.get_item(pity_item_id)
			if not pity_tpl.is_empty():
				InventoryManager.add_item(pity_tpl.duplicate(true))
				_no_ore_kill_streak = 0
				_tip("Ore pity drop: %s" % pity_item_id, 0.9)
	if QuestSystem:
		QuestSystem.track_event("enemy_kill", {
			"enemy_id": enemy.enemy_id,
			"count": 1,
			"mine_depth": depth_now,
			"kill_streak": _kill_streak,
			"daily_defeats": int(GameManager.player_data.get("daily_defeats", 0)) if GameManager else 0
		})
		var q_progress: String = _combat_quest_progress_line()
		if not q_progress.is_empty():
			_tip(q_progress, 0.8)
	if GameManager and GameManager.has_method("heal_hp"):
		GameManager.heal_hp(KILL_HEAL_BASE + float(depth_now) * 0.5)
	_run_kills += 1
	_no_hit_kill_streak += 1
	if _no_hit_kill_streak == NO_HIT_STREAK_GOAL and GameManager:
		var no_hit_bonus: int = 45
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + no_hit_bonus
		_run_bonus_gold += no_hit_bonus
		_journal("No-hit streak achieved! +%dg." % no_hit_bonus)
		_tip("No-hit streak x%d!" % NO_HIT_STREAK_GOAL, 1.0)
	_momentum_score += 3 + (2 if is_elite else 0)
	if _momentum_score >= MOMENTUM_STEP:
		var momentum_tiers: int = _momentum_score / MOMENTUM_STEP
		_momentum_score = _momentum_score % MOMENTUM_STEP
		var momentum_bonus: int = 10 * momentum_tiers
		if GameManager:
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + momentum_bonus
		_run_bonus_gold += momentum_bonus
		_tip("Momentum surge! +%dg" % momentum_bonus, 0.8)
		_journal("Momentum payout: +%dg." % momentum_bonus)
	if GameManager:
		var hp_cur: float = float(GameManager.player_data.get("hp", 100.0))
		var hp_max: float = maxf(1.0, float(GameManager.player_data.get("hp_max", 100.0)))
		if hp_cur / hp_max <= CLUTCH_HP_RATIO:
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + CLUTCH_BONUS_GOLD
			_journal("Clutch kill! +%dg bonus." % CLUTCH_BONUS_GOLD)
			_tip("Clutch kill!", 0.8)
	if GameManager:
		GameManager.player_data["combat_kills_today"] = int(GameManager.player_data.get("combat_kills_today", 0)) + 1
		if is_elite:
			GameManager.player_data["combat_elites_today"] = int(GameManager.player_data.get("combat_elites_today", 0)) + 1
			var elite_today: int = int(GameManager.player_data.get("combat_elites_today", 0))
			_tip("Elite progress today: %d / 5" % mini(elite_today, 5), 0.9)
			if elite_today == 5:
				_journal("Daily elite hunter target reached (5/5).")
				_tip("Daily elite target complete!", 1.0)
			if not bool(GameManager.player_data.get("combat_badge_first_elite", false)):
				GameManager.player_data["combat_badge_first_elite"] = true
				_journal("Badge unlocked: First Elite Down.")
				_tip("Badge: First Elite Down", 1.2)
	if is_elite:
		_tip("Elite defeated!", 0.8)
	else:
		_tip("Enemy defeated.", 0.35)
	if GameManager and is_elite:
		_no_elite_kill_streak = 0
		_run_elites += 1
		var bounty_gold: int = ELITE_BOUNTY_GOLD_BASE + depth_now * 10
		bounty_gold = int(round(float(bounty_gold) * float(_adaptive_combat_profile().get("bounty_scale", 1.0))))
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bounty_gold
		_run_bonus_gold += bounty_gold
		_journal("Elite bounty claimed (+%dg)." % bounty_gold)
		_tip("Elite bounty +%dg" % bounty_gold, 0.9)
		var elite_profile: Dictionary = _find_enemy_profile_by_id(enemy.profile_id)
		var bonus_item_id: String = _pick_weighted_drop_item(elite_profile.get("elite_bonus_drop_pool", []), "")
		if not bonus_item_id.is_empty():
			var bonus_tpl: Dictionary = ItemDatabase.get_item(bonus_item_id)
			if not bonus_tpl.is_empty():
				InventoryManager.add_item(bonus_tpl.duplicate(true))
				_tip("Elite bonus drop: %s" % bonus_item_id, 0.8)
	else:
		_no_elite_kill_streak += 1
	var splash_hits: int = 0
	if _enemy_layer:
		for c in _enemy_layer.get_children():
			if not (c is EnemyMelee):
				continue
			var near_enemy: EnemyMelee = c
			if near_enemy == enemy:
				continue
			if near_enemy.global_position.distance_to(enemy.global_position) <= KILL_SPLASH_RANGE:
				near_enemy.take_damage(KILL_SPLASH_DAMAGE)
				splash_hits += 1
	if splash_hits > 0:
		_tip("Cleave hit x%d" % splash_hits, 0.45)
	if GameManager:
		var total_kills: int = int(GameManager.player_data.get("combat_kills_total", 0)) + 1
		GameManager.player_data["combat_kills_total"] = total_kills
		var milestone_idx: int = int(GameManager.player_data.get("combat_kill_milestone_idx", 0))
		if milestone_idx >= 0 and milestone_idx < KILL_MILESTONES.size():
			var target: int = int(KILL_MILESTONES[milestone_idx])
			if total_kills >= target:
				var milestone_gold: int = 80 + milestone_idx * 70
				GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + milestone_gold
				GameManager.player_data["combat_kill_milestone_idx"] = milestone_idx + 1
				_journal("Combat milestone %d kills reached (+%dg)." % [target, milestone_gold])
				_tip("Milestone reached: %d kills!" % target, 1.3)
	if _kill_streak > 0 and _kill_streak % KILL_STREAK_STEP == 0 and GameManager:
		var depth_bonus: int = maxi(0, _kill_reward_depth(enemy))
		var bonus_gold: int = 14 + depth_bonus * 4
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus_gold
		_attack_speed_buff_until = now_sec + STREAK_HASTE_SEC
		_shield_charges = mini(SHIELD_MAX_CHARGES, _shield_charges + 1)
		var tier: String = _streak_tier_label(_kill_streak)
		_tip("%s streak %d! +%dg" % [tier, _kill_streak, bonus_gold], 1.1)
		_journal("Combat bonus: %s streak %d (+%dg)." % [tier, _kill_streak, bonus_gold])
		if _kill_streak >= 10 and not bool(GameManager.player_data.get("combat_badge_streak_10", false)):
			GameManager.player_data["combat_badge_streak_10"] = true
			_journal("Badge unlocked: Streak x10.")
			_tip("Badge: Streak x10", 1.2)
	feedback_fx_mine.emit()
	if GatheringSfx:
		GatheringSfx.play_mine_swing()
	feedback_shake.emit(3.2)
	_journal("Defeated %s." % enemy.enemy_id)
	_ui_refresh()


func _adaptive_combat_profile() -> Dictionary:
	var style: String = ""
	if GameManager:
		style = str(GameManager.player_data.get("player_style_last_day", "balanced"))
	match style:
		"combat_focused":
			return {"spawn_pressure": 0.92, "elite_delta": 0.025, "bounty_scale": 0.95}
		"farming_focused", "social_focused", "fishing_focused":
			return {"spawn_pressure": 1.1, "elite_delta": -0.018, "bounty_scale": 1.15}
		_:
			return {"spawn_pressure": 1.0, "elite_delta": 0.0, "bounty_scale": 1.0}


func _load_combat_weapons_config() -> void:
	_combat_weapons_cfg = {
		"starter_sword": {
			"damage": PLAYER_ATTACK_DAMAGE,
			"range": PLAYER_ATTACK_RANGE,
			"cooldown_ms": PLAYER_ATTACK_COOLDOWN_MS,
			"knockback": PLAYER_ATTACK_KNOCKBACK,
			"hitstop_sec": PLAYER_ATTACK_HITSTOP_SEC,
			"crit_chance": PLAYER_ATTACK_CRIT_CHANCE,
			"crit_mult": PLAYER_ATTACK_CRIT_MULT
		}
	}
	var f: FileAccess = FileAccess.open(COMBAT_WEAPONS_CFG_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		var dd: Dictionary = parsed
		if dd.get("weapons") is Dictionary:
			_combat_weapons_cfg = (dd["weapons"] as Dictionary).duplicate(true)


func _load_combat_enemies_config() -> void:
	_combat_enemies_cfg = {"mine_profiles": []}
	var f: FileAccess = FileAccess.open(COMBAT_ENEMIES_CFG_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		var dd: Dictionary = parsed
		if dd.get("mine_profiles") is Array:
			_combat_enemies_cfg = dd.duplicate(true)


func _pick_enemy_profile_for_depth(depth: int) -> Dictionary:
	var profiles: Array = _combat_enemies_cfg.get("mine_profiles", [])
	for p in profiles:
		if not (p is Dictionary):
			continue
		var d: Dictionary = p
		var dmin: int = int(d.get("depth_min", 0))
		var dmax: int = int(d.get("depth_max", 999))
		if depth >= dmin and depth <= dmax:
			return d
	return {}


func _find_enemy_profile_by_id(profile_id: String) -> Dictionary:
	var pid: String = profile_id.strip_edges()
	if pid.is_empty():
		return {}
	var profiles: Array = _combat_enemies_cfg.get("mine_profiles", [])
	for p in profiles:
		if not (p is Dictionary):
			continue
		var d: Dictionary = p
		if str(d.get("id", "")).strip_edges() == pid:
			return d
	return {}


func _pick_weighted_drop_item(entries: Variant, fallback: String) -> String:
	if not (entries is Array):
		return fallback
	var arr: Array = entries
	var total: float = 0.0
	for e in arr:
		if e is Dictionary:
			total += maxf(0.0, float((e as Dictionary).get("weight", 0.0)))
	if total <= 0.0:
		return fallback
	var roll: float = randf() * total
	var acc: float = 0.0
	for e in arr:
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		acc += maxf(0.0, float(d.get("weight", 0.0)))
		if roll <= acc:
			var item_id: String = str(d.get("item", fallback)).strip_edges()
			return item_id if not item_id.is_empty() else fallback
	return fallback


func _weapon_profile() -> Dictionary:
	var w: Dictionary = _combat_weapons_cfg.get(_active_weapon_id, {})
	if w.is_empty():
		w = {
			"damage": PLAYER_ATTACK_DAMAGE,
			"range": PLAYER_ATTACK_RANGE,
			"cooldown_ms": PLAYER_ATTACK_COOLDOWN_MS,
			"knockback": PLAYER_ATTACK_KNOCKBACK,
			"hitstop_sec": PLAYER_ATTACK_HITSTOP_SEC,
			"crit_chance": PLAYER_ATTACK_CRIT_CHANCE,
			"crit_mult": PLAYER_ATTACK_CRIT_MULT
		}
	return w


func _play_hitstop(sec: float) -> void:
	var dur: float = clampf(sec, 0.0, 0.09)
	if dur <= 0.0 or _hitstop_active:
		return
	_hitstop_active = true
	var old_scale: float = Engine.time_scale
	Engine.time_scale = minf(old_scale, 0.18)
	await get_tree().create_timer(dur, true, false, true).timeout
	if is_inside_tree():
		Engine.time_scale = old_scale
		_hitstop_active = false


func _season_index_from_name(season_name: String) -> int:
	match str(season_name).to_lower():
		"spring":
			return 0
		"summer":
			return 1
		"fall":
			return 2
		"winter":
			return 3
		_:
			return 0


func _combat_quest_progress_line() -> String:
	if not QuestSystem:
		return ""
	for qid in QuestSystem.active_quests:
		var q: Dictionary = QuestSystem.quests.get(qid, {})
		if q.is_empty():
			continue
		var objectives: Array = q.get("objectives", [])
		for o in objectives:
			if not (o is Dictionary):
				continue
			var od: Dictionary = o
			if str(od.get("type", "")) != "enemy_kill":
				continue
			var cur: int = int(od.get("current", 0))
			var goal: int = int(od.get("count", 1))
			if goal > 0 and cur < goal and float(cur) / float(goal) >= 0.8:
				if not bool(_quest_near_done_latched.get(str(qid), false)):
					_quest_near_done_latched[str(qid)] = true
					_tip("Almost done: %s" % str(q.get("title", qid)), 0.65)
			return "Quest %s: %d/%d" % [str(q.get("title", qid)), cur, goal]
		_quest_near_done_latched[str(qid)] = false
	return ""


func _streak_tier_label(streak: int) -> String:
	if streak >= 20:
		return "Legend"
	if streak >= 15:
		return "Gold"
	if streak >= 10:
		return "Silver"
	return "Bronze"


func _try_award_streak_medal(streak: int) -> void:
	var medals: Dictionary = {
		5: {"name": "Bronze Medal", "gold": 10},
		10: {"name": "Silver Medal", "gold": 18},
		15: {"name": "Gold Medal", "gold": 28},
		20: {"name": "Mythic Medal", "gold": 45}
	}
	if not medals.has(streak):
		return
	if bool(_streak_medal_awarded.get(streak, false)):
		return
	_streak_medal_awarded[streak] = true
	var d: Dictionary = medals[streak]
	var bonus: int = int(d.get("gold", 0))
	if GameManager:
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus
	_tip("%s unlocked! +%dg" % [str(d.get("name", "Medal")), bonus], 1.0)
	_journal("Streak medal unlocked: %s (+%dg)." % [str(d.get("name", "Medal")), bonus])
	_run_best_tag = str(d.get("name", "Medal"))


func _run_mvp_tag() -> String:
	if _run_elites >= 3:
		return "Elite Hunter"
	if _perfect_guard_chain_best >= 5:
		return "Iron Wall"
	if _daily_peak_streak >= 12:
		return "Combo Master"
	if not _run_best_tag.is_empty() and _run_best_tag != "None":
		return _run_best_tag
	return "Steady"


func _hype_rank_from_points(points: int) -> String:
	if points >= HYPE_STEP * 4:
		return "Mythic"
	if points >= HYPE_STEP * 3:
		return "Legend"
	if points >= HYPE_STEP * 2:
		return "Heroic"
	if points >= HYPE_STEP:
		return "Hot"
	return "Rookie"


func _run_star_rating(kills: int, elites: int, bonus_gold: int, guard_best: int) -> int:
	var score: int = kills + elites * 4 + bonus_gold / 18 + guard_best * 2
	if score >= 48:
		return 5
	if score >= 34:
		return 4
	if score >= 22:
		return 3
	if score >= 12:
		return 2
	return 1
