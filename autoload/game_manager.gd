extends Node

# Game state management
var player_data = {
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
var journal_world_event_feed: Array = []
var journal_active_story_hotspot: Dictionary = {}

# Time system
var current_time = 6.0  # Start at 6 AM
var time_speed = 10.0  # Seconds per game minute
var day_length = 20.0  # Minutes per game day (real time)

# Game signals
signal time_changed(new_time)
signal day_changed(new_day)
signal season_changed(new_season)
signal hp_changed(cur_hp, max_hp)

func _ready():
	pass

func _process(delta):
	# Update time
	current_time += delta / 60.0 * time_speed

	# Stamina regen (per second)
	var smax: float = float(player_data.get("stamina_max", 100.0))
	var scur: float = float(player_data.get("stamina", smax))
	var regen_mult: float = float(player_data.get("stamina_regen_mult", 1.0))
	if scur < smax:
		player_data.stamina = minf(smax, scur + delta * 0.35 * regen_mult)

	if current_time >= 24.0:
		current_time = 0.0
		advance_day()

	time_changed.emit(current_time)

func advance_day():
	player_data.day += 1
	day_changed.emit(player_data.day)

	if player_data.day > 28:
		player_data.day = 1
		advance_season()

func advance_season():
	var seasons = ["spring", "summer", "fall", "winter"]
	var sid: String = str(player_data.season).to_lower().strip_edges()
	var current_index: int = seasons.find(sid)
	if current_index < 0:
		current_index = 0
		player_data.season = seasons[0]
	current_index = (current_index + 1) % 4
	player_data.season = seasons[current_index]
	player_data.year += 1
	season_changed.emit(player_data.season)

func try_consume_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	var s: float = float(player_data.get("stamina", 0.0))
	if s < amount:
		return false
	player_data.stamina = s - amount
	return true

func restore_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	var smax: float = float(player_data.get("stamina_max", 100.0))
	var scur: float = float(player_data.get("stamina", 0.0))
	player_data.stamina = minf(smax, scur + amount)

func get_stamina_ratio() -> float:
	var smax: float = float(player_data.get("stamina_max", 100.0))
	return float(player_data.get("stamina", 0.0)) / maxf(1.0, smax)


func apply_damage(amount: float) -> bool:
	if amount <= 0.0:
		return true
	var hp_max: float = maxf(1.0, float(player_data.get("hp_max", 100.0)))
	var hp_cur: float = float(player_data.get("hp", hp_max))
	hp_cur = maxf(0.0, hp_cur - amount)
	player_data["hp"] = hp_cur
	hp_changed.emit(hp_cur, hp_max)
	return hp_cur > 0.0


func heal_hp(amount: float) -> void:
	if amount <= 0.0:
		return
	var hp_max: float = maxf(1.0, float(player_data.get("hp_max", 100.0)))
	var hp_cur: float = float(player_data.get("hp", hp_max))
	player_data["hp"] = minf(hp_max, hp_cur + amount)
	hp_changed.emit(float(player_data.get("hp", hp_max)), hp_max)

func get_time_string() -> String:
	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60)
	var am_pm = "AM" if hours < 12 else "PM"
	var display_hours = hours if hours <= 12 else hours - 12
	display_hours = 12 if display_hours == 0 else display_hours
	return "%02d:%02d %s" % [display_hours, minutes, am_pm]


## 24h clock for zh_CN; 12h AM/PM for English (`LocaleSettings.LOCALE_EN`).
func get_time_string_localized(locale_code: String) -> String:
	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60)
	if locale_code == "en":
		return get_time_string()
	return "%02d:%02d" % [hours, minutes]
