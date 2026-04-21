# UI 布局检查工具使用指南

## 📖 概述

本项目提供了两个 UI 布局检查工具，用于自动化检测不符合 Godot 工业标准的代码。

---

## 🔧 工具列表

### 1. 完整版检查器 - `ui_layout_checker.gd`

**功能**:
- ✅ 扫描所有场景文件 (`.tscn`)
- ✅ 扫描所有脚本文件 (`.gd`)
- ✅ 检测硬编码 offset 值
- ✅ 识别缺少 layout_mode 的节点
- ✅ 生成详细审计报告 (Markdown 格式)

**使用方法**:

1. **在 Godot 编辑器中运行**:
   ```
   1. 打开 Godot 编辑器
   2. 在文件系统面板中找到 tools/ui_layout_checker.gd
   3. 右键点击文件
   4. 选择 "Run" 或按 F6
   ```

2. **查看输出**:
   - 控制台会显示检查进度
   - 完成后生成 `docs/UI_LAYOUT_AUDIT.md`
   - 报告包含所有发现的问题和修复建议

**输出示例**:
```
========================================
Godot Industrial Standards Checker
========================================

检查完成！共发现 42 个问题
详细报告已保存到: res://docs/UI_LAYOUT_AUDIT.md
========================================
```

---

### 2. 简化版测试器 - `test_ui_checker.gd`

**功能**:
- ✅ 快速测试检查逻辑
- ✅ 仅检查 main.gd 作为示例
- ✅ 直接在控制台输出结果
- ✅ 适合开发和调试

**使用方法**:

1. **在 Godot 编辑器中运行**:
   ```
   1. 打开 tools/test_ui_checker.gd
   2. 按 F6 运行
   ```

2. **查看控制台输出**:
   ```
   ========================================
   UI Layout Checker - Quick Test
   ========================================

   发现的问题: 5

   [HARDCODED_OFFSET] res://scenes/main.gd:448
     代码: q_bg.offset_left = 924.0
     建议: 使用 set_anchors_preset() 和响应式计算代替硬编码值
   
   ...
   
   ========================================
   测试完成！
   ========================================
   ```

---

## 📊 理解检查结果

### 问题类型说明

#### 🔴 HARDCODED_OFFSET (场景文件)
**含义**: 场景文件中使用了硬编码的绝对像素值

**示例**:
```gdscript
# ❌ 错误
offset_left = 924.0
offset_right = 1276.0
```

**修复**:
```gdscript
# ✅ 正确 - 使用锚点预设
set_anchors_preset(Control.PRESET_TOP_RIGHT)
offset_left = -352.0  # 从右边缘向左
offset_right = -4.0
```

---

#### 🟡 MISSING_LAYOUT_MODE
**含义**: Control 节点缺少 layout_mode 属性

**示例**:
```gdscript
# ❌ 错误 - 旧式布局
[node name="Panel" type="Panel"]
offset_left = 100.0
```

**修复**:
```gdscript
# ✅ 正确 - 添加 layout_mode
[node name="Panel" type="Panel"]
layout_mode = 1  # 启用锚点布局
anchors_preset = 15  # PRESET_FULL_RECT
```

---

#### 🔴 SCRIPT_HARDCODED_OFFSET (脚本文件)
**含义**: 脚本中动态创建 UI 时使用了硬编码值

**示例**:
```gdscript
# ❌ 错误
var panel = Panel.new()
panel.offset_left = 924.0
```

**修复**:
```gdscript
# ✅ 正确
var panel = Panel.new()
panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
panel.offset_left = -352.0
```

---

## 🎯 修复优先级

### 高优先级 🔴
1. **main.gd 中的硬编码值** - 影响主界面
2. **世界场景的传送门 UI** - 影响游戏体验
3. **对话框和菜单** - 频繁使用的 UI

### 中优先级 🟡
1. **设置面板** - 偶尔使用
2. **库存界面** - 中等频率
3. **NPC 对话气泡** - 动态创建

### 低优先级 🟢
1. **调试 UI** - 仅开发时使用
2. **临时提示** - 短暂显示
3. **背景装饰** - 不影响功能

---

## 💡 批量修复技巧

### 1. 使用搜索替换

在 Godot 编辑器中：
```
1. 按 Ctrl+Shift+F 打开全局搜索
2. 搜索: offset_left = \d{3,}
3. 逐个审查并替换为响应式布局
```

### 2. 使用辅助函数

创建通用的响应式布局函数：

```gdscript
func create_responsive_panel(parent: Control, 
                              preset: int,
                              margin: float = 4.0) -> Panel:
    var panel = Panel.new()
    panel.set_anchors_preset(preset)
    panel.offset_left = margin
    panel.offset_top = margin
    panel.offset_right = -margin
    panel.offset_bottom = -margin
    parent.add_child(panel)
    return panel
```

### 3. 使用容器系统

```gdscript
# 替代手动计算位置
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)
parent.add_child(vbox)

# 子元素自动排列
for i in range(5):
    var btn = Button.new()
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_child(btn)
```

---

## 🔍 验证修复

### 1. 重新运行检查器

修复后再次运行检查工具，确认问题数量减少：

```bash
# 运行完整检查
tools/ui_layout_checker.gd

# 或快速测试
tools/test_ui_checker.gd
```

### 2. 视觉测试

在不同分辨率下测试 UI：

```gdscript
# 临时修改视口大小进行测试
get_viewport().size = Vector2(1920, 1080)  # 1080p
# 检查 UI 是否正常

get_viewport().size = Vector2(1280, 720)   # 720p
# 再次检查
```

### 3. 功能测试

确保修复后功能正常：
- [ ] UI 元素正确显示
- [ ] 按钮可点击
- [ ] 文本可读
- [ ] 滚动正常工作
- [ ] 动画流畅

---

## 📝 最佳实践

### 日常开发检查清单

创建新 UI 时：

- [ ] 使用容器而非手动定位
- [ ] 设置正确的锚点预设
- [ ] 配置 size_flags
- [ ] 避免硬编码 >200px 的值
- [ ] 添加主题样式
- [ ] 测试不同分辨率
- [ ] 添加类型注解

### 代码审查要点

审查他人代码时：

- [ ] 运行 UI 检查器
- [ ] 检查是否有硬编码值
- [ ] 验证响应式行为
- [ ] 确认性能合理
- [ ] 检查可访问性

---

## 🐛 常见问题

### Q: 检查器报告误报怎么办？

**A**: 有些情况下硬编码是合理的（如图标固定大小）。可以在代码中添加注释说明：

```gdscript
#  intentional: fixed size for icon
icon_panel.custom_minimum_size = Vector2(32, 32)
```

### Q: 如何排除某些文件？

**A**: 修改检查器代码，添加排除列表：

```gdscript
var exclude_files = [
    "res://addons/",
    "res://tests/"
]

if file_path.begins_with_any(exclude_files):
    return
```

### Q: 检查器运行太慢怎么办？

**A**: 使用简化版测试器，或只检查特定目录：

```gdscript
# 只检查 scenes 目录
check_scenes("res://scenes/", issues)
```

---

## 📚 相关资源

- [Godot 工业标准规范](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
- [UI 布局改进报告](res://docs/UI_LAYOUT_IMPROVEMENT_REPORT.md)
- [快速参考卡片](res://docs/GODOT_UI_QUICK_REFERENCE.md)
- [Godot 官方 UI 文档](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)

---

## 🤝 贡献

如果发现检查器的 bug 或有改进建议：

1. 记录问题详情
2. 提供复现步骤
3. 提交到项目 issue tracker
4. 或直接修复并提交 PR

---

**最后更新**: 2026-04-21  
**维护者**: Development Team
