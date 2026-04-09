# 今日任务清单（会话 2026-04-09）

| # | 状态 | 内容 |
|---|------|------|
| 1 | 部分 | FarmTier/商店/任务 JSON 化：见 `docs/DATA_ROADMAP_FARMTIER.md`；捏人贴图约定已写入同文档 |
| 2 | 部分 | 双语：已接 **商店 UI**（`messages_*` → `shop` 段 + `shop_ui.gd`）；NPC 对话/任务标题/FarmTier 文案需按模块继续补键 |
| 3 | 完成 | AI 默认 DashScope + `qwen-plus` + `openai_compatible`；密钥经 `data/local/ai_secrets.json`（gitignore）或环境变量 |
| 4 | 完成 | Agentic：`max_runtime_chains` 默认 24、`max_consecutive_failures` 5；支持 `user://agentic_content_config.json` 覆盖 |
| 5 | 完成 | OpenClaw 借鉴点：见 `docs/OPENCLAW_INSPIRATION_NPC.md` |

## 密钥说明

- 不要在公开仓库提交 `data/local/ai_secrets.json`（已加入 `.gitignore`）。
- 分发他人时改用环境变量 `DASHSCOPE_API_KEY` 或自建代理。
