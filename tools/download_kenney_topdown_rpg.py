#!/usr/bin/env python3
"""
Download Kenney Top-Down RPG Pack (NOT Tower Defense)
This pack contains proper orthographic top-down assets for farm simulation games.
"""
import requests
import os
import zipfile
import io
from pathlib import Path

def download_kenney_topdown_rpg():
    """Download Kenney Top-Down RPG Pack"""
    
    # Kenney Top-Down RPG Pack direct download URL
    # This is the correct pack with orthographic top-down perspective
    url = "https://kenney.nl/media/pages/assets/top-down-rpg/b5825c11b0-1732706980/kenney_topdown-rpg.zip"
    
    output_dir = Path("D:/repo/stardew_valley/outer_resource/kenney_top-down-rpg")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    zip_path = output_dir / "kenney_topdown-rpg.zip"
    
    print("=" * 60)
    print("Downloading Kenney Top-Down RPG Pack")
    print("=" * 60)
    print(f"URL: {url}")
    print(f"Output: {output_dir}")
    print()
    
    try:
        # Download with proper headers
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        print("Downloading...")
        response = requests.get(url, headers=headers, stream=True, timeout=60)
        response.raise_for_status()
        
        # Save zip file
        with open(zip_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print(f"✓ Downloaded: {zip_path.name} ({zip_path.stat().st_size / 1024 / 1024:.1f} MB)")
        
        # Extract
        print("\nExtracting...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(output_dir)
        
        print(f"✓ Extracted to: {output_dir}")
        
        # List contents
        print("\n📦 Package contents:")
        for item in sorted(output_dir.iterdir()):
            if item.is_file():
                size = item.stat().st_size / 1024
                print(f"  📄 {item.name} ({size:.1f} KB)")
            elif item.is_dir():
                file_count = len(list(item.rglob('*')))
                print(f"  📁 {item.name}/ ({file_count} files)")
        
        print("\n" + "=" * 60)
        print("✓ Success! Kenney Top-Down RPG Pack is ready.")
        print("=" * 60)
        print("\nThis pack contains:")
        print("  • Orthographic top-down houses and buildings")
        print("  • Characters and NPCs")
        print("  • Trees, plants, and decorations")
        print("  • Fences, paths, and terrain tiles")
        print("  • All assets are CC0 (public domain)")
        print("\nNext steps:")
        print("  1. Check the PNG/Default size/ folder for house assets")
        print("  2. Replace farmhouse_kenney_v01.png with appropriate top-down house")
        print("  3. Update world_farm.tscn to reference new asset")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"\n✗ Download failed: {e}")
        print("\n⚠ Alternative: Manually download from:")
        print("  https://kenney.nl/assets/top-down-rpg")
        print("  Save to: outer_resource/kenney_top-down-rpg/")
        return False

if __name__ == "__main__":
    download_kenney_topdown_rpg()
