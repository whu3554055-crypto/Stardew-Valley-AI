# Agent / 协作者说明（Godot 4.6）

## 技术栈

- 引擎：**Godot 4.6**（GDScript）
- 主场景：`res://scenes/main.tscn`；多场景冒烟：`world_playground` + **五带薄壳环**（`STUB_RING.md`，不拆 `main` 内农场/矿体逻辑）
- 阶段计划：`docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md`

## 多场景与存档

- **`WorldRouter`**（Autoload）：`change_world`、`pending_spawn_id`、读档后 `consume_saved_world_after_boot`（每局一次）。细节见 `scenes/world/ARCHITECTURE.md`。
- 出生点：场景内 **`WorldSpawnPoint`**（`spawn_id` + 组 `world_spawn`）。
- 存档 bundle 含 **`world`** 字段；**HMAC 签名载荷刻意不包含 `world`**（见 `scenes/main.gd` 中 `_bundle_signing_payload` 注释）。

## Headless 冒烟（无 CI 时本地/Agent 自检）

- 优先：`tools/run_headless_smoke.ps1`（默认 Godot 路径见 `.cursor/rules/godot-headless.mdc`；可用环境变量 `GODOT_CONSOLE` 覆盖）。
- `--quit-after` 单位为**帧/迭代**，不是秒。

## 密钥与隐私

- **勿**读取、提交或粘贴 `data/local/ai_secrets.json`（已在 `.gitignore` / `.cursorignore`）。
- 模板：`data/local/ai_secrets.json.example`（若存在）。

## Git 约定

- **一功能点一提交**（见 `.cursor/rules/git-one-feature-one-commit.mdc`）。
- 改动 `scenes/world/` 下场景或入口时，记得同步 `scenes/world/README.md` 场景表（见该目录 `AGENTS.md`）。

## Cursor 配置（本仓库）

- 规则：`.cursor/rules/*.mdc`
- 斜杠命令：`.cursor/commands/*.md`
- 可选钩子：`.cursor/hooks.json`（防误 `git add` 密钥路径）
