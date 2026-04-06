extends RefCounted

class_name MoodEnhancedPlugin

# ============================================
# Enhanced Mood Plugin
# Advanced emotional intelligence for NPCs
# ============================================

var plugin_config = {}
var npc_id = ""
var plugin_name = "mood_enhanced"

# Emotional state
var emotional_state = {
	"valence": 0.5,      # Positive/Negative (0-1)
	"arousal": 0.5,      # Calm/Excited (0-1)
	"dominance": 0.5     # Submissive/Dominant (0-1)
}

# Emotional intelligence
var eq_level = 0.7  # Ability to understand/manage emotions

func _plugin_init() -> bool:
	"""Initialize the mood plugin"""
	print("[MoodPlugin] Initialized for NPC: ", npc_id)
	return true

func _plugin_cleanup():
	"""Cleanup when plugin is unloaded"""
	print("[MoodPlugin] Cleaned up for NPC: ", npc_id)

func _plugin_save_state() -> Dictionary:
	"""Save plugin state"""
	return {
		"emotional_state": emotional_state,
		"eq_level": eq_level
	}

func _plugin_load_state(state: Dictionary):
	"""Load plugin state"""
	if state.has("emotional_state"):
		emotional_state = state.emotional_state
	if state.has("eq_level"):
		eq_level = state.eq_level

# ============================================
# EMOTIONAL CALCULUS
# ============================================

func calculate_emotional_response(event: String, context: Dictionary) -> Dictionary:
	"""Calculate emotional response to an event using VAD model"""
	var base_impact = context.get("impact", 0.5)
	
	# Adjust based on personality
	var traits = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
	var personality = traits.get("personality_core", {})
	
	# Optimism affects valence
	if personality.get("traits", []).has("optimistic"):
		base_impact *= 1.2
	elif personality.get("traits", []).has("pessimistic"):
		base_impact *= 0.8
	
	# Update VAD values
	emotional_state["valence"] = clamp(emotional_state["valence"] + base_impact * 0.1, 0, 1)
	emotional_state["arousal"] = clamp(emotional_state["arousal"] + abs(base_impact) * 0.05, 0, 1)
	
	# Determine emotion label
	var emotion_label = map_vad_to_emotion(emotional_state)
	
	return {
		"emotion": emotion_label,
		"vad": emotional_state.duplicate(),
		"intensity": abs(base_impact)
	}

func map_vad_to_emotion(vad: Dictionary) -> String:
	"""Map VAD coordinates to emotion labels"""
	var v = vad.valence
	var a = vad.arousal
	var d = vad.dominance
	
	if v > 0.6 and a > 0.6:
		return "excited" if d > 0.5 else "submissive_joy"
	elif v > 0.6 and a < 0.4:
		return "content" if d > 0.5 else "relaxed"
	elif v < 0.4 and a > 0.6:
		return "angry" if d > 0.5 else "anxious"
	elif v < 0.4 and a < 0.4:
		return "sad" if d < 0.5 else "bored"
	else:
		return "neutral"

# ============================================
# MOOD INFLUENCE ON BEHAVIOR
# ============================================

func get_mood_influence_on_decision() -> Dictionary:
	"""Get how current mood influences decision-making"""
	var influence = {
		"risk_tolerance": 0.5,
		"social_openness": 0.5,
		"generosity": 0.5,
		"patience": 0.5
	}
	
	# Valence affects optimism
	influence.risk_tolerance = emotional_state.valence
	influence.social_openness = emotional_state.valence * 0.8 + emotional_state.arousal * 0.2
	influence.generosity = emotional_state.valence
	
	# Arousal affects patience
	influence.patience = 1.0 - emotional_state.arousal
	
	return influence

func should_accept_social_interaction(initiator_mood: String) -> bool:
	"""Decide whether to accept social interaction based on mood"""
	var my_mood = map_vad_to_emotion(emotional_state)
	
	# Don't interact if very sad or angry
	if my_mood in ["sad", "angry", "anxious"]:
		if emotional_state.valence < 0.3:
			return false
	
	# More likely to interact if happy
	if my_mood in ["excited", "content", "relaxed"]:
		return randf() < 0.8
	
	# Default: 50% chance
	return randf() < 0.5

# ============================================
# EMOTIONAL CONTAGION
# ============================================

func catch_emotion_from(other_npc_id: String, intensity: float):
	"""Catch emotion from another NPC (emotional contagion)"""
	if not NPCTraitSystem:
		return
	
	var other_mood = NPCTraitSystem.get_mood_state(other_npc_id)
	var relationship = NPCTraitSystem.get_relationship(npc_id, other_npc_id)
	
	# Closer relationships = stronger contagion
	var relationship_multiplier = 1.0 + (relationship.get("level", 0) * 0.1)
	var contagion_strength = intensity * relationship_multiplier * eq_level
	
	# Shift emotional state toward other NPC
	var target_valence = 0.5
	if other_mood.get("current") in ["happy", "excited", "cheerful"]:
		target_valence = 0.7 + intensity * 0.3
	elif other_mood.get("current") in ["sad", "depressed", "melancholic"]:
		target_valence = 0.3 - intensity * 0.3
	
	emotional_state.valence = lerp(emotional_state.valence, target_valence, contagion_strength * 0.1)

# ============================================
# MOOD-BASED DIALOGUE MODIFIERS
# ============================================

func get_dialogue_modifiers() -> Dictionary:
	"""Get modifiers for dialogue generation based on mood"""
	var modifiers = {
		"tone": "neutral",
		"verbosity": 1.0,
		"formality": 0.5,
		"humor_chance": 0.1
	}
	
	var mood = map_vad_to_emotion(emotional_state)
	
	match mood:
		"excited", "content":
			modifiers.tone = "cheerful"
			modifiers.verbosity = 1.3
			modifiers.humor_chance = 0.3
		"sad", "melancholic":
			modifiers.tone = "somber"
			modifiers.verbosity = 0.7
			modifiers.formality = 0.3
		"angry":
			modifiers.tone = "curt"
			modifiers.verbosity = 0.6
			modifiers.formality = 0.2
		"anxious":
			modifiers.tone = "nervous"
			modifiers.verbosity = 1.2
			modifiers.formality = 0.7
		"relaxed":
			modifiers.tone = "casual"
			modifiers.verbosity = 1.1
			modifiers.humor_chance = 0.2
	
	return modifiers

# ============================================
# STRESS MANAGEMENT
# ============================================

func calculate_stress_level() -> float:
	"""Calculate current stress level"""
	# High arousal + low valence + low dominance = high stress
	var stress = (emotional_state.arousal * 0.4 + 
				 (1 - emotional_state.valence) * 0.4 + 
				 (1 - emotional_state.dominance) * 0.2)
	return stress

func apply_coping_mechanism(mechanism: String):
	"""Apply stress coping mechanism"""
	var stress = calculate_stress_level()
	
	match mechanism:
		"deep_breathing":
			emotional_state.arousal *= 0.8
		"social_support":
			emotional_state.valence += 0.1
			emotional_state.dominance += 0.05
		"exercise":
			emotional_state.arousal *= 0.9
			emotional_state.valence += 0.05
		"meditation":
			emotional_state.arousal *= 0.7
			emotional_state.valence = lerp(emotional_state.valence, 0.5, 0.2)
