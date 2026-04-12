# TODO 已实现项验收

- 可点击目录与逐项说明：[docs/03-研发管理/11-TODO已实现项验收清单.md](docs/03-研发管理/11-TODO已实现项验收清单.md)
- 一键批处理（仓库根目录 PowerShell）：

```powershell
.\tools\run_todo_acceptance.ps1
```

（GUT 步调用 `run_gut.ps1`，覆盖 `res://tests/unit` 及子目录。）  
仅冒烟、跳过 GUT：`.\tools\run_todo_acceptance.ps1 -SkipGut`
