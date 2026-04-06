"""
Gemini Provider - Google AI API

支持 Google Gemini 系列模型（Gemini Pro, Gemini Pro Vision, Gemini Ultra）。

获取 API Key:
    1. 访问 https://makersuite.google.com/app/apikey
    2. 登录 Google 账号
    3. 创建 API Key

定价参考 (2024):
    - Gemini Pro: 免费层级（60 RPM），之后 $0.0005/1K tokens
    - Gemini Ultra: 等待开放

使用示例:
    provider = GeminiProvider(
        api_key="your-gemini-api-key",
        model="gemini-pro"
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


class GeminiProvider(BaseLLMProvider):
    """
    Google Gemini 提供商

    特点:
    - 强大的多模态能力
    - 优秀的创意写作
    - 良好的多语言支持
    - 免费层级充足

    可用模型:
    - gemini-pro: 文本和对话任务
    - gemini-pro-vision: 图像+文本多模态
    - gemini-ultra: 最强性能（待开放）
    """

    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "gemini-pro",
        embedding_model: str = "models/embedding-001",
        timeout: int = 30,
        **kwargs
    ):
        """
        初始化 Gemini Provider

        Args:
            api_key: Google AI API Key（如果为 None，从环境变量读取）
            model: 聊天模型名称
            embedding_model: 嵌入模型名称
            timeout: 请求超时时间（秒）
            **kwargs: 额外参数
        """
        self._api_key = api_key or os.getenv("GEMINI_API_KEY", "")
        if not self._api_key:
            raise ValueError(
                "GEMINI_API_KEY is required. Set it via parameter or environment variable."
            )

        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout
        self._extra_params = kwargs

        logger.info(f"GeminiProvider initialized: model={model}")

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
        top_p: float = 0.95,
        top_k: int = 40,
        **kwargs
    ) -> LLMResponse:
        """
        调用 Gemini GenerateContent API

        Args:
            messages: 消息列表
            temperature: 温度参数 (0.0 - 1.0)
            max_tokens: 最大生成 token 数
            top_p: 核采样参数
            top_k: Top-K 采样参数
            **kwargs: 额外参数

        Returns:
            LLMResponse: 响应对象

        Raises:
            ValueError: API Key 未设置
            httpx.HTTPError: HTTP 请求失败
        """
        if not self._api_key:
            raise ValueError("GEMINI_API_KEY is not set")

        url = f"{self.BASE_URL}/models/{self._model}:generateContent"
        start_time = time.time()

        # 转换消息格式为 Gemini 格式
        contents = []
        system_instruction = None

        for msg in messages:
            if msg.role == "system":
                # Gemini 使用单独的 system_instruction 字段
                system_instruction = {
                    "parts": [{"text": msg.content}]
                }
            else:
                contents.append({
                    "role": "user" if msg.role == "user" else "model",
                    "parts": [{"text": msg.content}]
                })

        payload: Dict[str, Any] = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
                "topP": top_p,
                "topK": top_k,
            }
        }

        if system_instruction:
            payload["systemInstruction"] = system_instruction

        if max_tokens:
            payload["generationConfig"]["maxOutputTokens"] = max_tokens

        # 添加安全性设置（降低误拦截）
        payload["safetySettings"] = [
            {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_HATE_SPEECH",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_ONLY_HIGH"
            }
        ]

        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    url,
                    params={"key": self._api_key},
                    json=payload
                )

                # 处理错误响应
                if response.status_code != 200:
                    error_data = response.json()
                    error_msg = error_data.get("error", {}).get("message", "Unknown error")
                    logger.error(f"Gemini API error: {error_msg}")
                    raise httpx.HTTPStatusError(
                        message=f"Gemini API error: {error_msg}",
                        request=response.request,
                        response=response
                    )

                data = response.json()

            latency_ms = (time.time() - start_time) * 1000

            # 解析响应
            candidates = data.get("candidates", [])
            if not candidates:
                raise ValueError("No candidates in Gemini response")

            content = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")

            # 估算 token 使用量
            prompt_tokens = sum(len(msg.content.split()) * 1.3 for msg in messages)
            completion_tokens = len(content.split()) * 1.3

            # Gemini 目前在免费层级内
            cost = 0.0

            logger.debug(
                f"Gemini response: tokens≈{int(prompt_tokens + completion_tokens)}, "
                f"latency={latency_ms:.0f}ms"
            )

            return LLMResponse(
                content=content,
                model=self._model,
                provider="gemini",
                usage={
                    "prompt_tokens": int(prompt_tokens),
                    "completion_tokens": int(completion_tokens),
                    "total_tokens": int(prompt_tokens + completion_tokens)
                },
                cost=cost,
                latency_ms=latency_ms
            )

        except httpx.TimeoutException:
            logger.error(f"Gemini request timed out after {self._timeout}s")
            raise
        except Exception as e:
            logger.error(f"Gemini request failed: {e}")
            raise

    async def embedding(
        self,
        texts: List[str],
        task_type: str = "RETRIEVAL_DOCUMENT",
        **kwargs
    ) -> EmbeddingResponse:
        """
        生成文本嵌入向量

        Args:
            texts: 文本列表
            task_type: 任务类型（影响嵌入优化方向）
            **kwargs: 额外参数

        Returns:
            EmbeddingResponse: 嵌入向量响应
        """
        url = f"{self.BASE_URL}/{self._embedding_model}:embedContent"

        embeddings = []
        total_tokens = 0

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            for text in texts:
                payload = {
                    "model": self._embedding_model,
                    "content": {
                        "parts": [{"text": text}]
                    },
                    "taskType": task_type
                }

                response = await client.post(
                    url,
                    params={"key": self._api_key},
                    json=payload
                )
                response.raise_for_status()
                data = response.json()

                embeddings.append(data["embedding"]["values"])
                total_tokens += len(text.split())

        return EmbeddingResponse(
            embeddings=embeddings,
            model=self._embedding_model,
            provider="gemini",
            usage={"total_tokens": total_tokens}
        )

    async def is_available(self) -> bool:
        """
        检查 API 是否可用

        Returns:
            bool: API 是否可用
        """
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(
                    f"{self.BASE_URL}/models",
                    params={"key": self._api_key}
                )
                return response.status_code == 200
        except Exception as e:
            logger.debug(f"Gemini availability check failed: {e}")
            return False

    async def list_models(self) -> List[str]:
        """
        列出可用的 Gemini 模型

        Returns:
            List[str]: 模型名称列表
        """
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(
                    f"{self.BASE_URL}/models",
                    params={"key": self._api_key}
                )
                response.raise_for_status()
                data = response.json()
                return [m["name"] for m in data.get("models", [])]
        except Exception as e:
            logger.error(f"Failed to list Gemini models: {e}")
            return []

    def get_info(self) -> Dict[str, Any]:
        """获取提供商详细信息"""
        return {
            "name": self.name,
            "model": self.model_name,
            "embedding_model": self._embedding_model,
            "type": self.__class__.__name__,
            "local": False,
            "free_tier": True,
            "rate_limit": "60 RPM (free)",
            "estimated_cost_per_call": "$0.00 (free tier)"
        }
