# 区域薄壳环形冒烟（B9 试点）

> **不迁移 `main` 内逻辑**：仅独立 `world_*_stub.tscn` + `main` 上传送点/出生点。

## 环序（stub）

`main`（南缘 5 个入口）→ **farm** → **town** → **forest** → **beach** → **mine** → `main`（`default` 出生点）或任一回传口返回 `from_*_stub`。

## 手动冒烟清单

1. 新游戏或读档进入 `main`。
2. 依次走入：`Farm stub` → 东口到 `Town` → … → `Mine` → 东口回 `main`。
3. 每段西口应能回到 `main` 对应 `from_*_stub` 标记附近。
4. 存档再读档：应在 `world.path` 对应场景落地（已有 B8）。

## 资源路径

| 场景 | 路径 |
|------|------|
| Farm stub | `res://scenes/world/world_farm_stub.tscn` |
| Town stub | `res://scenes/world/world_town_stub.tscn` |
| Forest stub | `res://scenes/world/world_forest_stub.tscn` |
| Beach stub | `res://scenes/world/world_beach_stub.tscn` |
| Mine stub | `res://scenes/world/world_mine_stub.tscn` |

常量亦在 `WorldRouter`（`FARM_STUB_SCENE` …）。

## 与 B2–B6 关系

薄壳为 **路线与存档串联** 验证；真正迁出 `FarmManager`/TileMap 等见 `MIGRATION.md`（分阶段，避免一次性撕 `main`）。
