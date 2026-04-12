# 世界场景清单（活文档）

> 与 `docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md` 配套；新增/改名场景时请更新本表。

| 场景资源路径 | 用途 | 邻接/入口（spawn_id） | 状态 |
|--------------|------|------------------------|------|
| `res://scenes/main.tscn` | **枢纽**：镇区活动、NPC、商店、矿/林/海多边形区、UI 全量（**无**全局 TileMap / FarmManager） | `default`；`playground_return`；`from_farm_stub`；**`from_world_farm`** / **`from_world_town`** / **`from_world_forest`** / **`from_world_beach`** / **`from_world_mine`**；南缘 **↓ Farm / Town / Forest / Beach / Mine** | ✅ 当前默认 |
| `res://scenes/world/world_farm.tscn` | **B2 实体农场**：`GameTileMap` + `FarmManager` + 玩家 + `FarmHud` 文案提示 | `default`；`from_main`；西→`main` **`from_world_farm`**；东→`world_town` **`from_world_farm`** | ✅ 实体 |
| `res://scenes/world/world_town.tscn` | **B3 镇区壳**：地块 + Pierre（静态对话池）+ `ShopUI`（B 键近 Pierre） | `default`；`from_main`；`from_world_farm`；`from_world_forest`；西→`main` **`from_world_town`**；东→`world_forest` **`from_world_town`** | ✅ 实体壳 |
| `res://scenes/world/world_forest.tscn` | **B4 森林壳**：`ChoppingSystem` 矩形 override（伐木） | `default`；`from_world_town`；`from_world_beach`；西↔镇、东↔海滩 | ✅ 实体壳 |
| `res://scenes/world/world_beach.tscn` | **B5 海滩壳**：`FishingSystem` ocean override（海钓） | `default`；`from_world_forest`；`from_world_mine`；西↔林、东↔矿 | ✅ 实体壳 |
| `res://scenes/world/world_mine.tscn` | **B6 矿口壳**：`MiningSystem` 矩形 override + 深度带 | `default`；`from_world_beach`；`from_main`；西↔滩、东→`main` **`from_world_mine`** | ✅ 实体壳 |
| `res://scenes/world/world_playground.tscn` | 多场景冒烟 + **双 TileMapLayer** + **Y-Sort**（`YSortWorld`）试点 | `default` ↔ `main` 的 `PortalToPlayground` / `playground_return` | ✅ 冒烟 |
| `res://scenes/world/world_farm_stub.tscn` | **薄壳**农场带（传送验证；可与实体农场并存） | `default`；西→`main` `from_farm_stub`；东→`world_town_stub` | ✅ 环 |
| `res://scenes/world/world_town_stub.tscn` | **薄壳**镇区带 | `default`；西→`main` **`from_world_town`**；东→`world_forest_stub` | ✅ 环 |
| `res://scenes/world/world_forest_stub.tscn` | **薄壳**森林带 | `default`；西→`main` **`from_world_forest`**；东→`world_beach_stub` | ✅ 环 |
| `res://scenes/world/world_beach_stub.tscn` | **薄壳**沙滩带 | `default`；西→`main` **`from_world_beach`**；东→`world_mine_stub` | ✅ 环 |
| `res://scenes/world/world_mine_stub.tscn` | **薄壳**矿口带 | `default`；西→`main` **`from_world_mine`**；东→`main` `default`（合环） | ✅ 环 |

## 环形冒烟

见 **`STUB_RING.md`**。推荐主环：**实体** `world_farm` → `world_town` → `world_forest` → `world_beach` → `world_mine` → `main`；枢纽南缘五格与农场东口与此一致。薄壳 `world_*_stub` 仍可单独测传送。

`WorldRouter` 常量：`WORLD_TOWN_SCENE`、`WORLD_FOREST_SCENE`、`WORLD_BEACH_SCENE`、`WORLD_MINE_SCENE`（及既有 stub 常量）。

## spawn_id 约定

- 全项目唯一字符串，如 `default`、`town_gate`、`beach`、`mine_entrance`。
- 场景中用 `WorldSpawnPoint`（组 `world_spawn`）注册；`WorldRouter` 在场景加载后根据 `pending_spawn_id` 将玩家对齐到对应点。
