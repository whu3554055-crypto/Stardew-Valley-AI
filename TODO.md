# 项目路线图与 TODO 列表 (Project Roadmap & TODO)

本项目是一个基于 AI 驱动的星露谷物语克隆版，旨在实现具有深度个性化 NPC、动态叙事和智能环境系统的农场模拟游戏。

---

## 🟢 已完成项 (Implemented)

### 核心系统 (Core Systems)
- [x] **角色控制 (Player Controller)**: WASD 移动，朝向处理。
- [x] **农场系统 (Farming System)**: 耕种、播种、浇水、收获。
- [x] **作物生长 (Crop Growth)**: 基于时间的生长阶段，每日更新。
- [x] **背包系统 (Inventory System)**: 36 格背包，物品堆叠。
- [x] **时间系统 (Time System)**: 昼夜循环 (6 AM - 2 AM)，季节进度。
- [x] **商店系统 (Shop System)**: 购买种子，出售作物。

### AI 增强 NPC (AI-Powered NPCs)
- [x] **动态对话 (Dynamic Dialogue)**: 集成 Ollama/OpenAI 生成 NPC 对话。
- [x] **记忆系统 (Memory System)**: NPC 记录并引用过去的交互。
- [x] **情感系统 (Emotion System)**: 情绪随事件变化并影响行为。
- [x] **个性画像 (Personality Profiles)**: 独特的特质、职业、背景和说话风格。
- [x] **关系追踪 (Relationship Tracking)**: 追踪玩家与 NPC 的好感度。
- [x] **高级 AI 管理器 (Advanced AI Manager)**: 异步对话请求，LRU 缓存。
- [x] **NPC 行为控制 (NPC Behavior Controller)**: 基础日程安排与社交检查。

### 环境与生态 (Environment & Ecology)
- [x] **季节管理 (Season Management)**: 四季循环，对作物、NPC 的影响。
- [x] **动态天气 (Dynamic Weather)**: 基于马尔可夫链的天气生成（晴、雨、风、暴雨）。
- [x] **环境物品 (Environmental Items)**: 壁炉、空调、装饰植物等对局部环境的影响。
- [x] **自动浇水 (Auto-watering)**: 下雨天自动浇灌所有农田。
- [x] **视觉效果 (Visuals)**: 随时间、天气变化的灯光与天空颜色。

### 性能优化 (Performance Optimizations - Phase 1)
- [x] **异步叙事生成**: 避免生成长篇故事时界面卡顿。
- [x] **NPC 更新节流 (Throttling)**: 降低闲置 NPC 的 CPU 消耗。
- [x] **LRU 缓存**: 为 AI 回复提供高效缓存管理。

---

## 🟡 进行中 / 期望项 (In Progress & Desired Features)

### 核心玩法扩展 (Gameplay Expansion)
- [ ] **钓鱼系统 (Fishing System)**: 包含小游戏机制。
- [ ] **挖矿与战斗 (Mining & Combat)**: 洞穴系统、怪物、生命值与武器。
- [ ] **建筑升级 (Building Upgrades)**: 扩建房屋，建造谷仓等。
- [ ] **畜牧系统 (Animal Husbandry)**: 养鸡、养牛、产奶与产蛋。
- [ ] **烹饪系统 (Cooking System)**: 食谱学习与体力恢复。
- [ ] **工艺制作 (Crafting)**: 制作洒水器、栅栏、加工机等。

### AI 系统深度增强 (Advanced AI Enhancements)
- [ ] **AI 经济系统 (AI Economy)**: 根据 AI 预测动态调整物价。
- [ ] **AI 任务系统 (AI Quest System)**: 基于 NPC 当前需求动态生成任务。
- [ ] **社交动力学插件 (Social Dynamics)**: NPC 之间的复杂互动（争吵、合作、流言）。
- [ ] **语音集成 (NPC Audio/TTS)**: 为 NPC 对话集成文本转语音。

### 性能与架构 (Optimization Phase 2 & 3)
- [ ] **空间分区 (Spatial Partitioning)**: 优化大量 NPC 时的社交检测。
- [ ] **瓦片地图分块剔除 (Tilemap Culling)**: 仅渲染可见区域，优化超大地图。
- [ ] **NPC 延迟加载 (Lazy Loading)**: 仅在需要时加载 NPC 的详细 AI 数据。
- [ ] **对话流式传输 (Dialogue Streaming)**: 打字机效果配合流式 AI 输出。
- [ ] **自适应画质调节**: 根据硬件性能调整 NPC 活跃数量和视觉特效。

---

## 🔴 待办项 (TODO - Backlog)

### 技术债务与规范
- [ ] **单元测试覆盖**: 提高核心逻辑的测试覆盖率。
- [ ] **多语言文化适配**: 完善中英双语的提示词工程。
- [ ] **移动端支持**: 适配触摸控制。

### 长期目标
- [ ] **多玩家支持 (Multiplayer)**: 合作经营农场。
- [ ] **创意工坊 (Mod Support)**: 允许用户添加自定义 NPC 插件。

---

> **注意**: 每次完成一小项功能，请务必提交一次 Git 记录。
