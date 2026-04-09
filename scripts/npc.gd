extends CharacterBody2D

class_name NPC

@export var npc_id: String = "npc_default"
@export var npc_name: String = "Villager"
@export var dialogue_lines: Array[String] = []
@export var schedule: Dictionary = {}

# AI Agent settings
@export var use_ai_dialogue: bool = true
@export var ai_personality: Dictionary = {
	"traits": ["friendly"],
	"occupation": "villager",
	"backstory": "A friendly villager.",
	"speech_style": "casual",
	"interests": ["farming"]
}

@onready var sprite = $Sprite2D
@onready var name_label = $NameLabel
@onready var interaction_area = $InteractionArea
@onready var emotion_indicator = get_node_or_null("EmotionIndicator")

var current_dialogue_index = 0
var is_talking = false
var move_timer = 0
var wander_direction = Vector2.ZERO
var is_waiting_for_ai = false

const BASE_SPEED := 50.0
var _move_speed: float = BASE_SPEED

# Current conversation state
var last_player_message = ""
var conversation_active = false

signal dialogue_ready(text)
signal ai_thinking_started()
signal ai_thinking_finished()

func _ready():
	# Set default npc_id if not set
	if npc_id == "npc_default":
		npc_id = name.to_lower().replace(" ", "_")
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	name_label.text = npc_name
	name_label.visible = false
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Initialize AI systems
	if use_ai_dialogue:
		initialize_ai_npc()
	
	randomize_wander()
	
	# Connect to AI signals if using AI
	if use_ai_dialogue and AIAgentManager:
		AIAgentManager.dialogue_generated.connect(_on_ai_dialogue_generated)
		AIAgentManager.agent_error.connect(_on_ai_error)

func initialize_ai_npc():
	# Set up personality in emotion system
	if NPCEmotionSystem:
		NPCEmotionSystem.set_personality(npc_id, ai_personality)
		
		# Set initial emotion based on time/weather
		update_emotion_for_context()

func update_emotion_for_context():
	var time_of_day = get_time_period()
	var weather = WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny"
	
	# Adjust initial mood based on context
	if weather == "rain":
		NPCEmotionSystem.trigger_emotion(npc_id, "weather_rain")
	elif time_of_day == "morning":
		NPCEmotionSystem.set_emotion(npc_id, NPCEmotionSystem.BasicEmotion.CALM, 0.6)

func _physics_process(delta):
	# Simple wandering AI
	move_timer -= delta
	if move_timer <= 0:
		randomize_wander()

	update_behavior_from_emotion(delta)
	var velocity_input = wander_direction * _move_speed
	velocity = velocity_input
	move_and_slide()

	# Update sprite direction
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func randomize_wander():
	move_timer = randf_range(2.0, 5.0)
	wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

# Enhanced interact function with AI
func interact(player_message: String = "") -> String:
	is_talking = true
	conversation_active = true
	last_player_message = player_message
	
	# Record interaction in memory
	if NPCMemorySystem:
		NPCMemorySystem.update_relationship(npc_id, 0.1)  # Small relationship boost
		
		if player_message != "":
			NPCMemorySystem.record_conversation(npc_id, player_message, "...", "neutral")
	
	if use_ai_dialogue:
		return generate_ai_response(player_message)
	else:
		# Fallback to static dialogue
		return get_static_dialogue()

func generate_ai_response(player_message: String) -> String:
	if not AIAgentManager:
		return get_static_dialogue()
	
	is_waiting_for_ai = true
	ai_thinking_started.emit()
	
	# Build context
	var context = build_context()
	var relationship = NPCMemorySystem.get_relationship(npc_id) if NPCMemorySystem else 5
	context["relationship"] = relationship
	
	# Recent interactions: gossip/events first, then conversation history (newest-first lists)
	var recent_interactions: Array = []
	if NPCMemorySystem:
		var events = NPCMemorySystem.get_recent_event_summaries(npc_id, 3)
		var conv = NPCMemorySystem.get_conversation_history(npc_id, 5)
		for e in events:
			recent_interactions.append({"day": e.day, "summary": e.summary})
		for c in conv:
			recent_interactions.append({"day": c.day, "summary": c.summary})
		var keywords = _build_dialogue_memory_keywords(player_message)
		var scored = NPCMemorySystem.get_relevant_memories(npc_id, keywords, 4)
		var snippets: Array = []
		for m in scored:
			snippets.append(m.content)
		context["memory_snippets"] = snippets
	
	context["recent_interactions"] = recent_interactions
	
	# Trigger appropriate emotion
	if NPCEmotionSystem and player_message != "":
		analyze_and_trigger_emotion(player_message)
	
	# Request AI dialogue
	AIAgentManager.generate_dialogue(
		npc_id,
		npc_name,
		ai_personality,
		context,
		recent_interactions
	)
	
	# Return placeholder while waiting
	return "..."

func _on_ai_dialogue_generated(response_npc_id: String, dialogue: String):
	if response_npc_id != npc_id:
		return
	
	is_waiting_for_ai = false
	ai_thinking_finished.emit()
	
	# Display the AI-generated dialogue
	dialogue_ready.emit(dialogue)
	
	# Record the response in memory
	if NPCMemorySystem and last_player_message != "":
		NPCMemorySystem.record_conversation(
			npc_id,
			last_player_message,
			dialogue,
			NPCEmotionSystem.get_emotion_description(npc_id) if NPCEmotionSystem else "neutral"
		)

func _on_ai_error(response_npc_id: String, error: String):
	if response_npc_id != npc_id:
		return
	
	is_waiting_for_ai = false
	ai_thinking_finished.emit()
	
	# Fallback to static dialogue
	var fallback = get_static_dialogue()
	dialogue_ready.emit(fallback + " (AI unavailable)")

func get_static_dialogue() -> String:
	if dialogue_lines.size() > 0:
		current_dialogue_index = randi() % dialogue_lines.size()
		return dialogue_lines[current_dialogue_index]
	return "..."

func next_dialogue():
	if use_ai_dialogue:
		# For AI mode, generate follow-up
		return generate_follow_up()
	else:
		current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()
		if current_dialogue_index == 0:
			is_talking = false
			conversation_active = false
			return null
		return dialogue_lines[current_dialogue_index]

func generate_follow_up() -> String:
	if not AIAgentManager or not conversation_active:
		return get_static_dialogue()
	
	return generate_ai_response("Tell me more about yourself.")

func _build_dialogue_memory_keywords(player_message: String) -> Array:
	var seen := {}
	var out: Array = []
	var t := ""
	for raw in [npc_id, npc_name]:
		t = str(raw).strip_edges().to_lower()
		if t.length() < 2:
			continue
		if not seen.has(t):
			seen[t] = true
			out.append(t)
	for part in str(npc_name).split(" "):
		t = part.strip_edges().to_lower()
		if t.length() < 2:
			continue
		if not seen.has(t):
			seen[t] = true
			out.append(t)
	if GameManager:
		t = str(GameManager.player_data.season).to_lower()
		if not seen.has(t):
			seen[t] = true
			out.append(t)
		t = str(GameManager.player_data.day)
		if not seen.has(t):
			seen[t] = true
			out.append(t)
	if WeatherSystem:
		t = WeatherSystem.get_weather_name().to_lower()
		if not seen.has(t):
			seen[t] = true
			out.append(t)
	for anchor in ["player", "daily_narrative", "story", "help", "town"]:
		if not seen.has(anchor):
			seen[anchor] = true
			out.append(anchor)
	for w in player_message.split(" "):
		t = w.strip_edges().to_lower().replace(",", "").replace(".", "").replace("!", "")
		if t.length() < 3:
			continue
		if not seen.has(t):
			seen[t] = true
			out.append(t)
	return out

# Build context for AI
func build_context() -> Dictionary:
	var time_period = get_time_period()
	var weather = "sunny"
	var season = "spring"
	var location = get_current_location()
	
	if WeatherSystem:
		weather = WeatherSystem.get_weather_name().to_lower()
	
	if GameManager:
		season = GameManager.player_data.season
	
	return {
		"time": time_period,
		"weather": weather,
		"season": season,
		"location": location,
		"recent_interactions": []
	}

func get_time_period() -> String:
	if not GameManager:
		return "morning"
	
	var hour = int(GameManager.current_time)
	if hour >= 6 and hour < 12:
		return "morning"
	elif hour >= 12 and hour < 17:
		return "afternoon"
	elif hour >= 17 and hour < 21:
		return "evening"
	else:
		return "night"

func get_current_location() -> String:
	# Determine location based on position
	# This is simplified - you can expand this
	if global_position.y < 200:
		return "mountains"
	elif global_position.x < 300:
		return "forest"
	elif global_position.x > 800:
		return "beach"
	else:
		return "town"

# Emotion analysis and triggering
func analyze_and_trigger_emotion(player_message: String):
	if not NPCEmotionSystem:
		return
	
	var msg_lower = player_message.to_lower()
	
	# Check for keywords that should trigger emotions
	if "gift" in msg_lower or "present" in msg_lower:
		NPCEmotionSystem.trigger_emotion(npc_id, "gift_received")
	elif "rude" in msg_lower or "bad" in msg_lower or "hate" in msg_lower:
		NPCEmotionSystem.trigger_emotion(npc_id, "rude_behavior")
	elif "adventure" in msg_lower or "explore" in msg_lower or "cave" in msg_lower:
		if ai_personality.traits.get("adventurousness", 0) > 0.7:
			NPCEmotionSystem.trigger_emotion(npc_id, "adventure_talk")

# Behavior modification based on emotion
func update_behavior_from_emotion(delta: float):
	if not NPCEmotionSystem:
		return
	
	var emotion_desc = NPCEmotionSystem.get_emotion_description(npc_id)
	var modifier = NPCEmotionSystem.get_dialogue_modifier(npc_id)
	
	# Modify movement speed based on energy/emotion
	var base_s: float = BASE_SPEED
	match NPCEmotionSystem.npc_emotions[npc_id].current_emotion if NPCEmotionSystem.npc_emotions.has(npc_id) else 0:
		NPCEmotionSystem.BasicEmotion.EXCITED:
			_move_speed = base_s * 1.3
		NPCEmotionSystem.BasicEmotion.SAD, NPCEmotionSystem.BasicEmotion.LONELY:
			_move_speed = base_s * 0.7
		NPCEmotionSystem.BasicEmotion.ANGRY:
			_move_speed = base_s * 1.1
		_:
			_move_speed = base_s

func set_schedule(new_schedule: Dictionary):
	schedule = new_schedule

func update_schedule(current_time: float):
	# Implement time-based schedule system
	if schedule.is_empty():
		return
	
	for time_key in schedule:
		var time_val = float(time_key)
		if abs(current_time - time_val) < 0.1:
			var target_pos = schedule[time_key]
			# Move towards target position
			global_position = global_position.lerp(target_pos, 0.05)

func _on_interaction_area_mouse_entered():
	name_label.visible = true

func _on_interaction_area_mouse_exited():
	name_label.visible = false

# Save NPC state
func save_npc_state() -> Dictionary:
	return {
		"npc_id": npc_id,
		"position": global_position,
		"is_talking": is_talking
	}

# Load NPC state
func load_npc_state(data: Dictionary):
	if data.has("position"):
		global_position = data.position
