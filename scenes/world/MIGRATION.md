# 多场景迁移策略（避免一次性撕碎 `main`）

## 原则

1. **先串联、后搬迁**：用 `world_*_stub` 与 `WorldRouter` 验证传送、出生点、存档 `world` 字段；再按区域把子树迁出 `main.tscn`。
2. **每迁一块**：在新 `world_*` 内补齐依赖（`FarmManager`、TileMap、同路径 `UILayer` 或显式共享 HUD 决策），并在 `main` **仅删已迁节点**、改入口为传送。
3. **B2（world_farm）建议顺序**：`FarmManager` + 农场 TileMap 碰撞与作物显示 → 农场相关 UI 回调（或信号上抛）→ 最后收拢 `main` 上仅余「枢纽」传送。

当前 **B2 勾选条件**未满足时，以 `STUB_RING.md` 的薄壳环为 **B9 冒烟** 替代；正式 B2 仍待农场子树整体搬迁。
