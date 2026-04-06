#!/usr/bin/env python3
"""
Game Asset Downloader for Cyber Town Project

Downloads free game assets from legitimate sources:
- OpenGameArt.org
- Kenney.nl
- itch.io (free assets)
- Craftpix.net (freebies)

Usage:
    python download_assets.py [--category sprites|audio|all]
"""

import os
import sys
import json
from pathlib import Path
from urllib.request import urlretrieve
from urllib.error import URLError
import zipfile
import shutil

# Base directories
BASE_DIR = Path(__file__).parent.parent
SPRITES_DIR = BASE_DIR / "sprites"
AUDIO_DIR = BASE_DIR / "audio"
TILEMAPS_DIR = BASE_DIR / "tilemaps"

# Asset package URLs (free, open-source friendly licenses)
ASSET_PACKAGES = {
    # Character sprites - OpenGameArt
    "characters": {
        "url": "https://opengameart.org/sites/default/files/Character%20Pack.zip",
        "target_dir": SPRITES_DIR / "characters",
        "description": "Basic character sprites with animations"
    },

    # Farm/RPG tileset - OpenGameArt
    "farm_tiles": {
        "url": "https://opengameart.org/sites/default/files/farm_pack_0.png",
        "target_dir": TILEMAPS_DIR / "terrain",
        "description": "Farm and RPG terrain tiles"
    },

    # UI elements - Kenney.nl (CC0)
    "ui_pack": {
        "url": "https://kenney.nl/media/pages/assets/ui-pack/ad14f5f79a-1680098806/ui-pack.zip",
        "target_dir": SPRITES_DIR / "ui",
        "description": "Complete UI element pack"
    },

    # Item icons - OpenGameArt
    "item_icons": {
        "url": "https://opengameart.org/sites/default/files/icons_35.png",
        "target_dir": SPRITES_DIR / "items",
        "description": "RPG item icons"
    },

    # Sound effects - Kenney.nl (CC0)
    "sfx_pack": {
        "url": "https://kenney.nl/media/pages/assets/digital-audio/b9c4e086cd-1680098806/digital-audio.zip",
        "target_dir": AUDIO_DIR,
        "description": "Digital sound effects pack"
    }
}


def create_placeholder_sprites():
    """Create simple placeholder sprites using PIL if available"""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("PIL not available. Installing Pillow...")
        os.system("pip install Pillow")
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            print("Failed to install Pillow. Skipping placeholder creation.")
            return False

    print("Creating placeholder sprites...")

    # Create character placeholders (64x64)
    characters_dir = SPRITES_DIR / "characters"
    characters_dir.mkdir(parents=True, exist_ok=True)

    npc_names = [
        "player", "npc_pierre", "npc_abigail", "npc_lewis",
        "npc_robin", "npc_penny", "npc_sebastian", "npc_haley",
        "npc_alex", "npc_maru", "npc_sam"
    ]

    colors = {
        "player": (100, 150, 255),
        "npc_pierre": (50, 150, 50),
        "npc_abigail": (150, 50, 200),
        "npc_lewis": (100, 180, 50),
        "npc_robin": (200, 50, 50),
        "npc_penny": (255, 150, 180),
        "npc_sebastian": (50, 50, 80),
        "npc_haley": (255, 220, 100),
        "npc_alex": (100, 200, 100),
        "npc_maru": (255, 180, 220),
        "npc_sam": (255, 220, 50)
    }

    for name in npc_names:
        img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw simple character shape
        color = colors.get(name, (128, 128, 128))

        # Body
        draw.ellipse([16, 8, 48, 40], fill=color)
        # Head
        draw.ellipse([20, 32, 44, 60], fill=color)

        img.save(characters_dir / f"{name}.png")
        print(f"  Created: {name}.png")

    # Create item placeholders (32x32)
    items_dir = SPRITES_DIR / "items"
    items_dir.mkdir(parents=True, exist_ok=True)

    item_categories = {
        "crops": ["parsnip", "potato", "carrot", "tomato", "corn", "pumpkin"],
        "tools": ["hoe", "watering_can", "scythe", "axe"],
        "resources": ["wood", "stone", "iron_ore", "gold_ore"],
        "consumables": ["health_potion", "energy_drink", "bread", "salad"]
    }

    category_colors = {
        "crops": (100, 200, 50),
        "tools": (150, 150, 150),
        "resources": (180, 130, 80),
        "consumables": (255, 100, 100)
    }

    for category, items in item_categories.items():
        cat_dir = items_dir / category
        cat_dir.mkdir(exist_ok=True)

        for item in items:
            img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)
            color = category_colors[category]

            # Draw simple item shape
            draw.rectangle([4, 4, 28, 28], fill=color)
            draw.rectangle([8, 8, 24, 24], outline=(255, 255, 255, 200), width=2)

            img.save(cat_dir / f"{item}.png")
            print(f"  Created: {category}/{item}.png")

    # Create UI placeholders
    ui_dir = SPRITES_DIR / "ui"
    ui_dir.mkdir(parents=True, exist_ok=True)

    ui_elements = {
        "dialogue_box": (800, 200),
        "name_tag": (200, 40),
        "inventory_slot": (64, 64),
        "inventory_bg": (600, 400),
        "shop_panel": (700, 500),
        "quest_log": (500, 400),
        "health_bar": (200, 20),
        "energy_bar": (200, 20)
    }

    for element, size in ui_elements.items():
        img = Image.new('RGBA', size, (50, 50, 80, 200))
        draw = ImageDraw.Draw(img)
        draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(200, 200, 255, 255), width=3)
        img.save(ui_dir / f"{element}.png")
        print(f"  Created: ui/{element}.png ({size[0]}x{size[1]})")

    # Create emotion icons (64x64)
    emotions = ["happy", "sad", "angry", "excited", "neutral"]
    emotion_colors = {
        "happy": (255, 220, 50),
        "sad": (100, 150, 255),
        "angry": (255, 80, 80),
        "excited": (255, 150, 50),
        "neutral": (180, 180, 180)
    }

    for emotion in emotions:
        img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = emotion_colors[emotion]

        # Draw circle
        draw.ellipse([8, 8, 56, 56], fill=color)

        # Draw simple face
        if emotion == "happy":
            draw.arc([16, 24, 48, 48], 0, 180, fill=(0, 0, 0), width=3)
        elif emotion == "sad":
            draw.arc([16, 32, 48, 56], 180, 360, fill=(0, 0, 0), width=3)
        elif emotion == "angry":
            draw.line([16, 28, 28, 24], fill=(0, 0, 0), width=3)
            draw.line([36, 24, 48, 28], fill=(0, 0, 0), width=3)
        elif emotion == "excited":
            draw.ellipse([20, 28, 28, 36], fill=(0, 0, 0))
            draw.ellipse([36, 28, 44, 36], fill=(0, 0, 0))
            draw.ellipse([26, 40, 38, 50], fill=(0, 0, 0))

        img.save(ui_dir / f"emotion_icon_{emotion}.png")
        print(f"  Created: ui/emotion_icon_{emotion}.png")

    print("\nPlaceholder sprites created successfully!")
    return True


def create_placeholder_audio():
    """Create silent placeholder audio files"""
    import wave
    import struct

    print("Creating placeholder audio files...")

    # Audio categories
    audio_files = {
        "ambience": ["spring.ogg", "summer.ogg", "fall.ogg", "winter.ogg",
                     "rain.ogg", "storm.ogg", "night.ogg"],
        "emotions": ["happy.wav", "sad.wav", "excited.wav",
                     "angry.wav", "surprised.wav", "neutral.wav"],
        "activities": ["farming_till.wav", "farming_plant.wav", "farming_water.wav",
                       "farming_harvest.wav", "walking_grass.wav", "chop_wood.wav",
                       "mine_pickaxe.wav", "fish_cast.wav"],
        "locations": ["shop_enter.wav", "shop_bell.wav", "town_crowd.ogg",
                      "forest_birds.ogg", "beach_waves.ogg"],
        "ui": ["click.wav", "confirm.wav", "cancel.wav", "hover.wav",
               "notification.wav", "quest_complete.wav", "level_up.wav", "error.wav"]
    }

    for category, files in audio_files.items():
        cat_dir = AUDIO_DIR / category
        cat_dir.mkdir(parents=True, exist_ok=True)

        for filename in files:
            filepath = cat_dir / filename

            if filename.endswith('.wav'):
                # Create minimal valid WAV file (silent)
                with wave.open(str(filepath), 'w') as wav_file:
                    wav_file.setnchannels(1)  # Mono
                    wav_file.setsampwidth(2)  # 16-bit
                    wav_file.setframerate(22050)
                    # Write 0.1 seconds of silence
                    frames = b'\x00\x00' * 2205
                    wav_file.writeframes(frames)
            else:
                # For OGG, create empty file with note
                with open(filepath, 'w') as f:
                    f.write("# Placeholder OGG file - replace with actual audio\n")

            print(f"  Created: {category}/{filename}")

    print("\nPlaceholder audio files created!")
    return True


def download_asset_package(name, config):
    """Download a single asset package"""
    print(f"\nDownloading {name}...")
    print(f"  Description: {config['description']}")
    print(f"  URL: {config['url']}")

    target_dir = Path(config['target_dir'])
    target_dir.mkdir(parents=True, exist_ok=True)

    # Extract filename from URL
    filename = config['url'].split('/')[-1]
    filepath = target_dir / filename

    try:
        print(f"  Downloading to: {filepath}")
        urlretrieve(config['url'], str(filepath))
        print(f"  [OK] Downloaded successfully")

        # Extract if zip file
        if filename.endswith('.zip'):
            print(f"  Extracting...")
            with zipfile.ZipFile(filepath, 'r') as zip_ref:
                zip_ref.extractall(target_dir)
            print(f"  [OK] Extracted to: {target_dir}")

        return True

    except URLError as e:
        print(f"  [FAIL] Download failed: {e.reason}")
        return False
    except Exception as e:
        print(f"  [ERROR] {str(e)}")
        return False


def generate_asset_manifest():
    """Generate a manifest file listing all assets"""
    print("\nGenerating asset manifest...")

    manifest = {
        "project": "Cyber Town - hello-agent",
        "version": "1.0",
        "generated": "2026-04-06",
        "assets": {
            "sprites": {},
            "audio": {},
            "tilemaps": {}
        }
    }

    # Scan sprites
    if SPRITES_DIR.exists():
        for category in ['characters', 'items', 'ui']:
            cat_dir = SPRITES_DIR / category
            if cat_dir.exists():
                files = [f.name for f in cat_dir.rglob('*.png')]
                manifest['assets']['sprites'][category] = files

    # Scan audio
    if AUDIO_DIR.exists():
        for category in ['ambience', 'emotions', 'activities', 'locations', 'ui']:
            cat_dir = AUDIO_DIR / category
            if cat_dir.exists():
                files = [f.name for f in cat_dir.rglob('*')]
                manifest['assets']['audio'][category] = files

    # Scan tilemaps
    if TILEMAPS_DIR.exists():
        for category in ['terrain', 'buildings']:
            cat_dir = TILEMAPS_DIR / category
            if cat_dir.exists():
                files = [f.name for f in cat_dir.rglob('*.png')]
                manifest['assets']['tilemaps'][category] = files

    # Save manifest
    manifest_path = BASE_DIR / "asset_manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f"Manifest saved to: {manifest_path}")
    return manifest


def main():
    """Main execution"""
    print("="*60)
    print("Cyber Town Game Asset Downloader")
    print("="*60)
    print()

    # Parse arguments
    category = "all"
    if len(sys.argv) > 1:
        category = sys.argv[1].lower()

    # Create directory structure
    print("Creating directory structure...")
    for dir_path in [SPRITES_DIR, AUDIO_DIR, TILEMAPS_DIR]:
        dir_path.mkdir(parents=True, exist_ok=True)
        print(f"  [OK] {dir_path.relative_to(BASE_DIR)}")

    print()

    # Step 1: Create placeholder assets
    print("="*60)
    print("STEP 1: Creating placeholder assets")
    print("="*60)

    if category in ["all", "sprites"]:
        create_placeholder_sprites()

    if category in ["all", "audio"]:
        create_placeholder_audio()

    print()

    # Step 2: Download asset packages (optional)
    print("="*60)
    print("STEP 2: Downloading asset packages")
    print("="*60)
    print("\nNote: Some downloads may fail due to URL changes.")
    print("The placeholder assets will work for development.\n")

    if category == "all":
        success_count = 0
        total_count = len(ASSET_PACKAGES)

        for name, config in ASSET_PACKAGES.items():
            if download_asset_package(name, config):
                success_count += 1

        print(f"\n{'='*60}")
        print(f"Download Summary: {success_count}/{total_count} packages downloaded")
        print(f"{'='*60}")

    # Step 3: Generate manifest
    print()
    print("="*60)
    print("STEP 3: Generating asset manifest")
    print("="*60)
    manifest = generate_asset_manifest()

    # Print summary
    print("\n" + "="*60)
    print("ASSET COLLECTION COMPLETE")
    print("="*60)
    print(f"\nSprites:")
    for category, files in manifest['assets']['sprites'].items():
        print(f"  {category}: {len(files)} files")

    print(f"\nAudio:")
    for category, files in manifest['assets']['audio'].items():
        print(f"  {category}: {len(files)} files")

    print(f"\nTilemaps:")
    for category, files in manifest['assets']['tilemaps'].items():
        print(f"  {category}: {len(files)} files")

    print(f"\nAll assets are ready in: {BASE_DIR}")
    print("\nNext steps:")
    print("  1. Review placeholder assets")
    print("  2. Replace with final artwork when available")
    print("  3. Update Godot project to reference these assets")


if __name__ == "__main__":
    main()
