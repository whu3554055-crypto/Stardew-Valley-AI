# 环境影响系统与Hello-Agent实施清单

> **用途**: 逐步实施指南  
> **预计时间**: 6周

---

## 🎯 快速开始 (今天就能见效)

### Step 1: 创建基础文件结构 (30分钟)

```bash
# 创建目录结构
mkdir -p environment_system/effect_modifiers
mkdir -p hello_agent_backend
mkdir -p data/environment_configs

# 创建空文件
touch autoload/season_manager.gd
touch autoload/weather_controller.gd
touch scripts/environment_interactor.gd
touch environment_system/effect_modifiers/npc_mood_modifier.gd
touch environment_system/effect_modifiers/crop_growth_modifier.gd
```

### Step 2: 实现最简季节系统 (1小时)

复制 `docs/01-技术架构与优化/04-环境影响系统与Hello-Agent集成方案.md` 中的SeasonManager代码到 `autoload/season_manager.gd`

在 `project.godot` 中注册:
```ini
[autoload]
SeasonManager="*res://autoload/season_manager.gd"
WeatherController="*res://autoload/weather_controller.gd"
```

### Step 3: 测试季节切换 (30分钟)

在Godot编辑器中添加测试按钮:
```gdscript
# scenes/test_season.gd
func _on_test_button_pressed():
    SeasonManager.advance_day()
    print("Current season: ", SeasonManager.current_season)
```

---

## 📅 Week 1: 季节系统完整实现

### Day 1-2: SeasonManager核心

- [ ] 复制SeasonManager完整代码
- [ ] 创建season_config.json配置文件
- [ ] 实现季节切换信号连接
- [ ] 测试季节循环

**验收标准**:
```gdscript
# 运行以下代码无错误
SeasonManager.advance_day()  # 推进28次
assert(SeasonManager.current_season == "summer")
```

---

### Day 3-4: WeatherController核心

- [ ] 复制WeatherController代码
- [ ] 实现天气概率系统
- [ ] 添加天气视觉效果（雨、雪粒子）
- [ ] 测试天气自动切换

**验收标准**:
```gdscript
# 天气能根据季节自动变化
# 雨天时作物自动浇水
WeatherController.set_weather(WeatherController.WeatherType.RAINY)
assert(FarmManager.all_crops_watered())
```

---

### Day 5: 环境物品基类

- [ ] 实现EnvironmentItem基类
- [ ] 创建3个示例物品（壁炉、空调、装饰植物）
- [ ] 实现物品效果计算
- [ ] 测试物品放置和移除

**验收标准**:
```gdscript
var fireplace = Fireplace.new()
add_child(fireplace)
fireplace.global_position = player.position

var effects = fireplace.get_current_effects()
assert(effects.temperature_delta > 0)
```

---

### Day 6-7: 效果修饰器集成

- [ ] 实现NpcMoodModifier
- [ ] 实现CropGrowthModifier
- [ ] 集成到现有NPC系统
- [ ] 集成到农场系统

**验收标准**:
```gdscript
# NPC心情受环境影响
var mood_delta = NpcMoodModifier.calculate_environmental_mood(npc, npc.position)
assert(mood_delta >= -0.5 and mood_delta <= 0.5)

# 作物生长受季节影响
var growth = CropGrowthModifier.calculate_daily_growth(wheat, wheat.position)
assert(growth > 0)
```

**Week 1交付物**:
✅ 完整的季节系统  
✅ 动态天气系统  
✅ 环境物品框架  
✅ NPC心情环境影响  
✅ 作物生长环境影响  

---

## 📅 Week 2: Hello-Agent基础架构

### Day 8-9: Python后端搭建

- [ ] 安装依赖: `pip install fastapi uvicorn websockets`
- [ ] 创建hello_agent_server.py
- [ ] 实现基础WebSocket端点
- [ ] 测试连接

**代码**:
```python
# hello_agent_backend/server.py
from fastapi import FastAPI, WebSocket

app = FastAPI()

@app.websocket("/mcp")
async def mcp_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        # 处理请求...
        await websocket.send_text('{"result": "ok"}')

# 运行: uvicorn server:app --reload
```

**验收标准**:
```bash
# 启动服务器
uvicorn hello_agent_backend.server:app --reload

# 测试连接
curl http://localhost:8080/docs  # 应看到Swagger UI
```

---

### Day 10-11: Godot通信客户端

- [ ] 实现AgentCommunicationClient
- [ ] 实现WebSocket连接管理
- [ ] 实现请求/响应机制
- [ ] 测试双向通信

**验收标准**:
```gdscript
# Godot端能成功发送和接收消息
var client = AgentCommunicationClient.new()
client.server_url = "http://localhost:8080"

var result = await client.request_npc_decision("pierre", {"action": "greet"})
assert(result != null)
```

---

### Day 12-13: MCP协议适配

- [ ] 实现JSON-RPC 2.0格式
- [ ] 实现工具注册机制
- [ ] 实现上下文管理
- [ ] 测试MCP兼容

**验收标准**:
```gdscript
# 注册游戏工具
client.register_game_tools()

# Agent能调用工具
var npc_info = await client.call_tool("get_npc_info", {"npc_id": "pierre"})
assert(npc_info.has("name"))
```

---

### Day 14: 端到端测试

- [ ] 完整流程测试
- [ ] 错误处理测试
- [ ] 性能测试
- [ ] 文档编写

**Week 2交付物**:
✅ Python后端服务  
✅ Godot通信客户端  
✅ MCP协议支持  
✅ 工具注册机制  
✅ 端到端测试通过  

---

## 📅 Week 3: 向量数据库与记忆系统

### Day 15-16: LanceDB集成

- [ ] 安装LanceDB: `pip install lancedb`
- [ ] 创建VectorMemoryStore类
- [ ] 实现嵌入模型加载
- [ ] 实现向量存储和搜索

**代码**:
```python
# hello_agent_backend/vector_store.py
import lancedb

class VectorMemoryStore:
    def __init__(self):
        self.db = lancedb.connect("data/memories")
        self.table = self.create_table()
    
    def add_memory(self, npc_id: str, content: str, metadata: dict):
        embedding = self.generate_embedding(content)
        self.table.add([{
            "id": generate_uuid(),
            "npc_id": npc_id,
            "content": content,
            "embedding": embedding,
            "metadata": json.dumps(metadata)
        }])
    
    def search_similar(self, query: str, npc_id: str, limit: int = 5):
        query_embedding = self.generate_embedding(query)
        return self.table.search(query_embedding)\
            .where(f"npc_id = '{npc_id}'")\
            .limit(limit)\
            .to_list()
```

---

### Day 17-18: 记忆系统集成

- [ ] 实现记忆添加API
- [ ] 实现记忆检索API
- [ ] 集成到NPC决策流程
- [ ] 测试记忆召回

**验收标准**:
```python
# 添加记忆
store.add_memory("pierre", "今天玩家帮我浇了水", {
    "emotion": "happy",
    "day": 5
})

# 检索相关记忆
memories = store.search_similar("玩家帮助", "pierre")
assert(len(memories) > 0)
```

---

### Day 19-20: Agent决策逻辑

- [ ] 实现NPC决策Prompt构建
- [ ] 集成LLM调用
- [ ] 实现决策解析
- [ ] 测试决策质量

**Week 3交付物**:
✅ LanceDB向量存储  
✅ 记忆添加/检索API  
✅ Agent决策逻辑  
✅ 记忆增强NPC行为  

---

## 📅 Week 4: 高级环境交互

### Day 21-22: 季节性事件系统

- [ ] 实现事件触发器
- [ ] 创建季节节日（花节、收获节等）
- [ ] 实现事件奖励
- [ ] 测试事件流程

---

### Day 23-24: 天气灾害机制

- [ ] 暴风雨损坏作物
- [ ] 干旱影响
- [ ] 预警系统
- [ ] 防护措施

---

### Day 25-26: 多玩家同步

- [ ] 环境状态同步
- [ ] 物品放置同步
- [ ] 天气变化广播
- [ ] 测试多人场景

---

### Day 27-28: 性能优化

- [ ] 事件驱动更新
- [ ] 空间分区优化
- [ ] 缓存策略
- [ ] Profiling和优化

**Week 4交付物**:
✅ 季节事件系统  
✅ 天气灾害机制  
✅ 多玩家支持  
✅ 性能优化完成  

---

## 📅 Week 5-6: 完善与测试

### Week 5: 功能完善

- [ ] 成就系统集成
- [ ] 存档系统完善
- [ ] UI美化
- [ ] 音效添加
- [ ] 本地化支持

### Week 6: 测试与发布准备

- [ ] 单元测试 (>70%覆盖)
- [ ] 集成测试
- [ ] Beta测试招募
- [ ] Bug修复
- [ ] 文档完善
- [ ] 发布候选版

---

## 🔧 常用命令速查

### Python后端

```bash
# 启动开发服务器
uvicorn hello_agent_backend.server:app --reload --port 8080

# 安装依赖
pip install fastapi uvicorn lancedb sentence-transformers

# 运行测试
pytest tests/

# 数据库备份
python tools/backup_db.py
```

### Godot前端

```bash
# 运行项目
godot scenes/main.tscn

# 导出Windows版本
godot --export "Windows Desktop" export/game.exe

# 运行测试
godot --test

# 性能profiling
# 游戏中按F3
```

### Git工作流

```bash
# 创建功能分支
git checkout -b feature/environment-system

# 提交代码
git add .
git commit -m "feat: 实现季节管理系统"
git push origin feature/environment-system

# 合并到主分支（通过PR）
```

---

## 🐛 常见问题排查

### 问题1: WebSocket连接失败

**症状**: Godot端无法连接到Python后端

**解决**:
```bash
# 1. 检查服务器是否运行
curl http://localhost:8080/docs

# 2. 检查防火墙
# Windows: 允许Python通过防火墙

# 3. 检查URL格式
# Godot端应使用: ws://localhost:8080/mcp
```

---

### 问题2: 向量搜索返回空结果

**症状**: search_similar返回空列表

**解决**:
```python
# 1. 确认已添加记忆
print(store.table.count())  # 应 > 0

# 2. 检查嵌入维度
print(len(embedding))  # 应与表schema一致

# 3. 测试简单查询
results = store.table.search([0.1] * 384).limit(5).to_list()
print(results)
```

---

### 问题3: 季节切换时视觉效果好卡

**症状**: 切换季节时FPS下降

**解决**:
```gdscript
# 使用tween渐变而不是瞬间切换
var tween = create_tween()
tween.tween_property(environment, "sky_color", new_color, 2.0)
tween.set_ease(Tween.EASE_IN_OUT)
```

---

## 📊 进度追踪模板

```markdown
## Sprint X 进度

**日期**: YYYY-MM-DD

### 完成任务
- [x] 任务1
- [x] 任务2

### 进行中
- [~] 任务3 (50%)

### 阻碍
- 问题描述...

### 明日计划
- 任务4
- 任务5

### 指标
- FPS: ___
- 内存: ___ MB
- Bug数: ___
```

---

## 🎉 完成检查清单

### 技术完成标准

- [ ] 季节系统正常工作
- [ ] 天气系统动态变化
- [ ] 环境物品可放置和交互
- [ ] NPC心情受环境影响
- [ ] 作物生长受环境影响
- [ ] Hello-Agent通信正常
- [ ] 向量记忆系统工作
- [ ] Agent决策质量良好
- [ ] 性能达标 (60 FPS)
- [ ] 内存稳定 (<400MB)

### 文档完成标准

- [ ] API文档完整
- [ ] 配置说明清晰
- [ ] 故障排查指南
- [ ] 视频教程录制
- [ ] 示例项目提供

### 测试完成标准

- [ ] 单元测试覆盖率>70%
- [ ] 集成测试全部通过
- [ ] Beta测试反馈积极
- [ ] 无P0/P1级别Bug
- [ ] 压力测试通过

---

**祝实施顺利！有任何问题随时查阅本文档或查看详细技术方案。** 🚀
