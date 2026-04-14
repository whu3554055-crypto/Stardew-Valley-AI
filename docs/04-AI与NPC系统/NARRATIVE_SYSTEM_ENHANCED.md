# Enhanced Daily Narrative System - Complete Guide

## Overview

The Daily Narrative System now leverages the expanded NPC roster (18+ characters) and town layout (36+ locations) to create richer, more authentic stories. Key enhancements include:

1. **Expanded Casting Pool** - Access to diverse NPC archetypes
2. **Temporary Characters** - Auto-generated extras for roles without matching NPCs
3. **Dynamic Scene Generation** - Context-aware locations that adapt to narrative themes
4. **Enhanced Immersion** - Theme-specific atmospheres, lighting, sounds, and props

---

## 1. Expanded NPC Roster Integration

### Available NPCs for Casting (18+)

**Original Characters:**
- Pierre (Shopkeeper), Abigail (Adventurer), Lewis (Mayor)

**Newly Added:**
- Dr. Elias Thornwood (Eccentric Scientist)
- Isabella Nightingale (Horror Novelist)
- Marcus Chen (Street Musician)

**Template Ready (12+ more):**
- Professor Ada Lovelace, Luna Starweaver, Vincent Blackwood
- Bjorn Ironforge, Captain Jack Marlin, Robin Hoodshade
- Aiko Tanaka, Emma Sunshine, Sophia Martinez
- Morgana Shadowmoon, Finn O'Malley, Old Tom

### Intelligent Casting Algorithm

The system now matches NPCs to roles using:

```gdscript
# Multi-factor scoring:
1. Personality trait matching (synonym-aware)
2. Speech style compatibility
3. Occupational relevance
4. Relationship dynamics
5. Availability (no double-casting)
6. Random variety factor

# Example match:
Role: "brave hero" requires [brave, good_hearted]
→ Abigail matched (85% fit): brave, adventurous, energetic
→ Matched traits: ["brave"]
→ Speech style: casual (fits heroic dialogue)
```

### Casting Priority

1. **Permanent NPCs** - Existing characters with full profiles
2. **Temporary Characters** - Generated only if no suitable NPC found
3. **Fallback** - Any available NPC with adjusted dialogue

---

## 2. Temporary Character System

### What Are Temporary Characters?

Temporary characters are AI-generated NPCs created on-the-fly when:
- No permanent NPC fits a role well enough
- Story requires specific character types (aliens, ghosts, wizards)
- Extra background characters needed
- Player creates custom scenarios with unique roles

### Features

**Automatic Generation:**
```gdscript
# System automatically creates temp chars when needed
var cast = get_cast_with_temps(scenario, theme)

# Example output:
cast["mentor"] = {
    "npc_id": "temp_mentor_4521",
    "npc_name": "Elder Wizard",  # Generated name
    "is_temporary": true,
    "character_data": {
        "appearance": "Robes shimmering with arcane energy...",
        "backstory": "Trained in ancient arts...",
        "personality": {...}
    },
    "match_score": 1.0,  # Perfect fit (custom-made)
    "matched_traits": ["wise", "mysterious"]
}
```

**Theme-Appropriate Names:**
- Magical: "Young Apprentice", "Elder Wizard", "Dark Sorcerer"
- Horror: "Night Watchman", "Restless Ghost", "Missing Person"
- Romantic: "Handsome Stranger", "Childhood Friend", "Strict Parent"
- Sci-Fi: "Chrononaut", "Future Refugee", "Visitor from Beyond"

**Generated Attributes:**
- Name (theme-appropriate)
- Appearance description
- Backstory snippet
- Personality traits
- Theme alignment

**Automatic Cleanup:**
```gdscript
# Temp characters removed after narrative ends
func end_narrative_presentation():
    if current_narrative.has_temporary_characters:
        cleanup_temporary_characters()
```

### When to Use Temporary Characters

**Good Uses:**
- Fantasy races (elves, dwarves, wizards)
- Historical figures (ghosts of founders)
- Supernatural entities (aliens, spirits)
- One-time roles (traveling merchant, tourist)
- Crowd scenes (extras)

**Avoid For:**
- Major recurring roles
- Roles that could develop into relationships
- Characters players might want to befriend

---

## 3. Dynamic Scene Generation

### Scene Templates (8 Built-in)

1. **Town Square Day** - Bustling, lively, bright sunlight
2. **Town Square Night** - Peaceful, moonlight, street lamps
3. **Mystic Forest Clearing** - Secluded, dappled light, mysterious
4. **Haunted Manor Library** - Dusty, dim candlelight, eerie
5. **Scientific Laboratory** - Cluttered, fluorescent sparks, chaotic
6. **Cozy Cafe Corner** - Warm, welcoming, coffee aromas
7. **Beach at Sunset** - Golden hour, romantic, waves
8. **Mountain Summit** - Breathtaking, clear skies, awe-inspiring

### Theme-Adaptive Scenes

Scenes automatically adjust based on narrative theme:

**Example: Town Square**
```
Base: "Bustling center with townsfolk"

Horror Theme → "Unsettling square with ominous shadows"
  - Lighting: shadowy_with_flickering
  - Props: broken_mirror, cobwebs, old_diary
  
Romantic Theme → "Intimate square under starlight"
  - Lighting: soft_warm_glow
  - Props: rose_petals, string_lights, picnic_blanket
  
Magical Theme → "Enchanted square with mystical energy"
  - Lighting: ethereal_shimmer
  - Props: glowing_crystals, spell_books, potions
```

### Scene Components

Each generated scene includes:
- **Name & Description** - Location identity
- **Atmosphere** - Emotional tone (adjusted for theme)
- **Lighting** - Visual mood (theme-specific)
- **Ambient Sounds** - Background audio cues
- **Props** - Thematic objects for immersion
- **Unique ID** - For tracking and reuse

### Usage in Narratives

```gdscript
# Scenes auto-generated during narrative assembly
var narrative = generate_daily_narrative("horror")

# Each script scene gets a dynamic location
narrative.scenes[0] = {
    "scene_number": 1,
    "name": "Haunted Manor Library",
    "atmosphere": "terrifying",  # Adjusted from "eerie"
    "lighting": "shadowy_with_flickering",
    "ambient_sounds": ["creaking_floors", "wind_howling", "distant_thunder"],
    "props": ["bookshelves", "fireplace", "secret_passage", "broken_mirror", "cobwebs"]
}
```

---

## 4. Integration Examples

### Example 1: Horror Narrative with Mixed Cast

```gdscript
# Generate horror narrative
var horror_story = DailyNarrativeSystem.generate_daily_narrative("horror")

# Result:
horror_story.title = "Whispers in the Dark"
horror_story.cast = {
    "investigator": {
        "npc_id": "elias",  # Dr. Thornwood - perfect fit!
        "npc_name": "Dr. Elias Thornwood",
        "is_temporary": false,
        "match_score": 0.92
    },
    "spirit": {
        "npc_id": "temp_spirit_7823",  # Generated character
        "npc_name": "Restless Ghost",
        "is_temporary": true,
        "character_data": {
            "appearance": "Pale, translucent form in tattered Victorian dress",
            "backstory": "Trapped between worlds, seeking resolution"
        }
    },
    "historian": {
        "npc_id": "isabella",  # Horror novelist - ideal!
        "npc_name": "Isabella Nightingale",
        "is_temporary": false,
        "match_score": 0.88
    }
}

# Scenes dynamically generated for horror theme
horror_story.scenes[0].lighting = "shadowy_with_flickering"
horror_story.scenes[0].props.append("candles")
horror_story.scenes[0].props.append("old_diary")
```

### Example 2: Magical Academy Story

```gdscript
# Force magical theme
var magic_story = DailyNarrativeSystem.generate_daily_narrative("magical")

# System creates temporary wizard characters
magic_story.cast = {
    "protagonist": {
        "npc_id": "abigail",  # Adventurous spirit fits
        "npc_name": "Abigail",
        "match_score": 0.75
    },
    "mentor": {
        "npc_id": "temp_mentor_3344",
        "npc_name": "Elder Wizard",  # Custom-generated
        "is_temporary": true,
        "character_data": {
            "appearance": "Flowing robes with celestial patterns, staff of ancient wood",
            "backstory": "Keeper of forbidden knowledge, guardian of magical balance"
        }
    },
    "rival": {
        "npc_id": "temp_rival_9912",
        "npc_name": "Dark Sorcerer",  # Another temp char
        "is_temporary": true
    }
}

# Scenes adapted for magical theme
magic_story.scenes[1].name = "Mystic Forest Clearing"
magic_story.scenes[1].lighting = "ethereal_shimmer"
magic_story.scenes[1].props = ["glowing_crystals", "spell_books", "mystical_symbols"]
```

### Example 3: Romance with Real NPCs

```gdscript
# Romantic narrative using existing NPCs
var romance = DailyNarrativeSystem.generate_daily_narrative("romantic")

# System finds best romantic leads from roster
romance.cast = {
    "lover_1": {
        "npc_id": "marcus",  # Charming musician
        "npc_name": "Marcus Chen",
        "match_score": 0.85
    },
    "lover_2": {
        "npc_id": "emma",  # Sweet girl-next-door
        "npc_name": "Emma Sunshine",
        "match_score": 0.90
    },
    "obstacle": {
        "npc_id": "pierre",  # Protective father figure
        "npc_name": "Pierre",
        "match_score": 0.70
    }
}

# Romantic scene settings
romance.scenes[2].name = "Beach at Sunset"
romance.scenes[2].lighting = "soft_warm_glow"
romance.scenes[2].props = ["rose_petals", "string_lights", "picnic_blanket"]
```

---

## 5. API Reference

### Temporary Character Functions

```gdscript
# Create temporary character manually
var temp_char = DailyNarrativeSystem.create_temporary_character(
    "wizard",  # role_name
    {"traits": ["wise", "powerful"]},  # requirements
    "magical"  # theme
)

# Get cast with automatic temp character generation
var cast = DailyNarrativeSystem.get_cast_with_temps(scenario, theme)

# Cleanup all temporary characters
DailyNarrativeSystem.cleanup_temporary_characters()

# Check if narrative uses temp characters
if current_narrative.has_temporary_characters:
    print("This story features guest characters!")
```

### Scene Generation Functions

```gdscript
# Initialize scene templates (called automatically in _ready)
DailyNarrativeSystem.initialize_scene_templates()

# Generate dynamic scene for location + theme
var scene = DailyNarrativeSystem.generate_dynamic_scene(
    scene_templates["town_square_day"],
    "horror"  # Theme adjusts atmosphere
)

# Get or create scene for specific location
var forest_scene = DailyNarrativeSystem.get_or_create_scene(
    "forest",
    "magical"
)

# Access generated scenes in narrative
for scene in current_narrative.scenes:
    print("Scene ", scene.scene_number, ": ", scene.name)
    print("  Atmosphere: ", scene.atmosphere)
    print("  Props: ", scene.props)
```

### Enhanced Narrative Data Structure

```gdscript
# Complete narrative object now includes:
{
    "id": "narrative_123456",
    "title": "Story Title",
    "theme": "horror",
    "cast": {
        "role_name": {
            "npc_id": "elias",
            "npc_name": "Dr. Elias Thornwood",
            "is_temporary": false,
            "match_score": 0.92
        }
    },
    "scenes": [  # NEW: Dynamic scene data
        {
            "scene_number": 1,
            "name": "Haunted Manor Library",
            "atmosphere": "terrifying",
            "lighting": "shadowy_with_flickering",
            "ambient_sounds": ["creaking_floors", "wind"],
            "props": ["bookshelves", "cobwebs", "candles"]
        }
    ],
    "has_temporary_characters": true,  # NEW: Flag for temp chars
    "script": {...},
    "presentation": {...}
}
```

---

## 6. Benefits of Enhanced System

### For Storytelling

✅ **More Authentic Stories** - Diverse cast means better role matching
✅ **No Empty Roles** - Temporary characters fill gaps seamlessly
✅ **Immersive Settings** - Scenes adapt to theme automatically
✅ **Variety** - 18+ NPCs × 36+ locations × 8 themes = 5000+ combinations

### For Performance

✅ **Efficient Casting** - Smart matching reduces regeneration needs
✅ **Memory Management** - Temp characters cleaned up automatically
✅ **Reusable Templates** - Scene templates cached and modified

### For Flexibility

✅ **Custom Scenarios** - Add any role, system fills it
✅ **Theme Consistency** - Everything adapts to chosen theme
✅ **Extensible** - Easy to add more NPCs, locations, templates

---

## 7. Best Practices

### When Creating Custom Scenarios

1. **Define Clear Roles** - Specific traits help casting
```gdscript
"roles": {
    "detective": {"traits": ["observant", "logical"], "count": 1}
}
```

2. **Use Existing Locations** - Reference zones from game_tilemap.gd
```gdscript
"scenes": [
    {"location": "library", "action": "investigate_clues"}
]
```

3. **Consider NPC Schedules** - Some NPCs unavailable at certain times

4. **Balance Permanent vs Temporary** - Mix real NPCs with temps for richness

### Optimizing Casting Quality

- Add personality traits to new NPCs for better matching
- Use synonym-aware trait names (brave/courageous/fearless)
- Define speech styles that match potential roles
- Create varied schedules for availability

---

## 8. Future Enhancements

Potential additions:
1. **Player as Character** - Integrate player into narratives
2. **Relationship Impact** - Stories affect NPC relationships
3. **Multi-Day Epics** - Stories spanning multiple days
4. **Branching Narratives** - Player choices change outcome
5. **Voice Acting** - Audio lines for key scenes
6. **Visual Novels** - Full VN-style presentation mode

---

## Summary

The Enhanced Daily Narrative System now provides:

✅ **18+ NPC Actors** - Diverse personalities and archetypes
✅ **Temporary Characters** - Infinite casting possibilities
✅ **36+ Locations** - Rich environmental variety
✅ **8 Scene Templates** - Adaptable to any theme
✅ **Dynamic Generation** - Scenes match narrative mood
✅ **Smart Casting** - Best-fit algorithm with fallbacks
✅ **Auto-Cleanup** - No memory leaks from temp chars
✅ **Theme Immersion** - Everything adapts to story genre

Your NPCs now star in rich, varied narratives with appropriate settings, supporting cast, and atmospheric details - creating truly immersive daily storytelling experiences!
