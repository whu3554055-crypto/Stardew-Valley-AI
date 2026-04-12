# 世界场景清单（活文档）

> 与 `docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md` 配套；新增/改名场景时请更新本表。

| 场景资源路径 | 用途 | 邻接/入口（spawn_id） | 状态 |
|--------------|------|------------------------|------|
| `res://scenes/main.tscn` | 现行主场景（农场+镇区+林+海+矿等逻辑区聚合） | `default`；`playground_return`；`from_farm_stub`…`from_mine_stub`；南缘入口进各 **stub** | ✅ 当前默认 |
| `res://scenes/world/world_playground.tscn` | 多场景冒烟 + **双 TileMapLayer** + **Y-Sort**（`YSortWorld`）试点 | `default` ↔ `main` 的 `PortalToPlayground` / `playground_return` | ✅ 冒烟 |
| `res://scenes/world/world_farm_stub.tscn` | **薄壳**农场带（传送验证） | `default`；西→`main` `from_farm_stub`；东→`world_town_stub` | ✅ 环 |
| `res://scenes/world/world_town_stub.tscn` | **薄壳**镇区带 | `default`；西→`main` `from_town_stub`；东→`world_forest_stub` | ✅ 环 |
| `res://scenes/world/world_forest_stub.tscn` | **薄壳**森林带 | `default`；西→`main` `from_forest_stub`；东→`world_beach_stub` | ✅ 环 |
| `res://scenes/world/world_beach_stub.tscn` | **薄壳**沙滩带 | `default`；西→`main` `from_beach_stub`；东→`world_mine_stub` | ✅ 环 |
| `res://scenes/world/world_mine_stub.tscn` | **薄壳**矿口带 | `default`；西→`main` `from_mine_stub`；东→`main` `default`（合环） | ✅ 环 |

## 环形冒烟

见 **`STUB_RING.md`**（`main` 不拆逻辑，仅加传送）。

## spawn_id 约定

- 全项目唯一字符串，如 `default`、`town_gate`、`beach`、`mine_entrance`。
- 场景中用 `WorldSpawnPoint`（组 `world_spawn`）注册；`WorldRouter` 在场景加载后根据 `pending_spawn_id` 将玩家对齐到对应点。

## 后续（实体 `world_*`，非薄壳）

| `world_town.tscn` | 镇子核心区 | TBD | 📋 |
| `world_farm.tscn` | 独立农场 | TBD | 📋 |
| `world_forest.tscn` | 森林伐木 | TBD | 📋 |
| `world_beach.tscn` | 海边钓鱼 | TBD | 📋 |
| `world_mine.tscn` | 矿洞 | TBD | 📋 |
