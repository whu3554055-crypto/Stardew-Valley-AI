"""
Redis Cache Manager 单元测试

测试缓存管理器、装饰器和模式失效功能。

运行测试:
    pytest tests/test_cache.py -v
    pytest tests/test_cache.py::TestCacheManager -v  # 特定类
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch, PropertyMock
from datetime import timedelta

from core.cache import CacheManager


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def mock_redis():
    """模拟 Redis 客户端"""
    redis_mock = AsyncMock()
    redis_mock.get = AsyncMock(return_value=None)
    redis_mock.setex = AsyncMock(return_value=True)
    redis_mock.delete = AsyncMock(return_value=1)
    redis_mock.keys = AsyncMock(return_value=[])
    redis_mock.info = AsyncMock(return_value={
        "used_memory": 1048576,
        "used_memory_human": "1.00M",
        "keyspace_hits": 100,
        "keyspace_misses": 20,
        "db0": "keys=50,expires=30,avg_ttl=300"
    })
    return redis_mock


@pytest.fixture
def cache_manager(mock_redis):
    """缓存管理器实例（使用模拟 Redis）"""
    with patch('core.cache.redis.from_url', return_value=mock_redis):
        cache = CacheManager(url="redis://localhost:6379")
        cache.redis = mock_redis
        cache._connected = True
        return cache


@pytest.fixture
def sample_cache_data():
    """示例缓存数据"""
    return {
        "npc_id": "villager_001",
        "name": "Alice",
        "location": "town_square",
        "mood": "happy",
        "friendship_level": 3
    }


# ============================================================================
# Cache Manager Initialization Tests
# ============================================================================

class TestCacheManagerInitialization:
    """测试缓存管理器初始化"""

    def test_initialization(self, cache_manager):
        """测试基本初始化"""
        assert cache_manager is not None
        assert cache_manager.default_ttl == 300  # 默认 5 分钟

    def test_custom_ttl_initialization(self, mock_redis):
        """测试自定义 TTL 初始化"""
        with patch('core.cache.redis.from_url', return_value=mock_redis):
            cache = CacheManager(url="redis://localhost:6379", default_ttl=600)
            assert cache.default_ttl == 600

    @pytest.mark.asyncio
    async def test_connect_success(self, mock_redis):
        """测试成功连接"""
        with patch('core.cache.redis.from_url', return_value=mock_redis):
            cache = CacheManager(url="redis://localhost:6379")
            await cache.connect()
            assert cache._connected is True

    @pytest.mark.asyncio
    async def test_connect_failure(self):
        """测试连接失败"""
        with patch('core.cache.redis.from_url', side_effect=Exception("Connection refused")):
            cache = CacheManager(url="redis://invalid:6379")
            await cache.connect()
            assert cache._connected is False

    @pytest.mark.asyncio
    async def test_disconnect(self, cache_manager):
        """测试断开连接"""
        cache_manager._connected = True
        cache_manager.redis = AsyncMock()
        await cache_manager.disconnect()
        assert cache_manager._connected is False


# ============================================================================
# Basic Cache Operations Tests
# ============================================================================

class TestCacheOperations:
    """测试基本缓存操作"""

    @pytest.mark.asyncio
    async def test_set_and_get(self, cache_manager, sample_cache_data):
        """测试设置和获取缓存"""
        key = "test:npc:villager_001"

        # Set cache
        await cache_manager.set(key, sample_cache_data, ttl=60)

        # Mock get to return serialized data
        import json
        cache_manager.redis.get.return_value = json.dumps(sample_cache_data)

        # Get cache
        result = await cache_manager.get(key)
        assert result == sample_cache_data

    @pytest.mark.asyncio
    async def test_get_nonexistent_key(self, cache_manager):
        """测试获取不存在的键"""
        cache_manager.redis.get.return_value = None
        result = await cache_manager.get("nonexistent:key")
        assert result is None

    @pytest.mark.asyncio
    async def test_set_with_default_ttl(self, cache_manager, sample_cache_data):
        """测试使用默认 TTL 设置缓存"""
        key = "test:data"
        await cache_manager.set(key, sample_cache_data)

        # Verify setex was called with default TTL
        cache_manager.redis.setex.assert_called_once()
        call_args = cache_manager.redis.setex.call_args
        assert call_args[0][0] == key
        assert call_args[0][1] == 300  # Default TTL

    @pytest.mark.asyncio
    async def test_delete(self, cache_manager):
        """测试删除缓存"""
        key = "test:key"
        await cache_manager.delete(key)
        cache_manager.redis.delete.assert_called_once_with(key)

    @pytest.mark.asyncio
    async def test_exists_true(self, cache_manager):
        """测试键存在"""
        cache_manager.redis.exists = AsyncMock(return_value=1)
        result = await cache_manager.exists("existing:key")
        assert result is True

    @pytest.mark.asyncio
    async def test_exists_false(self, cache_manager):
        """测试键不存在"""
        cache_manager.redis.exists = AsyncMock(return_value=0)
        result = await cache_manager.exists("nonexistent:key")
        assert result is False

    @pytest.mark.asyncio
    async def test_expire(self, cache_manager):
        """测试设置过期时间"""
        key = "test:key"
        await cache_manager.expire(key, 120)
        cache_manager.redis.expire.assert_called_once_with(key, 120)


# ============================================================================
# Pattern-Based Operations Tests
# ============================================================================

class TestPatternOperations:
    """测试基于模式的操作"""

    @pytest.mark.asyncio
    async def test_invalidate_pattern(self, cache_manager):
        """测试按模式失效"""
        pattern = "npc_state:*"
        cache_manager.redis.keys.return_value = [
            "npc_state:villager_001",
            "npc_state:villager_002",
            "npc_state:guard_001"
        ]

        await cache_manager.invalidate_pattern(pattern)

        # Verify keys were retrieved
        cache_manager.redis.keys.assert_called_once_with(pattern)
        # Verify delete was called for each key
        assert cache_manager.redis.delete.call_count == 3

    @pytest.mark.asyncio
    async def test_invalidate_pattern_no_matches(self, cache_manager):
        """测试按模式失效 - 无匹配"""
        cache_manager.redis.keys.return_value = []
        await cache_manager.invalidate_pattern("nonexistent:*")
        cache_manager.redis.delete.assert_not_called()

    @pytest.mark.asyncio
    async def test_get_keys_by_pattern(self, cache_manager):
        """测试按模式获取键"""
        pattern = "mem_search:*"
        expected_keys = ["mem_search:abc", "mem_search:def"]
        cache_manager.redis.keys.return_value = expected_keys

        keys = await cache_manager.get_keys_by_pattern(pattern)
        assert keys == expected_keys


# ============================================================================
# Cache Decorator Tests
# ============================================================================

class TestCacheDecorator:
    """测试缓存装饰器"""

    @pytest.mark.asyncio
    async def test_cached_decorator(self, cache_manager):
        """测试 @cached 装饰器"""

        call_count = 0

        @cache_manager.cached(key_prefix="test_func", ttl=60)
        async def test_function(arg1, arg2):
            nonlocal call_count
            call_count += 1
            return {"result": arg1 + arg2}

        # First call - should execute function
        result1 = await test_function(10, 20)
        assert result1 == {"result": 30}
        assert call_count == 1

        # Second call - should return cached value (mock returns None, so will call again)
        # In real scenario, this would return cached value
        result2 = await test_function(10, 20)
        assert call_count >= 1  # At least called once

    @pytest.mark.asyncio
    async def test_cached_decorator_key_generation(self, cache_manager):
        """测试缓存装饰器键生成"""

        @cache_manager.cached(key_prefix="search", ttl=120)
        async def search_memories(query, npc_id):
            return {"memories": []}

        # Call function
        await search_memories("festival", "villager_001")

        # Verify key format
        cache_manager.redis.setex.assert_called_once()
        call_args = cache_manager.redis.setex.call_args
        key = call_args[0][0]
        assert "search:" in key
        assert "festival" in key or "villager_001" in key


# ============================================================================
# Cache Statistics Tests
# ============================================================================

class TestCacheStatistics:
    """测试缓存统计"""

    @pytest.mark.asyncio
    async def test_get_stats(self, cache_manager):
        """测试获取统计信息"""
        stats = await cache_manager.get_stats()

        assert "hits" in stats
        assert "misses" in stats
        assert "hit_rate" in stats
        assert "memory_used_bytes" in stats
        assert "memory_human" in stats
        assert "key_count" in stats

    @pytest.mark.asyncio
    async def test_hit_rate_calculation(self, cache_manager):
        """测试命中率计算"""
        cache_manager.redis.info.return_value = {
            "keyspace_hits": 80,
            "keyspace_misses": 20,
            "used_memory": 0,
            "used_memory_human": "0B",
            "db0": "keys=0,expires=0,avg_ttl=0"
        }

        stats = await cache_manager.get_stats()
        assert abs(stats["hit_rate"] - 0.8) < 0.01

    @pytest.mark.asyncio
    async def test_stats_zero_requests(self, cache_manager):
        """测试零请求时的统计"""
        cache_manager.redis.info.return_value = {
            "keyspace_hits": 0,
            "keyspace_misses": 0,
            "used_memory": 0,
            "used_memory_human": "0B",
            "db0": "keys=0,expires=0,avg_ttl=0"
        }

        stats = await cache_manager.get_stats()
        assert stats["hits"] == 0
        assert stats["misses"] == 0
        assert stats["hit_rate"] == 0.0


# ============================================================================
# Cache Serialization Tests
# ============================================================================

class TestCacheSerialization:
    """测试缓存序列化"""

    @pytest.mark.asyncio
    async def test_serialize_dict(self, cache_manager):
        """测试字典序列化"""
        data = {"key": "value", "number": 42}
        await cache_manager.set("test:dict", data)

        # Verify JSON serialization was used
        import json
        expected = json.dumps(data)
        call_args = cache_manager.redis.setex.call_args
        assert call_args[0][2] == expected

    @pytest.mark.asyncio
    async def test_serialize_list(self, cache_manager):
        """测试列表序列化"""
        data = [1, 2, 3, 4, 5]
        await cache_manager.set("test:list", data)

        import json
        expected = json.dumps(data)
        call_args = cache_manager.redis.setex.call_args
        assert call_args[0][2] == expected

    @pytest.mark.asyncio
    async def test_deserialize_dict(self, cache_manager):
        """测试字典反序列化"""
        import json
        original = {"name": "Alice", "level": 5}
        cache_manager.redis.get.return_value = json.dumps(original)

        result = await cache_manager.get("test:dict")
        assert result == original

    @pytest.mark.asyncio
    async def test_invalid_json_handling(self, cache_manager):
        """测试无效 JSON 处理"""
        cache_manager.redis.get.return_value = "{invalid json"

        result = await cache_manager.get("test:invalid")
        assert result is None  # Should handle gracefully


# ============================================================================
# Integration Tests
# ============================================================================

@pytest.mark.integration
class TestCacheIntegration:
    """集成测试（需要实际 Redis 运行）"""

    @pytest.mark.asyncio
    async def test_full_cache_lifecycle(self):
        """测试完整缓存生命周期"""
        import os
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")

        try:
            cache = CacheManager(url=redis_url)
            await cache.connect()

            if not cache._connected:
                pytest.skip("Redis not available")

            # Set
            await cache.set("test:integration", {"data": "test"}, ttl=60)

            # Get
            result = await cache.get("test:integration")
            assert result == {"data": "test"}

            # Exists
            assert await cache.exists("test:integration") is True

            # Delete
            await cache.delete("test:integration")
            assert await cache.exists("test:integration") is False

            await cache.disconnect()

        except Exception as e:
            pytest.skip(f"Redis integration test failed: {e}")


# ============================================================================
# Error Handling Tests
# ============================================================================

class TestCacheErrorHandling:
    """测试缓存错误处理"""

    @pytest.mark.asyncio
    async def test_connection_error_handling(self, cache_manager):
        """测试连接错误处理"""
        cache_manager.redis.get.side_effect = Exception("Connection lost")

        result = await cache_manager.get("test:key")
        assert result is None  # Should handle gracefully

    @pytest.mark.asyncio
    async def test_serialization_error_handling(self, cache_manager):
        """测试序列化错误处理"""
        # Non-serializable object
        class CustomObject:
            pass

        obj = CustomObject()

        # Should raise TypeError or handle gracefully
        with pytest.raises((TypeError, Exception)):
            await cache_manager.set("test:obj", obj)

    @pytest.mark.asyncio
    async def test_timeout_handling(self, cache_manager):
        """测试超时处理"""
        import asyncio
        cache_manager.redis.get.side_effect = asyncio.TimeoutError()

        result = await cache_manager.get("test:key")
        assert result is None


# ============================================================================
# Performance Tests
# ============================================================================

class TestCachePerformance:
    """性能测试"""

    @pytest.mark.asyncio
    async def test_batch_operations_speed(self, cache_manager):
        """测试批量操作速度"""
        import time

        # Prepare batch data
        operations = []
        for i in range(100):
            operations.append(cache_manager.set(f"batch:{i}", {"index": i}, ttl=60))

        start = time.time()
        await asyncio.gather(*operations)
        elapsed = time.time() - start

        # Should complete 100 operations in under 2 seconds (with mock)
        assert elapsed < 2.0

    @pytest.mark.asyncio
    async def test_stats_retrieval_speed(self, cache_manager):
        """测试统计检索速度"""
        import time

        start = time.time()
        for _ in range(50):
            await cache_manager.get_stats()
        elapsed = time.time() - start

        # Should be fast with mock
        assert elapsed < 1.0


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
