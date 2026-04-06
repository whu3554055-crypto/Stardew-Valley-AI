#!/usr/bin/env python3
"""
Generate Environment Asset Placeholders for Cyber Town

Creates placeholder sprites and audio for:
- Town environment (streets, lights, plants, details)
- River and water features
- Forest environment
- Ambient sounds
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import wave
import random
import math

# Base directory
BASE_DIR = Path(__file__).parent.parent

def create_town_assets():
    """Create town environment assets"""
    print("Creating town environment assets...")

    # Directory structure
    town_dir = BASE_DIR / "sprites" / "environment" / "town"
    town_dir.mkdir(parents=True, exist_ok=True)

    # Street elements
    street_elements = {
        "cobblestone_tile": {"size": (64, 64), "color": (120, 120, 130)},
        "street_lamp": {"size": (48, 96), "color": (80, 70, 60)},
        "bench": {"size": (80, 40), "color": (139, 69, 19)},
        "trash_can": {"size": (32, 48), "color": (100, 100, 100)},
        "flower_pot": {"size": (32, 32), "color": (160, 82, 45)},
        "mailbox": {"size": (24, 48), "color": (70, 130, 180)},
        "sign_post": {"size": (16, 64), "color": (139, 69, 19)},
        "fence_wood": {"size": (64, 32), "color": (160, 82, 45)},
        "fence_stone": {"size": (64, 32), "color": (128, 128, 128)},
        "planter_box": {"size": (64, 32), "color": (139, 69, 19)},
    }

    for name, config in street_elements.items():
        img = Image.new('RGBA', config["size"], (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw base shape
        color = config["color"]
        w, h = config["size"]

        if "lamp" in name:
            # Street lamp
            draw.rectangle([w//2-3, 0, w//2+3, h-20], fill=color)  # pole
            draw.ellipse([w//2-12, 0, w//2+12, 24], fill=(255, 255, 200))  # light
            draw.ellipse([w//2-10, 2, w//2+10, 22], fill=(255, 255, 220))  # glow
        elif "bench" in name:
            # Bench
            draw.rectangle([0, h-15, w, h], fill=color)  # seat
            draw.rectangle([5, 0, 15, h-15], fill=color)  # left back
            draw.rectangle([w-15, 0, w-5, h-15], fill=color)  # right back
        elif "trash" in name:
            # Trash can
            draw.ellipse([2, 0, w-2, 12], fill=color)
            draw.rectangle([0, 6, w, h-4], fill=color)
            draw.ellipse([2, h-10, w-2, h], fill=(color[0]-20, color[1]-20, color[2]-20))
        else:
            # Generic rectangle with detail
            draw.rectangle([2, 2, w-3, h-3], fill=color)
            draw.rectangle([6, 6, w-7, h-7], outline=(255, 255, 255, 100), width=2)

        img.save(town_dir / f"{name}.png")
        print(f"  Created: town/{name}.png")

    # Greenery
    greenery_dir = BASE_DIR / "sprites" / "environment" / "greenery"
    greenery_dir.mkdir(parents=True, exist_ok=True)

    plants = {
        "bush_small": {"size": (48, 48), "color": (34, 139, 34)},
        "bush_large": {"size": (80, 64), "color": (0, 100, 0)},
        "hedge": {"size": (64, 48), "color": (34, 139, 34)},
        "tree_sapling": {"size": (32, 64), "color": (139, 69, 19)},
        "grass_clump": {"size": (32, 32), "color": (50, 205, 50)},
        "fern": {"size": (40, 48), "color": (0, 128, 0)},
    }

    for name, config in plants.items():
        img = Image.new('RGBA', config["size"], (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = config["color"]
        w, h = config["size"]

        if "tree" in name:
            # Tree trunk
            draw.rectangle([w//2-4, h//2, w//2+4, h], fill=color)
            # Foliage
            draw.ellipse([4, 0, w-4, h//2+8], fill=(34, 139, 34))
            draw.ellipse([8, 4, w-8, h//2], fill=(50, 205, 50))
        elif "bush" in name or "hedge" in name:
            # Bush shape
            draw.ellipse([4, 8, w-4, h-4], fill=color)
            draw.ellipse([8, 4, w//2, h//2+4], fill=(color[0]+20, color[1]+20, color[2]+20))
            draw.ellipse([w//2-4, 4, w-8, h//2+4], fill=(color[0]+15, color[1]+15, color[2]+15))
        else:
            # Grass/fern
            for i in range(5):
                x = random.randint(4, w-8)
                y = random.randint(4, h-8)
                draw.ellipse([x, y, x+8, y+12], fill=color)

        img.save(greenery_dir / f"{name}.png")
        print(f"  Created: greenery/{name}.png")


def create_river_assets():
    """Create river and water assets"""
    print("\nCreating river and water assets...")

    water_dir = BASE_DIR / "sprites" / "environment" / "water"
    water_dir.mkdir(parents=True, exist_ok=True)

    water_elements = {
        "water_tile": {"size": (64, 64), "color": (65, 105, 225)},
        "rock_small": {"size": (32, 24), "color": (105, 105, 105)},
        "rock_medium": {"size": (48, 36), "color": (100, 100, 100)},
        "rock_large": {"size": (64, 48), "color": (95, 95, 95)},
        "seaweed": {"size": (24, 48), "color": (0, 100, 0)},
        "driftwood": {"size": (64, 24), "color": (139, 90, 43)},
        "bubble": {"size": (16, 16), "color": (200, 230, 255)},
        "lilypad": {"size": (40, 40), "color": (34, 139, 34)},
        "fish_small": {"size": (24, 12), "color": (255, 165, 0)},
        "bridge_wood": {"size": (128, 48), "color": (139, 69, 19)},
        "bridge_stone": {"size": (128, 48), "color": (128, 128, 128)},
        "rapids": {"size": (64, 64), "color": (100, 149, 237)},
        "waterfall": {"size": (48, 96), "color": (173, 216, 230)},
    }

    for name, config in water_elements.items():
        img = Image.new('RGBA', config["size"], (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = config["color"]
        w, h = config["size"]

        if "water" in name and "tile" in name:
            # Water tile with waves
            draw.rectangle([0, 0, w, h], fill=color)
            for i in range(3):
                y = 16 + i * 16
                draw.arc([0, y-8, w, y+8], 0, 180, fill=(255, 255, 255, 100), width=2)
        elif "rock" in name:
            # Rock
            draw.ellipse([2, 2, w-3, h-3], fill=color)
            draw.ellipse([6, 6, w//2, h//2], fill=(color[0]+30, color[1]+30, color[2]+30))
        elif "seaweed" in name:
            # Seaweed
            for i in range(3):
                x = 6 + i * 6
                points = [(x, h), (x-3, h-16), (x+2, h-32), (x-1, h-48)]
                draw.line(points, fill=color, width=3)
        elif "bubble" in name:
            # Bubble
            draw.ellipse([2, 2, w-2, h-2], fill=color)
            draw.ellipse([4, 4, 8, 8], fill=(255, 255, 255, 200))
        elif "bridge" in name:
            # Bridge
            draw.rectangle([0, h//2-4, w, h//2+4], fill=color)
            for i in range(0, w, 16):
                draw.rectangle([i, h//2-8, i+4, h//2+8], fill=(color[0]-20, color[1]-20, color[2]-20))
        elif "waterfall" in name:
            # Waterfall
            draw.rectangle([w//2-8, 0, w//2+8, h], fill=color)
            for i in range(0, h, 12):
                draw.line([w//2-6, i, w//2+6, i+6], fill=(255, 255, 255, 150), width=2)
        else:
            # Default shape
            draw.ellipse([2, 2, w-3, h-3], fill=color)

        img.save(water_dir / f"{name}.png")
        print(f"  Created: water/{name}.png")


def create_forest_assets():
    """Create forest environment assets"""
    print("\nCreating forest environment assets...")

    forest_dir = BASE_DIR / "sprites" / "environment" / "forest"
    forest_dir.mkdir(parents=True, exist_ok=True)

    forest_elements = {
        "tree_pine": {"size": (80, 120), "color": (139, 69, 19)},
        "tree_oak": {"size": (96, 110), "color": (139, 69, 19)},
        "tree_stump": {"size": (48, 32), "color": (160, 82, 45)},
        "mushroom_red": {"size": (24, 24), "color": (255, 0, 0)},
        "mushroom_brown": {"size": (20, 20), "color": (139, 69, 19)},
        "flower_wild": {"size": (24, 32), "color": (255, 105, 180)},
        "flower_blue": {"size": (24, 28), "color": (100, 149, 237)},
        "rabbit": {"size": (32, 24), "color": (200, 200, 200)},
        "squirrel": {"size": (28, 24), "color": (139, 69, 19)},
        "bird": {"size": (20, 16), "color": (255, 165, 0)},
        "butterfly": {"size": (16, 16), "color": (255, 105, 180)},
        "log_fallen": {"size": (96, 24), "color": (139, 69, 19)},
        "berry_bush": {"size": (48, 48), "color": (0, 100, 0)},
    }

    for name, config in forest_elements.items():
        img = Image.new('RGBA', config["size"], (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = config["color"]
        w, h = config["size"]

        if "tree_pine" in name:
            # Pine tree
            draw.rectangle([w//2-6, h//2, w//2+6, h], fill=color)
            for i in range(3):
                y = i * (h//3)
                width = w - i * 16
                draw.polygon([(w//2, y), (w//2-width//2, y+h//3), (w//2+width//2, y+h//3)],
                           fill=(0, 100+i*30, 0))
        elif "tree_oak" in name:
            # Oak tree
            draw.rectangle([w//2-8, h//2+8, w//2+8, h], fill=color)
            draw.ellipse([4, 0, w-4, h//2+12], fill=(34, 139, 34))
            draw.ellipse([12, 8, w//2, h//2], fill=(50, 205, 50))
        elif "mushroom" in name:
            # Mushroom
            draw.rectangle([w//2-3, h//2, w//2+3, h], fill=(255, 250, 240))
            draw.ellipse([2, 2, w-2, h//2+2], fill=color)
            if "red" in name:
                draw.ellipse([6, 6, 10, 10], fill=(255, 255, 255))
                draw.ellipse([12, 8, 16, 12], fill=(255, 255, 255))
        elif "rabbit" in name or "squirrel" in name:
            # Small animal
            draw.ellipse([4, 6, w-4, h-2], fill=color)
            draw.ellipse([w-10, 2, w-2, 12], fill=color)  # head
            draw.ellipse([w-8, 4, w-6, 6], fill=(0, 0, 0))  # eye
        elif "bird" in name:
            # Bird
            draw.ellipse([4, 6, w-4, h-2], fill=color)
            draw.polygon([(w-4, 8), (w+2, 6), (w+2, 10)], fill=(255, 140, 0))  # beak
            draw.ellipse([w-6, 7, w-4, 9], fill=(0, 0, 0))  # eye
        elif "butterfly" in name:
            # Butterfly
            draw.ellipse([2, 4, 10, 12], fill=color)
            draw.ellipse([6, 4, 14, 12], fill=color)
            draw.line([8, 2, 8, 14], fill=(0, 0, 0), width=1)
        else:
            # Default (flowers, bushes, etc.)
            draw.ellipse([4, 8, w-4, h-4], fill=color)
            if "flower" in name:
                draw.ellipse([w//2-3, 4, w//2+3, 10], fill=(255, 255, 0))

        img.save(forest_dir / f"{name}.png")
        print(f"  Created: forest/{name}.png")


def create_ambient_audio():
    """Create ambient audio placeholders"""
    print("\nCreating ambient audio placeholders...")

    audio_dir = BASE_DIR / "audio" / "ambience_extended"
    audio_dir.mkdir(parents=True, exist_ok=True)

    ambient_sounds = {
        "river_flow.wav": {"duration": 30, "freq": 200},
        "stream_gentle.wav": {"duration": 30, "freq": 250},
        "birds_morning.wav": {"duration": 45, "freq": 2000},
        "birds_forest.wav": {"duration": 45, "freq": 1800},
        "rain_light.wav": {"duration": 60, "freq": 500},
        "rain_heavy.wav": {"duration": 60, "freq": 400},
        "wind_trees.wav": {"duration": 45, "freq": 150},
        "crickets_night.wav": {"duration": 60, "freq": 3000},
        "frogs_pond.wav": {"duration": 30, "freq": 400},
        "leaves_rustle.wav": {"duration": 20, "freq": 800},
    }

    for filename, config in ambient_sounds.items():
        filepath = audio_dir / filename
        duration = config["duration"]
        sample_rate = 22050
        freq = config["freq"]

        # Generate simple tone as placeholder
        with wave.open(str(filepath), 'w') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)

            # Generate audio data
            frames = b''
            num_samples = int(sample_rate * duration)
            for i in range(num_samples):
                # Simple sine wave with some noise
                t = i / sample_rate
                value = int(5000 * math.sin(2 * math.pi * freq * t) * math.exp(-t * 0.1))
                # Add some randomness for natural sound
                value += random.randint(-1000, 1000)
                # Clamp to 16-bit range
                value = max(-32768, min(32767, value))
                frames += value.to_bytes(2, byteorder='little', signed=True)

            wav_file.writeframes(frames)

        print(f"  Created: ambience_extended/{filename}")


def generate_asset_manifest():
    """Update asset manifest with new environment assets"""
    import json

    manifest = {
        "project": "Cyber Town - Environment Assets",
        "version": "2.0",
        "generated": "2026-04-06",
        "categories": {
            "town": {
                "description": "Town environment elements",
                "path": "sprites/environment/town/",
                "items": [
                    "cobblestone_tile.png",
                    "street_lamp.png",
                    "bench.png",
                    "trash_can.png",
                    "flower_pot.png",
                    "mailbox.png",
                    "sign_post.png",
                    "fence_wood.png",
                    "fence_stone.png",
                    "planter_box.png"
                ]
            },
            "greenery": {
                "description": "Plants and vegetation",
                "path": "sprites/environment/greenery/",
                "items": [
                    "bush_small.png",
                    "bush_large.png",
                    "hedge.png",
                    "tree_sapling.png",
                    "grass_clump.png",
                    "fern.png"
                ]
            },
            "water": {
                "description": "River and water features",
                "path": "sprites/environment/water/",
                "items": [
                    "water_tile.png",
                    "rock_small.png",
                    "rock_medium.png",
                    "rock_large.png",
                    "seaweed.png",
                    "driftwood.png",
                    "bubble.png",
                    "lilypad.png",
                    "fish_small.png",
                    "bridge_wood.png",
                    "bridge_stone.png",
                    "rapids.png",
                    "waterfall.png"
                ]
            },
            "forest": {
                "description": "Forest environment",
                "path": "sprites/environment/forest/",
                "items": [
                    "tree_pine.png",
                    "tree_oak.png",
                    "tree_stump.png",
                    "mushroom_red.png",
                    "mushroom_brown.png",
                    "flower_wild.png",
                    "flower_blue.png",
                    "rabbit.png",
                    "squirrel.png",
                    "bird.png",
                    "butterfly.png",
                    "log_fallen.png",
                    "berry_bush.png"
                ]
            },
            "audio_ambient": {
                "description": "Ambient environmental sounds",
                "path": "audio/ambience_extended/",
                "items": [
                    "river_flow.wav",
                    "stream_gentle.wav",
                    "birds_morning.wav",
                    "birds_forest.wav",
                    "rain_light.wav",
                    "rain_heavy.wav",
                    "wind_trees.wav",
                    "crickets_night.wav",
                    "frogs_pond.wav",
                    "leaves_rustle.wav"
                ]
            }
        }
    }

    manifest_path = BASE_DIR / "environment_assets_manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f"\nManifest saved to: {manifest_path}")


if __name__ == "__main__":
    print("="*60)
    print("Cyber Town Environment Asset Generator")
    print("="*60)

    create_town_assets()
    create_river_assets()
    create_forest_assets()
    create_ambient_audio()
    generate_asset_manifest()

    print("\n" + "="*60)
    print("Environment asset generation complete!")
    print("="*60)
