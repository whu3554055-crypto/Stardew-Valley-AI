# 高级多智能体 NPC 系统

## 概述

这是一个企业级多智能体 NPC 系统，实现了：
- ✅ **并行执行** - 多个 NPC 同时思考和行动
- ✅ **NPC 间互动** - NPC 可以自主交流、建立关系
- ✅ **环境感知** - NPC 感知时间、天气、位置并做出反应
- ✅ **自主行为** - NPC 根据个性、日程、需求自动行动
- ✅ **深度个性化** - 每个 NPC 有独特的背景、价值观、恐惧、梦想
- ✅ **流畅对话** - 结构化响应格式（对话+动作+情绪+思考）
- ✅ **社交网络** - NPC 之间有复杂的关系网

## 架构设计

### 核心组件

```
┌─────────────────────────────────────────┐
│   AdvancedAIAgentManager (中央控制器)    │
│  - 管理所有 AI 智能体                     │
│  - 并行请求处理（限流3个并发）            │
│  - 上下文构建和提示词工程                 │
│  - NPC 社交网络管理                      │
└──────────────┬──────────────────────────┘
               │
     ┌─────────┼─────────┐
     │         │         │
┌────▼────┐ ┌──▼──┐ ┌───▼────┐
│ Agent 1 │ │Agent2│ │ Agent 3│  (并行执行)
│Pierre   │ │Abigail│ │ Lewis │
└────┬────┘ └──┬───┘ └───┬────┘
     │          │          │
     └──────────┴──────────┘
                │
     ┌──────────▼──────────┐
     │  NPCBehaviorController │
     │  - 自主决策引擎        │
     │  - 日程管理           │
     │  - 行为模式切换       │
     └─────────────────────┘
```

### 不是单一智能体！

**重要**：系统采用 **分布式智能体架构**
- 每个 NPC = 独立的 AI 智能体实例
- 有自己的记忆、情绪、个性、目标
- 可以并行运行（最多 3 个并发 LLM 请求）
- NPC 之间可以互相通信

## 高级特性详解

### 1. 深度个性化系统

每个 NPC 有完整的心理档案：

```gdscript
ai_config = {
    "name": "Pierre",
    "age": "42",
    "occupation": "General Store Owner",
    
    "personality": {
        "traits": ["friendly", "business-minded", "family-oriented"],
        "values": ["family", "hard work", "community", "honesty"],
        "fears": ["losing family", "business failure", "change"],
        "dreams": ["expand store", "daughter's happiness", "town prosperity"],
        "quirks": ["counts inventory daily", "hums when happy"]
    },
    
    "backstory": "Pierre runs the local general store...",
    "life_context": "Father of two, husband, businessman..."
}
```

### 2. 结构化响应格式

AI 返回的不只是对话，而是完整的行为包：

```
[DIALOGUE: Oh hey! Beautiful day for farming!]
[ACTION: Wiping sweat from forehead, leaning on hoe]
[EMOTION: Cheerful, slightly tired]
[THOUGHT: I hope the crops grow faster this season...]
```

系统会解析这四个部分：
- **DIALOGUE**: 实际说出的话
- **ACTION**: 物理动作（行走、工作、挥手等）
- **EMOTION**: 当前情绪状态
- **THOUGHT**: 内心独白（不显示给玩家）

### 3. NPC 间自主互动

NPC 会自动与其他 NPC 交流：

```gdscript
# 行为控制器每 10 秒做一次决策
if social_need > 0.7 and nearby_npcs.size() > 0:
    # 30% 几率发起社交
    initiate_npc_interaction(npc1_id, npc2_id, "casual")
```

**示例场景**：
- Pierre 和 Abigail 在商店聊天（父女关系）
- Lewis 巡视城镇时与路过的 NPC 交谈
- NPC 们会根据关系讨论不同话题

### 4. 并行执行引擎

```
时间线:
T0: Pierre 与玩家对话  (请求 1)
T1: Abigail 决定去探险  (请求 2)
T2: Lewis 与 Pierre 聊天 (请求 3)
T3: 等待队列...
T4: 请求 1 完成 → 处理队列下一个
```

**性能优化**：
- 最大 3 个并发请求（可配置）
- 优先级队列（玩家互动 > NPC 互动 > 自言自语）
- 响应缓存（相同上下文直接返回）

### 5. 环境感知系统

NPC 知道：
- ⏰ **时间** - 早上/下午/晚上，影响活动
- 🌤️ **天气** - 晴天/雨天/雪天，影响心情
- 📅 **季节** - 春/夏/秋/冬，影响话题
- 📍 **位置** - 在商店/森林/山区，影响行为
- 👥 **周围谁在** - 玩家/NPC，影响对话

**示例**：
```
下雨天 + 在户外 → "哎呀，没带伞..." → 寻找遮蔽处
晚上 + 在家 → "该休息了" → 降低能量消耗
春天 + 农场 → "播种的好时节！" → 谈论农业
```

### 6. 日程系统

每个 NPC 有每日计划：

```gdscript
daily_schedule = {
    6.0: {"action": "wake_up", "location": "home"},
    8.0: {"action": "open_shop", "location": "store"},
    12.0: {"action": "lunch_break", "location": "home"},
    18.0: {"action": "close_shop", "location": "store"},
    20.0: {"action": "family_time", "location": "home"},
    22.0: {"action": "sleep", "location": "home"}
}
```

系统会自动：
- 根据时间切换到对应活动
- 移动到目标位置
- 改变行为和对话主题

### 7. 社交网络

NPC 之间有预定义的关系：

```gdscript
relationships = {
    "pierre_abigail": {
        "type": "parent_child",
        "strength": 0.9,
        "history": "Father and daughter. Protective but clashes over adventures."
    },
    "pierre_lewis": {
        "type": "business_civic",
        "strength": 0.7,
        "history": "Respectful business relationship."
    }
}
```

影响：
- 对话语气（亲密 vs 正式）
- 互动频率
- 话题选择
- 情绪反应强度

### 8. 群组对话

支持多人同时对话：

```gdscript
AdvancedAIAgentManager.start_group_conversation(
    ["pierre", "abigail", "lewis"],
    "Upcoming festival plans",
    "town_square"
)
```

每个 NPC 会：
- 听到其他人的发言
- 根据个性回应
- 记住对话内容

## 使用指南

### 创建高级 NPC

```gdscript
# 1. 创建场景文件 (npc_yourname.tscn)
[node name="YourNPC" type="CharacterBody2D"]
script = ExtResource("1_advanced_npc")
npc_id = "your_unique_id"
npc_name = "Display Name"
use_ai_dialogue = true

# 个性
personality_traits = ["curious", "intelligent", "mysterious"]
values = ["knowledge", "truth", "solitude"]
fears = ["ignorance", "crowds"]
dreams = ["discover ancient secrets"]
quirks = ["talks to books", "wears glasses"]

# 背景
backstory = "A scholar who studies ancient texts..."
occupation = "Librarian"
age = "35"

# 行为
speech_style = "formal"
interests = ["reading", "history", "mysteries"]

# 日程
daily_schedule = {
    7.0: {"action": "open_library", "location": "library"},
    12.0: {"action": "read", "location": "library"},
    18.0: {"action": "close_library", "location": "library"}
}
```

### 自定义说话风格

可用的 `speech_style`：

| 风格 | 特点 | 示例 |
|------|------|------|
| `casual` | 随意亲切 | "Hey there! What's up?" |
| `formal` | 正式礼貌 | "Good morning. How may I assist you?" |
| `shy` | 害羞犹豫 | "Um... hello... if you don't mind..." |
| `energetic` | 充满活力 | "Wow! Amazing! Let's go!" |
| `mysterious` | 神秘cryptic | "The stars whisper secrets..." |
| `gruff` | 粗鲁直接 | "What do you want?" |
| `warm` | 温暖关怀 | "Dear, are you keeping warm?" |
| `sarcastic` | 讽刺幽默 | "Oh great, another visitor." |

### 触发 NPC 互动

```gdscript
# 手动触发两个 NPC 对话
NPCBehaviorController.force_interaction("pierre", "abigail", "family_discussion")

# 启动群组对话
AdvancedAIAgentManager.start_group_conversation(
    ["pierre", "abigail", "caroline"],
    "Family dinner plans",
    "home"
)
```

### 监听 NPC 行为

```gdscript
func _ready():
    # 连接信号
    AdvancedAIAgentManager.npc_interaction_completed.connect(_on_npc_chat)
    AdvancedAIAgentManager.group_conversation_updated.connect(_on_group_chat)

func _on_npc_chat(npc1, npc2, summary):
    print("%s and %s finished talking!" % [npc1, npc2])

func _on_group_chat(conv_id, messages):
    for msg in messages:
        print("%s: %s" % [msg.speaker, msg.content.dialogue])
```

## 性能优化

### 并发控制

```gdscript
# 在 ai_config.json 中配置
{
    "max_concurrent_requests": 3,  # 同时处理的请求数
    "max_tokens": 300,              # 响应长度限制
    "temperature": 0.85             # 创意程度
}
```

### 缓存策略

- 相同上下文 → 直接返回缓存
- TTL: 60 秒
- 减少 80% 的 API 调用

### 优先级系统

```
优先级 10: 玩家互动（立即处理）
优先级 5:  NPC 间互动
优先级 2:  自发行为
优先级 1:  环境反应
```

## 调试技巧

### 查看 NPC 状态

```gdscript
# 打印所有 NPC 状态
var states = NPCBehaviorController.get_all_npc_states()
for npc_id in states:
    var state = states[npc_id]
    print("%s: Action=%s, Energy=%.1f, Mode=%d" % [
        npc_id, state.current_action, state.energy, state.mode
    ])
```

### 测试并行执行

```gdscript
# 同时让 3 个 NPC 说话
AdvancedAIAgentManager.generate_dialogue_async("pierre", context1, callback1)
AdvancedAIAgentManager.generate_dialogue_async("abigail", context2, callback2)
AdvancedAIAgentManager.generate_dialogue_async("lewis", context3, callback3)

# 观察它们并行执行（最多 3 个并发）
```

### 监控请求队列

```gdscript
print("Active requests: ", AdvancedAIAgentManager.active_requests)
print("Queued requests: ", AdvancedAIAgentManager.request_queue.size())
```

## 扩展建议

### 添加新特性

1. **情感记忆** - NPC 记住玩家的行为并产生好恶
2. **谣言系统** - NPC 之间传播信息
3. **动态关系** - 关系随互动自动变化
4. **任务系统** - NPC 主动给玩家任务
5. **经济模拟** - NPC 有金钱、购物行为

### 集成现有系统

```gdscript
# 与记忆系统集成
NPCMemorySystem.record_event("pierre", "Had deep conversation with player", 0.8)

# 与情绪系统集成
NPCEmotionSystem.trigger_emotion("abigail", "excited_about_adventure")

# 与天气系统集成
WeatherSystem.weather_changed.connect(_on_weather_change)
```

## 故障排除

### NPC 不说话？

1. 检查 Ollama 是否运行
2. 确认 `use_ai_dialogue = true`
3. 查看 Godot 控制台错误
4. 检查并发限制（默认 3 个）

### 响应太慢？

1. 降低 `max_tokens` (300 → 150)
2. 降低 `temperature` (0.85 → 0.7)
3. 使用更小的模型
4. 启用 GPU 加速

### NPC 不动？

1. 检查是否有日程安排
2. 确认 `target_position` 设置
3. 查看 `BehaviorMode` 是否正确
4. 检查碰撞体设置

## 完整示例

查看以下文件获得完整参考：
- `autoload/advanced_ai_manager.gd` - 核心管理器
- `autoload/npc_behavior_controller.gd` - 行为控制
- `scripts/advanced_npc.gd` - NPC 脚本
- `scenes/npc_pierre.tscn` - 示例 NPC

---

**这就是一个真正的多智能体系统！** 🎉

每个 NPC 都是独立的 AI，可以：
- 独立思考
- 自主行动
- 互相交流
- 感知环境
- 建立关系
- 并行执行
