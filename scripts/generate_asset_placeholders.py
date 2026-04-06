#!/usr/bin/env python3
"""
生成游戏素材占位符文件

此脚本创建所有必需的素材文件和配置文件，
方便后续替换为实际的美术资源。
"""

import json
import os
from pathlib import Path

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets"


def create_placeholder_textures():
    """创建占位符纹理配置"""
    textures_config = {
        "characters": {
            "player": {
                "filename": "player.png",
                "frames": {"idle": 4, "walk": 8, "talk": 4, "work": 6},
                "directions": 4,
                "size": [64, 64],
                "status": "placeholder"
            }
        },
        "items": {
            "crops": ["parsnip", "potato", "carrot", "tomato", "corn", "pumpkin"],
            "tools": ["hoe", "watering_can", "scythe", "axe"],
            "resources": ["wood", "stone", "iron_ore", "gold_ore"],
            "consumables": ["health_potion", "energy_drink", "bread", "salad"]
        },
        "ui": {
            "dialogue_box": {"size": [800, 200]},
            "inventory_slot": {"size": [64, 64]},
            "emotion_icons": ["happy", "sad", "angry", "excited", "neutral"]
        }
    }

    config_path = ASSETS_DIR / "config" / "textures_config.json"
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(textures_config, f, indent=2, ensure_ascii=False)

    print(f"[OK] Created textures config: {config_path}")


def create_audio_manifest():
    """创建音频清单文件"""
    audio_manifest = {
        "ambience": {
            "spring.ogg": {"duration": 60, "loop": True, "description": "春季环境音"},
            "summer.ogg": {"duration": 60, "loop": True, "description": "夏季环境音"},
            "fall.ogg": {"duration": 60, "loop": True, "description": "秋季环境音"},
            "winter.ogg": {"duration": 60, "loop": True, "description": "冬季环境音"},
            "rain.ogg": {"duration": 30, "loop": True, "description": "雨声"},
            "storm.ogg": {"duration": 45, "loop": True, "description": "暴风雨"},
            "night.ogg": {"duration": 60, "loop": True, "description": "夜晚环境音"}
        },
        "emotions": {
            "happy.wav": {"max_duration": 2, "description": "开心音效"},
            "sad.wav": {"max_duration": 2, "description": "悲伤音效"},
            "excited.wav": {"max_duration": 2, "description": "兴奋音效"},
            "angry.wav": {"max_duration": 2, "description": "生气音效"},
            "surprised.wav": {"max_duration": 2, "description": "惊讶音效"},
            "neutral.wav": {"max_duration": 2, "description": "中性音效"}
        },
        "activities": {
            "farming_till.wav": "耕地音效",
            "farming_plant.wav": "种植音效",
            "farming_water.wav": "浇水音效",
            "farming_harvest.wav": "收获音效",
            "walking_grass.wav": "草地脚步声",
            "walking_wood.wav": "木板脚步声",
            "walking_stone.wav": "石板脚步声",
            "chop_wood.wav": "砍树音效",
            "mine_pickaxe.wav": "挖矿音效"
        },
        "locations": {
            "shop_enter.wav": "进入商店",
            "shop_bell.wav": "商店门铃",
            "town_crowd.ogg": "城镇人群嘈杂声",
            "farm_animals.ogg": "农场动物声音",
            "forest_birds.ogg": "森林鸟鸣",
            "beach_waves.ogg": "海滩海浪声"
        },
        "ui": {
            "click.wav": "点击按钮",
            "confirm.wav": "确认操作",
            "cancel.wav": "取消操作",
            "hover.wav": "鼠标悬停",
            "notification.wav": "通知提示音",
            "quest_complete.wav": "任务完成音效",
            "level_up.wav": "升级音效",
            "error.wav": "错误提示音"
        }
    }

    manifest_path = ASSETS_DIR / "audio" / "audio_manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(audio_manifest, f, indent=2, ensure_ascii=False)

    print(f"[OK] Created audio manifest: {manifest_path}")


def create_items_database():
    """创建物品数据库配置"""
    items_db = {
        "crops": [
            {"id": "parsnip", "name": "防风草", "season": "spring", "grow_days": 4, "sell_price": 35, "energy": 13},
            {"id": "potato", "name": "土豆", "season": "spring", "grow_days": 6, "sell_price": 80, "energy": 26},
            {"id": "carrot", "name": "胡萝卜", "season": "fall", "grow_days": 3, "sell_price": 35, "energy": 15},
            {"id": "tomato", "name": "番茄", "season": "summer", "grow_days": 11, "sell_price": 60, "energy": 18, "regrows": True},
            {"id": "corn", "name": "玉米", "season": "summer,fall", "grow_days": 14, "sell_price": 50, "energy": 20, "regrows": True},
            {"id": "pumpkin", "name": "南瓜", "season": "fall", "grow_days": 13, "sell_price": 320, "energy": 36}
        ],
        "tools": [
            {"id": "hoe", "name": "锄头", "type": "tool", "durability": 100, "energy_cost": 5},
            {"id": "watering_can", "name": "洒水壶", "type": "tool", "capacity": 40, "energy_cost": 2},
            {"id": "scythe", "name": "镰刀", "type": "tool", "durability": 150, "energy_cost": 3},
            {"id": "axe", "name": "斧头", "type": "tool", "durability": 100, "energy_cost": 7}
        ],
        "resources": [
            {"id": "wood", "name": "木材", "type": "resource", "stack_size": 999, "sell_price": 2},
            {"id": "stone", "name": "石头", "type": "resource", "stack_size": 999, "sell_price": 3},
            {"id": "iron_ore", "name": "铁矿石", "type": "resource", "stack_size": 999, "sell_price": 15},
            {"id": "gold_ore", "name": "金矿石", "type": "resource", "stack_size": 999, "sell_price": 25}
        ],
        "consumables": [
            {"id": "health_potion", "name": "生命药水", "type": "consumable", "effect": {"health": 50}, "sell_price": 50},
            {"id": "energy_drink", "name": "能量饮料", "type": "consumable", "effect": {"energy": 30}, "sell_price": 40},
            {"id": "bread", "name": "面包", "type": "food", "effect": {"energy": 25, "health": 10}, "sell_price": 60},
            {"id": "salad", "name": "沙拉", "type": "food", "effect": {"energy": 35, "health": 20}, "sell_price": 110}
        ]
    }

    db_path = ASSETS_DIR / "config" / "items_database.json"
    with open(db_path, 'w', encoding='utf-8') as f:
        json.dump(items_db, f, indent=2, ensure_ascii=False)

    print(f"[OK] Created items database: {db_path}")


def create_tilemap_configs():
    """创建瓦片地图配置"""
    tilemaps = {
        "terrain": {
            "grass": {"tile_size": 16, "tiles_count": 256, "animated": False},
            "dirt": {"tile_size": 16, "tiles_count": 256, "animated": False},
            "water": {"tile_size": 16, "tiles_count": 64, "animated": True, "frame_count": 4},
            "sand": {"tile_size": 16, "tiles_count": 128, "animated": False},
            "snow": {"tile_size": 16, "tiles_count": 128, "animated": False},
            "flowers": {"tile_size": 16, "tiles_count": 64, "animated": False},
            "rocks": {"tile_size": 16, "tiles_count": 32, "animated": False},
            "trees": {"tile_size": 16, "tiles_count": 48, "animated": True, "frame_count": 2}
        },
        "buildings": {
            "pierre_shop": {"size": [320, 240], "interior": True},
            "town_hall": {"size": [280, 200], "interior": True},
            "carpenter_shop": {"size": [240, 200], "interior": True},
            "hospital": {"size": [200, 180], "interior": True},
            "saloon": {"size": [220, 180], "interior": True},
            "blacksmith": {"size": [200, 160], "interior": True}
        }
    }

    config_path = ASSETS_DIR / "config" / "tilemaps_config.json"
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(tilemaps, f, indent=2, ensure_ascii=False)

    print(f"[OK] Created tilemaps config: {config_path}")


def generate_readme_files():
    """在各个目录生成 README 说明文件"""

    # Sprites directory README
    sprites_readme = """# 精灵图素材目录

请将角色、物品和 UI 的 PNG 文件放在对应的子目录中。

## 技术要求
- 格式: PNG (支持透明通道)
- 色彩: RGBA, 最多 32 色调色板
- 尺寸: 参考 config/textures_config.json

## 命名规范
使用 snake_case，例如: `npc_pierre.png`, `item_parsnip.png`
"""

    with open(ASSETS_DIR / "sprites" / "README.md", 'w', encoding='utf-8') as f:
        f.write(sprites_readme)

    # Audio directory README
    audio_readme = """# 音频素材目录

请按照 audio_manifest.json 中的清单放置音频文件。

## 技术要求
- 音乐/环境音: OGG Vorbis, 44.1kHz, 立体声
- 音效: WAV, 22.05kHz, 单声道
- 音量: -6dB 峰值标准化

## 循环音频
标记为 loop: true 的文件需要无缝循环播放。
"""

    with open(ASSETS_DIR / "audio" / "README.md", 'w', encoding='utf-8') as f:
        f.write(audio_readme)

    print("[OK] Created directory README files")


def main():
    """主函数"""
    print("=" * 60)
    print("生成赛博小镇游戏素材占位符配置")
    print("=" * 60)
    print()

    # 创建所有配置
    create_placeholder_textures()
    create_audio_manifest()
    create_items_database()
    create_tilemap_configs()
    generate_readme_files()

    print()
    print("=" * 60)
    print("[DONE] 所有占位符配置已生成！")
    print("=" * 60)
    print()
    print("下一步:")
    print("1. 查看 assets/ASSETS_README.md 了解完整需求")
    print("2. 收集或制作实际的素材文件")
    print("3. 将素材文件放入对应目录")
    print("4. 更新配置文件中的状态字段")
    print()


if __name__ == "__main__":
    main()
