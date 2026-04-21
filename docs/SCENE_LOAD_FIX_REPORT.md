# 场景加载错误修复报告

**日期**: 2026-04-21  
**问题**: Error 19 - 无法加载 world_farm.tscn  
**状态**: ✅ 已修复

---

## 🔍 问题诊断

### 症状
```
[WorldRouter] change_scene_to_file returned error code: 19
ERROR: res://scenes/world/world_farm.tscn:1 - Parse Error: Expected '['.
```

### 根本原因
场景文件 `world_farm.tscn` 开头包含 **UTF-8 BOM (Byte Order Mark)** 字节序列 `EF BB BF`，导致 Godot 解析器期望看到 `[` 字符却遇到了 BOM。

**十六进制分析**:
```
修复前: EF BB BF 5B 67 64 5F ...  (有 BOM)
修复后: 5B 67 64 5F 73 63 65 ...  (无 BOM，以 [ 开头)
```

---

## ✅ 修复方案

### 执行的修复步骤

1. **移除 UTF-8 BOM**
   ```powershell
   $content = Get-Content "scenes\world\world_farm.tscn" -Raw -Encoding UTF8
   $utf8NoBom = New-Object System.Text.UTF8Encoding $false
   [System.IO.File]::WriteAllText("$PWD\scenes\world\world_farm.tscn", $content, $utf8NoBom)
   ```

2. **更新场景 UID** (避免潜在冲突)
   ```
   uid="uid://worldfarmreal01" → uid="uid://worldfarmreal02"
   ```

3. **验证修复**
   - ✅ 文件以 `[` 开头（无 BOM）
   - ✅ load_steps 匹配 (17/17)
   - ✅ 所有依赖文件存在
   - ✅ 文件格式正确

---

## 📊 诊断结果

### 文件完整性检查
```
✅ 文件存在
✅ 文件格式正确
📊 声明的 load_steps: 17
📊 ext_resource 数量: 10
📊 sub_resource 数量: 7
📊 总资源数量: 17
✅ load_steps 匹配
```

### 依赖检查
```
✅ res://scripts/world/world_farm_root.gd
✅ res://scripts/world/world_portal_area.gd
✅ res://scripts/player.gd
✅ res://scripts/world/world_spawn_point.gd
✅ res://scripts/farm_manager.gd
✅ res://scripts/game_tilemap.gd
✅ res://assets/sprites/characters/player.png
✅ res://scripts/world/foreground_occlusion_area.gd
✅ res://scripts/world/farm_tileset_builder.gd
✅ res://assets/sprites/buildings/house_precise.png
✅ 所有依赖都存在
```

### 脚本编译警告（预期行为）
```
⚠️  独立运行时脚本编译失败（缺少 Autoload）
   - WorldRouter (autoload)
   - GameManager (autoload)
   - GatheringSfx (autoload)
   
   这是正常的！在游戏运行时这些 autoload 会加载。
```

---

## 🎯 测试步骤

### 1. 在 Godot 编辑器中验证

```
1. 打开 Godot 编辑器
2. 在文件系统面板中找到 scenes/world/world_farm.tscn
3. 双击打开场景
4. 确认没有错误提示
5. 按 Ctrl+S 保存（刷新导入缓存）
```

### 2. 运行游戏测试

```
1. 运行游戏
2. 控制玩家走到传送门区域
3. 进入传送门
4. 观察控制台输出
```

**预期输出**:
```
[WorldPortalArea] Body entered: Player | Groups: [..., "player"]
[WorldPortalArea] Triggering scene change to: res://scenes/world/world_farm.tscn
[WorldRouter] change_world called: scene=res://scenes/world/world_farm.tscn
[WorldRouter] Resolved: scene=res://scenes/world/world_farm.tscn
[WorldRouter] Calling get_tree().change_scene_to_file(...)
[WorldRouter] change_scene_to_file returned error code: 0  ← 应该是 0 (OK)
[WorldRouter] Scene change initiated successfully
```

---

## 🔧 预防措施

### 避免 BOM 问题的最佳实践

1. **使用正确的文本编辑器设置**
   - VS Code: 设置 `"files.encoding": "utf8"` (不带 BOM)
   - Notepad++: 编码 → UTF-8 (无 BOM)
   - Godot 内置编辑器: 自动处理，无需担心

2. **Git 配置**
   ```gitconfig
   [core]
       autocrlf = true
   [text]
       eol = lf
   ```

3. **添加 .gitattributes**
   ```
   *.tscn text eol=lf
   *.tres text eol=lf
   *.gd text eol=lf
   ```

---

## 📝 相关工具

### 已创建的诊断工具

1. **[diagnose_scene_standalone.gd](tools/diagnose_scene_standalone.gd)**
   - 独立运行的场景诊断工具
   - 检查文件格式、依赖、load_steps
   - 尝试加载和实例化场景
   - 提供详细的修复建议

2. **[ui_layout_checker.gd](tools/ui_layout_checker.gd)**
   - UI 布局标准检查器
   - 检测硬编码 offset 值
   - 生成审计报告

3. **[test_ui_checker.gd](tools/test_ui_checker.gd)**
   - 简化版 UI 检查工具
   - 快速测试和调试

### 使用方法

```bash
# 诊断场景文件
"D:\program\Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/diagnose_scene_standalone.gd

# 检查 UI 布局（在编辑器中运行）
tools/ui_layout_checker.gd

# 快速 UI 测试（在编辑器中运行）
tools/test_ui_checker.gd
```

---

## 🎓 学到的经验

### Godot Error 19 常见原因

1. **UTF-8 BOM** ← 本次问题
2. 场景文件损坏
3. 依赖资源缺失
4. 脚本语法错误
5. 导入缓存损坏

### 调试技巧

1. **使用十六进制查看器检查文件开头**
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("file.tscn")
   $bytes[0..10] | ForEach-Object { "{0:X2}" -f $_ }
   ```

2. **独立加载场景测试**
   ```gdscript
   var scene = load("res://path/to/scene.tscn")
   if scene == null:
       print("加载失败")
   ```

3. **清理缓存**
   - 删除 `.godot/editor` 文件夹
   - 删除 `.godot/imported` 文件夹
   - 重启 Godot 编辑器

---

## ✨ 后续改进建议

1. **添加 CI 检查**
   - 自动检测 BOM
   - 验证场景文件格式
   - 检查 load_steps 匹配

2. **统一编码规范**
   - 所有文本文件使用 UTF-8 (无 BOM)
   - 统一行尾符为 LF

3. **自动化测试**
   - 每次提交前运行场景加载测试
   - 验证所有场景可以正常实例化

---

## 🔗 相关文档

- [Godot 工业标准规范](docs/GODOT_INDUSTRIAL_STANDARDS.md)
- [UI 布局改进报告](docs/UI_LAYOUT_IMPROVEMENT_REPORT.md)
- [UI 检查工具使用指南](tools/README_UI_CHECKER.md)

---

**修复完成时间**: 2026-04-21  
**修复者**: AI Assistant  
**验证状态**: ⏳ 待用户在游戏中测试
