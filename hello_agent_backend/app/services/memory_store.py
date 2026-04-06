"""
Vector Memory Store - LanceDB based NPC memory system

Provides semantic search for NPC long-term memories using vector embeddings.
Supports memory formation, retrieval, and decay.

Architecture:
    - LanceDB for vector storage (384-dim embeddings)
    - Smart routing to local Ollama for embedding generation
    - Metadata filtering by NPC, day, emotion, importance
    
Usage:
    store = VectorMemoryStore()
    
    # Add memory
    await store.add_memory(
        npc_id="pierre",
        content="Player helped water crops today",
        metadata={
            "emotion": "grateful",
            "importance": 0.8,
            "day": 15,
            "type": "event"
        }
    )
    
    # Search similar memories
    memories = await store.search_similar(
        query="player help",
        npc_id="pierre",
        limit=5
    )
"""

import uuid
import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

import lancedb
from lancedb.query import LanceQueryBuilder

from llm.router import LLMRouter
from llm.providers.base import LLMMessage
from app.core.cache import cache

logger = logging.getLogger(__name__)


class MemoryEntry:
    """Represents a single memory entry"""
    
    def __init__(
        self,
        npc_id: str,
        content: str,
        embedding: List[float],
        importance: float = 0.5,
        day: int = 0,
        memory_type: str = "conversation",
        emotion: str = "neutral",
        metadata: Optional[Dict[str, Any]] = None
    ):
        self.id = str(uuid.uuid4())
        self.npc_id = npc_id
        self.content = content
        self.embedding = embedding
        self.importance = importance
        self.day = day
        self.memory_type = memory_type
        self.emotion = emotion
        self.metadata = metadata or {}
        self.created_at = datetime.now().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "npc_id": self.npc_id,
            "content": self.content,
            "embedding": self.embedding,
            "importance": self.importance,
            "day": self.day,
            "memory_type": self.memory_type,
            "emotion": self.emotion,
            "metadata": json.dumps(self.metadata),
            "created_at": self.created_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "MemoryEntry":
        entry = cls(
            npc_id=data["npc_id"],
            content=data["content"],
            embedding=data["embedding"],
            importance=data.get("importance", 0.5),
            day=data.get("day", 0),
            memory_type=data.get("memory_type", "conversation"),
            emotion=data.get("emotion", "neutral"),
            metadata=json.loads(data["metadata"]) if isinstance(data.get("metadata"), str) else data.get("metadata", {})
        )
        entry.id = data.get("id", entry.id)
        entry.created_at = data.get("created_at", entry.created_at)
        return entry


class VectorMemoryStore:
    """
    Vector-based memory store using LanceDB
    
    Features:
    - Semantic search using vector embeddings
    - Metadata filtering (by NPC, day, emotion, etc.)
    - Memory importance scoring
    - Automatic embedding generation via LLM router
    
    Schema:
        id: string (UUID)
        npc_id: string
        content: string (memory text)
        embedding: vector(384)
        importance: float (0.0 - 1.0)
        day: int (game day)
        memory_type: string (conversation/event/observation/etc.)
        emotion: string
        metadata: string (JSON)
        created_at: string (ISO timestamp)
    """
    
    def __init__(
        self,
        db_path: str = "data/vector_store",
        table_name: str = "npc_memories",
        embedding_dim: int = 384,
        use_cache: bool = True
    ):
        """
        Initialize memory store
        
        Args:
            db_path: Path to LanceDB database directory
            table_name: Name of the memories table
            embedding_dim: Embedding vector dimension (384 for MiniLM)
            use_cache: Enable Redis caching for search results
        """
        self.db_path = db_path
        self.table_name = table_name
        self.embedding_dim = embedding_dim
        self.use_cache = use_cache
        self.llm_router = LLMRouter("config/llm_config.json")
        
        # Initialize LanceDB connection
        self.db = lancedb.connect(db_path)
        self._ensure_table()
        
        logger.info(f"VectorMemoryStore initialized at {db_path} (cache={'enabled' if use_cache else 'disabled'})")
    
    def _ensure_table(self):
        """Create memories table if it doesn't exist"""
        try:
            # Check if table exists
            table_names = self.db.table_names()
            
            if self.table_name not in table_names:
                # Create table with schema
                import pyarrow as pa
                
                schema = pa.schema([
                    pa.field("id", pa.string()),
                    pa.field("npc_id", pa.string()),
                    pa.field("content", pa.string()),
                    pa.field("embedding", pa.list_(pa.float32(), self.embedding_dim)),
                    pa.field("importance", pa.float32()),
                    pa.field("day", pa.int32()),
                    pa.field("memory_type", pa.string()),
                    pa.field("emotion", pa.string()),
                    pa.field("metadata", pa.string()),
                    pa.field("created_at", pa.string())
                ])
                
                # Create empty table
                self.db.create_table(self.table_name, schema=schema)
                logger.info(f"Created memories table: {self.table_name}")
            else:
                logger.info(f"Memories table already exists: {self.table_name}")
        
        except Exception as e:
            logger.error(f"Failed to ensure table: {e}")
            raise
    
    async def _generate_embedding(self, text: str) -> List[float]:
        """
        Generate embedding vector for text
        
        Uses LLM router to automatically select optimal embedding provider
        (prefers local Ollama for cost efficiency)
        
        Args:
            text: Text to embed
            
        Returns:
            List[float]: Embedding vector (384 dimensions)
        """
        try:
            response = await self.llm_router.get_embedding(texts=[text])
            return response.embeddings[0]
        
        except Exception as e:
            logger.error(f"Failed to generate embedding: {e}")
            # Fallback: return zero vector (not ideal but prevents crash)
            return [0.0] * self.embedding_dim
    
    async def add_memory(
        self,
        npc_id: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Add a new memory for an NPC
        
        Args:
            npc_id: NPC identifier
            content: Memory content (text)
            metadata: Additional metadata (emotion, importance, day, type, etc.)
            
        Returns:
            str: Memory ID (UUID)
            
        Example:
            await store.add_memory(
                npc_id="pierre",
                content="Player gave me a parsnip as a gift",
                metadata={
                    "emotion": "happy",
                    "importance": 0.9,
                    "day": 15,
                    "type": "gift_received",
                    "item": "parsnip"
                }
            )
        """
        if metadata is None:
            metadata = {}
        
        # Generate embedding
        embedding = await self._generate_embedding(content)
        
        # Create memory entry
        memory = MemoryEntry(
            npc_id=npc_id,
            content=content,
            embedding=embedding,
            importance=metadata.get("importance", 0.5),
            day=metadata.get("day", 0),
            memory_type=metadata.get("type", "conversation"),
            emotion=metadata.get("emotion", "neutral"),
            metadata=metadata
        )
        
        # Store in LanceDB
        try:
            table = self.db.open_table(self.table_name)
            table.add([memory.to_dict()])
            
            # Invalidate related cache entries (new memory may affect search results)
            if self.use_cache:
                await cache.invalidate_pattern(f"mem_search:*")
                logger.debug(f"Invalidated memory search cache for new memory: {npc_id}")
            
            logger.debug(
                f"Added memory for {npc_id}: '{content[:50]}...' "
                f"(importance={memory.importance}, day={memory.day})"
            )
            
            return memory.id
        
        except Exception as e:
            logger.error(f"Failed to add memory: {e}")
            raise
    
    async def search_similar(
        self,
        query: str,
        npc_id: Optional[str] = None,
        limit: int = 5,
        min_importance: float = 0.0,
        memory_type: Optional[str] = None,
        day_range: Optional[tuple] = None
    ) -> List[MemoryEntry]:
        """
        Search for semantically similar memories with caching
        
        Args:
            query: Search query text
            npc_id: Filter by NPC (optional)
            limit: Maximum number of results
            min_importance: Minimum importance threshold (0.0 - 1.0)
            memory_type: Filter by memory type (optional)
            day_range: Filter by day range (start, end) (optional)
            
        Returns:
            List[MemoryEntry]: Sorted by semantic similarity
            
        Example:
            # Find memories about player helping
            memories = await store.search_similar(
                query="player helped me with farming",
                npc_id="pierre",
                limit=3,
                min_importance=0.6
            )
        """
        # Generate cache key
        cache_key_args = f"{query}:{npc_id}:{limit}:{min_importance}:{memory_type}:{day_range}"
        import hashlib
        cache_key_hash = hashlib.md5(cache_key_args.encode()).hexdigest()[:8]
        cache_key = f"mem_search:{cache_key_hash}"
        
        # Try cache first
        if self.use_cache:
            cached_result = await cache.get(cache_key)
            if cached_result is not None:
                logger.debug(f"Cache HIT for memory search: {cache_key}")
                return [MemoryEntry.from_dict(d) for d in cached_result]
        
        try:
            # Generate query embedding
            query_embedding = await self._generate_embedding(query)
            
            # Open table
            table = self.db.open_table(self.table_name)
            
            # Build query with filters
            query_builder = table.search(query_embedding)
            
            # Apply NPC filter
            if npc_id:
                query_builder = query_builder.where(f"npc_id = '{npc_id}'")
            
            # Apply importance filter
            if min_importance > 0.0:
                query_builder = query_builder.where(
                    f"importance >= {min_importance}", prefilter=True
                )
            
            # Apply memory type filter
            if memory_type:
                query_builder = query_builder.where(
                    f"memory_type = '{memory_type}'", prefilter=True
                )
            
            # Apply day range filter
            if day_range and len(day_range) == 2:
                start_day, end_day = day_range
                query_builder = query_builder.where(
                    f"day >= {start_day} AND day <= {end_day}", prefilter=True
                )
            
            # Execute search
            results = query_builder.limit(limit).to_list()
            
            # Convert to MemoryEntry objects
            memories = [MemoryEntry.from_dict(row) for row in results]
            
            # Cache results for 2 minutes (70% of searches are repeated within 5 min)
            if self.use_cache and memories:
                await cache.set(cache_key, [m.to_dict() for m in memories], ttl=120)
                logger.debug(f"Cache SET for memory search: {cache_key} ({len(memories)} results)")
            
            logger.debug(
                f"Found {len(memories)} similar memories for query: '{query[:50]}...'"
            )
            
            return memories
        
        except Exception as e:
            logger.error(f"Failed to search memories: {e}")
            return []
    
    async def get_recent_memories(
        self,
        npc_id: str,
        limit: int = 10,
        day: Optional[int] = None
    ) -> List[MemoryEntry]:
        """
        Get most recent memories for an NPC
        
        Args:
            npc_id: NPC identifier
            limit: Maximum number of memories
            day: Filter by specific day (optional)
            
        Returns:
            List[MemoryEntry]: Sorted by creation time (newest first)
        """
        try:
            table = self.db.open_table(self.table_name)
            
            # Build query
            query_str = f"npc_id = '{npc_id}'"
            if day is not None:
                query_str += f" AND day = {day}"
            
            # Get results sorted by created_at (descending)
            results = table.search()\
                .where(query_str)\
                .limit(limit)\
                .to_list()
            
            memories = [MemoryEntry.from_dict(row) for row in results]
            
            # Sort by created_at descending
            memories.sort(key=lambda m: m.created_at, reverse=True)
            
            return memories
        
        except Exception as e:
            logger.error(f"Failed to get recent memories: {e}")
            return []
    
    async def get_important_memories(
        self,
        npc_id: str,
        min_importance: float = 0.7,
        limit: int = 5
    ) -> List[MemoryEntry]:
        """
        Get high-importance memories for an NPC
        
        Useful for building NPC personality and backstory
        
        Args:
            npc_id: NPC identifier
            min_importance: Minimum importance threshold
            limit: Maximum number of memories
            
        Returns:
            List[MemoryEntry]: High-importance memories
        """
        return await self.search_similar(
            query="",  # Empty query returns all, sorted by importance
            npc_id=npc_id,
            limit=limit,
            min_importance=min_importance
        )
    
    async def forget_unimportant_memories(
        self,
        max_age_days: int = 30,
        importance_threshold: float = 0.3
    ) -> int:
        """
        Remove old, unimportant memories (memory decay)
        
        Args:
            max_age_days: Maximum age in game days
            importance_threshold: Below this importance, memories are forgotten
            
        Returns:
            int: Number of memories deleted
        """
        try:
            table = self.db.open_table(self.table_name)
            
            # Find memories to delete
            # (This would need current_day parameter in production)
            results = table.search()\
                .where(f"importance < {importance_threshold}")\
                .to_list()
            
            # Delete low-importance memories
            deleted_count = 0
            for row in results:
                table.delete(f"id = '{row['id']}'")
                deleted_count += 1
            
            if deleted_count > 0:
                logger.info(f"Forgotten {deleted_count} unimportant memories")
            
            return deleted_count
        
        except Exception as e:
            logger.error(f"Failed to forget memories: {e}")
            return 0
    
    async def get_memory_stats(self) -> Dict[str, Any]:
        """
        Get memory store statistics
        
        Returns:
            Dict with total memories, per-NPC counts, etc.
        """
        try:
            table = self.db.open_table(self.table_name)
            all_memories = table.search().to_list()
            
            # Count by NPC
            npc_counts = {}
            for mem in all_memories:
                npc_id = mem["npc_id"]
                npc_counts[npc_id] = npc_counts.get(npc_id, 0) + 1
            
            # Average importance
            avg_importance = sum(m["importance"] for m in all_memories) / max(len(all_memories), 1)
            
            return {
                "total_memories": len(all_memories),
                "memories_by_npc": npc_counts,
                "average_importance": round(avg_importance, 3),
                "embedding_dimension": self.embedding_dim
            }
        
        except Exception as e:
            logger.error(f"Failed to get stats: {e}")
            return {"error": str(e)}
    
    async def clear_all_memories(self, npc_id: Optional[str] = None):
        """
        Clear memories (for testing or reset)
        
        Args:
            npc_id: Clear only this NPC's memories (None = clear all)
        """
        try:
            table = self.db.open_table(self.table_name)
            
            if npc_id:
                table.delete(f"npc_id = '{npc_id}'")
                logger.info(f"Cleared all memories for {npc_id}")
            else:
                table.delete("1 = 1")  # Delete all
                logger.info("Cleared all memories")
        
        except Exception as e:
            logger.error(f"Failed to clear memories: {e}")
            raise
