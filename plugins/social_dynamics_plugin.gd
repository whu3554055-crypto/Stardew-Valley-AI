extends RefCounted

class_name SocialDynamicsPlugin

# ============================================
# Social Dynamics Plugin
# Manages group interactions, social influence, and network effects
# ============================================

var plugin_config = {}
var npc_id = ""
var plugin_name = "social_dynamics"

# Social state
var social_state = {
	"current_group": "",
	"influence_score": 0.5,  # How much this NPC influences others
	"susceptibility": 0.5,   # How easily influenced by others
	"charisma": 0.5,
	"empathy": 0.5
}

# Social network cache
var social_network = {}

func _plugin_init() -> bool:
	"""Initialize the social dynamics plugin"""
	print("[SocialDynamics] Initialized for NPC: ", npc_id)
	return true

func _plugin_cleanup():
	"""Cleanup when plugin is unloaded"""
	print("[SocialDynamics] Cleaned up for NPC: ", npc_id)

func _plugin_save_state() -> Dictionary:
	"""Save plugin state"""
	return {
		"social_state": social_state,
		"social_network": social_network
	}

func _plugin_load_state(state: Dictionary):
	"""Load plugin state"""
	if state.has("social_state"):
		social_state = state.social_state
	if state.has("social_network"):
		social_network = state.social_network

# ============================================
# GROUP DYNAMICS
# ============================================

func join_group(group_id: String, members: Array) -> bool:
	"""Join a social group"""
	if social_state.current_group != "":
		leave_current_group()
	
	social_state.current_group = group_id
	
	# Update influence based on relationships with members
	var total_relationship = 0
	for member_id in members:
		if member_id != npc_id:
			var rel = NPCTraitSystem.get_relationship(npc_id, member_id)
			total_relationship += rel.get("level", 0)
	
	var avg_relationship = total_relationship / max(1, members.size() - 1)
	social_state.influence_score = clamp(avg_relationship / 10.0, 0.1, 1.0)
	
	return true

func leave_current_group():
	"""Leave current social group"""
	if social_state.current_group != "":
		social_state.current_group = ""
		social_state.influence_score = 0.5

func get_group_influence() -> float:
	"""Get influence within current group"""
	return social_state.influence_score

# ============================================
# SOCIAL INFLUENCE
# ============================================

func calculate_influence_on(other_npc_id: String) -> float:
	"""Calculate how much this NPC can influence another"""
	var relationship = NPCTraitSystem.get_relationship(npc_id, other_npc_id)
	var my_charisma = social_state.charisma
	
	# Base influence from relationship
	var base_influence = relationship.get("level", 0) / 10.0
	
	# Modify by charisma
	var charisma_bonus = (my_charisma - 0.5) * 0.3
	
	# Modify by current mood
	var mood_state = NPCTraitSystem.get_mood_state(npc_id)
	var mood_modifier = 1.0
	if mood_state.current in ["happy", "excited"]:
		mood_modifier = 1.2
	elif mood_state.current in ["sad", "angry"]:
		mood_modifier = 0.7
	
	var final_influence = (base_influence + charisma_bonus) * mood_modifier
	return clamp(final_influence, 0.0, 1.0)

func is_influenced_by(other_npc_id: String, influence_attempt: float) -> bool:
	"""Check if this NPC is influenced by another's attempt"""
	var their_influence = calculate_influence_on_me(other_npc_id)
	var my_resistance = 1.0 - social_state.susceptibility
	
	# Get mood modifier
	var mood_state = NPCTraitSystem.get_mood_state(npc_id)
	if mood_state.current in ["confident", "excited"]:
		my_resistance *= 1.3
	elif mood_state.current in ["uncertain", "anxious"]:
		my_resistance *= 0.7
	
	var threshold = their_influence * (1.0 - my_resistance)
	return influence_attempt < threshold

func calculate_influence_on_me(other_npc_id: String) -> float:
	"""Calculate how much another NPC can influence me"""
	var relationship = NPCTraitSystem.get_relationship(other_npc_id, npc_id)
	var their_plugin = NPCPluginManager.get_plugin_for_npc(other_npc_id, "social_dynamics")
	
	if not their_plugin:
		return 0.3  # Default low influence
	
	var their_charisma = their_plugin.social_state.charisma
	var base_influence = relationship.get("level", 0) / 10.0
	
	return clamp((base_influence + their_charisma * 0.3), 0.0, 1.0)

# ============================================
# OPINION FORMATION
# ============================================

func form_opinion(topic: String, initial_stance: float = 0.5) -> Dictionary:
	"""Form an opinion on a topic based on social influences"""
	var opinion = {
		"topic": topic,
		"stance": initial_stance,  # -1 to 1 (negative to positive)
		"confidence": 0.5,
		"sources": [],
		"formed_at": Time.get_unix_time_from_system()
	}
	
	# Check memories for related experiences
	if NPCTraitSystem:
		var memories = NPCTraitSystem.recall_memories(npc_id, topic, 3)
		for memory in memories:
			if memory.emotional_valence == "positive":
				opinion.stance += 0.1
			elif memory.emotional_valence == "negative":
				opinion.stance -= 0.1
	
	# Check relationships - trust friends' opinions
	var relationships = NPCTraitSystem.get_all_relationships(npc_id)
	for other_id in relationships.keys():
		var rel = relationships[other_id]
		if rel.level >= 5:  # Friends and above
			# In a real system, we'd check their opinions
			opinion.sources.append(other_id)
	
	opinion.stance = clamp(opinion.stance, -1.0, 1.0)
	opinion.confidence = min(1.0, 0.5 + len(opinion.sources) * 0.1)
	
	return opinion

func update_opinion_from_social(opinion: Dictionary, peer_opinions: Array) -> Dictionary:
	"""Update opinion based on peer pressure"""
	var social_pressure = 0.0
	var total_influence = 0.0
	
	for peer_data in peer_opinions:
		var peer_id = peer_data.npc_id
		var peer_stance = peer_data.stance
		var influence = calculate_influence_on_me(peer_id)
		
		social_pressure += peer_stance * influence
		total_influence += influence
	
	if total_influence > 0:
		var avg_pressure = social_pressure / total_influence
		# Move opinion toward social consensus based on susceptibility
		var shift = (avg_pressure - opinion.stance) * social_state.susceptibility * 0.2
		opinion.stance += shift
		opinion.stance = clamp(opinion.stance, -1.0, 1.0)
	
	return opinion

# ============================================
# RUMOR SPREADING
# ============================================

func receive_rumor(rumor: Dictionary, from_npc_id: String) -> bool:
	"""Receive and potentially spread a rumor"""
	var credibility = rumor.get("credibility", 0.5)
	var interest = rumor.get("interest", 0.5)
	
	# Decide whether to believe it
	var belief_threshold = 0.5 - social_state.empathy * 0.2  # More empathetic = more trusting
	var believes = randf() < (credibility * (1.0 - belief_threshold))
	
	if not believes:
		return false
	
	# Add to memory
	if NPCTraitSystem:
		NPCTraitSystem.form_memory(npc_id, 
			"Heard rumor: " + rumor.get("content", ""),
			interest * 0.6,
			rumor.get("emotional_tone", "neutral"))
	
	# Decide whether to spread
	var spread_chance = interest * social_state.susceptibility
	if randf() < spread_chance:
		spread_rumor(rumor, from_npc_id)
		return true
	
	return true

func spread_rumor(rumor: Dictionary, original_source: String):
	"""Spread a rumor to nearby NPCs"""
	# Modify rumor as it spreads (telephone game effect)
	var modified_rumor = rumor.duplicate(true)
	modified_rumor.credibility *= randf_range(0.8, 1.2)
	
	# Add self as source
	if not modified_rumor.has("spread_chain"):
		modified_rumor.spread_chain = []
	modified_rumor.spread_chain.append(npc_id)
	
	# In a real implementation, spread to nearby NPCs
	# This would integrate with the behavior controller

# ============================================
# SOCIAL STATUS
# ============================================

func calculate_social_status() -> float:
	"""Calculate overall social status in community"""
	var relationships = NPCTraitSystem.get_all_relationships(npc_id)
	if relationships.is_empty():
		return 0.5
	
	var total_status = 0.0
	var weighted_count = 0
	
	for other_id in relationships.keys():
		var rel = relationships[other_id]
		var other_plugin = NPCPluginManager.get_plugin_for_npc(other_id, "social_dynamics")
		
		if other_plugin:
			# Weight by their social status
			var their_status = other_plugin.calculate_social_status()
			total_status += rel.level * their_status
		else:
			total_status += rel.level
		
		weighted_count += rel.level
	
	if weighted_count == 0:
		return 0.5
	
	return clamp(total_status / (weighted_count * 10.0), 0.0, 1.0)

# ============================================
# CONFLICT RESOLUTION
# ============================================

func handle_conflict(with_npc_id: String, conflict_type: String) -> Dictionary:
	"""Handle a social conflict"""
	var relationship = NPCTraitSystem.get_relationship(npc_id, with_npc_id)
	var resolution = {
		"outcome": "unresolved",
		"relationship_change": 0,
		"strategy": ""
	}
	
	# Choose strategy based on personality and relationship
	var strategies = ["compromise", "accommodate", "compete", "avoid"]
	var chosen_strategy = choose_conflict_strategy(strategies, relationship)
	resolution.strategy = chosen_strategy
	
	match chosen_strategy:
		"compromise":
			resolution.outcome = "partial_resolution"
			resolution.relationship_change = -5
		"accommodate":
			resolution.outcome = "peaceful"
			resolution.relationship_change = 5
		"compete":
			resolution.outcome = "escalation" if randf() < 0.5 else "victory"
			resolution.relationship_change = -15
		"avoid":
			resolution.outcome = "delayed"
			resolution.relationship_change = -2
	
	# Apply relationship change
	if NPCTraitSystem:
		NPCTraitSystem.update_relationship(npc_id, with_npc_id, 
			resolution.relationship_change, "conflict: " + conflict_type)
	
	return resolution

func choose_conflict_strategy(strategies: Array, relationship: Dictionary) -> String:
	"""Choose conflict resolution strategy"""
	# High relationship = more cooperative
	if relationship.level >= 7:
		return "compromise" if randf() < 0.6 else "accommodate"
	
	# Low relationship = more competitive
	if relationship.level <= 2:
		return "compete" if randf() < 0.4 else "avoid"
	
	# Medium relationship = mixed
	return strategies[randi() % strategies.size()]
