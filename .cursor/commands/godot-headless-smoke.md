# Godot headless 冒烟

在仓库根目录执行（Windows PowerShell）：

```powershell
.\tools\run_headless_smoke.ps1 -Frames 120
```

可选：只跑子场景，例如：

```powershell
.\tools\run_headless_smoke.ps1 -Frames 60 -Scene "res://scenes/world/world_playground.tscn"
```

若 exe 不在默认路径，先设置环境变量 `GODOT_CONSOLE` 指向 `*_console.exe`。

根据结果：若有脚本/场景错误，定位并修复；`ObjectDB leaked` 在 `--quit-after` 硬退出时常见，以退出码是否为 0 为准。
