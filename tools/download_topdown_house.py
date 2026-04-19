#!/usr/bin/env python3
"""
Download free orthographic top-down pixel art house assets
Alternative sources for proper 2D top-down farm buildings
"""
import requests
import os
from pathlib import Path

def download_file(url, output_path):
    """Download a file from URL to output_path"""
    print(f"Downloading: {url}")
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    response = requests.get(url, headers=headers, stream=True, timeout=30)
    response.raise_for_status()
    
    with open(output_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    
    file_size = os.path.getsize(output_path)
    print(f"✓ Downloaded: {output_path.name} ({file_size / 1024:.1f} KB)")
    return output_path

def main():
    output_dir = Path("D:/repo/stardew_valley/assets/sprites/buildings")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("=" * 60)
    print("Downloading Orthographic Top-Down House Assets")
    print("=" * 60)
    
    # Try multiple sources for orthographic top-down house
    
    # Source 1: OpenGameArt - Simple top-down house
    sources = [
        {
            "name": "OpenGameArt RPG House",
            "url": "https://opengameart.org/sites/default/files/house_12.png",
            "output": "house_topdown_v02.png"
        },
        {
            "name": "Alternative House Tileset",
            "url": "https://opengameart.org/sites/default/files/styles/original/public/house-tileset.png",
            "output": "house_topdown_v03.png"
        },
        {
            "name": "Pixel Art House",
            "url": "https://opengameart.org/sites/default/files/house3_0.png",
            "output": "house_topdown_v04.png"
        }
    ]
    
    for i, source in enumerate(sources, 1):
        print(f"\n=== Attempt {i}: {source['name']} ===")
        try:
            output = output_dir / source['output']
            download_file(source['url'], output)
            print(f"✓ Success! Downloaded {source['output']}")
            print(f"\nNext steps:")
            print(f"  1. Check the file: assets/sprites/buildings/{source['output']}")
            print(f"  2. Verify it's orthographic top-down (not isometric)")
            print(f"  3. Update world_farm.tscn to reference this file")
            return True
        except Exception as e:
            print(f"✗ Failed: {e}")
    
    print("\n" + "=" * 60)
    print("⚠ Could not automatically download suitable assets")
    print("=" * 60)
    print("\nManual alternatives:")
    print("1. Kenney Top-Down RPG Pack (RECOMMENDED)")
    print("   https://kenney.nl/assets/top-down-rpg")
    print("   - Proper orthographic top-down perspective")
    print("   - Complete set of buildings, characters, decorations")
    print("   - CC0 license (free for any use)")
    print("\n2. OpenGameArt Top-Down Assets")
    print("   https://opengameart.org/art-search-advanced?keys=top+down+house")
    print("   - Search for 'top down house' or 'orthographic building'")
    print("   - Verify perspective matches ground tiles")
    print("\n3. Itch.io Free Assets")
    print("   https://itch.io/game-assets/free/tag-top-down")
    print("   - Filter by 'top-down' and 'pixel art'")
    
    return False

if __name__ == "__main__":
    main()
