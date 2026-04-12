# 世界场景清单（活文档）

> 与 `docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md` 配套；新增/改名场景时请更新本表。

| 场景资源路径 | 用途 | 邻接/入口（spawn_id） | 状态 |
|--------------|------|------------------------|------|
| `res://scenes/main.tscn` | **枢纽**：镇区活动、NPC、商店、矿/林/海多边形区、UI 全量（**无**全局 TileMap / FarmManager） | `default`；`playground_return`；`from_farm_stub`…`from_mine_stub`；**`from_world_farm`**；南缘 **↓ Farm** → `world_farm`；其它 stub 入口仍可用 | ✅ 当前默认 |
| `res://scenes/world/world_farm.tscn` | **B2 实体农场**：`GameTileMap` + `FarmManager` + 玩家 + `FarmHud` 文案提示 | `default`；`from_main`；西→`main` **`from_world_farm`**；东→`world_town_stub` `default` | ✅ 实体 |
| `res://scenes/world/world_playground.tscn` | 多场景冒烟 + **双 TileMapLayer** + **Y-Sort**（`YSortWorld`）试点 | `default` ↔ `main` 的 `PortalToPlayground` / `playground_return` | ✅ 冒烟 |
| `res://scenes/world/world_farm_stub.tscn` | **薄壳**农场带（传送验证；可与实体农场并存） | `default`；西→`main` `from_farm_stub`；东→`world_town_stub` | ✅ 环 |
| `res://scenes/world/world_town_stub.tscn` | **薄壳**镇区带 | `default`；西→`main` `from_town_stub`；东→`world_forest_stub` | ✅ 环 |
| `res://scenes/world/world_forest_stub.tscn` | **薄壳**森林带 | `default`；西→`main` `from_forest_stub`；东→`world_beach_stub` | ✅ 环 |
| `res://scenes/world/world_beach_stub.tscn` | **薄壳**沙滩带 | `default`；西→`main` `from_beach_stub`；东→`world_mine_stub` | ✅ 环 |
| `res://scenes/world/world_mine_stub.tscn` | **薄壳**矿口带 | `default`；西→`main` `from_mine_stub`；东→`main` `default`（合环） | ✅ 环 |

## 环形冒烟

见 **`STUB_RING.md`**。南缘第一格现为 **实体农场**（`world_farm.tscn`）；`world_farm_stub` 仍可从编辑器或其它入口进入做纯传送测试。

## spawn_id 约定

- 全项目唯一字符串，如 `default`、`town_gate`、`beach`、`mine_entrance`。
- 场景中用 `WorldSpawnPoint`（组 `world_spawn`）注册；`WorldRouter` 在场景加载后根据 `pending_spawn_id` 将玩家对齐到对应点。

## 后续（实体 `world_*`，非薄壳）

| `world_town.tscn` | 镇子核心区 | TBD | 📋 |
| `world_forest.tscn` | 森林伐木 | TBD | 📋 |
| `world_beach.tscn` | 海边钓鱼 | TBD | 📋 |
| `world_mine.tscn` | 矿洞 | TBD | 📋 |
