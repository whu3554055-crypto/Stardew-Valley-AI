# 多 LLM 提供商快速开始指南

5 分钟快速上手灵活的多 LLM 提供商系统！

---

## 🚀 快速开始（3 步）

### 步骤 1: 安装 Ollama（本地模型，推荐）

**Windows/Mac/Linux:**
```bash
# 下载并安装
curl -fsSL https://ollama.com/install.sh | sh  # Linux/Mac
# Windows: 访问 https://ollama.com/download

# 拉取模型
ollama pull qwen3.5:9b
ollama pull nomic-embed-text:latest

# 启动服务
ollama serve
```

### 步骤 2: 配置环境变量

复制 `.env.example` 为 `.env`：

```bash
cd hello_agent_backend
cp .env.example .env
```

编辑 `.env`，设置默认提供商：

```bash
# 使用本地 Ollama（免费，推荐开发使用）
DEFAULT_LLM_PROVIDER=ollama
OLLAMA_MODEL=qwen3.5:9b

# 或者使用云端 Qwen（需要 API Key）
# DEFAULT_LLM_PROVIDER=qwen
# QWEN_API_KEY=your-api-key-here
```

### 步骤 3: 运行测试

```bash
# 安装依赖
pip install -r requirements.txt

# 运行示例
python examples/llm_router_demo.py

# 运行测试
pytest tests/test_llm_providers.py -v
```

---

## 📋 可用提供商对比

| 提供商 | 设置难度 | 成本 | 延迟 | 推荐场景 |
|--------|---------|------|------|----------|
| **Ollama** (本地) | ⭐ 简单 | 免费 | 低 | NPC 对话、日常任务 |
| **Qwen** (云端) | ⭐⭐ 中等 | $0.002/1K | 中 | 故事生成、复杂推理 |
| **Gemini** (云端) | ⭐⭐ 中等 | 免费层级 | 中 | 创意写作 |

---

## 🔧 切换提供商

### 方法 1: 修改 .env 文件

```bash
# 切换到 Qwen
DEFAULT_LLM_PROVIDER=qwen
QWEN_API_KEY=your-key-here

# 切换到 Gemini
DEFAULT_LLM_PROVIDER=gemini
GEMINI_API_KEY=your-key-here
```

### 方法 2: 代码中指定

```python
from llm.router import LLMRouter
from llm.providers.base import LLMMessage

router = LLMRouter()

# 强制使用特定提供商
response = await router.chat_completion(
    messages=[LLMMessage(role="user", content="你好")],
    force_provider="qwen"  # 强制使用 Qwen
)
```

### 方法 3: 智能路由（自动选择）

```python
# 根据任务类型自动选择最优提供商
response = await router.chat_completion(
    messages=messages,
    task_type="npc_dialogue"  # 自动使用 Ollama
)

response = await router.chat_completion(
    messages=messages,
    task_type="story_generation"  # 自动使用 Qwen
)
```

---

## 💻 代码示例

### 基础用法

```python
from llm.router import LLMRouter
from llm.providers.base import LLMMessage

# 初始化路由器
router = LLMRouter("config/llm_config.json")

# NPC 对话
messages = [
    LLMMessage(role="system", content="你是村民 Pierre"),
    LLMMessage(role="user", content="你好！")
]

response = await router.chat_completion(
    messages=messages,
    task_type="npc_dialogue"
)

print(f"Pierre: {response.content}")
print(f"提供商: {response.provider}")
print(f"成本: ${response.cost:.4f}")
```

### 获取文本嵌入

```python
# 用于向量搜索、语义匹配
texts = ["春天播种", "夏天生长", "秋天收获"]

embedding_response = await router.get_embedding(texts=texts)
print(f"向量维度: {len(embedding_response.embeddings[0])}")
```

### 监控和统计

```python
# 查看各提供商使用情况
stats = router.get_provider_stats()
for provider, data in stats.items():
    print(f"{provider}: {data['success_rate']} 成功率")

# 查看预算
budget = router.get_budget_info()
print(f"今日已用: ${budget['current_usage']:.4f}")
print(f"剩余预算: ${budget['remaining']:.4f}")
```

---

## 🎯 获取 API Keys

### Qwen (阿里云 DashScope)

1. 访问 https://dashscope.console.aliyun.com/
2. 注册/登录阿里云账号
3. 创建 API Key
4. 充值（新用户有免费额度）

### Gemini (Google AI)

1. 访问 https://makersuite.google.com/app/apikey
2. 登录 Google 账号
3. 创建 API Key
4. 免费层级：60 RPM，足够开发使用

---

## 🐛 常见问题

### Q1: Ollama 连接失败？

```bash
# 检查 Ollama 是否运行
ollama list

# 如果没有运行，启动服务
ollama serve

# 测试 API
curl http://localhost:11434/api/tags
```

### Q2: 如何查看可用的 Ollama 模型？

```bash
# 列出已安装的模型
ollama list

# 搜索新模型
ollama search llama3

# 拉取模型
ollama pull llama3:8b
```

### Q3: 成本控制？

在 `config/llm_config.json` 中设置预算：

```json
{
  "monitoring": {
    "daily_budget_usd": 5.0
  }
}
```

### Q4: 如何添加新的提供商？

1. 创建 Provider 类（继承 `BaseLLMProvider`）
2. 在 `router.py` 中注册
3. 更新配置文件

参考 `ollama_provider.py` 的实现。

---

## 📚 更多资源

- [完整技术文档](../../docs/01-技术架构与优化/06-多LLM提供商集成方案.md)
- [API 参考](../llm/providers/base.py)
- [示例代码](../examples/llm_router_demo.py)
- [单元测试](../tests/test_llm_providers.py)

---

## ✅ 检查清单

开始前确认：

- [ ] Ollama 已安装并运行
- [ ] 至少有一个模型已拉取（如 `qwen3.5:9b`）
- [ ] `.env` 文件已配置
- [ ] 依赖已安装（`pip install -r requirements.txt`）
- [ ] 测试通过（`pytest tests/test_llm_providers.py -v`）

---

祝您使用愉快！🎮
