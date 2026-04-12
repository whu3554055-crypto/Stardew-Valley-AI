# TODO 已实现项 — 验收清单（可跳转）

> **对应**：[TODO.md](../../TODO.md) 中所有 `[x]` 条目。  
> **原则**：每条具备「验收要点 + 最小自动化（若有）+ 手动抽检」；与 [TODO.md §开发总纲](../../TODO.md) 第 5 条「清单与实现一致」对齐。

## 一键批处理（BATCH-A）

<a id="acc-batch-a"></a>

在仓库根目录执行：

```powershell
.\tools\run_todo_acceptance.ps1
```

含：关键路径存在性校验 → `run_world_shells_smoke.ps1` → `run_headless_smoke.ps1`（默认主场景若干帧）→ **全量 GUT**（与 [`tools/run_gut.ps1`](../../tools/run_gut.ps1) 相同：`res://tests/unit` + `-ginclude_subdirs`，含 `test_season_manager.gd`、`test_weather_controller.gd` 等）。仅跑冒烟可：

```powershell
.\tools\run_todo_acceptance.ps1 -SkipGut
```

日志：`tools/last_gut_log.txt`（由 `run_gut.ps1` 写入）。更多说明见 [`docs/RUNTIME_VERIFICATION.md`](../RUNTIME_VERIFICATION.md)。

---

## 目录（按 TODO.md 结构）

1. [沉浸与反馈 IMM-01～12](#acc-imm)
2. [核心系统 CORE-01～06](#acc-core)
3. [AI 增强 NPC NPC-01～07](#acc-npc)
4. [环境与生态 ENV-01～05](#acc-env)
5. [性能 Phase1 PERF-01～03](#acc-perf)
6. [玩法扩展 PLAY-01～05](#acc-play)
7. [AI 系统深度增强 AIA-01～09](#acc-aia)（含 AI 任务子项 / B1–B3 对齐项）

---

## 沉浸与反馈

<a id="acc-imm"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-imm-01"></a>**IMM-01** | 商店开门铃 | Pierre 附近打开商店触发 `GatheringSfx.play_shop_bell()` | BATCH-A | 主场景近店开商店听铃/看日志 |
| <a id="acc-imm-02"></a>**IMM-02** | 昼夜×天气画面 | `WorldWeatherVisuals` 叠昼夜；换天气 tween | BATCH-A | 调时间 + 换天气观色 |
| <a id="acc-imm-03"></a>**IMM-03** | 区域环境音轮询 | 移动阈值/0.5s 节流 | BATCH-A | 站立 vs 走动音量重算 |
| <a id="acc-imm-04"></a>**IMM-04** | 室内环境压低 | `GameZones.is_indoor_station` 压低 Ambience | BATCH-A | 进厨房/熔炉/工作台矩形 |
| <a id="acc-imm-05"></a>**IMM-05** | 工具动作压低环境 | 矿/林/鱼成功 → `WorldAmbientController.request_activity_duck` | BATCH-A | 各成功一击听环境暂降 |
| <a id="acc-imm-06"></a>**IMM-06** | 雨雪粒子风向 | 暴雨更斜、雪 gravity/direction | BATCH-A | 切暴雨/雪观粒子 |
| <a id="acc-imm-07"></a>**IMM-07** | 工具失败进简报 | 矿/林/鱼失败 → `record_world_event` | BATCH-A | 故意失败看 World 简报 |
| <a id="acc-imm-08"></a>**IMM-08** | 音频与天气外置 | `data/presentation/immersion_config.json` + `ImmersionConfig` | BATCH-A（含文件存在） | 改 JSON 看是否生效 |
| <a id="acc-imm-09"></a>**IMM-09** | 钓鱼区统一入口 | `GameZones.get_fish_zone_id`；`FishingSystem.get_fish_zone` 委托 | BATCH-A | 河/海钓鱼区 HUD 一致 |
| <a id="acc-imm-10"></a>**IMM-10** | 工作站/矿区/升级区收口 | `immersion_config.json` zones；`GameZones` 矩形 API | BATCH-A | U/H 区与矿林提示 |
| <a id="acc-imm-11"></a>**IMM-11** | UI 与天气 | HUD 季节 accent × `ui_weather_accent_mult` | BATCH-A | 换季+换天气看 UI 色调 |
| <a id="acc-imm-12"></a>**IMM-12** | Ambience LowPass | 降水时 `ImmersionConfig.apply_ambience_lowpass_for_precipitation` | BATCH-A | 雨雪听低通滤波 |

---

## 核心系统

<a id="acc-core"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-core-01"></a>**CORE-01** | 角色控制 | WASD 移动与朝向 | BATCH-A | 主场景走动 |
| <a id="acc-core-02"></a>**CORE-02** | 农场系统 | 犁地/播/浇/收 | BATCH-A | 农场场景完整种一茬 |
| <a id="acc-core-03"></a>**CORE-03** | 作物生长 | 按天阶段推进 | BATCH-A | 睡过数天看阶段 |
| <a id="acc-core-04"></a>**CORE-04** | 背包 | 36 格、堆叠 | BATCH-A | 打开背包堆叠物品 |
| <a id="acc-core-05"></a>**CORE-05** | 时间 | 6:00–2:00、季节 | BATCH-A | 看时钟与换季 |
| <a id="acc-core-06"></a>**CORE-06** | 商店 | 买种卖作物 | BATCH-A | 买卖一笔 |

---

## AI 增强 NPC

<a id="acc-npc"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-npc-01"></a>**NPC-01** | 动态对话 | LLM/Ollama 路径可请求 | BATCH-A | 与 AI NPC 对话 |
| <a id="acc-npc-02"></a>**NPC-02** | 记忆 | 交互写入并可召回 | BATCH-A | 同 NPC 多轮引用前文 |
| <a id="acc-npc-03"></a>**NPC-03** | 情感 | 事件改情绪并影响行为 | BATCH-A | 送礼/粗鲁后情绪变化 |
| <a id="acc-npc-04"></a>**NPC-04** | 个性画像 | traits/职业/风格 | BATCH-A | 检 `EnhancedPersonalitySystem` 数据 |
| <a id="acc-npc-05"></a>**NPC-05** | 关系 | 好感追踪 | BATCH-A | 对话/送礼看关系 |
| <a id="acc-npc-06"></a>**NPC-06** | 高级 AI 管理器 | 异步 + LRU | BATCH-A | 快速连点对话不卡死 |
| <a id="acc-npc-07"></a>**NPC-07** | NPC 行为控制 | 日程/社交检查 | BATCH-A | 日志见 `NPCBehaviorController`；日程 JSON |

---

## 环境与生态

<a id="acc-env"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-env-01"></a>**ENV-01** | 季节管理 | 四季循环影响作物/NPC | BATCH-A + GUT [`test_season_manager.gd`](../../tests/unit/test_season_manager.gd) | 换季 + 作物表 |
| <a id="acc-env-02"></a>**ENV-02** | 动态天气 | 马尔可夫链 / `WeatherController` | BATCH-A + GUT [`test_weather_controller.gd`](../../tests/unit/test_weather_controller.gd) | `WeatherSystem` / 天气壳切天气 |
| <a id="acc-env-03"></a>**ENV-03** | 环境物品 | 壁炉/空调/植物局部影响 | BATCH-A | 靠近壁炉/空调看局部效果；脚本自测见 [`test_environment_item.gd`](../../tests/unit/test_environment_item.gd)（非 GutTest，默认不纳入 GUT 批跑） |
| <a id="acc-env-04"></a>**ENV-04** | 自动浇水 | 雨天浇灌农田 | BATCH-A | 雨天看地块湿润 |
| <a id="acc-env-05"></a>**ENV-05** | 视觉效果 | 灯光/天空随时间天气 | BATCH-A | 昼夜+天气组合 |

---

## 性能优化（Phase 1）

<a id="acc-perf"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-perf-01"></a>**PERF-01** | 异步叙事 | 长叙事不阻塞主线程 UI | BATCH-A | 触发日叙事时可操作 |
| <a id="acc-perf-02"></a>**PERF-02** | NPC 节流 | 闲置降频 | BATCH-A | 多 NPC 场景 profiler |
| <a id="acc-perf-03"></a>**PERF-03** | LRU 缓存 | AI 回复缓存命中 | BATCH-A | 重复问句延迟下降 |

---

## 玩法扩展（黄区 MVP）

<a id="acc-play"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-play-01"></a>**PLAY-01** | 钓鱼 | `FishingSystem`、分区、咬钩窗口 | BATCH-A + `world_beach` 壳 | 装备竿在河/海钓鱼 |
| <a id="acc-play-02"></a>**PLAY-02** | 挖矿与战斗 | `MiningSystem`、`MineCombatController` | BATCH-A + `world_mine` 壳 | 主场景矿带 + 矿壳战斗 |
| <a id="acc-play-03"></a>**PLAY-03** | 建筑升级 | `data/buildings/upgrades.json`、**H**、`house_level` | BATCH-A（文件存在） | 房屋区升级看体力上限 |
| <a id="acc-play-04"></a>**PLAY-04** | 烹饪 | `CookingSystem` + `data/recipes/cooking.json` | BATCH-A | 厨房做一道菜 |
| <a id="acc-play-05"></a>**PLAY-05** | 工艺 | `CraftingSystem` + `data/recipes/crafting.json` | BATCH-A | 工作台做鱼饵 |

---

## AI 系统深度增强

<a id="acc-aia"></a>

| ID | 条目 | 验收要点 | 自动化 | 手动抽检 |
|----|------|----------|--------|----------|
| <a id="acc-aia-01"></a>**AIA-01** | AI 经济 | `AIEconomySystem` + `ShopSystem.on_shop_trade`、市价标签、换日简报 | BATCH-A | 买卖后看价签与简报 |
| <a id="acc-aia-02"></a>**AIA-02** | AI 任务（总） | 生成、入 `QuestSystem`、完成反馈；奖励与任务面板 `reward.items` 与 AI `rewards` 对齐 | BATCH-A（headless 日志可见分配） | 任务面板看 AI 任务与物品奖励预览 |
| <a id="acc-aia-03"></a>**AIA-03** | 任务·异步框架 | 模板与分配 | BATCH-A | 同上 |
| <a id="acc-aia-04"></a>**AIA-04** | 任务·LLM 增强 | `AIAgentManager.request_text_generation` 链路 | BATCH-A | 关网看降级文案 |
| <a id="acc-aia-05"></a>**AIA-05** | 任务·目标验证 | `verify_active_objectives` | GUT [`test_ai_quest_objective_verify.gd`](../../tests/unit/test_ai_quest_objective_verify.gd) + [`test_ai_quest_system.gd`](../../tests/unit/test_ai_quest_system.gd) | 交付类对话后完成 |
| <a id="acc-aia-06"></a>**AIA-06** | 社交动力学 | `register_npc` → `auto_load_plugins_for_npc`；换日「镇上闲语」 | BATCH-A（插件初始化日志） | 睡到下一天多次看简报 |
| <a id="acc-aia-07"></a>**AIA-07** | B1 · AI 任务奖励落地 | `grant_quest_rewards` → `player_data.gold`、`GameManager` 的 `npc_friendship` / `skill_xp`、背包物品（`item` / `items` / `friendship_both`） | GUT [`test_ai_quest_reward_grant.gd`](../../tests/unit/test_ai_quest_reward_grant.gd) | 完成一条含多类奖励的 AI 任务看数值与背包 |
| <a id="acc-aia-08"></a>**AIA-08** | B3 · 当日叙事可见化 | 日记 **今日** 页读 `daily_narrative_snapshot`；主场景 `StoryHotspotHud` 热点行（`UITextCatalog` `journal.hotspot_hud_line`） | BATCH-A（字符串表存在） | 换日后开日记「今日」；有热点时看右上提示 |
| <a id="acc-aia-09"></a>**AIA-09** | B2 · 任务↔经济闭环 | `AIEconomySystem.on_quest_completed` 统一 `reward`/`rewards`、奖励物品与多类 `objectives`（钓鱼/挖矿/交付等）写入当日压力；商店买卖 `on_shop_trade`；换日 `on_day_passed` 简报；AI 任务完成可触发即时市场提示 | GUT [`test_ai_economy_quest_and_trade.gd`](../../tests/unit/test_ai_economy_quest_and_trade.gd) | 完成任务后睡到下一天看 `WorldEventFeed` 市场行；商店买卖看价签变化 |

### 关联单测（命令行）

BATCH-A 与单独跑单元测试均可用：

```powershell
.\tools\run_gut.ps1
```

定向单个脚本（调试）：

```powershell
$env:GODOT_CONSOLE = "D:\path\to\Godot_*_console.exe"
& $env:GODOT_CONSOLE --headless --path . -s res://addons/gut/gut_cmdln.gd -- -gconfig= -gtest=res://tests/unit/test_ai_quest_objective_verify.gd -gexit
```

托管链 / 任务链：[`test_managed_chain_system.gd`](../../tests/unit/test_managed_chain_system.gd)、[`test_quest_system.gd`](../../tests/unit/test_quest_system.gd)。季节 / 天气：`test_season_manager.gd`、`test_weather_controller.gd`（已纳入 BATCH-A 全量 GUT）。

---

## 维护说明

- 在 [TODO.md](../../TODO.md) 新增或取消 `[x]` 时，**同步**本文件对应行（或整段删除/改为 `[ ]` 指引）。  
- 为某条增加专属自动化时：在「自动化」列写脚本或 `res://tests/...` 路径；`run_todo_acceptance.ps1` 的 GUT 步已对齐 **全量** `tests/unit`（`extends GutTest`），非 GUT 脚本（如仅 `extends Node` 的自跑测）须注明排除原因或另挂入口。  
- **版本**：随仓库迭代更新；引擎版本以 `project.godot` 为准。
