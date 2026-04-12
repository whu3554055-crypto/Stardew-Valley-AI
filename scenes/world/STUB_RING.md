# 区域薄壳环形冒烟（B9 试点）

> **不迁移 `main` 内逻辑**：仅独立 `world_*_stub.tscn` + `main` 上传送点/出生点。

## 环序

`main` 南缘第一格为 **实体农场** `world_farm.tscn`（B2）；农场东口进入 **town stub** → **forest** → **beach** → **mine** → `main`（`default`）或各 `from_*_stub` / **`from_world_farm`** 回枢纽。

## 手动冒烟清单

1. 新游戏或读档进入 `main`。
2. 依次走入：**↓ Farm**（实体农场）→ 东口到 `Town` stub → … → `Mine` → 东口回 `main`。
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

**B2** 已迁出实体 `world_farm.tscn`；薄壳 stub 仍可单独测传送。其余区域迁出见 `MIGRATION.md`。
