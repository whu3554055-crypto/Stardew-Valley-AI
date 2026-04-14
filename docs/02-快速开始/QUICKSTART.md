# Quick Start Guide

## Getting Started in 5 Minutes

### Prerequisites
1. Download and install [Godot Engine 4.2+](https://godotengine.org/download)
2. Clone or download this project

### Running the Game

1. **Open Godot Engine**
2. Click "Import" and select the `project.godot` file
3. Click "Run" (F5) or press the play button
4. The game will start with the player on a basic farm

### First Steps in Game

1. Press **I** to open inventory
2. Select the **Hoe** tool
3. Close inventory and press **E** on grass to till soil
4. Open inventory, select **Parsnip Seeds**
5. Press **E** on tilled soil to plant
6. Select **Watering Can** and press **E** on planted seeds
7. Wait for time to pass (or modify time speed in GameManager)
8. Harvest when fully grown

## Adding Your First Custom Crop

Edit `scripts/farm_manager.gd`:

```gdscript
func load_crop_database():
    # ... existing crops ...
    
    # Add your new crop here
    crops_db["strawberry"] = {
        "id": "strawberry",
        "name": "Strawberry",
        "growth_days": 8,
        "harvest_product": "strawberry",
        "harvest_count": 2,
        "regrows": true,
        "regrow_days": 4,
        "seasons": ["spring"]
    }
```

Add the seed item in `autoload/item_database.gd`:

```gdscript
items["strawberry_seeds"] = {
    "id": "strawberry_seeds",
    "name": "Strawberry Seeds",
    "description": "Plant these to grow strawberries.",
    "type": "seed",
    "crop_id": "strawberry",
    "stack": 1,
    "max_stack": 99,
    "buy_price": 100,
    "sell_price": 50
}
```

## Creating a New NPC

1. Create a new scene file `scenes/npc_yourname.tscn`:

```gdscript
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/npc.gd" id="1_npc"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_npc"]
size = Vector2(32, 32)

[node name="YourNPC" type="CharacterBody2D"]
position = Vector2(300.0, 200.0)
script = ExtResource("1_npc")
npc_name = "Your NPC Name"
dialogue_lines = ["Hello there!", "Nice weather today!"]

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, -16)
# texture = preload("res://assets/sprites/your_npc.png")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_npc")

[node name="NameLabel" type="Label" parent="."]
offset_left = -30.0
offset_top = -50.0
offset_right = 70.0
offset_bottom = -30.0
text = "Your NPC"
horizontal_alignment = 1
visible = false

[node name="InteractionArea" type="Area2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractionArea"]
shape = SubResource("RectangleShape2D_npc")
```

2. Instance the NPC in `main.tscn` or spawn it via code

## Modifying Player Stats

Edit `autoload/game_manager.gd`:

```gdscript
var player_data = {
    "gold": 1000,      # Starting gold
    "day": 1,
    "season": "spring",
    "year": 1
}

# Adjust time speed
var time_speed = 5.0   # Slower (was 10.0)
```

## Adding Custom Tiles

1. Create a tileset image in `assets/tilemaps/`
2. Create a TileSet resource in Godot editor
3. Assign tiles in the TileMap node
4. Update `scripts/game_tilemap.gd` with new tile types

## Debugging Tips

### Enable Debug Visualizations

Add to player script:
```gdscript
func _draw():
    # Draw interaction area
    draw_circle(facing_direction * 32, 5, Color.RED)
```

### Print Debug Info

```gdscript
func _process(delta):
    if Input.is_action_just_pressed("ui_accept"):
        print("Position: ", global_position)
        print("Tile: ", get_facing_tile())
```

### Check Autoload Status

```gdscript
func _ready():
    print("GameManager loaded: ", GameManager != null)
    print("Inventory loaded: ", InventoryManager != null)
```

## Common Modifications

### Change Window Size

Edit `project.godot`:
```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
```

### Add New Tool

In `item_database.gd`:
```gdscript
items["fishing_rod"] = {
    "id": "fishing_rod",
    "name": "Fishing Rod",
    "description": "Used for fishing",
    "type": "tool",
    "stack": 1,
    "max_stack": 1,
    "sell_price": 0
}
```

### Modify Controls

Edit `project.godot` [input] section or use Project Settings > Input Map in editor.

## Next Steps

1. Read `GAME_DESIGN.md` for full feature documentation
2. Explore the code comments for implementation details
3. Check Godot's official documentation for engine features
4. Join the Godot community forums for support

## Useful Resources

- [Godot Documentation](https://docs.godotengine.org/)
- [Godot Asset Library](https://godotengine.org/asset-library/asset)
- [Stardew Valley Wiki](https://stardewvalleywiki.com/) (for inspiration)
- [OpenGameArt](https://opengameart.org/) (free assets)
