extends Node
## QuestSystem - Global quest management singleton.
## Handles quest tracking, progression, completion, and rewards.
## Supports both static quests and AI-generated dynamic quests.
##
## Usage Example:
## ```gdscript
## # Get active quests
## var quests = QuestSystem.get_active_quests()
##
## # Complete a quest
## QuestSystem.complete_quest("quest_id")
##
## # Connect signals
## QuestSystem.quest_completed.connect(_on_quest_completed)
## ```

enum QuestStatus {
	NOT_STARTED,
	IN_PROGRESS,
	COMPLETED,
	TURNED_IN,
	FAILED
}

var quests = {}
var active_quests = []
var completed_quests = []
var failed_quests: Array = []
var last_story_quest_day_key = ""
const MANAGED_CHAIN_STEP_1 := "managed_supply_chain_1"
const MANAGED_CHAIN_STEP_2 := "managed_supply_chain_2"
const MANAGED_CHAIN_STEP_3 := "managed_supply_chain_3"
const MANAGED_MINING_CHAIN_STEP_1 := "managed_mining_chain_1"
const MANAGED_CHAIN_FAST_SEC := 900
const MANAGED_CHAIN_STEADY_SEC := 2400
const MANAGED_CHAIN_CONFIG_PATH := "res://data/quests/managed_chain.json"
const MANAGED_CHAIN_TEMPLATES_PATH := "res://data/quests/chain_templates.json"
const MANAGED_CHAIN_DEFAULT_BONUS := {
	"fast": 80,
	"steady": 40,
	"slow": 10
}
const MANAGED_CHAIN_DEFAULT_PULSE_FACTOR := {
	"fast": 1.08,
	"steady": 1.04,
	"slow": 1.02,
	"failed": 0.94
}
const MANAGED_CHAIN_DEFAULT_PULSE_ITEMS := ["parsnip", "parsnip_seeds", "bread", "basic_fertilizer", "worm_bait"]
const MANAGED_CHAIN_DEFAULT_FAILURE_ITEMS := ["parsnip", "parsnip_seeds", "bread"]
const MANAGED_CHAIN_DEFAULT_TIMEOUT_DAYS := 1
var managed_chain_timing: Dictionary = {
	"fast_sec": MANAGED_CHAIN_FAST_SEC,
	"steady_sec": MANAGED_CHAIN_STEADY_SEC
}
var managed_chain_bonus_gold: Dictionary = MANAGED_CHAIN_DEFAULT_BONUS.duplicate(true)
var managed_chain_pulse_factor: Dictionary = MANAGED_CHAIN_DEFAULT_PULSE_FACTOR.duplicate(true)
var managed_chain_pulse_items: Array = MANAGED_CHAIN_DEFAULT_PULSE_ITEMS.duplicate()
var managed_chain_failure_items: Array = MANAGED_CHAIN_DEFAULT_FAILURE_ITEMS.duplicate()
var managed_chain_failure: Dictionary = {
	"timeout_days": MANAGED_CHAIN_DEFAULT_TIMEOUT_DAYS,
	"bonus_gold": 0
}
var managed_chain_streak: Dictionary = {
	"enabled": true,
	"bonus_per_stack": 0.1,
	"max_stacks": 3
}
var chain_templates: Dictionary = {}
var chain_first_step_by_chain: Dictionary = {}
var chain_next_by_step_id: Dictionary = {}
var chain_id_by_step_id: Dictionary = {}
var last_chain_focus_items: Array = []
var chain_cooldown_days: Dictionary = {}
var chain_daily_pick_policy: String = "theme_priority_then_rotate"
var chain_enabled_map: Dictionary = {}

signal quest_started(quest_id)
signal quest_updated(quest_id, objective)
signal quest_completed(quest_id)
signal managed_chain_resolved(outcome)
signal managed_chain_state_changed(quest_id, state)
signal quest_impact_applied(quest_id, impact)
signal quest_failed(quest_id, reason)
signal quest_journal_refresh_requested()

func _ready():
	_load_managed_chain_config()
	_load_chain_templates()
	initialize_quests()
	call_deferred("_connect_world_router_quest_ui")


func _connect_world_router_quest_ui() -> void:
	if WorldRouter and not WorldRouter.world_changed.is_connected(_on_world_changed_quest_refresh):
		WorldRouter.world_changed.connect(_on_world_changed_quest_refresh)


func _on_world_changed_quest_refresh(_scene_path: String) -> void:
	call_deferred("_emit_quest_journal_refresh")


func _emit_quest_journal_refresh() -> void:
	quest_journal_refresh_requested.emit()

func _load_managed_chain_config() -> void:
	var f: FileAccess = FileAccess.open(MANAGED_CHAIN_CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("QuestSystem: missing %s — using managed chain defaults" % MANAGED_CHAIN_CONFIG_PATH)
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_warning("QuestSystem: invalid %s — using managed chain defaults" % MANAGED_CHAIN_CONFIG_PATH)
		return
	var d: Dictionary = json.data
	var timing: Dictionary = d.get("timing", {})
	var bonus: Dictionary = d.get("bonus_gold", {})
	var pulse: Dictionary = d.get("economy_pulse", {})
	var pulse_factor: Dictionary = pulse.get("factor", {})
	var failure: Dictionary = d.get("failure", {})
	var fast_sec: int = int(timing.get("fast_sec", MANAGED_CHAIN_FAST_SEC))
	var steady_sec: int = int(timing.get("steady_sec", MANAGED_CHAIN_STEADY_SEC))
	managed_chain_timing["fast_sec"] = maxi(60, fast_sec)
	managed_chain_timing["steady_sec"] = maxi(int(managed_chain_timing["fast_sec"]) + 1, steady_sec)
	managed_chain_bonus_gold["fast"] = maxi(0, int(bonus.get("fast", MANAGED_CHAIN_DEFAULT_BONUS["fast"])))
	managed_chain_bonus_gold["steady"] = maxi(0, int(bonus.get("steady", MANAGED_CHAIN_DEFAULT_BONUS["steady"])))
	managed_chain_bonus_gold["slow"] = maxi(0, int(bonus.get("slow", MANAGED_CHAIN_DEFAULT_BONUS["slow"])))
	managed_chain_pulse_factor["fast"] = clampf(float(pulse_factor.get("fast", MANAGED_CHAIN_DEFAULT_PULSE_FACTOR["fast"])), 1.0, 1.5)
	managed_chain_pulse_factor["steady"] = clampf(float(pulse_factor.get("steady", MANAGED_CHAIN_DEFAULT_PULSE_FACTOR["steady"])), 1.0, 1.5)
	managed_chain_pulse_factor["slow"] = clampf(float(pulse_factor.get("slow", MANAGED_CHAIN_DEFAULT_PULSE_FACTOR["slow"])), 1.0, 1.5)
	managed_chain_pulse_factor["failed"] = clampf(float(pulse_factor.get("failed", MANAGED_CHAIN_DEFAULT_PULSE_FACTOR["failed"])), 0.5, 1.0)
	managed_chain_pulse_items.clear()
	var pulse_items_raw: Array = pulse.get("items", MANAGED_CHAIN_DEFAULT_PULSE_ITEMS)
	for it in pulse_items_raw:
		var item_id: String = str(it).strip_edges()
		if item_id.is_empty():
			continue
		managed_chain_pulse_items.append(item_id)
	if managed_chain_pulse_items.is_empty():
		managed_chain_pulse_items = MANAGED_CHAIN_DEFAULT_PULSE_ITEMS.duplicate()
	managed_chain_failure_items.clear()
	var failure_items_raw: Array = pulse.get("failure_items", MANAGED_CHAIN_DEFAULT_FAILURE_ITEMS)
	for it in failure_items_raw:
		var item_id2: String = str(it).strip_edges()
		if item_id2.is_empty():
			continue
		managed_chain_failure_items.append(item_id2)
	if managed_chain_failure_items.is_empty():
		managed_chain_failure_items = MANAGED_CHAIN_DEFAULT_FAILURE_ITEMS.duplicate()
	managed_chain_failure["timeout_days"] = maxi(1, int(failure.get("timeout_days", MANAGED_CHAIN_DEFAULT_TIMEOUT_DAYS)))
	managed_chain_failure["bonus_gold"] = int(failure.get("bonus_gold", 0))
	var streak: Dictionary = d.get("streak", {})
	managed_chain_streak["enabled"] = bool(streak.get("enabled", true))
	managed_chain_streak["bonus_per_stack"] = clampf(float(streak.get("bonus_per_stack", 0.1)), 0.0, 0.5)
	managed_chain_streak["max_stacks"] = maxi(1, int(streak.get("max_stacks", 3)))

func _load_chain_templates() -> void:
	chain_templates.clear()
	chain_first_step_by_chain.clear()
	chain_next_by_step_id.clear()
	chain_id_by_step_id.clear()
	chain_enabled_map.clear()
	var f: FileAccess = FileAccess.open(MANAGED_CHAIN_TEMPLATES_PATH, FileAccess.READ)
	if f == null:
		push_warning("QuestSystem: missing %s — managed chain templates fallback to built-in IDs" % MANAGED_CHAIN_TEMPLATES_PATH)
		_apply_builtin_chain_templates()
		return
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_warning("QuestSystem: invalid %s — chain templates ignored" % MANAGED_CHAIN_TEMPLATES_PATH)
		_apply_builtin_chain_templates()
		return
	var d: Dictionary = json.data
	chain_daily_pick_policy = str(d.get("daily_pick_policy", "theme_priority_then_rotate"))
	var chains: Array = d.get("chains", [])
	for c in chains:
		if not (c is Dictionary):
			continue
		var cd: Dictionary = c
		var chain_id: String = str(cd.get("id", "")).strip_edges()
		var steps: Array = cd.get("steps", [])
		if chain_id.is_empty() or steps.is_empty():
			continue
		chain_cooldown_days[chain_id] = maxi(0, int(cd.get("cooldown_days", 0)))
		chain_templates[chain_id] = cd.duplicate(true)
		chain_enabled_map[chain_id] = true
		var prev_step_id: String = ""
		for i in range(steps.size()):
			if not (steps[i] is Dictionary):
				continue
			var step_d: Dictionary = steps[i]
			var sid: String = str(step_d.get("id", "")).strip_edges()
			if sid.is_empty():
				continue
			chain_id_by_step_id[sid] = chain_id
			if i == 0:
				chain_first_step_by_chain[chain_id] = sid
			if not prev_step_id.is_empty():
				chain_next_by_step_id[prev_step_id] = sid
			prev_step_id = sid
	if chain_templates.is_empty():
		_apply_builtin_chain_templates()

func _apply_builtin_chain_templates() -> void:
	chain_templates = {
		"managed_supply_chain": {
			"id": "managed_supply_chain",
			"display_name": "Village Supply Chain",
			"preferred_themes": ["joyful"],
			"steps": [
				{"id": MANAGED_CHAIN_STEP_1, "title": "Village Request I: Fresh Produce", "description": "Harvest 2 parsnips so the town can prepare a shared meal.", "objective": {"type": "harvest", "crop_id": "parsnip", "count": 2}, "reward": {"gold": 60, "items": ["bread:1"]}},
				{"id": MANAGED_CHAIN_STEP_2, "title": "Village Request II: Deliver the News", "description": "Talk to Pierre and tell him the produce is ready.", "objective": {"type": "talk", "npc_id": "pierre", "count": 1}, "reward": {"gold": 80, "items": ["worm_bait:2"]}},
				{"id": MANAGED_CHAIN_STEP_3, "title": "Village Request III: Market Momentum", "description": "Sell goods worth 120g to complete today's village supply loop.", "objective": {"type": "earn_gold", "count": 120}, "reward": {"gold": 120, "items": ["basic_fertilizer:1"]}}
			]
		},
		"managed_mining_chain": {
			"id": "managed_mining_chain",
			"display_name": "Mining Support Chain",
			"preferred_themes": ["adventure"],
			"steps": [
				{"id": MANAGED_MINING_CHAIN_STEP_1, "title": "Mine Request I: Ore Rush", "description": "Mine ore 3 times to help replenish workshop materials.", "objective": {"type": "mine_ore", "count": 3}, "reward": {"gold": 70, "items": ["coal:2"]}}
			]
		}
	}
	chain_cooldown_days = {
		"managed_supply_chain": 1,
		"managed_mining_chain": 1
	}
	chain_first_step_by_chain = {
		"managed_supply_chain": MANAGED_CHAIN_STEP_1,
		"managed_mining_chain": MANAGED_MINING_CHAIN_STEP_1
	}
	chain_next_by_step_id = {
		MANAGED_CHAIN_STEP_1: MANAGED_CHAIN_STEP_2,
		MANAGED_CHAIN_STEP_2: MANAGED_CHAIN_STEP_3
	}
	chain_id_by_step_id = {
		MANAGED_CHAIN_STEP_1: "managed_supply_chain",
		MANAGED_CHAIN_STEP_2: "managed_supply_chain",
		MANAGED_CHAIN_STEP_3: "managed_supply_chain",
		MANAGED_MINING_CHAIN_STEP_1: "managed_mining_chain"
	}
	chain_enabled_map = {
		"managed_supply_chain": true,
		"managed_mining_chain": true
	}

func initialize_quests():
	# Tutorial quest
	quests["tutorial_plant"] = {
		"id": "tutorial_plant",
		"title": "Your First Crop",
		"description": "Plant a parsnip seed and water it.",
		"objectives": [
			{"type": "plant", "crop_id": "parsnip", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 50, "items": ["parsnip_seeds:5"]}
	}

	quests["tutorial_harvest"] = {
		"id": "tutorial_harvest",
		"title": "First Harvest",
		"description": "Harvest your first crop.",
		"objectives": [
			{"type": "harvest", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 100, "items": []}
	}

	quests["earn_gold"] = {
		"id": "earn_gold",
		"title": "Entrepreneur",
		"description": "Earn 1000 gold by selling items at the shop.",
		"objectives": [
			{"type": "earn_gold", "count": 1000, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 200, "items": []}
	}

	quests["intro_fish"] = {
		"id": "intro_fish",
		"title": "First Catch",
		"description": "Catch real fish (not junk) 3 times — river east, ocean south.",
		"objectives": [
			{"type": "fish_caught", "count": 3, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["worm_bait:5"]}
	}

	quests["intro_mine"] = {
		"id": "intro_mine",
		"title": "Into the Stone",
		"description": "Mine ore 5 times.",
		"objectives": [
			{"type": "mine_ore", "count": 5, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 60, "items": ["coal:3"]}
	}

	quests["intro_smelt"] = {
		"id": "intro_smelt",
		"title": "Hot Metal",
		"description": "Smelt any bar at the furnace once.",
		"objectives": [
			{"type": "smelt_bar", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["coal:2"]}
	}

	quests["intro_eat"] = {
		"id": "intro_eat",
		"title": "A Bite to Eat",
		"description": "Eat something to recover energy (select food, press E).",
		"objectives": [
			{"type": "consume_food", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 25, "items": ["bread:2"]}
	}

	quests["intro_cook"] = {
		"id": "intro_cook",
		"title": "Home Cooking",
		"description": "Cook a meal at the kitchen counter (empty hands, E).",
		"objectives": [
			{"type": "cook_meal", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 35, "items": ["bread:1"]}
	}

	quests["intro_chop"] = {
		"id": "intro_chop",
		"title": "Lumberjack",
		"description": "Chop wood in the forest (west) with the axe equipped.",
		"objectives": [
			{"type": "chop_wood", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 30, "items": ["coal:2"]}
	}

	quests["intro_craft"] = {
		"id": "intro_craft",
		"title": "Workbench",
		"description": "Craft something at the workbench (east of kitchen, empty hands, E).",
		"objectives": [
			{"type": "craft_item", "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 40, "items": ["wood_log:3"]}
	}

	quests["intro_combat"] = {
		"id": "intro_combat",
		"title": "First Blood",
		"description": "Defeat 3 enemies in the mine.",
		"objectives": [
			{"type": "enemy_kill", "count": 3, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 70, "items": ["coal:2"]}
	}

	quests["deep_mine_hunt"] = {
		"id": "deep_mine_hunt",
		"title": "Deep Mine Hunt",
		"description": "Defeat 5 enemies in deep mine layers (depth >= 1).",
		"objectives": [
			{"type": "enemy_kill", "count": 5, "current": 0, "min_depth": 1}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 140, "items": ["iron_ore:2"]}
	}

	quests["elite_slayer"] = {
		"id": "elite_slayer",
		"title": "Elite Slayer",
		"description": "Defeat 2 elite mine enemies.",
		"objectives": [
			{"type": "enemy_kill", "count": 2, "current": 0, "enemy_id": "mine_slime_elite"}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 220, "items": ["silver_ore:2"]}
	}

	quests["streak_hunter"] = {
		"id": "streak_hunter",
		"title": "Streak Hunter",
		"description": "Reach a kill streak of 8 in the mine.",
		"objectives": [
			{"type": "enemy_kill", "count": 1, "current": 0, "min_streak": 8}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 180, "items": ["coal:4"]}
	}

	quests["elite_slayer_ii"] = {
		"id": "elite_slayer_ii",
		"title": "Elite Slayer II",
		"description": "Defeat 4 elite enemies in deep mine layers (depth >= 2).",
		"objectives": [
			{"type": "enemy_kill", "count": 4, "current": 0, "enemy_id": "mine_slime_elite", "min_depth": 2}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 320, "items": ["gold_ore:2"]}
	}

	quests["combat_mastery"] = {
		"id": "combat_mastery",
		"title": "Combat Mastery",
		"description": "Defeat 35 enemies in total.",
		"objectives": [
			{"type": "enemy_kill", "count": 35, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 420, "items": ["gold_ore:3"]}
	}

	quests["flawless_miner"] = {
		"id": "flawless_miner",
		"title": "Flawless Miner",
		"description": "Defeat 12 mine enemies in one day without collapsing.",
		"objectives": [
			{"type": "enemy_kill", "count": 12, "current": 0, "max_daily_defeats": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 500, "items": ["gold_ore:2", "silver_ore:2"]}
	}

	_register_chain_quests_from_templates()

func _register_chain_quests_from_templates() -> void:
	for chain_id in chain_templates.keys():
		var cd: Dictionary = chain_templates[chain_id]
		var steps: Array = cd.get("steps", [])
		_register_chain_steps(str(chain_id), steps, "managed_story_chain")

func _register_chain_steps(chain_id: String, steps: Array, source_tag: String) -> void:
	for i in range(steps.size()):
		if not (steps[i] is Dictionary):
			continue
		var step: Dictionary = steps[i]
		var sid: String = str(step.get("id", "")).strip_edges()
		if sid.is_empty():
			continue
		var objective_raw: Dictionary = step.get("objective", {})
		var objective: Dictionary = objective_raw.duplicate(true)
		objective["current"] = 0
		var qd: Dictionary = {
			"id": sid,
			"title": str(step.get("title", sid)),
			"description": str(step.get("description", "")),
			"objectives": [objective],
			"status": QuestStatus.NOT_STARTED,
			"reward": step.get("reward", {"gold": 0, "items": []}),
			"source": source_tag,
			"chain_id": chain_id
		}
		var next_sid: String = ""
		if i + 1 < steps.size() and steps[i + 1] is Dictionary:
			next_sid = str((steps[i + 1] as Dictionary).get("id", "")).strip_edges()
		if next_sid.is_empty():
			next_sid = str(chain_next_by_step_id.get(sid, ""))
		if not next_sid.is_empty():
			qd["chain_next"] = next_sid
		quests[sid] = qd

func register_runtime_chain_template(chain_def: Dictionary, source_tag: String = "runtime_agentic") -> Dictionary:
	var incoming: Dictionary = chain_def.duplicate(true)
	var chain_id: String = str(incoming.get("id", "")).strip_edges()
	if chain_id.is_empty():
		return {"ok": false, "error": "missing_chain_id"}
	if chain_templates.has(chain_id):
		return {"ok": false, "error": "chain_exists"}
	var steps: Array = incoming.get("steps", [])
	if steps.is_empty():
		return {"ok": false, "error": "missing_steps"}
	var first_sid: String = ""
	var prev_sid: String = ""
	for i in range(steps.size()):
		if not (steps[i] is Dictionary):
			return {"ok": false, "error": "step_not_dict"}
		var s: Dictionary = (steps[i] as Dictionary).duplicate(true)
		var sid: String = str(s.get("id", "")).strip_edges()
		if sid.is_empty():
			return {"ok": false, "error": "missing_step_id"}
		if quests.has(sid):
			return {"ok": false, "error": "step_exists:%s" % sid}
		if i == 0:
			first_sid = sid
		if not prev_sid.is_empty():
			chain_next_by_step_id[prev_sid] = sid
		chain_id_by_step_id[sid] = chain_id
		prev_sid = sid
		steps[i] = s
	if first_sid.is_empty():
		return {"ok": false, "error": "missing_first_step"}
	incoming["steps"] = steps
	incoming["cooldown_days"] = maxi(0, int(incoming.get("cooldown_days", 1)))
	chain_templates[chain_id] = incoming
	chain_cooldown_days[chain_id] = int(incoming.get("cooldown_days", 1))
	chain_first_step_by_chain[chain_id] = first_sid
	chain_enabled_map[chain_id] = true
	_register_chain_steps(chain_id, steps, source_tag)
	return {"ok": true, "chain_id": chain_id}

func set_chain_runtime_enabled(chain_id: String, enabled: bool) -> void:
	if chain_id.is_empty():
		return
	chain_enabled_map[chain_id] = enabled

func is_chain_runtime_enabled(chain_id: String) -> bool:
	if chain_id.is_empty():
		return false
	return bool(chain_enabled_map.get(chain_id, true))

func _objective_goal_max(o: Dictionary) -> int:
	if o.has("count"):
		return int(o["count"])
	if o.has("amount"):
		return int(o["amount"])
	return 1

func start_quest(quest_id: String):
	if not quests.has(quest_id):
		return

	var quest = quests[quest_id]
	if quest.status == QuestStatus.NOT_STARTED:
		quest.status = QuestStatus.IN_PROGRESS
		quest["started_at"] = Time.get_unix_time_from_system()
		if str(quest.get("source", "")) == "managed_story_chain" and not quest.has("chain_started_at"):
			quest["chain_started_at"] = int(quest["started_at"])
		if str(quest.get("source", "")) == "managed_story_chain" and not quest.has("chain_started_day_index"):
			quest["chain_started_day_index"] = _current_day_index()
		if str(quest.get("source", "")) == "managed_story_chain":
			var cur_day_idx: int = _current_day_index()
			quest["started_day_index"] = cur_day_idx
			quest["deadline_day_index"] = cur_day_idx + int(managed_chain_failure.get("timeout_days", MANAGED_CHAIN_DEFAULT_TIMEOUT_DAYS))
			quest["managed_state"] = "active"
			managed_chain_state_changed.emit(quest_id, "active")
		if not active_quests.has(quest_id):
			active_quests.append(quest_id)
		quest_started.emit(quest_id)

func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1):
	if not quests.has(quest_id):
		return

	var quest = quests[quest_id]
	if quest.status != QuestStatus.IN_PROGRESS:
		return

	if objective_index < 0 or objective_index >= quest.objectives.size():
		return
	var objective = quest.objectives[objective_index]
	var goal: int = _objective_goal_max(objective)
	objective.current += amount
	if objective.current >= goal:
		objective.current = goal
		check_quest_completion(quest_id)

	quest_updated.emit(quest_id, objective_index)

func check_quest_completion(quest_id: String):
	var quest = quests[quest_id]

	for objective in quest.objectives:
		if int(objective.get("current", 0)) < _objective_goal_max(objective):
			return

	# All objectives complete
	quest.status = QuestStatus.COMPLETED
	complete_quest(quest_id)

func complete_quest(quest_id: String):
	var quest = quests[quest_id]
	quest.status = QuestStatus.COMPLETED
	quest["completed_at"] = Time.get_unix_time_from_system()

	# Give rewards
	var reward_data: Dictionary = quest.reward if quest.get("reward") is Dictionary else {}
	var grant_id: String = "quest_reward:%s" % quest_id
	if _claim_reward_grant(grant_id):
		if reward_data.has("gold"):
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + int(reward_data.get("gold", 0))
		if reward_data.has("items"):
			var reward_items: Array = reward_data.get("items", [])
			for item_str in reward_items:
				var parts = item_str.split(":")
				var item_id = parts[0]
				var count = int(parts[1]) if parts.size() > 1 else 1
				var item_template = ItemDatabase.get_item(item_id)
				if item_template.is_empty():
					continue
				for i in range(count):
					InventoryManager.add_item(item_template.duplicate(true))
		_apply_reward_pool(reward_data)
	_apply_quest_outcome_impacts(quest_id, quest, true)

	# Move from active to completed
	active_quests.erase(quest_id)
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
	if AIEconomySystem:
		AIEconomySystem.on_quest_completed(quest)
	_try_advance_managed_chain(quest_id, quest)
	if str(quest.get("source", "")) == "managed_recovery":
		_on_recovery_quest_completed(quest)
	quest_completed.emit(quest_id)

func _apply_quest_outcome_impacts(quest_id: String, quest: Dictionary, success: bool) -> void:
	if bool(quest.get("impact_applied", false)):
		return
	var reward_data: Dictionary = quest.get("reward", {}) if quest.get("reward") is Dictionary else {}
	var impact: Dictionary = {
		"social_delta": _apply_quest_social_impact(quest, reward_data, success),
		"growth_xp": _apply_quest_growth(quest, reward_data, success),
		"success": success
	}
	quest["impact_applied"] = true
	quest_impact_applied.emit(quest_id, impact)

func _apply_quest_social_impact(quest: Dictionary, reward_data: Dictionary, success: bool) -> int:
	var npc_id: String = _resolve_quest_npc(quest)
	if npc_id.is_empty():
		return 0
	var base: int = int(reward_data.get("friendship", 0))
	if base == 0:
		base = 2 + int(reward_data.get("gold", 0)) / 120
	base = clampi(base, 1, 12)
	var delta: int = base if success else -maxi(1, base / 2)
	if NPCTraitSystem and NPCTraitSystem.has_method("update_relationship"):
		NPCTraitSystem.update_relationship(npc_id, "player", delta, "quest_outcome")
	if NPCMemorySystem and NPCMemorySystem.has_method("record_event"):
		var tone: String = "positive" if delta >= 0 else "negative"
		NPCMemorySystem.record_event(
			npc_id,
			"Quest outcome with player: %s (%d)." % ["success" if success else "failed", delta],
			0.6,
			tone,
			["quest", "relationship", str(quest.get("id", ""))]
		)
	return delta

func _resolve_quest_npc(quest: Dictionary) -> String:
	var sid: String = str(quest.get("story_npc_id", "")).strip_edges()
	if not sid.is_empty():
		return sid
	if quest.has("npc_id"):
		var nid: String = str(quest.get("npc_id", "")).strip_edges()
		if not nid.is_empty():
			return nid
	var objectives: Array = quest.get("objectives", [])
	for o in objectives:
		if o is Dictionary:
			var npc: String = str((o as Dictionary).get("npc_id", "")).strip_edges()
			if not npc.is_empty():
				return npc
	return "pierre"

func _apply_quest_growth(quest: Dictionary, reward_data: Dictionary, success: bool) -> int:
	if not GameManager or not GameManager.player_data:
		return 0
	var growth: Dictionary = GameManager.player_data.get("quest_growth", {
		"xp": 0,
		"level": 1,
		"total_completed": 0,
		"total_failed": 0,
		"streak": 0,
		"last_day_index": -1
	})
	var objective_count: int = 0
	if quest.get("objectives") is Array:
		objective_count = (quest.get("objectives") as Array).size()
	var base_xp: int = 4 + objective_count * 3 + int(reward_data.get("gold", 0)) / 80
	base_xp = clampi(base_xp, 2, 30)
	var today: int = _current_day_index()
	if not success:
		growth["streak"] = 0
		growth["total_failed"] = int(growth.get("total_failed", 0)) + 1
		var xp_before: int = int(growth.get("xp", 0))
		var xp_penalty: int = clampi(base_xp, 2, 28)
		growth["xp"] = maxi(0, xp_before - xp_penalty)
		GameManager.player_data["quest_growth"] = growth
		return -xp_penalty
	var xp_gain: int = base_xp
	var last_day: int = int(growth.get("last_day_index", -1))
	if last_day == today - 1:
		growth["streak"] = int(growth.get("streak", 0)) + 1
	elif last_day != today:
		growth["streak"] = 1
	growth["last_day_index"] = today
	growth["total_completed"] = int(growth.get("total_completed", 0)) + 1
	growth["xp"] = int(growth.get("xp", 0)) + xp_gain
	var level: int = int(growth.get("level", 1))
	var threshold: int = level * 100
	while int(growth.get("xp", 0)) >= threshold:
		growth["xp"] = int(growth.get("xp", 0)) - threshold
		level += 1
		threshold = level * 100
	growth["level"] = level
	GameManager.player_data["quest_growth"] = growth
	return xp_gain

func _apply_reward_pool(reward_data: Dictionary) -> void:
	if not reward_data.has("pool"):
		return
	var pool: Dictionary = reward_data.get("pool", {})
	var entries: Array = pool.get("entries", [])
	var draw_count: int = maxi(0, int(pool.get("count", 1)))
	for _i in range(draw_count):
		var item_spec: String = _pick_weighted_pool_item(entries)
		if item_spec.is_empty():
			continue
		_grant_item_spec(item_spec)

func _pick_weighted_pool_item(entries: Array) -> String:
	var total: float = 0.0
	for e in entries:
		if e is Dictionary:
			total += maxf(0.0, float((e as Dictionary).get("weight", 0.0)))
	if total <= 0.0:
		return ""
	var roll: float = randf() * total
	var acc: float = 0.0
	for e in entries:
		if not (e is Dictionary):
			continue
		var ed: Dictionary = e
		acc += maxf(0.0, float(ed.get("weight", 0.0)))
		if roll <= acc:
			return str(ed.get("item", ""))
	return ""

func _grant_item_spec(item_spec: String) -> void:
	var spec: String = item_spec.strip_edges()
	if spec.is_empty():
		return
	var parts: PackedStringArray = spec.split(":")
	var item_id: String = str(parts[0])
	var count: int = int(parts[1]) if parts.size() > 1 else 1
	if not ItemDatabase:
		return
	var item_template = ItemDatabase.get_item(item_id)
	if item_template.is_empty():
		return
	for _i in range(maxi(1, count)):
		InventoryManager.add_item(item_template.duplicate(true))

func _try_advance_managed_chain(quest_id: String, quest: Dictionary) -> void:
	if str(quest.get("source", "")) != "managed_story_chain":
		return
	var chain_id: String = str(quest.get("chain_id", chain_id_by_step_id.get(quest_id, "managed_supply_chain")))
	var next_id: String = str(quest.get("chain_next", ""))
	if next_id.is_empty():
		_resolve_managed_chain_finale(quest, chain_id)
		return
	if not quests.has(next_id):
		return
	var next_q: Dictionary = quests[next_id]
	if int(next_q.get("status", QuestStatus.NOT_STARTED)) != QuestStatus.NOT_STARTED:
		return
	if quest.has("chain_started_at"):
		next_q["chain_started_at"] = int(quest.get("chain_started_at", Time.get_unix_time_from_system()))
		next_q["chain_id"] = chain_id
	start_quest(next_id)

func _resolve_managed_chain_finale(final_quest: Dictionary, chain_id: String) -> void:
	var now_ts: int = int(final_quest.get("completed_at", Time.get_unix_time_from_system()))
	var chain_start: int = int(final_quest.get("chain_started_at", now_ts))
	var elapsed: int = maxi(0, now_ts - chain_start)
	var fast_sec: int = int(managed_chain_timing.get("fast_sec", MANAGED_CHAIN_FAST_SEC))
	var steady_sec: int = int(managed_chain_timing.get("steady_sec", MANAGED_CHAIN_STEADY_SEC))
	var pace: String = "steady"
	var bonus_gold: int = int(managed_chain_bonus_gold.get("steady", 40))
	if elapsed <= fast_sec:
		pace = "fast"
		bonus_gold = int(managed_chain_bonus_gold.get("fast", 80))
	elif elapsed > steady_sec:
		pace = "slow"
		bonus_gold = int(managed_chain_bonus_gold.get("slow", 10))
	var streak_mult: float = 1.0
	if bool(managed_chain_streak.get("enabled", true)):
		var st: int = _compute_chain_streak_bonus(chain_id)
		streak_mult += float(managed_chain_streak.get("bonus_per_stack", 0.1)) * st
	bonus_gold = int(round(float(bonus_gold) * streak_mult))

	if GameManager and GameManager.player_data and _claim_reward_grant("managed_chain_bonus:%s:%d" % [chain_id, _current_day_index()]):
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus_gold

	if AIEconomySystem and AIEconomySystem.has_method("pulse_story_completion"):
		var factor: float = float(managed_chain_pulse_factor.get(pace, managed_chain_pulse_factor.get("steady", 1.04)))
		AIEconomySystem.pulse_story_completion(pace, bonus_gold, factor, managed_chain_pulse_items)
	last_chain_focus_items = managed_chain_pulse_items.duplicate()

	managed_chain_resolved.emit({
		"result": "success",
		"pace": pace,
		"elapsed_sec": elapsed,
		"bonus_gold": bonus_gold,
		"chain_id": chain_id,
		"streak_mult": streak_mult
	})
	_set_chain_cooldown(chain_id)

func on_day_passed() -> void:
	var today: int = _current_day_index()
	var should_fail := false
	var fail_qid := ""
	for qid in active_quests:
		var q: Dictionary = quests.get(qid, {})
		if str(q.get("source", "")) != "managed_story_chain":
			continue
		var deadline: int = int(q.get("deadline_day_index", today))
		if today > deadline:
			should_fail = true
			fail_qid = str(qid)
			break
		if today == deadline and str(q.get("managed_state", "active")) != "urgent":
			q["managed_state"] = "urgent"
			managed_chain_state_changed.emit(str(qid), "urgent")
	if should_fail:
		_fail_managed_chain_timeout(fail_qid, today)

func get_managed_chain_status_tag(quest_id: String) -> String:
	var q: Dictionary = quests.get(quest_id, {})
	if q.is_empty() or str(q.get("source", "")) != "managed_story_chain":
		return ""
	return str(q.get("managed_state", "active"))

func get_chain_focus_items() -> Array:
	return last_chain_focus_items.duplicate()

func activate_chain_for_narrative(narrative: Dictionary) -> void:
	var pick_chain: String = "managed_supply_chain"
	var theme: String = str(narrative.get("theme", "")).to_lower()
	var candidates: Array = []
	for chain_id in chain_templates.keys():
		var cd: Dictionary = chain_templates[chain_id]
		if not is_chain_runtime_enabled(str(chain_id)):
			continue
		if _is_chain_on_cooldown(str(chain_id)):
			continue
		var rollout: Dictionary = cd.get("runtime_rollout", {})
		var stage: String = str(rollout.get("stage", "full"))
		if stage == "canary":
			var ratio: float = clampf(float(rollout.get("ratio", 0.2)), 0.0, 1.0)
			if randf() > ratio:
				continue
		candidates.append(str(chain_id))
		var preferred: Array = cd.get("preferred_themes", [])
		for t in preferred:
			if str(t).to_lower() == theme:
				pick_chain = str(chain_id)
				break
	if chain_daily_pick_policy == "rotate" and not candidates.is_empty():
		pick_chain = _rotate_pick_chain(candidates)
	elif chain_daily_pick_policy == "random" and not candidates.is_empty():
		pick_chain = str(candidates[randi() % candidates.size()])
	elif not candidates.has(pick_chain) and not candidates.is_empty():
		pick_chain = str(candidates[0])
	if candidates.is_empty():
		return
	if not _has_any_active_managed_chain():
		var first_step: String = str(chain_first_step_by_chain.get(pick_chain, MANAGED_CHAIN_STEP_1))
		start_quest(first_step)
		_mark_chain_selected_today(pick_chain)

func _has_any_active_managed_chain() -> bool:
	for qid in active_quests:
		var q: Dictionary = quests.get(qid, {})
		if str(q.get("source", "")) == "managed_story_chain":
			return true
	return false

func _fail_managed_chain_timeout(failed_qid: String, today_idx: int) -> void:
	var chain_start: int = today_idx
	var chain_id: String = str(chain_id_by_step_id.get(failed_qid, "managed_supply_chain"))
	if quests.has(failed_qid):
		chain_start = int(quests[failed_qid].get("chain_started_day_index", quests[failed_qid].get("started_day_index", today_idx)))
	for qid in quests.keys():
		if not quests.has(qid):
			continue
		var q: Dictionary = quests[qid]
		if str(q.get("source", "")) != "managed_story_chain":
			continue
		if str(q.get("chain_id", chain_id_by_step_id.get(qid, ""))) != chain_id:
			continue
		q["managed_state"] = "failed"
		q["failed_reason"] = "timeout"
		if active_quests.has(qid):
			active_quests.erase(qid)
			managed_chain_state_changed.emit(qid, "failed")
	var pace := "failed"
	var bonus_gold: int = int(managed_chain_failure.get("bonus_gold", 0))
	if GameManager and GameManager.player_data and bonus_gold != 0 and _claim_reward_grant("managed_chain_fail_bonus:%s:%d" % [chain_id, today_idx]):
		GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + bonus_gold
	if AIEconomySystem and AIEconomySystem.has_method("pulse_story_completion"):
		var f: float = float(managed_chain_pulse_factor.get("failed", 0.94))
		AIEconomySystem.pulse_story_completion(pace, bonus_gold, f, managed_chain_failure_items)
	last_chain_focus_items = managed_chain_failure_items.duplicate()
	_apply_chain_timeout_impacts(chain_id)
	managed_chain_resolved.emit({
		"result": "failed",
		"reason": "timeout",
		"pace": pace,
		"elapsed_sec": maxi(0, today_idx - chain_start) * 86400,
		"bonus_gold": bonus_gold,
		"chain_id": chain_id
	})
	_set_chain_cooldown(chain_id)
	_spawn_recovery_quest(chain_id)


func _reward_ledger() -> Dictionary:
	if not GameManager or not GameManager.player_data:
		return {}
	if not GameManager.player_data.has("reward_ledger") or not (GameManager.player_data.get("reward_ledger") is Dictionary):
		GameManager.player_data["reward_ledger"] = {}
	return GameManager.player_data["reward_ledger"]


func _claim_reward_grant(grant_id: String) -> bool:
	var gid: String = grant_id.strip_edges()
	if gid.is_empty():
		return true
	var ledger: Dictionary = _reward_ledger()
	if ledger.has(gid):
		return false
	ledger[gid] = _current_day_index()
	if GameManager and GameManager.player_data:
		GameManager.player_data["reward_ledger"] = ledger
	return true

func _apply_chain_timeout_impacts(chain_id: String) -> void:
	var npc_id: String = "pierre"
	var total_gold: int = 0
	if chain_templates.has(chain_id):
		var cd: Dictionary = chain_templates[chain_id]
		var steps: Array = cd.get("steps", [])
		for s in steps:
			if not (s is Dictionary):
				continue
			var sd: Dictionary = s
			total_gold += int(sd.get("reward", {}).get("gold", 0))
			var obj: Dictionary = sd.get("objective", {})
			if str(obj.get("type", "")) == "talk" and obj.has("npc_id"):
				var tid: String = str(obj.get("npc_id", "")).strip_edges()
				if not tid.is_empty():
					npc_id = tid
	var synthetic: Dictionary = {
		"id": "chain_timeout_%s_%d" % [chain_id, _current_day_index()],
		"source": "managed_chain_timeout",
		"chain_id": chain_id,
		"npc_id": npc_id,
		"objectives": [{"type": "chain", "count": 3}],
		"reward": {"gold": maxi(60, total_gold / maxi(1, 3))}
	}
	_apply_quest_outcome_impacts(synthetic["id"], synthetic, false)

func _spawn_recovery_quest(chain_id: String) -> void:
	var qid: String = "managed_recovery_%s_%d" % [chain_id, _current_day_index()]
	if quests.has(qid):
		return
	var focus_item: String = "bread"
	if not managed_chain_failure_items.is_empty():
		focus_item = str(managed_chain_failure_items[0])
	quests[qid] = {
		"id": qid,
		"title": "Recovery Task: Rebuild Trust",
		"description": "Sell %s worth 60g to restore market confidence." % focus_item,
		"objectives": [{"type": "earn_gold", "count": 60, "current": 0}],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 20, "items": ["bread:1"]},
		"source": "managed_recovery",
		"chain_id": chain_id
	}
	start_quest(qid)

func _on_recovery_quest_completed(recovery_quest: Dictionary) -> void:
	var chain_id: String = str(recovery_quest.get("chain_id", "managed_supply_chain"))
	if GameManager and GameManager.player_data:
		GameManager.player_data["managed_chain_failed_banner"] = ""
	var restart_step: String = str(chain_first_step_by_chain.get(chain_id, MANAGED_CHAIN_STEP_1))
	var q: Dictionary = quests.get(restart_step, {})
	if not q.is_empty():
		q["status"] = QuestStatus.NOT_STARTED
		q["managed_state"] = "active"
		start_quest(restart_step)
	managed_chain_resolved.emit({
		"result": "recovered",
		"chain_id": chain_id,
		"bonus_gold": int(recovery_quest.get("reward", {}).get("gold", 0)),
		"pace": "recovery",
		"elapsed_sec": 0
	})

func _compute_chain_streak_bonus(chain_id: String) -> int:
	if not GameManager or not GameManager.player_data:
		return 0
	var today: int = _current_day_index()
	var prev_day: int = int(GameManager.player_data.get("managed_chain_streak_day", -9999))
	var prev_chain: String = str(GameManager.player_data.get("managed_chain_streak_chain", ""))
	var stacks: int = int(GameManager.player_data.get("managed_chain_streak", 0))
	if prev_day == today - 1 and prev_chain == chain_id:
		stacks += 1
	else:
		stacks = 1
	var capped: int = mini(stacks, int(managed_chain_streak.get("max_stacks", 3)))
	GameManager.player_data["managed_chain_streak"] = capped
	GameManager.player_data["managed_chain_streak_day"] = today
	GameManager.player_data["managed_chain_streak_chain"] = chain_id
	return maxi(0, capped - 1)

func _set_chain_cooldown(chain_id: String) -> void:
	if not GameManager or not GameManager.player_data:
		return
	var cd_days: int = int(chain_cooldown_days.get(chain_id, 0))
	if cd_days <= 0:
		return
	GameManager.player_data["chain_cooldown_until_%s" % chain_id] = _current_day_index() + cd_days

func _is_chain_on_cooldown(chain_id: String) -> bool:
	if not GameManager or not GameManager.player_data:
		return false
	var key := "chain_cooldown_until_%s" % chain_id
	return int(GameManager.player_data.get(key, -1)) > _current_day_index()

func _mark_chain_selected_today(chain_id: String) -> void:
	if not GameManager or not GameManager.player_data:
		return
	GameManager.player_data["chain_last_selected"] = chain_id
	GameManager.player_data["chain_last_selected_day"] = _current_day_index()

func _rotate_pick_chain(candidates: Array) -> String:
	if not GameManager or not GameManager.player_data:
		return str(candidates[0])
	var last: String = str(GameManager.player_data.get("chain_last_selected", ""))
	if candidates.size() <= 1:
		return str(candidates[0])
	var idx: int = candidates.find(last)
	if idx < 0:
		return str(candidates[0])
	return str(candidates[(idx + 1) % candidates.size()])

func _current_day_index() -> int:
	if not GameManager or not GameManager.player_data:
		return 0
	var season: String = str(GameManager.player_data.get("season", "spring"))
	var season_idx: int = 0
	match season:
		"spring":
			season_idx = 0
		"summer":
			season_idx = 1
		"fall":
			season_idx = 2
		"winter":
			season_idx = 3
		_:
			season_idx = 0
	var year: int = int(GameManager.player_data.get("year", 1))
	var day: int = int(GameManager.player_data.get("day", 1))
	return (year - 1) * 112 + season_idx * 28 + day

func turn_in_quest(quest_id: String):
	if not quests.has(quest_id):
		return false

	var quest = quests[quest_id]
	if quest.status == QuestStatus.COMPLETED:
		quest.status = QuestStatus.TURNED_IN
		return true
	return false

func get_active_quests() -> Array:
	var result = []
	for quest_id in active_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func get_completed_quests() -> Array:
	var result = []
	for quest_id in completed_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

func track_event(event_type: String, data: Dictionary):
	for quest_id in active_quests.duplicate():
		if not quests.has(quest_id):
			continue
		var quest = quests[quest_id]
		for i in range(quest.objectives.size()):
			var objective = quest.objectives[i]
			if not (objective is Dictionary):
				continue
			if str(objective.get("type", "")) != event_type:
				continue
			if not _objective_matches_event(objective, data):
				continue
			if event_type == "earn_gold":
				var g: int = int(data.get("gold", 0))
				if g <= 0:
					continue
				var goal: int = _objective_goal_max(objective)
				objective.current = mini(goal, int(objective.get("current", 0)) + g)
				check_quest_completion(quest_id)
				quest_updated.emit(quest_id, i)
			else:
				update_quest_progress(quest_id, i, int(data.get("count", 1)))

func _objective_matches_event(objective: Dictionary, data: Dictionary) -> bool:
	"""Generic matcher for objective/event payload compatibility."""
	var ot: String = str(objective.get("type", ""))
	if ot == "fish_caught":
		if objective.has("fish_id"):
			return str(data.get("fish_id", "")) == str(objective.get("fish_id", ""))
		return true
	if ot == "mine_ore":
		if objective.has("ore_id"):
			return str(data.get("ore_id", "")) == str(objective.get("ore_id", ""))
		return true
	if ot == "smelt_bar":
		if objective.has("bar_id"):
			return str(data.get("bar_id", "")) == str(objective.get("bar_id", ""))
		return true
	if ot == "consume_food":
		if objective.has("item_id"):
			return str(data.get("item_id", "")) == str(objective.get("item_id", ""))
		return true
	if ot == "cook_meal":
		if objective.has("dish_id"):
			return str(data.get("dish_id", "")) == str(objective.get("dish_id", ""))
		return true
	if ot == "chop_wood":
		return true
	if ot == "craft_item":
		if objective.has("item_id"):
			return str(data.get("item_id", "")) == str(objective.get("item_id", ""))
		return true
	if ot == "earn_gold":
		return true
	if ot == "enemy_kill":
		if objective.has("enemy_id"):
			if str(data.get("enemy_id", "")) != str(objective.get("enemy_id", "")):
				return false
		if objective.has("max_daily_defeats"):
			if int(data.get("daily_defeats", 0)) > int(objective.get("max_daily_defeats", 0)):
				return false
		if objective.has("min_streak"):
			if int(data.get("kill_streak", 0)) < int(objective.get("min_streak", 0)):
				return false
		if objective.has("min_depth"):
			return int(data.get("mine_depth", 0)) >= int(objective.get("min_depth", 0))
		return true
	if objective.has("crop_id"):
		return data.get("crop_id") == objective.get("crop_id")
	if objective.has("npc_id"):
		return data.get("npc_id") == objective.get("npc_id")
	return true

func add_story_daily_quest(event_data: Dictionary):
	"""
	Create one lightweight daily quest from narrative event.
	Playable-first: simple talk objective with clear reward.
	"""
	if not GameManager or not GameManager.player_data:
		return
	var day_key = "%d-%s-%d" % [GameManager.player_data.year, GameManager.player_data.season, GameManager.player_data.day]
	var narrative_day_key: String = str(event_data.get("narrative_day_key", day_key))
	var existing_qid: String = ""
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("source", "")) != "daily_narrative":
			continue
		if str(q.get("narrative_day_key", "")) == narrative_day_key:
			existing_qid = str(qid)
			break
	
	var npc_id = str(event_data.get("npc_id", "pierre"))
	var title = str(event_data.get("title", "Daily Story Task"))
	var quest_id = "story_daily_%s" % day_key
	var quest_payload: Dictionary = {
		"id": quest_id,
		"title": title,
		"description": "Talk to %s to follow today's story." % npc_id.capitalize(),
		"story_npc_id": npc_id,
		"narrative_id": str(event_data.get("narrative_id", "")),
		"narrative_day_key": narrative_day_key,
		"narrative_source": str(event_data.get("narrative_source", "local")),
		"source": "daily_narrative",
		"objectives": [
			{"type": "talk", "npc_id": npc_id, "count": 1, "current": 0}
		],
		"status": QuestStatus.NOT_STARTED,
		"reward": {"gold": 80, "items": []}
	}

	# Strong dedupe: same narrative day key refreshes existing quest instead of adding duplicates.
	if not existing_qid.is_empty():
		quest_payload["id"] = existing_qid
		quests[existing_qid] = quest_payload
		if not active_quests.has(existing_qid):
			start_quest(existing_qid)
		else:
			quests[existing_qid].status = QuestStatus.IN_PROGRESS
		last_story_quest_day_key = day_key
		return

	# Cap active narrative quests at one to avoid list bloat.
	for aqid in active_quests.duplicate():
		var aq: Dictionary = quests.get(aqid, {})
		if str(aq.get("source", "")) == "daily_narrative":
			active_quests.erase(aqid)
			if quests.has(aqid):
				quests[aqid].status = QuestStatus.COMPLETED

	quests[quest_id] = quest_payload
	start_quest(quest_id)
	last_story_quest_day_key = day_key

func _flatten_ai_quest_reward_items(ai_quest: Dictionary) -> Array:
	var out: Array = []
	var rw: Variant = ai_quest.get("rewards", {})
	if not rw is Dictionary:
		return out
	var rd: Dictionary = rw as Dictionary
	if rd.has("items") and rd.items is Array:
		for ent in rd.items:
			if ent is Dictionary:
				var iid: String = str((ent as Dictionary).get("id", (ent as Dictionary).get("item_id", ""))).strip_edges()
				var cnt: int = maxi(1, int((ent as Dictionary).get("count", (ent as Dictionary).get("qty", 1))))
				if not iid.is_empty():
					out.append("%s:%d" % [iid, cnt])
			else:
				out.append(str(ent))
	var single: String = str(rd.get("item", "")).strip_edges()
	if not single.is_empty() and single != "null":
		var sqty: int = maxi(1, int(rd.get("item_count", rd.get("item_qty", 1))))
		out.append("%s:%d" % [single, sqty])
	return out


func add_quest_from_ai(ai_quest: Dictionary) -> void:
	"""
	Bridge AIQuestSystem quest into QuestSystem tracking so UI/events stay unified.
	This keeps QuestSystem read-model consistent without owning AI reward settlement.
	"""
	var quest_id: String = str(ai_quest.get("id", ""))
	if quest_id.is_empty():
		return
	if quests.has(quest_id):
		return
	var rw: Dictionary = ai_quest.get("rewards", {}) if ai_quest.get("rewards") is Dictionary else {}
	var reward_gold: int = int(rw.get("gold", 0))
	var reward_items: Array = _flatten_ai_quest_reward_items(ai_quest)
	var target_count: int = int(ai_quest.get("target_count", 1))
	var qtype: String = str(ai_quest.get("type", "fetch"))
	var objective_type: String = "collect_item"
	if qtype == "delivery":
		objective_type = "delivery"
	elif qtype == "problem_solving" or qtype == "talk":
		objective_type = "talk"
	var objective: Dictionary = {
		"type": objective_type,
		"item_id": str(ai_quest.get("target_item", "")),
		"npc_id": str(ai_quest.get("target_npc", ai_quest.get("quest_giver", ""))),
		"count": maxi(1, target_count),
		"current": 0
	}
	quests[quest_id] = {
		"id": quest_id,
		"title": str(ai_quest.get("name", "AI Quest")),
		"description": str(ai_quest.get("description", "")),
		"npc_id": str(ai_quest.get("target_npc", ai_quest.get("quest_giver", ""))),
		"objectives": [objective],
		"status": QuestStatus.IN_PROGRESS,
		"reward": {"gold": reward_gold, "items": reward_items},
		"source": "ai_quest_system",
	}
	if not active_quests.has(quest_id):
		active_quests.append(quest_id)
	quest_started.emit(quest_id)

func sync_ai_quest_status(quest_id: String, success: bool, reason: String = "") -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	if str(q.get("source", "")) != "ai_quest_system":
		return
	var current_status: int = int(q.get("status", QuestStatus.NOT_STARTED))
	if current_status == QuestStatus.COMPLETED or current_status == QuestStatus.TURNED_IN:
		return
	if current_status == QuestStatus.FAILED:
		return
	if active_quests.has(quest_id):
		active_quests.erase(quest_id)
	if success:
		q["status"] = QuestStatus.COMPLETED
		_apply_quest_outcome_impacts(quest_id, q, true)
		if not completed_quests.has(quest_id):
			completed_quests.append(quest_id)
		quest_completed.emit(quest_id)
	else:
		q["status"] = QuestStatus.FAILED
		q["failed_reason"] = reason if not reason.is_empty() else "failed"
		_apply_quest_outcome_impacts(quest_id, q, false)
		if not failed_quests.has(quest_id):
			failed_quests.append(quest_id)
		quest_failed.emit(quest_id, q["failed_reason"])


func save_snapshot() -> Dictionary:
	var qd: Dictionary = {}
	for qid in quests.keys():
		qd[qid] = _serialize_quest_entry(quests[qid])
	return {
		"quests": qd,
		"active_quests": active_quests.duplicate(),
		"completed_quests": completed_quests.duplicate(),
		"failed_quests": failed_quests.duplicate(),
		"last_story_quest_day_key": last_story_quest_day_key
	}


func _serialize_quest_entry(q: Dictionary) -> Dictionary:
	var out: Dictionary = q.duplicate(true)
	out["status"] = int(q.get("status", QuestStatus.NOT_STARTED))
	return out


func load_snapshot(data: Variant) -> void:
	if not data is Dictionary:
		return
	quests.clear()
	active_quests.clear()
	completed_quests.clear()
	failed_quests.clear()
	var d: Dictionary = data
	last_story_quest_day_key = ""
	if d.has("last_story_quest_day_key"):
		last_story_quest_day_key = str(d["last_story_quest_day_key"])
	if d.get("active_quests") is Array:
		active_quests = d["active_quests"].duplicate()
	if d.get("completed_quests") is Array:
		completed_quests = d["completed_quests"].duplicate()
	if d.get("failed_quests") is Array:
		failed_quests = d["failed_quests"].duplicate()
	else:
		failed_quests = []
	if d.get("quests") is Dictionary:
		var qsave: Dictionary = d["quests"]
		for qid in qsave.keys():
			var saved: Dictionary = qsave[qid].duplicate(true)
			if saved.has("status"):
				saved["status"] = int(saved["status"])
			quests[qid] = saved
	active_quests = active_quests.filter(func(qid): return quests.has(qid))
	completed_quests = completed_quests.filter(func(qid): return quests.has(qid))
	failed_quests = failed_quests.filter(func(qid): return quests.has(qid))
	for qid in completed_quests:
		if active_quests.has(qid):
			active_quests.erase(qid)
	for qid in failed_quests:
		if active_quests.has(qid):
			active_quests.erase(qid)
	_migrate_loaded_snapshot()

func _migrate_loaded_snapshot() -> void:
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		if str(q.get("source", "")) != "managed_story_chain":
			continue
		if not q.has("chain_id"):
			q["chain_id"] = str(chain_id_by_step_id.get(str(qid), "managed_supply_chain"))
		if not q.has("managed_state"):
			q["managed_state"] = "active"
