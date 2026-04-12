# 多场景架构决策（现阶段）

## 玩家实体策略

**当前阶段（Phase 1）**：**每个场景各自实例化玩家**（`CharacterBody2D` + 子节点），通过 `WorldRouter.change_scene_to_file()` 切换场景时，由新场景提供玩家节点。

- **优点**：与 Godot 默认 `change_scene` 流程一致，无需在切换时迁移节点树。
- **代价**：各世界场景需包含玩家根或实例化同一 `PackedScene`（后续可抽 `player_avatar.tscn` 统一）。

**暂不采用**：跨场景持久单例玩家节点（迁移到 `get_tree().root` 等）——复杂度更高，留待大地图稳定后再评估。

## 出生点

- 使用 `WorldSpawnPoint`（`Marker2D` + 组 `world_spawn` + `spawn_id`）。
- 场景加载后由 `WorldRouter.apply_pending_spawn()` 将 `group("player")` 的节点对齐到目标点。

## 存档中的世界字段

- Bundle 内 `world: { "path": string, "spawn_id": string }` 描述上次退出时的场景与出生点。
- **注意**：当前 HMAC 签名载荷未纳入 `world`（避免破坏旧档校验）；后续版本可经 `SAVE_BUNDLE_VERSION` 迁移后纳入。

## 切换流程（摘要）

1. 游戏加载存档 → `WorldRouter.set_world_state_from_bundle(world)`。
2. `Main` 完成角色档案引导后 → `call_deferred` → `WorldRouter.consume_saved_world_after_boot()`。
3. 若 `path` 与当前场景一致 → 仅应用出生点；否则 `change_scene_to_file`。
4. 新场景 `_ready` 末尾调用 `WorldRouter.apply_pending_spawn(player)`。
