# Godot 工业标准规范

本文档定义了本项目遵循的 Godot 引擎开发工业标准，确保代码质量、可维护性和跨分辨率兼容性。

## 目录
- [UI 布局标准](#ui-布局标准)
- [场景架构标准](#场景架构标准)
- [代码组织标准](#代码组织标准)
- [资源管理标准](#资源管理标准)
- [性能优化标准](#性能优化标准)

---

## UI 布局标准

### 1. 锚点和容器使用原则

#### ✅ 正确做法
```gdscript
# 使用锚点预设 + 容器系统
var panel = Panel.new()
panel.set_anchors_preset(Control.PRESET_FULL_RECT)  # 全屏填充
panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

# 使用容器自动布局
var vbox = VBoxContainer.new()
vbox.add_theme_constant_override("separation", 8)  # 元素间距
panel.add_child(vbox)

# 子元素自动扩展
var button = Button.new()
button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
vbox.add_child(button)
```

#### ❌ 错误做法
```gdscript
# 避免硬编码像素值
panel.offset_left = 924.0
panel.offset_top = 44.0
panel.offset_right = 1276.0
panel.offset_bottom = 632.0
```

### 2. 响应式布局策略

#### 优先级顺序
1. **锚点预设 (Anchors Preset)** - 定义相对位置
2. **尺寸标志 (Size Flags)** - 控制扩展行为
3. **容器 (Containers)** - 自动管理子节点布局
4. **边距 (Margins/Offsets)** - 仅在必要时微调

#### 常用锚点预设
```gdscript
Control.PRESET_FULL_RECT          # 填满父节点
Control.PRESET_CENTER             # 居中
Control.PRESET_TOP_LEFT           # 左上角
Control.PRESET_TOP_RIGHT          # 右上角
Control.PRESET_BOTTOM_LEFT        # 左下角
Control.PRESET_BOTTOM_RIGHT       # 右下角
Control.PRESET_HCENTER_WIDE       # 水平居中，全宽
Control.PRESET_VCENTER_HEIGHT     # 垂直居中，全高
```

### 3. 容器选择指南

| 容器类型 | 用途 | 示例 |
|---------|------|------|
| `VBoxContainer` | 垂直排列 | 菜单列表、表单 |
| `HBoxContainer` | 水平排列 | 工具栏、按钮组 |
| `GridContainer` | 网格布局 | 物品栏、技能树 |
| `MarginContainer` | 添加边距 | 面板内边距 |
| `CenterContainer` | 居中对齐 | 弹窗、提示框 |
| `ScrollContainer` | 滚动区域 | 长列表、日志 |
| `TabContainer` | 标签页 | 设置面板、多页UI |

### 4. UI 主题和样式

```gdscript
# 使用 Theme 统一管理样式
var theme = Theme.new()
theme.set_color("font_color", "Label", Color.WHITE)
theme.set_font_size("font_size", "Label", 16)

# 或使用 StyleBoxFlat
var style = StyleBoxFlat.new()
style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
style.set_border_width_all(2)
style.border_color = Color(0.4, 0.4, 0.4)
style.corner_radius_top_left = 8
style.corner_radius_top_right = 8
```

---

## 场景架构标准

### 1. 场景组织原则

#### 推荐的目录结构
```
scenes/
├── main.tscn                  # 主场景（游戏入口）
├── world/                     # 世界场景
│   ├── world_farm.tscn
│   ├── world_town.tscn
│   └── ...
├── ui/                        # UI 场景
│   ├── inventory_ui.tscn
│   ├── dialogue_box.tscn
│   └── ...
├── characters/                # 角色场景
│   ├── player.tscn
│   ├── npc_base.tscn
│   └── ...
└── systems/                   # 系统场景
    ├── weather_overlay.tscn
    └── ...
```

### 2. 单例 (Autoload) 使用规范

#### ✅ 正确使用
```gdscript
# 仅用于全局状态管理和跨场景通信
extends Node

# GameManager - 游戏状态
# WorldRouter - 场景切换
# InventoryManager - 背包数据
# QuestSystem - 任务系统
```

#### ❌ 避免滥用
- 不要在 Autoload 中放置场景特定逻辑
- 不要将 UI 节点放入 Autoload
- 避免在 Autoload 中直接操作场景节点

### 3. 信号通信模式

```gdscript
# 使用信号解耦组件
signal player_moved(position: Vector2)
signal item_collected(item_id: String)
signal quest_completed(quest_id: String)

# 连接信号
player.player_moved.connect(_on_player_moved)
inventory.item_collected.connect(_on_item_collected)
```

---

## 代码组织标准

### 1. GDScript 文件结构

```gdscript
extends CharacterBody2D
class_name Player

# === 导出变量（Inspector 可见）===
@export var speed: float = 100.0
@export_group("Combat")
@export var attack_power: int = 10

# === 常量 ===
const MAX_HEALTH := 100
const JUMP_FORCE := -300.0

# === 枚举 ===
enum State { IDLE, WALKING, JUMPING }

# === 信号 ===
signal health_changed(new_health: int)
signal died

# === 节点引用（@onready）===
@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer

# === 成员变量 ===
var current_state := State.IDLE
var health := MAX_HEALTH

# === 生命周期方法 ===
func _ready():
    _initialize()

func _process(delta):
    _handle_input()
    _update_movement(delta)

# === 公共方法 ===
func take_damage(amount: int):
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()

# === 私有方法 ===
func _initialize():
    add_to_group("player")

func _handle_input():
    # 输入处理逻辑
    pass

func _update_movement(delta):
    # 移动逻辑
    pass
```

### 2. 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 类名 | PascalCase | `PlayerController`, `InventoryManager` |
| 函数/方法 | snake_case | `take_damage()`, `_update_ui()` |
| 变量 | snake_case | `player_health`, `max_speed` |
| 常量 | UPPER_SNAKE_CASE | `MAX_ITEMS`, `DEFAULT_SPEED` |
| 信号 | snake_case | `item_collected`, `level_up` |
| 私有方法 | 前缀 `_` | `_internal_helper()` |

### 3. 类型注解

```gdscript
# 始终使用类型注解
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

var player_position: Vector2 = Vector2.ZERO
var inventory_items: Array[String] = []
var npc_data: Dictionary = {}
```

---

## 资源管理标准

### 1. 资源预加载 vs 延迟加载

```gdscript
# 频繁使用的资源 - 预加载
const PLAYER_TEXTURE := preload("res://assets/sprites/player.png")

# 偶尔使用的资源 - 延迟加载
func show_dialogue():
    var dialogue_scene = load("res://scenes/ui/dialogue_box.tscn")
    var instance = dialogue_scene.instantiate()
    add_child(instance)
```

### 2. 资源路径规范

```
assets/
├── sprites/           # 精灵图
│   ├── characters/
│   ├── environment/
│   └── ui/
├── audio/             # 音频
│   ├── music/
│   ├── sfx/
│   └── voice/
├── tilemaps/          # 瓦片地图
├── fonts/             # 字体
├── shaders/           # 着色器
└── data/              # 数据文件
    ├── items.json
    └── quests.json
```

---

## 性能优化标准

### 1. Y-Sort 优化

```gdscript
# 在 TileMap 或大场景中启用 Y-Sort
tilemap.y_sort_enabled = true

# 为需要排序的节点设置 z_index
sprite.z_index = 10
```

### 2. 对象池模式

```gdscript
# 对于频繁创建/销毁的对象（子弹、粒子）
class ObjectPool:
    var pool: Array[Node] = []
    var scene: PackedScene
    
    func get_instance() -> Node:
        if pool.is_empty():
            return scene.instantiate()
        return pool.pop_back()
    
    func return_instance(instance: Node):
        instance.queue_free()  # 或隐藏重用
        pool.append(instance)
```

### 3. 视锥剔除

```gdscript
# 使用 VisibleOnScreenNotifier2D
func _on_visibility_changed():
    if not is_visible_in_tree():
        set_process(false)  # 暂停处理
```

---

## 调试和测试标准

### 1. 条件编译

```gdscript
func _debug_draw():
    if OS.is_debug_build():
        # 仅调试版本执行
        draw_collision_boxes()
```

### 2. 日志规范

```gdscript
print("[Player] Health: ", health)                    # 一般信息
push_warning("[Player] Low health: ", health)         # 警告
push_error("[Player] Invalid state: ", current_state) # 错误
```

---

## 版本控制和协作

### 1. .gitignore 配置

确保以下文件被忽略：
```
.godot/editor/
.godot/imported/
*.import
dump.rdb
```

### 2. 提交规范

```
feat: 添加新的农场升级系统
fix: 修复传送门场景切换失败
docs: 更新 UI 布局标准文档
refactor: 重构玩家控制器代码
perf: 优化 TileMap 渲染性能
```

---

## 检查清单

在提交代码前，请确认：

- [ ] UI 使用锚点和容器，无硬编码像素值
- [ ] 所有变量和函数有类型注解
- [ ] 遵循命名约定
- [ ] 添加了必要的注释
- [ ] 没有内存泄漏（使用 `queue_free()` 而非 `free()`）
- [ ] 信号正确连接和断开
- [ ] 性能关键路径已优化
- [ ] 调试代码已移除或条件编译

---

## 参考资源

- [Godot 官方文档 - UI 系统](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [Godot 最佳实践](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
