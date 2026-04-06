"""
LLM Router - 智能路由器

根据任务类型、成本、性能等因素智能选择最优 LLM 提供商，
支持故障转移和负载均衡。

功能:
- 智能路由：根据任务类型自动选择最佳提供商
- 故障转移：主提供商失败时自动切换备用
- 成本控制：在预算内优化使用
- 性能监控：跟踪各提供商的延迟和成功率

使用示例:
    router = LLMRouter("config/llm_config.json")

    # NPC 对话（自动使用 Ollama）
    response = await router.chat_completion(
        messages=[LLMMessage(role="user", content="你好")],
        task_type="npc_dialogue"
    )

    # 故事生成（自动使用 Qwen）
    response = await router.chat_completion(
        messages=[...],
        task_type="story_generation"
    )
"""

import json
import time
import logging
import os
from typing import Dict, List, Optional, Any, Tuple
from collections import defaultdict
from .providers.base import BaseLLMProvider, LLMMessage, LLMResponse, EmbeddingResponse
from .providers.ollama_provider import OllamaProvider
from .providers.qwen_provider import QwenProvider
from .providers.gemini_provider import GeminiProvider

logger = logging.getLogger(__name__)


class ProviderStats:
    """提供商统计数据"""

    def __init__(self):
        self.total_requests: int = 0
        self.successful_requests: int = 0
        self.failed_requests: int = 0
        self.total_tokens: int = 0
        self.total_cost: float = 0.0
        self.avg_latency_ms: float = 0.0
        self.last_error: Optional[str] = None
        self._latency_sum: float = 0.0

    def record_success(self, latency_ms: float, tokens: int, cost: float):
        """记录成功请求"""
        self.total_requests += 1
        self.successful_requests += 1
        self.total_tokens += tokens
        self.total_cost += cost
        self._latency_sum += latency_ms
        self.avg_latency_ms = self._latency_sum / self.successful_requests

    def record_failure(self, error: str):
        """记录失败请求"""
        self.total_requests += 1
        self.failed_requests += 1
        self.last_error = error

    @property
    def success_rate(self) -> float:
        """成功率"""
        if self.total_requests == 0:
            return 1.0
        return self.successful_requests / self.total_requests

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "failed_requests": self.failed_requests,
            "success_rate": f"{self.success_rate:.2%}",
            "total_tokens": self.total_tokens,
            "total_cost": f"${self.total_cost:.4f}",
            "avg_latency_ms": f"{self.avg_latency_ms:.0f}ms",
            "last_error": self.last_error
        }


class LLMRouter:
    """
    智能 LLM 路由器

    功能:
    - 根据任务类型智能选择提供商
    - 自动故障转移
    - 成本控制和监控
    - 性能统计

    配置示例 (config/llm_config.json):
    {
        "providers": {
            "ollama": {"enabled": true, "priority": 1},
            "qwen": {"enabled": true, "priority": 2},
            "gemini": {"enabled": false, "priority": 3}
        },
        "routing_strategy": {
            "mode": "smart",
            "fallback_enabled": true,
            "cache_enabled": true
        },
        "task_routing": {
            "npc_dialogue": "ollama",
            "story_generation": "qwen",
            "emotion_analysis": "gemini"
        }
    }
    """

    # 默认任务到提供商的映射
    DEFAULT_TASK_ROUTING = {
        "npc_dialogue": "ollama",           # NPC 对话用本地模型
        "emotion_analysis": "ollama",       # 情感分析用本地模型
        "simple_reasoning": "ollama",       # 简单推理用本地模型
        "story_generation": "qwen",         # 故事生成用 Qwen
        "complex_reasoning": "qwen",        # 复杂推理用 Qwen
        "translation": "qwen",              # 翻译用 Qwen（中文好）
        "creative_writing": "gemini",       # 创意写作用 Gemini
        "multimodal": "gemini",             # 多模态用 Gemini
        "fallback": "ollama",               # 默认降级目标
    }

    def __init__(self, config_path: str = "config/llm_config.json"):
        """
        初始化 LLM 路由器

        Args:
            config_path: 配置文件路径
        """
        self.config = self._load_config(config_path)
        self.providers: Dict[str, BaseLLMProvider] = {}
        self.stats: Dict[str, ProviderStats] = defaultdict(ProviderStats)
        self.routing_rules = self.config.get("routing_strategy", {})
        self.task_routing = self.config.get("task_routing", self.DEFAULT_TASK_ROUTING)
        self.cost_budget = self.config.get("monitoring", {}).get("daily_budget_usd", 5.0)
        self.current_daily_cost = 0.0

        self._initialize_providers()
        logger.info(f"LLMRouter initialized with {len(self.providers)} providers")

    def _load_config(self, config_path: str) -> dict:
        """加载配置文件"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                logger.info(f"Loaded LLM config from {config_path}")
                return config
        except FileNotFoundError:
            logger.warning(f"Config file not found: {config_path}, using defaults")
            return self._default_config()
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in config file: {e}")
            return self._default_config()

    def _default_config(self) -> dict:
        """默认配置"""
        return {
            "providers": {
                "ollama": {
                    "enabled": True,
                    "priority": 1,
                    "model": "qwen3.5:9b",
                    "embedding_model": "nomic-embed-text:latest"
                },
                "qwen": {
                    "enabled": False,
                    "priority": 2,
                    "model": "qwen-plus"
                },
                "gemini": {
                    "enabled": False,
                    "priority": 3,
                    "model": "gemini-pro"
                }
            },
            "routing_strategy": {
                "mode": "smart",
                "fallback_enabled": True,
                "cache_enabled": False
            },
            "task_routing": self.DEFAULT_TASK_ROUTING,
            "monitoring": {
                "daily_budget_usd": 5.0
            }
        }

    def _initialize_providers(self):
        """初始化所有启用的提供商"""
        providers_config = self.config.get("providers", {})

        # Ollama
        if providers_config.get("ollama", {}).get("enabled"):
            try:
                ollama_cfg = providers_config["ollama"]
                self.providers["ollama"] = OllamaProvider(
                    base_url=ollama_cfg.get("base_url", "http://localhost:11434"),
                    model=ollama_cfg.get("model", "qwen3.5:9b"),
                    embedding_model=ollama_cfg.get("embedding_model", "nomic-embed-text:latest"),
                    timeout=ollama_cfg.get("timeout_seconds", 60)
                )
                logger.info("✓ Ollama provider initialized")
            except Exception as e:
                logger.error(f"Failed to initialize Ollama: {e}")

        # Qwen
        if providers_config.get("qwen", {}).get("enabled"):
            try:
                qwen_cfg = providers_config["qwen"]
                api_key = os.getenv("QWEN_API_KEY")
                if api_key:
                    self.providers["qwen"] = QwenProvider(
                        api_key=api_key,
                        model=qwen_cfg.get("model", "qwen-plus"),
                        embedding_model=qwen_cfg.get("embedding_model", "text-embedding-v2"),
                        timeout=qwen_cfg.get("timeout_seconds", 30)
                    )
                    logger.info("✓ Qwen provider initialized")
                else:
                    logger.warning("QWEN_API_KEY not set, skipping Qwen provider")
            except Exception as e:
                logger.error(f"Failed to initialize Qwen: {e}")

        # Gemini
        if providers_config.get("gemini", {}).get("enabled"):
            try:
                gemini_cfg = providers_config["gemini"]
                api_key = os.getenv("GEMINI_API_KEY")
                if api_key:
                    self.providers["gemini"] = GeminiProvider(
                        api_key=api_key,
                        model=gemini_cfg.get("model", "gemini-pro"),
                        embedding_model=gemini_cfg.get("embedding_model", "models/embedding-001"),
                        timeout=gemini_cfg.get("timeout_seconds", 30)
                    )
                    logger.info("✓ Gemini provider initialized")
                else:
                    logger.warning("GEMINI_API_KEY not set, skipping Gemini provider")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini: {e}")

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        task_type: str = "general",
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        force_provider: Optional[str] = None,
        **kwargs
    ) -> LLMResponse:
        """
        智能路由聊天请求

        Args:
            messages: 消息列表
            task_type: 任务类型（影响路由决策）
            temperature: 温度参数
            max_tokens: 最大生成 token 数
            force_provider: 强制使用指定提供商（跳过路由）
            **kwargs: 额外参数

        Returns:
            LLMResponse: 响应对象

        Raises:
            Exception: 所有提供商都失败时抛出异常
        """
        # 检查预算
        if self.current_daily_cost >= self.cost_budget:
            logger.warning(f"Daily budget ${self.cost_budget} exceeded")
            # 仍然允许使用免费提供商
            free_providers = ["ollama"]
            available = [p for p in free_providers if p in self.providers]
            if not available:
                raise Exception("Budget exceeded and no free providers available")

        # 确定目标提供商
        if force_provider:
            target_providers = [force_provider]
        else:
            primary = self._select_provider(task_type)
            target_providers = self._get_fallback_chain(primary)

        logger.info(f"Routing task '{task_type}' to providers: {target_providers}")

        # 尝试调用，失败则降级
        last_error = None
        for provider_name in target_providers:
            if provider_name not in self.providers:
                logger.debug(f"Provider {provider_name} not configured, skipping")
                continue

            provider = self.providers[provider_name]

            # 检查可用性
            if not await provider.is_available():
                logger.warning(f"Provider {provider_name} is not available")
                self.stats[provider_name].record_failure("Not available")
                continue

            try:
                start_time = time.time()
                response = await provider.chat_completion(
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    **kwargs
                )
                latency_ms = (time.time() - start_time) * 1000

                # 记录成功
                self.stats[provider_name].record_success(
                    latency_ms=response.latency_ms or latency_ms,
                    tokens=response.usage.get("total_tokens", 0),
                    cost=response.cost
                )

                # 更新成本
                self.current_daily_cost += response.cost

                logger.info(
                    f"✓ Success with {provider_name} "
                    f"(task={task_type}, tokens={response.usage.get('total_tokens', 0)}, "
                    f"cost=${response.cost:.4f})"
                )

                return response

            except Exception as e:
                last_error = e
                self.stats[provider_name].record_failure(str(e))
                logger.error(f"Provider {provider_name} failed: {e}")
                continue

        # 所有提供商都失败了
        error_msg = f"All providers failed for task '{task_type}'. Last error: {last_error}"
        logger.error(error_msg)
        raise Exception(error_msg)

    async def get_embedding(
        self,
        texts: List[str],
        force_provider: Optional[str] = None,
        **kwargs
    ) -> EmbeddingResponse:
        """
        获取文本嵌入（优先使用本地）

        Args:
            texts: 文本列表
            force_provider: 强制使用指定提供商
            **kwargs: 额外参数

        Returns:
            EmbeddingResponse: 嵌入向量响应
        """
        # 优先使用 Ollama（免费）
        if force_provider:
            target_providers = [force_provider]
        else:
            target_providers = ["ollama"] + [p for p in self.providers if p != "ollama"]

        last_error = None
        for provider_name in target_providers:
            if provider_name not in self.providers:
                continue

            provider = self.providers[provider_name]

            try:
                response = await provider.embedding(texts, **kwargs)
                logger.info(f"✓ Embedding success with {provider_name}")
                return response
            except Exception as e:
                last_error = e
                logger.error(f"Embedding with {provider_name} failed: {e}")
                continue

        raise Exception(f"All embedding providers failed. Last error: {last_error}")

    def _select_provider(self, task_type: str) -> str:
        """
        根据任务类型选择最优提供商

        Args:
            task_type: 任务类型

        Returns:
            str: 提供商名称
        """
        routing_mode = self.routing_rules.get("mode", "smart")

        if routing_mode == "smart":
            # 智能路由：根据任务类型映射
            preferred = self.task_routing.get(task_type, "ollama")

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

        return "ollama"  # 默认 fallback

    def _get_fallback_chain(self, primary: str) -> List[str]:
        """
        获取降级链

        Args:
            primary: 主提供商

        Returns:
            List[str]: 提供商列表（按降级顺序）
        """
        if not self.routing_rules.get("fallback_enabled", True):
            return [primary]

        all_providers = list(self.providers.keys())

        # 按优先级排序
        priority_order = sorted(
            all_providers,
            key=lambda p: self.config.get("providers", {}).get(p, {}).get("priority", 99)
        )

        # 确保 primary 在最前面
        if primary in priority_order:
            priority_order.remove(primary)
            priority_order.insert(0, primary)

        return priority_order

    def get_provider_stats(self) -> Dict[str, Dict[str, Any]]:
        """
        获取所有提供商的统计信息

        Returns:
            Dict: 各提供商的统计数据
        """
        stats = {}
        for name in self.providers:
            stats[name] = self.stats[name].to_dict()
        return stats

    def get_budget_info(self) -> Dict[str, Any]:
        """获取预算使用情况"""
        return {
            "daily_budget": self.cost_budget,
            "current_usage": self.current_daily_cost,
            "remaining": max(0, self.cost_budget - self.current_daily_cost),
            "usage_percentage": f"{(self.current_daily_cost / self.cost_budget * 100):.1f}%" if self.cost_budget > 0 else "0%"
        }

    def reset_daily_cost(self):
        """重置每日成本（通常在每天零点调用）"""
        self.current_daily_cost = 0.0
        logger.info("Daily cost counter reset")

    async def check_all_providers(self) -> Dict[str, bool]:
        """
        检查所有提供商的可用性

        Returns:
            Dict[str, bool]: 各提供商的可用状态
        """
        results = {}
        for name, provider in self.providers.items():
            results[name] = await provider.is_available()
        return results

    def get_info(self) -> Dict[str, Any]:
        """获取路由器完整信息"""
        return {
            "providers": {name: p.get_info() for name, p in self.providers.items()},
            "stats": self.get_provider_stats(),
            "budget": self.get_budget_info(),
            "routing_mode": self.routing_rules.get("mode", "smart"),
            "fallback_enabled": self.routing_rules.get("fallback_enabled", True)
        }
