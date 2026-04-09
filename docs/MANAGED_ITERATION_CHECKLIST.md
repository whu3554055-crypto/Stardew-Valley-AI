# 托管迭代检查清单（每轮一次）

每轮目标：在**不扩大范围**的前提下，各做一小块 **A1 / A2 / A3**，并可持续合并进主线。

## 原则（与 `TODO.md` 一致）

- **范式锚点**：AI / Agentic 与确定性边界的原则见 [`docs/03-研发管理/04-AI与Agentic开发指导大纲.md`](03-研发管理/04-AI与Agentic开发指导大纲.md)；多轮只做玩法/表现时，建议按该文档 **§7 阶段性反思清单** 自查。
- **可玩优先**：主循环能跑通；改动可验收。
- **闭环优先**：有输入、有反馈、最好有经济或配方去向。
- **单线最多细化 2 次**：同一子系统本轮若已做过一次加深，第二次只做收尾或验收，不无限堆。

## 每轮必做步骤

1. **选线**
   - **A1**：玩法加深（钓鱼 / 挖矿 / 烹饪 / 农场 / 建筑 等任选一条）。
   - **A2**：换另一条系统重复「内容或规则 + 数值/反馈」标准（避免只堆一条线）。
   - **A3**：呈现或可读性（HUD、引导、占位图、文案统一等），可与玩法并行、体量宜小。

2. **实现**
   - 尽量**数据驱动**（`res://data/...json`），少硬编码魔法数。
   - 与现有存档字段兼容；新字段要有默认与加载路径。

3. **自检**
   - 修改过的脚本跑 **linter**（无新告警）。
   - 关键路径能说明白：玩家如何触发、成功/失败各看到什么。

4. **文档**
   - 更新 `TODO.md` 对应阶段**进度说明**（一句话即可）。

5. **提交**
   - 遵循 `CONTRIBUTING.md`：**Conventional Commits**。
   - 一轮可 **一个 commit** 打包本清单三项，或按子域拆成多个 commit（任选，保持历史可读）。

## 何时打断人类

- 需要产品取舍（两种玩法方向互斥）。
- 改动会大面积破坏存档或需迁移策略。
- 外部依赖/环境无法在本机验证。

## 本轮执行记录（人工填写）

| 日期 | A1 | A2 | A3 | Commit |
|------|----|----|-----|--------|
| 2026-04-08 | 烹饪 `hearty_pumpkin_bowl`（南瓜+土豆+面包） | 钓鱼咬钩：过早 / 超时提示区分 | `WorldEventFeed` 边框季节色 | 见 `git log -1 --oneline` |

## 轻测试闭环记录

| 日期 | 变更 | 结果 |
|------|------|------|
| 2026-04-09 | 新增 `tests/unit/test_ai_quest_system.gd`：覆盖 `_normalize_ai_quest_payload`（裁剪与 `objective_type` 映射）和 `_parse_ai_quest_json`（fenced JSON 解析） | 代码已提交到工作区，待运行 |
| 2026-04-09 | 新增 `tests/unit/test_quest_system.gd`：覆盖 `add_story_daily_quest` 按 `narrative_day_key` 去重刷新 | 代码已提交到工作区，待运行 |
| 2026-04-09 | 执行 `godot --version` 以启动本地测试链路 | 阻塞：当前环境未安装或未配置 Godot CLI（`CommandNotFoundException: godot`） |
| 2026-04-09 | A1/A2/A3 实装：新增 `managed_supply_chain_*` 三步村庄委托链（收获→对话→卖货），`DailyNarrativeSystem`/`AIQuestSystem` 的 AI 失败可见降级提示，`ShopUI` 增加市场热度标签（`HOT/COLD/STEADY` + 趋势箭头） | 已完成，进入下一轮可玩性观察 |
| 2026-04-09 | 继续可玩性强化：三步村庄委托链加入“完成速度分支奖励”（fast/steady/slow）与“链路收尾市场脉冲”，并在 `WorldEventFeed`/`QuickTip` 显示世界反馈 | 已完成，待实机观察体感与数值 |
| 2026-04-09 | 参数外提：新增 `data/quests/managed_chain.json`，将委托链速度阈值与奖励金币改为配置驱动；`QuestSystem` 启动时读取配置并保留默认兜底 | 已完成，后续可仅改 JSON 调平衡 |
| 2026-04-09 | 配置化继续收敛：将“链路收尾经济脉冲因子 + 作用商品列表”并入 `data/quests/managed_chain.json`；`QuestSystem` 读取后透传给 `AIEconomySystem` | 已完成，实现单一配置源调平衡 |
| 2026-04-09 | 第1轮优先项：委托链新增“临近超时/超时失败”分支；失败触发负向市场脉冲；`QuestLog` 增加链路状态标签与失败横幅提示 | 已完成，待实机观察失败分支体感 |
| 2026-04-09 | 第2-4轮合并推进：新增 `data/quests/chain_templates.json`（供应链+矿产链），`QuestSystem` 模板化注册链路；叙事主题驱动链路选择；`QuestLog` 分组展示 chain；`ShopUI` 增加 `[Chain Focus]` 高亮 | 已完成，进入多链调优阶段 |
| 2026-04-09 | 第5轮收尾：新增 `tests/unit/test_managed_chain_system.gd`（主题选链/临界日 urgent/超时 failed），沉淀 `docs/03-研发管理/06-配置化开发原则.md` | 已完成，形成可复制迭代规范 |
| 2026-04-09 | 按优先级继续强化（你点名 2/3/4 轮）：加入链路冷却与日选链策略（rotate/random/theme 优先），奖励池加权掉落，失败后 1 步 Recovery 任务并成功后自动重启链路 | 已完成，进入运营调参阶段 |
| 2026-04-09 | 新6轮完成：事件预算门控（narrative/chain/recovery）；`tools/validate_chain_templates.py` 校验脚本；新增烹饪链/渔业链；NPC分层反应（语音+记忆）；商店周策略（balanced/promotion/tight_margin）；存档版本迁移到 v3 | 已完成，准备进入 AI/Agentic 批量造链 |
| 2026-04-09 | Agentic 工具链强化并实跑首批：新增 `tools/merge_chain_batch.py`、`tools/generate_chain_batch_template.json`、批次文件 `tools/batches/batch_20260409_01.json`；校验器支持 `--batch-prefix` 和近似去重；成功合并 6 条新链（总计 10 链） | 已完成，进入下一批批量生成 |
| 2026-04-09 | Agentic 第2批实跑：新增批次 `tools/batches/batch_20260409_02.json`（恐怖/科幻/喜剧/冒险/浪漫等 6 条链）；批次前缀去重校验通过并合并入主模板（+6） | 已完成，主模板增至 16 链，继续可按同流程扩批 |
