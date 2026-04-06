# 记忆系统和 MCP 协议完整指南

本文档详细介绍 NPC 长期记忆系统和 MCP 工具调用协议的使用。

---

## 📚 目录

1. [向量记忆系统](#向量记忆系统)
2. [MCP 协议适配器](#mcp-协议适配器)
3. [API 端点](#api-端点)
4. [使用示例](#使用示例)
5. [最佳实践](#最佳实践)

---

## 🧠 向量记忆系统

### 架构概述

```
┌─────────────────────────────────────┐
│     NPC Dialogue Request            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   VectorMemoryStore                 │
│   - Generate embedding (Ollama)     │
│   - Search LanceDB (semantic)       │
│   - Filter by NPC/importance/day    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Relevant Memories Retrieved       │
│   - Memory 1: "Player gave gift"    │
│   - Memory 2: "Player helped farm"  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   LLM generates response with       │
│   memory-aware context              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Store new conversation as memory  │
└─────────────────────────────────────┘
```

### 核心功能

#### 1. 添加记忆

```python
from app.services.memory_store import VectorMemoryStore

store = VectorMemoryStore()

# 添加简单记忆
await store.add_memory(
    npc_id="pierre",
    content="Player gave me a parsnip as a gift",
    metadata={
        "emotion": "happy",
        "importance": 0.9,
        "day": 5,
        "type": "gift_received"
    }
)

# 添加事件记忆
await store.add_memory(
    npc_id="abigail",
    content="Player defeated monsters in the mines with me",
    metadata={
        "emotion": "excited",
        "importance": 0.95,
        "day": 12,
        "type": "event",
        "location": "mines"
    }
)
```

#### 2. 语义搜索记忆

```python
# 搜索相关记忆
memories = await store.search_similar(
    query="player helped me with farming",
    npc_id="pierre",
    limit=3,
    min_importance=0.5
)

for mem in memories:
    print(f"Day {mem.day}: {mem.content}")
    print(f"  Emotion: {mem.emotion}, Importance: {mem.importance:.2f}")
```

**搜索结果示例：**
```
Day 10: Player helped me water my crops when I was sick
  Emotion: grateful, Importance: 0.95

Day 8: Player gave me fertilizer for my garden
  Emotion: happy, Importance: 0.75
```

#### 3. 获取最近记忆

```python
# 获取 Pierre 最近的 5 条记忆
recent = await store.get_recent_memories("pierre", limit=5)

# 获取特定日期的记忆
day_10_memories = await store.get_recent_memories("pierre", day=10)
```

#### 4. 获取重要记忆

```python
# 获取高重要性记忆（用于构建 NPC 性格）
important = await store.get_important_memories(
    npc_id="pierre",
    min_importance=0.7,
    limit=5
)
```

#### 5. 记忆统计

```python
stats = await store.get_memory_stats()
print(stats)
# {
#     "total_memories": 150,
#     "memories_by_npc": {"pierre": 50, "abigail": 45, ...},
#     "average_importance": 0.65,
#     "embedding_dimension": 384
# }
```

### 记忆类型

| 类型 | 描述 | 示例 |
|------|------|------|
| `conversation` | 日常对话 | "Player said hello" |
| `gift_received` | 收到礼物 | "Player gave me a diamond" |
| `gift_given` | 送出礼物 | "I gave player a cake" |
| `favor_received` | 接受帮助 | "Player helped harvest crops" |
| `event` | 重要事件 | "Attended flower dance together" |
| `observation` | 观察记录 | "Player seems to like ancient fruit" |
| `preference` | 偏好学习 | "Player dislikes fishing" |

### 重要性评分

| 分数范围 | 含义 | 示例 |
|---------|------|------|
| 0.9 - 1.0 | 极其重要 | 救命之恩、重大礼物 |
| 0.7 - 0.9 | 很重要 | 帮助农活、参加节日 |
| 0.5 - 0.7 | 中等重要 | 普通对话、小礼物 |
| 0.3 - 0.5 | 不太重要 | 日常问候 |
| 0.0 - 0.3 | 微不足道 | 路过打招呼 |

---

## 🔧 MCP 协议适配器

### 什么是 MCP？

MCP (Model Context Protocol) 是标准化的 AI Agent 工具调用协议，基于 JSON-RPC 2.0。

**优势：**
- ✅ 标准化消息格式
- ✅ 动态工具发现
- ✅ 类型安全的参数
- ✅ 统一的错误处理

### 注册自定义工具

```python
from app.core.mcp_protocol import game_mcp

# 注册新工具
game_mcp.register_tool(
    name="check_weather_forecast",
    description="Get weather forecast for next 3 days",
    handler=lambda days: weather_service.get_forecast(days),
    parameters={
        "type": "object",
        "properties": {
            "days": {
                "type": "integer",
                "description": "Number of days to forecast (1-7)",
                "minimum": 1,
                "maximum": 7
            }
        },
        "required": ["days"]
    }
)
```

### 调用工具

```python
# 通过 MCP 调用工具
response = await game_mcp.handle_request({
    "jsonrpc": "2.0",
    "id": "req-123",
    "method": "get_npc_info",
    "params": {"npc_id": "pierre"}
})

print(response)
# {
#     "jsonrpc": "2.0",
#     "id": "req-123",
#     "result": {
#         "npc_id": "pierre",
#         "name": "Pierre",
#         "location": "general_store",
#         "mood": "happy"
#     },
#     "error": null
# }
```

### 内置工具列表

| 工具名 | 描述 | 参数 |
|--------|------|------|
| `get_npc_info` | 获取 NPC 详细信息 | `npc_id` |
| `get_world_state` | 获取世界状态 | 无 |
| `get_relationship` | 获取关系等级 | `npc_id`, `player_id` |
| `place_item` | 放置物品 | `item_id`, `location_x`, `location_y` |
| `get_inventory` | 获取玩家背包 | `player_id` |

---

## 🌐 API 端点

### 记忆管理

#### 获取记忆统计
```bash
GET /api/v1/memory/stats
```

**响应：**
```json
{
    "total_memories": 150,
    "memories_by_npc": {
        "pierre": 50,
        "abigail": 45
    },
    "average_importance": 0.65
}
```

#### 获取 NPC 最近记忆
```bash
GET /api/v1/memory/{npc_id}/recent?limit=10
```

**响应：**
```json
{
    "npc_id": "pierre",
    "memories": [
        {
            "id": "uuid-123",
            "content": "Player gave me a parsnip",
            "emotion": "happy",
            "importance": 0.9,
            "day": 5,
            "created_at": "2024-01-15T10:30:00"
        }
    ]
}
```

#### 清除 NPC 记忆
```bash
DELETE /api/v1/memory/{npc_id}
```

### MCP 工具

#### 列出所有工具
```bash
GET /api/v1/mcp/tools
```

**响应：**
```json
{
    "tools": {
        "get_npc_info": {
            "description": "Get detailed information about an NPC",
            "parameters": {
                "type": "object",
                "properties": {
                    "npc_id": {"type": "string"}
                }
            }
        }
    },
    "stats": {
        "total_tools": 5,
        "registered_tools": ["get_npc_info", "get_world_state", ...]
    }
}
```

#### 调用工具
```bash
POST /api/v1/mcp/call
Content-Type: application/json

{
    "jsonrpc": "2.0",
    "id": "req-123",
    "method": "get_npc_info",
    "params": {"npc_id": "pierre"}
}
```

**响应：**
```json
{
    "jsonrpc": "2.0",
    "id": "req-123",
    "result": {
        "npc_id": "pierre",
        "name": "Pierre",
        "location": "general_store"
    },
    "error": null
}
```

---

## 💡 使用示例

### 示例 1：记忆驱动的 NPC 对话

```python
# 1. 玩家与 NPC 对话
player_message = "Hey Pierre! Remember when I helped you with the harvest?"

# 2. 检索相关记忆
relevant_memories = await memory_store.search_similar(
    query=player_message,
    npc_id="pierre",
    limit=3
)

# 3. 构建包含记忆的 prompt
system_prompt = "You are Pierre.\n\nRelevant memories:\n"
for mem in relevant_memories:
    system_prompt += f"- {mem.content} (Day {mem.day})\n"

# 4. LLM 生成回应（会引用记忆）
# "Oh yes! I remember how you helped me water the crops when I was sick. 
#  I'm still grateful for that!"

# 5. 存储新对话为记忆
await memory_store.add_memory(
    npc_id="pierre",
    content=f"Player mentioned helping with harvest",
    metadata={"type": "conversation", "day": 15}
)
```

### 示例 2：Agent 自主调用工具

```python
# Agent 决定查询 NPC 信息
tool_call = {
    "jsonrpc": "2.0",
    "id": "agent-decision-1",
    "method": "get_npc_info",
    "params": {"npc_id": "pierre"}
}

response = await game_mcp.handle_request(tool_call)

# Agent 根据返回信息做决策
if response["result"]["mood"] == "happy":
    # NPC 心情好，可以请求帮助
    action = "ask_for_quest"
else:
    # NPC 心情不好，先送礼物
    action = "give_gift"
```

### 示例 3：运行演示脚本

```bash
# 进入项目目录
cd hello_agent_backend

# 运行演示
python examples/memory_and_mcp_demo.py
```

---

## 🎯 最佳实践

### 记忆管理

✅ **推荐做法：**

1. **设置合理的重要性阈值**
   ```python
   # 只检索重要性 > 0.5 的记忆
   memories = await store.search_similar(
       query="...",
       min_importance=0.5
   )
   ```

2. **定期清理低重要性记忆**
   ```python
   # 每月清理一次
   deleted = await store.forget_unimportant_memories(
       max_age_days=30,
       importance_threshold=0.3
   )
   ```

3. **使用元数据过滤**
   ```python
   # 只搜索对话类型的记忆
   memories = await store.search_similar(
       query="...",
       memory_type="conversation"
   )
   ```

❌ **避免的做法：**

1. **不要存储过多琐碎记忆**
   ```python
   # ❌ 坏例子：每次路过都记录
   await store.add_memory("Player walked past me")
   
   # ✅ 好例子：只记录有意义的互动
   await store.add_memory("Player stopped to chat for 5 minutes")
   ```

2. **不要忘记设置重要性**
   ```python
   # ❌ 坏例子：默认重要性 0.5
   await store.add_memory(npc_id="pierre", content="...")
   
   # ✅ 好例子：明确指定重要性
   await store.add_memory(
       npc_id="pierre",
       content="...",
       metadata={"importance": 0.8}
   )
   ```

### MCP 工具使用

✅ **推荐做法：**

1. **提供清晰的工具描述**
   ```python
   game_mcp.register_tool(
       name="get_weather",
       description="Get current weather and 3-day forecast (used for farming decisions)",
       handler=...
   )
   ```

2. **定义严格的参数 schema**
   ```python
   parameters={
       "type": "object",
       "properties": {
           "npc_id": {
               "type": "string",
               "pattern": "^[a-z_]+$",  # 验证格式
               "description": "NPC identifier (lowercase with underscores)"
           }
       },
       "required": ["npc_id"]
   }
   ```

3. **处理异步和同步函数**
   ```python
   # 异步 handler
   async def get_async_data(npc_id: str):
       return await db.query(npc_id)
   
   # 同步 handler（自动在线程池运行）
   def get_sync_data(npc_id: str):
       return cache.get(npc_id)
   
   # 两者都可以注册
   game_mcp.register_tool("async_tool", "...", get_async_data)
   game_mcp.register_tool("sync_tool", "...", get_sync_data)
   ```

---

## 🔗 相关文档

- [LLM 提供商快速开始](LLM_PROVIDERS_QUICKSTART.md)
- [多 LLM 集成方案](../../docs/01-技术架构与优化/06-多LLM提供商集成方案.md)
- [API 文档](http://localhost:8080/docs)（启动后访问）

---

## 📊 性能指标

| 操作 | 延迟 | 说明 |
|------|------|------|
| 添加记忆 | ~100-200ms | 包含嵌入生成 |
| 语义搜索 | ~50-150ms | 取决于数据库大小 |
| 工具调用 | <10ms | 纯内存操作 |
| 记忆检索 + 对话 | ~500-1000ms | 端到端总延迟 |

---

## 🎓 学习资源

- **LanceDB 官方文档**: https://lancedb.github.io/lancedb/
- **JSON-RPC 2.0 规范**: https://www.jsonrpc.org/specification
- **MCP 协议**: https://modelcontextprotocol.io/

---

祝您使用愉快！🚀
