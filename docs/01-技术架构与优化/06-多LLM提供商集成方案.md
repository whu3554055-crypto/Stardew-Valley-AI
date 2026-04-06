# 多 LLM 提供商集成方案

## 📋 需求概述

实现灵活的 LLM 提供商切换和组合使用系统，支持：
- ✅ 本地 Ollama（运行 Qwen3.5:9B、Llama3 等）
- ✅ 云端 OpenAI（GPT-4、GPT-3.5）
- ✅ 云端 Qwen（阿里云 DashScope）
- ✅ 云端 Gemini（Google AI）
- ✅ 智能路由和组合策略
- ✅ 配置驱动的灵活切换

---

## 🏗️ 架构设计

### 核心原则

1. **抽象接口层** - 统一的 LLM Provider 接口
2. **配置驱动** - 通过配置文件切换提供商
3. **智能路由** - 根据场景自动选择最优提供商
4. **降级策略** - 主提供商失败时自动切换备用
5. **成本优化** - 简单任务用本地模型，复杂任务用云端

### 架构图

```
┌─────────────────────────────────────────────────────┐
│              Game Agent / NPC System                │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           LLM Router (智能路由器)                    │
│  - 场景识别                                         │
│  - 负载均衡                                         │
│  - 故障转移                                         │
│  - 成本优化                                         │
└────┬────────────┬────────────┬────────────┬────────┘
     │            │            │            │
     ▼            ▼            ▼            ▼
┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Ollama  │ │ OpenAI   │ │ Qwen     │ │ Gemini   │
│Provider │ │ Provider │ │ Provider │ │ Provider │
└─────────┘ └──────────┘ └──────────┘ └──────────┘
     │            │            │            │
     ▼            ▼            ▼            ▼
  Local HTTP   OpenAI API  DashScope    Google AI
  (localhost)  (cloud)     API (cloud)  API (cloud)
```

---

## 📝 配置示例

### `.env` 文件

```bash
# ============================================================================
# LLM Provider Configuration
# ============================================================================

# Default provider for general tasks
DEFAULT_LLM_PROVIDER=ollama

# Ollama Configuration (Local)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen3.5:9b
OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest

# OpenAI Configuration (Cloud)
OPENAI_API_KEY=sk-your-openai-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4-turbo
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

# Qwen Configuration (Alibaba Cloud DashScope)
QWEN_API_KEY=your-dashscope-api-key
QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v1
QWEN_MODEL=qwen-max
QWEN_EMBEDDING_MODEL=text-embedding-v2

# Gemini Configuration (Google AI)
GEMINI_API_KEY=your-gemini-key
GEMINI_MODEL=gemini-pro
GEMINI_EMBEDDING_MODEL=models/embedding-001

# ============================================================================
# Routing Strategy Configuration
# ============================================================================

# Enable smart routing
SMART_ROUTING_ENABLED=true

# Provider priority order (fallback chain)
PROVIDER_PRIORITY=ollama,qwen,gemini,openai

# Task-specific routing
ROUTING_NPC_DIALOGUE=ollama
ROUTING_STORY_GENERATION=qwen
ROUTING_EMOTION_ANALYSIS=gemini
ROUTING_COMPLEX_REASONING=openai

# Cost optimization thresholds
MAX_CLOUD_CALLS_PER_HOUR=100
CLOUD_FALLBACK_ON_ERROR=true

# Performance settings
REQUEST_TIMEOUT=30
MAX_RETRIES=3
RETRY_DELAY=2
```

### `llm_config.json` (高级配置)

```json
{
  "providers": {
    "ollama": {
      "enabled": true,
      "priority": 1,
      "base_url": "http://localhost:11434",
      "model": "qwen3.5:9b",
      "embedding_model": "nomic-embed-text:latest",
      "context_window": 32768,
      "max_tokens": 8192,
      "temperature": 0.7,
      "use_for": ["npc_dialogue", "emotion_analysis", "simple_reasoning"],
      "rate_limit": {
        "requests_per_minute": 60
      }
    },
    "qwen": {
      "enabled": true,
      "priority": 2,
      "base_url": "https://dashscope.aliyuncs.com/api/v1",
      "model": "qwen-max",
      "embedding_model": "text-embedding-v2",
      "context_window": 8192,
      "max_tokens": 2048,
      "temperature": 0.8,
      "use_for": ["story_generation", "complex_reasoning", "multi_language"],
      "cost_per_1k_tokens": 0.02,
      "rate_limit": {
        "requests_per_minute": 100
      }
    },
    "gemini": {
      "enabled": true,
      "priority": 3,
      "model": "gemini-pro",
      "embedding_model": "models/embedding-001",
      "context_window": 32768,
      "max_tokens": 8192,
      "temperature": 0.7,
      "use_for": ["emotion_analysis", "creative_writing", "multimodal"],
      "cost_per_1k_tokens": 0.0005,
      "rate_limit": {
        "requests_per_minute": 60
      }
    },
    "openai": {
      "enabled": false,
      "priority": 4,
      "model": "gpt-4-turbo",
      "embedding_model": "text-embedding-3-small",
      "context_window": 128000,
      "max_tokens": 4096,
      "temperature": 0.7,
      "use_for": ["complex_reasoning", "fallback"],
      "cost_per_1k_tokens": 0.01,
      "rate_limit": {
        "requests_per_minute": 200
      }
    }
  },
  "routing_strategy": {
    "mode": "smart",
    "fallback_enabled": true,
    "load_balancing": "priority",
    "cache_enabled": true,
    "cache_ttl_seconds": 3600
  },
  "monitoring": {
    "log_all_requests": true,
    "track_costs": true,
    "alert_on_high_usage": true,
    "daily_budget_usd": 5.0
  }
}
```

---

## 💻 代码实现

### 1. Provider 抽象接口

```python
# hello_agent_backend/llm/providers/base.py
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from pydantic import BaseModel


class LLMMessage(BaseModel):
    """统一的消息格式"""
    role: str  # "system", "user", "assistant"
    content: str


class LLMResponse(BaseModel):
    """统一的响应格式"""
    content: str
    model: str
    provider: str
    usage: Dict[str, int] = {}  # prompt_tokens, completion_tokens, total_tokens
    cost: float = 0.0


class EmbeddingResponse(BaseModel):
    """嵌入向量响应"""
    embeddings: List[List[float]]
    model: str
    provider: str


class BaseLLMProvider(ABC):
    """LLM Provider 抽象基类"""

    @abstractmethod
    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> LLMResponse:
        """聊天补全"""
        pass

    @abstractmethod
    async def embedding(
        self,
        texts: List[str],
        **kwargs
    ) -> EmbeddingResponse:
        """文本嵌入"""
        pass

    @abstractmethod
    async def is_available(self) -> bool:
        """检查提供商是否可用"""
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        """提供商名称"""
        pass

    @property
    @abstractmethod
    def model_name(self) -> str:
        """模型名称"""
        pass
```

### 2. Ollama Provider

```python
# hello_agent_backend/llm/providers/ollama_provider.py
import httpx
from typing import List, Optional
from .base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse


class OllamaProvider(BaseLLMProvider):
    """Ollama 本地 LLM 提供商"""

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "qwen3.5:9b",
        embedding_model: str = "nomic-embed-text:latest",
        timeout: int = 30
    ):
        self._base_url = base_url
        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout

    @property
    def name(self) -> str:
        return "ollama"

    @property
    def model_name(self) -> str:
        return self._model

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> LLMResponse:
        """调用 Ollama API"""
        url = f"{self._base_url}/api/chat"

        payload = {
            "model": self._model,
            "messages": [msg.dict() for msg in messages],
            "options": {
                "temperature": temperature,
            }
        }

        if max_tokens:
            payload["options"]["num_predict"] = max_tokens

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()

        return LLMResponse(
            content=data["message"]["content"],
            model=self._model,
            provider="ollama",
            usage={
                "prompt_tokens": data.get("prompt_eval_count", 0),
                "completion_tokens": data.get("eval_count", 0),
                "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0)
            }
        )

    async def embedding(self, texts: List[str], **kwargs) -> EmbeddingResponse:
        """生成嵌入向量"""
        url = f"{self._base_url}/api/embeddings"

        embeddings = []
        for text in texts:
            payload = {
                "model": self._embedding_model,
                "prompt": text
            }

            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()

            embeddings.append(data["embedding"])

        return EmbeddingResponse(
            embeddings=embeddings,
            model=self._embedding_model,
            provider="ollama"
        )

    async def is_available(self) -> bool:
        """检查 Ollama 服务是否运行"""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self._base_url}/api/tags")
                return response.status_code == 200
        except Exception:
            return False
```

### 3. Qwen Provider (DashScope)

```python
# hello_agent_backend/llm/providers/qwen_provider.py
import httpx
from typing import List, Optional
from .base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse


class QwenProvider(BaseLLMProvider):
    """阿里云 Qwen (DashScope) 提供商"""

    def __init__(
        self,
        api_key: str,
        base_url: str = "https://dashscope.aliyuncs.com/api/v1",
        model: str = "qwen-max",
        embedding_model: str = "text-embedding-v2",
        timeout: int = 30
    ):
        self._api_key = api_key
        self._base_url = base_url
        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout
        self._headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    @property
    def name(self) -> str:
        return "qwen"

    @property
    def model_name(self) -> str:
        return self._model

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> LLMResponse:
        """调用 DashScope API"""
        url = f"{self._base_url}/services/aigc/text-generation/generation"

        payload = {
            "model": self._model,
            "input": {
                "messages": [msg.dict() for msg in messages]
            },
            "parameters": {
                "temperature": temperature,
            }
        }

        if max_tokens:
            payload["parameters"]["max_tokens"] = max_tokens

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(
                url,
                headers=self._headers,
                json=payload
            )
            response.raise_for_status()
            data = response.json()

        output = data["output"]
        usage = data.get("usage", {})

        # 计算成本（约 0.02元/1K tokens）
        total_tokens = usage.get("total_tokens", 0)
        cost = (total_tokens / 1000) * 0.02

        return LLMResponse(
            content=output["choices"][0]["message"]["content"],
            model=self._model,
            provider="qwen",
            usage=usage,
            cost=cost
        )

    async def embedding(self, texts: List[str], **kwargs) -> EmbeddingResponse:
        """生成嵌入向量"""
        url = f"{self._base_url}/services/embeddings/text-embedding/text-embedding"

        payload = {
            "model": self._embedding_model,
            "input": {
                "texts": texts
            }
        }

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(
                url,
                headers=self._headers,
                json=payload
            )
            response.raise_for_status()
            data = response.json()

        embeddings = [item["embedding"] for item in data["output"]["embeddings"]]

        return EmbeddingResponse(
            embeddings=embeddings,
            model=self._embedding_model,
            provider="qwen"
        )

    async def is_available(self) -> bool:
        """检查 API 是否可用"""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                # 简单测试调用
                response = await client.get(
                    f"{self._base_url}/models",
                    headers=self._headers
                )
                return response.status_code == 200
        except Exception:
            return False
```

### 4. Gemini Provider

```python
# hello_agent_backend/llm/providers/gemini_provider.py
import httpx
from typing import List, Optional
from .base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse


class GeminiProvider(BaseLLMProvider):
    """Google Gemini 提供商"""

    def __init__(
        self,
        api_key: str,
        model: str = "gemini-pro",
        embedding_model: str = "models/embedding-001",
        timeout: int = 30
    ):
        self._api_key = api_key
        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout
        self._base_url = "https://generativelanguage.googleapis.com/v1beta"

    @property
    def name(self) -> str:
        return "gemini"

    @property
    def model_name(self) -> str:
        return self._model

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> LLMResponse:
        """调用 Gemini API"""
        url = f"{self._base_url}/models/{self._model}:generateContent"

        # 转换消息格式为 Gemini 格式
        contents = []
        for msg in messages:
            contents.append({
                "role": "user" if msg.role in ["user", "system"] else "model",
                "parts": [{"text": msg.content}]
            })

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
            }
        }

        if max_tokens:
            payload["generationConfig"]["maxOutputTokens"] = max_tokens

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(
                url,
                params={"key": self._api_key},
                json=payload
            )
            response.raise_for_status()
            data = response.json()

        content = data["candidates"][0]["content"]["parts"][0]["text"]

        # 估算 token 使用量
        prompt_tokens = sum(len(msg.content.split()) for msg in messages)
        completion_tokens = len(content.split())

        # Gemini 免费层级足够开发使用
        cost = 0.0

        return LLMResponse(
            content=content,
            model=self._model,
            provider="gemini",
            usage={
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens
            },
            cost=cost
        )

    async def embedding(self, texts: List[str], **kwargs) -> EmbeddingResponse:
        """生成嵌入向量"""
        url = f"{self._base_url}/{self._embedding_model}:embedContent"

        embeddings = []
        for text in texts:
            payload = {
                "model": self._embedding_model,
                "content": {
                    "parts": [{"text": text}]
                }
            }

            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    url,
                    params={"key": self._api_key},
                    json=payload
                )
                response.raise_for_status()
                data = response.json()

            embeddings.append(data["embedding"]["values"])

        return EmbeddingResponse(
            embeddings=embeddings,
            model=self._embedding_model,
            provider="gemini"
        )

    async def is_available(self) -> bool:
        """检查 API 是否可用"""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(
                    f"{self._base_url}/models",
                    params={"key": self._api_key}
                )
                return response.status_code == 200
        except Exception:
            return False
```

### 5. 智能路由器

```python
# hello_agent_backend/llm/router.py
import json
import logging
from typing import Dict, List, Optional, Any
from .providers.base import BaseLLMProvider, LLMMessage, LLMResponse
from .providers.ollama_provider import OllamaProvider
from .providers.qwen_provider import QwenProvider
from .providers.gemini_provider import GeminiProvider

logger = logging.getLogger(__name__)


class LLMRouter:
    """智能 LLM 路由器"""

    def __init__(self, config_path: str = "config/llm_config.json"):
        self.config = self._load_config(config_path)
        self.providers: Dict[str, BaseLLMProvider] = {}
        self.routing_rules = self.config.get("routing_strategy", {})
        self._initialize_providers()

    def _load_config(self, config_path: str) -> dict:
        """加载配置文件"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning(f"Config file not found: {config_path}, using defaults")
            return self._default_config()

    def _default_config(self) -> dict:
        """默认配置"""
        return {
            "providers": {
                "ollama": {"enabled": True, "priority": 1},
                "qwen": {"enabled": False, "priority": 2},
                "gemini": {"enabled": False, "priority": 3}
            },
            "routing_strategy": {
                "mode": "priority",
                "fallback_enabled": True
            }
        }

    def _initialize_providers(self):
        """初始化所有启用的提供商"""
        providers_config = self.config.get("providers", {})

        if providers_config.get("ollama", {}).get("enabled"):
            ollama_cfg = providers_config["ollama"]
            self.providers["ollama"] = OllamaProvider(
                base_url=ollama_cfg.get("base_url", "http://localhost:11434"),
                model=ollama_cfg.get("model", "qwen3.5:9b")
            )
            logger.info("✓ Ollama provider initialized")

        if providers_config.get("qwen", {}).get("enabled"):
            import os
            qwen_cfg = providers_config["qwen"]
            api_key = os.getenv("QWEN_API_KEY")
            if api_key:
                self.providers["qwen"] = QwenProvider(
                    api_key=api_key,
                    model=qwen_cfg.get("model", "qwen-max")
                )
                logger.info("✓ Qwen provider initialized")
            else:
                logger.warning("QWEN_API_KEY not set, skipping Qwen provider")

        if providers_config.get("gemini", {}).get("enabled"):
            import os
            gemini_cfg = providers_config["gemini"]
            api_key = os.getenv("GEMINI_API_KEY")
            if api_key:
                self.providers["gemini"] = GeminiProvider(
                    api_key=api_key,
                    model=gemini_cfg.get("model", "gemini-pro")
                )
                logger.info("✓ Gemini provider initialized")
            else:
                logger.warning("GEMINI_API_KEY not set, skipping Gemini provider")

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        task_type: str = "general",
        **kwargs
    ) -> LLMResponse:
        """
        智能路由聊天请求

        Args:
            messages: 消息列表
            task_type: 任务类型 (npc_dialogue, story_generation, etc.)
            **kwargs: 额外参数
        """
        # 确定目标提供商
        target_provider = self._select_provider(task_type)

        if not target_provider:
            raise Exception("No available LLM provider")

        # 尝试调用，失败则降级
        last_error = None
        for provider_name in self._get_fallback_chain(target_provider):
            if provider_name not in self.providers:
                continue

            provider = self.providers[provider_name]

            if not await provider.is_available():
                logger.warning(f"Provider {provider_name} is not available")
                continue

            try:
                logger.info(f"Using provider: {provider_name} for task: {task_type}")
                response = await provider.chat_completion(messages, **kwargs)
                logger.info(f"✓ Success with {provider_name}")
                return response
            except Exception as e:
                last_error = e
                logger.error(f"Provider {provider_name} failed: {e}")
                continue

        raise Exception(f"All providers failed. Last error: {last_error}")

    def _select_provider(self, task_type: str) -> Optional[str]:
        """根据任务类型选择最优提供商"""
        routing_mode = self.routing_rules.get("mode", "priority")

        if routing_mode == "smart":
            # 智能路由：根据任务类型映射
            task_mapping = {
                "npc_dialogue": "ollama",
                "emotion_analysis": "ollama",
                "story_generation": "qwen",
                "complex_reasoning": "qwen",
                "creative_writing": "gemini",
                "translation": "qwen",
            }
            preferred = task_mapping.get(task_type, "ollama")

            if preferred in self.providers:
                return preferred

        # 默认：按优先级选择第一个可用的
        sorted_providers = sorted(
            self.config.get("providers", {}).items(),
            key=lambda x: x[1].get("priority", 99)
        )

        for name, cfg in sorted_providers:
            if cfg.get("enabled") and name in self.providers:
                return name

        return None

    def _get_fallback_chain(self, primary: str) -> List[str]:
        """获取降级链"""
        if not self.routing_rules.get("fallback_enabled", True):
            return [primary]

        all_providers = list(self.providers.keys())
        fallback_order = [primary] + [p for p in all_providers if p != primary]

        return fallback_order

    async def get_embedding(self, texts: List[str], **kwargs):
        """获取文本嵌入（优先使用本地）"""
        # 优先使用 Ollama（免费）
        if "ollama" in self.providers:
            try:
                return await self.providers["ollama"].embedding(texts, **kwargs)
            except Exception as e:
                logger.error(f"Ollama embedding failed: {e}")

        # 降级到云端
        for name, provider in self.providers.items():
            if name != "ollama":
                try:
                    return await provider.embedding(texts, **kwargs)
                except Exception as e:
                    logger.error(f"{name} embedding failed: {e}")

        raise Exception("All embedding providers failed")

    def get_provider_stats(self) -> Dict[str, Any]:
        """获取所有提供商状态"""
        stats = {}
        for name, provider in self.providers.items():
            stats[name] = {
                "available": False,  # 需要异步检查
                "model": provider.model_name
            }
        return stats
```

---

## 🎯 使用示例

### 基础使用

```python
# 初始化路由器
router = LLMRouter("config/llm_config.json")

# NPC 对话（自动使用 Ollama）
response = await router.chat_completion(
    messages=[
        LLMMessage(role="system", content="你是友好的村民 Pierre"),
        LLMMessage(role="user", content="你好！今天天气怎么样？")
    ],
    task_type="npc_dialogue"
)

print(response.content)
print(f"Provider: {response.provider}")
print(f"Cost: ${response.cost:.4f}")
```

### 切换提供商

```python
# 修改 .env 文件
DEFAULT_LLM_PROVIDER=qwen

# 或在代码中指定
response = await router.chat_completion(
    messages=messages,
    task_type="story_generation"  # 自动使用 Qwen
)
```

---

## 📊 对比分析

| 特性 | Ollama (本地) | Qwen (云端) | Gemini (云端) | OpenAI (云端) |
|------|--------------|-------------|---------------|---------------|
| **成本** | 免费 | $0.02/1K tokens | 免费层级 | $0.01/1K tokens |
| **延迟** | 低（本地） | 中 | 中 | 中 |
| **隐私** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **质量** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **可用性** | 需本地运行 | 99.9% | 99.9% | 99.9% |
| **推荐场景** | NPC对话、日常任务 | 故事生成、推理 | 创意写作 | 复杂推理 |

---

## ✅ 实施清单

- [ ] 创建 Provider 抽象接口
- [ ] 实现 Ollama Provider
- [ ] 实现 Qwen Provider
- [ ] 实现 Gemini Provider
- [ ] 实现智能路由器
- [ ] 创建配置文件模板
- [ ] 编写单元测试
- [ ] 更新文档
