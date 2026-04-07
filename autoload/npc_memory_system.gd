extends Node

class_name NPCMemorySystem

# Memory types
enum MemoryType {
	CONVERSATION,
	EVENT,
	PREFERENCE,
	OBSERVATION,
	EMOTION
}

# Memory structure
class Memory:
	var id: String
	var type: MemoryType
	var timestamp: float
	var day: int
	var content: String
	var importance: float  # 0.0 - 1.0
	var emotion: String
	var related_entities: Array
	
	func _init(
		p_type: MemoryType,
		p_content: String,
		p_importance: float = 0.5,
		p_emotion: String = "neutral"
	):
		type = p_type
		content = p_content
		importance = p_importance
		emotion = p_emotion
		day = GameManager.player_data.day
		timestamp = Time.get_unix_time_from_system()
		id = str(timestamp) + "_" + str(randi())

# NPC memory storage
var npc_memories = {}  # npc_id -> Array[Memory]
var npc_relationships = {}  # npc_id -> relationship data
var npc_preferences = {}  # npc_id -> preferences dict

signal memory_added(npc_id, memory)
signal relationship_changed(npc_id, new_level)
signal preference_learned(npc_id, preference)

func _ready():
	load_memories()

# Add a memory for an NPC
func add_memory(
	npc_id: String,
	memory_type: MemoryType,
	content: String,
	importance: float = 0.5,
	emotion: String = "neutral",
	related_entities: Array = []
) -> Memory:
	
	if not npc_memories.has(npc_id):
		npc_memories[npc_id] = []
	
	var memory = Memory.new(memory_type, content, importance, emotion)
	memory.related_entities = related_entities
	
	npc_memories[npc_id].append(memory)
	
	# Sort by importance (keep most important memories)
	if npc_memories[npc_id].size() > 50:  # Max 50 memories per NPC
		npc_memories[npc_id].sort_custom(func(a, b): return a.importance > b.importance)
		npc_memories[npc_id].resize(50)
	
	memory_added.emit(npc_id, memory)
	return memory

# Record a conversation
func record_conversation(
	npc_id: String,
	player_message: String,
	npc_response: String,
	emotion: String = "neutral"
):
	var summary = "Player: %s | %s: %s" % [player_message, npc_id, npc_response]
	add_memory(
		npc_id,
		MemoryType.CONVERSATION,
		summary,
		0.7,
		emotion
	)

# Record an event involving player
func record_event(
	npc_id: String,
	event_description: String,
	importance: float = 0.5,
	emotion: String = "neutral",
	related_entities: Array = []
):
	add_memory(
		npc_id,
		MemoryType.EVENT,
		event_description,
		importance,
		emotion,
		related_entities
	)

# Learn player preference
func learn_preference(
	npc_id: String,
	preference_key: String,
	preference_value,
	confidence: float = 0.5
):
	if not npc_preferences.has(npc_id):
		npc_preferences[npc_id] = {}
	
	npc_preferences[npc_id][preference_key] = {
		"value": preference_value,
		"confidence": confidence,
		"learned_day": GameManager.player_data.day
	}
	
	preference_learned.emit(npc_id, preference_key)

# Get learned preferences
func get_preferences(npc_id: String) -> Dictionary:
	return npc_preferences.get(npc_id, {})

# Update relationship level
func update_relationship(npc_id: String, change: float):
	if not npc_relationships.has(npc_id):
		npc_relationships[npc_id] = {
			"level": 0,
			"points": 0,
			"last_gift": null,
			"conversations": 0,
			"quests_completed": 0
		}
	
	var rel = npc_relationships[npc_id]
	rel.points += change * 10
	
	# Calculate level (0-10)
	rel.level = clamp(int(rel.points / 100), 0, 10)
	
	relationship_changed.emit(npc_id, rel.level)

# Get relationship level
func get_relationship(npc_id: String) -> int:
	if not npc_relationships.has(npc_id):
		return 0
	return npc_relationships[npc_id].level

# Get relevant memories for context
func get_relevant_memories(
	npc_id: String,
	context_keywords: Array = [],
	max_memories: int = 3
) -> Array:
	
	if not npc_memories.has(npc_id):
		return []
	
	var memories = npc_memories[npc_id]
	var scored_memories = []
	
	for memory in memories:
		var score = memory.importance
		
		# Boost recent memories
		var days_ago = GameManager.player_data.day - memory.day
		score *= pow(0.9, days_ago)  # Decay over time
		
		# Boost matching keywords
		for keyword in context_keywords:
			var kw = str(keyword).to_lower()
			if kw in memory.content.to_lower():
				score *= 1.5
			for entity in memory.related_entities:
				if kw in str(entity).to_lower():
					score *= 1.35
		
		scored_memories.append({"memory": memory, "score": score})
	
	# Sort by score and return top memories
	scored_memories.sort_custom(func(a, b): return a.score > b.score)
	
	var result = []
	for i in range(min(max_memories, scored_memories.size())):
		result.append(scored_memories[i].memory)
	
	return result

# Get conversation history
func get_conversation_history(npc_id: String, count: int = 5) -> Array:
	if not npc_memories.has(npc_id):
		return []
	
	var conversations = []
	for memory in npc_memories[npc_id]:
		if memory.type == MemoryType.CONVERSATION:
			conversations.append({
				"day": memory.day,
				"summary": memory.content,
				"emotion": memory.emotion
			})
	
	conversations.reverse()  # Most recent first
	return conversations.slice(0, count)

# Recent non-conversation memories (events, etc.) for prompt injection
func get_recent_event_summaries(npc_id: String, max_count: int = 3) -> Array:
	if not npc_memories.has(npc_id):
		return []
	var events: Array = []
	for memory in npc_memories[npc_id]:
		if memory.type == MemoryType.EVENT:
			events.append(memory)
	if events.is_empty():
		return []
	events.sort_custom(func(a, b):
		if a.day != b.day:
			return a.day > b.day
		return a.timestamp > b.timestamp
	)
	var result: Array = []
	for i in range(min(max_count, events.size())):
		var m = events[i]
		result.append({
			"day": m.day,
			"summary": m.content,
			"emotion": m.emotion
		})
	return result

# Calculate emotional state based on memories
func calculate_emotional_state(npc_id: String) -> Dictionary:
	if not npc_memories.has(npc_id):
		return {"mood": "neutral", "intensity": 0.0}
	
	var mood_scores = {
		"happy": 0.0,
		"sad": 0.0,
		"angry": 0.0,
		"excited": 0.0,
		"neutral": 0.0
	}
	
	# Consider last 10 memories
	var recent = npc_memories[npc_id].slice(-10)
	for memory in recent:
		if mood_scores.has(memory.emotion):
			mood_scores[memory.emotion] += memory.importance
	
	# Find dominant mood
	var dominant_mood = "neutral"
	var max_score = 0.0
	
	for mood in mood_scores:
		if mood_scores[mood] > max_score:
			max_score = mood_scores[mood]
			dominant_mood = mood
	
	return {
		"mood": dominant_mood,
		"intensity": min(max_score, 1.0)
	}

# Save memories to disk
func save_memories():
	var save_data = {
		"memories": {},
		"relationships": npc_relationships,
		"preferences": npc_preferences
	}
	
	for npc_id in npc_memories:
		save_data.memories[npc_id] = []
		for memory in npc_memories[npc_id]:
			save_data.memories[npc_id].append({
				"type": memory.type,
				"content": memory.content,
				"importance": memory.importance,
				"emotion": memory.emotion,
				"day": memory.day
			})
	
	var file = FileAccess.open("user://npc_memories.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

# Load memories from disk
func load_memories():
	if not FileAccess.file_exists("user://npc_memories.json"):
		return
	
	var file = FileAccess.open("user://npc_memories.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not data:
		return
	
	npc_relationships = data.get("relationships", {})
	npc_preferences = data.get("preferences", {})
	
	# Reconstruct memories
	for npc_id in data.get("memories", {}):
		npc_memories[npc_id] = []
		for mem_data in data.memories[npc_id]:
			var memory = Memory.new(
				mem_data.type,
				mem_data.content,
				mem_data.importance,
				mem_data.emotion
			)
			memory.day = mem_data.day
			npc_memories[npc_id].append(memory)
