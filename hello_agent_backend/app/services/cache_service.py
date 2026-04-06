"""
Redis Cache Service for Database Query Optimization

Provides intelligent caching layer to reduce database load and improve response times.
Uses Redis with automatic cache invalidation and TTL management.
"""

import json
import logging
from typing import Optional, Any, Dict, List
from datetime import timedelta

from app.core.cache import cache as redis_cache

logger = logging.getLogger(__name__)


# ============================================================================
# Cache Configuration
# ============================================================================

class CacheConfig:
    """Cache TTL configuration (in seconds)"""

    # Short-lived caches (1-5 minutes)
    NPC_LOCATION_TTL = 60           # NPC current location changes frequently
    PLAYER_STATUS_TTL = 30          # Player energy/health updates often
    WORLD_STATE_TTL = 120           # World state (time, weather)

    # Medium-lived caches (10-30 minutes)
    NPC_PROFILE_TTL = 600           # NPC profiles rarely change
    ITEM_DATABASE_TTL = 1800        # Item definitions are static
    QUEST_TEMPLATE_TTL = 900        # Quest templates

    # Long-lived caches (1-24 hours)
    LEADERBOARD_TTL = 300           # Leaderboards update periodically
    SHOP_INVENTORY_TTL = 600        # Shop stock
    SEASONAL_EVENTS_TTL = 3600      # Seasonal events change daily

    # Very long-lived (days)
    ACHIEVEMENT_DEFS_TTL = 86400    # Achievement definitions never change
    DIALOGUE_TEMPLATES_TTL = 43200  # Dialogue templates

    # Default TTL
    DEFAULT_TTL = 300


# ============================================================================
# Cache Keys
# ============================================================================

class CacheKeys:
    """Cache key generators for consistent naming"""

    @staticmethod
    def npc_profile(npc_id: str) -> str:
        return f"npc:profile:{npc_id}"

    @staticmethod
    def npc_location(npc_id: str) -> str:
        return f"npc:location:{npc_id}"

    @staticmethod
    def npcs_by_location(location: str) -> str:
        return f"npcs:location:{location}"

    @staticmethod
    def player_inventory(player_id: str) -> str:
        return f"player:inventory:{player_id}"

    @staticmethod
    def player_status(player_id: str) -> str:
        return f"player:status:{player_id}"

    @staticmethod
    def player_friendship(player_id: str, npc_id: str) -> str:
        return f"friendship:{player_id}:{npc_id}"

    @staticmethod
    def quest_active(quest_id: str) -> str:
        return f"quest:active:{quest_id}"

    @staticmethod
    def quests_by_player(player_id: str, status: str = "active") -> str:
        return f"quests:player:{player_id}:{status}"

    @staticmethod
    def item_definition(item_id: str) -> str:
        return f"item:def:{item_id}"

    @staticmethod
    def shop_inventory(shop_id: str) -> str:
        return f"shop:inventory:{shop_id}"

    @staticmethod
    def leaderboard(leaderboard_type: str, limit: int = 10) -> str:
        return f"leaderboard:{leaderboard_type}:{limit}"

    @staticmethod
    def world_state() -> str:
        return "world:state"

    @staticmethod
    def seasonal_events(season: str) -> str:
        return f"events:season:{season}"


# ============================================================================
# Cached Repository Methods
# ============================================================================

class CachedRepository:
    """
    Decorator class that adds caching to database repository methods

    Usage:
        cached_repo = CachedRepository(db_repository)
        npc = await cached_repo.get_cached_npc("pierre")
    """

    def __init__(self, repo):
        self.repo = repo
        self.config = CacheConfig()
        self.keys = CacheKeys()

    # ========================================================================
    # NPC Caching
    # ========================================================================

    async def get_cached_npc(self, npc_id: str) -> Optional[Dict[str, Any]]:
        """Get NPC profile with caching"""
        cache_key = self.keys.npc_profile(npc_id)

        # Try cache first
        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        # Cache miss - fetch from database
        logger.debug(f"Cache MISS: {cache_key}")
        npc = await self.repo.get_npc(npc_id)

        if npc:
            # Store in cache
            await redis_cache.set(
                cache_key,
                json.dumps(npc, default=str),
                expire=self.config.NPC_PROFILE_TTL
            )

        return npc

    async def get_cached_npcs_by_location(self, location: str) -> List[Dict[str, Any]]:
        """Get NPCs at location with caching"""
        cache_key = self.keys.npcs_by_location(location)

        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        npcs = await self.repo.get_npcs_by_location(location)

        if npcs:
            await redis_cache.set(
                cache_key,
                json.dumps(npcs, default=str),
                expire=self.config.NPC_LOCATION_TTL
            )

        return npcs

    async def invalidate_npc_cache(self, npc_id: str):
        """Invalidate NPC cache on updates"""
        cache_key = self.keys.npc_profile(npc_id)
        await redis_cache.delete(cache_key)
        logger.debug(f"Cache INVALIDATED: {cache_key}")

    # ========================================================================
    # Player Caching
    # ========================================================================

    async def get_cached_player_inventory(self, player_id: str) -> Optional[List[Dict]]:
        """Get player inventory with caching"""
        cache_key = self.keys.player_inventory(player_id)

        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        # Fetch from database (implement this method in repository)
        inventory = await self._fetch_player_inventory(player_id)

        if inventory:
            await redis_cache.set(
                cache_key,
                json.dumps(inventory, default=str),
                expire=self.config.PLAYER_STATUS_TTL
            )

        return inventory

    async def invalidate_player_inventory(self, player_id: str):
        """Invalidate player inventory cache on changes"""
        cache_key = self.keys.player_inventory(player_id)
        await redis_cache.delete(cache_key)
        logger.debug(f"Cache INVALIDATED: {cache_key}")

    async def get_cached_friendship(self, player_id: str, npc_id: str) -> Optional[int]:
        """Get friendship level with caching"""
        cache_key = self.keys.player_friendship(player_id, npc_id)

        cached = await redis_cache.get(cache_key)
        if cached is not None:
            logger.debug(f"Cache HIT: {cache_key}")
            return int(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        friendship = await self.repo.get_friendship_level(player_id, npc_id)

        if friendship is not None:
            await redis_cache.set(
                cache_key,
                friendship,
                expire=self.config.PLAYER_STATUS_TTL
            )

        return friendship

    async def invalidate_friendship_cache(self, player_id: str, npc_id: str):
        """Invalidate friendship cache on updates"""
        cache_key = self.keys.player_friendship(player_id, npc_id)
        await redis_cache.delete(cache_key)

    # ========================================================================
    # Quest Caching
    # ========================================================================

    async def get_cached_quests_for_player(self, player_id: str, status: str = "active") -> List[Dict]:
        """Get player's quests with caching"""
        cache_key = self.keys.quests_by_player(player_id, status)

        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        # Implement in repository
        quests = await self._fetch_player_quests(player_id, status)

        if quests:
            await redis_cache.set(
                cache_key,
                json.dumps(quests, default=str),
                expire=self.config.QUEST_TEMPLATE_TTL
            )

        return quests

    async def invalidate_player_quests_cache(self, player_id: str):
        """Invalidate quest cache on quest completion"""
        for status in ["active", "completed"]:
            cache_key = self.keys.quests_by_player(player_id, status)
            await redis_cache.delete(cache_key)

    # ========================================================================
    # Item Caching
    # ========================================================================

    async def get_cached_item_definition(self, item_id: str) -> Optional[Dict]:
        """Get item definition with caching"""
        cache_key = self.keys.item_definition(item_id)

        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        # Fetch from item manager or database
        item = await self._fetch_item_definition(item_id)

        if item:
            await redis_cache.set(
                cache_key,
                json.dumps(item, default=str),
                expire=self.config.ITEM_DATABASE_TTL
            )

        return item

    # ========================================================================
    # Leaderboard Caching
    # ========================================================================

    async def get_cached_leaderboard(self, leaderboard_type: str, limit: int = 10) -> List[Dict]:
        """Get leaderboard with caching"""
        cache_key = self.keys.leaderboard(leaderboard_type, limit)

        cached = await redis_cache.get(cache_key)
        if cached:
            logger.debug(f"Cache HIT: {cache_key}")
            return json.loads(cached) if isinstance(cached, str) else cached

        logger.debug(f"Cache MISS: {cache_key}")
        # Fetch from database
        leaderboard = await self._fetch_leaderboard(leaderboard_type, limit)

        if leaderboard:
            await redis_cache.set(
                cache_key,
                json.dumps(leaderboard, default=str),
                expire=self.config.LEADERBOARD_TTL
            )

        return leaderboard

    async def invalidate_leaderboard(self, leaderboard_type: str):
        """Invalidate leaderboard on score updates"""
        pattern = f"leaderboard:{leaderboard_type}:*"
        keys = await redis_cache.keys(pattern)
        if keys:
            await redis_cache.delete(*keys)

    # ========================================================================
    # Helper Methods (to be implemented in repository)
    # ========================================================================

    async def _fetch_player_inventory(self, player_id: str) -> List[Dict]:
        """Fetch player inventory from database"""
        # This should call the actual repository method
        # Placeholder implementation
        return []

    async def _fetch_player_quests(self, player_id: str, status: str) -> List[Dict]:
        """Fetch player quests from database"""
        return []

    async def _fetch_item_definition(self, item_id: str) -> Optional[Dict]:
        """Fetch item definition from database"""
        return None

    async def _fetch_leaderboard(self, leaderboard_type: str, limit: int) -> List[Dict]:
        """Fetch leaderboard from database"""
        return []

    # ========================================================================
    # Cache Management
    # ========================================================================

    async def clear_all_caches(self):
        """Clear all cached data (use with caution!)"""
        pattern = "*"
        keys = await redis_cache.keys(pattern)
        if keys:
            await redis_cache.delete(*keys)
            logger.info(f"Cleared {len(keys)} cache entries")

    async def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        # Count keys by pattern
        patterns = [
            "npc:profile:*",
            "player:inventory:*",
            "quest:active:*",
            "item:def:*",
            "leaderboard:*"
        ]

        stats = {}
        for pattern in patterns:
            keys = await redis_cache.keys(pattern)
            stats[pattern] = len(keys) if keys else 0

        return stats
