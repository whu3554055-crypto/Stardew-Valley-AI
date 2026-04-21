# UI 布局审计报告

**生成时间**: 2026-04-21T23:30:22

**问题总数**: 84

## 问题统计

| 问题类型 | 数量 |
|---------|------|
| HARDCODED_OFFSET | 60 |
| SCRIPT_HARDCODED_OFFSET | 24 |

---

## 🔴 硬编码 Offset 值 - 场景文件

### 📄 godot_client/scenes/main.tscn:34

**代码**:
```gdscript
offset_left = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/main.tscn:35

**代码**:
```gdscript
offset_top = 650.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/main.tscn:36

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/main.tscn:37

**代码**:
```gdscript
offset_bottom = 680.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:12

**代码**:
```gdscript
offset_right = 1280.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:13

**代码**:
```gdscript
offset_bottom = 720.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:51

**代码**:
```gdscript
offset_right = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:52

**代码**:
```gdscript
offset_bottom = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:100

**代码**:
```gdscript
offset_left = 650.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:102

**代码**:
```gdscript
offset_right = 1050.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:103

**代码**:
```gdscript
offset_bottom = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:144

**代码**:
```gdscript
offset_left = 1100.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:146

**代码**:
```gdscript
offset_right = 1260.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 godot_client/scenes/ui_manager.tscn:147

**代码**:
```gdscript
offset_bottom = 300.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/ai_config_ui.tscn:23

**代码**:
```gdscript
offset_right = 550.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/ai_config_ui.tscn:24

**代码**:
```gdscript
offset_bottom = 500.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/ai_config_ui.tscn:110

**代码**:
```gdscript
offset_top = 520.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/ai_config_ui.tscn:111

**代码**:
```gdscript
offset_right = 550.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/ai_config_ui.tscn:112

**代码**:
```gdscript
offset_bottom = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:372

**代码**:
```gdscript
offset_right = 540.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:399

**代码**:
```gdscript
offset_right = 240.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:408

**代码**:
```gdscript
offset_right = 480.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:409

**代码**:
```gdscript
offset_bottom = 320.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:440

**代码**:
```gdscript
offset_right = 320.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:441

**代码**:
```gdscript
offset_bottom = 220.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:446

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/main.tscn:447

**代码**:
```gdscript
offset_bottom = 440.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/recipe_picker.tscn:10

**代码**:
```gdscript
offset_right = 1080.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/recipe_picker.tscn:11

**代码**:
```gdscript
offset_bottom = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:30

**代码**:
```gdscript
offset_right = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:37

**代码**:
```gdscript
offset_left = 650.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:39

**代码**:
```gdscript
offset_right = 850.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:48

**代码**:
```gdscript
offset_right = 340.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:56

**代码**:
```gdscript
offset_right = 450.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:57

**代码**:
```gdscript
offset_bottom = 500.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:62

**代码**:
```gdscript
offset_top = 520.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:63

**代码**:
```gdscript
offset_right = 450.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:64

**代码**:
```gdscript
offset_bottom = 550.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:70

**代码**:
```gdscript
offset_left = 350.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:71

**代码**:
```gdscript
offset_top = 560.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:72

**代码**:
```gdscript
offset_right = 550.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/shop_ui.tscn:73

**代码**:
```gdscript
offset_bottom = 600.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_beach.tscn:76

**代码**:
```gdscript
offset_right = 780.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_beach.tscn:163

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_beach_stub.tscn:35

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_cave.tscn:72

**代码**:
```gdscript
offset_right = 860.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_cave.tscn:159

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_farm.tscn:148

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_farm.tscn:176

**代码**:
```gdscript
offset_right = 720.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_farm_stub.tscn:35

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_forest.tscn:76

**代码**:
```gdscript
offset_right = 760.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_forest.tscn:185

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_forest_stub.tscn:35

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_mine.tscn:90

**代码**:
```gdscript
offset_right = 760.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_mine.tscn:199

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_mine_stub.tscn:35

**代码**:
```gdscript
offset_right = 720.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_playground.tscn:49

**代码**:
```gdscript
offset_right = 520.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_town.tscn:128

**代码**:
```gdscript
offset_right = 720.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_town.tscn:243

**代码**:
```gdscript
offset_right = 400.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

### 📄 scenes/world/world_town_stub.tscn:35

**代码**:
```gdscript
offset_right = 640.0
```

**建议**: 使用锚点预设 (set_anchors_preset) + 容器系统代替硬编码偏移值

---

## 🔴 硬编码 Offset 值 - 脚本文件

### 📄 scenes/main.gd:425

**代码**:
```gdscript
hud_bg.offset_left = 4.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:426

**代码**:
```gdscript
hud_bg.offset_top = 4.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:454

**代码**:
```gdscript
q_bg.offset_top = 44.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:472

**代码**:
```gdscript
dim.offset_left = 0.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:473

**代码**:
```gdscript
dim.offset_top = 0.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:488

**代码**:
```gdscript
spot_lbl.offset_left = -300.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:489

**代码**:
```gdscript
spot_lbl.offset_top = 130.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:505

**代码**:
```gdscript
a_bg.offset_left = 8.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:506

**代码**:
```gdscript
a_bg.offset_top = 128.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:551

**代码**:
```gdscript
h.offset_left = 4.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:552

**代码**:
```gdscript
h.offset_top = 4.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:560

**代码**:
```gdscript
qb.offset_top = 44.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:567

**代码**:
```gdscript
ab.offset_left = 8.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scenes/main.gd:568

**代码**:
```gdscript
ab.offset_top = 128.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/player_creation_panel.gd:32

**代码**:
```gdscript
_panel.offset_left = -340.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/player_creation_panel.gd:33

**代码**:
```gdscript
_panel.offset_top = -280.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/player_journal_panel.gd:21

**代码**:
```gdscript
_panel.offset_left = -380.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/player_journal_panel.gd:22

**代码**:
```gdscript
_panel.offset_top = -300.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/world/perf_overlay.gd:12

**代码**:
```gdscript
_label.offset_left = 12.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/world/perf_overlay.gd:13

**代码**:
```gdscript
_label.offset_top = 680.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 scripts/world/world_region_banner.gd:14

**代码**:
```gdscript
margin.offset_top = 28.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 tools/ui_layout_checker.gd:261

**代码**:
```gdscript
panel.offset_left = 924.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 tools/ui_layout_checker.gd:262

**代码**:
```gdscript
panel.offset_top = 44.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---

### 📄 tools/ui_layout_checker.gd:272

**代码**:
```gdscript
panel.offset_top = 44.0
```

**建议**: 使用 set_anchors_preset() 和 size_flags 代替硬编码 offset

---


## 🔧 修复指南

### 1. 硬编码 Offset 修复示例

#### ❌ 错误做法
```gdscript
panel.offset_left = 924.0
panel.offset_top = 44.0
panel.offset_right = 1276.0
panel.offset_bottom = 632.0
```

#### ✅ 正确做法
```gdscript
# 方法 1: 使用锚点预设
panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
panel.offset_left = -352.0  # 从右边缘向左偏移
panel.offset_top = 44.0
panel.offset_right = -4.0
panel.offset_bottom = 632.0

# 方法 2: 使用容器自动布局
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)
parent.add_child(vbox)

var panel = Panel.new()
panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
vbox.add_child(panel)
```

### 2. 响应式布局最佳实践

```gdscript
# 监听视口变化
get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized():
    var viewport_size = get_viewport().get_visible_rect().size
    
    # 基于屏幕比例计算尺寸
    var panel_width = viewport_size.x * 0.3  # 占屏幕宽度 30%
    var panel_height = viewport_size.y * 0.5  # 占屏幕高度 50%
    
    # 更新 UI
    my_panel.custom_minimum_size = Vector2(panel_width, panel_height)
```

### 3. 容器选择指南

- **垂直列表**: `VBoxContainer`
- **水平排列**: `HBoxContainer`
- **网格布局**: `GridContainer`
- **滚动区域**: `ScrollContainer`
- **居中对齐**: `CenterContainer`
- **添加边距**: `MarginContainer`

### 4. 批量修复脚本

对于大量需要修复的场景，可以使用以下 GDScript 辅助函数：

```gdscript
func convert_to_responsive_layout(control: Control, preset: int):
    control.set_anchors_preset(preset)
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.size_flags_vertical = Control.SIZE_EXPAND_FILL
```

---

## 📚 参考资源

- [Godot UI 系统文档](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [控制节点大小调整](https://docs.godotengine.org/en/stable/tutorials/ui/controlling_3d_gui.html)
- [本项目 Godot 工业标准](res://docs/GODOT_INDUSTRIAL_STANDARDS.md)
