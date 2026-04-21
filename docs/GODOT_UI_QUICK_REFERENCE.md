# Godot UI 布局快速参考

> 速查表 - 符合工业标准的 UI 开发最佳实践

---

## 🎯 锚点预设速查

```gdscript
# 全屏填充（最常用）
control.set_anchors_preset(Control.PRESET_FULL_RECT)

# 四角定位
Control.PRESET_TOP_LEFT      # 左上
Control.PRESET_TOP_RIGHT     # 右上
Control.PRESET_BOTTOM_LEFT   # 左下
Control.PRESET_BOTTOM_RIGHT  # 右下

# 居中对齐
Control.PRESET_CENTER           # 中心点
Control.PRESET_HCENTER_WIDE     # 水平居中 + 全宽
Control.PRESET_VCENTER_HEIGHT   # 垂直居中 + 全高

# 顶部/底部居中
Control.PRESET_TOP_WIDE
Control.PRESET_BOTTOM_WIDE
```

---

## 📦 容器选择指南

| 需求 | 容器 | 示例 |
|------|------|------|
| 垂直列表 | `VBoxContainer` | 菜单、设置项 |
| 水平排列 | `HBoxContainer` | 工具栏、按钮组 |
| 网格布局 | `GridContainer` | 物品栏、技能树 |
| 滚动内容 | `ScrollContainer` | 长文本、日志 |
| 居中对齐 | `CenterContainer` | 弹窗、提示框 |
| 添加边距 | `MarginContainer` | 面板内边距 |
| 标签切换 | `TabContainer` | 多页设置 |

---

## 🔧 常用代码片段

### 1. 创建响应式面板

```gdscript
var panel = Panel.new()
panel.set_anchors_preset(Control.PRESET_FULL_RECT)
panel.offset_left = 10    # 左边距
panel.offset_top = 10     # 上边距
panel.offset_right = -10  # 右边距（负值）
panel.offset_bottom = -10 # 下边距（负值）
```

### 2. 使用容器自动布局

```gdscript
# 父容器
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)  # 元素间距
parent.add_child(vbox)

# 子元素自动扩展
var button = Button.new()
button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
button.text = "点击我"
vbox.add_child(button)
```

### 3. 动态调整布局

```gdscript
func _on_viewport_resized():
    var viewport_size = get_viewport().get_visible_rect().size
    
    # 基于屏幕比例
    var panel_width = viewport_size.x * 0.3   # 30% 宽度
    var panel_height = viewport_size.y * 0.5  # 50% 高度
    
    my_panel.custom_minimum_size = Vector2(panel_width, panel_height)
```

### 4. 创建样式

```gdscript
var style = StyleBoxFlat.new()
style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
style.set_border_width_all(2)
style.border_color = Color(0.4, 0.4, 0.4)
style.corner_radius_top_left = 8
style.corner_radius_top_right = 8

panel.add_theme_stylebox_override("panel", style)
```

---

## ⚡ Size Flags 速查

```gdscript
# 水平方向
Control.SIZE_FILL              # 填充（默认）
Control.SIZE_EXPAND            # 扩展
Control.SIZE_EXPAND_FILL       # 扩展并填充
Control.SIZE_SHRINK_BEGIN      # 收缩到内容（左对齐）
Control.SIZE_SHRINK_CENTER     # 收缩到内容（居中）
Control.SIZE_SHRINK_END        # 收缩到内容（右对齐）

# 垂直方向（同上）
control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
control.size_flags_vertical = Control.SIZE_EXPAND_FILL
```

---

## 🚫 常见错误 vs ✅ 正确做法

### ❌ 错误：硬编码绝对位置

```gdscript
panel.offset_left = 924.0
panel.offset_top = 44.0
panel.offset_right = 1276.0
panel.offset_bottom = 632.0
```

### ✅ 正确：使用相对锚点

```gdscript
panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
panel.offset_left = -352.0   # 从右边缘向左
panel.offset_top = 44.0
panel.offset_right = -4.0
panel.offset_bottom = 632.0
```

---

### ❌ 错误：手动计算位置

```gdscript
for i in range(5):
    var btn = Button.new()
    btn.position = Vector2(100, i * 40)  # 硬编码
    add_child(btn)
```

### ✅ 正确：使用容器

```gdscript
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)
add_child(vbox)

for i in range(5):
    var btn = Button.new()
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.text = "按钮 %d" % i
    vbox.add_child(btn)
```

---

## 🎨 UI 主题最佳实践

### 创建全局主题

```gdscript
# 在 autoload 中
var global_theme = Theme.new()

# 定义标准颜色
global_theme.set_color("primary", "Label", Color(0.9, 0.9, 0.9))
global_theme.set_color("secondary", "Label", Color(0.7, 0.7, 0.7))
global_theme.set_color("accent", "Label", Color(0.3, 0.7, 1.0))

# 定义标准字体大小
global_theme.set_font_size("small", "Label", 12)
global_theme.set_font_size("normal", "Label", 16)
global_theme.set_font_size("large", "Label", 24)

# 应用主题
get_tree().root.theme = global_theme
```

### 使用主题常量

```gdscript
label.add_theme_color_override("font_color", 
    get_theme_color("primary", "Label"))
label.add_theme_font_size_override("font_size", 
    get_theme_font_size("normal", "Label"))
```

---

## 🔍 调试技巧

### 显示布局边界

```gdscript
# 在 _ready() 中
if OS.is_debug_build():
    set_process_input(true)
    
func _input(event):
    if event.is_action_pressed("ui_focus_next"):  # Tab 键
        # 打印所有 Control 节点的布局信息
        _debug_layout_info(self)

func _debug_layout_info(node: Node, indent: String = ""):
    if node is Control:
        print("%s%s: pos=%s size=%s" % [
            indent, 
            node.name, 
            node.position, 
            node.size
        ])
    
    for child in node.get_children():
        _debug_layout_info(child, indent + "  ")
```

### 可视化锚点

```gdscript
# 临时添加彩色边框查看布局
func show_layout_bounds(control: Control):
    var debug_rect = ColorRect.new()
    debug_rect.color = Color(1, 0, 0, 0.3)  # 半透明红色
    debug_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    control.add_child(debug_rect)
    debug_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
```

---

## 📱 响应式设计模式

### 1. 断点系统

```gdscript
enum ScreenSize { SMALL, MEDIUM, LARGE }

func get_screen_size() -> ScreenSize:
    var width = get_viewport().get_visible_rect().size.x
    if width < 800:
        return ScreenSize.SMALL
    elif width < 1280:
        return ScreenSize.MEDIUM
    else:
        return ScreenSize.LARGE

func apply_responsive_layout():
    match get_screen_size():
        ScreenSize.SMALL:
            # 手机布局
            sidebar.visible = false
            main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        ScreenSize.MEDIUM:
            # 平板布局
            sidebar.visible = true
            sidebar.custom_minimum_size.x = 200
        ScreenSize.LARGE:
            # 桌面布局
            sidebar.visible = true
            sidebar.custom_minimum_size.x = 300
```

### 2. 比例布局

```gdscript
func setup_proportional_layout():
    var viewport = get_viewport().get_visible_rect().size
    
    # 左侧面板占 30%，右侧占 70%
    left_panel.size_flags_stretch_ratio = 3.0
    right_panel.size_flags_stretch_ratio = 7.0
```

---

## 🚀 性能优化

### 1. 减少重绘

```gdscript
# 静态 UI 禁用处理
static_label.process_mode = Node.PROCESS_MODE_DISABLED

# 隐藏时停止处理
func _on_visibility_changed():
    if not is_visible_in_tree():
        set_process(false)
        set_physics_process(false)
```

### 2. 对象池

```gdscript
# 对于频繁创建/销毁的 UI 元素（如伤害数字）
class UIPool:
    var pool: Array[Label] = []
    
    func get_label() -> Label:
        if pool.is_empty():
            var label = Label.new()
            label.add_theme_color_override("font_color", Color.RED)
            return label
        return pool.pop_back()
    
    func return_label(label: Label):
        label.visible = false
        pool.append(label)
```

---

## 📝 检查清单

创建 UI 时确认：

- [ ] 使用了合适的容器（VBox/HBox/Grid）
- [ ] 设置了正确的锚点预设
- [ ] 配置了 size_flags
- [ ] 没有硬编码绝对位置（>200px）
- [ ] 添加了必要的边距
- [ ] 测试了不同分辨率
- [ ] 使用了主题颜色和字体
- [ ] 添加了类型注解
- [ ] 遵循命名约定

---

## 🔗 相关链接

- [完整规范文档](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
- [Godot UI 教程](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [控制节点 API](https://docs.godotengine.org/en/stable/classes/class_control.html)

---

**提示**: 将此文件加入书签，开发时随时查阅！
