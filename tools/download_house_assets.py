#!/usr/bin/env python3
"""
Download free top-down pixel art house assets for Stardew Valley clone
"""
import requests
import os
from pathlib import Path

def download_file(url, output_path):
    """Download a file from URL to output_path"""
    print(f"Downloading: {url}")
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    response = requests.get(url, headers=headers, stream=True)
    response.raise_for_status()
    
    with open(output_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    
    file_size = os.path.getsize(output_path)
    print(f"✓ Downloaded: {output_path} ({file_size / 1024:.1f} KB)")
    return output_path

def main():
    output_dir = Path("D:/repo/stardew_valley/assets/sprites/buildings")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Try multiple sources for top-down house assets
    
    # Source 1: OpenGameArt - RPG House (CC0)
    # This is a known CC0 top-down house sprite
    try:
        print("\n=== Attempting Source 1: OpenGameArt RPG House ===")
        url = "https://opengameart.org/sites/default/files/house_12.png"
        output = output_dir / "house_topdown_v01.png"
        download_file(url, output)
        print("✓ Success! Using OpenGameArt RPG House")
        return
    except Exception as e:
        print(f"✗ Failed: {e}")
    
    # Source 2: Alternative OpenGameArt house
    try:
        print("\n=== Attempting Source 2: Alternative House ===")
        url = "https://opengameart.org/sites/default/files/styles/original/public/house-tileset.png"
        output = output_dir / "house_topdown_v02.png"
        download_file(url, output)
        print("✓ Success! Using alternative house")
        return
    except Exception as e:
        print(f"✗ Failed: {e}")
    
    # Source 3: Use existing Kenney isometric farm assets and extract buildings
    print("\n=== Fallback: Check existing Kenney assets ===")
    kenney_zip = Path("D:/repo/stardew_valley/art_out/kenney_isometric-miniature-farm.zip")
    if kenney_zip.exists():
        print(f"Found Kenney asset: {kenney_zip}")
        print("Note: This is isometric perspective, not ideal but can be used temporarily")
    else:
        print("No Kenney assets found")
    
    print("\n⚠ Could not automatically download suitable top-down house assets")
    print("Recommendation: Manually download from one of these sources:")
    print("1. https://kenney.nl/assets/top-down-rpg (Kenney Top-Down RPG)")
    print("2. https://gif-superretroworld.itch.io/farming-pack (Super Retro World Farming)")
    print("3. https://craftpix.net/freebies/main-characters-home-free-top-down-pixel-art-asset/")

if __name__ == "__main__":
    main()
