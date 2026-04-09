# FarmTier / 商店 / 任务 — JSON 化优先级（路线图）

当前 `data/farm/tiers.json` 已承载农场等级数值与活动区 HUD 文案（`FarmTierCatalog`）。后续建议按下面顺序把「规则」从代码挪到数据：

1. **FarmTier 数值与升级条件**（已有 `tiers.json`）— 继续只维护这一处。
2. **商店可购/库存与季节门控** — 新增例如 `data/shop/stock_by_farm_tier.json`（或扩展现有 `ShopSystem` 数据源），字段：`min_farm_tier`、`seasons`、`item_id`。
3. **任务链解锁条件** — 在 `data/quests/*.json` 或链模板上增加 `min_farm_tier` / `requires_building`（与 Building 文案键引用）。
4. **活动区标签** — `tiers.json` 的 `interaction.messages` 已部分覆盖；若需按区拆分，抽到 `data/ui/messages_*.json` 的 `farm_tier` 段并由 `UITextCatalog` 统一取键。

## 捏人 → 主角贴图 / 调色

- **资源命名约定**：`res://assets/player/body_{preset}.png`、`hair_{preset}.png`，调色用同一套图 + `modulate` 或 `ShaderMaterial` 的 `hair_color` / `skin_tone` uniform。
- **或**接一层 `PlayerAppearance`（Dictionary：`body_id`, `hair_id`, `tint_hair`, `tint_skin`）在 `_ready` 里换 `Sprite2D.texture` 与材质参数；捏人面板只写 `GameManager.player_data.appearance`。
