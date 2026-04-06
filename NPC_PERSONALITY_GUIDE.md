# NPC 个性化系统 - 喜好、口头禅、习惯动作

## 概述

每个 NPC 现在都有丰富的个性化特征，让他们更像真实的人：

- ✅ **独特的喜好** - 喜欢/讨厌的礼物、食物、活动、话题
- ✅ **口头禅** - 根据情境自动说出的标志性话语
- ✅ **习惯动作** - 无聊、开心、思考时的习惯性行为
- ✅ **说话风格** - 用词偏好、语气特征
- ✅ **特殊反应** - 对特定事件的独特回应
- ✅ **情绪对话变化** - 不同心情下说话方式不同

## 系统架构

```
NPCPersonalitySystem (中央数据库)
    ↓
每个 NPC 的个性档案:
├── catchphrases (口头禅)
│   ├── greeting (问候)
│   ├── agreement (同意)
│   ├── excitement (兴奋)
│   ├── concern (担忧)
│   └── filler (填充词)
├── preferences (喜好)
│   ├── gifts (礼物喜好等级)
│   ├── foods (食物偏好)
│   ├── activities (活动喜好)
│   ├── topics (话题偏好)
│   └── environment (环境偏好)
├── habits (习惯动作)
│   ├── when_happy (开心时)
│   ├── when_worried (担心时)
│   ├── when_thinking (思考时)
│   └── idle (空闲时)
├── special_reactions (特殊反应)
└── speech_patterns (说话模式)
```

## Pierre 的完整个性

### 🗣️ 口头禅

| 情境 | 口头禅 |
|------|--------|
| **问候** | "Welcome to my store!" / "Ah, a valued customer!" |
| **同意** | "Absolutely!" / "Indeed indeed!" / "That's right!" |
| **担忧** | "Oh dear..." / "I do hope..." / "Let's see what we can do..." |
| **兴奋** | "Wonderful!" / "Splendid!" / "How marvelous!" |
| **填充词** | "you see" / "as it were" / "if you will" |

**示例对话**：
```
Pierre: "Welcome to my store! *polishes counter* 
         We have the finest seeds in the valley, you see. 
         Absolutely top quality!"
```

### ❤️ 喜好

**礼物**：
- 😍 最爱：金条、钻石、烹饪食谱（+80 关系点）
- 🙂 喜欢：防风草、青豆、花椰菜（+45 关系点）
- 😐 无感：木材、石头（+20 关系点）
- 😕 不喜欢：怪物战利品、粘液（-20 关系点）
- 😡 讨厌：垃圾、破碎眼镜（-50 关系点）

**食物**：
- 最爱：披萨、意面、面包
- 爱喝：咖啡、果汁
- 讨厌：野辣根、蒲公英

**活动**：
- 享受：购物、农业、家庭时光
- 避免：战斗、采矿、熬夜

**话题**：
- 爱聊：生意、家庭、社区、农业
- 讨厌：JojaMart、危险、丑闻

**环境**：
- 最爱天气：晴天
- 最爱时间：早上
- 最爱地点：商店

### 🎭 习惯动作

| 情绪 | 习惯动作 |
|------|----------|
| **开心时** | 擦拭柜台、整理货架、哼着小曲 |
| **担心时** | 擦额头、检查账本、来回踱步 |
| **思考时** | 抚摸胡子、调整围裙、轻敲下巴 |
| **空闲时** | 整理物品、扫地、检查库存 |

### 💬 特殊反应

```
看到下雨 → "The crops will love this rain!"
看到玩家种田 → "Keep up the good work! The valley needs farmers like you!"
提到 Abigail → "Abigail? She's... quite the character. *sighs*"
提到生意 → "Business is good! Well, most days anyway..."
```

### 📝 说话风格

```gdscript
speech_patterns = {
    "uses_exclamations": true,       // 常用感叹号
    "formal_level": 0.3,             // 不太正式
    "warmth_level": 0.9,             // 非常温暖
    "common_words": ["dear", "valued", "wonderful", "splendid"],
    "avoid_words": ["bad", "terrible", "awful"]
}
```

---

## Abigail 的完整个性

### 🗣️ 口头禅

| 情境 | 口头禅 |
|------|--------|
| **问候** | "Hey!" / "Yo!" / "What's up adventurer?" |
| **同意** | "Heck yeah!" / "Totally!" / "For sure!" |
| **兴奋** | "AWESOME!!!" / "SO COOL!" / "Let's goooo!" |
| **沮丧** | "Ugh!" / "Not again!" / "So annoying!" |
| **填充词** | "like" / "totally" / "you know" |

**示例对话**：
```
Abigail: "Hey! *does a little dance* 
          Wanna go explore the caves? It'll be AWESOME!!! 
          Like, totally!"
```

### ❤️ 喜好

**礼物**：
- 😍 最爱：紫水晶、怪物战利品、剑、约巴戒指
- 🙂 喜欢：石英、地球水晶、电子游戏
- 😐 无感：花朵、水果
- 😕 不喜欢：农具、食谱
- 😡 讨厌：干草、蛋黄酱

**食物**：
- 最爱：巧克力蛋糕、南瓜汤、茄子帕尔马干酪
- 爱喝：咖啡、能量饮料
- 讨厌：沙拉、健康食品

**活动**：
- 享受：冒险、游戏、探索洞穴、魔法
- 避免：种田、打扫、购物

**话题**：
- 爱聊：冒险、怪物、魔法、游戏、神秘事件
- 讨厌：家务、无聊的事、婚姻

**环境**：
- 最爱天气：暴风雨 ⛈️
- 最爱时间：夜晚 🌙
- 最爱地点：山区 ⛰️

### 🎭 习惯动作

| 情绪 | 习惯动作 |
|------|----------|
| **开心时** | 跳小舞、转圈、弹空气吉他 |
| **兴奋时** | 上下跳跃、挥拳、转圈跑 |
| **思考时** | 歪头、卷头发、看指甲 |
| **空闲时** | 练习剑术、检查宝石、玩掌机 |

### 💬 特殊反应

```
看到暴风雨 → "YES! Storm weather is perfect for adventure!"
看到玩家有剑 → "Whoa! Nice sword! Wanna spar sometime?"
提到爸爸 → "Dad worries too much. I can take care of myself!"
提到冒险 → "Adventure? I'm SO in! When do we start?"
```

### 📝 说话风格

```gdscript
speech_patterns = {
    "uses_exclamations": true,
    "exclamation_frequency": 0.7,    // 70% 句子带感叹号
    "uses_slang": true,              // 使用俚语
    "energy_level": 0.95,            // 超高能量
    "common_words": ["awesome", "cool", "totally", "heck"],
    "avoid_words": ["boring", "maybe", "perhaps"]
}
```

---

## Mayor Lewis 的完整个性

### 🗣️ 口头禅

| 情境 | 口头禅 |
|------|--------|
| **问候** | "Good day to you." / "Greetings, citizen." / "Welcome." |
| **同意** | "Quite so." / "Indeed." / "A sound proposition." |
| **担忧** | "This is troubling..." / "We must address this..." / "Hmm..." |
| **权威** | "As mayor..." / "For the good of the town..." / "I must insist..." |
| **填充词** | "you understand" / "if you will" / "as it were" |

**示例对话**：
```
Lewis: "Good day to you, citizen. *nods approvingly*
        As mayor, I must ensure Pelican Town remains harmonious.
        Indeed, your contributions are most valued."
```

### ❤️ 喜好

**礼物**：
- 😍 最爱：古代神器、书籍、葡萄酒
- 🙂 喜欢：蔬菜、花朵、茶
- 😐 无感：矿石、宝石
- 😕 不喜欢：垃圾、废品
- 😡 讨厌：怪物部件、粘液

**食物**：
- 最爱：蔬菜炖肉、汤、烤蘑菇
- 爱喝：茶、葡萄酒、咖啡
- 讨厌：快餐、糖果

**活动**：
- 享受：城镇管理、节日、视察、园艺
- 避免：冲突、丑闻、深夜派对

**话题**：
- 爱聊：社区、节日、农业、历史
- 讨厌：丑闻、Marnie 的秘密、抱怨

**环境**：
- 最爱天气：晴天
- 最爱时间：下午
- 最爱地点：城镇广场

### 🎭 习惯动作

| 情绪 | 习惯动作 |
|------|----------|
| **开心时** | 赞许地点头、双手交握、温暖微笑 |
| **担心时** | 皱眉、缓慢踱步、抚摸下巴 |
| **展现权威时** | 站直、清嗓子、举手 |
| **空闲时** | 视察城镇、打理花园、审阅文件 |

### 💬 特殊反应

```
看到节日准备 → "The festival brings our community together!"
看到玩家工作 → "Hard work builds character. Keep it up!"
提到 Marnie → "M-Marnie? Ah yes, a fine upstanding citizen!" *(紧张)*
城镇问题 → "We must handle this discreetly, for the good of Pelican Town."
```

### 📝 说话风格

```gdscript
speech_patterns = {
    "uses_formal_language": true,
    "formal_level": 0.85,            // 非常正式
    "uses_titles": true,             // 称呼头衔
    "diplomatic_level": 0.9,         // 高度外交辞令
    "common_words": ["indeed", "citizen", "community", "responsibility"],
    "avoid_words": ["yeah", "nope", "whatever"]
}
```

---

## 使用指南

### 获取 NPC 口头禅

```gdscript
# 获取问候语
var greeting = NPCPersonalitySystem.get_catchphrase("pierre", "greeting")
# 返回: "Welcome to my store!" 或 "Ah, a valued customer!"

# 获取兴奋时的口头禅
var excited = NPCPersonalitySystem.get_catchphrase("abigail", "excitement")
# 返回: "AWESOME!!!" 或 "SO COOL!"
```

### 检查礼物喜好

```gdscript
var reaction = NPCPersonalitySystem.check_gift_preference("pierre", "gold_bar")
# 返回: {"level": "loved", "points": 80, "reaction": "absolutely_loves"}

if reaction.level == "loved":
    # Pierre 超爱这个礼物！
    show_hearts_animation(5)
```

### 获取习惯动作

```gdscript
# Pierre 开心时会做什么
var habit = NPCPersonalitySystem.get_habitual_action("pierre", "happy")
# 返回: "polishing counter" 或 "arranging shelves" 或 "humming tune"
```

### 检查话题喜好

```gdscript
if NPCPersonalitySystem.loves_topic("abigail", "adventure"):
    # Abigail 爱聊冒险话题
    start_excited_conversation()

if NPCPersonalitySystem.hates_topic("lewis", "scandals"):
    # 别跟 Lewis 聊丑闻
    change_topic()
```

### 获取特殊反应

```gdscript
# Pierre 看到下雨的反应
var reaction = NPCPersonalitySystem.get_special_reaction("pierre", "sees_rain")
# 返回: "The crops will love this rain!"
```

### 添加自定义口头禅

```gdscript
# 给 Pierre 添加新的兴奋口头禅
NPCPersonalitySystem.add_custom_catchphrase(
    "pierre",
    "excitement",
    "Fantastic news!"
)
```

### 学习新喜好

```gdscript
# Pierre 开始喜欢某种新作物
NPCPersonalitySystem.learn_preference(
    "pierre",
    "gifts",
    "strawberry",
    "liked"
)
```

---

## 游戏中的实际效果

### 场景 1：送礼物

```
玩家送给 Pierre 一个金条：

Pierre:
  [EMOTION: Overjoyed]
  [ACTION: Eyes widen, hands trembling]
  [DIALOGUE: A gold bar?! Oh my stars, this is absolutely wonderful!]
  [THOUGHT: This could help expand the store...]
  
  → 口头禅气泡: "Absolutely!"
  → 习惯动作: polishing counter excitedly
  → 关系 +80 点
```

### 场景 2：自发对话

```
Abigail 在山区遇到玩家：

Abigail:
  [ACTION: Practicing sword moves]
  [DIALOGUE: Hey! Wanna see my new sword technique? It's SO COOL!]
  [EMOTION: Excited, energetic]
  
  → 口头禅气泡: "Let's goooo!"
  → 习惯动作: jumping up and down
```

### 场景 3：环境反应

```
暴风雨来临：

Abigail (看到闪电):
  [DIALOGUE: YES! Storm weather is perfect for adventure!]
  [ACTION: Punching air excitedly]
  [EMOTION: Thrilled]

Pierre (看到雨):
  [DIALOGUE: The crops will love this rain!]
  [ACTION: Looking at sky with relief]
  [EMOTION: Content]

Lewis (看到雨):
  [DIALOGUE: I do hope everyone seeks proper shelter...]
  [ACTION: Furrowing brow with concern]
  [EMOTION: Worried]
```

---

## 扩展你的 NPC

### 创建新 NPC 的个性

```gdscript
# 在 npc_personality_system.gd 的 initialize_npc_personalities() 中添加

npc_personalities["your_npc"] = {
    "name": "Your NPC Name",
    "speech_style": "energetic",  # 选择说话风格
    
    "catchphrases": {
        "greeting": ["你的问候语1", "你的问候语2"],
        "excitement": ["兴奋语1", "兴奋语2"],
        # ... 更多类别
    },
    
    "preferences": {
        "gifts": {
            "loved": ["最爱的礼物ID"],
            "liked": ["喜欢的礼物ID"],
            # ...
        },
        # ... 更多偏好
    },
    
    "habits": {
        "when_happy": ["开心时的动作"],
        "idle": ["空闲时的动作"]
    },
    
    "special_reactions": {
        "sees_rain": "看到雨的反应",
        # ...
    },
    
    "speech_patterns": {
        "common_words": ["常用词"],
        "avoid_words": ["避免的词"]
    }
}
```

---

## 性能优化

- 口头禅随机触发率低（0.1%/帧），不会刷屏
- 习惯动作间隔 10-30 秒，自然不突兀
- 所有数据预加载，无运行时查询开销
- 支持动态添加/修改，无需重启

---

**这就是让 NPC 活起来的关键！** 🎉

每个 NPC 现在都有：
- 独特的说话方式
- 明确的喜好厌恶
- 标志性的口头禅
- 个人化的习惯动作
- 情境化的特殊反应

**他们不再是千篇一律的机器人，而是有个性的真人！**
