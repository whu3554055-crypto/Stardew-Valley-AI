# 环境影响系统与Hello-Agent集成方案

> **文档版本**: 1.0  
> **编制日期**: 2026-04-06  
> **目标**: 实现模块化季节/天气/环境交互，集成hello-agent架构

---

## 📋 目录

1. [Hello-Agent架构分析](#hello-agent架构分析)
2. [模块化环境影响系统](#模块化环境影响系统)
3. [Godot与Agent通信协议](#godot与agent通信协议)
4. [数据库架构设计](#数据库架构设计)
5. [实施计划](#实施计划)

---

## Hello-Agent架构分析

### 核心设计理念

Hello-Agent的赛博小镇项目采用**分层解耦架构**:

```
┌─────────────────────────────────────────┐
│         Godot Frontend Layer            │  ← 游戏渲染、玩家输入
│  (npc.gd, player.gd, environment.gd)    │
├─────────────────────────────────────────┤
│      Communication Protocol Layer       │  ← HTTP/WebSocket + MCP
│     (REST API / WebSocket / MCP)        │
├─────────────────────────────────────────┤
│        Agent Backend Layer              │  ← hello-agent framework
│  (Agent Orchestrator, Memory, Tools)    │
├─────────────────────────────────────────┤
│       Data Storage Layer                │  ← SQLite + Vector DB
│   (ChromaDB, PostgreSQL, Redis)         │
└─────────────────────────────────────────┘
```

### 关键特性借鉴

#### 1. **MCP (Model Context Protocol)**

**什么是MCP**: Anthropic提出的标准化智能体通信协议

**核心概念**:
```
Client (Godot) ←→ MCP Server ←→ LLM Agent
     │                    │
     └─ JSON-RPC over ───┘
        WebSocket/HTTP
```

**优势**:
- ✅ 标准化接口，易于扩展
- ✅ 支持工具调用（Tools）
- ✅ 上下文管理（Context）
- ✅ 资源访问（Resources）

#### 2. **Agent状态管理**

Hello-Agent采用的状态管理模式:
```python
# Agent状态机
class AgentState:
    current_action: str
    target_location: Vector2
    mood: float
    energy: float
    social_need: float
    inventory: List[Item]
    memories: List[Memory]
    relationships: Dict[str, Relationship]
```

#### 3. **事件驱动架构**

```
Game Event → Event Bus → Agent Reacts → Action Queue → Execute
```

---

## 模块化环境影响系统

### 系统设计目标

✅ **模块化**: 季节、天气、环境独立可插拔  
✅ **双向影响**: 环境影响NPC行为，NPC也能影响环境  
✅ **可扩展**: 轻松添加新季节、天气类型、环境物品  
✅ **性能优化**: 只在变化时计算，缓存结果  

### 架构设计

```
environment_system/
├── season_manager.gd          # 季节管理器
├── weather_controller.gd      # 天气控制器
├── environment_interactor.gd  # 环境交互器
├── effect_modifiers/          # 效果修饰器
│   ├── crop_growth_modifier.gd
│   ├── npc_mood_modifier.gd
│   ├── energy_consumption_modifier.gd
│   └── social_activity_modifier.gd
└── data/
    ├── season_config.json
    ├── weather_patterns.json
    └── item_effects.json
```

---

### 1. 季节管理系统

#### 数据结构设计

```gdscript
# autoload/season_manager.gd
extends Node

## 季节配置
var season_config = {
    "spring": {
        "duration_days": 28,
        "temperature_range": {"min": 10, "max": 25},
        "rain_probability": 0.3,
        "crop_growth_multiplier": 1.0,
        "npc_energy_regen": 1.2,
        "mood_bonus": 0.1,
        "special_events": ["flower_festival", "planting_season"],
        "visual_theme": {
            "sky_color": Color(0.7, 0.85, 1.0),
            "ambient_sound": "res://audio/ambience/spring.ogg",
            "particle_effect": "falling_petals"
        }
    },
    "summer": {
        "duration_days": 28,
        "temperature_range": {"min": 20, "max": 35},
        "rain_probability": 0.2,
        "crop_growth_multiplier": 1.5,
        "npc_energy_regen": 0.8,  # 炎热消耗更多能量
        "mood_bonus": -0.05,
        "special_events": ["swimming_competition", "fireworks_festival"],
        "visual_theme": {
            "sky_color": Color(0.9, 0.95, 1.0),
            "ambient_sound": "res://audio/ambience/summer.ogg",
            "particle_effect": "heat_haze"
        }
    },
    "fall": {
        "duration_days": 28,
        "temperature_range": {"min": 8, "max": 22},
        "rain_probability": 0.25,
        "crop_growth_multiplier": 0.8,
        "npc_energy_regen": 1.0,
        "mood_bonus": 0.05,
        "special_events": ["harvest_festival", "pumpkin_contest"],
        "visual_theme": {
            "sky_color": Color(1.0, 0.85, 0.6),
            "ambient_sound": "res://audio/ambience/fall.ogg",
            "particle_effect": "falling_leaves"
        }
    },
    "winter": {
        "duration_days": 28,
        "temperature_range": {"min": -5, "max": 8},
        "rain_probability": 0.15,  # 下雪概率
        "crop_growth_multiplier": 0.0,  # 作物停止生长
        "npc_energy_regen": 0.7,  # 寒冷消耗能量
        "mood_bonus": -0.1,
        "special_events": ["snow_festival", "winter_feast"],
        "visual_theme": {
            "sky_color": Color(0.8, 0.85, 0.95),
            "ambient_sound": "res://audio/ambience/winter.ogg",
            "particle_effect": "falling_snow"
        }
    }
}

signal season_changed(old_season: String, new_season: String)
signal day_progressed(day: int, season: String)

var current_season: String = "spring"
var current_day: int = 1
var season_day: int = 1  # 当前季节的第几天

func _ready():
    load_season_config()
    connect_signals()

func advance_day():
    """推进一天"""
    season_day += 1
    current_day += 1
    
    emit_signal("day_progressed", current_day, current_season)
    
    # 检查是否换季
    if season_day > season_config[current_season].duration_days:
        change_to_next_season()

func change_to_next_season():
    """切换到下一个季节"""
    var old_season = current_season
    var seasons = ["spring", "summer", "fall", "winter"]
    var current_index = seasons.find(current_season)
    var next_index = (current_index + 1) % 4
    
    current_season = seasons[next_index]
    season_day = 1
    
    apply_season_effects(old_season, current_season)
    emit_signal("season_changed", old_season, current_season)
    
    print("Season changed from %s to %s!" % [old_season, current_season])

func apply_season_effects(old_season: String, new_season: String):
    """应用季节转换效果"""
    var config = season_config[new_season]
    
    # 1. 更新全局生长倍率
    FarmManager.crop_growth_multiplier = config.crop_growth_multiplier
    
    # 2. 通知NPC系统
    NPCBehaviorController.update_seasonal_behavior(new_season)
    
    # 3. 更新视觉效果
    update_visual_theme(config.visual_theme)
    
    # 4. 触发季节事件
    trigger_seasonal_events(config.special_events)
    
    # 5. 保存进度
    save_season_state()

func get_season_modifier(stat: String) -> float:
    """获取当前季节对某属性的修正系数"""
    var config = season_config[current_season]
    match stat:
        "crop_growth":
            return config.crop_growth_multiplier
        "energy_regen":
            return config.npc_energy_regen
        "mood":
            return config.mood_bonus
        _:
            return 1.0

func update_visual_theme(theme_config: Dictionary):
    """更新视觉主题"""
    # 天空颜色渐变
    var tween = create_tween()
    tween.tween_property(WorldEnvironment, "environment.sky.sky_material.sky_color", 
                        theme_config.sky_color, 2.0)
    
    # 背景音乐切换
    AudioPlayer.fade_to_ambient(theme_config.ambient_sound)
    
    # 粒子效果
    ParticleSystem.set_season_effect(theme_config.particle_effect)
```

---

### 2. 天气控制系统

#### 动态天气模式

```gdscript
# autoload/weather_controller.gd
extends Node

## 天气类型定义
enum WeatherType {
    SUNNY,
    CLOUDY,
    RAINY,
    STORMY,
    SNOWY,
    FOGGY,
    WINDY
}

## 天气配置
var weather_config = {
    WeatherType.SUNNY: {
        "name": "晴天",
        "crop_watering": false,
        "npc_outdoor_activity": 1.0,  # 100%户外活动的倾向
        "mood_effect": 0.1,
        "energy_consumption": 1.0,
        "visual_effects": {
            "light_intensity": 1.2,
            "shadow_enabled": true,
            "bloom_strength": 0.3
        }
    },
    WeatherType.RAINY: {
        "name": "雨天",
        "crop_watering": true,  # 自动浇水
        "npc_outdoor_activity": 0.3,
        "mood_effect": -0.05,
        "energy_consumption": 0.9,
        "visual_effects": {
            "light_intensity": 0.7,
            "rain_particles": true,
            "puddle_reflections": true
        }
    },
    WeatherType.STORMY: {
        "name": "暴风雨",
        "crop_watering": true,
        "npc_outdoor_activity": 0.0,  # 不外出
        "mood_effect": -0.2,
        "energy_consumption": 1.3,
        "damage_risk": 0.1,  # 可能损坏作物
        "visual_effects": {
            "light_intensity": 0.4,
            "lightning_flash": true,
            "heavy_rain": true,
            "wind_effect": true
        }
    },
    WeatherType.SNOWY: {
        "name": "雪天",
        "crop_watering": false,
        "npc_outdoor_activity": 0.2,
        "mood_effect": 0.05,
        "energy_consumption": 1.4,  # 寒冷消耗
        "visual_effects": {
            "light_intensity": 0.9,
            "snow_particles": true,
            "ground_snow_cover": true
        }
    }
}

signal weather_changed(old_weather: int, new_weather: int)
signal weather_updated(weather_data: Dictionary)

var current_weather: WeatherType = WeatherType.SUNNY
var weather_duration_hours: float = 6.0  # 天气持续小时数
var weather_timer: float = 0.0

func _process(delta):
    weather_timer += delta / 3600.0  # 转换为游戏小时
    
    if weather_timer >= weather_duration_hours:
        generate_new_weather()
        weather_timer = 0.0

func generate_new_weather():
    """根据季节生成新天气"""
    var season = SeasonManager.current_season
    var probabilities = get_weather_probabilities(season)
    
    var roll = randf()
    var cumulative = 0.0
    var new_weather = WeatherType.SUNNY
    
    for weather_type in probabilities.keys():
        cumulative += probabilities[weather_type]
        if roll <= cumulative:
            new_weather = weather_type
            break
    
    set_weather(new_weather)

func get_weather_probabilities(season: String) -> Dictionary:
    """获取不同季节的天气概率"""
    match season:
        "spring":
            return {
                WeatherType.SUNNY: 0.4,
                WeatherType.CLOUDY: 0.25,
                WeatherType.RAINY: 0.3,
                WeatherType.STORMY: 0.05
            }
        "summer":
            return {
                WeatherType.SUNNY: 0.5,
                WeatherType.CLOUDY: 0.2,
                WeatherType.RAINY: 0.15,
                WeatherType.STORMY: 0.15
            }
        "fall":
            return {
                WeatherType.SUNNY: 0.45,
                WeatherType.CLOUDY: 0.3,
                WeatherType.RAINY: 0.2,
                WeatherType.FOGGY: 0.05
            }
        "winter":
            return {
                WeatherType.SUNNY: 0.3,
                WeatherType.CLOUDY: 0.3,
                WeatherType.SNOWY: 0.35,
                WeatherType.STORMY: 0.05
            }
    return {}

func set_weather(weather_type: WeatherType):
    """设置天气并应用效果"""
    var old_weather = current_weather
    current_weather = weather_type
    
    var config = weather_config[weather_type]
    
    # 1. 应用视觉效果
    apply_weather_visuals(config.visual_effects)
    
    # 2. 通知农场系统
    if config.crop_watering:
        FarmManager.auto_water_all_crops()
    
    # 3. 通知NPC系统
    NPCBehaviorController.update_weather_behavior(weather_type)
    
    # 4. 更新UI
    emit_signal("weather_changed", old_weather, weather_type)
    emit_signal("weather_updated", config)
    
    # 5. 随机持续时间 (4-12小时)
    weather_duration_hours = 4.0 + randf() * 8.0
    
    print("Weather changed to: %s" % config.name)

func get_weather_modifier(stat: String) -> float:
    """获取天气对属性的修正"""
    var config = weather_config[current_weather]
    match stat:
        "outdoor_activity":
            return config.npc_outdoor_activity
        "mood":
            return config.mood_effect
        "energy":
            return config.energy_consumption
        "crop_watered":
            return 1.0 if config.crop_watering else 0.0
        _:
            return 1.0

func apply_weather_visuals(effects: Dictionary):
    """应用天气视觉效果"""
    # 光照强度
    if effects.has("light_intensity"):
        $WorldEnvironment.environment.adjustment_brightness = effects.light_intensity
    
    # 粒子效果
    if effects.has("rain_particles"):
        $WeatherParticles.setup_rain()
    elif effects.has("snow_particles"):
        $WeatherParticles.setup_snow()
    elif effects.has("lightning_flash"):
        $LightningEffect.start_flashing()
```

---

### 3. 环境物品交互系统

#### 模块化物品影响

```gdscript
# scripts/environment_interactor.gd
extends Node

## 环境物品基类
class_name EnvironmentItem extends Node2D

export(String) var item_id: String
export(String) var item_name: String
export(Dictionary) var properties = {}

# 物品对环境的影响
var environmental_effects = {
    "temperature_delta": 0.0,  # 温度变化
    "humidity_delta": 0.0,     # 湿度变化
    "light_radius": 0.0,       # 光照范围
    "comfort_bonus": 0.0,      # 舒适度加成
    "aesthetic_value": 0.0     # 美观度
}

# 受季节/天气影响的效果
var seasonal_modifiers = {}
var weather_modifiers = {}

func _ready():
    initialize_item()

func initialize_item():
    """初始化物品，加载配置"""
    var config = load_item_config(item_id)
    if config:
        properties = config.get("properties", {})
        environmental_effects = config.get("environmental_effects", {})
        seasonal_modifiers = config.get("seasonal_modifiers", {})
        weather_modifiers = config.get("weather_modifiers", {})

func get_current_effects() -> Dictionary:
    """获取当前实际效果（考虑季节和天气修正）"""
    var base_effects = environmental_effects.duplicate()
    
    # 应用季节修正
    var season = SeasonManager.current_season
    if seasonal_modifiers.has(season):
        for key in seasonal_modifiers[season].keys():
            if base_effects.has(key):
                base_effects[key] *= seasonal_modifiers[season][key]
    
    # 应用天气修正
    var weather = WeatherController.current_weather
    if weather_modifiers.has(weather):
        for key in weather_modifiers[weather].keys():
            if base_effects.has(key):
                base_effects[key] *= weather_modifiers[weather][key]
    
    return base_effects

func on_player_proximity(player_pos: Vector2):
    """玩家在附近时的效果"""
    var distance = global_position.distance_to(player_pos)
    if distance < 100:  # 100像素范围内
        apply_proximity_effects(distance)

func apply_proximity_effects(distance: float):
    """应用近距离效果"""
    var effects = get_current_effects()
    
    # 温度影响
    if effects.temperature_delta != 0:
        Player.temperature += effects.temperature_delta * (1.0 - distance/100.0)
    
    # 舒适度影响心情
    if effects.comfort_bonus != 0:
        Player.mood += effects.comfort_bonus * 0.01

# ============================================
# 具体物品示例
# ============================================

## 壁炉
class Fireplace extends EnvironmentItem:
    func _init():
        item_id = "fireplace"
        item_name = "壁炉"
        environmental_effects = {
            "temperature_delta": 5.0,
            "light_radius": 150.0,
            "comfort_bonus": 0.3,
            "aesthetic_value": 0.5
        }
        seasonal_modifiers = {
            "winter": {"temperature_delta": 1.5},  # 冬天效果更好
            "summer": {"temperature_delta": 0.5}   # 夏天效果减弱
        }

## 空调
class AirConditioner extends EnvironmentItem:
    func _init():
        item_id = "air_conditioner"
        item_name = "空调"
        environmental_effects = {
            "temperature_delta": -3.0,
            "comfort_bonus": 0.2,
            "energy_cost": 0.1  # 消耗电力
        }
        seasonal_modifiers = {
            "summer": {"temperature_delta": 1.5},  # 夏天更强
            "winter": {"temperature_delta": 0.3}   # 冬天弱化
        }

## 花盆装饰
class DecorativePlant extends EnvironmentItem:
    func _init():
        item_id = "decorative_plant"
        item_name = "装饰植物"
        environmental_effects = {
            "humidity_delta": 0.1,
            "aesthetic_value": 0.4,
            "air_quality_bonus": 0.1
        }
        weather_modifiers = {
            WeatherController.WeatherType.RAINY: {"humidity_delta": 1.2},
            WeatherController.WeatherType.SUNNY: {"humidity_delta": 0.8}
        }
```

---

### 4. 效果修饰器系统

#### NPC心情修饰器

```gdscript
# environment_system/effect_modifiers/npc_mood_modifier.gd
extends Node

## 计算环境对NPC心情的综合影响
static func calculate_environmental_mood(npc: Node, location: Vector2) -> float:
    var mood_delta = 0.0
    
    # 1. 季节基础心情
    mood_delta += SeasonManager.get_season_modifier("mood")
    
    # 2. 天气影响
    mood_delta += WeatherController.get_weather_modifier("mood")
    
    # 3. 周围物品影响
    var nearby_items = get_nearby_items(location, radius=200)
    for item in nearby_items:
        var effects = item.get_current_effects()
        if effects.has("comfort_bonus"):
            mood_delta += effects.comfort_bonus * 0.1
    
    # 4. 温度舒适度
    var temperature = get_temperature_at(location)
    var comfort_level = calculate_temperature_comfort(temperature, npc.preferences)
    mood_delta += (comfort_level - 0.5) * 0.2
    
    # 5. 时间影响（夜晚心情略低）
    var hour = GameManager.get_current_hour()
    if hour >= 20 or hour <= 6:
        mood_delta -= 0.05
    
    return clamp(mood_delta, -0.5, 0.5)

static func get_temperature_at(location: Vector2) -> float:
    """计算某位置的当前温度"""
    var base_temp = get_season_base_temperature()
    
    # 天气影响
    var weather = WeatherController.current_weather
    if weather == WeatherController.WeatherType.SUNNY:
        base_temp += 3.0
    elif weather == WeatherController.WeatherType.SNOWY:
        base_temp -= 5.0
    
    # 周围物品影响
    var nearby_items = get_nearby_items(location)
    for item in nearby_items:
        var effects = item.get_current_effects()
        if effects.has("temperature_delta"):
            base_temp += effects.temperature_delta
    
    return base_temp

static func calculate_temperature_comfort(temp: float, preferences: Dictionary) -> float:
    """计算温度舒适度 (0-1)"""
    var preferred_temp = preferences.get("preferred_temperature", 20.0)
    var tolerance = preferences.get("temperature_tolerance", 5.0)
    
    var diff = abs(temp - preferred_temp)
    var comfort = max(0.0, 1.0 - diff / tolerance)
    
    return comfort
```

#### 作物生长修饰器

```gdscript
# environment_system/effect_modifiers/crop_growth_modifier.gd
extends Node

static func calculate_daily_growth(crop: Dictionary, location: Vector2) -> float:
    """计算作物每日生长量"""
    var base_growth = crop.base_growth_rate
    
    # 1. 季节倍率
    var season_mult = SeasonManager.get_season_modifier("crop_growth")
    
    # 2. 天气影响
    var weather_mult = 1.0
    if WeatherController.current_weather == WeatherController.WeatherType.RAINY:
        weather_mult = 1.2  # 雨天促进生长
    elif WeatherController.current_weather == WeatherController.WeatherType.STORMY:
        weather_mult = 0.8  # 暴雨抑制生长
    
    # 3. 土壤湿度
    var soil_moisture = FarmManager.get_soil_moisture(location)
    var moisture_mult = 1.0
    if soil_moisture < 0.3:
        moisture_mult = 0.5  # 太干
    elif soil_moisture > 0.8:
        moisture_mult = 0.9  # 太湿
    
    # 4. 温度适宜度
    var temp = NpcMoodModifier.get_temperature_at(location)
    var temp_mult = calculate_temperature_growth_factor(temp, crop.optimal_temp)
    
    # 5. 肥料效果
    var fertilizer_mult = crop.fertilizer_bonus if crop.has_fertilizer else 1.0
    
    # 综合计算
    var final_growth = base_growth * season_mult * weather_mult * \
                      moisture_mult * temp_mult * fertilizer_mult
    
    return final_growth

static func calculate_temperature_growth_factor(temp: float, optimal_temp: float) -> float:
    """温度对生长的影响 (0-2)"""
    var diff = abs(temp - optimal_temp)
    if diff < 3:
        return 1.5  # 最佳温度
    elif diff < 8:
        return 1.0  # 正常
    elif diff < 15:
        return 0.6  # 较差
    else:
        return 0.2  # 极差
```

---

## Godot与Agent通信协议

### 基于MCP的架构设计

#### 通信层实现

```gdscript
# autoload/agent_communication.gd
extends Node

## Godot-MCP通信客户端
class_name AgentCommunicationClient

var server_url: String = "http://localhost:8080"
var websocket: WebSocketPeer
var request_queue: Array
var response_handlers: Dictionary

signal agent_response_received(response_id: String, data: Dictionary)
signal agent_connected
signal agent_disconnected

func _ready():
    initialize_connection()

func initialize_connection():
    """初始化与hello-agent的连接"""
    websocket = WebSocketPeer.new()
    var ws_url = server_url.replace("http", "ws") + "/mcp"
    websocket.connect_to_url(ws_url)
    
    set_process(true)

func _process(_delta):
    websocket.poll()
    
    var state = websocket.get_ready_state()
    match state:
        WebSocketPeer.STATE_OPEN:
            process_pending_requests()
            read_messages()
        WebSocketPeer.STATE_CLOSED:
            emit_signal("agent_disconnected")
            reconnect()

func send_request(method: String, params: Dictionary, callback: Callable = Callable()) -> String:
    """发送MCP请求到Agent"""
    var request_id = generate_uuid()
    var request = {
        "jsonrpc": "2.0",
        "id": request_id,
        "method": method,
        "params": params
    }
    
    var json_text = JSON.stringify(request)
    websocket.send_text(json_text)
    
    if callback.is_valid():
        response_handlers[request_id] = callback
    
    return request_id

func read_messages():
    """读取Agent响应"""
    while websocket.get_available_packet_count() > 0:
        var packet = websocket.get_packet()
        var message = packet.get_string_from_utf8()
        var response = JSON.parse_string(message)
        
        if response and response.has("id"):
            handle_response(response)

func handle_response(response: Dictionary):
    """处理Agent响应"""
    var request_id = response.id
    
    # 调用回调
    if response_handlers.has(request_id):
        var callback = response_handlers[request_id]
        callback.call(response.result if response.has("result") else null)
        response_handlers.erase(request_id)
    
    emit_signal("agent_response_received", request_id, response)

# ============================================
# 高级API封装
# ============================================

func request_npc_decision(npc_id: String, context: Dictionary) -> Dictionary:
    """请求NPC决策"""
    var result = await send_request("npc.decide", {
        "npc_id": npc_id,
        "context": context,
        "timestamp": Time.get_unix_time_from_system()
    })
    
    return result

func update_agent_world_state(game_state: Dictionary):
    """同步游戏世界状态到Agent"""
    send_request("world.update", {
        "season": SeasonManager.current_season,
        "weather": WeatherController.current_weather,
        "time": GameManager.get_current_time(),
        "players_online": get_online_players(),
        "active_npcs": get_active_npc_list()
    })

func register_game_tools():
    """注册游戏工具供Agent调用"""
    send_request("tools.register", {
        "tools": [
            {
                "name": "get_npc_info",
                "description": "获取NPC信息",
                "parameters": {"npc_id": "string"}
            },
            {
                "name": "modify_npc_mood",
                "description": "修改NPC心情",
                "parameters": {"npc_id": "string", "delta": "float"}
            },
            {
                "name": "spawn_item",
                "description": "生成物品",
                "parameters": {"item_id": "string", "location": "vector2"}
            }
        ]
    })
```

---

### hello-agent后端集成

#### Python Agent服务端

```python
# hello_agent_server.py
from fastapi import FastAPI, WebSocket
import asyncio
import json
from typing import Dict, Any

app = FastAPI(title="Stardew AI Agent Server")

class GameAgent:
    def __init__(self):
        self.npc_states: Dict[str, Any] = {}
        self.world_state: Dict[str, Any] = {}
        self.memory_store = VectorMemoryStore()  # ChromaDB/LanceDB
    
    async def handle_npc_decision(self, npc_id: str, context: dict) -> dict:
        """处理NPC决策请求"""
        # 1. 获取NPC档案
        npc_profile = await self.get_npc_profile(npc_id)
        
        # 2. 检索相关记忆
        relevant_memories = await self.memory_store.search(
            query=context.get("situation", ""),
            filter={"npc_id": npc_id},
            limit=5
        )
        
        # 3. 构建Prompt
        prompt = self.build_decision_prompt(npc_profile, context, relevant_memories)
        
        # 4. 调用LLM
        decision = await self.llm_generate(prompt)
        
        # 5. 解析并返回
        return self.parse_decision(decision)
    
    async def update_world_state(self, state: dict):
        """更新世界状态"""
        self.world_state.update(state)
        
        # 触发环境事件检测
        await self.check_environmental_events()
    
    async def check_environmental_events(self):
        """检查环境触发的事件"""
        season = self.world_state.get("season")
        weather = self.world_state.get("weather")
        
        # 季节事件
        if season == "spring" and random.random() < 0.1:
            await self.trigger_event("flower_blooming")
        
        # 天气事件
        if weather == "stormy":
            await self.trigger_event("storm_damage_check")

# WebSocket endpoint for MCP
@app.websocket("/mcp")
async def mcp_endpoint(websocket: WebSocket):
    await websocket.accept()
    agent = GameAgent()
    
    while True:
        try:
            data = await websocket.receive_text()
            request = json.loads(data)
            
            # 路由到对应处理方法
            method = request.get("method")
            params = request.get("params", {})
            request_id = request.get("id")
            
            if method == "npc.decide":
                result = await agent.handle_npc_decision(
                    params["npc_id"], 
                    params["context"]
                )
            elif method == "world.update":
                await agent.update_world_state(params)
                result = {"status": "ok"}
            else:
                result = {"error": "Unknown method"}
            
            # 发送响应
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": result
            }
            await websocket.send_text(json.dumps(response))
        
        except Exception as e:
            print(f"Error: {e}")
            break

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

---

## 数据库架构设计

### 混合存储方案

```
数据存储架构:
┌─────────────────────────────────────┐
│   Hot Data (Redis)                  │  ← 实时状态
│   - NPC当前位置                     │
│   - 临时心情值                      │
│   - 活跃任务                        │
├─────────────────────────────────────┤
│   Warm Data (SQLite)                │  ← 游戏存档
│   - 玩家进度                        │
│   - NPC关系                         │
│   - 农场状态                        │
├─────────────────────────────────────┤
│   Cold Data (LanceDB)               │  ← 向量搜索
│   - NPC长期记忆                     │
│   - 对话历史                        │
│   - 事件日志                        │
└─────────────────────────────────────┘
```

### SQLite Schema

```sql
-- 环境状态表
CREATE TABLE environment_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp REAL NOT NULL,
    season TEXT NOT NULL,
    season_day INTEGER NOT NULL,
    weather INTEGER NOT NULL,
    temperature REAL,
    humidity REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 物品放置表
CREATE TABLE placed_items (
    id TEXT PRIMARY KEY,
    item_id TEXT NOT NULL,
    location_x REAL NOT NULL,
    location_y REAL NOT NULL,
    map_layer TEXT,
    owner_id TEXT,  -- 所属玩家或NPC
    properties JSON,
    FOREIGN KEY (item_id) REFERENCES items(id)
);

-- 环境影响日志
CREATE TABLE environmental_effects_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp REAL,
    affected_entity TEXT,  -- NPC ID或Player
    entity_type TEXT,      -- 'npc' or 'player'
    effect_type TEXT,      -- 'mood', 'energy', 'health'
    effect_value REAL,
    source TEXT,           -- 'season', 'weather', 'item'
    source_id TEXT,
    location_x REAL,
    location_y REAL
);

-- 索引优化
CREATE INDEX idx_env_state_timestamp ON environment_state(timestamp);
CREATE INDEX idx_placed_items_location ON placed_items(location_x, location_y);
CREATE INDEX idx_effects_log_entity ON environmental_effects_log(affected_entity);
```

---

## 实施计划

### Phase 1: 基础环境系统 (Week 1-2)

**Week 1**:
- [ ] 实现SeasonManager
- [ ] 实现WeatherController
- [ ] 创建配置文件结构
- [ ] 基础视觉效果

**Week 2**:
- [ ] 环境物品基类
- [ ] 效果修饰器框架
- [ ] NPC心情影响集成
- [ ] 作物生长影响集成

### Phase 2: Hello-Agent集成 (Week 3-4)

**Week 3**:
- [ ] 搭建Python后端服务
- [ ] 实现WebSocket通信
- [ ] MCP协议适配
- [ ] 基础Agent逻辑

**Week 4**:
- [ ] 向量数据库集成
- [ ] 记忆系统对接
- [ ] 工具注册机制
- [ ] 端到端测试

### Phase 3: 高级功能 (Week 5-6)

**Week 5**:
- [ ] 复杂环境交互
- [ ] 季节性事件系统
- [ ] 天气灾害机制
- [ ] 成就系统集成

**Week 6**:
- [ ] 性能优化
- [ ] 多玩家同步
- [ ] 存档系统完善
- [ ] Beta测试准备

---

## 总结

本方案实现了:

✅ **模块化环境系统** - 季节、天气、物品独立可扩展  
✅ **双向影响机制** - 环境影响NPC，NPC影响环境  
✅ **Hello-Agent集成** - 基于MCP协议的标准化通信  
✅ **混合存储架构** - Redis + SQLite + LanceDB  
✅ **高性能设计** - 事件驱动、按需计算、缓存优化  

**下一步**: 开始Phase 1实施，先完成基础季节和天气系统。
