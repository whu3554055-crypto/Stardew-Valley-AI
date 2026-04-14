# Quick Start: Enhanced NPC System with Audio

## Getting Started in 5 Minutes

### 1. Open Your Project
```bash
"D:\program\Godot_v4.6.2-stable_win64.exe" --path d:\repo\stardew_valley
```

### 2. Verify Autoloads
Check `Project > Project Settings > Autoload` - you should see:
- EnhancedPersonalitySystem
- NPCAudioManager
- AdvancedAIManager
- NPCBehaviorController
- (and 9 others)

### 3. Test an NPC

Create a test scene or use existing NPC scenes:

```gdscript
# In any script, you can now access:

# Get NPC personality data
var profile = EnhancedPersonalitySystem.get_npc_complete_profile("pierre")
print(profile.basic_info.name)  # "Pierre"

# Check gift preference
var reaction = EnhancedPersonalitySystem.check_gift_preference("pierre", "diamond")
print(reaction.level)  # "loved"

# Get a catchphrase
var phrase = EnhancedPersonalitySystem.get_catchphrase("pierre", "greeting")
print(phrase)  # "Welcome to Pierre's General Store!"

# Play sounds
NPCAudioManager.play_emotion_sound("pierre", "happy")
NPCAudioManager.play_activity_sound("pierre", "working")
```

### 4. Add Audio Files (Optional)

The system works without audio files (it just won't play sounds), but for full immersion:

1. Create folder structure:
```
assets/
  audio/
    sfx/
      emotions/
        happy.wav
        sad.wav
        angry.wav
      activities/
        footsteps_grass.wav
        work_tools.wav
        page_turn.wav
      greetings/
        morning_greeting.wav
        evening_greeting.wav
    ambience/
      shop_bell.wav
      town_fountain.wav
```

2. Update paths in `autoload/enhanced_personality_system.gd`:
```gdscript
"audio_profile": {
    "emotion_sounds": {
        "happy": ["res://assets/audio/sfx/emotions/pierre_happy.wav"]
    }
}
```

## Common Use Cases

### Giving a Gift to an NPC

```gdscript
func give_gift_to_npc(npc_id: String, gift_id: String):
    var npc = get_node("NPC_" + npc_id)
    if not npc:
        return
    
    var reaction = npc.react_to_gift(gift_id)
    
    match reaction.level:
        "loved":
            print("They loved it! +80 points")
        "liked":
            print("They liked it! +45 points")
        "disliked":
            print("They didn't like it... -20 points")
        "hated":
            print("They hated it! -40 points")
```

### Creating a New NPC

```gdscript
# 1. Create new scene extending CharacterBody2D
# 2. Attach advanced_npc.gd script
# 3. Set properties in inspector:
#    - npc_id: "my_new_npc"
#    - npc_name: "My New NPC"
#    - use_ai_dialogue: true
#    - occupation: "Blacksmith"
#    - etc.

# 4. Add to EnhancedPersonalitySystem database:
# Edit autoload/enhanced_personality_system.gd
npc_database["my_new_npc"] = {
    "basic_info": {...},
    "personality_core": {...},
    # ... (see existing NPCs for template)
}
```

### Customizing Schedules

```gdscript
# In enhanced_personality_system.gd, edit dynamic_schedule:
"dynamic_schedule": {
    "weekday": {
        "6:00": {"action": "waking_up", "location": "home"},
        "9:00": {"action": "opening_shop", "location": "store"},
        "17:00": {"action": "closing_shop", "location": "store"},
        "22:00": {"action": "sleeping", "location": "home"}
    },
    "weekend": {
        # Different schedule for weekends
    },
    "rainy": {
        # Adjustments for rainy days
    }
}
```

### Adjusting Audio Volume

```gdscript
# In-game settings menu
func _on_master_volume_changed(value):
    NPCAudioManager.set_category_volume("master", value)

func _on_emotion_volume_changed(value):
    NPCAudioManager.set_category_volume("emotion", value)

func _on_ambient_volume_changed(value):
    NPCAudioManager.set_category_volume("ambient", value)
```

## Troubleshooting

### No Sounds Playing
1. Check if audio files exist at specified paths
2. Verify AudioStreamPlayer nodes are created (check scene tree)
3. Ensure volume levels aren't set too low
4. Check Godot's audio bus configuration

### NPCs Not Responding
1. Verify Ollama is running: `ollama list`
2. Check ai_config.json has correct model name
3. Ensure AdvancedAIManager is in autoload list
4. Check console for error messages

### Catchphrases Not Showing
1. Verify NPC has catchphrase_label node
2. Check EnhancedPersonalitySystem is loaded
3. Increase probability in update_catchphrases() (default 0.001 = 0.1%/frame)

### Performance Issues
1. Reduce MAX_CONCURRENT_SOUNDS in NPCAudioManager (default 10)
2. Increase DEFAULT_COOLDOWN to reduce sound frequency
3. Disable ambient sounds if needed: `enable_ambient_sounds = false`

## API Reference

### EnhancedPersonalitySystem

```gdscript
# Get complete NPC profile
get_npc_complete_profile(npc_id: String) -> Dictionary

# Check gift reactions
check_gift_preference(npc_id: String, gift_id: String) -> Dictionary
# Returns: {"level": "loved|liked|disliked|hated", "points": int}

# Get catchphrases
get_catchphrase(npc_id: String, context: String) -> String
# Contexts: "greeting", "excitement", "concern", "agreement", "filler"

# Get sounds
get_activity_sounds(npc_id: String, activity: String) -> Array
get_greeting_sounds(npc_id: String, situation: String) -> Array
get_ambient_sounds(npc_id: String, location: String) -> Array

# Get behaviors
get_habitual_action(npc_id: String, mood: String) -> String
get_special_reaction(npc_id: String, reaction_type: String) -> String

# Check topics
loves_topic(npc_id: String, topic: String) -> bool
hates_topic(npc_id: String, topic: String) -> bool

# Get schedules
get_current_schedule(npc_id: String, day_type: String) -> Dictionary

# Get secrets (relationship-based)
get_npc_secrets(npc_id: String, relationship_level: int) -> Array
```

### NPCAudioManager

```gdscript
# Play sounds (returns true if successful)
play_emotion_sound(npc_id: String, emotion: String, volume_db=-10, priority=5) -> bool
play_activity_sound(npc_id: String, sound_path: String, volume_db=-12, priority=3) -> bool
play_greeting_sound(npc_id: String, sound_path: String, volume_db=-8, priority=7) -> bool
play_ambient_sound(npc_id: String, sound_path: String, volume_db=-15, priority=2) -> bool

# Control volumes
set_category_volume(category: String, volume_db: float)
# Categories: "master", "emotion", "activity", "greeting", "ambient"

# Reset cooldowns (useful for testing)
reset_cooldowns()

# Get currently playing sounds
get_active_sounds() -> Dictionary
```

## Example: Complete Interaction

```gdscript
extends Node2D

@onready var pierre = $Pierre  # AdvancedNPC instance

func _ready():
    # Connect to NPC signals
    pierre.dialogue_ready.connect(_on_dialogue)
    pierre.spontaneous_speech.connect(_on_spontaneous)

func interact_with_pierre():
    # Give Pierre a diamond
    var reaction = pierre.react_to_gift("diamond")
    
    # He'll automatically:
    # 1. Play happy emotion sound
    # 2. Show catchphrase bubble
    # 3. Update relationship
    # 4. Generate AI response
    
    print("Pierre's reaction: ", reaction.level)
    print("Relationship points: ", reaction.points)

func _on_dialogue(npc_id: String, dialogue_data: Dictionary):
    if dialogue_data.has("dialogue"):
        print("%s says: %s" % [npc_id, dialogue_data.dialogue])
    
    if dialogue_data.has("action"):
        print("%s does: %s" % [npc_id, dialogue_data.action])
    
    if dialogue_data.has("emotion"):
        print("%s feels: %s" % [npc_id, dialogue_data.emotion])

func _on_spontaneous(npc_id: String, speech_data: Dictionary):
    print("%s spontaneously: %s" % [npc_id, speech_data.get("text", "")])
```

## Resources

- **Full Documentation**: `ENHANCED_NPC_SYSTEM.md`
- **Integration Guide**: `INTEGRATION_COMPLETE.md`
- **Multi-Agent Architecture**: `ADVANCED_AI_SYSTEM.md`
- **Personality System**: `NPC_PERSONALITY_GUIDE.md`

## Support

For issues or questions:
1. Check console output for error messages
2. Verify all autoloads are registered
3. Review documentation files
4. Test with simple examples first

Enjoy your lifelike NPCs!
