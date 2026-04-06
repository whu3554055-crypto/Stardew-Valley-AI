# Hello-Agent Backend - 快速开始

Stardew Valley AI Agent 后端服务，支持多 LLM 提供商智能路由。

---

## 🚀 5 分钟快速启动

### 步骤 1: 安装依赖

```powershell
# Windows (PowerShell)
.\start.ps1

# 或手动安装
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### 步骤 2: 配置环境

```bash
# 复制配置文件
cp .env.example .env

# 编辑 .env，设置你的配置
```

**最小配置（仅使用本地 Ollama）：**
```bash
DEFAULT_LLM_PROVIDER=ollama
OLLAMA_MODEL=qwen3.5:9b
```

**完整配置（包含云端提供商）：**
```bash
# Qwen API Key（阿里云）
QWEN_API_KEY=your-dashscope-api-key

# Gemini API Key（Google）
GEMINI_API_KEY=your-gemini-api-key
```

### 步骤 3: 启动 Ollama（如果使用本地模型）

```bash
# 安装 Ollama: https://ollama.com/download

# 拉取模型
ollama pull qwen3.5:9b

# 启动服务
ollama serve
```

### 步骤 4: 启动后端服务

```powershell
# Windows
.\start.ps1

# 或手动启动
python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

### 步骤 5: 验证服务

访问 http://localhost:8080/docs 查看 API 文档

测试 API：
```bash
curl http://localhost:8080/health
```

---

## 📖 API 端点

### NPC 对话
```bash
POST /api/v1/npc/dialogue
{
  "npc_id": "pierre",
  "npc_name": "Pierre",
  "personality": {"traits": ["friendly"]},
  "context": {"time": "morning"},
  "player_message": "你好！"
}
```

### 通用聊天
```bash
POST /api/v1/chat
{
  "messages": [{"role": "user", "content": "你好"}],
  "task_type": "general"
}
```

### 故事生成
```bash
POST /api/v1/story/generate
{
  "prompt": "一个年轻人继承农场的故事",
  "genre": "fantasy"
}
```

### 文本嵌入
```bash
POST /api/v1/embedding
{
  "texts": ["春天播种", "夏天生长"]
}
```

### 提供商管理
```bash
GET /api/v1/providers   # 列出所有提供商
GET /api/v1/stats       # 使用统计
```

---

## 🔧 配置说明

### 切换 LLM 提供商

编辑 `.env`：

```bash
# 使用本地 Ollama（免费）
DEFAULT_LLM_PROVIDER=ollama

# 使用云端 Qwen（高质量中文）
DEFAULT_LLM_PROVIDER=qwen
QWEN_API_KEY=your-key

# 使用云端 Gemini（创意写作）
DEFAULT_LLM_PROVIDER=gemini
GEMINI_API_KEY=your-key
```

### 智能路由配置

编辑 `config/llm_config.json`：

```json
{
  "task_routing": {
    "npc_dialogue": "ollama",        // NPC对话用本地
    "story_generation": "qwen",      // 故事生成用Qwen
    "creative_writing": "gemini"     // 创意写作用Gemini
  }
}
```

---

## 🐛 常见问题

### Q1: 端口 8080 被占用？

修改 `.env`：
```bash
PORT=8081
```

同时更新 Godot 端的配置：
```gdscript
AIAgentManager.api_config.backend_url = "http://localhost:8081"
```

### Q2: Ollama 连接失败？

```bash
# 检查 Ollama 是否运行
ollama list

# 如果没有，启动服务
ollama serve
```

### Q3: 如何查看日志？

日志文件位置：`logs/backend.log`

或在控制台直接查看实时日志。

---

## 📚 更多文档

- [LLM 提供商快速开始](docs/LLM_PROVIDERS_QUICKSTART.md)
- [完整技术方案](../docs/01-技术架构与优化/06-多LLM提供商集成方案.md)
- [API 文档](http://localhost:8080/docs)（启动后访问）

---

## ✅ 验证清单

启动前确认：

- [ ] Python 3.11+ 已安装
- [ ] Ollama 已安装并运行（如使用本地模型）
- [ ] `.env` 文件已配置
- [ ] 端口 8080 未被占用
- [ ] 依赖已安装（`pip install -r requirements.txt`）

---

祝您使用愉快！🎮
