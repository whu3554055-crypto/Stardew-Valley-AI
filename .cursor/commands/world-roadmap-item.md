# 按阶段计划做一项 world 工作

1. 打开 `docs/03-研发管理/09-星露谷向体验与多场景阶段计划.md`，在 **§4 TODO** 中选**一项**未勾选条目（优先 B/C 与多场景相关）。
2. 阅读 `AGENTS.md`、`scenes/world/AGENTS.md`、`scenes/world/ARCHITECTURE.md` 中与该项相关的段落。
3. 实现该项：**一功能点一提交**；若动到 `scenes/world/` 场景或入口，同步更新 `scenes/world/README.md` 表。
4. 完成后把该 TODO 改为 `- [x]`，必要时用一句话注明范围（可选）。
5. 本地验证：在仓库根运行 `.\tools\run_headless_smoke.ps1 -Frames 120`（或用户指定的 Godot 路径）。
