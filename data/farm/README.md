# 农场数据表

## `crops.json`

作物单行字段（与 `FarmManager.crops_db` 对齐）：

| 字段 | 说明 |
|------|------|
| `id` | 作物 id |
| `name` | 显示名 |
| `growth_days` | 成熟所需「有效生长日」数 |
| `harvest_product` / `harvest_count` | 收获物品与数量 |
| `regrows` / `regrow_days` | 是否再生及再生周期 |
| `seasons` | 可种植季节列表 |
| `watering` | `daily`：需当日浇水才记一日生长；`none`：每日自动生长一格（低维护作物） |

缺省：未写 `watering` 时按 `daily` 处理。
