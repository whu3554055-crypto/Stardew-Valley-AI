# Stardew Valley Clone - Game Design Document

## Overview

A 2D farming simulation RPG inspired by Stardew Valley, built with Godot Engine 4.2. Players inherit their grandfather's old farm and must build a new life in the countryside.

## Core Features

### 1. Farming System

**Crop Management**
- Till soil using hoes
- Plant seeds from inventory
- Water crops daily (rain automatically waters)
- Harvest when fully grown
- Sell crops for profit

**Crop Types**
| Crop | Growth Time | Season | Seed Price | Sell Price |
|------|-------------|--------|------------|------------|
| Parsnip | 4 days | Spring | 20g | 35g |
| Cauliflower | 12 days | Spring | 80g | 175g |
| Potato | 6 days | Spring | 50g | 80g |

**Growth Stages**
- Stage 0: Just planted (seeds)
- Stage 1: Small sprout
- Stage 2: Growing plant
- Stage 3: Nearly mature
- Stage 4: Ready to harvest

### 2. Time & Seasons

**Daily Cycle**
- Day starts at 6:00 AM
- Player passes out at 2:00 AM
- Real-time progression (adjustable speed)
- Visual day/night cycle overlay

**Seasonal System**
- 4 seasons: Spring, Summer, Fall, Winter
- 28 days per season
- Different crops available each season
- Year counter increments after winter

### 3. Weather System

**Weather Types**
- Sunny: Normal day
- Rain: Auto-waters crops
- Storm: Heavy rain with lightning
- Snow: Winter weather
- Windy: Cosmetic wind effects
- Overcast: Cloudy but dry

**Weather Effects**
- Visual particle effects (rain/snow)
- Automatic crop watering on rainy days
- Affects NPC schedules

### 4. Inventory System

**Inventory Grid**
- 36 slots (4 rows x 9 columns)
- Item stacking (up to 99)
- Quick-select hotbar
- Drag-and-drop support (future)

**Item Types**
- Seeds: Plantable crop seeds
- Crops: Harvested produce
- Tools: Equipment for farming
- Resources: Materials (wood, stone)
- Consumables: Food items

### 5. Tool System

**Basic Tools**
- Hoe: Till soil for planting
- Watering Can: Water crops
- Axe: Chop wood
- Pickaxe: Break stones
- Scythe: Cut grass

**Tool Usage**
- Select from inventory
- Click or press interaction key
- Tools have durability (future feature)

### 6. NPC System

**Villager Features**
- Unique dialogue per NPC
- Daily schedules
- Friendship system (future)
- Gift preferences (future)

**Sample NPCs**
- Pierre: Shop owner, sells seeds
- Abigail: Adventurous villager
- Mayor Lewis: Town mayor

**Dialogue System**
- Random dialogue lines
- Multi-line conversations
- Quest-related dialogue

### 7. Shop System

**Pierre's General Store**
- Buy seeds and supplies
- Sell harvested crops
- Dynamic stock based on season
- Price fluctuations (future)

**Transaction Features**
- Gold-based economy
- Stock limits
- Bulk buying/selling

### 8. Quest System

**Quest Types**
- Tutorial quests
- Delivery quests
- Collection quests
- Crafting quests

**Quest Tracking**
- Active quest list
- Objective progress
- Completion rewards
- Quest log UI (future)

**Sample Quests**
1. "Your First Crop" - Plant a parsnip
2. "First Harvest" - Harvest your first crop
3. "Entrepreneur" - Earn 1000 gold

### 9. Achievement System

**Achievement Categories**
- Farming: Crop-related goals
- Earning: Money milestones
- Social: NPC interactions
- Fishing: Catching fish
- Exploration: Area discovery
- Cooking: Recipe completion
- Collection: Museum donations

**Progress Tracking**
- Persistent achievement data
- Unlock notifications
- Completion percentage

### 10. Save/Load System

**Saved Data**
- Player stats (gold, day, season)
- Farm layout (tilled soil, planted crops)
- Inventory contents
- Quest progress
- Achievement status

**Save Locations**
- Automatic saves on day end
- Manual save option
- Multiple save slots (future)

## Controls

### Keyboard
| Key | Action |
|-----|--------|
| W/A/S/D | Move character |
| E | Interact |
| I | Toggle inventory |
| ESC | Pause menu |
| Left Click | Use tool/item |

### Gamepad Support
| Button | Action |
|--------|--------|
| Left Stick | Move |
| A/Cross | Interact |
| B/Circle | Cancel |
| Y/Triangle | Inventory |

## Technical Architecture

### Autoload Singletons
- **GameManager**: Global game state, time tracking
- **InventoryManager**: Inventory operations
- **ItemDatabase**: Item definitions
- **ShopSystem**: Shop mechanics
- **WeatherSystem**: Weather effects
- **QuestSystem**: Quest management
- **AchievementSystem**: Achievement tracking

### Scene Structure
```
Main (Node2D)
├── TileMap (TileMap)
├── Player (CharacterBody2D)
│   ├── Sprite2D
│   ├── CollisionShape2D
│   └── InteractionArea
├── FarmManager (Node2D)
├── UILayer (CanvasLayer)
│   ├── TimeLabel
│   ├── GoldLabel
│   ├── DayLabel
│   ├── SeasonLabel
│   ├── WeatherLabel
│   ├── DialogueBox
│   └── InventoryUI
└── NPCs (CharacterBody2D instances)
```

## File Structure

```
stardew_valley/
├── autoload/           # Global singleton scripts
│   ├── game_manager.gd
│   ├── inventory_manager.gd
│   ├── item_database.gd
│   ├── shop_system.gd
│   ├── weather_system.gd
│   ├── quest_system.gd
│   └── achievement_system.gd
├── scenes/             # Scene files
│   ├── main.tscn
│   ├── npc_pierre.tscn
│   ├── npc_abigail.tscn
│   ├── npc_lewis.tscn
│   └── shop_ui.tscn
├── scripts/            # GDScript files
│   ├── player.gd
│   ├── farm_manager.gd
│   ├── npc.gd
│   ├── day_night_cycle.gd
│   ├── inventory_ui.gd
│   ├── shop_ui.gd
│   ├── game_tilemap.gd
│   └── sprite_generator.gd
├── resources/          # Resource class definitions
│   ├── item_data.gd
│   └── crop_data.gd
├── assets/             # Game assets
│   ├── sprites/        # Character/item sprites
│   └── tilemaps/       # Tileset textures
├── project.godot       # Project configuration
├── icon.svg            # Application icon
└── README.md           # Project documentation
```

## Future Enhancements

### Phase 2 Features
- [ ] Fishing mini-game
- [ ] Mining/cave exploration
- [ ] Combat system
- [ ] Monster encounters
- [ ] Weapon crafting

### Phase 3 Features
- [ ] Animal husbandry (chickens, cows)
- [ ] Building upgrades
- [ ] Marriage candidates
- [ ] Child system
- [ ] Community center bundles

### Phase 4 Features
- [ ] Cooking system
- [ ] Festival events
- [ ] Secret notes
- [ ] Junimo collection
- [ ] Multiplayer co-op

## Art Style Guidelines

### Recommended Style
- Pixel art aesthetic (16x16 or 32x32 tiles)
- Bright, cheerful color palette
- Top-down perspective
- Smooth animations

### Color Palette Suggestions
- Grass: #4a9c5d
- Dirt: #8B6914
- Water: #4a90e2
- Wood: #8B4513
- Stone: #808080

## Audio Design (Future)

### Music Tracks Needed
- Title screen theme
- Spring/Summer/Fall/Winter themes
- Shop music
- Festival music

### Sound Effects
- Footstep sounds (different surfaces)
- Tool usage sounds
- UI interaction sounds
- Ambient nature sounds
- NPC speech bleeps

## Performance Considerations

### Optimization Tips
- Use tilemaps for terrain (efficient)
- Limit active NPCs on screen
- Pool particle effects
- Batch draw calls where possible
- Use texture atlases

### Target Specifications
- 60 FPS on integrated graphics
- < 200MB RAM usage
- < 100MB disk space
- Quick load times (< 3 seconds)
