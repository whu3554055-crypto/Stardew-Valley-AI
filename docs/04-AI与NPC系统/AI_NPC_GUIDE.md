# AI-Powered NPC System Guide

## Overview

This project now includes an advanced AI agent system that makes NPCs behave more like real people through:
- **Dynamic Dialogue**: AI-generated responses based on context, personality, and relationship
- **Memory System**: NPCs remember past interactions and reference them naturally
- **Emotion System**: NPCs have moods that change based on events and affect their behavior
- **Personality Profiles**: Each NPC has unique traits, interests, and speech styles

## Architecture

### Three Core Systems

1. **AIAgentManager** (`autoload/ai_agent_manager.gd`)
   - Handles LLM API communication
   - Builds contextual prompts for NPCs
   - Caches responses to reduce API calls
   - Supports Ollama (local) and OpenAI-compatible APIs

2. **NPCMemorySystem** (`autoload/npc_memory_system.gd`)
   - Stores conversation history
   - Tracks relationships with players
   - Learns player preferences
   - Provides relevant memories for context

3. **NPCEmotionSystem** (`autoload/npc_emotion_system.gd`)
   - Manages NPC emotional states
   - Defines personality traits
   - Triggers emotions based on events
   - Modifies behavior based on mood

## Setup Instructions

### Option 1: Local AI with Ollama (Recommended)

1. **Install Ollama**
   ```bash
   # Windows
   # Download from https://ollama.com/download
   
   # macOS
   brew install ollama
   
   # Linux
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. **Pull a Model**
   ```bash
   # Smaller model (faster, less accurate)
   ollama pull qwen2.5:3b
   
   # Medium model (balanced)
   ollama pull qwen2.5:7b
   
   # Larger model (slower, more accurate)
   ollama pull qwen2.5:14b
   ```

3. **Start Ollama**
   ```bash
   ollama serve
   ```

4. **Configure in Game**
   - Press the AI Config button (or add to your UI)
   - Set Base URL: `http://localhost:11434`
   - Set Model: `qwen2.5:7b` (or whichever you pulled)
   - Click "Test Connection"
   - Click "Save Configuration"

### Option 2: OpenAI-Compatible API

1. Get an API key from providers like:
   - OpenAI (GPT models)
   - Anthropic (Claude)
   - Any OpenAI-compatible endpoint

2. Configure in game:
   - Base URL: `https://api.openai.com/v1`
   - Model: `gpt-3.5-turbo` or your chosen model
   - Add authentication headers (modify `ai_agent_manager.gd` if needed)

## Using AI NPCs

### Basic Interaction

```gdscript
# In your main scene or dialogue system
func _on_player_interact_npc(npc: NPC):
    # Simple interaction (uses static dialogue or AI)
    var response = npc.interact()
    show_dialogue(response)
    
    # Or with player message for AI
    var player_message = "Hello, how are you?"
    npc.interact(player_message)
    
    # Listen for AI response
    npc.dialogue_ready.connect(func(text): show_dialogue(text))
```

### Creating Custom AI NPCs

1. **Create NPC Scene**
```gdscript
[node name="MyNPC" type="CharacterBody2D"]
script = ExtResource("1_npc")
npc_id = "my_unique_npc"
npc_name = "Character Name"
use_ai_dialogue = true
ai_personality = {
    "traits": ["curious", "shy", "intelligent"],
    "occupation": "Librarian",
    "backstory": "A quiet librarian who loves books and knows ancient secrets.",
    "speech_style": "shy",
    "interests": ["books", "history", "mysteries", "tea"]
}
```

2. **Speech Style Options**
   - `"casual"` - Relaxed, friendly
   - `"formal"` - Proper, sophisticated
   - `"shy"` - Hesitant, soft-spoken
   - `"energetic"` - Enthusiastic, dynamic
   - `"mysterious"` - Cryptic, enigmatic
   - `"gruff"` - Blunt, rough

3. **Personality Traits** (affects behavior)
   - `friendliness` (0-1): How warm/friendly they are
   - `patience` (0-1): Tolerance for repeated interactions
   - `energy` (0-1): Movement speed and enthusiasm
   - `sensitivity` (0-1): Emotional responsiveness
   - Custom traits for roleplay flavor

### Memory System Usage

```gdscript
# Record important events
NPCMemorySystem.record_event(
    "pierre",
    "Player helped me find my lost item",
    0.9,  # High importance
    "grateful"
)

# Learn player preferences
NPCMemorySystem.learn_preference(
    "abigail",
    "likes_gifts",
    ["amethyst", "monster_loot"],
    0.8
)

# Get relationship level (0-10)
var relationship = NPCMemorySystem.get_relationship("pierre")

# Get relevant memories for context
var memories = NPCMemorySystem.get_relevant_memories(
    "pierre",
    ["farming", "seeds"],
    3  # Max 3 memories
)
```

### Emotion System Usage

```gdscript
# Trigger emotion based on event
NPCEmotionSystem.trigger_emotion(
    "abigail",
    "gift_received",
    {"relationship": 7}  # Context modifiers
)

# Manually set emotion
NPCEmotionSystem.set_emotion(
    "lewis",
    NPCEmotionSystem.BasicEmotion.HAPPY,
    0.8,  # Intensity
    180.0,  # Duration in seconds
    "Festival announcement"
)

# Get current emotional state
var mood = NPCEmotionSystem.get_emotion_description("pierre")
# Returns: "happy", "very excited", "slightly sad", etc.

# Get dialogue modifier
var modifier = NPCEmotionSystem.get_dialogue_modifier("abigail")
# Returns: {tone: "positive", enthusiasm: 0.8, warmth: 0.7}
```

## Prompt Engineering

The system builds rich prompts for the LLM. You can customize this in `ai_agent_manager.gd`:

### Prompt Components

1. **Character Profile**: Name, occupation, traits, backstory
2. **Current Context**: Time, weather, season, location
3. **Relationship Level**: How well they know the player
4. **Recent Interactions**: Last 3-5 conversations
5. **Speech Style Guide**: How to format dialogue

### Customizing Prompts

```gdscript
# Add custom instructions when calling
AIAgentManager.generate_dialogue(
    npc_id,
    npc_name,
    personality,
    context,
    recent_interactions,
    "Custom instruction: Always mention the weather in your response."
)
```

## Performance Optimization

### Caching
- Responses are cached for 5 minutes
- Same context + history = cached response
- Reduces API calls significantly

### Tips
1. Use smaller models (3B-7B) for faster responses
2. Limit `max_tokens` to 128-256 for dialogue
3. Lower temperature (0.7-0.9) for consistent personalities
4. Run Ollama on GPU if available

## Debugging

### Enable Logging
```gdscript
# In ai_agent_manager.gd, add:
print("Prompt sent to AI: ", full_prompt)
print("AI Response: ", generated_text)
```

### Test Connection
Use the AI Config UI's "Test Connection" button to verify API connectivity.

### Check Memory/Emotion State
```gdscript
# Print NPC state
print("Pierre's memories: ", NPCMemorySystem.npc_memories.get("pierre", []))
print("Pierre's emotion: ", NPCEmotionSystem.get_emotion_description("pierre"))
print("Relationship: ", NPCMemorySystem.get_relationship("pierre"))
```

## Advanced Features

### Schedule-Based Behavior
```gdscript
# Define NPC daily schedule
var schedule = {
    6.0: Vector2(100, 200),   # 6 AM: Home
    9.0: Vector2(400, 300),   # 9 AM: Shop
    12.0: Vector2(500, 350),  # Noon: Lunch spot
    17.0: Vector2(400, 300),  # 5 PM: Back to shop
    20.0: Vector2(100, 200)   # 8 PM: Home
}
npc.set_schedule(schedule)
```

### Event-Triggered Emotions
```gdscript
# In your game logic
func _on_player_gives_gift(npc_id: String, gift_id: String):
    NPCEmotionSystem.trigger_emotion(npc_id, "gift_received")
    NPCMemorySystem.update_relationship(npc_id, 0.5)
    
    # Check if it's their favorite
    var preferences = NPCMemorySystem.get_preferences(npc_id)
    if preferences.get("favorite_gifts", []).has(gift_id):
        NPCEmotionSystem.trigger_emotion(npc_id, "favorite_gift")
        NPCMemorySystem.update_relationship(npc_id, 1.0)
```

### Weather/Mood Integration
```gdscript
# NPCs react to weather
if WeatherSystem.is_raining():
    NPCEmotionSystem.trigger_emotion(npc_id, "weather_rain")
    
# Time-based moods
var hour = int(GameManager.current_time)
if hour >= 20:  # Evening
    NPCEmotionSystem.set_emotion(npc_id, 
        NPCEmotionSystem.BasicEmotion.CALM, 0.6)
```

## Example: Complete NPC Interaction Flow

```gdscript
# Player interacts with Pierre
func talk_to_pierre():
    var pierre = get_node("Pierre")
    
    # Player says something
    var player_message = "Do you have any parsnip seeds?"
    
    # This triggers:
    # 1. Memory lookup for context
    # 2. Emotion check for mood
    # 3. AI prompt generation
    # 4. API call to LLM
    pierre.interact(player_message)
    
    # Wait for AI response
    await pierre.dialogue_ready
    
    # Display response
    show_dialogue_box(pierre.current_dialogue)
    
    # Systems automatically:
    # - Record conversation in memory
    # - Update relationship slightly
    # - Adjust emotion if needed
    # - Cache response for efficiency
```

## Troubleshooting

### AI Not Responding
1. Check Ollama is running: `ollama list`
2. Verify model is downloaded: `ollama pull qwen2.5:7b`
3. Check base URL in config
4. Look for errors in Godot console

### Responses Too Slow
1. Use smaller model (3B instead of 7B)
2. Reduce `max_tokens` to 128
3. Lower temperature for faster sampling
4. Enable GPU acceleration in Ollama

### Personality Not Consistent
1. Increase temperature slightly (0.8-0.9)
2. Make backstory more detailed
3. Add more specific traits
4. Provide example dialogues in prompt

### Memory Not Working
1. Check if `NPCMemorySystem` is in autoload
2. Verify `npc_id` matches across systems
3. Save/load functions called properly
4. Check `user://npc_memories.json` exists

## Next Steps

1. **Add More NPCs**: Create diverse personalities
2. **Custom Events**: Hook into game events for emotion triggers
3. **Quest Integration**: NPCs remember quest progress
4. **Gift System**: Learn and react to player gifts
5. **Relationship Milestones**: Unlock new dialogue at relationship levels
6. **Group Conversations**: Multiple NPCs interacting
7. **Voice Acting**: TTS integration for spoken dialogue

## Resources

- [Ollama Documentation](https://ollama.com/docs)
- [Godot HTTPRequest](https://docs.godotengine.org/en/stable/classes/class_httprequest.html)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
