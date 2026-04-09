# Agentic 链路 Prompt 模板

用于让 Agent B（Chain Generator）批量生成 `chain_templates` JSON。

---

## 0) 通用系统提示（固定）

你是内容生成 Agent。请输出 JSON 片段，结构必须兼容 `data/quests/chain_templates.json`。

硬性要求：
- 每条链 3 steps
- objective.type 仅可用白名单（harvest/talk/earn_gold/mine_ore/fish_caught/cook_meal/smelt_bar/chop_wood/craft_item）
- 每步 reward 必须包含 `gold`、`items`，可选 `pool`
- `pool.entries[].weight` 必须大于 0
- 文案简短，能直接展示到 QuestLog

输出只允许 JSON，不要附加解释。

---

## 1) 恐怖（horror）模板

生成 1 条主题为 horror 的 chain，要求：
- `preferred_themes` 包含 `horror`
- 步骤风格：调查异常 -> 与 NPC 确认 -> 出售相关物资
- 奖励池更偏保守（基础物资权重较高）

---

## 2) 浪漫（romantic）模板

生成 1 条主题为 romantic 的 chain，要求：
- `preferred_themes` 包含 `romantic`
- 步骤风格：准备礼物素材 -> 对话传递 -> 完成经济闭环
- 奖励池偏“温和、连续可玩”

---

## 3) 搞笑（comedy）模板

生成 1 条主题为 comedy 的 chain，要求：
- `preferred_themes` 包含 `comedy`
- 文案轻松幽默，但 objective 仍然务实可完成
- 奖励池中至少 2 个条目且权重不极端（建议 40/60 或 50/50）

---

## 4) 科幻（sci_fi）模板

生成 1 条主题为 sci_fi 的 chain，要求：
- `preferred_themes` 包含 `sci_fi`
- 步骤风格：收集样本 -> 技术汇报 -> 交易兑现
- 保持玩法 objective 与现有系统兼容，不引入新类型

---

## 5) 冒险（adventure）模板

生成 1 条主题为 adventure 的 chain，要求：
- `preferred_themes` 包含 `adventure`
- 第一步建议 `mine_ore` 或 `fish_caught`
- 结尾保持 `earn_gold` 收束

---

## 6) 批量生成提示（6条）

请一次生成 6 条 chain，主题配比：
- 2 条：joyful/comedy
- 2 条：adventure/fairy_tale
- 2 条：horror/romantic/sci_fi（任选其二）

每条链：
- 3 steps
- `cooldown_days` 在 1~2
- reward pool 不得只有单一条目

输出格式：
```json
{
  "chains": [
    { ... },
    { ... }
  ]
}
```

---

## 7) 生成后固定动作

1. 将结果写入临时文件（例如 `chain_templates_batch.json`）  
2. 运行校验：`python tools/validate_chain_templates.py`  
3. 若失败，按报错自动修复后重跑  
4. 通过后再合并到主文件
