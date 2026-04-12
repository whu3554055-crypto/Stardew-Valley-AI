# NPC 数据（占位）

## `dialogue_pools.json`（E2）

- **用途**：可重复闲聊 `lines[]` + 单条 `quest_line`（进行中任务相关 NPC 时约 35% 替换）。
- **运行时**：Autoload `NpcDialogueCatalog` 加载；`NPC.get_static_dialogue()` 优先池化文案，再回落 `dialogue_lines`。

## `simple_schedules.json`（E1）

- **用途**：2–3 名 NPC 的**时间段 + 锚点 + 行为说明**，与游戏内钟点对齐。
- **字段**：`blocks[]` 内 `start_hour` / `end_hour` 为 24h 制；`anchor` 为逻辑点名（非场景路径）；`note` 为简短中文说明；`policy` 说明推荐策略。
- **运行时**：Autoload **`NpcSimpleScheduleCatalog`** 加载本文件。
  - **`NPC`（`npc.gd`）**：`build_context()` 注入 `schedule_hint`，`AIAgentManager.build_npc_prompt` 写入「Planned routine」供对话参考。
  - **`AdvancedNPC`**：`daily_schedule` 为空时，用 `to_advanced_ai_schedule(npc_id)` 合并进 `AdvancedAIAgentManager` 的日程键值格式。

## 好感 / 关系存档（E3）

- **运行时**：`NPCTraitSystem` 内 `npc_traits[...][relationships][other_id]`（`points` / `level` / `status` / `history` 等）。
- **主存档**：`GameSaveService.build_runtime_bundle()` 写入 **`npc_traits`**；读档时 `main.gd` → `NPCTraitSystem.load_snapshot()`。与 `NPCMemorySystem` 的 `user://npc_memories.json`（独立文件）并存，职责不同。
