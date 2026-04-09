# 项目路线图与 TODO 列表 (Project Roadmap & TODO)

本项目是一个基于 AI 驱动的星露谷物语克隆版，旨在实现具有深度个性化 NPC、动态叙事和智能环境系统的农场模拟游戏。

## 🎯 开发总纲（Execution Principle）

1. **先让游戏可玩（Playable First）**  
   每个阶段先保证主循环可跑通：进入游戏 → 交互 → 获得反馈 → 可持续进行。

2. **再让游戏好玩（Fun Second）**  
   在“可玩”稳定后，再增强沉浸感、策略深度、叙事张力与 AI 个性化体验。

3. **功能先闭环，再打磨完美（Closed Loop Before Perfect）**  
   每个功能点优先做最小可用闭环（MVP），允许先用回退策略/简化实现；后续迭代优化质量与表现。

4. **防遗漏优先于一次做完（No-Loss Priority）**  
   当下不做完的点必须记录到“实施中发现（防遗漏）”，确保后续可追踪、可排期。

5. **玩家可见后果（反暗箱，长期遵守）**  
   - 任何会改变玩家**可感知**状态（经济、社交、任务进度、NPC 情绪与记忆、叙事/Agentic 运行时等）的逻辑，**必须**有对应的玩家可见反馈；禁止只改后台数值却零提示。  
   - **同一因果事件，最多两条信息**：一条说明「发生了什么」，一条说明「对你意味着什么」（物品名、金币、NPC、涨跌方向等）。  
   - **用游戏内语言呈现**；内部 `reason`/错误码/调试串需映射为简短玩家文案，不直接糊进 UI。  
   - **高频系统必须节流**：模拟 tick、定时刷新类逻辑，仅在**显著变化**或**玩家行为触发后**推送；避免刷屏。  
   - **统一出口优先**：同类反馈优先走 `WorldEventFeed` + `QuickTip`（或后续专用面板），保持风格与节流策略一致。

---

## 🎧 沉浸与反馈迭代（按性价比排序，做完勾一项）

> 以下为「体感明显、改动集中」的连续优化；与 `WorldAmbientController`、`WorldWeatherVisuals`、`GameZones`、`GatheringSfx` 等相关。

- [x] **商店开门铃**：在 Pierre 附近成功打开商店时播放 `shop_bell`（`GatheringSfx.play_shop_bell()`）。  
- [x] **昼夜×天气画面**：`WorldWeatherVisuals` 在天气色调上叠加昼夜时间（`GameManager.time_changed` 即时刷新；换天气仍 tween）。  
- [x] **区域环境音轮询**：移动超过约 48px 或每 0.5s 才重算区域，减少站立不动时的开销。  
- [x] **室内环境压低**：站在厨房/熔炉/工作台矩形（`GameZones.is_indoor_station`）时压低区域与天气层音量。  
- [x] **工具动作短暂压低环境**：挖矿成功 / 砍树成功 / 咬钩提示 / 钓鱼成功时 `WorldAmbientController.request_activity_duck(…)`。  
- [x] **雨雪粒子风向**：暴雨更斜、更强侧风；雪略调 `gravity`/`direction`。  
- [x] **工具失败进简报**：矿/林/鱼失败时 `record_world_event` 一行（与对话一致）。  
- [ ] **音频与天气常量外置**：`PATH_*`、色调、`dB` 偏移收到单份 JSON / Resource，便于策划调参。  
- [ ] **区域检测统一入口**：钓鱼/砍树/农场/商店等矩形逐步收敛到 `GameZones` + 少量专用 API，避免改一处漏一处。  
- [ ] **UI 与天气**：面板/边框在现有季节 accent 下，可按天气只做轻量 `modulate` 或透明度（不动布局）。  
- [ ] **Ambience 总线效果（可选）**：雨天为 Ambience 加轻量低通或音量曲线（需 `AudioEffect` 与资源）。  

---

## 📋 分阶段迭代顺序（约定：先玩法，后 AI）

> 与下方「进行中」列表互补：这里按**推荐完成顺序**排列，做完一项勾一项；AI 段在玩法阶段未收尾前默认不插队（紧急 Bug 除外）。

### 阶段 A — 玩法（优先）

> **托管迭代**：每轮按 `docs/MANAGED_ITERATION_CHECKLIST.md` 执行 **A1 / A2 / A3 各一项**（单线最多细化 2 次），并更新本文件进度一句。

- [ ] **A1 — 单系统加深（第一轮）**  
  在钓鱼 / 挖矿 / 烹饪 / 农场扩展中**选定一条**已有入口的系统，做一轮闭环：**更多内容或规则 + 数值 + 失败/成功提示与反馈**（比开新系统优先）。  
  *进度：已加深钓鱼 / 挖矿 / 烹饪各一轮；农场：夏季玉米、季节播种、`crop_id`、基础肥料；新增 **Farm Tier 配置**（`data/farm/tiers.json`）与升级（U），并支持可配置收获加成（`harvest_bonus_chance` / `harvest_bonus_max`）；作物库迁移到 `data/farm/crops.json`，新增秋季作物 **pumpkin** 与 `roasted_pumpkin`；商店库存迁移到 `data/shop/stock.json`，种子按季节上架。钓鱼：**狗鱼（河，夜/冬/暴雨偏重）**、**比目鱼（海，秋冬与清晨偏重）**、暴风雨微调；新烤制 `grilled_pike` / `grilled_halibut`。伐木：**树液**随机掉落（约 12%）、装备斧头时活动区 HUD「伐木 · 森林」。烹饪：**树液闭环** — `sap_glazed_toast`（面包+树液）、`sap_glazed_catfish`（鲶鱼+树液）；托管迭代本轮 **`hearty_pumpkin_bowl`**（南瓜+土豆+面包）。挖矿：**深脉** 稀有掉落 `amethyst_shard`（铁镐权重略加成）；煤/铜/铁/石 成功文案区分；熔炉新增 `amethyst_glass`（2 碎块 + 1 煤）。*

- [ ] **A2 — 单系统加深（第二轮）**  
  换另一条系统重复 A1 的标准，避免长期只堆一条线。  
  *进度：钓鱼新增鲶鱼/鲭鱼与表修正；新增鱼饵分级（`premium_bait` 优先消耗，显著提升鱼类权重），并开放商店购买与工作台制作；咬钩窗口内区分 **过早按 E** / **超时** 提示；挖矿矿层前缀、主题权重、表层 geode；**银矿 / 银锭**（深脉 + 铁镐、熔炉 5 矿+1 煤）；烹饪四条三料复合食谱。*

- [ ] **A3 — 呈现与资源**  
  补齐或替换占位：**TileMap tileset、玩家/作物/工具相关美术**，让玩法反馈「看得见」（可与 A1/A2 并行，由人力安排）。  
  *进度：`GameTileMap` + `terrain_atlas_32.png`；玩家/NPC 精灵 **NEAREST**；作物 **NEAREST**；背包格 + **体力条填色**（填色随 **季节 accent**）；**对话/图鉴/配方/简报/商店** 面板与字阴影；**HUD 半透明底**、**AI Config** 按钮描边（边框随季节色）；**海洋区域**示意；**对话 Label 铺满**；**WorldEventFeed 标题** 阴影 + **标题字色**随季节；**WorldEventFeed** 面板边框随 **季节色**（与 HUDBackdrop / QuestLog / ActivityZone 一致）；**背包 / 图鉴 / 配方选择器 / 对话** 面板边框与 **季节色** 同步；**商店** 全屏 **SeasonBorder** 边框与季节色同步；**QuickTip** 条 **QuickTipBackdrop** 底板与边框随季节色（随提示显隐）；**任务列表**字色随季节；**商店** 商品行 / **关闭** 按钮边框随 **季节 accent**（`apply_seasonal_accent`）；NPC **头顶名字** 阴影；**配方选择器** 外框 + **制作/关闭** 按钮 + 列表 **选中/悬停** 字色随季节（`set_seasonal_accent`）；**图鉴 (J)** 外框 + 标题字色 + 四列表 **选中/悬停** 随季节；**背包** 格子 **非选中** 边框与季节 accent 混合（选中格仍金色描边）；**AI 配置界面** 输入框/按钮统一；**银矿/银锭** 32px 占位 PNG（`tools/gen_silver_placeholders.py`）+ `resolve_icon` 走资源路径；新增地图内 **Farm/House Upgrade Zone** 可视引导（U/H）；并统一世界区域提示（矿/林/河/海/升级区）文字阴影与视觉强度；新增 **QuestLog/ActivityZone** 独立底板增强可读性。存档仅 `game_save.bundle`。*

- [ ] **A4 — 长线玩法 MVP（按需排期）**  
  从下列中选做最小可用版本（不必一次全做）：**建筑升级** / **畜牧** / **洞穴与战斗**（若目标超出当前「矿区条带式」挖矿）。
  *进度：建筑升级 MVP（房屋）已落地：`data/buildings/upgrades.json` 配置升级成本与收益；地图内房屋区域按 **H** 升级；`player_data.house_level` 持久化并驱动 `stamina_max` / `stamina_regen_mult`。新增 **Lv3 Family House**（上限与恢复倍率进一步提升）。*

### 阶段 B — AI（玩法阶段目标达成后再做）

> **范式节奏（与 AI/Agentic 大纲对齐）**：每季度至少完成 **一项** 与 `docs/03-研发管理/04-AI与Agentic开发指导大纲.md` **§6 下一步计划** 可对应的工作（例如：确定性字段清单、一条端到端校验链路、客户端 LLM 入口划界、或 B1–B3 中一项可验收闭环），并在该大纲 **§7 阶段性反思清单** 或团队记录中简要留痕。

- [ ] **B1 — AI 任务落地**  
  补全动态任务奖励与状态：**好感 / 技能经验 / 物品** 等到 `GameManager` 或现有系统；**任务完成条件**与玩家背包、对话记录等一致可验（含后端 `verify` 路径时保证上报字段对齐）。
  *进度：客户端 `AIQuestSystem` 的 AI 增强链路已从占位改为真实调用统一入口 `AIAgentManager.request_text_generation()`，并加入 JSON 校验与失败降级；新增 `_normalize_ai_quest_payload()` 做字段收口（长度裁剪、默认值、显式目标字段）并统一 `objective_type`（`fetch_item` / `deliver_to_npc` / `solve_problem` / `talk_to_npc`）；任务描述会自动追加 `Completion:` 行提示，和实际验证规则对齐；最小目标验证已覆盖 `fetch` / `delivery`（含 `target_npc` 时需与目标 NPC 对话后交付）并扩展 `problem_solving`（与任务发起 NPC 对话后可完成）；奖励写回统一到 `player_data.gold`（修正 `money` 漂移），并补 AI 任务桥接 `QuestSystem.add_quest_from_ai()` 以保持任务 UI/事件一致；AI 任务完成会向 `WorldEventFeed` 写结构化反馈（完成项/金币/市场脉冲）。*

- [ ] **B2 — AI 经济闭环**  
  **任务完成 / 出售行为 / 天气等** → 写入经济状态 → **次日（或刷新点）商店买卖价可见变化**（先简单公式 + 一句 UI 说明即可）。
  *进度：已接入最小交易反馈环：玩家在商店买入/卖出会即时写入 `AIEconomySystem.on_shop_trade()`，对供需做轻量脉冲（买入偏涨、卖出偏跌），并直接影响 `get_shop_buy_price/get_shop_sell_price`；商店列表已显示 `get_market_brief()` 标签（如 `↑+12%`/`↓-8%`）作为价格变化可见说明；每日换日会将 `get_daily_shop_brief()` 写入 `WorldEventFeed`，且买/卖后追加单条 `Market shift` 反馈。*

- [ ] **B3 — 每日叙事可见化**  
  除生成与任务外，增加**当日摘要 UI**，可选 **地图热点 / 弹窗**，让玩家每天「看见」叙事结果。
  *进度：`DailyNarrativeSystem` 的后端日叙事请求已改为统一入口 `AIAgentManager.request_text_generation(use_backend)`，与 AI 任务链路一致，减少分散 HTTP 客户端实现；`main.gd` 已接 `DailyNarrativeSystem.narrative_generated`，将当日标题/来源/摘要写入 `WorldEventFeed`，并在叙事任务落地时附带 `narrative_id/narrative_day_key` 索引；`QuestLog` 对日叙事任务显示 `[Story <day_key>]` 标签；`QuestSystem.add_story_daily_quest()` 已加同日同源强去重（按 `narrative_day_key` 刷新而非重复新增）并限制活跃叙事任务数。*

- [ ] **B4 — AI 增强（后排）**  
  **NPC↔NPC 社交**、**真实 TTS 与语音队列** 等，见本文「实施中发现（防遗漏）」中的 TTS/社交条目；在 B1–B3 稳定后再展开。

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
- [x] **AI 任务系统 (AI Quest System)**: 基于 NPC 当前需求动态生成任务。
  - [x] 基础异步任务生成框架
  - [x] LLM 创意增强接口 (LLM-enhanced quest details)
  - [ ] 任务目标自动验证逻辑 (Objective verification)
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

## 📝 实施中发现（防遗漏）

> 规则：开发过程中发现“本轮不做，但必须记住”的点，统一追加到这里（不要只留在聊天记录里）。

### 记录模板
- [ ] **功能点名称**  
  - 来源：在哪个任务/文件发现  
  - 原因：为什么本轮未做  
  - 建议：下次实现的最小切入点  

### 当前已记录
- [ ] **真实 TTS Provider 接入（替换 text-only / sfx 回退）**  
  - 来源：`autoload/npc_audio_manager.gd` 与 `hello_agent_backend/app/api/routes.py`  
  - 原因：本轮先做 MVP 回退策略，保证稳定不阻塞  
  - 建议：先接 1 个 Provider（Edge/ElevenLabs 等），保留失败回退

- [ ] **关系事件驱动的双向 NPC 社交传播（NPC↔NPC）**  
  - 来源：`hello_agent_backend/app/services/social_manager.py`  
  - 原因：本轮聚焦玩家↔NPC 主链路  
  - 建议：新增 NPC-NPC 关系图谱与事件广播，驱动群体流言/合作

- [ ] **每日叙事事件对前端可视化触发器（地图热点/弹窗）**  
  - 来源：`hello_agent_backend/app/services/daily_narrative_manager.py`  
  - 原因：本轮已完成生成与缓存，前端演出未全量接入  
  - 建议：在 Godot 增加事件消费器，按地点触发

- [ ] **链式任务奖励与经济系统联动（价格波动）**  
  - 来源：`hello_agent_backend/app/services/quest_manager.py`  
  - 原因：本轮仅完成任务链与奖励倍率，未接 AI 经济闭环  
  - 建议：将任务完成结果写入 AI 经济输入，按日刷新物价

- [ ] **后端 TTS 音频流真实播放（非 mock/text-only）**  
  - 来源：`autoload/npc_audio_manager.gd`、`hello_agent_backend/app/api/routes.py`  
  - 原因：当前已接“异步请求 + 回退”，但真实音频文件/流未接入  
  - 建议：实现 provider 产出音频文件 URL，并在 Godot 侧拉流播放

- [ ] **TTS 并发队列与打断策略（避免语音重叠）**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前为单请求上下文，连续多句会竞争同一请求状态  
  - 建议：为每个 NPC 增加 speak queue 与优先级中断规则

- [ ] **TTS 请求硬取消能力（真正抢断网络请求）**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前已支持“逻辑抢断”，但 `HTTPRequest` 本身无法直接硬取消在途请求  
  - 建议：改为每请求独立客户端或可取消 HTTP 实现，确保高优先级语音即时生效

- [ ] **TTS 并发上限自适应（按设备性能动态调整）**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前 `TTS_MAX_PARALLEL_NPC` 为固定值，低配设备可能过载  
  - 建议：结合帧率/CPU 监控动态调整并发通道数量

- [ ] **TTS 通道持久化与重连恢复**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前通道是运行时内存态，游戏重启/后端重连后不会恢复未完成语音上下文  
  - 建议：持久化关键队列元信息，并在重连后按优先级恢复

- [ ] **TTS 请求级可观测性面板（成功率/超时/重建次数）**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前已有自愈逻辑，但缺少可视化指标来判断是否频繁触发重建  
  - 建议：接入性能监控面板并统计每 NPC 的请求成功率与超时次数

- [ ] **TTS 指标持久化与会话对比（重启后可追溯）**  
  - 来源：`autoload/npc_audio_manager.gd`  
  - 原因：当前指标为运行时内存态，重启后会清空  
  - 建议：按日保存指标快照，支持版本/会话间对比

---

> **注意**: 每次完成一小项功能，请务必提交一次 Git 记录。
