extends Node

# Emotion model based on OCC (Ortony, Clore, and Collins)
enum EmotionType {
	JOY,
	DISTRESS,
	HAPPY_FOR,
	RESENTMENT,
	GLOATING,
	REGRET,
	PRIDE,
	SHAME_REMORSE,
 GRATITUDE,
	ANGER,
	FEAR,
	HOPE,
	FEAR_CONFIRMED,
	SATISFACTION,
	FEARS_CONFIRMED,
	RELIEF,
	DISAPPOINTMENT,
	LIKE,
	DISLIKE,
	LOVE,
	HATE
}

# Basic emotions for simplicity
enum BasicEmotion {
	NEUTRAL,
	HAPPY,
	SAD,
	ANGRY,
	EXCITED,
	CALM,
	ANXIOUS,
	GRATEFUL,
	LONELY,
	CONFIDENT,
	SHY,
	PLAYFUL,
	SERIOUS,
	ROMANTIC,
	NOSTALGIC
}

class EmotionalState:
	var current_emotion: BasicEmotion
	var intensity: float  # 0.0 - 1.0
	var duration: float  # seconds remaining
	var cause: String
	
	func _init(
		p_emotion: BasicEmotion = BasicEmotion.NEUTRAL,
		p_intensity: float = 0.5,
		p_duration: float = 60.0,
		p_cause: String = ""
	):
		current_emotion = p_emotion
		intensity = p_intensity
		duration = p_duration
		cause = p_cause

# NPC emotional states
var npc_emotions = {}
var npc_personalities = {}
var emotion_history = {}
var npc_social_graph = {}

signal emotion_changed(npc_id, new_emotion, intensity)
signal mood_updated(npc_id, mood_description)

func _ready():
	initialize_personalities()
	initialize_social_graph()
	load_emotion_state()

func _process(delta):
	update_emotions(delta)

# Initialize default personalities for NPCs
func initialize_personalities():
	# Pierre - Friendly shopkeeper
	npc_personalities["pierre"] = {
		"base_mood": BasicEmotion.HAPPY,
		"traits": {
			"friendliness": 0.9,
			"patience": 0.8,
			"generosity": 0.7,
			"energy": 0.7,
			"sensitivity": 0.4
		},
		"triggers": {
			"customer_purchase": {"emotion": BasicEmotion.HAPPY, "intensity": 0.6},
			"rude_behavior": {"emotion": BasicEmotion.SAD, "intensity": 0.4},
			"gift_received": {"emotion": BasicEmotion.GRATEFUL, "intensity": 0.8}
		}
	}
	
	# Abigail - Adventurous and energetic
	npc_personalities["abigail"] = {
		"base_mood": BasicEmotion.EXCITED,
		"traits": {
			"friendliness": 0.7,
			"patience": 0.5,
			"generosity": 0.6,
			"energy": 0.95,
			"sensitivity": 0.6,
			"adventurousness": 0.9
		},
		"triggers": {
			"adventure_talk": {"emotion": BasicEmotion.EXCITED, "intensity": 0.8},
			"boring_conversation": {"emotion": BasicEmotion.ANXIOUS, "intensity": 0.5},
			"gift_received": {"emotion": BasicEmotion.HAPPY, "intensity": 0.9}
		}
	}
	
	# Mayor Lewis - Responsible and dignified
	npc_personalities["lewis"] = {
		"base_mood": BasicEmotion.CALM,
		"traits": {
			"friendliness": 0.75,
			"patience": 0.85,
			"generosity": 0.65,
			"energy": 0.6,
			"sensitivity": 0.5,
			"responsibility": 0.95
		},
		"triggers": {
			"town_event": {"emotion": BasicEmotion.HAPPY, "intensity": 0.7},
			"disorder": {"emotion": BasicEmotion.SERIOUS, "intensity": 0.6},
			"respect_shown": {"emotion": BasicEmotion.GRATEFUL, "intensity": 0.7}
		}
	}

func initialize_social_graph():
	# Lightweight social graph for first playable propagation loop.
	npc_social_graph = {
		"pierre": {"abigail": 0.9, "lewis": 0.5},
		"abigail": {"pierre": 0.9, "lewis": 0.4},
		"lewis": {"pierre": 0.5, "abigail": 0.4}
	}

# Set initial emotion for NPC
func set_emotion(
	npc_id: String,
	emotion: BasicEmotion,
	intensity: float = 0.5,
	duration: float = 120.0,
	cause: String = ""
):
	if not npc_emotions.has(npc_id):
		npc_emotions[npc_id] = EmotionalState.new()
	
	npc_emotions[npc_id].current_emotion = emotion
	npc_emotions[npc_id].intensity = intensity
	npc_emotions[npc_id].duration = duration
	npc_emotions[npc_id].cause = cause
	
	emotion_changed.emit(npc_id, emotion, intensity)

func propagate_emotion_to_social_circle(
	source_npc_id: String,
	emotion: BasicEmotion,
	source_intensity: float = 0.7,
	cause: String = "social_propagation"
) -> Array:
	var changed_npcs: Array = []
	if not npc_social_graph.has(source_npc_id):
		return changed_npcs
	
	var neighbors: Dictionary = npc_social_graph.get(source_npc_id, {})
	for neighbor_id in neighbors.keys():
		var bond_strength = float(neighbors[neighbor_id])
		var personality = get_personality(neighbor_id)
		var friendliness = float(personality.get("traits", {}).get("friendliness", 0.5))
		var sensitivity = float(personality.get("traits", {}).get("sensitivity", 0.5))
		var propagated_intensity = source_intensity * bond_strength * (0.6 + friendliness * 0.2 + sensitivity * 0.2)
		propagated_intensity = clamp(propagated_intensity, 0.15, 0.75)
		
		set_emotion(neighbor_id, emotion, propagated_intensity, 90.0, cause)
		changed_npcs.append({
			"npc_id": neighbor_id,
			"intensity": propagated_intensity
		})
	
	return changed_npcs

# Trigger emotion based on event
func trigger_emotion(npc_id: String, event_type: String, context: Dictionary = {}):
	var personality = get_personality(npc_id)
	if not personality:
		return
	
	var triggers = personality.get("triggers", {})
	if triggers.has(event_type):
		var trigger = triggers[event_type]
		var base_intensity = trigger.intensity
		
		# Modify by personality traits
		var sensitivity = personality.get("traits", {}).get("sensitivity", 0.5)
		var modified_intensity = base_intensity * (0.5 + sensitivity * 0.5)
		
		# Apply context modifiers
		var relationship_bonus = context.get("relationship", 0.0) * 0.1
		modified_intensity = clamp(modified_intensity + relationship_bonus, 0.0, 1.0)
		
		set_emotion(npc_id, trigger.emotion, modified_intensity, 120.0, event_type)

# Update emotions over time (decay)
func update_emotions(delta: float):
	for npc_id in npc_emotions:
		var state = npc_emotions[npc_id]
		state.duration -= delta
		
		if state.duration <= 0:
			# Return to base mood
			var personality = get_personality(npc_id)
			if personality and personality.has("base_mood"):
				state.current_emotion = personality.base_mood
				state.intensity *= 0.5  # Gradual decay
				state.duration = 60.0
		
		# Natural decay of intensity
		state.intensity = max(state.intensity * 0.99, 0.1)

# Get current emotion description
func get_emotion_description(npc_id: String) -> String:
	if not npc_emotions.has(npc_id):
		return "neutral"
	
	var state = npc_emotions[npc_id]
	var emotion_name = BasicEmotion.keys()[state.current_emotion].to_lower()
	
	if state.intensity < 0.3:
		return "slightly " + emotion_name
	elif state.intensity > 0.7:
		return "very " + emotion_name
	else:
		return emotion_name

# Get personality profile
func get_personality(npc_id: String) -> Dictionary:
	return npc_personalities.get(npc_id, {
		"base_mood": BasicEmotion.NEUTRAL,
		"traits": {
			"friendliness": 0.5,
			"patience": 0.5,
			"generosity": 0.5,
			"energy": 0.5,
			"sensitivity": 0.5
		},
		"triggers": {}
	})

# Set custom personality
func set_personality(npc_id: String, personality_data: Dictionary):
	npc_personalities[npc_id] = personality_data

# Calculate mood-based dialogue modifier
func get_dialogue_modifier(npc_id: String) -> Dictionary:
	if not npc_emotions.has(npc_id):
		return {"tone": "neutral", "enthusiasm": 0.5}
	
	var state = npc_emotions[npc_id]
	var modifier = {
		"tone": "neutral",
		"enthusiasm": 0.5,
		"formality": 0.5,
		"warmth": 0.5
	}
	
	match state.current_emotion:
		BasicEmotion.HAPPY, BasicEmotion.EXCITED:
			modifier.tone = "positive"
			modifier.enthusiasm = 0.5 + state.intensity * 0.5
			modifier.warmth = 0.5 + state.intensity * 0.3
		BasicEmotion.SAD, BasicEmotion.LONELY:
			modifier.tone = "melancholic"
			modifier.enthusiasm = 0.5 - state.intensity * 0.3
			modifier.warmth = 0.5 - state.intensity * 0.2
		BasicEmotion.ANGRY:
			modifier.tone = "irritated"
			modifier.enthusiasm = 0.3
			modifier.formality = 0.3
		BasicEmotion.SHY:
			modifier.tone = "hesitant"
			modifier.enthusiasm = 0.4
			modifier.formality = 0.7
		BasicEmotion.PLAYFUL:
			modifier.tone = "playful"
			modifier.enthusiasm = 0.8
			modifier.warmth = 0.7
		BasicEmotion.ROMANTIC:
			modifier.tone = "affectionate"
			modifier.warmth = 0.9
			modifier.enthusiasm = 0.6
	
	return modifier

func get_emotion_ui_style(npc_id: String) -> Dictionary:
	"""Provide lightweight UI style hints based on current emotion."""
	if not npc_emotions.has(npc_id):
		return {
			"badge": "neutral",
			"name_tint": Color(1, 1, 1, 1),
			"sfx": "notification"
		}
	
	var state = npc_emotions[npc_id]
	match state.current_emotion:
		BasicEmotion.HAPPY, BasicEmotion.EXCITED, BasicEmotion.GRATEFUL:
			return {"badge": "positive", "name_tint": Color(0.8, 1.0, 0.8, 1), "sfx": "level_up"}
		BasicEmotion.SAD, BasicEmotion.LONELY:
			return {"badge": "sad", "name_tint": Color(0.8, 0.85, 1.0, 1), "sfx": "notification"}
		BasicEmotion.ANGRY:
			return {"badge": "angry", "name_tint": Color(1.0, 0.75, 0.75, 1), "sfx": "error"}
		_:
			return {"badge": "neutral", "name_tint": Color(1, 1, 1, 1), "sfx": "notification"}

# Record emotion change
func record_emotion_change(npc_id: String, emotion: BasicEmotion, cause: String):
	if not emotion_history.has(npc_id):
		emotion_history[npc_id] = []
	
	emotion_history[npc_id].append({
		"emotion": emotion,
		"cause": cause,
		"day": GameManager.player_data.get("day", 1),
		"time": GameManager.current_time
	})
	
	# Keep only last 20 entries
	if emotion_history[npc_id].size() > 20:
		emotion_history[npc_id].pop_front()

# Save emotion state
func save_emotion_state():
	var save_data = {
		"emotions": {},
		"personalities": npc_personalities,
		"history": emotion_history
	}
	
	for npc_id in npc_emotions:
		var state = npc_emotions[npc_id]
		save_data.emotions[npc_id] = {
			"emotion": state.current_emotion,
			"intensity": state.intensity,
			"duration": state.duration,
			"cause": state.cause
		}
	
	var file = FileAccess.open("user://npc_emotions.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

# Load emotion state
func load_emotion_state():
	if not FileAccess.file_exists("user://npc_emotions.json"):
		return
	
	var file = FileAccess.open("user://npc_emotions.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not data:
		return
	
	npc_personalities = data.get("personalities", npc_personalities)
	emotion_history = data.get("history", {})
	
	# Reconstruct emotions
	for npc_id in data.get("emotions", {}):
		var emo_data = data.emotions[npc_id]
		npc_emotions[npc_id] = EmotionalState.new(
			emo_data.emotion,
			emo_data.intensity,
			emo_data.duration,
			emo_data.cause
		)
