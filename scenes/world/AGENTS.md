# `scenes/world/` — Agent 提示

- 新增/改名 **世界场景**（`world_*.tscn`）时：更新同目录 **`README.md`** 场景清单表（路径、用途、spawn、状态）。
- 传送：**`WorldPortalArea`**（`target_scene` + `target_spawn_id`）；目标场景需有对应 **`WorldSpawnPoint`**。
- 子场景根脚本：加载后调用 **`WorldRouter.apply_pending_spawn_and_clear()`**（参考 `world_playground_root.gd`）；`Main` 的引导流程见 `ARCHITECTURE.md`。
- 架构决策：**`ARCHITECTURE.md`**（每场景独立玩家、存档 `world` 字段等）。
- **薄壳环**（`world_*_stub.tscn`）：只验证传送/存档串联；迁出实体场景见 **`MIGRATION.md`**。
