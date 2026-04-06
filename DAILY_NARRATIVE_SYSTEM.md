# Daily Narrative Event System - Complete Guide

## Overview

The **DailyNarrativeSystem** generates themed daily narrative scripts with intelligent NPC casting, immersive presentation, and admin controls. It's designed to complement (not duplicate) the existing AIEventSystem.

### Key Distinction: Events vs Narratives

| Feature | AIEventSystem | DailyNarrativeSystem |
|---------|---------------|---------------------|
| **Purpose** | World-state events (weather, festivals, emergencies) | Scripted story experiences with themes |
| **Duration** | Hours to days | Single day experience |
| **Focus** | Gameplay impact (prices, mood, availability) | Narrative immersion (story, characters, dialogue) |
| **Generation** | Reactive to world conditions | Proactive daily generation |
| **Examples** | Thunderstorm, market boom, fire emergency | Magical academy tale, romance story, horror mystery |
| **Player Role** | Observer/participant in town event | Main audience or participant in scripted drama |
| **NPC Behavior** | React naturally to situation | Act out assigned roles in script |

---

## Architecture

```
DailyNarrativeSystem
├── Scenario Library (9 built-in templates)
│   ├── Magical (Hogwarts-style)
│   ├── Fairy Tale (Cinderella, etc.)
│   ├── Horror (Alien visit, haunted manor)
│   ├── Romantic (Butterfly Lovers)
│   ├── Joyful (Harvest festival)
│   ├── Sci-Fi (Time paradox)
│   ├── Adventure (Hero's journey)
│   └── Comedy (Mistaken identity)
│
├── Theme System (8 genres with visual/audio profiles)
│   ├── Visual filters (dream_purple, soft_glow, etc.)
│   ├── Audio themes (mystical_harp, eerie_ambient, etc.)
│   └── Mood modifiers (wonder, fear, love, etc.)
│
├── AI Casting System
│   ├── Personality-trait matching
│   ├── Role compatibility scoring
│   └── Intelligent role assignment
│
├── Script Generation
│   ├── AI-driven via AdvancedAIAgentManager
│   ├── 4-scene structure
│   └── Character-appropriate dialogue
│
├── Immersive Presentation
│   ├── Visual transitions (shaders/filters)
│   ├── Thematic audio
│   └── NPC mood modifications
│
└── Admin UI
    ├── Theme management (block/prefer)
    ├── Scenario editor (add/remove/modify)
    ├── Configuration panel
    └── Live preview
```

---

## System Integration

### How It Works With Existing Systems

#### 1. AdvancedAIAgentManager (Script Generation)
```gdscript
# DailyNarrativeSystem uses AdvancedAIAgentManager for AI script writing
var context = {
    "type": "narrative_script",
    "theme": theme,
    "scenario": scenario.id,
    "cast_size": cast.size(),
    "prompt": detailed_prompt
}

AdvancedAIAgentManager.generate_dialogue_async("narrative_generator", context, callback, 100)
```

**No Duplication**: AIEventSystem doesn't generate scripts - it triggers world state changes. DailyNarrativeSystem creates actual dialogue and scene descriptions.

#### 2. NPCBehaviorController (Casting)
```gdscript
# Get all available NPCs for casting
var all_npcs = NPCBehaviorController.get_all_npc_ids()

# Cast based on personality matching
var cast = cast_npcs_for_scenario(scenario)
```

**No Duplication**: AIEventSystem notifies NPCs of events but doesn't assign roles. DailyNarrativeSystem specifically casts NPCs to character roles.

#### 3. EnhancedPersonalitySystem (Trait Matching)
```gdscript
# Match NPC traits to role requirements
var profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
var npc_traits = profile.get("personality_core", {}).get("traits", [])

# Calculate fit score
var score = calculate_npc_role_fit(npc_id, required_traits)
```

**No Duplication**: Pure data source - no overlap in functionality.

#### 4. NPCTraitSystem (Mood Application)
```gdscript
# Apply thematic moods to cast members
for role in cast.keys():
    var npc_id = cast[role].npc_id
    NPCTraitSystem.set_mood(npc_id, "wonder", 0.8, duration=3600.0)
```

**No Duplication**: DailyNarrativeSystem uses NPCTraitSystem as a tool to enhance immersion.

#### 5. NPCAudioManager (Thematic Audio)
```gdscript
# Play theme-specific ambient audio
NPCAudioManager.play_ambient_sound("narrative", 
    "res://assets/audio/music/{theme}_theme.ogg".format({"theme": theme}), 
    0.6)
```

**No Duplication**: AIEventSystem doesn't manage audio. This is unique to DailyNarrativeSystem.

#### 6. AIEventSystem (Complementary, Not Competitive)
```gdscript
# AIEventSystem handles: Weather, festivals, emergencies, economic events
# DailyNarrativeSystem handles: Themed storylines with scripts and casting

# They can work together:
# - AIEventSystem generates "meteor_shower" weather event
# - DailyNarrativeSystem creates "Magical Night" narrative around it
# - Both enhance the same gameplay moment from different angles
```

**Coordination Strategy**:
- AIEventSystem = macro-level world simulation
- DailyNarrativeSystem = micro-level story experience
- Both can reference each other's outputs for consistency

---

## Usage Guide

### Automatic Daily Generation

The system automatically generates a new narrative each in-game day at 6 AM:

```gdscript
# Enabled by default in config
DailyNarrativeSystem.config.auto_generate_daily = true

# Listen for new narratives
DailyNarrativeSystem.narrative_generated.connect(func(narrative_id, narrative_data):
    print("Today's narrative: ", narrative_data.title)
    print("Theme: ", narrative_data.theme_info.name)
    print("Cast: ", narrative_data.cast.size(), " NPCs")
)
```

### Manual Generation

```gdscript
# Generate with random theme
var narrative = DailyNarrativeSystem.generate_daily_narrative()

# Force specific theme
var horror_narrative = DailyNarrativeSystem.generate_daily_narrative("horror")

# Check result
if narrative:
    print("Generated: ", narrative.title)
    print("Scenario: ", narrative.scenario_id)
    print("Cast:")
    for role in narrative.cast.keys():
        var actor = narrative.cast[role]
        print("  {role}: {name} (fit: {score:.0%})".format({
            "role": role,
            "name": actor.npc_name,
            "score": actor.match_score
        }))
```

### Starting Narrative Presentation

```gdscript
# Begin immersive presentation
DailyNarrativeSystem.start_narrative_presentation()

# This will:
# 1. Apply visual filter (e.g., dream_purple for magical theme)
# 2. Play thematic audio
# 3. Modify NPC moods to match theme
# 4. Emit narrative_started signal

# Listen for transitions
DailyNarrativeSystem.scene_transition_started.connect(func(transition_type, theme):
    print("Transition started: ", transition_type, " - ", theme)
    # Apply custom shader effects here
)

DailyNarrativeSystem.scene_transition_ended.connect(func(transition_type):
    print("Transition complete: ", transition_type)
)
```

### Ending Narrative Presentation

```gdscript
# End presentation and restore normal state
DailyNarrativeSystem.end_narrative_presentation()

# This will:
# 1. Remove visual filters
# 2. Fade out theme audio
# 3. Save to history
# 4. Emit narrative_ended signal
```

---

## Admin Interface

### Accessing the Admin UI

The admin UI scene is located at: `res://scenes/daily_narrative_admin_ui.tscn`

To open it in-game (for testing):
```gdscript
var admin_ui = preload("res://scenes/daily_narrative_admin_ui.tscn").instantiate()
get_tree().root.add_child(admin_ui)
```

### Admin UI Features

#### 1. Theme Management Panel
- **View all themes**: See all 8 available themes with descriptions
- **Block/Unblock**: Prevent certain themes from being selected
- **Add to Preferences**: Mark themes as preferred (higher selection chance)

#### 2. Scenario Library Panel
- **Browse scenarios**: View all built-in and custom scenarios
- **View details**: Click to see full scenario JSON
- **Add new**: Create custom scenarios with JSON editor
- **Remove**: Delete unwanted scenarios

#### 3. Configuration Panel
- **System Enabled**: Toggle entire system on/off
- **Auto-Generate Daily**: Enable/disable automatic daily generation
- **Immersive Transitions**: Toggle visual/audio effects
- **Theme Rotation**: Ensure variety by avoiding recent themes
- **Generate Now**: Manually trigger narrative generation
- **Test Presentation**: Preview current narrative with effects

#### 4. Preview Panel
- **Narrative Title**: Current narrative title
- **Theme Info**: Selected theme and date
- **Cast List**: All roles with assigned NPCs and fit scores
- **Script Preview**: Full 4-scene script with dialogue

---

## Scenario Library Reference

### Built-in Scenarios (9 Total)

#### 1. hogwarts_arrival (Magical)
- **Trope**: Chosen One
- **Roles**: protagonist, mentor, sidekick, rival
- **Scenes**: home → town_square → forest → mountains
- **Use When**: You want a Harry Potter-esque magic academy feel

#### 2. butterfly_lovers (Romantic)
- **Trope**: Forbidden Love
- **Roles**: lover_1, lover_2, obstacle, confidant
- **Scenes**: garden → river → village → hilltop
- **Use When**: Creating bittersweet romance narratives

#### 3. alien_visit (Horror)
- **Trope**: First Contact Gone Wrong
- **Roles**: witness, skeptic, victim, hero
- **Scenes**: farm → town → mine → beach
- **Use When**: Building tension and paranoia

#### 4. haunted_manor (Horror)
- **Trope**: Haunted Location
- **Roles**: investigator, spirit, historian, skeptic
- **Scenes**: manor → library → basement → attic
- **Use When**: Psychological horror with tragic backstory

#### 5. cinderella_ball (Fairy Tale)
- **Trope**: Rags to Riches
- **Roles**: protagonist, benefactor, antagonist, love_interest
- **Scenes**: home → workshop → town_hall → street
- **Use When**: Classic transformation story

#### 6. hero_journey (Adventure)
- **Trope**: Hero's Journey (Monomyth)
- **Roles**: hero, mentor, companion, villain
- **Scenes**: village → crossroads → wilderness → summit
- **Use When**: Epic quest narrative

#### 7. harvest_festival (Joyful)
- **Trope**: Community Bonding
- **Roles**: organizer, performer, newcomer, elder
- **Scenes**: town_square → market → stage → square
- **Use When**: Celebrating community spirit

#### 8. time_paradox (Sci-Fi)
- **Trope**: Time Travel Paradox
- **Roles**: time_traveler, scientist, affected_person, guardian
- **Scenes**: lab → town → past_version → present
- **Use When**: Mind-bending temporal puzzles

#### 9. case_mistaken_identity (Comedy)
- **Trope**: Mistaken Identity
- **Roles**: lookalike_1, lookalike_2, confused_person, revealer
- **Scenes**: town → shop → event → square
- **Use When**: Lighthearted farce

### Creating Custom Scenarios

Use the admin UI or manually add to scenario library:

```gdscript
var custom_scenario = {
    "id": "my_custom_story",
    "theme": "magical",  # Must match one of 8 themes
    "title_template": "The Enchanted Discovery",
    "description": "Someone discovers a hidden magical artifact",
    "trope": "discovery_of_power",
    "roles": {
        "discoverer": {
            "traits": ["curious", "lucky"],
            "count": 1
        },
        "guide": {
            "traits": ["wise", "mysterious"],
            "count": 1
        }
    },
    "scenes": [
        {"location": "forest", "action": "find_artifact"},
        {"location": "cave", "action": "first_magic"},
        {"location": "town", "action": "reveal_to_others"},
        {"location": "hilltop", "action": "accept_destiny"}
    ],
    "ai_prompt_additions": "Include wonder and discovery. Think Studio Ghibli magic."
}

DailyNarrativeSystem.add_custom_scenario(custom_scenario)
```

---

## Theme System Reference

### 8 Available Themes

| Theme ID | Name | Visual Filter | Audio Theme | Best For |
|----------|------|--------------|-------------|----------|
| `magical` | Magical Fantasy | dream_purple | mystical_harp | Wizard tales, enchantment |
| `fairy_tale` | Fairy Tale | soft_glow | orchestral_whimsy | Classic folklore |
| `horror` | Horror/Mystery | dark_vignette | eerie_ambient | Suspense, scares |
| `romantic` | Romance | warm_soft | gentle_strings | Love stories |
| `joyful` | Joyful Celebration | bright_vibrant | upbeat_folk | Happy occasions |
| `sci_fi` | Science Fiction | neon_grid | synth_wave | Future tech, space |
| `adventure` | Adventure/Quest | cinematic_wide | epic_orchestral | Heroic journeys |
| `comedy` | Comedy | bright_saturated | playful_winds | Humor, farce |

### Theme Selection Algorithm

1. Check user preferences (preferred themes weighted higher)
2. Remove blocked themes
3. If rotation enabled, exclude last used theme
4. Random selection from remaining candidates

---

## Casting System Details

### How NPCs Are Matched to Roles

The casting system uses a multi-factor scoring algorithm:

```gdscript
# Example: Finding best "brave hero" role
var required_traits = ["brave", "good_hearted"]

# For each NPC:
# 1. Check personality traits match
# 2. Check speech style compatibility
# 3. Calculate match score (0.0 - 1.0)
# 4. Sort by score
# 5. Assign top matches to roles

# Result:
cast["hero"] = {
    "npc_id": "abigail",
    "npc_name": "Abigail",
    "match_score": 0.85,  # 85% trait match
    "matched_traits": ["brave", "adventurous"]
}
```

### Trait Compatibility Matrix

The system recognizes synonyms and related traits:

```gdscript
"brave" matches: ["courageous", "fearless", "bold", "adventurous"]
"kind" matches: ["gentle", "compassionate", "caring", "generous"]
"wise" matches: ["intelligent", "knowledgeable", "smart", "thoughtful"]
"mysterious" matches: ["enigmatic", "secretive", "cryptic"]
"cheerful" matches: ["happy", "optimistic", "positive", "energetic"]
```

### Ensuring Variety

- Each NPC can only be cast once per narrative
- Unused NPCs are prioritized for next narrative
- Small random factor prevents identical casting

---

## Immersive Presentation System

### Visual Filters

Visual filters are shader effects applied during narrative presentation:

```gdscript
# Available filters:
"dream_purple"      # Purple tint + slight blur (magical)
"soft_glow"         # Warm glow + bloom (fairy tale)
"dark_vignette"     # Dark edges + desaturated (horror)
"warm_soft"         # Soft focus + warm tones (romance)
"bright_vibrant"    # High saturation + contrast (joyful)
"neon_grid"         # Cyan/magenta shift + scanlines (sci-fi)
"cinematic_wide"    # Letterbox + color grading (adventure)
"bright_saturated"  # Oversaturated colors (comedy)
```

**Implementation Note**: The system emits signals for your shader manager to handle:
```gdscript
DailyNarrativeSystem.scene_transition_started.connect(func(filter_type, theme):
    # Your code to apply actual shader
    shader_manager.apply_filter(filter_type)
)
```

### Audio Themes

Thematic background audio enhances immersion:

```gdscript
# Audio files should be placed at:
# res://assets/audio/music/{theme}_theme.ogg

# Examples:
"mystical_harp.ogg"       # Magical theme
"orchestral_whimsy.ogg"   # Fairy tale
"eerie_ambient.ogg"       # Horror
"gentle_strings.ogg"      # Romance
"upbeat_folk.ogg"         # Joyful
"synth_wave.ogg"          # Sci-fi
"epic_orchestral.ogg"     # Adventure
"playful_winds.ogg"       # Comedy
```

### Mood Modifications

During narrative presentation, cast members receive mood boosts:

```gdscript
# Example for "magical" theme:
mood_modifiers = {
    "wonder": 0.8,
    "excitement": 0.6
}

# Applied to each cast member:
NPCTraitSystem.set_mood("abigail", "wonder", 0.8, duration=3600.0)
NPCTraitSystem.set_mood("pierre", "excitement", 0.6, duration=3600.0)
```

This makes NPCs act according to the narrative theme even after it ends!

---

## Integration Examples

### Example 1: Simple Daily Flow

```gdscript
# In your game manager
func _on_new_day(day_data):
    # DailyNarrativeSystem auto-generates at 6 AM
    # Just listen for the result
    pass

func _ready():
    DailyNarrativeSystem.narrative_generated.connect(_on_narrative_ready)

func _on_narrative_ready(narrative_id, narrative_data):
    print("Today's story: ", narrative_data.title)
    
    # Notify player
    show_notification("New Narrative Available: " + narrative_data.title)
    
    # Store for later
    todays_narrative = narrative_data
```

### Example 2: Player Triggers Narrative

```gdscript
# Player reads a magical book -> trigger narrative
func _on_magical_book_read():
    if DailyNarrativeSystem.is_narrative_active():
        return  # Already running
    
    # Generate magical-themed narrative
    var narrative = DailyNarrativeSystem.generate_daily_narrative("magical")
    
    if narrative:
        # Start presentation immediately
        DailyNarrativeSystem.start_narrative_presentation()
        
        # Show first scene
        show_narrative_scene(narrative.script.scenes[0])
```

### Example 3: Custom Scenario Creation

```gdscript
# Add a Christmas-themed scenario
var christmas_scenario = {
    "id": "christmas_special",
    "theme": "joyful",
    "title_template": "Winter Wonderland Celebration",
    "description": "The town prepares for a special holiday",
    "trope": "holiday_spirit",
    "roles": {
        "organizer": {"traits": ["enthusiastic", "organized"], "count": 1},
        "grinch": {"traits": ["cynical", "lonely"], "count": 1},
        "child": {"traits": ["innocent", "hopeful"], "count": 1},
        "santa_figure": {"traits": ["jolly", "generous"], "count": 1}
    },
    "scenes": [
        {"location": "town_square", "action": "decoration_setup"},
        {"location": "grinch_home", "action": "reluctant_invitation"},
        {"location": "square", "action": "celebration_begins"},
        {"location": "square", "action": "grinch_has_change_of_heart"}
    ],
    "ai_prompt_additions": "Heartwarming holiday story about community bringing someone in from the cold."
}

DailyNarrativeSystem.add_custom_scenario(christmas_scenario)
```

### Example 4: Coordinating with AIEventSystem

```gdscript
# When AIEventSystem generates a storm, create complementary narrative
AIEventSystem.event_generated.connect(func(event_type, event_data):
    if event_type == "weather" and event_data.name == "Thunderstorm":
        # Generate horror/mystery narrative to match
        var narrative = DailyNarrativeSystem.generate_daily_narrative("horror")
        
        if narrative:
            # Override scenario to storm-related one
            # (You'd need to add storm scenarios first)
            print("Storm narrative ready: ", narrative.title)
)
```

---

## Configuration Reference

### Config File Location
`user://daily_narrative_config.json`

### Config Options

```json
{
    "enabled": true,                    // Master toggle
    "auto_generate_daily": true,        // Auto-gen at 6 AM
    "generation_time": 6.0,             // 6 AM in-game
    "max_duration_hours": 24,           // Max narrative length
    "allow_player_participation": true, // Can player join scenes?
    "immersive_transitions": true,      // Visual/audio effects
    "theme_rotation": true,             // Avoid repeat themes
    "last_theme_used": "magical",       // Tracking for rotation
    "preferred_themes": ["romantic"],   // Weighted themes
    "blocked_themes": ["horror"]        // Excluded themes
}
```

### Runtime Configuration

```gdscript
# Change settings programmatically
DailyNarrativeSystem.config.enabled = false  // Disable system
DailyNarrativeSystem.config.blocked_themes.append("horror")  // Block horror
DailyNarrativeSystem.save_config()  // Persist changes
```

---

## Troubleshooting

### Issue: No Narrative Generated

**Check:**
1. System is enabled: `DailyNarrativeSystem.config.enabled == true`
2. Auto-generation is on: `config.auto_generate_daily == true`
3. At least one theme is available (not all blocked)
4. AdvancedAIAgentManager is loaded

**Debug:**
```gdscript
print("Enabled: ", DailyNarrativeSystem.config.enabled)
print("Available themes: ", DailyNarrativeSystem.NARRATIVE_THEMES.keys())
print("Scenarios: ", DailyNarrativeSystem.scenario_library.size())
```

### Issue: Poor NPC Casting

**Solution:**
- Add more NPCs to your game (system needs variety)
- Ensure NPCs have personality traits defined in EnhancedPersonalitySystem
- Check trait compatibility matrix matches your needs

### Issue: AI Script Generation Fails

**Fallback Behavior:**
System automatically generates basic fallback script if AI times out or fails.

**Improve Success:**
- Ensure Ollama is running
- Check ai_config.json has correct model
- Increase timeout in `generate_narrative_script()`

### Issue: Visual Filters Not Working

**Note:**
The system emits signals but doesn't include actual shaders.

**Implementation Required:**
```gdscript
# You need to create shader manager
DailyNarrativeSystem.scene_transition_started.connect(func(filter_type, theme):
    match filter_type:
        "dream_purple":
            $CanvasLayer.shader.material.set_shader_parameter("tint", Color(0.5, 0.3, 0.8))
        # ... implement other filters
)
```

---

## Performance Considerations

### Optimization Tips

1. **Generation Timing**: Generate narratives during loading screens or off-peak moments
2. **Caching**: Generated narratives are stored - no regeneration needed
3. **Audio**: Theme audio is low priority (priority=2) to not interfere with SFX
4. **Mood Updates**: Only applied to cast members (typically 4 NPCs), not all

### Memory Usage

- Scenario library: ~50KB (9 scenarios)
- Generated narrative: ~10KB per narrative
- History: Stores last 100 narratives (~1MB max)

---

## Future Enhancements

Potential additions:
1. **Multi-day narratives**: Epic stories spanning multiple days
2. **Player character integration**: Player as a role in the narrative
3. **Branching narratives**: Player choices affect outcome
4. **Seasonal scenarios**: Special themes for holidays/events
5. **Collaborative narratives**: Multiple players in multiplayer
6. **Narrative achievements**: Unlock scenarios by completing others

---

## Summary

The DailyNarrativeSystem provides:
✅ **8 themed genres** with distinct visual/audio identities
✅ **9 built-in scenarios** covering classic tropes
✅ **Intelligent NPC casting** based on personality matching
✅ **AI-generated scripts** with 4-scene structure
✅ **Immersive presentation** with transitions and mood effects
✅ **Full admin control** via UI for customization
✅ **Seamless integration** with existing AI systems (no duplication)

It transforms your farming sim into a living story generator where NPCs become actors in daily theatrical experiences!
