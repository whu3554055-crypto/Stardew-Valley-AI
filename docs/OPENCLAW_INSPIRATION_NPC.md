# 借鉴 OpenClaw / AutoClaw 式「记忆 + 性格」

可落地的映射（不引入外部向量服务的前提下）：

## 性格（≈ SOUL.md）

- 每个 NPC 在 `data/npcs/*.json`（或现有 personality 配置）增加 **`soul_prompt`** 或 **`voice_rules`** 短列表（3–5 条），生成对话时拼进 `AIAgentManager` / `AdvancedAIManager` 的 prompt 前缀。
- 版本化：同一 NPC 可保留 `soul_version`，存档里记录已见过的版本，避免人设突变无解释。

## 记忆分层

| OpenClaw 概念 | 本游戏可映射 |
|----------------|--------------|
| 每日日志 | `GameManager.history_log` / 日记事件；或 `user://npc_memory_<id>.json`（append 当日摘要） |
| MEMORY.md（长期） | 每 N 天用 **一次** LLM 调用把「最近日志」压成 5–10 条 bullet 写入 `player_data` 或 `npc_memory` 文件 |
| 会话历史 | 对话 UI 最近 K 轮（已有 `player_history` 类结构可扩展） |

## 语义检索（memory_search）

- 若不上向量库：用 **关键词 + 最近 N 条** 记忆做 prompt 片段；后续可选接入后端 `hello_agent_backend` 的向量检索。

## 安全与成本

- 长期记忆进 prompt 前做 **长度上限** 与 **敏感词/脱敏**（与现有 guardrail 一致）。
- 主会话才注入「长期记忆」：与 OpenClaw「主会话加载 MEMORY」一致，避免多 NPC 广播泄露。
