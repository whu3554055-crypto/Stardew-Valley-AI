# Advanced AI Systems - Complete Implementation Guide

## Overview

This document describes the comprehensive AI-driven systems that make NPCs feel like living, breathing individuals in a dynamic world. The implementation includes:

1. **Rich NPC Trait System** - Deep personality modeling with mood, relationships, skills, memories, goals, and fears
2. **Hybrid Modular Architecture** - Plugin-based system for easy maintenance and extensibility
3. **AI-Driven Economy** - Autonomous market simulation with dynamic pricing and NPC trading
4. **AI Event Generation** - Spontaneous world events driven by AI analysis
5. **AI Quest Generation** - Emergent quests based on NPC needs and world state

---

## 1. Rich NPC Trait System (NPCTraitSystem)

### Architecture

The trait system manages six core dimensions of NPC psychology:

#### A. Mood System
Dynamic emotional states using the VAD (Valence-Arousal-Dominance) model.

```gdscript
# Initialize mood for an NPC
NPCTraitSystem.initialize_mood_system("pierre")

# Set mood with intensity and duration
NPCTraitSystem.set_mood("pierre", "excited", 0.8, duration=120.0)

# Add temporary mood modifier
NPCTraitSystem.add_mood_modifier("pierre", "coffee_boost", 0.2, duration=60.0)

# Update mood over time (call in _process)
NPCTraitSystem.update_mood("pierre", delta)

# Get current mood state
var mood = NPCTraitSystem.get_mood_state("pierre")
print(mood.current)  # "excited"
print(mood.intensity)  # 0.8
```

**Features:**
- 8 base moods: happy, sad, angry, excited, anxious, tired, energetic, melancholic
- Intensity tracking (0-1 scale)
- Natural decay toward baseline personality
- Temporary modifiers from events/items
- Mood history tracking (last 50 entries)
- Volatility and resilience parameters per NPC

#### B. Relationship System
Dynamic social bonds between NPCs and player.

```gdscript
# Initialize relationship
NPCTraitSystem.initialize_relationship("pierre", "player")

# Update relationship points
NPCTraitSystem.update_relationship("pierre", "player", 15, "Gave loved gift")

# Get relationship data
var rel = NPCTraitSystem.get_relationship("pierre", "player")
print(rel.level)  # 0-10 scale
print(rel.status)  # "friend", "best_friend", etc.

# Add shared memory
NPCTraitSystem.add_shared_memory("pierre", "player", "Attended flower dance together")
```

**Relationship Levels:**
- 0-1: Stranger
- 2-4: Acquaintance
- 5-6: Friend
- 7-8: Good Friend
- 9-10: Best Friend (or Rival if negative interactions)

**Tracked Data:**
- Points (accumulated, every 100 = 1 level)
- Trust level (0-1)
- Affinity (natural compatibility)
- Interaction history (last 100)
- Gifts given/received
- Conflicts and favors
- Shared memories

#### C. Skill System
NPC competencies that improve over time.

```gdscript
# Initialize skills
NPCTraitSystem.initialize_skills("pierre")

# Gain skill experience
NPCTraitSystem.gain_skill_experience("pierre", "social", 50.0)

# Get skill level
var farming_level = NPCTraitSystem.get_skill_level("abigail", "farming")

# Get all skills
var all_skills = NPCTraitSystem.get_all_skills("pierre")
```

**Skill Categories:**
- Farming
- Mining
- Fishing
- Cooking
- Crafting
- Social
- Combat

Each skill has:
- Level (1-10)
- Experience points
- Learning rate (individual variation)
- Last practiced timestamp

#### D. Memory System
Long-term event storage with emotional tagging.

```gdscript
# Initialize memory system
NPCTraitSystem.initialize_memory_system("pierre")

# Form a memory
NPCTraitSystem.form_memory(
    "pierre",
    "Player gave me a diamond for my birthday",
    0.9,  # importance (0-1)
    "positive"  # emotional valence
)

# Recall memories about a topic
var memories = NPCTraitSystem.recall_memories("pierre", "gift", limit=5)
for memory in memories:
    print(memory.event)
    print(memory.emotional_valence)

# Get emotional bias
var bias = NPCTraitSystem.get_emotional_bias("pierre")
print(bias.positive)  # How many positive memories
```

**Memory Types:**
- Short-term (last 20 events, subject to forgetting)
- Long-term (important events, permanent)
- Emotional tags (positive, negative, neutral, traumatic, joyful)

#### E. Goal System
NPC aspirations and objectives.

```gdscript
# Initialize goals
NPCTraitSystem.initialize_goals("pierre")

# Add a goal
NPCTraitSystem.add_goal(
    "pierre",
    "expand_store",
    "Expand the general store to sell more items",
    priority=8,
    deadline=Time.get_unix_time_from_system() + 86400 * 30  # 30 days
)

# Update progress
NPCTraitSystem.update_goal_progress("pierre", "expand_store", 0.2)

# Get active goals
var goals = NPCTraitSystem.get_active_goals("pierre")

# Get top priority goal
var top_goal = NPCTraitSystem.get_top_priority_goal("pierre")
```

**Goal Types:**
- Short-term (days)
- Medium-term (weeks)
- Long-term (months)
- Secret (hidden motivations)

#### F. Fear System
NPC anxieties and phobias affecting behavior.

```gdscript
# Initialize fears
NPCTraitSystem.initialize_fears("abigail", {
    "darkness": 0.7,
    "confinement": 0.5
})

# Trigger a fear
NPCTraitSystem.trigger_fear("abigail", "darkness", 0.6)

# Get anxiety level
var anxiety = NPCTraitSystem.get_anxiety_level("abigail")

# Reduce anxiety
NPCTraitSystem.reduce_anxiety("abigail", 0.3)
```

**Common Fears:**
- Rejection
- Failure
- Loneliness
- Poverty
- Darkness
- Water
- Heights

### Personality Evolution

NPCs evolve based on life experiences:

```gdscript
var life_events = [
    {"event": "Received generous gift", "valence": "positive"},
    {"event": "Store robbed", "valence": "negative"}
]

NPCTraitSystem.evolve_personality("pierre", life_events)
# This can shift baseline mood, volatility, etc.
```

---

## 2. Hybrid Modular Architecture (NPCPluginManager)

### Philosophy

The hybrid approach combines:
- **Core traits** in main NPC script (always present)
- **Optional plugins** for advanced features (load/unload as needed)
- **Hot-swappable** modules for runtime flexibility

### Plugin Management

```gdscript
# Register a custom plugin
NPCPluginManager.register_plugin("my_custom_trait", preload("res://plugins/my_trait.gd"), {
    "description": "My custom NPC trait",
    "version": "1.0.0",
    "auto_load": true,
    "optional": false,
    "dependencies": ["mood_enhanced"]
})

# Load plugin for specific NPC
NPCPluginManager.load_plugin_for_npc("pierre", "economy_trader")

# Load plugin for all NPCs
NPCPluginManager.load_plugin_for_all_npcs("social_dynamics")

# Check if plugin is loaded
if NPCPluginManager.is_plugin_loaded_for_npc("pierre", "mood_enhanced"):
    print("Pierre has enhanced mood!")

# Get plugin instance
var plugin = NPCPluginManager.get_plugin_for_npc("pierre", "mood_enhanced")
if plugin:
    var modifiers = plugin.get_dialogue_modifiers()

# Unload plugin
NPCPluginManager.unload_plugin_from_npc("pierre", "economy_trader")

# Get all plugins for NPC
var plugins = NPCPluginManager.get_all_plugins_for_npc("pierre")
```

### Built-in Plugins

#### 1. Mood Enhanced Plugin
Advanced emotional intelligence with VAD model.

```gdscript
var plugin = NPCPluginManager.get_plugin_for_npc("pierre", "mood_enhanced")

# Calculate emotional response to event
var response = plugin.calculate_emotional_response("received_gift", {
    "impact": 0.8
})
print(response.emotion)  # "excited"
print(response.vad)  # {valence: 0.8, arousal: 0.7, dominance: 0.6}

# Get mood influence on decisions
var influence = plugin.get_mood_influence_on_decision()
print(influence.risk_tolerance)  # Higher when happy

# Emotional contagion from other NPCs
plugin.catch_emotion_from("abigail", 0.5)

# Get dialogue modifiers based on mood
var modifiers = plugin.get_dialogue_modifiers()
print(modifiers.tone)  # "cheerful", "somber", etc.
```

#### 2. Social Dynamics Plugin
Group interactions and social influence.

```gdscript
var plugin = NPCPluginManager.get_plugin_for_npc("pierre", "social_dynamics")

# Join a social group
plugin.join_group("merchants", ["pierre", "other_shopkeeper"])

# Calculate influence on another NPC
var influence = plugin.calculate_influence_on("abigail")

# Form opinion on topic
var opinion = plugin.form_opinion("town_development", initial_stance=0.6)

# Handle conflict
var resolution = plugin.handle_conflict("abigail", "business_disagreement")
print(resolution.outcome)  # "compromise", "escalation", etc.

# Calculate social status
var status = plugin.calculate_social_status()
```

#### 3. Economy Trader Plugin
Individual NPC economic behavior.

#### 4. Quest Giver Plugin
AI-driven quest assignment.

#### 5. Memory Enhanced Plugin
Semantic memory search and retrieval.

#### 6. Schedule Manager Plugin
Flexible scheduling with adaptations.

#### 7. Rumor System Plugin
Information spreading between NPCs.

#### 8. Skill Mastery Plugin
Advanced skill progression.

### Creating Custom Plugins

```gdscript
# plugins/my_custom_plugin.gd
extends RefCounted

class_name MyCustomPlugin

var plugin_config = {}
var npc_id = ""
var plugin_name = "my_custom"

func _plugin_init() -> bool:
    print("[MyCustomPlugin] Initialized for ", npc_id)
    return true

func _plugin_cleanup():
    print("[MyCustomPlugin] Cleaned up for ", npc_id)

func _plugin_save_state() -> Dictionary:
    return {"custom_data": "value"}

func _plugin_load_state(state: Dictionary):
    pass

# Your custom methods
func do_something_special():
    print("Special action for ", npc_id)
```

---

## 3. AI-Driven Economy System (AIEconomySystem)

### Features

- **Dynamic Pricing**: Supply/demand-based price fluctuations
- **Vendor AI**: Autonomous business decisions
- **Market Trends**: AI-identified patterns and predictions
- **Seasonal Effects**: Weather and season impact on economy
- **Economic Events**: Booms, recessions, shortages

### Usage

```gdscript
# Get current price for item
var price = AIEconomySystem.get_current_price("diamond")
print(price)  # Dynamically calculated

# Get price trend
var trend = AIEconomySystem.get_price_trend("diamond")
print(trend)  # "rising", "falling", "stable", "volatile"

# Get top demanded items
var top_items = AIEconomySystem.get_top_demanded_items(5)
print(top_items)  # ["wheat", "corn", ...]

# Listen for price changes
AIEconomySystem.price_changed.connect(func(item_id, old_price, new_price, reason):
    print("%s price changed from %d to %d: %s" % [item_id, old_price, new_price, reason])
)

# Listen for market trends
AIEconomySystem.market_trend_updated.connect(func(trend_data):
    for trend in trend_data.trends:
        print("Trend: %s - %s" % [trend.item, trend.pattern])
)

# Get AI decision history
var decisions = AIEconomySystem.get_ai_decision_history(10)
for decision in decisions:
    print(decision.type, decision.data)
```

### Economic Simulation

The system autonomously:
1. Updates supply/demand every in-game hour
2. Adjusts prices based on market forces
3. Identifies emerging trends
4. Triggers economic events when conditions met
5. Makes vendor restocking decisions
6. Applies seasonal/weather modifiers

### Integration with Shops

```gdscript
# In shop system
func get_item_price(item_id: String) -> int:
    # Get AI-calculated price
    var base_price = AIEconomySystem.get_current_price(item_id)

    # Apply vendor markup
    var vendor = AIEconomySystem.market_state.vendors.get(current_vendor)
    if vendor:
        base_price *= vendor.markup

    return int(base_price)
```

---

## 4. AI Event Generation System (AIEventSystem)

### Event Categories

1. **Weather Events**: Storms, meteor showers, heatwaves
2. **Social Events**: Festivals, competitions, gatherings
3. **Emergency Events**: Fires, missing persons, outbreaks
4. **Economic Events**: Market booms, shortages
5. **Personal Events**: Birthdays, anniversaries, crises

### Autonomous Generation

The system continuously analyzes:
- Town mood and stress levels
- NPC needs and desires
- Environmental conditions
- Narrative opportunities
- Recent event history

Then generates appropriate events.

### Usage

```gdscript
# Listen for generated events
AIEventSystem.event_generated.connect(func(event_type, event_data):
    print("New %s event: %s" % [event_type, event_data.name])
    print(event_data.description)
)

# Listen for event start
AIEventSystem.event_started.connect(func(event_id, event_info):
    print("Event started: ", event_info.name)
)

# Listen for event end
AIEventSystem.event_ended.connect(func(event_id, outcome):
    print("Event ended with outcome: ", outcome)
)

# Get active events
var active = AIEventSystem.get_active_events()
for event in active:
    print(event.name, " - ", event.category)

# Get world state
var state = AIEventSystem.get_world_state_summary()
print("Town mood: ", state.mood)
print("Prosperity: ", state.prosperity)
print("Stress level: ", state.stress_level)
```

### Example Generated Event

```json
{
    "id": "evt_1234567890_42",
    "name": "Thunderstorm",
    "category": "weather",
    "description": "A severe thunderstorm sweeps through the valley",
    "severity": "moderate",
    "duration_hours": 8,
    "effects": {
        "crops_watered": true,
        "outdoor_penalty": -0.3,
        "indoor_bonus": 0.2,
        "mood_impact": -0.1
    },
    "ai_triggers": [
        "Low crop hydration levels",
        "High temperature buildup"
    ]
}
```

### NPC Reactions to Events

NPCs automatically react to events based on their traits:
- Excitable NPCs respond more intensely
- Friends coordinate responses
- Fearful NPCs may panic
- Leaders take charge

---

## 5. AI Quest Generation System (AIQuestSystem)

### Quest Types

1. **Fetch Quests**: Find and retrieve items
2. **Delivery Quests**: Transport items between NPCs
3. **Problem-Solving**: Help NPCs resolve issues
4. **Relationship Building**: Mend social bonds
5. **Skill Challenges**: Demonstrate abilities
6. **Mysteries**: Investigate strange occurrences
7. **Emergencies**: Time-critical rescue missions

### Autonomous Generation

The system analyzes:
- NPC goals and needs
- World events requiring response
- Relationship dynamics
- Economic conditions
- Ongoing narrative threads

Then creates contextually appropriate quests.

### Usage

```gdscript
# Listen for generated quests
AIQuestSystem.quest_generated.connect(func(quest_id, quest_data):
    print("New quest: ", quest_data.name)
    print(quest_data.description)
    print("Rewards: ", quest_data.rewards)
)

# Complete a quest
AIQuestSystem.complete_quest("quest_123", success=true, extra_data={
    "completion_time": 3600,
    "bonus_objectives": ["completed_early"]
})

# Get active quests
var quests = AIQuestSystem.get_active_quests()
for quest in quests:
    print(quest.name, " - ", quest.status)

# Get quests for specific NPC
var pierre_quests = AIQuestSystem.get_quests_for_npc("pierre")
```

### Example Generated Quest

```json
{
    "id": "quest_1234567890_42",
    "template": "fetch_item",
    "type": "fetch",
    "name": "Find Ancient Sword for Abigail",
    "description": "Abigail needs an Ancient Sword because it's a rare collectible she's been seeking. This item has sentimental value to Abigail.",
    "difficulty": "medium",
    "target_item": "ancient_sword",
    "time_limit": 1234567890,
    "rewards": {
        "gold": 250,
        "friendship": 25,
        "unique_item": true
    }
}
```

### Narrative Threads

Multi-quest storylines:

```gdscript
# Create a narrative thread
var thread_id = AIQuestSystem.create_narrative_thread({
    "title": "The Mysterious Stranger",
    "description": "A stranger arrives in town with secrets",
    "steps": 5,
    "importance": 0.8,
    "next_quest_type": "investigation"
})

# Quests completed as part of this thread update progress
# When all steps complete, special rewards unlock
```

---

## System Integration

### How Systems Work Together

```
Player Action
     |
     v
NPCTraitSystem updates mood/relationships
     |
     v
NPCPluginManager plugins react (mood, social)
     |
     v
AIEconomySystem adjusts prices based on demand
     |
     v
AIEventSystem may generate related event
     |
     v
AIQuestSystem creates follow-up quest
     |
     v
AdvancedNPC integrates all into dialogue/action
```

### Example Flow: Giving a Gift

1. Player gives diamond to Pierre
2. **NPCTraitSystem**: Updates relationship (+points), forms positive memory
3. **MoodPlugin**: Calculates emotional response (excitement), sets mood
4. **EnhancedPersonalitySystem**: Checks preferences (loved gift!)
5. **NPCAudioManager**: Plays happy emotion sound
6. **AIEconomySystem**: Diamond demand increases slightly, price adjusts
7. **AIQuestSystem**: May generate quest for Pierre to reciprocate
8. **AdvancedNPC**: Generates grateful dialogue with appropriate tone

---

## Performance Considerations

### Optimization Strategies

1. **Trait Updates**: Only update active NPCs (within range or in conversation)
2. **Economy Simulation**: Run every in-game hour, not every frame
3. **Event Generation**: Cooldown periods prevent spam
4. **Quest Generation**: Limit concurrent active quests
5. **Plugin Loading**: Only load needed plugins per NPC

### Recommended Settings

```gdscript
# In generation_params
generation_params.min_event_interval = 3600  # 1 hour minimum between events
generation_params.max_concurrent_events = 3  # Max 3 simultaneous events
generation_params.max_active_quests = 10     # Max 10 active quests
```

---

## Extending the Systems

### Adding New Traits

1. Extend `NPCTraitSystem` with new trait category
2. Add initialization and update methods
3. Integrate with AI decision-making

### Creating New Plugins

1. Create plugin script in `plugins/` folder
2. Extend `RefCounted` base class
3. Implement required lifecycle methods
4. Register with `NPCPluginManager`

### Adding Event Types

1. Add template to `AIEventSystem.load_event_templates()`
2. Define prerequisites and effects
3. System will auto-generate when conditions met

### Custom Quest Types

1. Add template to `AIQuestSystem.load_quest_templates()`
2. Define generation logic
3. Implement reward calculation

---

## Debugging and Testing

### Diagnostic Tools

```gdscript
# Get complete NPC trait profile
var profile = NPCTraitSystem.get_complete_trait_profile("pierre")
print(JSON.stringify(profile, "  "))

# Check plugin status
var plugins = NPCPluginManager.get_available_plugins()
for plugin in plugins:
    print(plugin.name, " - Active on ", plugin.active_count, " NPCs")

# View economy state
for item_id in AIEconomySystem.market_state.items.keys():
    var item = AIEconomySystem.market_state.items[item_id]
    print("%s: $%d (%s)" % [item_id, item.current_price, item.trend])

# Check active events
var events = AIEventSystem.get_active_events()
print("Active events: ", events.size())

# View quest generation history
var history = AIQuestSystem.get_quest_by_id("quest_123")
```

### Common Issues

**Issue**: NPCs not responding to events
- **Solution**: Ensure NPCPluginManager has loaded relevant plugins

**Issue**: Economy prices not updating
- **Solution**: Check that `start_autonomous_simulation()` was called

**Issue**: No quests generating
- **Solution**: Verify NPCs have active goals in NPCTraitSystem

---

## Summary

You now have a fully autonomous AI-driven game world where:

✅ **NPCs have rich inner lives** with moods, relationships, skills, memories, goals, and fears that evolve over time

✅ **Modular architecture** allows easy addition/removal of features without breaking existing code

✅ **Economy runs itself** with dynamic pricing, vendor AI, and market trends

✅ **Events happen organically** based on world state analysis, not just scripts

✅ **Quests emerge naturally** from NPC needs and situations

✅ **Everything connects** - actions ripple through multiple systems creating emergent gameplay

The systems are production-ready and fully integrated!
