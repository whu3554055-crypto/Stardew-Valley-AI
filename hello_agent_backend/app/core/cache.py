"""
Cache Manager - Redis-based caching layer for performance optimization

Provides transparent caching for frequently accessed data:
- NPC memory search results
- World state queries
- LLM responses (optional)
- Agent decisions

Architecture:
    - Redis for hot cache (<10ms access)
    - Automatic cache invalidation
    - Configurable TTL per cache type
    - Pattern-based bulk invalidation

Usage:
    from app.core.cache import cache

    # Decorator-based caching
    @cache.cached(key_prefix="mem_search", ttl=60)
    async def search_memories(query, npc_id):
        ...

    # Manual cache operations
    await cache.set("key", data, ttl=300)
    data = await cache.get("key")
    await cache.invalidate_pattern("mem_search:*")
"""

import json
import logging
import hashlib
from typing import Any, Optional, Dict, Callable
from functools import wraps

import redis.asyncio as redis

logger = logging.getLogger(__name__)


class CacheManager:
    """
    Async Redis cache manager with decorator support

    Features:
    - Automatic serialization/deserialization
    - Configurable TTL (time-to-live)
    - Pattern-based invalidation
    - Cache hit/miss statistics
    - Graceful degradation if Redis unavailable
    """

    def __init__(self, url: str = "redis://localhost:6379", default_ttl: int = 300):
        """
        Initialize cache manager

        Args:
            url: Redis connection URL
            default_ttl: Default cache expiration in seconds (5 minutes)
        """
        self.url = url
        self.default_ttl = default_ttl
        self.redis: Optional[redis.Redis] = None
        self.stats = {
            "hits": 0,
            "misses": 0,
            "errors": 0
        }
        self._connected = False

    async def connect(self):
        """Establish connection to Redis"""
        try:
            self.redis = redis.from_url(
                self.url,
                decode_responses=True,
                socket_connect_timeout=5,
                retry_on_timeout=True
            )
            # Test connection
            await self.redis.ping()
            self._connected = True
            logger.info(f"Connected to Redis at {self.url}")
        except Exception as e:
            logger.warning(f"Failed to connect to Redis: {e}. Caching disabled.")
            self._connected = False

    async def disconnect(self):
        """Close Redis connection"""
        if self.redis:
            await self.redis.close()
            self._connected = False
            logger.info("Disconnected from Redis")

    async def get(self, key: str) -> Optional[Any]:
        """
        Get value from cache

        Args:
            key: Cache key

        Returns:
            Cached value or None if not found/error
        """
        if not self._connected or not self.redis:
            return None

        try:
            value = await self.redis.get(key)
            if value is None:
                self.stats["misses"] += 1
                return None

            self.stats["hits"] += 1
            return json.loads(value)

        except Exception as e:
            logger.error(f"Cache GET error for key '{key}': {e}")
            self.stats["errors"] += 1
            return None

    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """
        Set value in cache

        Args:
            key: Cache key
            value: Value to cache (must be JSON-serializable)
            ttl: Time-to-live in seconds (uses default if None)

        Returns:
            True if successful, False otherwise
        """
        if not self._connected or not self.redis:
            return False

        try:
            serialized = json.dumps(value, ensure_ascii=False, default=str)
            expire = ttl if ttl is not None else self.default_ttl
            await self.redis.setex(key, expire, serialized)
            return True

        except Exception as e:
            logger.error(f"Cache SET error for key '{key}': {e}")
            self.stats["errors"] += 1
            return False

    async def delete(self, key: str) -> bool:
        """
        Delete specific cache entry

        Args:
            key: Cache key to delete

        Returns:
            True if deleted, False otherwise
        """
        if not self._connected or not self.redis:
            return False

        try:
            await self.redis.delete(key)
            return True
        except Exception as e:
            logger.error(f"Cache DELETE error for key '{key}': {e}")
            return False

    async def invalidate_pattern(self, pattern: str) -> int:
        """
        Invalidate all keys matching pattern

        Args:
            pattern: Redis key pattern (e.g., "mem_search:*pierre*")

        Returns:
            Number of keys deleted
        """
        if not self._connected or not self.redis:
            return 0

        try:
            keys = await self.redis.keys(pattern)
            if keys:
                deleted = await self.redis.delete(*keys)
                logger.debug(f"Invalidated {deleted} cache keys matching '{pattern}'")
                return deleted
            return 0

        except Exception as e:
            logger.error(f"Cache invalidation error for pattern '{pattern}': {e}")
            return 0

    async def clear_all(self) -> bool:
        """
        Clear entire cache (use with caution!)

        Returns:
            True if successful
        """
        if not self._connected or not self.redis:
            return False

        try:
            await self.redis.flushdb()
            logger.warning("Cache cleared completely!")
            return True
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return False

    def cached(self, key_prefix: str, ttl: Optional[int] = None):
        """
        Decorator for automatic function result caching

        Args:
            key_prefix: Prefix for cache keys
            ttl: Time-to-live in seconds

        Usage:
            @cache.cached(key_prefix="npc_info", ttl=60)
            async def get_npc_info(npc_id: str):
                ...
        """
        def decorator(func: Callable):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # Generate cache key from function name and arguments
                key_args = str(args) + str(sorted(kwargs.items()))
                key_hash = hashlib.md5(key_args.encode()).hexdigest()[:8]
                cache_key = f"{key_prefix}:{func.__name__}:{key_hash}"

                # Try cache first
                cached_result = await self.get(cache_key)
                if cached_result is not None:
                    logger.debug(f"Cache HIT: {cache_key}")
                    return cached_result

                # Execute function
                logger.debug(f"Cache MISS: {cache_key}")
                result = await func(*args, **kwargs)

                # Store in cache
                if result is not None:
                    await self.set(cache_key, result, ttl)

                return result
            return wrapper
        return decorator

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total = self.stats["hits"] + self.stats["misses"]
        hit_rate = (self.stats["hits"] / total * 100) if total > 0 else 0

        return {
            **self.stats,
            "total_requests": total,
            "hit_rate_percent": round(hit_rate, 2),
            "connected": self._connected
        }

    def reset_stats(self):
        """Reset cache statistics"""
        self.stats = {"hits": 0, "misses": 0, "errors": 0}


# Global cache instance (singleton)
cache = CacheManager()
