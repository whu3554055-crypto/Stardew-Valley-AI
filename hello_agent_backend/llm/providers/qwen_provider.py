"""
Qwen Provider - 阿里云 DashScope API

支持阿里云通义千问系列模型（Qwen-Max, Qwen-Plus, Qwen-Turbo 等）。

获取 API Key:
    1. 访问 https://dashscope.console.aliyun.com/
    2. 注册/登录阿里云账号
    3. 创建 API Key

定价参考 (2024):
    - Qwen-Max: ¥0.04/1K tokens (输入), ¥0.12/1K tokens (输出)
    - Qwen-Plus: ¥0.008/1K tokens (输入), ¥0.02/1K tokens (输出)
    - Qwen-Turbo: ¥0.002/1K tokens (输入), ¥0.006/1K tokens (输出)

使用示例:
    provider = QwenProvider(
        api_key="your-dashscope-api-key",
        model="qwen-max"
    )

    response = await provider.chat_completion([
        LLMMessage(role="user", content="你好！")
    ])
    print(response.content)
"""

import httpx
import time
import logging
import os
from typing import List, Optional, Dict, Any
from .base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse

logger = logging.getLogger(__name__)


class QwenProvider(BaseLLMProvider):
    """
    阿里云 Qwen (DashScope) 提供商

    特点:
    - 高质量中文理解
    - 强大的推理能力
    - 支持长上下文（最高 256K）
    - 按用量付费

    可用模型:
    - qwen-max: 最强性能，复杂任务
    - qwen-plus: 平衡性能和成本
    - qwen-turbo: 快速响应，简单任务
    - qwen-long: 超长上下文（256K）
    """

    # DashScope API 端点
    CHAT_ENDPOINT = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
    EMBEDDING_ENDPOINT = "https://dashscope.aliyuncs.com/api/v1/services/embeddings/text-embedding/text-embedding"

    # 模型定价（每 1K tokens，美元）
    MODEL_PRICING = {
        "qwen-max": {"input": 0.006, "output": 0.018},
        "qwen-plus": {"input": 0.0012, "output": 0.003},
        "qwen-turbo": {"input": 0.0003, "output": 0.0009},
        "qwen-long": {"input": 0.0007, "output": 0.002},
    }

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "qwen-plus",
        embedding_model: str = "text-embedding-v2",
        timeout: int = 30,
        **kwargs
    ):
        """
        初始化 Qwen Provider

        Args:
            api_key: DashScope API Key（如果为 None，从环境变量读取）
            model: 聊天模型名称
            embedding_model: 嵌入模型名称
            timeout: 请求超时时间（秒）
            **kwargs: 额外参数
        """
        self._api_key = api_key or os.getenv("QWEN_API_KEY", "")
        if not self._api_key:
            raise ValueError(
                "QWEN_API_KEY is required. Set it via parameter or environment variable."
            )

        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout
        self._extra_params = kwargs

        self._headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
            "X-DashScope-SSE": "disable"  # 禁用 SSE
        }

        logger.info(f"QwenProvider initialized: model={model}")

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
        top_p: float = 0.8,
        **kwargs
    ) -> LLMResponse:
        """
        调用 DashScope Chat API

        Args:
            messages: 消息列表
            temperature: 温度参数 (0.0 - 2.0)
            max_tokens: 最大生成 token 数
            top_p: 核采样参数
            **kwargs: 额外参数

        Returns:
            LLMResponse: 响应对象

        Raises:
            ValueError: API Key 未设置
            httpx.HTTPError: HTTP 请求失败
        """
        if not self._api_key:
            raise ValueError("QWEN_API_KEY is not set")

        start_time = time.time()

        payload: Dict[str, Any] = {
            "model": self._model,
            "input": {
                "messages": [msg.model_dump() for msg in messages]
            },
            "parameters": {
                "temperature": temperature,
                "top_p": top_p,
                "result_format": "message"
            }
        }

        if max_tokens:
            payload["parameters"]["max_tokens"] = max_tokens

        # 添加额外参数
        payload["parameters"].update(kwargs)

        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    self.CHAT_ENDPOINT,
                    headers=self._headers,
                    json=payload
                )

                # 处理错误响应
                if response.status_code != 200:
                    error_data = response.json()
                    error_msg = error_data.get("error", {}).get("message", "Unknown error")
                    logger.error(f"DashScope API error: {error_msg}")
                    raise httpx.HTTPStatusError(
                        message=f"DashScope API error: {error_msg}",
                        request=response.request,
                        response=response
                    )

                data = response.json()

            latency_ms = (time.time() - start_time) * 1000

            # 解析响应
            output = data.get("output", {})
            usage = data.get("usage", {})

            content = output.get("choices", [{}])[0].get("message", {}).get("content", "")

            # 计算成本
            prompt_tokens = usage.get("input_tokens", 0)
            completion_tokens = usage.get("output_tokens", 0)
            cost = self._calculate_cost(prompt_tokens, completion_tokens)

            logger.debug(
                f"Qwen response: tokens={prompt_tokens + completion_tokens}, "
                f"cost=${cost:.4f}, latency={latency_ms:.0f}ms"
            )

            return LLMResponse(
                content=content,
                model=self._model,
                provider="qwen",
                usage={
                    "prompt_tokens": prompt_tokens,
                    "completion_tokens": completion_tokens,
                    "total_tokens": usage.get("total_tokens", prompt_tokens + completion_tokens)
                },
                cost=cost,
                latency_ms=latency_ms
            )

        except httpx.TimeoutException:
            logger.error(f"Qwen request timed out after {self._timeout}s")
            raise
        except Exception as e:
            logger.error(f"Qwen request failed: {e}")
            raise

    async def embedding(
        self,
        texts: List[str],
        **kwargs
    ) -> EmbeddingResponse:
        """
        生成文本嵌入向量

        Args:
            texts: 文本列表（最多 25 条）
            **kwargs: 额外参数

        Returns:
            EmbeddingResponse: 嵌入向量响应
        """
        if len(texts) > 25:
            logger.warning(f"Batch size {len(texts)} exceeds limit of 25, truncating")
            texts = texts[:25]

        start_time = time.time()

        payload = {
            "model": self._embedding_model,
            "input": {
                "texts": texts
            }
        }

        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    self.EMBEDDING_ENDPOINT,
                    headers=self._headers,
                    json=payload
                )
                response.raise_for_status()
                data = response.json()

            latency_ms = (time.time() - start_time) * 1000

            # 解析响应
            output = data.get("output", {})
            embeddings = [item["embedding"] for item in output.get("embeddings", [])]

            usage = data.get("usage", {})
            total_tokens = usage.get("total_tokens", sum(len(t.split()) for t in texts))

            return EmbeddingResponse(
                embeddings=embeddings,
                model=self._embedding_model,
                provider="qwen",
                usage={"total_tokens": total_tokens}
            )

        except Exception as e:
            logger.error(f"Qwen embedding failed: {e}")
            raise

    async def is_available(self) -> bool:
        """
        检查 API 是否可用

        Returns:
            bool: API 是否可用
        """
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                # 尝试列出可用模型
                response = await client.get(
                    "https://dashscope.aliyuncs.com/api/v1/models",
                    headers=self._headers
                )
                return response.status_code == 200
        except Exception as e:
            logger.debug(f"Qwen availability check failed: {e}")
            return False

    def _calculate_cost(self, prompt_tokens: int, completion_tokens: int) -> float:
        """
        计算 API 调用成本

        Args:
            prompt_tokens: 输入 token 数
            completion_tokens: 输出 token 数

        Returns:
            float: 成本（美元）
        """
        pricing = self.MODEL_PRICING.get(self._model, {"input": 0.001, "output": 0.003})

        input_cost = (prompt_tokens / 1000) * pricing["input"]
        output_cost = (completion_tokens / 1000) * pricing["output"]

        return input_cost + output_cost

    def get_info(self) -> Dict[str, Any]:
        """获取提供商详细信息"""
        pricing = self.MODEL_PRICING.get(self._model, {})

        return {
            "name": self.name,
            "model": self.model_name,
            "embedding_model": self._embedding_model,
            "type": self.__class__.__name__,
            "local": False,
            "pricing": pricing,
            "estimated_cost_per_call": "~$0.01-0.05"
        }
