# 区域环形冒烟（B9）

## 主环（实体 B2–B6）

`main` 南缘：**↓ Farm**（`world_farm`）→ 东口 **Town**（`world_town`）→ **Forest**（`world_forest`）→ **Beach**（`world_beach`）→ **Mine**（`world_mine`）→ 东口回 **`main`**（落地 `from_world_mine` 等）。

枢纽亦可从南缘直接进入 **Town / Forest / Beach / Mine**（`default` 出生点）。

## 薄壳备用环

`world_*_stub.tscn` 链仍可用来**仅验证传送**；自 `main` 返回时的 `spawn_id` 已与实体环对齐（`from_world_town` … `from_world_mine`）。

## 手动冒烟清单

1. 新游戏或读档进入 `main`。
2. 走通：**↓ Farm** → 东口 **Town** → … → **Mine** → **→ Main**。
3. 在 `world_forest` / `world_beach` / `world_mine` 内用斧 / 竿 / 镐各试一次（应在彩色逻辑带内成功）。
4. `world_town`：靠近 Pierre 按 **B** 打开商店；**E** 对话应出现 `dialogue_pools.json` 文案。
5. 存档再读档：`world.path` + `spawn_id` 落地（B8）。

## 资源路径（薄壳）

| 场景 | 路径 |
|------|------|
| Farm stub | `res://scenes/world/world_farm_stub.tscn` |
| Town stub | `res://scenes/world/world_town_stub.tscn` |
| Forest stub | `res://scenes/world/world_forest_stub.tscn` |
| Beach stub | `res://scenes/world/world_beach_stub.tscn` |
| Mine stub | `res://scenes/world/world_mine_stub.tscn` |

## 与 B2–B6 关系

**B2** `world_farm` 为实体农场；**B3–B6** 为带玩法 override 的薄壳实体场景（非 stub）；stub 保留作传送回归测试。
