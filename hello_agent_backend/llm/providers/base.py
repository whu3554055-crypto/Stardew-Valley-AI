"""
LLM Provider 抽象接口层

定义统一的 LLM 提供商接口，支持多种后端（Ollama, OpenAI, Qwen, Gemini 等）
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class LLMMessage(BaseModel):
    """统一的消息格式"""
    role: str = Field(..., description="消息角色: system, user, assistant")
    content: str = Field(..., description="消息内容")

    class Config:
        json_schema_extra = {
            "example": {
                "role": "user",
                "content": "你好！"
            }
        }


class LLMResponse(BaseModel):
    """统一的 LLM 响应格式"""
    content: str = Field(..., description="生成的文本内容")
    model: str = Field(..., description="使用的模型名称")
    provider: str = Field(..., description="提供商名称")
    usage: Dict[str, int] = Field(
        default_factory=dict,
        description="Token 使用统计: prompt_tokens, completion_tokens, total_tokens"
    )
    cost: float = Field(default=0.0, description="本次请求的成本（美元）")
    latency_ms: float = Field(default=0.0, description="请求延迟（毫秒）")

    class Config:
        json_schema_extra = {
            "example": {
                "content": "你好！我是村民 Pierre。",
                "model": "qwen3.5:9b",
                "provider": "ollama",
                "usage": {
                    "prompt_tokens": 20,
                    "completion_tokens": 15,
                    "total_tokens": 35
                },
                "cost": 0.0,
                "latency_ms": 150.5
            }
        }


class EmbeddingResponse(BaseModel):
    """嵌入向量响应"""
    embeddings: List[List[float]] = Field(..., description="嵌入向量列表")
    model: str = Field(..., description="使用的嵌入模型")
    provider: str = Field(..., description="提供商名称")
    usage: Dict[str, int] = Field(default_factory=dict, description="Token 使用统计")

    class Config:
        json_schema_extra = {
            "example": {
                "embeddings": [[0.1, 0.2, 0.3]],
                "model": "nomic-embed-text:latest",
                "provider": "ollama",
                "usage": {"total_tokens": 10}
            }
        }


class ProviderConfig(BaseModel):
    """提供商配置"""
    enabled: bool = Field(default=True, description="是否启用此提供商")
    priority: int = Field(default=99, description="优先级（数字越小优先级越高）")
    base_url: Optional[str] = Field(default=None, description="API 基础 URL")
    model: str = Field(..., description="模型名称")
    embedding_model: Optional[str] = Field(default=None, description="嵌入模型名称")
    context_window: int = Field(default=4096, description="上下文窗口大小")
    max_tokens: int = Field(default=2048, description="最大生成 token 数")
    temperature: float = Field(default=0.7, description="温度参数")
    use_for: List[str] = Field(
        default_factory=lambda: ["general"],
        description="适用的任务类型列表"
    )
    cost_per_1k_tokens: float = Field(default=0.0, description="每 1K tokens 的成本（美元）")
    rate_limit_rpm: int = Field(default=60, description="每分钟请求数限制")
    timeout_seconds: int = Field(default=30, description="请求超时时间（秒）")


class BaseLLMProvider(ABC):
    """
    LLM Provider 抽象基类

    所有 LLM 提供商必须实现此接口，确保可以无缝切换和组合使用。

    使用示例:
        provider = OllamaProvider(model="qwen3.5:9b")
        response = await provider.chat_completion([
            LLMMessage(role="user", content="你好")
        ])
        print(response.content)
    """

    @abstractmethod
    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        **kwargs
    ) -> LLMResponse:
        """
        聊天补全

        Args:
            messages: 消息列表
            temperature: 温度参数 (0.0 - 1.0)
            max_tokens: 最大生成 token 数
            **kwargs: 额外参数

        Returns:
            LLMResponse: 统一的响应对象

        Raises:
            Exception: 请求失败时抛出异常
        """
        pass

    @abstractmethod
    async def embedding(
        self,
        texts: List[str],
        **kwargs
    ) -> EmbeddingResponse:
        """
        文本嵌入

        Args:
            texts: 文本列表
            **kwargs: 额外参数

        Returns:
            EmbeddingResponse: 嵌入向量响应
        """
        pass

    @abstractmethod
    async def is_available(self) -> bool:
        """
        检查提供商是否可用

        Returns:
            bool: 是否可用
        """
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        """提供商名称标识"""
        pass

    @property
    @abstractmethod
    def model_name(self) -> str:
        """当前使用的模型名称"""
        pass

    def get_info(self) -> Dict[str, Any]:
        """获取提供商信息"""
        return {
            "name": self.name,
            "model": self.model_name,
            "type": self.__class__.__name__
        }
