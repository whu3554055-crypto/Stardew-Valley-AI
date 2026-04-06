# Enhanced NPC System - Complete Implementation Guide

## Overview

This enhanced NPC system provides deep character immersion and environmental interactivity through:

✅ **Deep Personalization** - Secrets, quirks, occupational depth  
✅ **Dynamic Schedules** - Realistic daily routines with breaks and hobbies  
✅ **Contextual Awareness** - Reacts to player actions, weather, time, location  
✅ **NPC-to-NPC Dynamics** - Autonomous conversations based on relationships  
✅ **Rich Audio Feedback** - Emotion sounds, activity SFX, ambient audio  

## Architecture

```
EnhancedPersonalitySystem (Database)
    ↓
├── Complete NPC Profiles
│   ├── Basic Info (name, age, occupation)
│   ├── Personality Core (traits, values, fears, dreams)
│   ├── Occupational Depth (job behaviors, work topics)
│   ├── Preferences (gifts, weather, topics, food)
│   ├── Secrets & Quirks (hidden traits, reveal conditions)
│   ├── Speech Patterns (catchphrases, style characteristics)
│   ├── Dynamic Schedules (weekday, weekend, special days)
│   └── Audio Profile (voice pitch, emotion sounds, activity SFX)
    ↓
NPCAudioManager (Sound System)
    ↓
├── Emotion Sounds (laugh, sigh, gasp, hmm)
├── Activity Sounds (working, walking, farming)
├── Greeting Sounds (mood-based)
└── Ambient Sounds (location-based)
```

## 1. Deep NPC Personalization

### Complete Profile Structure

Each NPC has a comprehensive profile with 8 major sections:

```gdscript
npc_database["pierre"] = {
    "basic_info": {...},           // Name, age, occupation, family
    "personality_core": {...},     // Traits, values, fears, dreams, quirks
    "occupational_depth": {...},   // Job details, work behaviors
    "preferences": {...},          // Gifts, weather, topics, food
    "secrets_and_quirks": {...},   // Hidden secrets, reveal conditions
    "speech_patterns": {...},      // Catchphrases, speaking style
    "dynamic_schedule": {...},     // Daily routines by day type
    "audio_profile": {...}         // Voice characteristics, sound files
}
```

### Secrets System

Secrets are revealed based on relationship levels:

```gdscript
"secrets": [
    {
        "id": "financial_worries",
        "description": "Pierre secretly worries about money",
        "reveal_condition": {
            "relationship_min": 6,
            "trigger": "evening_conversation"
        },
        "revealed_dialogue": "Between you and me... business hasn't been as good as I'd like.",
        "impact": "Unlocks discount opportunities and business advice"
    }
]
```

**Usage**:
```gdscript
# Check available secrets
var secrets = EnhancedPersonalitySystem.get_npc_secrets("pierre", relationship_level=7)
for secret in secrets:
    print(secret.revealed_dialogue)
```

### Occupational Depth

NPCs have job-specific behaviors and topics:

```gdscript
"occupational_depth": {
    "job_description": "Runs the local general store",
    "work_schedule": {"open": 9.0, "close": 17.0},
    "work_topics": ["seed_quality", "crop_prices", "inventory"],
    "work_behaviors": {
        "during_work": ["organizing_shelves", "checking_ledger"],
        "busy_reaction": "I'll be with you in just a moment!",
        "slow_day_reaction": "Business has been quiet lately..."
    }
}
```

## 2. Dynamic Schedule System

### Schedule Structure

Schedules vary by day type and include modifications for weather/events:

```gdscript
"dynamic_schedule": {
    "weekday": {
        6.0: {
            "action": "wake_up",
            "location": "bedroom",
            "duration": 1.0,
            "animation": "stretching"
        },
        9.0: {
            "action": "open_store",
            "location": "general_store",
            "duration": 8.0,
            "animation": "behind_counter",
            "state": "working"
        }
    },
    "weekend": {...},
    "rainy_day": {
        "modifications": {
            "store_hours": {"open": 10.0, "close": 16.0},
            "mood_modifier": -0.1
        }
    }
}
```

### Getting Current Activity

```gdscript
# Get schedule for current day
var schedule = EnhancedPersonalitySystem.get_current_schedule("pierre", "weekday")

# Find current activity based on game time
var current_time = GameManager.current_time
for time_key in schedule:
    if float(time_key) <= current_time:
        var activity = schedule[time_key]
        # Execute activity logic
```

## 3. Contextual Awareness

### Weather Reactions

Each NPC has unique weather responses:

```gdscript
# Pierre's weather reactions
"sunny": "What a beautiful day! Perfect for business!"
"rain": "The crops will love this rain, though foot traffic might slow down..."
"storm": "I do hope the store roof holds up..."

# Abigail's weather reactions (completely different!)
"sunny": "Nice day, but kind of boring..."
"storm": "YES! Storm weather is PERFECT for adventure!"
```

**Usage**:
```gdscript
var reaction = EnhancedPersonalitySystem.get_weather_reaction("pierre", "rain")
print(reaction)  # "The crops will love this rain..."
```

### Gift Reaction System

Multi-level gift preferences with unique reactions:

```gdscript
var reaction = EnhancedPersonalitySystem.check_gift_reaction("abigail", "amethyst")
# Returns:
{
    "level": "loved",
    "reaction": "WHOA!!! This is AMAZING!!! How did you know?!",
    "relationship_gain": 80
}
```

**Gift Levels**:
- 😍 **Loved**: +80 points, excited reaction
- 🙂 **Liked**: +45 points, pleased reaction
- 😐 **Neutral**: +20 points, polite reaction
- 😕 **Disliked**: -20 points, disappointed reaction
- 😡 **Hated**: -50 points, upset reaction

### Topic Preferences

NPCs have strong opinions about conversation topics:

```gdscript
if EnhancedPersonalitySystem.loves_topic("lewis", "festivals"):
    # Lewis lights up talking about festivals
    start_enthusiastic_conversation()

if EnhancedPersonalitySystem.hates_topic("pierre", "jojamart"):
    # Avoid this topic!
    change_subject()
```

## 4. NPC-to-NPC Dynamics

### Relationship-Based Conversations

NPCs discuss relevant topics based on their relationships:

```gdscript
# Pierre and Abigail (father-daughter)
# Topics: Family concerns, store business, Abigail's adventures

# Pierre and Lewis (business-civic)
# Topics: Town events, crop prices, community welfare

# Abigail and Lewis (citizen-mayor)
# Topics: Town safety, cave dangers, youth activities
```

### Autonomous Interaction Topics

When NPCs interact autonomously, they choose topics based on:

1. **Relationship Type** - Family vs business vs friendship
2. **Current Activities** - What they're doing influences conversation
3. **Shared Interests** - Common topics both enjoy
4. **Recent Events** - Festivals, weather, town news

```gdscript
# Example: Pierre and Abigail interaction
# Context: Abigail returning from adventure
Pierre: "Abigail! You're back! Were you careful out there?"
Abigail: "Dad, I'm fine! I found some amazing crystals!"
Pierre: "Crystals? I hope you didn't spend too much money..."
```

## 5. Audio Feedback System

### Audio Categories

The system manages 4 types of audio:

#### A. Emotion Sounds
Played based on NPC's current emotional state:

```gdscript
# Play emotion vocalization
NPCAudioManager.play_emotion_sound("pierre", "happy")
# Plays: pierre_chuckle.wav

NPCAudioManager.play_emotion_sound("abigail", "excited")
# Plays: abigail_cheer.wav
```

**Available Emotions**:
- happy, excited, sad, angry, surprised, thinking, frustrated, determined

#### B. Activity Sounds
Played when NPCs perform actions:

```gdscript
# Play activity sound
NPCAudioManager.play_activity_sound("pierre", "working")
# Plays: register_ring.wav

NPCAudioManager.play_activity_sound("abigail", "sword_practice")
# Plays: sword_swing.wav
```

**Available Activities**:
- working, farming, cleaning, walking, reading, sword_practice, gaming, gardening

#### C. Greeting Sounds
Mood-based greeting vocalizations:

```gdscript
NPCAudioManager.play_greeting_sound("lewis", "neutral")
# Plays formal greeting sound
```

#### D. Ambient Sounds
Location-based background audio:

```gdscript
NPCAudioManager.play_ambient_sound("shop")
# Plays: shop_murmur.wav with bell sounds

NPCAudioManager.play_ambient_sound("farm")
# Plays: birds_chirp.wav
```

### Audio Configuration

Control audio settings:

```gdscript
# Adjust volumes
NPCAudioManager.set_volume_for_category("master", 0.8)
NPCAudioManager.set_volume_for_category("voice", 1.0)
NPCAudioManager.set_volume_for_category("ambient", 0.5)

# Toggle categories
NPCAudioManager.toggle_sound_category("emotion", true)
NPCAudioManager.toggle_sound_category("activity", false)

# Get status
var status = NPCAudioManager.get_audio_status()
print("Active sounds: ", status.active_sounds)
```

### Audio Priority System

Sounds have priority levels to prevent important sounds from being cut off:

```
Priority 7-10: Greetings, critical emotions
Priority 4-6:  Normal emotions, important activities
Priority 1-3:  Ambient sounds, minor activities
Priority 0:    Background noise
```

## Integration Examples

### Complete NPC Interaction with Audio

```gdscript
func interact_with_npc(npc_id: String, player_message: String):
    var npc = get_node(npc_id)
    
    # 1. Play greeting sound
    var mood = NPCEmotionSystem.get_emotion_description(npc_id)
    NPCAudioManager.play_greeting_sound(npc_id, mood)
    
    # 2. Get contextual response
    var context = {
        "player_message": player_message,
        "time": GameManager.current_time,
        "weather": WeatherSystem.get_weather_name(),
        "relationship": NPCMemorySystem.get_relationship(npc_id)
    }
    
    # 3. Generate AI response with personality
    var response = generate_personalized_response(npc_id, context)
    
    # 4. Play emotion sound based on response
    if "happy" in response.emotion.to_lower():
        NPCAudioManager.play_emotion_sound(npc_id, "happy")
    elif "excited" in response.emotion.to_lower():
        NPCAudioManager.play_emotion_sound(npc_id, "excited")
    
    # 5. Display dialogue
    show_dialogue_box(npc.npc_name, response.dialogue)
    
    # 6. Record interaction
    NPCMemorySystem.record_conversation(npc_id, player_message, response.dialogue)
```

### Weather-Based Behavior with Audio

```gdscript
func _on_weather_changed(new_weather: String):
    for npc_id in get_all_npcs():
        # Get weather reaction
        var reaction = EnhancedPersonalitySystem.get_weather_reaction(npc_id, new_weather)
        
        # Play appropriate sound
        if new_weather == "storm":
            if npc_id == "abigail":
                NPCAudioManager.play_emotion_sound(npc_id, "excited")
            else:
                NPCAudioManager.play_emotion_sound(npc_id, "concerned")
        
        # Show reaction if nearby
        if is_npc_nearby(npc_id):
            show_speech_bubble(npc_id, reaction)
```

### Schedule-Based Activity with Sounds

```gdscript
func update_npc_activities():
    var current_time = GameManager.current_time
    var day_type = get_current_day_type()  # weekday, weekend, festival
    
    for npc_id in get_all_npcs():
        var schedule = EnhancedPersonalitySystem.get_current_schedule(npc_id, day_type)
        var current_activity = get_activity_at_time(schedule, current_time)
        
        if current_activity:
            # Update NPC state
            set_npc_action(npc_id, current_activity.action)
            move_npc_to_location(npc_id, current_activity.location)
            
            # Play activity sound
            NPCAudioManager.play_activity_sound(npc_id, current_activity.animation)
            
            # Special social interactions
            if current_activity.has("social"):
                for partner in current_activity.social:
                    start_social_interaction(npc_id, partner)
```

## NPC Profiles Summary

### Pierre - The Shopkeeper

| Aspect | Details |
|--------|---------|
| **Occupation** | General Store Owner |
| **Personality** | Warm, family-oriented, business-minded |
| **Loves** | Gold bars, diamonds, family time, sunny weather |
| **Hates** | JojaMart, trash gifts, storms |
| **Secret** | Worries about money despite appearing successful |
| **Speech** | "Welcome to my store!", "Absolutely!", "Oh dear..." |
| **Audio** | Warm voice (pitch 1.0), chuckles when happy |
| **Schedule** | Opens store 9AM, closes 5PM, family evenings |

### Abigail - The Adventurer

| Aspect | Details |
|--------|---------|
| **Occupation** | Adventurer / Shopkeeper's Daughter |
| **Personality** | Energetic, independent, mysterious, impulsive |
| **Loves** | Amethyst, monster loot, storms, adventure |
| **Hates** | Hay, mayonnaise, boredom, chores |
| **Secret** | Eats gems, has latent magical abilities |
| **Speech** | "Hey!", "AWESOME!!!", "Totally!" |
| **Audio** | High energy voice (pitch 1.2), cheers when excited |
| **Schedule** | Helps store mornings, adventures afternoons, gaming nights |

### Mayor Lewis - The Leader

| Aspect | Details |
|--------|---------|
| **Occupation** | Town Mayor |
| **Personality** | Responsible, diplomatic, cautious, proud |
| **Loves** | Ancient artifacts, wine, festivals, order |
| **Hates** | Scandals, slime, disorder, Marnie secret exposed |
| **Secret** | Romantic relationship with Marnie |
| **Speech** | "Good day to you.", "Indeed.", "As mayor..." |
| **Audio** | Formal voice (pitch 0.9), clears throat authoritatively |
| **Schedule** | Town inspections, office work, Friday visits to Marnie |

## API Reference

### EnhancedPersonalitySystem

```gdscript
# Get complete profile
get_npc_complete_profile(npc_id: String) -> Dictionary

# Get preferences
get_npc_preferences(npc_id: String, category: String) -> Dictionary

# Get secrets (based on relationship)
get_npc_secrets(npc_id: String, relationship_level: int) -> Array

# Get schedule
get_current_schedule(npc_id: String, day_type: String) -> Dictionary

# Get audio file
get_audio_file(npc_id: String, category: String, emotion: String) -> String

# Check gift reaction
check_gift_reaction(npc_id: String, gift_id: String) -> Dictionary

# Get weather reaction
get_weather_reaction(npc_id: String, weather: String) -> String

# Topic preferences
loves_topic(npc_id: String, topic: String) -> bool
hates_topic(npc_id: String, topic: String) -> bool

# Catchphrases
get_catchphrase_by_context(npc_id: String, context: String) -> String
```

### NPCAudioManager

```gdscript
# Play sounds
play_npc_sound(npc_id, sound_type, sound_path, volume_db, pitch, priority) -> bool
play_emotion_sound(npc_id: String, emotion: String) -> bool
play_activity_sound(npc_id: String, activity: String) -> bool
play_greeting_sound(npc_id: String, mood: String) -> bool
play_ambient_sound(location: String) -> bool

# Control
stop_all_sounds_for_npc(npc_id: String)
stop_all_sounds()
set_volume_for_category(category: String, volume: float)
toggle_sound_category(category: String, enabled: bool)

# Status
get_active_sound_count() -> int
get_audio_status() -> Dictionary
```

## Performance Considerations

### Audio Optimization

- **Player Pooling**: Reuses 10 audio players instead of creating/destroying
- **Cooldown System**: Prevents sound spam (default 2s cooldown)
- **Priority System**: Important sounds can interrupt less important ones
- **Volume Scaling**: Automatic volume adjustment per category

### Memory Management

- **Lazy Loading**: Audio files loaded only when needed
- **Profile Caching**: NPC profiles loaded once at startup
- **Efficient Lookups**: Dictionary-based O(1) access to all data

## Future Enhancements

1. **Dynamic Learning** - NPCs learn new preferences over time
2. **Seasonal Variations** - Different schedules/preferences per season
3. **Group Dynamics** - Crowd behavior when multiple NPCs together
4. **Voice Acting** - Full voice lines for key dialogue
5. **Music Triggers** - NPC-specific theme music in certain situations
6. **Emotional Contagion** - NPCs influence each other's moods

---

**This system creates living, breathing characters that feel real!** 🎉

Each NPC is now a complex individual with:
- Deep personalities and hidden secrets
- Realistic daily routines
- Unique audio signatures
- Context-aware reactions
- Meaningful relationships

**The valley feels alive!**
