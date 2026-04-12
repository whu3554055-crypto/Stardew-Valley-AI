# 世界场景清单（活文档）

> 与 `docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md` 配套；新增/改名场景时请更新本表。

| 场景资源路径 | 用途 | 邻接/入口（spawn_id） | 状态 |
|--------------|------|------------------------|------|
| `res://scenes/main.tscn` | 现行主场景（农场+镇区+林+海+矿等逻辑区聚合） | `default`（推荐主出生点）；其它出生点见场景内 `WorldSpawnPoint` | ✅ 当前默认 |
| `res://scenes/world/world_playground.tscn` | 多场景切换冒烟 + **双 TileMapLayer**（地面/装饰）试点 | `default` ↔ `main` 的 `PortalToPlayground` / `playground_return` | ✅ 冒烟 |

## spawn_id 约定

- 全项目唯一字符串，如 `default`、`town_gate`、`beach`、`mine_entrance`。
- 场景中用 `WorldSpawnPoint`（组 `world_spawn`）注册；`WorldRouter` 在场景加载后根据 `pending_spawn_id` 将玩家对齐到对应点。

## 后续计划（占位）

| `world_town.tscn` | 镇子核心区 | TBD | 📋 |
| `world_farm.tscn` | 独立农场 | TBD | 📋 |
| `world_forest.tscn` | 森林伐木 | TBD | 📋 |
| `world_beach.tscn` | 海边钓鱼 | TBD | 📋 |
| `world_mine.tscn` | 矿洞 | TBD | 📋 |
