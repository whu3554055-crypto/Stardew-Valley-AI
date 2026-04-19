#!/usr/bin/env python3
"""
从 OpenGameArt 下载正交俯视角像素房屋素材
Orthographic Top-Down Pixel Art House Assets
"""
import requests
import os
from pathlib import Path

def download_file(url, output_path, description):
    """下载文件并显示进度"""
    print(f"\n📥 下载: {description}")
    print(f"   URL: {url}")
    print(f"   保存: {output_path}")
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, stream=True, timeout=30)
        response.raise_for_status()
        
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        file_size = os.path.getsize(output_path)
        print(f"   ✅ 成功! ({file_size / 1024:.1f} KB)")
        return True
        
    except Exception as e:
        print(f"   ❌ 失败: {e}")
        return False

def main():
    output_dir = Path("D:/repo/stardew_valley/assets/sprites/buildings")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("=" * 60)
    print("下载正交俯视角像素房屋素材")
    print("=" * 60)
    
    # 多个备选资源，按推荐顺序排列
    sources = [
        {
            "name": "RPG Housing Set (OpenGameArt)",
            "url": "https://opengameart.org/sites/default/files/house_12.png",
            "file": "house_orthographic_v01.png",
            "desc": "RPG 风格房屋，正交俯视角"
        },
        {
            "name": "Simple House Tileset (OpenGameArt)",
            "url": "https://opengameart.org/sites/default/files/house3_0.png",
            "file": "house_orthographic_v02.png",
            "desc": "简单房屋瓦片集"
        },
        {
            "name": "Village Houses (OpenGameArt)",
            "url": "https://opengameart.org/sites/default/files/village-houses.png",
            "file": "house_orthographic_v03.png",
            "desc": "村庄房屋集合"
        }
    ]
    
    success = False
    
    for i, source in enumerate(sources, 1):
        print(f"\n{'='*60}")
        print(f"尝试 {i}/{len(sources)}: {source['name']}")
        print(f"{'='*60}")
        
        output = output_dir / source['file']
        
        if download_file(source['url'], output, source['desc']):
            success = True
            print(f"\n{'='*60}")
            print("✅ 下载成功！")
            print(f"{'='*60}")
            print(f"\n文件位置: {output}")
            print(f"\n下一步:")
            print(f"1. 在 Godot 中查看此素材，确认是正交俯视角（不是等距视角）")
            print(f"2. 如果是正确的，更新 world_farm.tscn 引用此文件")
            print(f"3. 调整房屋位置和缩放比例")
            break
        else:
            if os.path.exists(output):
                os.remove(output)
    
    if not success:
        print(f"\n{'='*60}")
        print("⚠️  自动下载失败，请手动下载")
        print(f"{'='*60}")
        print("\n推荐资源（正交俯视角像素房屋）:")
        print("\n1. ⭐ Kenney Top-Down RPG Pack（最推荐）")
        print("   https://kenney.nl/assets/top-down-rpg")
        print("   - 完整的俯视角 RPG 素材包")
        print("   - 包含房屋、NPC、装饰物")
        print("   - CC0 许可，免费商用")
        print("   - 下载后放到: outer_resource/kenney_top-down-rpg/")
        
        print("\n2. OpenGameArt 搜索")
        print("   https://opengameart.org/art-search-advanced?keys=top+down+house+pixel")
        print("   - 搜索关键词: 'top down house pixel'")
        print("   - 筛选: 2D, Orthographic（正交）")
        
        print("\n3. Itch.io 免费素材")
        print("   https://itch.io/game-assets/free/tag-top-down/tag-pixel-art")
        print("   - 筛选: Top-Down + Pixel Art")
        print("   - 注意选择正交视角（不是等距）")
        
        print("\n4. CraftPix 免费素材")
        print("   https://craftpix.net/freebies/")
        print("   - 搜索 'Top Down House'")

if __name__ == "__main__":
    main()
