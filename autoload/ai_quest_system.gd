extends Node

# ============================================
# AI Quest Generation System
# Autonomous quest creation based on NPC needs, world state, and narratives
# Fully AI-driven with emergent quest chains
# ============================================

signal quest_generated(quest_id, quest_data)
signal quest_assigned(npc_id, quest_id)
signal quest_completed(quest_id, outcome, rewards)
signal quest_failed(quest_id, reason)
signal quest_chain_completed(chain_id, quests_completed)
signal ai_quest_request_started(npc_id)
signal ai_quest_request_completed(npc_id, quest_data)
signal ai_quest_request_failed(npc_id, reason)

const OBJECTIVE_FETCH := "fetch_item"
const OBJECTIVE_DELIVERY := "deliver_to_npc"
const OBJECTIVE_SOLVE := "solve_problem"
const OBJECTIVE_TALK := "talk_to_npc"

# Quest database
var quest_templates = {}
var active_quests = {}
var completed_quests = {}
var quest_chains = {}

# AI quest generation state
var generation_state = {
	"last_generation": 0,
	"generation_cooldown": 7200,  # 2 hours between quest generations
	"max_active_quests": 10,
	"max_quests_per_npc": 3,
	"quest_difficulty_curve": 0.1  # How quickly quests scale in difficulty
}

# Narrative threads
var narrative_threads = []
var daily_narrative_cache = {}
var _verify_tick_accum: float = 0.0
var _recent_events: Array = []
const AI_QUEST_MIN_ACCEPT_SCORE := 0.58
const AI_QUEST_BREAKER_FAILS := 3
const AI_QUEST_BREAKER_COOLDOWN_SEC := 480
var _ai_guardrail_state: Dictionary = {
	"consecutive_failures": 0,
	"breaker_until": 0.0,
	"last_quality": 1.0
}

func _ready():
	initialize_quest_system()
	set_process(true)

func _process(delta: float) -> void:
	_verify_tick_accum += delta
	if _verify_tick_accum < 1.0:
		return
	_verify_tick_accum = 0.0
	verify_active_objectives()

func track_event(event_type: String, data: Dictionary = {}) -> void:
	_recent_events.append({
		"type": event_type,
		"data": data.duplicate(true),
		"ts": Time.get_unix_time_from_system()
	})
	while _recent_events.size() > 24:
		_recent_events.pop_front()

func initialize_quest_system():
	"""Initialize the quest generation system"""
	print("[AIQuestSystem] Initializing autonomous quest generation...")
	
	load_quest_templates()
	start_autonomous_generation()
	
	print("[AIQuestSystem] Ready with ", quest_templates.size(), " quest templates")

func load_quest_templates():
	"""Load quest template definitions"""
	# Fetch/Collection Quests
	quest_templates["fetch_item"] = {
		"type": "fetch",
		"name_template": "Find {item} for {npc}",
		"description_template": "{npc} needs {item} because {reason}.",
		"difficulty": "easy",
		"time_limit_hours": 48,
		"rewards": {
			"gold": "{base_reward}",
			"friendship": 10,
			"item": null
		},
		"ai_parameters": {
			"urgency_range": [0.3, 0.7],
			"reward_multiplier": 1.0,
			"failure_penalty": "mild_disappointment"
		},
		"narrative_hooks": [
			"{npc} has been searching for this for weeks",
			"This item has sentimental value to {npc}",
			"{npc} needs it for an important occasion"
		]
	}
	
	# Delivery Quests
	quest_templates["delivery"] = {
		"type": "delivery",
		"name_template": "Deliver {item} to {target_npc}",
		"description_template": "{npc} asks you to deliver {item} to {target_npc}.",
		"difficulty": "easy",
		"time_limit_hours": 24,
		"rewards": {
			"gold": "{base_reward}",
			"friendship": 15,
			"reputation": 5
		},
		"ai_parameters": {
			"urgency_range": [0.4, 0.8],
			"reward_multiplier": 1.2,
			"requires_careful_handling": false
		},
		"narrative_hooks": [
			"The package is fragile and valuable",
			"It's a surprise gift for someone",
			"Time is of the essence"
		]
	}
	
	# Problem-Solving Quests
	quest_templates["problem_solve"] = {
		"type": "problem_solving",
		"name_template": "Help {npc} solve {problem}",
		"description_template": "{npc} is facing {problem} and needs your help.",
		"difficulty": "medium",
		"time_limit_hours": 72,
		"rewards": {
			"gold": "{base_reward}",
			"friendship": 25,
			"unique_item": true,
			"story_progression": true
		},
		"ai_parameters": {
			"complexity_range": [0.5, 0.8],
			"reward_multiplier": 2.0,
			"multiple_solutions": true
		},
		"narrative_hooks": [
			"This problem has been bothering {npc} for months",
			"Solving this could reveal a deeper mystery",
			"Multiple townsfolk are affected by this issue"
		]
	}
	
	# Relationship Quests
	quest_templates["relationship_build"] = {
		"type": "social",
		"name_template": "Strengthen bond between {npc1} and {npc2}",
		"description_template": "Help {npc1} and {npc2} resolve their differences.",
		"difficulty": "medium",
		"time_limit_hours": 168,
		"rewards": {
			"gold": 0,
			"friendship_both": 20,
			"unlock_story": true,
			"group_harmony": true
		},
		"ai_parameters": {
			"relationship_requirement": 3,
			"reward_multiplier": 1.5,
			"emotional_depth": "high"
		},
		"narrative_hooks": [
			"They used to be best friends but had a falling out",
			"There's a misunderstanding that needs clearing up",
			"This could lead to something beautiful"
		]
	}
	
	# Skill Challenge Quests
	quest_templates["skill_challenge"] = {
		"type": "skill",
		"name_template": "Demonstrate {skill} mastery for {npc}",
		"description_template": "{npc} challenges you to prove your {skill} abilities.",
		"difficulty": "variable",
		"time_limit_hours": 48,
		"rewards": {
			"gold": "{base_reward}",
			"skill_xp": 100,
			"recognition": true,
			"title": null
		},
		"ai_parameters": {
			"skill_threshold": 5,
			"reward_multiplier": 1.8,
			"prestige_value": "high"
		},
		"narrative_hooks": [
			"{npc} is known for their expertise in this area",
			"This challenge is legendary in the town",
			"Success brings great honor"
		]
	}
	
	# Mystery/Investigation Quests
	quest_templates["investigation"] = {
		"type": "mystery",
		"name_template": "Investigate {mystery} for {npc}",
		"description_template": "{npc} has noticed something strange: {mystery}. Can you figure it out?",
		"difficulty": "hard",
		"time_limit_hours": 168,
		"rewards": {
			"gold": "{base_reward}",
			"friendship": 30,
			"secret_revealed": true,
			"story_advancement": true
		},
		"ai_parameters": {
			"clue_count_range": [3, 7],
			"reward_multiplier": 3.0,
			"narrative_significance": "high"
		},
		"narrative_hooks": [
			"This mystery connects to a larger conspiracy",
			"Several NPCs have noticed odd occurrences",
			"The truth may be unsettling"
		]
	}
	
	# Emergency Quests
	quest_templates["emergency"] = {
		"type": "emergency",
		"name_template": "URGENT: Help {npc} with crisis!",
		"description_template": "Emergency! {npc} needs immediate help with {crisis}!",
		"difficulty": "hard",
		"time_limit_hours": 12,
		"rewards": {
			"gold": "{base_reward}",
			"friendship": 40,
			"hero_status": true,
			"town_gratitude": true
		},
		"ai_parameters": {
			"urgency": 0.95,
			"reward_multiplier": 2.5,
			"failure_consequences": "severe"
		},
		"narrative_hooks": [
			"Time is running out!",
			"The whole town is counting on you",
			"Failure is not an option"
		]
	}

func start_autonomous_generation():
	"""Start autonomous quest generation"""
	if GameManager:
		GameManager.connect("time_changed", Callable(self, "_on_time_check"))

func _on_time_check(new_time: float):
	"""Check if new quests should be generated"""
	if int(new_time * 10) % 6 == 0:  # Every hour
		attempt_generate_quests()

# ============================================
# AUTONOMOUS QUEST GENERATION
# ============================================

func attempt_generate_quests():
	"""Attempt to generate new quests autonomously"""
	# Check cooldown
	var current_time = Time.get_unix_time_from_system()
	if current_time - generation_state.last_generation < generation_state.generation_cooldown:
		return
	
	# Check active quest limit
	if active_quests.size() >= generation_state.max_active_quests:
		return
	
	# Analyze situation for quest opportunities
	apply_daily_narrative_context()
	var opportunities = analyze_quest_opportunities()
	
	if opportunities.is_empty():
		return
	
	# Generate quests based on opportunities
	for opportunity in opportunities:
		if active_quests.size() >= generation_state.max_active_quests:
			break
		
		var quest = generate_quest_from_opportunity(opportunity)
		if quest:
			assign_quest_to_player(quest)
	
	generation_state.last_generation = current_time

func apply_daily_narrative_context():
	"""Inject lightweight daily narrative context into local thread cache."""
	var day_key = "day_" + str(GameManager.player_data.get("day", 1) if GameManager and GameManager.player_data else 1)
	if daily_narrative_cache.has(day_key):
		return
	
	var seed_threads = [
		{
			"id": "daily_social_" + day_key,
			"title": "今日村庄动向",
			"description": "村民间出现了新的互动机会。",
			"status": "active",
			"progress": 0,
			"total_steps": 2,
			"active_quests": [],
			"completed_quests": [],
			"importance": 0.6,
			"next_quest_type": "relationship_build"
		}
	]
	
	for thread in seed_threads:
		narrative_threads.append(thread)
	daily_narrative_cache[day_key] = true

func analyze_quest_opportunities() -> Array:
	"""Analyze game state for quest opportunities"""
	var opportunities = []
	var bias: Dictionary = _derive_world_state_bias()
	
	# 1. Check NPC needs and goals
	opportunities.append_array(analyze_npc_needs())
	
	# 2. Check world events
	opportunities.append_array(analyze_world_events())
	
	# 3. Check relationship dynamics
	opportunities.append_array(analyze_relationships())
	
	# 4. Check economic conditions
	opportunities.append_array(analyze_economy())
	
	# 5. Check narrative threads
	opportunities.append_array(analyze_narrative_threads())
	
	# Sort by priority
	for i in range(opportunities.size()):
		var op: Dictionary = opportunities[i]
		var tpl: String = str(op.get("quest_template", "fetch_item"))
		op.priority = float(op.get("priority", 0.0)) + float(bias.get(tpl, 0.0))
		opportunities[i] = op
	opportunities.sort_custom(func(a, b): return a.priority > b.priority)
	
	return opportunities


func _derive_world_state_bias() -> Dictionary:
	var bias: Dictionary = {
		"fetch_item": 0.0,
		"delivery": 0.0,
		"problem_solve": 0.0,
		"relationship_build": 0.0,
		"skill_challenge": 0.0,
		"emergency": 0.0
	}
	for ev in _recent_events:
		var et: String = str(ev.get("type", ""))
		match et:
			"enemy_kill":
				bias["skill_challenge"] += 0.45
			"harvest", "mine_ore":
				bias["delivery"] += 0.35
				bias["fetch_item"] += 0.2
			"talk":
				bias["relationship_build"] += 0.5
			"quest_completed":
				bias["problem_solve"] += 0.25
	if AIEconomySystem and AIEconomySystem.has_method("get_top_demanded_items"):
		var demands: Array = AIEconomySystem.get_top_demanded_items(2)
		if not demands.is_empty():
			bias["delivery"] += 0.6
	if AIEventSystem and AIEventSystem.has_method("get_active_events"):
		var events: Array = AIEventSystem.get_active_events()
		for event in events:
			var cat: String = str((event as Dictionary).get("category", ""))
			if cat == "emergency":
				bias["emergency"] += 1.2
			elif cat == "social":
				bias["relationship_build"] += 0.45
	return bias

func analyze_npc_needs() -> Array:
	"""Analyze NPC needs that could become quests"""
	var opportunities = []
	
	if not NPCBehaviorController or not NPCTraitSystem:
		return opportunities
	
	var all_npcs = NPCBehaviorController.get_all_npc_ids()
	
	for npc_id in all_npcs:
		# Check active goals
		var goals = NPCTraitSystem.get_active_goals(npc_id)
		for goal in goals:
			if goal.progress < 1.0 and randf() < 0.3:
				opportunities.append({
					"type": "goal_assistance",
					"npc": npc_id,
					"goal": goal,
					"priority": goal.priority,
					"quest_template": select_appropriate_template(goal)
				})
		
		# Check fears/anxieties
		var anxiety = NPCTraitSystem.get_anxiety_level(npc_id)
		if anxiety > 0.7 and randf() < 0.2:
			opportunities.append({
				"type": "comfort_npc",
				"npc": npc_id,
				"anxiety_level": anxiety,
				"priority": anxiety * 10,
				"quest_template": "relationship_build"
			})
	
	return opportunities

func analyze_world_events() -> Array:
	"""Analyze world events for quest hooks"""
	var opportunities = []
	
	if AIEventSystem:
		var active_events = AIEventSystem.get_active_events()
		for event in active_events:
			if event.category == "emergency":
				opportunities.append({
					"type": "event_response",
					"event": event,
					"priority": 8,
					"quest_template": "emergency"
				})
			elif event.category == "social":
				opportunities.append({
					"type": "event_participation",
					"event": event,
					"priority": 5,
					"quest_template": "fetch_item"
				})
	
	return opportunities

func analyze_relationships() -> Array:
	"""Analyze relationships for social quests"""
	var opportunities = []
	
	if not NPCTraitSystem:
		return opportunities
	
	# Look for strained relationships that could be mended
	# This would iterate through all NPC pairs
	# Simplified example:
	if randf() < 0.2:  # 20% chance per check
		opportunities.append({
			"type": "relationship_repair",
			"npc1": "pierre",
			"npc2": "abigail",
			"priority": 6,
			"quest_template": "relationship_build"
		})
	
	return opportunities

func analyze_economy() -> Array:
	"""Analyze economy for trade/delivery quests"""
	var opportunities = []
	
	if AIEconomySystem and randf() < 0.3:
		# Check for supply shortages creating delivery opportunities
		var top_items = AIEconomySystem.get_top_demanded_items(3)
		for item_id in top_items:
			opportunities.append({
				"type": "economic_opportunity",
				"item": item_id,
				"priority": 4,
				"quest_template": "delivery"
			})
	
	return opportunities

func analyze_narrative_threads() -> Array:
	"""Analyze ongoing narratives for continuation"""
	var opportunities = []
	
	# Check for unresolved story threads
	for thread in narrative_threads:
		if thread.status == "active" and randf() < 0.4:
			opportunities.append({
				"type": "narrative_continuation",
				"thread": thread,
				"priority": thread.importance * 10,
				"quest_template": thread.next_quest_type
			})
	
	return opportunities

func select_appropriate_template(goal: Dictionary) -> String:
	"""Select quest template based on goal type"""
	# Simple heuristic based on goal description
	var desc = goal.description.to_lower()
	
	if "find" in desc or "get" in desc or "collect" in desc:
		return "fetch_item"
	elif "deliver" in desc or "bring" in desc or "give" in desc:
		return "delivery"
	elif "solve" in desc or "fix" in desc or "resolve" in desc:
		return "problem_solve"
	elif "learn" in desc or "master" in desc or "improve" in desc:
		return "skill_challenge"
	else:
		return "fetch_item"  # Default

func generate_quest_from_opportunity(opportunity: Dictionary) -> Dictionary:
	"""Generate a complete quest from an opportunity"""
	var npc_id = opportunity.get("npc", "unknown")
	
	# If AI Agent Manager is available, try to use LLM for creative quest details
	if AIAgentManager and AIAgentManager._backend_available:
		generate_ai_enhanced_quest(opportunity)
		return {} # Will be handled by signal
	
	return generate_procedural_quest(opportunity)

func generate_procedural_quest(opportunity: Dictionary) -> Dictionary:
	"""Fall back to procedural generation if AI is unavailable"""
	var template_name = opportunity.quest_template
	var template = quest_templates.get(template_name)
	
	if not template:
		return {}
	
	# Create quest instance
	var quest = {
		"id": generate_quest_id(),
		"template": template_name,
		"type": template.type,
		"status": "offered",
		"created_at": Time.get_unix_time_from_system(),
		"opportunity_source": opportunity.type,
		"difficulty": template.difficulty,
		"narrative_context": {},
		"opportunity_source_npc": str(opportunity.get("npc", ""))
	}
	
	# Fill in template variables
	quest = fill_quest_template(quest, template, opportunity)
	
	# Calculate rewards
	quest.rewards = calculate_quest_rewards(quest, template)
	
	# Set time limit
	if template.has("time_limit_hours"):
		quest.time_limit = quest.created_at + (template.time_limit_hours * 3600)
	
	return quest

func generate_ai_enhanced_quest(opportunity: Dictionary):
	"""Request LLM to generate creative quest details"""
	var npc_id = opportunity.get("npc", "unknown")
	ai_quest_request_started.emit(npc_id)
	if float(Time.get_unix_time_from_system()) < float(_ai_guardrail_state.get("breaker_until", 0.0)):
		_degrade_to_procedural(npc_id, opportunity, "quality_breaker_open", "procedural_breaker")
		return
	
	var npc_profile = {}
	if EnhancedPersonalitySystem:
		npc_profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
	
	var prompt = """Generate a unique quest for the player in a farming simulation game.
NPC: %s
NPC Personality: %s
Current Situation: %s
Quest Template Type: %s

Requirements:
1. Provide a creative 'title' for the quest.
2. Provide a 'description' (2-3 sentences) in the NPC's voice.
3. Define 'objective' (e.g., "Bring 5 Potatoes", "Talk to Mayor Lewis").
4. Explain the 'motivation' behind this quest.

Output ONLY in JSON format:
{
  "title": "Quest Title",
  "description": "I really need...",
  "objective": "Collect...",
  "motivation": "Because..."
}""" % [
		get_npc_name(npc_id),
		str(npc_profile.get("traits", [])),
		str(opportunity),
		opportunity.quest_template
	]
	
	# Use AIAgentManager to make the request
	if not AIAgentManager or not AIAgentManager.has_method("request_text_generation"):
		_degrade_to_procedural(npc_id, opportunity, "AIAgentManager unavailable", "procedural_unavailable")
		return

	var gen: Dictionary = await AIAgentManager.request_text_generation({
		"prompt": prompt,
		"temperature": 0.72,
		"max_tokens": 280,
		"source": "ai_quest:%s" % npc_id
	})
	if not bool(gen.get("ok", false)):
		_degrade_to_procedural(npc_id, opportunity, str(gen.get("error", "quest generation failed")), "procedural_request_error")
		return

	var ai_data: Dictionary = _parse_ai_quest_json(str(gen.get("text", "")))
	if ai_data.is_empty():
		_degrade_to_procedural(npc_id, opportunity, "invalid ai quest json", "procedural_invalid_json")
		return
	var quality: float = _score_ai_quest_payload(ai_data)
	_ai_guardrail_state["last_quality"] = quality
	var threshold: float = _effective_ai_quality_threshold()
	if quality < threshold:
		_degrade_to_procedural(npc_id, opportunity, "low_quality_ai_payload:%.2f<thr:%.2f" % [quality, threshold], "procedural_low_quality")
		return

	_ai_guardrail_state["consecutive_failures"] = 0
	_on_ai_quest_response_received(npc_id, opportunity, ai_data)


func _effective_ai_quality_threshold() -> float:
	var threshold: float = AI_QUEST_MIN_ACCEPT_SCORE
	if GameManager:
		var style: String = str(GameManager.player_data.get("player_style_last_day", "balanced"))
		if style == "social_focused":
			threshold += 0.06
		elif style == "combat_focused":
			threshold -= 0.04
	return clampf(threshold, 0.45, 0.82)


func _degrade_to_procedural(npc_id: String, opportunity: Dictionary, reason: String, degraded_to: String) -> void:
	ai_quest_request_failed.emit(npc_id, reason)
	var fails: int = int(_ai_guardrail_state.get("consecutive_failures", 0)) + 1
	_ai_guardrail_state["consecutive_failures"] = fails
	if fails >= AI_QUEST_BREAKER_FAILS:
		_ai_guardrail_state["breaker_until"] = float(Time.get_unix_time_from_system()) + float(AI_QUEST_BREAKER_COOLDOWN_SEC)
	var fallback_quest: Dictionary = generate_procedural_quest(opportunity)
	if fallback_quest.is_empty():
		return
	fallback_quest["ai_degraded_to"] = degraded_to
	fallback_quest["ai_fallback_reason"] = reason
	ai_quest_request_completed.emit(npc_id, fallback_quest)
	assign_quest_to_player(fallback_quest)

func _on_ai_quest_response_received(npc_id: String, opportunity: Dictionary, ai_data: Dictionary):
	"""Process LLM response and create the quest"""
	var quest = generate_procedural_quest(opportunity)
	
	# Override with AI generated content
	quest.name = ai_data.get("title", quest.name)
	quest.description = ai_data.get("description", quest.description)
	quest.ai_objective = ai_data.get("objective_text", ai_data.get("objective", ""))
	quest.ai_motivation = ai_data.get("motivation", "")
	if ai_data.has("target_item"):
		quest.target_item = str(ai_data.get("target_item", quest.get("target_item", "")))
	if ai_data.has("target_npc"):
		quest.target_npc = str(ai_data.get("target_npc", quest.get("target_npc", "")))
	if ai_data.has("target_count"):
		quest.target_count = maxi(1, int(ai_data.get("target_count", quest.get("target_count", 1))))
	if ai_data.has("objective_type"):
		quest.objective_type = str(ai_data.get("objective_type", quest.get("objective_type", "")))
		_apply_objective_type_to_quest(quest)
	quest.description = _append_completion_hint(quest)
	
	ai_quest_request_completed.emit(npc_id, quest)
	assign_quest_to_player(quest)


func _score_ai_quest_payload(ai_data: Dictionary) -> float:
	var score: float = 0.0
	var title: String = str(ai_data.get("title", "")).strip_edges()
	var desc: String = str(ai_data.get("description", "")).strip_edges()
	var objective: String = str(ai_data.get("objective", "")).strip_edges()
	var motivation: String = str(ai_data.get("motivation", "")).strip_edges()
	if title.length() >= 6:
		score += 0.2
	if desc.length() >= 24:
		score += 0.3
	if objective.length() >= 10:
		score += 0.3
	if motivation.length() >= 12:
		score += 0.2
	if objective.find("???") >= 0 or objective.find("unknown") >= 0:
		score -= 0.25
	if title.to_lower().find("quest") >= 0 and title.length() < 10:
		score -= 0.1
	return clampf(score, 0.0, 1.0)

func _clip_text(v: String, max_len: int) -> String:
	var t: String = v.strip_edges()
	if t.length() <= max_len:
		return t
	return t.substr(0, max_len)

func _normalize_ai_quest_payload(ai_data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	out["title"] = _clip_text(str(ai_data.get("title", "")), 72)
	out["description"] = _clip_text(str(ai_data.get("description", "")), 240)
	out["objective_text"] = _clip_text(str(ai_data.get("objective", "")), 120)
	out["motivation"] = _clip_text(str(ai_data.get("motivation", "")), 140)
	out["target_item"] = _clip_text(str(ai_data.get("target_item", "")), 64)
	out["target_npc"] = _clip_text(str(ai_data.get("target_npc", "")), 64)
	out["target_count"] = maxi(1, int(ai_data.get("target_count", 1)))
	var objective_hint: String = str(ai_data.get("objective_type", "")).to_lower()
	if objective_hint.is_empty():
		objective_hint = out["objective_text"].to_lower()
	if objective_hint.contains("deliver") or objective_hint.contains("bring"):
		out["objective_type"] = OBJECTIVE_DELIVERY
	elif objective_hint.contains("solve") or objective_hint.contains("fix"):
		out["objective_type"] = OBJECTIVE_SOLVE
	elif objective_hint.contains("talk"):
		out["objective_type"] = OBJECTIVE_TALK
	else:
		out["objective_type"] = OBJECTIVE_FETCH
	return out

func _append_completion_hint(quest: Dictionary) -> String:
	var desc: String = str(quest.get("description", "")).strip_edges()
	var qtype: String = str(quest.get("type", ""))
	var hint: String = ""
	if qtype == "fetch":
		hint = "Completion: Keep %s x%d in your backpack." % [
			str(quest.get("target_item", "item")),
			int(quest.get("target_count", 1))
		]
	elif qtype == "delivery":
		var npc: String = str(quest.get("target_npc", ""))
		if npc.is_empty():
			hint = "Completion: Carry %s x%d in your backpack." % [
				str(quest.get("target_item", "item")),
				int(quest.get("target_count", 1))
			]
		else:
			hint = "Completion: Carry %s x%d, then talk to %s." % [
				str(quest.get("target_item", "item")),
				int(quest.get("target_count", 1)),
				npc
			]
	elif qtype == "problem_solving":
		hint = "Completion: Talk to %s." % str(quest.get("quest_giver", "the quest giver"))
	elif qtype == "talk":
		hint = "Completion: Talk to %s." % str(quest.get("target_npc", quest.get("quest_giver", "the contact")))
	if hint.is_empty():
		return desc
	if desc.find("Completion:") >= 0:
		return desc
	return "%s\n%s" % [desc, hint]

func _apply_objective_type_to_quest(quest: Dictionary) -> void:
	var otype: String = str(quest.get("objective_type", "")).strip_edges()
	match otype:
		OBJECTIVE_FETCH:
			quest["type"] = "fetch"
		OBJECTIVE_DELIVERY:
			quest["type"] = "delivery"
		OBJECTIVE_SOLVE:
			quest["type"] = "problem_solving"
			if str(quest.get("quest_giver", "")).is_empty():
				quest["quest_giver"] = str(quest.get("opportunity_source_npc", quest.get("target_npc", "pierre")))
		OBJECTIVE_TALK:
			quest["type"] = "talk"
		_:
			pass

func _parse_ai_quest_json(raw_text: String) -> Dictionary:
	var text: String = raw_text.strip_edges()
	if text.is_empty():
		return {}
	# Support fenced output from models, keep only JSON body when possible.
	if text.begins_with("```"):
		var first_brace: int = text.find("{")
		var last_brace: int = text.rfind("}")
		if first_brace >= 0 and last_brace > first_brace:
			text = text.substr(first_brace, last_brace - first_brace + 1)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		var d: Dictionary = parsed
		if d.has("title") and d.has("description"):
			var normalized: Dictionary = _normalize_ai_quest_payload(d)
			if not str(normalized.get("title", "")).is_empty() and not str(normalized.get("description", "")).is_empty():
				return normalized
	return {}
func fill_quest_template(quest: Dictionary, template: Dictionary, opportunity: Dictionary) -> Dictionary:
	"""Fill in quest template with specific data"""
	var npc_id = opportunity.get("npc", "unknown")
	var npc_name = get_npc_name(npc_id)
	
	# Generate name
	quest.name = template.name_template.replace("{npc}", npc_name)
	
	# Generate description with narrative hook
	var base_desc = template.description_template.replace("{npc}", npc_name)
	
	if template.has("narrative_hooks") and not template.narrative_hooks.is_empty():
		var hook = template.narrative_hooks[randi() % template.narrative_hooks.size()]
		hook = hook.replace("{npc}", npc_name)
		base_desc += " " + hook
	
	quest.description = base_desc
	
	# Add specifics based on type
	match quest.type:
		"fetch":
			quest.target_item = generate_target_item(opportunity)
			quest.target_count = int(opportunity.get("target_count", 1))
			quest.objective_type = OBJECTIVE_FETCH
			quest.description = quest.description.replace("{item}", quest.target_item)
			quest.description = quest.description.replace("{reason}", generate_item_reason(npc_id))
		
		"delivery":
			quest.target_item = generate_target_item(opportunity)
			quest.target_npc = generate_target_npc()
			quest.target_count = int(opportunity.get("target_count", 1))
			quest.objective_type = OBJECTIVE_DELIVERY
			quest.description = quest.description.replace("{item}", quest.target_item)
			quest.description = quest.description.replace("{target_npc}", get_npc_name(quest.target_npc))
		
		"problem_solving":
			quest.problem = generate_problem(npc_id)
			quest.quest_giver = npc_id
			quest.objective_type = OBJECTIVE_SOLVE
			quest.description = quest.description.replace("{problem}", quest.problem)
	quest.description = _append_completion_hint(quest)
	if str(quest.get("quest_giver", "")).is_empty():
		quest["quest_giver"] = str(npc_id)
	return quest

func generate_target_item(opportunity: Dictionary) -> String:
	"""Generate target item for fetch/delivery quests"""
	if ItemDatabase:
		var all_items = ItemDatabase.get_all_item_ids()
		if not all_items.is_empty():
			return all_items[randi() % all_items.size()]
	return "mysterious_item"

func generate_item_reason(npc_id: String) -> String:
	"""Generate reason why NPC needs an item"""
	var reasons = [
		"it's very important to them personally",
		"they need it for their work",
		"it's a rare collectible they've been seeking",
		"they want to give it as a gift",
		"it's essential for an upcoming event"
	]
	return reasons[randi() % reasons.size()]

func generate_target_npc() -> String:
	"""Generate target NPC for delivery quests"""
	if NPCBehaviorController:
		var npcs = NPCBehaviorController.get_all_npc_ids()
		if npcs.size() > 1:
			return npcs[randi() % npcs.size()]
	return "villager"

func generate_problem(npc_id: String) -> String:
	"""Generate a problem for the NPC"""
	var problems = [
		"a pest infestation in their crops",
		"trouble with their equipment",
		"a disagreement with a neighbor",
		"difficulty finding a rare ingredient",
		"concerns about the upcoming festival"
	]
	return problems[randi() % problems.size()]

func calculate_quest_rewards(quest: Dictionary, template: Dictionary) -> Dictionary:
	"""Calculate appropriate rewards for quest"""
	var rewards = template.rewards.duplicate(true)
	var multiplier = template.ai_parameters.reward_multiplier
	
	# Adjust based on difficulty
	match quest.difficulty:
		"easy":
			multiplier *= 1.0
		"medium":
			multiplier *= 1.5
		"hard":
			multiplier *= 2.5
	
	# Calculate gold reward
	if rewards.gold is String and rewards.gold.contains("{base_reward}"):
		var base_reward = 100
		rewards.gold = int(base_reward * multiplier)
	
	return rewards

func verify_active_objectives() -> void:
	# Phase-B minimum verifier: fetch/delivery by inventory checks.
	if not InventoryManager:
		return
	var ids: Array = active_quests.keys()
	for qid in ids:
		var quest: Dictionary = active_quests.get(qid, {})
		if quest.is_empty():
			continue
		var qtype: String = str(quest.get("type", ""))
		if qtype == "fetch":
			var item_id: String = str(quest.get("target_item", ""))
			var need: int = int(quest.get("target_count", 1))
			if not item_id.is_empty() and InventoryManager.count_item(item_id) >= need:
				complete_quest(str(qid), true, {"verified_by": "inventory_fetch", "item_id": item_id, "count": need})
		elif qtype == "delivery":
			var item_id2: String = str(quest.get("target_item", ""))
			var need2: int = int(quest.get("target_count", 1))
			if item_id2.is_empty():
				continue
			if InventoryManager.count_item(item_id2) < need2:
				continue
			var target_npc: String = str(quest.get("target_npc", ""))
			if target_npc.is_empty():
				if InventoryManager.consume_item_by_id(item_id2, need2):
					complete_quest(str(qid), true, {"verified_by": "inventory_delivery", "item_id": item_id2, "count": need2})
				continue
			var talked_to_target := false
			for ev in _recent_events:
				if str(ev.get("type", "")) != "talk":
					continue
				var ed: Dictionary = ev.get("data", {})
				if str(ed.get("npc_id", "")) == target_npc:
					talked_to_target = true
					break
			if not talked_to_target:
				continue
			if InventoryManager.consume_item_by_id(item_id2, need2):
				complete_quest(str(qid), true, {
					"verified_by": "talk_delivery",
					"item_id": item_id2,
					"count": need2,
					"target_npc": target_npc
				})
		elif qtype == "problem_solving":
			var giver: String = str(quest.get("quest_giver", ""))
			if giver.is_empty():
				continue
			for ev in _recent_events:
				if str(ev.get("type", "")) != "talk":
					continue
				var ed: Dictionary = ev.get("data", {})
				if str(ed.get("npc_id", "")) == giver:
					complete_quest(str(qid), true, {"verified_by": "talk_problem_solving", "npc_id": giver})
					break
		elif qtype == "talk":
			var talk_npc: String = str(quest.get("target_npc", quest.get("quest_giver", "")))
			if talk_npc.is_empty():
				talk_npc = "pierre"
			for ev in _recent_events:
				if str(ev.get("type", "")) != "talk":
					continue
				var ed: Dictionary = ev.get("data", {})
				if str(ed.get("npc_id", "")) == talk_npc:
					complete_quest(str(qid), true, {"verified_by": "talk_to_npc", "npc_id": talk_npc})
					break

func assign_quest_to_player(quest: Dictionary):
	"""Assign generated quest to player"""
	quest.status = "active"
	quest.assigned_to = "player"
	quest.accepted_at = Time.get_unix_time_from_system()
	
	active_quests[quest.id] = quest
	
	# Emit signals
	quest_generated.emit(quest.id, quest)
	
	if QuestSystem:
		# Integrate with existing quest system
		QuestSystem.add_quest_from_ai(quest)
	
	print("[AIQuestSystem] Quest generated and assigned: ", quest.name)

# ============================================
# QUEST MANAGEMENT
# ============================================

func complete_quest(quest_id: String, success: bool = true, extra_data: Dictionary = {}):
	"""Mark a quest as completed"""
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest.status = "completed" if success else "failed"
	quest.completed_at = Time.get_unix_time_from_system()
	quest.outcome_data = extra_data
	
	# Move to completed
	completed_quests[quest_id] = quest
	active_quests.erase(quest_id)
	
	if success:
		# Grant rewards
		grant_quest_rewards(quest)
		if AIEconomySystem and AIEconomySystem.has_method("on_quest_completed"):
			var econ_payload: Dictionary = {
				"id": quest_id,
				"source": "ai_quest_system",
				"reward": quest.get("rewards", {}),
				"objectives": [_to_econ_objective(quest)]
			}
			AIEconomySystem.on_quest_completed(econ_payload)
		quest_completed.emit(quest_id, "success", quest.rewards)
		_emit_structured_completion_feedback(quest_id, quest)
	else:
		quest_failed.emit(quest_id, extra_data.get("reason", "Unknown"))
	if QuestSystem and QuestSystem.has_method("sync_ai_quest_status"):
		QuestSystem.sync_ai_quest_status(
			quest_id,
			quest.status == "completed",
			str(extra_data.get("reason", "failed"))
		)
	
	# Update narrative threads
	update_narrative_from_quest(quest, success)

func grant_quest_rewards(quest: Dictionary):
	"""Grant rewards to player"""
	var rewards: Dictionary = quest.rewards if quest.get("rewards") is Dictionary else {}
	var giver: String = str(quest.get("quest_giver", quest.get("opportunity_source_npc", ""))).strip_edges()

	if rewards.has("gold"):
		var gv: Variant = rewards.gold
		var g: int = int(gv) if gv is int or gv is float else (int(str(gv)) if str(gv).is_valid_int() else 0)
		if g > 0 and GameManager and GameManager.player_data:
			GameManager.player_data["gold"] = int(GameManager.player_data.get("gold", 0)) + g

	if rewards.has("friendship"):
		var fh: int = maxi(0, int(rewards.friendship))
		if fh > 0:
			_apply_ai_friendship_reward(giver, fh)

	if rewards.has("friendship_both"):
		var fb: int = maxi(0, int(rewards.friendship_both))
		if fb > 0:
			var n1: String = str(quest.get("npc1", giver)).strip_edges()
			var n2: String = str(quest.get("npc2", "")).strip_edges()
			if not n1.is_empty() and n1 != "unknown":
				_apply_ai_friendship_reward(n1, fb)
			if not n2.is_empty():
				_apply_ai_friendship_reward(n2, fb)

	if rewards.has("skill_xp"):
		var sx: int = maxi(0, int(rewards.skill_xp))
		if sx > 0 and GameManager:
			var sk: String = str(rewards.get("skill", quest.get("reward_skill", "general"))).strip_edges()
			GameManager.add_skill_xp(sk, sx)

	if rewards.has("item") and rewards.item != null:
		var item_id: String = str(rewards.item)
		if not item_id.is_empty() and item_id != "null":
			var qty: int = maxi(1, int(rewards.get("item_count", rewards.get("item_qty", 1))))
			_grant_reward_item_stack(item_id, qty)

	if rewards.has("items") and rewards.items is Array:
		for ent in rewards.items:
			if ent is Dictionary:
				var iid: String = str(ent.get("id", ent.get("item_id", ""))).strip_edges()
				var cnt: int = maxi(1, int(ent.get("count", ent.get("qty", 1))))
				if not iid.is_empty():
					_grant_reward_item_stack(iid, cnt)
			elif ent is String:
				var parts: PackedStringArray = (ent as String).split(":")
				var sid: String = parts[0].strip_edges()
				var scnt: int = int(parts[1]) if parts.size() > 1 and parts[1].strip_edges().is_valid_int() else 1
				if not sid.is_empty():
					_grant_reward_item_stack(sid, maxi(1, scnt))


func _apply_ai_friendship_reward(npc_id: String, heart_units: int) -> void:
	if heart_units <= 0:
		return
	var nid: String = npc_id.strip_edges()
	if nid.is_empty() or nid == "unknown":
		return
	if GameManager:
		GameManager.add_npc_friendship(nid, heart_units)
	if NPCTraitSystem:
		NPCTraitSystem.update_relationship(nid, "player", heart_units * 10, "ai_quest_reward")


func _grant_reward_item_stack(item_id: String, count: int) -> void:
	if count <= 0 or ItemDatabase == null or InventoryManager == null:
		return
	var tpl: Dictionary = ItemDatabase.get_item(item_id)
	if tpl.is_empty():
		return
	for _i in count:
		InventoryManager.add_item(tpl.duplicate(true))

func _emit_structured_completion_feedback(quest_id: String, quest: Dictionary) -> void:
	var title: String = str(quest.get("name", quest_id))
	var rw: Dictionary = quest.get("rewards", {}) as Dictionary
	var gpv: Variant = rw.get("gold", 0)
	var gold: int = int(gpv) if gpv is int or gpv is float else 0
	var target_item: String = str(quest.get("target_item", ""))
	var market_note: String = ""
	if AIEconomySystem and not target_item.is_empty():
		market_note = str(AIEconomySystem.get_market_brief(target_item))
	var line: String = "AI Quest done: %s | gold +%d" % [title, gold]
	if not market_note.is_empty():
		line += " | market %s" % market_note
	var giver: String = str(quest.get("quest_giver", "")).strip_edges()
	var fh: int = int(rw.get("friendship", 0))
	if fh > 0 and not giver.is_empty():
		line += " | friendship %+d (%s)" % [fh, giver]
	var sx: int = int(rw.get("skill_xp", 0))
	if sx > 0:
		var sk: String = str(rw.get("skill", quest.get("reward_skill", "general")))
		line += " | skill_xp %+d (%s)" % [sx, sk]
	if rw.has("item") and str(rw.item).strip_edges() != "" and str(rw.item) != "null":
		var q: int = maxi(1, int(rw.get("item_count", rw.get("item_qty", 1))))
		line += " | item %s x%d" % [str(rw.item), q]
	if get_tree() and get_tree().current_scene and get_tree().current_scene.has_method("record_world_event"):
		get_tree().current_scene.call("record_world_event", line)

func _to_econ_objective(quest: Dictionary) -> Dictionary:
	var qtype: String = str(quest.get("type", ""))
	if qtype == "fetch":
		return {"type": "harvest", "crop_id": str(quest.get("target_item", "")), "count": int(quest.get("target_count", 1))}
	if qtype == "delivery":
		return {"type": "delivery", "item_id": str(quest.get("target_item", "")), "count": int(quest.get("target_count", 1))}
	if qtype == "problem_solving" or qtype == "talk":
		return {"type": "talk", "npc_id": str(quest.get("quest_giver", quest.get("target_npc", ""))), "count": 1}
	return {"type": qtype, "count": int(quest.get("target_count", 1))}

func update_narrative_from_quest(quest: Dictionary, success: bool):
	"""Update narrative threads based on quest outcome"""
	# Check if this quest advances any narrative
	for thread in narrative_threads:
		if thread.active_quests.has(quest.id):
			if success:
				thread.progress += 1
				thread.completed_quests.append(quest.id)
				thread.next_quest_type = _next_template_from_quest_type(str(quest.get("template", "fetch_item")))
				if thread.progress >= thread.total_steps:
					thread.status = "completed"
					quest_chain_completed.emit(thread.id, thread.completed_quests)
			else:
				thread.status = "blocked"


func _next_template_from_quest_type(current_template: String) -> String:
	match current_template:
		"fetch_item":
			return "delivery"
		"delivery":
			return "relationship_build"
		"relationship_build":
			return "problem_solve"
		"problem_solve":
			return "skill_challenge"
		_:
			return "fetch_item"

# ============================================
# NARRATIVE THREAD MANAGEMENT
# ============================================

func create_narrative_thread(thread_data: Dictionary) -> String:
	"""Create a new narrative thread (multi-quest storyline)"""
	var thread = {
		"id": "thread_" + str(randi() % 10000),
		"title": thread_data.title,
		"description": thread_data.description,
		"status": "active",
		"progress": 0,
		"total_steps": thread_data.steps,
		"active_quests": [],
		"completed_quests": [],
		"importance": thread_data.get("importance", 0.5),
		"next_quest_type": thread_data.get("next_quest_type", "fetch_item")
	}
	
	narrative_threads.append(thread)
	return thread.id

# ============================================
# UTILITY FUNCTIONS
# ============================================

func generate_quest_id() -> String:
	"""Generate unique quest ID"""
	return "quest_" + str(Time.get_unix_time_from_system()).replace(".", "") + "_" + str(randi() % 1000)

func get_npc_name(npc_id: String) -> String:
	"""Get NPC display name"""
	if EnhancedPersonalitySystem:
		var profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
		if profile.has("basic_info"):
			return profile.basic_info.get("name", npc_id)
	return npc_id.capitalize()

func get_active_quests() -> Array:
	"""Get all active quests"""
	return active_quests.values()

func get_quests_for_npc(npc_id: String) -> Array:
	"""Get quests related to a specific NPC"""
	var related = []
	for quest in active_quests.values():
		if quest.opportunity_source.get("npc") == npc_id:
			related.append(quest)
	return related

func get_quest_by_id(quest_id: String) -> Dictionary:
	"""Get quest data by ID"""
	return active_quests.get(quest_id, completed_quests.get(quest_id, {}))
