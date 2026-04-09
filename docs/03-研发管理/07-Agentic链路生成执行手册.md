# Agentic 链路生成执行手册

目标：通过多 Agent 协同，批量生成高质量任务链，并自动校验后安全落盘到 `data/quests/chain_templates.json`。

## 1. 角色分工

- Agent A（Theme Planner）
  - 产出：`theme_plan.json`
  - 内容：本批次主题配比、每条链情绪强度、推荐 `preferred_themes`

- Agent B（Chain Generator）
  - 产出：`chain_templates_batch.json`
  - 内容：完整 chain 草案（3 steps、objective、reward pool、cooldown）

- Agent C（Validator/Fixer）
  - 输入：B 产物
  - 工具：`tools/validate_chain_templates.py`
  - 产出：`chain_templates_batch.fixed.json`
  - 规则：不过检不合并

- Agent D（Balance Reviewer）
  - 产出：`balance_notes.md`
  - 内容：奖励、权重、冷却、失败压力的调参建议

- Gatekeeper（合并守门）
  - 合并到 `data/quests/chain_templates.json`
  - 输出：变更摘要 + 风险清单 + 实测建议

## 2. 标准批次规模

- 每批建议 6 条链：
  - 2 条轻松（joyful/comedy）
  - 2 条中性（adventure/fairy_tale）
  - 2 条强情绪（horror/romantic/sci_fi）

- 每条链固定 3 步：
  1) 触发步（低门槛）
  2) 承接步（社交或加工）
  3) 兑现步（earn_gold）

## 3. Schema 约束（必须满足）

- `id`、`display_name`、`cooldown_days`、`preferred_themes`、`steps` 必填
- 批次生成建议强制 `id` 前缀（例如 `b20260409_`）
- objective type 仅允许：
  - `harvest`
  - `talk`
  - `earn_gold`
  - `mine_ore`
  - `fish_caught`
  - `cook_meal`
  - `smelt_bar`
  - `chop_wood`
  - `craft_item`
- reward pool:
  - `entries` 非空
  - `weight` > 0
  - `count` > 0

## 4. 执行流程

1) Agent A 先产主题计划  
2) Agent B 根据主题计划生成 JSON 草案  
3) Agent C 运行校验并修复：
   - `python tools/validate_chain_templates.py --file <batch.json> --batch-prefix <prefix> --existing data/quests/chain_templates.json`
4) Agent D 给平衡建议（不直接改 schema）  
5) Gatekeeper 合并：
   - `python tools/merge_chain_batch.py --batch <batch.json> --target data/quests/chain_templates.json --replace-policy`
6) 合并后再跑一次全量校验并记录到 `docs/MANAGED_ITERATION_CHECKLIST.md`

## 5. 合并前检查清单

- 是否有重复 chain id / step id  
- 是否有单主题过载（同类 > 50%）  
- 是否存在 reward pool 单一化（一个条目权重 > 90%）  
- 是否有 cooldown_days 全为 0（容易重复）  

## 6. 上线后观察（3天）

- 完成率（按 chain）  
- 失败率与 recovery 触发率  
- `[Chain Focus]` 商品是否被玩家利用  
- fast/steady/slow 分布是否合理
