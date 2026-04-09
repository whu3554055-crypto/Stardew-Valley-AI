extends Node

# ============================================
# Rich NPC Trait System
# Manages dynamic traits: mood, relationships, skills, memories, goals, fears
# ============================================

signal trait_changed(npc_id, trait_name, old_value, new_value)
signal goal_completed(npc_id, goal_id)
signal fear_triggered(npc_id, fear_type, intensity)
signal memory_formed(npc_id, memory_data)
signal relationship_evolved(npc_id, other_id, new_level)

# Core trait data structure
var npc_traits = {}

# Trait categories
const TRAIT_CATEGORIES = {
	"mood": ["happy", "sad", "angry", "excited", "anxious", "tired", "energetic", "melancholic"],
	"personality": ["outgoing", "shy", "optimistic", "pessimistic", "patient", "impulsive", "generous", "selfish"],
	"skills": ["farming", "mining", "fishing", "cooking", "crafting", "social", "combat"],
	"goals": ["short_term", "medium_term", "long_term", "secret"],
	"fears": ["rejection", "failure", "loneliness", "poverty", "darkness", "water", "heights"],
	"memories": ["positive", "negative", "neutral", "traumatic", "joyful"]
}

func _ready():
	initialize_trait_system()

func initialize_trait_system():
	"""Initialize the trait system with default structures"""
	print("[NPCTraitSystem] Initialized")

# ============================================
# MOOD SYSTEM - Dynamic emotional states
# ============================================

func initialize_mood_system(npc_id: String):
	"""Initialize mood system for an NPC"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["mood"] = {
		"current": "neutral",
		"intensity": 0.5,
		"duration": 0.0,
		"decay_rate": 0.01,
		"modifiers": [],
		"history": [],
		"baseline": "neutral",
		"volatility": 0.3,  # How quickly mood changes (0-1)
		"resilience": 0.5   # How quickly returns to baseline (0-1)
	}

func update_mood(npc_id: String, delta: float):
	"""Update mood over time with decay and modifiers"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("mood"):
		initialize_mood_system(npc_id)
	
	var mood = npc_traits[npc_id]["mood"]
	
	# Apply decay
	mood["duration"] -= delta
	if mood["duration"] <= 0:
		# Decay toward baseline
		var decay_amount = mood["decay_rate"] * mood["resilience"] * delta
		mood["intensity"] = lerp(mood["intensity"], 0.5, decay_amount)
		
		if abs(mood["intensity"] - 0.5) < 0.05:
			mood["current"] = mood["baseline"]
			mood["intensity"] = 0.5
	
	# Apply modifiers
	for modifier in mood["modifiers"]:
		modifier["duration"] -= delta
		if modifier["duration"] <= 0:
			mood["modifiers"].erase(modifier)
		else:
			mood["intensity"] += modifier["strength"] * delta
	
	# Clamp intensity
	mood["intensity"] = clamp(mood["intensity"], 0.0, 1.0)

func set_mood(npc_id: String, mood_name: String, intensity: float, duration: float = 60.0):
	"""Set NPC's current mood"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("mood"):
		initialize_mood_system(npc_id)
	
	var old_mood = npc_traits[npc_id]["mood"]["current"]
	npc_traits[npc_id]["mood"]["current"] = mood_name
	npc_traits[npc_id]["mood"]["intensity"] = intensity
	npc_traits[npc_id]["mood"]["duration"] = duration
	
	# Record in history
	npc_traits[npc_id]["mood"]["history"].append({
		"mood": mood_name,
		"intensity": intensity,
		"timestamp": Time.get_unix_time_from_system(),
		"duration": duration
	})
	
	# Keep history manageable (last 50 entries)
	if npc_traits[npc_id]["mood"]["history"].size() > 50:
		npc_traits[npc_id]["mood"]["history"].pop_front()
	
	trait_changed.emit(npc_id, "mood", old_mood, mood_name)

func add_mood_modifier(npc_id: String, modifier_name: String, strength: float, duration: float):
	"""Add temporary mood modifier"""
	if not npc_traits.has(npc_id):
		initialize_mood_system(npc_id)
	
	npc_traits[npc_id]["mood"]["modifiers"].append({
		"name": modifier_name,
		"strength": strength,
		"duration": duration
	})

func get_mood_state(npc_id: String) -> Dictionary:
	"""Get complete mood state"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("mood"):
		initialize_mood_system(npc_id)
	return npc_traits[npc_id]["mood"]

func is_in_mood(npc_id: String, mood_name: String) -> bool:
	"""Check if NPC is in specific mood"""
	if not npc_traits.has(npc_id):
		return false
	return npc_traits[npc_id].get("mood", {}).get("current") == mood_name

# ============================================
# RELATIONSHIP SYSTEM - Dynamic social bonds
# ============================================

func initialize_relationship(npc_id: String, other_id: String):
	"""Initialize relationship between two entities"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["relationships"] = npc_traits[npc_id].get("relationships", {})
	npc_traits[npc_id]["relationships"][other_id] = {
		"level": 0,  # 0-10 scale
		"points": 0,  # Accumulated points
		"trust": 0.5,  # 0-1 scale
		"affinity": 0.5,  # Natural compatibility
		"history": [],
		"last_interaction": 0,
		"gifts_given": [],
		"conversations": 0,
		"favors_done": 0,
		"conflicts": 0,
		"shared_memories": [],
		"status": "acquaintance"  # stranger, acquaintance, friend, good_friend, best_friend, rival, enemy
	}

func update_relationship(npc_id: String, other_id: String, points: int, reason: String = ""):
	"""Update relationship points and level"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("relationships"):
		initialize_relationship(npc_id, other_id)
	
	var rel = npc_traits[npc_id]["relationships"][other_id]
	var old_level = rel["level"]
	
	rel["points"] += points
	rel["last_interaction"] = Time.get_unix_time_from_system()
	
	# Record interaction
	rel["history"].append({
		"points": points,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Calculate level (every 100 points = 1 level, max 10)
	rel["level"] = min(10, max(0, rel["points"] / 100))
	
	# Update status based on level and points direction
	if points < 0:
		rel["conflicts"] += 1
	
	if rel["level"] >= 9:
		rel["status"] = "best_friend" if points > 0 else "rival"
	elif rel["level"] >= 7:
		rel["status"] = "good_friend"
	elif rel["level"] >= 5:
		rel["status"] = "friend"
	elif rel["level"] >= 2:
		rel["status"] = "acquaintance"
	else:
		rel["status"] = "stranger"
	
	# Check for level change
	if int(rel["level"]) != int(old_level):
		relationship_evolved.emit(npc_id, other_id, rel["level"])
	
	# Keep history manageable
	if rel["history"].size() > 100:
		rel["history"] = rel["history"].slice(-100)

func get_relationship(npc_id: String, other_id: String) -> Dictionary:
	"""Get relationship data"""
	if not npc_traits.has(npc_id):
		return {"level": 0, "status": "stranger"}
	
	var relationships = npc_traits[npc_id].get("relationships", {})
	return relationships.get(other_id, {"level": 0, "status": "stranger"})

func get_all_relationships(npc_id: String) -> Dictionary:
	"""Get all relationships for an NPC"""
	if not npc_traits.has(npc_id):
		return {}
	return npc_traits[npc_id].get("relationships", {})

func add_shared_memory(npc_id: String, other_id: String, memory: String):
	"""Add shared memory to relationship"""
	if not npc_traits.has(npc_id):
		initialize_relationship(npc_id, other_id)
	
	npc_traits[npc_id]["relationships"][other_id]["shared_memories"].append({
		"memory": memory,
		"timestamp": Time.get_unix_time_from_system()
	})

# ============================================
# SKILL SYSTEM - NPC competencies
# ============================================

func initialize_skills(npc_id: String):
	"""Initialize skill system for NPC"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["skills"] = {}
	
	for skill in TRAIT_CATEGORIES["skills"]:
		npc_traits[npc_id]["skills"][skill] = {
			"level": randi_range(1, 5),
			"experience": 0,
			"max_level": 10,
			"learning_rate": randf_range(0.8, 1.2),
			"last_practiced": 0
		}

func gain_skill_experience(npc_id: String, skill: String, amount: float):
	"""Add experience to a skill"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("skills"):
		initialize_skills(npc_id)
	
	if not npc_traits[npc_id]["skills"].has(skill):
		return
	
	var skill_data = npc_traits[npc_id]["skills"][skill]
	var old_level = skill_data["level"]
	
	skill_data["experience"] += amount * skill_data["learning_rate"]
	skill_data["last_practiced"] = Time.get_unix_time_from_system()
	
	# Check for level up
	var exp_needed = skill_data["level"] * 100
	if skill_data["experience"] >= exp_needed and skill_data["level"] < skill_data["max_level"]:
		skill_data["level"] += 1
		skill_data["experience"] = 0
		trait_changed.emit(npc_id, "skill_" + skill, old_level, skill_data["level"])

func get_skill_level(npc_id: String, skill: String) -> int:
	"""Get NPC's skill level"""
	if not npc_traits.has(npc_id):
		return 0
	
	var skills = npc_traits[npc_id].get("skills", {})
	return skills.get(skill, {}).get("level", 0)

func get_all_skills(npc_id: String) -> Dictionary:
	"""Get all skills for an NPC"""
	if not npc_traits.has(npc_id):
		return {}
	return npc_traits[npc_id].get("skills", {})

# ============================================
# MEMORY SYSTEM - Long-term event storage
# ============================================

func initialize_memory_system(npc_id: String):
	"""Initialize memory system"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["memories"] = {
		"short_term": [],  # Last 20 events
		"long_term": [],   # Important events
		"emotional_tags": {},
		"forgetting_rate": 0.001  # Chance to forget short-term memories
	}

func form_memory(npc_id: String, event: String, importance: float, emotional_valence: String = "neutral"):
	"""Create a new memory"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("memories"):
		initialize_memory_system(npc_id)
	
	var memory = {
		"event": event,
		"importance": importance,
		"emotional_valence": emotional_valence,
		"timestamp": Time.get_unix_time_from_system(),
		"recalled_count": 0,
		"associated_npcs": [],
		"location": "",
		"tags": []
	}
	
	# Add to short-term
	npc_traits[npc_id]["memories"]["short_term"].append(memory)
	
	# If important enough, also add to long-term
	if importance > 0.7:
		npc_traits[npc_id]["memories"]["long_term"].append(memory.duplicate())
	
	# Update emotional tags
	if not npc_traits[npc_id]["memories"]["emotional_tags"].has(emotional_valence):
		npc_traits[npc_id]["memories"]["emotional_tags"][emotional_valence] = 0
	npc_traits[npc_id]["memories"]["emotional_tags"][emotional_valence] += 1
	
	memory_formed.emit(npc_id, memory)
	
	# Limit short-term memories
	if npc_traits[npc_id]["memories"]["short_term"].size() > 20:
		npc_traits[npc_id]["memories"]["short_term"].pop_front()

func recall_memories(npc_id: String, topic: String = "", limit: int = 5) -> Array:
	"""Recall memories related to a topic"""
	if not npc_traits.has(npc_id):
		return []
	
	var memories = npc_traits[npc_id].get("memories", {}).get("short_term", [])
	var relevant = []
	
	for memory in memories:
		if topic == "" or topic.to_lower() in memory["event"].to_lower():
			memory["recalled_count"] += 1
			relevant.append(memory)
	
	# Sort by relevance (recency + recall count + importance)
	relevant.sort_custom(func(a, b):
		var score_a = a["importance"] * 2 + a["recalled_count"] + (1.0 / (Time.get_unix_time_from_system() - a["timestamp"] + 1))
		var score_b = b["importance"] * 2 + b["recalled_count"] + (1.0 / (Time.get_unix_time_from_system() - b["timestamp"] + 1))
		return score_a > score_b
	)
	
	return relevant.slice(0, limit)

func get_emotional_bias(npc_id: String) -> Dictionary:
	"""Get NPC's emotional bias based on memories"""
	if not npc_traits.has(npc_id):
		return {"positive": 0.5, "negative": 0.5, "neutral": 0.5}
	
	return npc_traits[npc_id].get("memories", {}).get("emotional_tags", {
		"positive": 0.5,
		"negative": 0.5,
		"neutral": 0.5
	})

# ============================================
# GOAL SYSTEM - NPC aspirations and objectives
# ============================================

func initialize_goals(npc_id: String):
	"""Initialize goal system"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["goals"] = {
		"active": [],
		"completed": [],
		"failed": [],
		"priority_queue": []
	}

func add_goal(npc_id: String, goal_id: String, description: String, priority: int, deadline: float = 0):
	"""Add a new goal for NPC"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("goals"):
		initialize_goals(npc_id)
	
	var goal = {
		"id": goal_id,
		"description": description,
		"priority": priority,
		"progress": 0.0,
		"deadline": deadline,
		"created_at": Time.get_unix_time_from_system(),
		"status": "active",
		"subtasks": [],
		"rewards": [],
		"motivation": 0.8  # How motivated NPC is to pursue this
	}
	
	npc_traits[npc_id]["goals"]["active"].append(goal)
	
	# Sort by priority
	npc_traits[npc_id]["goals"]["active"].sort_custom(func(a, b):
		return a["priority"] > b["priority"]
	)

func update_goal_progress(npc_id: String, goal_id: String, progress: float):
	"""Update progress on a goal"""
	if not npc_traits.has(npc_id):
		return
	
	for goal in npc_traits[npc_id]["goals"]["active"]:
		if goal["id"] == goal_id:
			goal["progress"] += progress
			
			if goal["progress"] >= 1.0:
				complete_goal(npc_id, goal_id)
			break

func complete_goal(npc_id: String, goal_id: String):
	"""Mark a goal as completed"""
	if not npc_traits.has(npc_id):
		return
	
	var goals = npc_traits[npc_id]["goals"]
	
	for i in range(goals["active"].size()):
		if goals["active"][i]["id"] == goal_id:
			var completed_goal = goals["active"].pop_at(i)
			completed_goal["status"] = "completed"
			completed_goal["completed_at"] = Time.get_unix_time_from_system()
			goals["completed"].append(completed_goal)
			
			goal_completed.emit(npc_id, goal_id)
			break

func get_active_goals(npc_id: String) -> Array:
	"""Get all active goals"""
	if not npc_traits.has(npc_id):
		return []
	return npc_traits[npc_id].get("goals", {}).get("active", [])

func get_top_priority_goal(npc_id: String) -> Dictionary:
	"""Get the highest priority active goal"""
	var goals = get_active_goals(npc_id)
	if goals.is_empty():
		return {}
	return goals[0]

# ============================================
# FEAR SYSTEM - NPC anxieties and phobias
# ============================================

func initialize_fears(npc_id: String, fear_profile: Dictionary = {}):
	"""Initialize fear system"""
	npc_traits[npc_id] = npc_traits.get(npc_id, {})
	npc_traits[npc_id]["fears"] = {
		"profile": fear_profile,
		"current_anxiety": 0.0,
		"triggers": [],
		"coping_mechanisms": []
	}

func trigger_fear(npc_id: String, fear_type: String, intensity: float):
	"""Trigger a fear response"""
	if not npc_traits.has(npc_id) or not npc_traits[npc_id].has("fears"):
		initialize_fears(npc_id)
	
	npc_traits[npc_id]["fears"]["current_anxiety"] = min(1.0, 
		npc_traits[npc_id]["fears"]["current_anxiety"] + intensity)
	
	# Record trigger
	npc_traits[npc_id]["fears"]["triggers"].append({
		"type": fear_type,
		"intensity": intensity,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	fear_triggered.emit(npc_id, fear_type, intensity)
	
	# Fear affects behavior - can be checked by AI
	if npc_traits[npc_id]["fears"]["current_anxiety"] > 0.8:
		# High anxiety - NPC should seek comfort/avoid trigger
		pass

func reduce_anxiety(npc_id: String, amount: float):
	"""Reduce anxiety level"""
	if not npc_traits.has(npc_id):
		return
	
	npc_traits[npc_id]["fears"]["current_anxiety"] = max(0.0,
		npc_traits[npc_id]["fears"]["current_anxiety"] - amount)

func get_anxiety_level(npc_id: String) -> float:
	"""Get current anxiety level"""
	if not npc_traits.has(npc_id):
		return 0.0
	return npc_traits[npc_id].get("fears", {}).get("current_anxiety", 0.0)

# ============================================
# PERSONALITY EVOLUTION - Traits change over time
# ============================================

func evolve_personality(npc_id: String, life_events: Array):
	"""Evolve NPC personality based on life experiences"""
	if not npc_traits.has(npc_id):
		return
	
	# Analyze life events
	var positive_events = 0
	var negative_events = 0
	
	for event in life_events:
		if event.get("valence", "neutral") == "positive":
			positive_events += 1
		elif event.get("valence", "neutral") == "negative":
			negative_events += 1
	
	# Adjust baseline personality
	var total_events = positive_events + negative_events
	if total_events > 10:  # Need significant life experience
		var positivity_ratio = float(positive_events) / total_events
		
		# Shift baseline mood
		if positivity_ratio > 0.7:
			npc_traits[npc_id]["mood"]["baseline"] = "cheerful"
		elif positivity_ratio < 0.3:
			npc_traits[npc_id]["mood"]["baseline"] = "melancholic"
		
		# Adjust volatility based on trauma
		if negative_events > 20:
			npc_traits[npc_id]["mood"]["volatility"] *= 0.9  # Become more stable
		elif negative_events > 5:
			npc_traits[npc_id]["mood"]["volatility"] *= 1.1  # Become more volatile

# ============================================
# UTILITY FUNCTIONS
# ============================================

func get_complete_trait_profile(npc_id: String) -> Dictionary:
	"""Get complete trait profile for an NPC"""
	return npc_traits.get(npc_id, {})

func reset_npc_traits(npc_id: String):
	"""Reset all traits for an NPC"""
	npc_traits.erase(npc_id)

func save_traits_to_file(npc_id: String, file_path: String):
	"""Save NPC traits to file"""
	var data = JSON.stringify(npc_traits.get(npc_id, {}))
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(data)
		file.close()

func load_traits_from_file(npc_id: String, file_path: String):
	"""Load NPC traits from file"""
	if not FileAccess.file_exists(file_path):
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		npc_traits[npc_id] = data
