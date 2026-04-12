# NPC 数据（占位）

## `simple_schedules.json`（E1）

- **用途**：2–3 名 NPC 的**时间段 + 锚点占位**，供后续「仅当前场景实例化 NPC」或「全局日程 + 场景内刷新」接入。
- **字段**：`blocks[]` 内 `start_hour` / `end_hour` 为 24h 制；`anchor` 为逻辑点名（非场景路径）；`policy` 说明推荐策略。
- **现状**：**未**接入 `NPCBehaviorController` 运行时；添加此文件仅为数据与约定落地。
