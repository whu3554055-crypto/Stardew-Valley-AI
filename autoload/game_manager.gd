extends Node
## GameManager - Global game state management singleton.
## Handles player data, time system, stamina, HP, and progression tracking.

# === 成员变量 ===

## Player game state data
var player_data: Dictionary = {
	"gold": 500,
	"day": 1,
	"season": "spring",
	"year": 1,
	"stamina": 100.0,
	"stamina_max": 100.0,
	"stamina_regen_mult": 1.0,
	"hp": 100.0,
	"hp_max": 100.0
}

## Survives `Main` unload so `world_farm` saves can include journal fields (B2).
var journal_world_event_feed: Array[String] = []
var journal_active_story_hotspot: Dictionary = {}

## Current in-game time (24-hour format, e.g., 6.0 = 6:00 AM)
var current_time: float = 6.0

## Time progression speed (seconds per game minute)
var time_speed: float = 10.0

## Real-time minutes per game day
var day_length: float = 20.0

# === 信号 ===

## Emitted when in-game time changes
signal time_changed(new_time: float)

## Emitted when day advances
signal day_changed(new_day: int)

## Emitted when season changes
signal season_changed(new_season: String)

## Emitted when player HP changes
signal hp_changed(cur_hp: float, max_hp: float)

# === 生命周期方法 ===

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Update time
	current_time += delta / 60.0 * time_speed

	# Stamina regen (per second)
	var smax: float = float(player_data.get("stamina_max", 100.0))
	var scur: float = float(player_data.get("stamina", smax))
	var regen_mult: float = float(player_data.get("stamina_regen_mult", 1.0))
	if scur < smax:
		player_data["stamina"] = minf(smax, scur + delta * 0.35 * regen_mult)

	if current_time >= 24.0:
		current_time = 0.0
		advance_day()

	time_changed.emit(current_time)

# === 公共方法 ===

## Advance to the next day
func advance_day() -> void:
	player_data["day"] += 1
	day_changed.emit(player_data["day"])

	if player_data["day"] > 28:
		player_data["day"] = 1
		advance_season()

## Advance to the next season
func advance_season() -> void:
	var seasons: Array[String] = ["spring", "summer", "fall", "winter"]
	var sid: String = str(player_data.get("season", "spring")).to_lower().strip_edges()
	var current_index: int = seasons.find(sid)
	if current_index < 0:
		current_index = 0
		player_data["season"] = seasons[0]
	current_index = (current_index + 1) % 4
	player_data["season"] = seasons[current_index]
	player_data["year"] += 1
	season_changed.emit(player_data["season"])

## Attempt to consume stamina. Returns false if insufficient.
func try_consume_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	var s: float = float(player_data.get("stamina", 0.0))
	if s < amount:
		return false
	player_data["stamina"] = s - amount
	return true

## Restore stamina up to maximum
func restore_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	var smax: float = float(player_data.get("stamina_max", 100.0))
	var scur: float = float(player_data.get("stamina", 0.0))
	player_data.stamina = minf(smax, scur + amount)

## Get current stamina as a ratio (0.0 to 1.0)
func get_stamina_ratio() -> float:
	var smax: float = float(player_data.get("stamina_max", 100.0))
	return float(player_data.get("stamina", 0.0)) / maxf(1.0, smax)


## Apply damage to player HP. Returns false if HP reaches 0.
func apply_damage(amount: float) -> bool:
	if amount <= 0.0:
		return true
	var hp_max: float = maxf(1.0, float(player_data.get("hp_max", 100.0)))
	var hp_cur: float = float(player_data.get("hp", hp_max))
	hp_cur = maxf(0.0, hp_cur - amount)
	player_data["hp"] = hp_cur
	hp_changed.emit(hp_cur, hp_max)
	return hp_cur > 0.0


## Heal player HP
func heal_hp(amount: float) -> void:
	if amount <= 0.0:
		return
	var hp_max: float = maxf(1.0, float(player_data.get("hp_max", 100.0)))
	var hp_cur: float = float(player_data.get("hp", hp_max))
	player_data["hp"] = minf(hp_max, hp_cur + amount)
	hp_changed.emit(float(player_data.get("hp", hp_max)), hp_max)

## Get formatted time string (12-hour AM/PM format)
func get_time_string() -> String:
	var hours: int = int(current_time)
	var minutes: int = int((current_time - hours) * 60)
	var am_pm: String = "AM" if hours < 12 else "PM"
	var display_hours: int = hours if hours <= 12 else hours - 12
	display_hours = 12 if display_hours == 0 else display_hours
	return "%02d:%02d %s" % [display_hours, minutes, am_pm]


## 24h clock for zh_CN; 12h AM/PM for English (`LocaleSettings.LOCALE_EN`).
func get_time_string_localized(locale_code: String) -> String:
	var hours: int = int(current_time)
	var minutes: int = int((current_time - hours) * 60)
	if locale_code == "en":
		return get_time_string()
	return "%02d:%02d" % [hours, minutes]


## Ensure progression data structures exist
func ensure_progression_subtrees() -> void:
	if not player_data.has("npc_friendship") or not (player_data["npc_friendship"] is Dictionary):
		player_data["npc_friendship"] = {}
	if not player_data.has("skill_xp") or not (player_data["skill_xp"] is Dictionary):
		player_data["skill_xp"] = {}
	if not player_data.has("daily_narrative_snapshot") or not (player_data["daily_narrative_snapshot"] is Dictionary):
		player_data["daily_narrative_snapshot"] = {}


## Get NPC friendship level
func get_npc_friendship(npc_id: String) -> int:
	ensure_progression_subtrees()
	var d: Dictionary = player_data["npc_friendship"] as Dictionary
	return int(d.get(npc_id, 0))


## Add friendship points to NPC
func add_npc_friendship(npc_id: String, delta: int) -> int:
	if npc_id.is_empty() or delta == 0:
		return get_npc_friendship(npc_id)
	ensure_progression_subtrees()
	var d: Dictionary = player_data["npc_friendship"] as Dictionary
	var next: int = int(d.get(npc_id, 0)) + delta
	d[npc_id] = next
	return next


## Get skill XP
func get_skill_xp(skill_id: String) -> int:
	ensure_progression_subtrees()
	var sid: String = skill_id.strip_edges().to_lower()
	if sid.is_empty():
		sid = "general"
	var d: Dictionary = player_data["skill_xp"] as Dictionary
	return int(d.get(sid, 0))


## Add XP to skill
func add_skill_xp(skill_id: String, delta: int) -> int:
	if delta == 0:
		return get_skill_xp(skill_id)
	ensure_progression_subtrees()
	var sid: String = skill_id.strip_edges().to_lower()
	if sid.is_empty():
		sid = "general"
	var d: Dictionary = player_data["skill_xp"] as Dictionary
	var next: int = int(d.get(sid, 0)) + delta
	d[sid] = next
	return next
