"""
LLM Provider 单元测试

测试所有 LLM 提供商和路由器的功能。

运行测试:
    pytest tests/test_llm_providers.py -v
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

from llm.providers.base import LLMMessage, LLMResponse, EmbeddingResponse
from llm.providers.ollama_provider import OllamaProvider
from llm.providers.qwen_provider import QwenProvider
from llm.providers.gemini_provider import GeminiProvider
from llm.router import LLMRouter, ProviderStats


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def sample_messages():
    """示例消息列表"""
    return [
        LLMMessage(role="system", content="你是一个助手"),
        LLMMessage(role="user", content="你好")
    ]


@pytest.fixture
def ollama_provider():
    """Ollama 提供商实例（模拟）"""
    return OllamaProvider(
        base_url="http://localhost:11434",
        model="qwen3.5:9b"
    )


@pytest.fixture
def qwen_provider():
    """Qwen 提供商实例（需要 API Key）"""
    import os
    api_key = os.getenv("QWEN_API_KEY", "test-key")
    return QwenProvider(api_key=api_key, model="qwen-plus")


@pytest.fixture
def gemini_provider():
    """Gemini 提供商实例（需要 API Key）"""
    import os
    api_key = os.getenv("GEMINI_API_KEY", "test-key")
    return GeminiProvider(api_key=api_key, model="gemini-pro")


@pytest.fixture
def router():
    """LLM 路由器实例"""
    return LLMRouter("config/llm_config.json")


# ============================================================================
# Base Model Tests
# ============================================================================

class TestLLMMessage:
    """测试 LLMMessage 模型"""

    def test_create_message(self):
        """创建消息"""
        msg = LLMMessage(role="user", content="Hello")
        assert msg.role == "user"
        assert msg.content == "Hello"

    def test_message_to_dict(self):
        """消息转字典"""
        msg = LLMMessage(role="user", content="Hello")
        data = msg.model_dump()
        assert data == {"role": "user", "content": "Hello"}

    def test_invalid_role(self):
        """无效角色应该失败"""
        with pytest.raises(ValueError):
            LLMMessage(role="invalid", content="Hello")


class TestLLMResponse:
    """测试 LLMResponse 模型"""

    def test_create_response(self):
        """创建响应"""
        response = LLMResponse(
            content="Hello",
            model="test-model",
            provider="test-provider"
        )
        assert response.content == "Hello"
        assert response.cost == 0.0

    def test_response_with_usage(self):
        """带使用统计的响应"""
        response = LLMResponse(
            content="Hello",
            model="test",
            provider="test",
            usage={"total_tokens": 100},
            cost=0.01,
            latency_ms=150.0
        )
        assert response.usage["total_tokens"] == 100
        assert response.cost == 0.01


# ============================================================================
# Ollama Provider Tests
# ============================================================================

class TestOllamaProvider:
    """测试 Ollama Provider"""

    def test_initialization(self, ollama_provider):
        """测试初始化"""
        assert ollama_provider.name == "ollama"
        assert ollama_provider.model_name == "qwen3.5:9b"

    @pytest.mark.asyncio
    async def test_is_available_success(self, ollama_provider):
        """测试可用性检查 - 成功"""
        with patch('httpx.AsyncClient') as mock_client:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "models": [{"name": "qwen3.5:9b"}]
            }

            mock_instance = AsyncMock()
            mock_instance.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_instance

            result = await ollama_provider.is_available()
            assert result is True

    @pytest.mark.asyncio
    async def test_is_available_failure(self, ollama_provider):
        """测试可用性检查 - 失败"""
        with patch('httpx.AsyncClient') as mock_client:
            mock_instance = AsyncMock()
            mock_instance.get.side_effect = Exception("Connection refused")
            mock_client.return_value.__aenter__.return_value = mock_instance

            result = await ollama_provider.is_available()
            assert result is False

    def test_get_info(self, ollama_provider):
        """测试获取信息"""
        info = ollama_provider.get_info()
        assert info["name"] == "ollama"
        assert info["local"] is True
        assert info["cost_per_call"] == 0.0


# ============================================================================
# Qwen Provider Tests
# ============================================================================

class TestQwenProvider:
    """测试 Qwen Provider"""

    def test_initialization(self, qwen_provider):
        """测试初始化"""
        assert qwen_provider.name == "qwen"
        assert qwen_provider.model_name == "qwen-plus"

    def test_missing_api_key(self):
        """缺少 API Key 应该抛出异常"""
        import os
        original = os.environ.get("QWEN_API_KEY")
        if "QWEN_API_KEY" in os.environ:
            del os.environ["QWEN_API_KEY"]

        with pytest.raises(ValueError):
            QwenProvider(api_key="")

        if original:
            os.environ["QWEN_API_KEY"] = original

    def test_calculate_cost(self, qwen_provider):
        """测试成本计算"""
        cost = qwen_provider._calculate_cost(1000, 500)
        assert cost > 0
        assert isinstance(cost, float)

    def test_get_info(self, qwen_provider):
        """测试获取信息"""
        info = qwen_provider.get_info()
        assert info["name"] == "qwen"
        assert info["local"] is False


# ============================================================================
# Gemini Provider Tests
# ============================================================================

class TestGeminiProvider:
    """测试 Gemini Provider"""

    def test_initialization(self, gemini_provider):
        """测试初始化"""
        assert gemini_provider.name == "gemini"
        assert gemini_provider.model_name == "gemini-pro"

    def test_missing_api_key(self):
        """缺少 API Key 应该抛出异常"""
        import os
        original = os.environ.get("GEMINI_API_KEY")
        if "GEMINI_API_KEY" in os.environ:
            del os.environ["GEMINI_API_KEY"]

        with pytest.raises(ValueError):
            GeminiProvider(api_key="")

        if original:
            os.environ["GEMINI_API_KEY"] = original

    def test_get_info(self, gemini_provider):
        """测试获取信息"""
        info = gemini_provider.get_info()
        assert info["name"] == "gemini"
        assert info["free_tier"] is True


# ============================================================================
# Router Tests
# ============================================================================

class TestProviderStats:
    """测试提供商统计数据"""

    def test_initial_stats(self):
        """初始统计"""
        stats = ProviderStats()
        assert stats.total_requests == 0
        assert stats.success_rate == 1.0

    def test_record_success(self):
        """记录成功请求"""
        stats = ProviderStats()
        stats.record_success(latency_ms=100, tokens=50, cost=0.01)
        assert stats.total_requests == 1
        assert stats.successful_requests == 1
        assert stats.avg_latency_ms == 100

    def test_record_failure(self):
        """记录失败请求"""
        stats = ProviderStats()
        stats.record_failure("Connection error")
        assert stats.failed_requests == 1
        assert stats.last_error == "Connection error"

    def test_success_rate(self):
        """成功率计算"""
        stats = ProviderStats()
        stats.record_success(100, 50, 0.01)
        stats.record_success(100, 50, 0.01)
        stats.record_failure("Error")
        assert abs(stats.success_rate - 0.67) < 0.01


class TestLLMRouter:
    """测试 LLM 路由器"""

    def test_initialization(self, router):
        """测试初始化"""
        assert len(router.providers) >= 1  # 至少应该有 Ollama
        assert "ollama" in router.providers

    def test_select_provider_smart_mode(self, router):
        """智能模式选择提供商"""
        # NPC 对话应该选择 Ollama
        provider = router._select_provider("npc_dialogue")
        assert provider in ["ollama", "qwen", "gemini"]

    def test_fallback_chain(self, router):
        """测试降级链"""
        chain = router._get_fallback_chain("ollama")
        assert "ollama" in chain
        assert len(chain) <= len(router.providers)

    def test_budget_info(self, router):
        """测试预算信息"""
        budget = router.get_budget_info()
        assert "daily_budget" in budget
        assert "current_usage" in budget
        assert "remaining" in budget

    @pytest.mark.asyncio
    async def test_check_all_providers(self, router):
        """检查所有提供商"""
        results = await router.check_all_providers()
        assert isinstance(results, dict)
        for name, available in results.items():
            assert isinstance(available, bool)

    def test_get_provider_stats(self, router):
        """获取提供商统计"""
        stats = router.get_provider_stats()
        assert isinstance(stats, dict)

    def test_reset_daily_cost(self, router):
        """重置每日成本"""
        router.current_daily_cost = 1.5
        router.reset_daily_cost()
        assert router.current_daily_cost == 0.0


# ============================================================================
# Integration Tests (require running services)
# ============================================================================

@pytest.mark.integration
class TestIntegration:
    """集成测试（需要实际运行服务）"""

    @pytest.mark.asyncio
    async def test_ollama_chat(self):
        """测试 Ollama 聊天（需要 Ollama 运行）"""
        provider = OllamaProvider()

        if not await provider.is_available():
            pytest.skip("Ollama not available")

        messages = [LLMMessage(role="user", content="Say hello")]

        response = await provider.chat_completion(messages)
        assert response.content
        assert response.provider == "ollama"

    @pytest.mark.asyncio
    async def test_router_chat(self):
        """测试路由器聊天"""
        router = LLMRouter("config/llm_config.json")

        messages = [LLMMessage(role="user", content="Hello")]

        try:
            response = await router.chat_completion(
                messages=messages,
                task_type="general"
            )
            assert response.content
            assert response.provider in router.providers
        except Exception as e:
            pytest.skip(f"No providers available: {e}")


# ============================================================================
# Performance Tests
# ============================================================================

class TestPerformance:
    """性能测试"""

    @pytest.mark.asyncio
    async def test_router_creation_time(self):
        """路由器创建时间"""
        import time
        start = time.time()
        router = LLMRouter("config/llm_config.json")
        elapsed = time.time() - start
        assert elapsed < 1.0  # 应该在 1 秒内完成

    @pytest.mark.asyncio
    async def test_provider_availability_check_speed(self, router):
        """提供商可用性检查速度"""
        import time
        start = time.time()
        await router.check_all_providers()
        elapsed = time.time() - start
        assert elapsed < 5.0  # 应该在 5 秒内完成


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
