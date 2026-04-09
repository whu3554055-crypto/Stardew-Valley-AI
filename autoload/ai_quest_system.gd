extends Node

class_name AIQuestSystem

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
	var day_key = "day_" + str(GameManager.player_data.day if GameManager and GameManager.player_data else 1)
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
	opportunities.sort_custom(func(a, b): return a.priority > b.priority)
	
	return opportunities

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
		"narrative_context": {}
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
		ai_quest_request_failed.emit(npc_id, "AIAgentManager unavailable")
		var fallback_quest: Dictionary = generate_procedural_quest(opportunity)
		if fallback_quest.is_empty():
			return
		ai_quest_request_completed.emit(npc_id, fallback_quest)
		assign_quest_to_player(fallback_quest)
		return

	var gen: Dictionary = await AIAgentManager.request_text_generation({
		"prompt": prompt,
		"temperature": 0.72,
		"max_tokens": 280
	})
	if not bool(gen.get("ok", false)):
		ai_quest_request_failed.emit(npc_id, str(gen.get("error", "quest generation failed")))
		var fallback_quest2: Dictionary = generate_procedural_quest(opportunity)
		if fallback_quest2.is_empty():
			return
		ai_quest_request_completed.emit(npc_id, fallback_quest2)
		assign_quest_to_player(fallback_quest2)
		return

	var ai_data: Dictionary = _parse_ai_quest_json(str(gen.get("text", "")))
	if ai_data.is_empty():
		ai_quest_request_failed.emit(npc_id, "invalid ai quest json")
		var fallback_quest3: Dictionary = generate_procedural_quest(opportunity)
		if fallback_quest3.is_empty():
			return
		ai_quest_request_completed.emit(npc_id, fallback_quest3)
		assign_quest_to_player(fallback_quest3)
		return

	_on_ai_quest_response_received(npc_id, opportunity, ai_data)

func _on_ai_quest_response_received(npc_id: String, opportunity: Dictionary, ai_data: Dictionary):
	"""Process LLM response and create the quest"""
	var quest = generate_procedural_quest(opportunity)
	
	# Override with AI generated content
	quest.name = ai_data.get("title", quest.name)
	quest.description = ai_data.get("description", quest.description)
	quest.ai_objective = ai_data.get("objective", "")
	quest.ai_motivation = ai_data.get("motivation", "")
	
	ai_quest_request_completed.emit(npc_id, quest)
	assign_quest_to_player(quest)

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
			return d
	return {}
>>>>+++ REPLACE


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
			quest.description = quest.description.replace("{item}", quest.target_item)
			quest.description = quest.description.replace("{reason}", generate_item_reason(npc_id))
		
		"delivery":
			quest.target_item = generate_target_item(opportunity)
			quest.target_npc = generate_target_npc()
			quest.target_count = int(opportunity.get("target_count", 1))
			quest.description = quest.description.replace("{item}", quest.target_item)
			quest.description = quest.description.replace("{target_npc}", get_npc_name(quest.target_npc))
		
		"problem_solving":
			quest.problem = generate_problem(npc_id)
			quest.quest_giver = npc_id
			quest.description = quest.description.replace("{problem}", quest.problem)
	
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
		quest_completed.emit(quest_id, "success", quest.rewards)
	else:
		quest_failed.emit(quest_id, extra_data.get("reason", "Unknown"))
	
	# Update narrative threads
	update_narrative_from_quest(quest, success)

func grant_quest_rewards(quest: Dictionary):
	"""Grant rewards to player"""
	var rewards = quest.rewards
	
	if rewards.has("gold") and rewards.gold > 0:
		if GameManager and GameManager.player_data:
			GameManager.player_data.gold = int(GameManager.player_data.get("gold", 0)) + int(rewards.gold)
	
	if rewards.has("friendship"):
		# Add friendship to quest giver
		pass
	
	if rewards.has("skill_xp"):
		# Grant skill experience
		pass
	
	if rewards.has("item") and rewards.item != null:
		var item_id: String = str(rewards.item)
		var tpl: Dictionary = ItemDatabase.get_item(item_id) if ItemDatabase else {}
		if not tpl.is_empty() and InventoryManager:
			InventoryManager.add_item(tpl.duplicate(true))

func update_narrative_from_quest(quest: Dictionary, success: bool):
	"""Update narrative threads based on quest outcome"""
	# Check if this quest advances any narrative
	for thread in narrative_threads:
		if thread.active_quests.has(quest.id):
			if success:
				thread.progress += 1
				if thread.progress >= thread.total_steps:
					thread.status = "completed"
					quest_chain_completed.emit(thread.id, thread.completed_quests)
			else:
				thread.status = "blocked"

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
