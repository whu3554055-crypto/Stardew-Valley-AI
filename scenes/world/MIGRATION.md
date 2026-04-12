# 多场景迁移策略（避免一次性撕碎 `main`）

## 原则

1. **先串联、后搬迁**：用 `world_*_stub` 与 `WorldRouter` 验证传送、出生点、存档 `world` 字段；再按区域把子树迁出 `main.tscn`。
2. **每迁一块**：在新 `world_*` 内补齐依赖（`FarmManager`、TileMap、同路径 `UILayer` 或显式共享 HUD 决策），并在 `main` **仅删已迁节点**、改入口为传送。
3. **B2（world_farm）建议顺序**：`FarmManager` + 农场 TileMap 碰撞与作物显示 → 农场相关 UI 回调（或信号上抛）→ 最后收拢 `main` 上仅余「枢纽」传送。

**B2 已完成**：`world_farm.tscn` 含 `TileMap` + `FarmManager`；`main` 为枢纽；农场状态经 `FarmStateCache`，存档经 `GameSaveService` + `WorldRouter` 离场景前自动 flush。后续 B3+ 仍按「先串联、后搬迁」执行。
