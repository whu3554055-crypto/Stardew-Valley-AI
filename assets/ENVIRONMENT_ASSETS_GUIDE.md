# 环境素材使用指南

本文档说明如何在 Godot 项目中使用新生成的环境素材。

## 素材分类

### 1. 城镇环境 (`sprites/environment/town/`)

**用途**: 构建小镇街道和公共区域

```gdscript
# 示例：创建街道场景
var cobblestone = preload("res://assets/sprites/environment/town/cobblestone_tile.png")
var street_lamp = preload("res://assets/sprites/environment/town/street_lamp.png")
var bench = preload("res://assets/sprites/environment/town/bench.png")
var trash_can = preload("res://assets/sprites/environment/town/trash_can.png")

# 铺设街道
for x in range(20):
    for y in range(15):
        var tile = Sprite2D.new()
        tile.texture = cobblestone
        tile.position = Vector2(x * 64, y * 64)
        add_child(tile)

# 添加路灯（每隔一段距离）
for x in range(0, 20, 4):
    var lamp = Sprite2D.new()
    lamp.texture = street_lamp
    lamp.position = Vector2(x * 64, 2 * 64)
    add_child(lamp)
```

**可用素材**:
- `cobblestone_tile.png` - 鹅卵石地面（64x64瓦片）
- `street_lamp.png` - 路灯（48x96，带发光效果）
- `bench.png` - 长椅（80x40）
- `trash_can.png` - 垃圾桶（32x48）
- `flower_pot.png` - 花盆（32x32）
- `mailbox.png` - 邮箱（24x48）
- `sign_post.png` - 指示牌（16x64）
- `fence_wood.png` / `fence_stone.png` - 木/石栅栏（64x32）
- `planter_box.png` - 种植箱（64x32）

---

### 2. 绿植装饰 (`sprites/environment/greenery/`)

**用途**: 增添自然元素到任何场景

```gdscript
# 随机放置灌木丛
var bush_small = preload("res://assets/sprites/environment/greenery/bush_small.png")
var grass_clump = preload("res://assets/sprites/environment/greenery/grass_clump.png")

for i in range(10):
    var bush = Sprite2D.new()
    bush.texture = bush_small
    bush.position = Vector2(randi() % 800, randi() % 600)
    # 随机缩放增加变化
    var scale_factor = 0.8 + randf() * 0.4
    bush.scale = Vector2(scale_factor, scale_factor)
    add_child(bush)
```

**可用素材**:
- `bush_small.png` - 小灌木（48x48）
- `bush_large.png` - 大灌木（80x64）
- `hedge.png` - 绿篱（64x48）
- `tree_sapling.png` - 树苗（32x64）
- `grass_clump.png` - 草丛（32x32）
- `fern.png` - 蕨类植物（40x48）

---

### 3. 河流与水体 (`sprites/environment/water/`)

**用途**: 创建河流、池塘、瀑布等水景

```gdscript
# 创建河流
var water_tile = preload("res://assets/sprites/environment/water/water_tile.png")
var rock = preload("res://assets/sprites/environment/water/rock_medium.png")
var lilypad = preload("res://assets/sprites/environment/water/lilypad.png")

# 铺设河床
for x in range(5, 15):
    for y in range(20):
        var water = Sprite2D.new()
        water.texture = water_tile
        water.position = Vector2(x * 64, y * 64)
        river_layer.add_child(water)

# 添加河中石头
for i in range(5):
    var stone = Sprite2D.new()
    stone.texture = rock
    stone.position = Vector2((7 + i) * 64, randi() % 10 * 64)
    river_layer.add_child(stone)

# 添加睡莲
for i in range(8):
    var pad = Sprite2D.new()
    pad.texture = lilypad
    pad.position = Vector2((6 + randi() % 8) * 64, randi() % 15 * 64)
    river_layer.add_child(pad)
```

**动画提示**: 对 `water_tile.png` 添加着色器实现波浪动画：

```glsl
// water_shader.gdshader
shader_type canvas_item;

uniform float wave_speed = 2.0;
uniform float wave_height = 0.05;

void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 10.0 + TIME * wave_speed) * wave_height;
    COLOR = texture(TEXTURE, uv);
}
```

**可用素材**:
- `water_tile.png` - 水瓦片（64x64，带动画波纹）
- `rock_small/medium/large.png` - 石头（3种尺寸）
- `seaweed.png` - 水草（24x48）
- `driftwood.png` - 浮木（64x24）
- `bubble.png` - 气泡（16x16，可动画上浮）
- `lilypad.png` - 睡莲（40x40）
- `fish_small.png` - 小鱼（24x12，可动画游动）
- `bridge_wood.png` / `bridge_stone.png` - 木桥/石桥（128x48）
- `rapids.png` - 激流（64x64）
- `waterfall.png` - 瀑布（48x96）

---

### 4. 森林环境 (`sprites/environment/forest/`)

**用途**: 构建森林区域

```gdscript
# 创建森林场景
var tree_pine = preload("res://assets/sprites/environment/forest/tree_pine.png")
var tree_oak = preload("res://assets/sprites/environment/forest/tree_oak.png")
var mushroom = preload("res://assets/sprites/environment/forest/mushroom_red.png")

# 分层渲染实现视差效果
var back_layer = ParallaxLayer.new()
var mid_layer = ParallaxLayer.new()
var front_layer = ParallaxLayer.new()

# 背景树（较小，移动慢）
for i in range(8):
    var tree = Sprite2D.new()
    tree.texture = tree_pine if randi() % 2 == 0 else tree_oak
    tree.position = Vector2(i * 120 + randi() % 40, 100 + randi() % 50)
    tree.scale = Vector2(0.7, 0.7)
    back_layer.add_child(tree)

# 前景蘑菇和花草
for i in range(15):
    var mush = Sprite2D.new()
    mush.texture = mushroom
    mush.position = Vector2(randi() % 800, 400 + randi() % 100)
    front_layer.add_child(mush)
```

**可用素材**:
- `tree_pine.png` - 松树（80x120）
- `tree_oak.png` - 橡树（96x110）
- `tree_stump.png` - 树桩（48x32）
- `mushroom_red.png` - 红蘑菇（24x24，带白点）
- `mushroom_brown.png` - 棕蘑菇（20x20）
- `flower_wild.png` - 野花粉色（24x32）
- `flower_blue.png` - 野花蓝色（24x28）
- `rabbit.png` - 兔子（32x24，可动画跳跃）
- `squirrel.png` - 松鼠（28x24，可动画爬树）
- `bird.png` - 小鸟（20x16，可动画飞行）
- `butterfly.png` - 蝴蝶（16x16，可动画飞舞）
- `log_fallen.png` - 倒木（96x24）
- `berry_bush.png` - 浆果丛（48x48）

---

### 5. 环境音效 (`audio/ambience_extended/`)

**用途**: 增强沉浸感的背景音

```gdscript
# 根据场景播放环境音
var audio_player = AudioStreamPlayer.new()
add_child(audio_player)

func play_river_sound():
    audio_player.stream = load("res://assets/audio/ambience_extended/river_flow.wav")
    audio_player.volume_db = -15
    audio_player.play()

func play_forest_morning():
    audio_player.stream = load("res://assets/audio/ambience_extended/birds_morning.wav")
    audio_player.volume_db = -20
    audio_player.play()

# 天气变化时切换音效
func set_weather(weather: String):
    match weather:
        "rain":
            audio_player.stream = load("res://assets/audio/ambience_extended/rain_light.wav")
        "storm":
            audio_player.stream = load("res://assets/audio/ambience_extended/rain_heavy.wav")
        _:
            audio_player.stream = load("res://assets/audio/ambience_extended/birds_morning.wav")
    audio_player.play()
```

**可用音效**:
- `river_flow.wav` - 河流水声（30秒循环）
- `stream_gentle.wav` - 轻柔溪流（30秒循环）
- `birds_morning.wav` - 清晨鸟鸣（45秒循环）
- `birds_forest.wav` - 森林鸟叫（45秒循环）
- `rain_light.wav` - 小雨声（60秒循环）
- `rain_heavy.wav` - 大雨声（60秒循环）
- `wind_trees.wav` - 风吹树叶（45秒循环）
- `crickets_night.wav` - 夜晚蟋蟀（60秒循环）
- `frogs_pond.wav` - 池塘蛙鸣（30秒循环）
- `leaves_rustle.wav` - 树叶沙沙（20秒循环）

---

## 场景构建示例

### 完整的小镇广场

```gdscript
# town_square.tscn
extends Node2D

@onready var tilemap = $TileMap
@onready var decorations = $Decorations
@onready var ambient_audio = $AmbientAudio

func _ready():
    build_town_square()
    play_ambient_sound()

func build_town_square():
    # 铺设鹅卵石地面
    var cobblestone = preload("res://assets/sprites/environment/town/cobblestone_tile.png")

    # 添加中央喷泉（用水瓦片模拟）
    var water = preload("res://assets/sprites/environment/water/water_tile.png")

    # 周围放置长椅
    var bench = preload("res://assets/sprites/environment/town/bench.png")
    for i in range(4):
        var b = Sprite2D.new()
        b.texture = bench
        b.position = Vector2(200 + i * 100, 400)
        decorations.add_child(b)

    # 添加花坛
    var flower_pot = preload("res://assets/sprites/environment/town/flower_pot.png")
    var flowers = preload("res://assets/sprites/environment/forest/flower_wild.png")

func play_ambient_sound():
    ambient_audio.stream = load("res://assets/audio/ambience_extended/birds_morning.wav")
    ambient_audio.volume_db = -18
    ambient_audio.play()
```

---

## 性能优化建议

1. **使用 TileMap**: 对于大量重复元素（地面瓦片），使用 Godot 的 TileMap 节点
2. **对象池**: 对动态元素（气泡、蝴蝶）使用对象池避免频繁创建销毁
3. **视锥剔除**: 大地图只渲染屏幕内的元素
4. **LOD**: 远处的树使用较小的精灵图
5. **音频淡入淡出**: 切换环境音时使用渐变避免突兀

```gdscript
# 音频淡入示例
func fade_in_audio(player: AudioStreamPlayer, duration: float = 2.0):
    var tween = create_tween()
    player.volume_db = -40
    player.play()
    tween.tween_property(player, "volume_db", -15, duration)
```

---

## 下一步

这些素材现在可以用于：
1. 构建 Godot 场景原型
2. 测试不同区域的视觉效果
3. 根据实际游戏调整素材大小和风格
4. 替换为最终美术资源时保持相同命名规范
