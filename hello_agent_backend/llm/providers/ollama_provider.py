"""
Ollama Provider - 本地 LLM 服务

支持运行在本地的 Ollama 服务，可使用 Qwen、Llama3、Mistral 等开源模型。

安装 Ollama:
    curl -fsSL https://ollama.com/install.sh | sh  # Linux/Mac
    # Windows: 下载 https://ollama.com/download

拉取模型:
    ollama pull qwen3.5:9b
    ollama pull nomic-embed-text:latest

启动服务:
    ollama serve
"""

import httpx
import time
import logging
from typing import List, Optional, Dict, Any
from .base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse

logger = logging.getLogger(__name__)


class OllamaProvider(BaseLLMProvider):
    """
    Ollama 本地 LLM 提供商

    特点:
    - 完全本地运行，无网络延迟
    - 数据隐私性好
    - 免费使用
    - 需要本地 GPU/CPU 资源

    使用示例:
        provider = OllamaProvider(
            base_url="http://localhost:11434",
            model="qwen3.5:9b"
        )

        response = await provider.chat_completion([
            LLMMessage(role="user", content="你好！")
        ])
        print(response.content)
    """

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "qwen3.5:9b",
        embedding_model: str = "nomic-embed-text:latest",
        timeout: int = 60,
        **kwargs
    ):
        """
        初始化 Ollama Provider

        Args:
            base_url: Ollama API 地址
            model: 聊天模型名称
            embedding_model: 嵌入模型名称
            timeout: 请求超时时间（秒）
            **kwargs: 额外参数
        """
        self._base_url = base_url.rstrip("/")
        self._model = model
        self._embedding_model = embedding_model
        self._timeout = timeout
        self._extra_params = kwargs

        logger.info(f"OllamaProvider initialized: model={model}, url={base_url}")

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
        stream: bool = False,
        **kwargs
    ) -> LLMResponse:
        """
        调用 Ollama Chat API

        Args:
            messages: 消息列表
            temperature: 温度参数 (0.0 - 1.0)
            max_tokens: 最大生成 token 数
            stream: 是否流式输出（暂不支持）
            **kwargs: 额外参数

        Returns:
            LLMResponse: 响应对象

        Raises:
            httpx.HTTPError: HTTP 请求失败
            Exception: 其他错误
        """
        url = f"{self._base_url}/api/chat"
        start_time = time.time()

        payload: Dict[str, Any] = {
            "model": self._model,
            "messages": [msg.model_dump() for msg in messages],
            "stream": stream,
            "options": {
                "temperature": temperature,
                "top_p": kwargs.get("top_p", 0.9),
                "top_k": kwargs.get("top_k", 40),
            }
        }

        # 添加额外的 Ollama 选项
        if max_tokens:
            payload["options"]["num_predict"] = max_tokens

        if "repeat_penalty" in kwargs:
            payload["options"]["repeat_penalty"] = kwargs["repeat_penalty"]

        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()

            latency_ms = (time.time() - start_time) * 1000

            # 解析响应
            message_content = data.get("message", {}).get("content", "")
            prompt_eval_count = data.get("prompt_eval_count", 0)
            eval_count = data.get("eval_count", 0)

            logger.debug(
                f"Ollama response: tokens={prompt_eval_count + eval_count}, "
                f"latency={latency_ms:.0f}ms"
            )

            return LLMResponse(
                content=message_content,
                model=self._model,
                provider="ollama",
                usage={
                    "prompt_tokens": prompt_eval_count,
                    "completion_tokens": eval_count,
                    "total_tokens": prompt_eval_count + eval_count
                },
                cost=0.0,  # 本地运行免费
                latency_ms=latency_ms
            )

        except httpx.TimeoutException:
            logger.error(f"Ollama request timed out after {self._timeout}s")
            raise
        except httpx.HTTPError as e:
            logger.error(f"Ollama HTTP error: {e}")
            raise
        except Exception as e:
            logger.error(f"Ollama request failed: {e}")
            raise

    async def embedding(
        self,
        texts: List[str],
        **kwargs
    ) -> EmbeddingResponse:
        """
        生成文本嵌入向量

        Args:
            texts: 文本列表
            **kwargs: 额外参数

        Returns:
            EmbeddingResponse: 嵌入向量响应
        """
        url = f"{self._base_url}/api/embeddings"
        start_time = time.time()

        embeddings = []
        total_tokens = 0

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            for text in texts:
                payload = {
                    "model": self._embedding_model,
                    "prompt": text
                }

                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()

                embeddings.append(data["embedding"])
                total_tokens += len(text.split())  # 估算 token 数

        latency_ms = (time.time() - start_time) * 1000

        return EmbeddingResponse(
            embeddings=embeddings,
            model=self._embedding_model,
            provider="ollama",
            usage={"total_tokens": total_tokens}
        )

    async def is_available(self) -> bool:
        """
        检查 Ollama 服务是否可用

        Returns:
            bool: 服务是否可用
        """
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self._base_url}/api/tags")
                if response.status_code == 200:
                    # 检查模型是否存在
                    data = response.json()
                    models = [m["name"] for m in data.get("models", [])]
                    if self._model in models:
                        logger.debug(f"Ollama model '{self._model}' is available")
                        return True
                    else:
                        logger.warning(
                            f"Model '{self._model}' not found. "
                            f"Available: {models}"
                        )
                        return False
                return False
        except Exception as e:
            logger.debug(f"Ollama availability check failed: {e}")
            return False

    async def list_models(self) -> List[str]:
        """
        列出本地可用的模型

        Returns:
            List[str]: 模型名称列表
        """
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self._base_url}/api/tags")
                response.raise_for_status()
                data = response.json()
                return [m["name"] for m in data.get("models", [])]
        except Exception as e:
            logger.error(f"Failed to list models: {e}")
            return []

    async def pull_model(self, model_name: str) -> bool:
        """
        拉取新模型（异步，可能需要较长时间）

        Args:
            model_name: 模型名称

        Returns:
            bool: 是否成功开始拉取
        """
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.post(
                    f"{self._base_url}/api/pull",
                    json={"name": model_name}
                )
                response.raise_for_status()
                logger.info(f"Started pulling model: {model_name}")
                return True
        except Exception as e:
            logger.error(f"Failed to pull model: {e}")
            return False

    def get_info(self) -> Dict[str, Any]:
        """获取提供商详细信息"""
        return {
            "name": self.name,
            "model": self.model_name,
            "embedding_model": self._embedding_model,
            "base_url": self._base_url,
            "type": self.__class__.__name__,
            "local": True,
            "cost_per_call": 0.0
        }
