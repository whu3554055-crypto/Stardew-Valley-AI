# 星露谷物语AI克隆版 - Stardew Valley AI Clone

> **会思考的NPC，永不重复的故事**  
> An AI-driven farming simulation with intelligent NPCs and dynamic narratives

[![Godot Engine](https://img.shields.io/badge/Godot-4.2+-blue.svg)](https://godotengine.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CI Status](https://github.com/YOUR_USERNAME/stardew_valley/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/stardew_valley/actions)
[![Docs](https://img.shields.io/badge/docs-complete-brightgreen.svg)](docs/README.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 🚀 快速开始

### 本地开发环境设置

**必需软件：**
- **Godot Engine 4.2+** - [下载](https://godotengine.org/download)
- **Python 3.11+** - AI 后端服务
- **Git** - 版本控制

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/stardew_valley.git
cd stardew_valley

# 安装 Python 依赖
cd hello_agent_backend
pip install -r requirements.txt
cd ..

# 运行 Godot 项目
godot project.godot
```

### Codespaces 开发（云端）

1. 点击 **"Code"** > **"Codespaces"** > **"Create codespace on main"**
2. 等待环境自动配置（约 2-3 分钟）
3. 开始开发！

**注意：** Godot 图形编辑器建议本地使用，Codespaces 适合：
- ✅ Python 后端开发
- ✅ 文档编写
- ✅ 配置文件管理
- ✅ 代码审查

### 验证安装

```bash
# 验证 Godot
godot --version  # 应显示 4.2.x

# 验证 Python 后端
cd hello_agent_backend
python --version  # 应显示 3.11+
pytest tests/ -v  # 运行测试

# 验证项目结构
test -f "project.godot" && echo "✓ Godot 项目正常"
test -d "environment_system" && echo "✓ 环境系统存在"
test -d "hello_agent_backend" && echo "✓ Python 后端存在"
```

---

## 🌟 项目亮点

### ✨ 核心特色
- **🤖 AI驱动的智能NPC** - 每个NPC都有独特性格、记忆和情感系统
- **📖 动态叙事生成** - AI每天生成新故事，永不重复
- **🌍 多语言支持** - 中英双语首发，文化适配
- **🎮 经典农场玩法** - 种植、养殖、社交、探索
- **🌦️ 智能环境系统** - 季节、天气、物品相互影响的动态生态系统（NEW!）

### 🚀 技术优势
- **高性能架构** - SQLite + 向量数据库 + 多线程AI
- **智能路由** - 本地LLM + 云端AI混合部署
- **插件系统** - 热插拔扩展，MOD友好
- **60 FPS稳定** - 全面性能优化
- **产品级代码质量** - 完整类型注解、单元测试、错误处理、日志系统

---

## 📚 文档导航

### 🎯 快速开始（新玩家必读）
- **[执行摘要](docs/00-执行摘要.md)** ⭐ - 项目概览、技术方案、商业计划一页纸总结
- **[TODO 路线图](docs/01-项目概览/TODO.md)** 🚀 - **当前任务进度与开发计划 (推荐阅读)**（含 **「分阶段迭代顺序」**：先玩法 A1→A4，后 AI B1→B4）
- **[文档索引](docs/README.md)** - 完整文档体系导航
- **[快速参考卡片](docs/08-开发工具/CHEATSHEET.md)** - 日常开发速查表

### 📖 结构化文档（按主题分类）

#### 🌟 项目概览
- [游戏设计文档](docs/01-项目概览/GAME_DESIGN.md) - 游戏的整体设计理念
- [贡献指南](docs/01-项目概览/CONTRIBUTING.md) - 如何参与项目开发

#### 🚀 快速开始指南
- [中文快速开始](docs/02-快速开始/快速开始.md) - 新手入门指南
- [通用快速开始](docs/02-快速开始/QUICK_START.md) - Quick Start Guide
- [NPC 音频系统](docs/02-快速开始/QUICK_START_NPC_AUDIO.md) - NPC Audio Quick Start
- [优化系统](docs/02-快速开始/QUICK_START_OPTIMIZATION.md) - Optimization Quick Start
- [快速参考卡](docs/02-快速开始/快速参考.txt) - 日常开发速查

#### 🏗️ 技术架构
- [后端设置](docs/03-技术架构/BACKEND_SETUP.md) - Backend Setup Guide
- [Godot 集成](docs/03-技术架构/GODOT_INTEGRATION_GUIDE.md) - Godot Integration Guide
- [优化架构](docs/03-技术架构/OPTIMIZATION_ARCHITECTURE.md) - Optimization Architecture
- [性能优化](docs/03-技术架构/OPTIMIZATION_GUIDE.md) - Performance Optimization Guide

#### 🤖 AI 与 NPC 系统
- [高级 AI 系统](docs/04-AI与NPC系统/ADVANCED_AI_SYSTEM.md) - Advanced AI System
- [AI NPC 指南](docs/04-AI与NPC系统/AI_NPC_GUIDE.md) - AI NPC Guide
- [增强 NPC 系统](docs/04-AI与NPC系统/ENHANCED_NPC_SYSTEM.md) - Enhanced NPC System
- [NPC 扩展指南](docs/04-AI与NPC系统/NPC_EXPANSION_GUIDE.md) - NPC Expansion Guide
- [NPC 个性化](docs/04-AI与NPC系统/NPC_PERSONALITY_GUIDE.md) - NPC Personality Guide
- [每日叙事系统](docs/04-AI与NPC系统/DAILY_NARRATIVE_SYSTEM.md) - Daily Narrative System
- [增强叙事系统](docs/04-AI与NPC系统/NARRATIVE_SYSTEM_ENHANCED.md) - Enhanced Narrative System

#### ✅ 实施与交付
- [实施检查清单](docs/05-实施与交付/IMPLEMENTATION_CHECKLIST.md) - Implementation Checklist
- [实施总结](docs/05-实施与交付/IMPLEMENTATION_SUMMARY.md) - Implementation Summary
- [集成完成报告](docs/05-实施与交付/INTEGRATION_COMPLETE.md) - Integration Complete
- [当前状态与计划](docs/05-实施与交付/CURRENT_STATUS_AND_NEXT_STEPS.md) - Current Status & Next Steps
- [后续路线图](docs/05-实施与交付/NEXT_STEPS_ROADMAP.md) - Next Steps Roadmap
- [项目交付总结](docs/05-实施与交付/项目交付总结.md) - Project Delivery Summary

#### 🚀 部署与运维
- [GitHub 推送准备](docs/06-部署与运维/GITHUB_PUSH_READY.md) - GitHub Push Ready
- [GitHub 推送指南](docs/06-部署与运维/PUSH_TO_GITHUB.md) - Push to GitHub Guide
- [自动推送脚本](docs/06-部署与运维/push_to_github.ps1) - PowerShell Auto-push Script

#### 📊 优化与总结
- [优化总结](docs/07-优化与总结/优化总结.md) - Optimization Summary
- [个性化系统总结](docs/07-优化与总结/个性化系统总结.md) - Personalization Summary
- [高级系统总结](docs/07-优化与总结/高级系统总结.md) - Advanced Systems Summary
- [个性化速查卡](docs/07-优化与总结/个性化速查卡.txt) - Personalization Cheatsheet

#### 🛠️ 开发工具
- [AI Agents](docs/08-开发工具/AGENTS.md) - AI Agent Configuration
- [开发者速查表](docs/08-开发工具/CHEATSHEET.md) - Developer Cheatsheet

### 💼 商业运营文档
- **[商业运营方案](docs/02-商业运营/01-商业运营方案.md)** 💰 - 市场分析、定价策略、营销推广、收入预测
- **[研发周期计划](docs/03-研发管理/01-研发周期与里程碑.md)** 📅 - 7个月详细研发时间表和里程碑

---

## ✅ 已实现功能

### Core Systems
- **Player Movement**: WASD movement with directional facing
- **Farming System**: Till soil, plant seeds, water crops, and harvest
- **Crop Growth**: Time-based growth system with daily updates
- **Inventory System**: 36-slot inventory with item stacking
- **Time System**: Day/night cycle with seasonal progression
- **Weather System**: Dynamic weather affecting gameplay
- **NPC System**: Villagers with dialogue and schedules
- **Shop System**: Buy seeds and sell crops

### AI-Powered NPC Features (NEW!)
- **Dynamic Dialogue**: AI-generated responses using LLMs (Ollama/OpenAI)
- **Memory System**: NPCs remember past interactions and reference them
- **Emotion System**: Moods change based on events and affect behavior
- **Personality Profiles**: Unique traits, interests, and speech styles per NPC
- **Relationship Tracking**: NPCs build relationships with players over time

### 🌦️ Environmental System (NEW! - Just Completed!)
- **Season Management** - 4 seasons with unique effects on crops, NPCs, and gameplay
- **Dynamic Weather** - Probabilistic weather system with Markov chain generation
- **Environmental Items** - Interactive objects (fireplace, AC, plants) affecting local environment
- **Seasonal Modifiers** - Items behave differently based on season and weather
- **Automatic Crop Watering** - Rain automatically waters crops
- **Storm Damage Risk** - Severe weather can damage crops and items
- **Visual Transitions** - Smooth sky color and lighting changes
- **Configuration-Driven** - All parameters in external JSON files for easy tweaking

**Implementation Details:**
- ✅ `SeasonManager` - 600+ lines, 18 unit tests
- ✅ `WeatherController` - 700+ lines, 22 unit tests  
- ✅ `EnvironmentItem` - 450+ lines, 13 test suites
- ✅ Example items: Fireplace, AirConditioner, DecorativePlant
- ✅ External configs: `seasons.json`, `weather.json`, item configs

### Game Mechanics
- **Seasons**: Spring, Summer, Fall, Winter (28 days each)
- **Daily Cycle**: Time progresses from 6 AM to 2 AM
- **Crop Watering**: Crops need daily watering (rain counts)
- **Growth Stages**: 4 visual growth stages for crops
- **Harvesting**: Collect crops when fully grown

## Project Structure

```
stardew_valley/
├── autoload/              # Global singleton scripts
│   ├── game_manager.gd    # Game state, time, seasons
│   ├── inventory_manager.gd  # Inventory handling
│   ├── item_database.gd   # Item definitions
│   ├── shop_system.gd     # Shop mechanics
│   ├── weather_system.gd  # Weather effects
│   ├── quest_system.gd    # Quest management
│   ├── achievement_system.gd  # Achievement tracking
│   ├── ai_agent_manager.gd    # AI/LLM integration
│   ├── npc_memory_system.gd   # NPC memory & relationships
│   └── npc_emotion_system.gd  # NPC emotions & personalities
├── scenes/                # Scene files (.tscn)
│   ├── main.tscn          # Main game scene
│   ├── npc_pierre.tscn    # AI-enabled NPC
│   ├── npc_abigail.tscn   # AI-enabled NPC
│   ├── npc_lewis.tscn     # AI-enabled NPC
│   ├── shop_ui.tscn       # Shop interface
│   └── ai_config_ui.tscn  # AI configuration panel
├── scripts/               # GDScript files
│   ├── player.gd          # Player controller
│   ├── farm_manager.gd    # Farming logic
│   ├── npc.gd             # Enhanced NPC with AI
│   ├── day_night_cycle.gd # Visual day/night
│   ├── inventory_ui.gd    # Inventory interface
│   ├── shop_ui.gd         # Shop UI logic
│   ├── game_tilemap.gd    # Tilemap management
│   └── ai_agent_config_ui.gd  # AI settings UI
├── resources/             # Resource definitions
│   ├── item_data.gd       # Item resource class
│   └── crop_data.gd       # Crop resource class
├── assets/                # Game assets
│   ├── sprites/           # Character/item sprites
│   └── tilemaps/          # Tileset images
├── project.godot          # Godot project config
├── README.md              # This file
└── docs/                  # Documentation (organized by topic)
    ├── 01-项目概览/       # Project overview & design
    ├── 02-快速开始/       # Quick start guides
    ├── 03-技术架构/       # Technical architecture
    ├── 04-AI与NPC系统/   # AI & NPC systems
    ├── 05-实施与交付/     # Implementation & delivery
    ├── 06-部署与运维/     # Deployment & operations
    ├── 07-优化与总结/     # Optimization & summaries
    └── 08-开发工具/       # Development tools
```

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move player |
| E | Interact (talk to NPCs, use tools) |
| I | Toggle inventory |
| Left Click | Use selected tool/item |

## Getting Started

### Prerequisites
- Godot Engine 4.2 or later
- Download from [godotengine.org](https://godotengine.org/)

### Running the Game
1. Open Godot Engine
2. Import the project by selecting `project.godot`
3. Click "Run" or press F5

### Adding Assets
The project currently uses placeholder graphics. To add proper assets:

1. Create sprite textures in `assets/sprites/`
2. Create tileset images in `assets/tilemaps/`
3. Update scene files to reference the new textures

## Extending the Game

### Adding New Crops
Edit `scripts/farm_manager.gd`:
```gdscript
crops_db["new_crop"] = {
    "id": "new_crop",
    "name": "New Crop",
    "growth_days": 7,
    "harvest_product": "new_crop_item",
    "harvest_count": 1,
    "regrows": false,
    "seasons": ["spring", "summer"]
}
```

### Adding New Items
Edit `autoload/item_database.gd`:
```gdscript
items["new_item"] = {
    "id": "new_item",
    "name": "New Item",
    "description": "Description here",
    "type": "misc",
    "stack": 1,
    "max_stack": 99,
    "sell_price": 50
}
```

### Adding NPCs

**Basic NPC:**
```gdscript
var npc = NPC.new()
npc.npc_name = "Villager Name"
npc.dialogue_lines = ["Hello!", "Nice day!"]
```

**AI-Enabled NPC:**
```gdscript
var npc = NPC.new()
npc.npc_id = "my_npc"
npc.use_ai_dialogue = true
npc.ai_personality = {
    "traits": ["friendly", "curious"],
    "occupation": "Librarian",
    "backstory": "A quiet librarian.",
    "speech_style": "shy",
    "interests": ["books"]
}
```

See [AI_NPC_GUIDE.md](AI_NPC_GUIDE.md) for full AI setup instructions.

## Planned Features (TODO)

详细的进度跟踪和未来计划，请参阅 [TODO.md](TODO.md)；**当前约定迭代顺序**见其中 **「分阶段迭代顺序（先玩法，后 AI）」** 章节，按 A1→A4、再 B1→B4 逐项勾选。

- [ ] 钓鱼系统与小游戏 (Fishing)
- [ ] 挖矿与战斗系统 (Mining & Combat)
- [ ] 工艺制作与建筑升级 (Crafting & Upgrades)
- [ ] 畜牧与烹饪系统 (Animals & Cooking)
- [ ] 动态 AI 任务与经济系统 (AI Quests & Economy)
- [ ] NPC 语音集成 (TTS)
- [ ] 多人游戏支持 (Multiplayer)

## License

This project is for educational purposes. Stardew Valley is a trademark of ConcernedApe.

## Credits

Inspired by Stardew Valley by ConcernedApe
Built with Godot Engine
