"""
SQLite Database Models - Game state persistence

Provides persistent storage for:
- NPC states and relationships
- Player data and inventory
- Quests and achievements
- World state history

Architecture:
    - aiosqlite for async database access
    - Connection pooling
    - Automatic schema migration
    - CRUD operations for all entities

Usage:
    from app.db.models import game_db

    # Initialize (call once at startup)
    await game_db.initialize()

    # Query NPC
    npc = await game_db.get_npc("pierre")

    # Update player gold
    await game_db.update_player_gold("player1", 1000)
"""

import aiosqlite
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)


class GameDatabase:
    """
    Async SQLite database manager for game state

    Tables:
    - npcs: NPC states and metadata
    - players: Player data
    - inventory: Player items
    - relationships: NPC-player friendship levels
    - quests: Active and completed quests
    - world_state: Historical world state snapshots
    """

    def __init__(self, db_path: str = "data/game_state.db"):
        self.db_path = db_path
        self._initialized = False

    async def initialize(self):
        """Create tables if they don't exist"""
        if self._initialized:
            return

        try:
            async with aiosqlite.connect(self.db_path) as db:
                # Enable WAL mode for better concurrent performance
                await db.execute("PRAGMA journal_mode=WAL")

                # NPCs table
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS npcs (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        location TEXT DEFAULT 'unknown',
                        mood TEXT DEFAULT 'neutral',
                        energy INTEGER DEFAULT 100,
                        schedule TEXT DEFAULT '',
                        personality TEXT DEFAULT '{}',
                        occupation TEXT DEFAULT '',
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                # Players table
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS players (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        gold INTEGER DEFAULT 500,
                        level INTEGER DEFAULT 1,
                        experience INTEGER DEFAULT 0,
                        location TEXT DEFAULT 'farmhouse',
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                # Inventory table
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS inventory (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        player_id TEXT NOT NULL,
                        item_id TEXT NOT NULL,
                        item_name TEXT NOT NULL,
                        quantity INTEGER DEFAULT 1,
                        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
                    )
                """)

                # Relationships table (NPC-player friendship)
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS relationships (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        npc_id TEXT NOT NULL,
                        player_id TEXT NOT NULL,
                        friendship_points INTEGER DEFAULT 0,
                        level INTEGER DEFAULT 0,
                        gifts_given_today INTEGER DEFAULT 0,
                        last_gift_date TEXT DEFAULT '',
                        last_interaction TEXT DEFAULT '',
                        last_interaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(npc_id, player_id),
                        FOREIGN KEY (npc_id) REFERENCES npcs(id) ON DELETE CASCADE,
                        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
                    )
                """)

                # Quests table
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS quests (
                        id TEXT PRIMARY KEY,
                        title TEXT NOT NULL,
                        description TEXT,
                        status TEXT DEFAULT 'active' CHECK(status IN ('active', 'completed', 'failed')),
                        assigned_to TEXT,
                        assigned_by TEXT,
                        reward_gold INTEGER DEFAULT 0,
                        reward_items TEXT DEFAULT '[]',
                        progress TEXT DEFAULT '{}',
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        completed_at TIMESTAMP,
                        FOREIGN KEY (assigned_to) REFERENCES players(id) ON DELETE SET NULL,
                        FOREIGN KEY (assigned_by) REFERENCES npcs(id) ON DELETE SET NULL
                    )
                """)

                # World state history table
                await db.execute("""
                    CREATE TABLE IF NOT EXISTS world_state_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        season TEXT NOT NULL,
                        day INTEGER NOT NULL,
                        year INTEGER NOT NULL,
                        time_of_day TEXT NOT NULL,
                        weather TEXT NOT NULL,
                        temperature REAL,
                        recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                # Create indexes for performance
                await db.execute("CREATE INDEX IF NOT EXISTS idx_inventory_player ON inventory(player_id)")
                await db.execute("CREATE INDEX IF NOT EXISTS idx_relationships_npc ON relationships(npc_id)")
                await db.execute("CREATE INDEX IF NOT EXISTS idx_relationships_player ON relationships(player_id)")
                await db.execute("CREATE INDEX IF NOT EXISTS idx_quests_status ON quests(status)")
                await db.execute("CREATE INDEX IF NOT EXISTS idx_world_state_date ON world_state_history(year, season, day)")

                await db.commit()

            self._initialized = True
            logger.info(f"Game database initialized at {self.db_path}")

        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            raise

    # ========================================================================
    # NPC Operations
    # ========================================================================

    async def get_npc(self, npc_id: str) -> Optional[Dict[str, Any]]:
        """Get NPC by ID"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM npcs WHERE id = ?", (npc_id,)) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None

    async def create_npc(self, npc_id: str, name: str, location: str = "unknown", mood: str = "neutral") -> bool:
        """Create a new NPC"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "INSERT OR REPLACE INTO npcs (id, name, location, mood) VALUES (?, ?, ?, ?)",
                    (npc_id, name, location, mood)
                )
                await db.commit()
            logger.info(f"Created NPC: {npc_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to create NPC: {e}")
            return False

    async def update_npc_mood(self, npc_id: str, mood: str) -> bool:
        """Update NPC mood"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "UPDATE npcs SET mood = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (mood, npc_id)
                )
                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to update NPC mood: {e}")
            return False

    async def update_npc_location(self, npc_id: str, location: str) -> bool:
        """Update NPC location"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "UPDATE npcs SET location = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (location, npc_id)
                )
                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to update NPC location: {e}")
            return False

    async def get_all_npcs(self) -> List[Dict[str, Any]]:
        """Get all NPCs"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM npcs ORDER BY name") as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]

    # ========================================================================
    # Player Operations
    # ========================================================================

    async def get_player(self, player_id: str) -> Optional[Dict[str, Any]]:
        """Get player by ID"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM players WHERE id = ?", (player_id,)) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None

    async def create_player(self, player_id: str, name: str, gold: int = 500) -> bool:
        """Create a new player"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "INSERT OR REPLACE INTO players (id, name, gold) VALUES (?, ?, ?)",
                    (player_id, name, gold)
                )
                await db.commit()
            logger.info(f"Created player: {player_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to create player: {e}")
            return False

    async def update_player_gold(self, player_id: str, gold: int) -> bool:
        """Update player gold amount"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "UPDATE players SET gold = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (gold, player_id)
                )
                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to update player gold: {e}")
            return False

    # ========================================================================
    # Inventory Operations
    # ========================================================================

    async def get_inventory(self, player_id: str) -> List[Dict[str, Any]]:
        """Get player's inventory"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM inventory WHERE player_id = ?",
                (player_id,)
            ) as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]

    async def add_item(self, player_id: str, item_id: str, item_name: str, quantity: int = 1) -> bool:
        """Add item to player's inventory"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                # Check if item already exists
                async with db.execute(
                    "SELECT quantity FROM inventory WHERE player_id = ? AND item_id = ?",
                    (player_id, item_id)
                ) as cursor:
                    row = await cursor.fetchone()

                    if row:
                        # Update quantity
                        new_quantity = row[0] + quantity
                        await db.execute(
                            "UPDATE inventory SET quantity = ? WHERE player_id = ? AND item_id = ?",
                            (new_quantity, player_id, item_id)
                        )
                    else:
                        # Insert new item
                        await db.execute(
                            "INSERT INTO inventory (player_id, item_id, item_name, quantity) VALUES (?, ?, ?, ?)",
                            (player_id, item_id, item_name, quantity)
                        )

                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to add item: {e}")
            return False

    async def remove_item(self, player_id: str, item_id: str, quantity: int = 1) -> bool:
        """Remove item from player's inventory"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute(
                    "SELECT quantity FROM inventory WHERE player_id = ? AND item_id = ?",
                    (player_id, item_id)
                ) as cursor:
                    row = await cursor.fetchone()

                    if row:
                        new_quantity = row[0] - quantity
                        if new_quantity <= 0:
                            await db.execute(
                                "DELETE FROM inventory WHERE player_id = ? AND item_id = ?",
                                (player_id, item_id)
                            )
                        else:
                            await db.execute(
                                "UPDATE inventory SET quantity = ? WHERE player_id = ? AND item_id = ?",
                                (new_quantity, player_id, item_id)
                            )
                        await db.commit()

            return True
        except Exception as e:
            logger.error(f"Failed to remove item: {e}")
            return False

    # ========================================================================
    # Relationship Operations
    # ========================================================================

    async def get_relationship(self, npc_id: str, player_id: str = "player") -> Optional[Dict[str, Any]]:
        """Get relationship between NPC and player"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM relationships WHERE npc_id = ? AND player_id = ?",
                (npc_id, player_id)
            ) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None

    async def update_friendship(self, npc_id: str, player_id: str, points: int) -> bool:
        """Update friendship points"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                # Calculate level (every 250 points = 1 level)
                current = await self.get_relationship(npc_id, player_id)

                if current:
                    new_points = current['friendship_points'] + points
                    new_level = new_points // 250

                    await db.execute(
                        """UPDATE relationships
                           SET friendship_points = ?, level = ?,
                               last_interaction_date = CURRENT_TIMESTAMP
                           WHERE npc_id = ? AND player_id = ?""",
                        (new_points, new_level, npc_id, player_id)
                    )
                else:
                    new_level = points // 250
                    await db.execute(
                        """INSERT INTO relationships
                           (npc_id, player_id, friendship_points, level)
                           VALUES (?, ?, ?, ?)""",
                        (npc_id, player_id, points, new_level)
                    )

                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to update friendship: {e}")
            return False

    # ========================================================================
    # Quest Operations
    # ========================================================================

    async def get_quest(self, quest_id: str) -> Optional[Dict[str, Any]]:
        """Get quest by ID"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM quests WHERE id = ?", (quest_id,)) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None

    async def get_active_quests(self, player_id: str) -> List[Dict[str, Any]]:
        """Get all active quests for a player"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM quests WHERE assigned_to = ? AND status = 'active'",
                (player_id,)
            ) as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]

    async def create_quest(self, quest_id: str, title: str, description: str,
                          assigned_to: str, assigned_by: str, reward_gold: int = 0) -> bool:
        """Create a new quest"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    """INSERT INTO quests
                       (id, title, description, assigned_to, assigned_by, reward_gold)
                       VALUES (?, ?, ?, ?, ?, ?)""",
                    (quest_id, title, description, assigned_to, assigned_by, reward_gold)
                )
                await db.commit()
            logger.info(f"Created quest: {quest_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to create quest: {e}")
            return False

    async def complete_quest(self, quest_id: str) -> bool:
        """Mark quest as completed"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    """UPDATE quests
                       SET status = 'completed', completed_at = CURRENT_TIMESTAMP
                       WHERE id = ?""",
                    (quest_id,)
                )
                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to complete quest: {e}")
            return False

    # ========================================================================
    # World State Operations
    # ========================================================================

    async def record_world_state(self, season: str, day: int, year: int,
                                 time_of_day: str, weather: str, temperature: float = None) -> bool:
        """Record a snapshot of world state"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    """INSERT INTO world_state_history
                       (season, day, year, time_of_day, weather, temperature)
                       VALUES (?, ?, ?, ?, ?, ?)""",
                    (season, day, year, time_of_day, weather, temperature)
                )
                await db.commit()
            return True
        except Exception as e:
            logger.error(f"Failed to record world state: {e}")
            return False

    async def get_current_world_state(self) -> Optional[Dict[str, Any]]:
        """Get the most recent world state"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM world_state_history ORDER BY recorded_at DESC LIMIT 1"
            ) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None

    # ========================================================================
    # Utility Operations
    # ========================================================================

    async def clear_all_data(self) -> bool:
        """Clear all data from all tables (use with caution!)"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("DELETE FROM world_state_history")
                await db.execute("DELETE FROM quests")
                await db.execute("DELETE FROM relationships")
                await db.execute("DELETE FROM inventory")
                await db.execute("DELETE FROM players")
                await db.execute("DELETE FROM npcs")
                await db.commit()
            logger.warning("All game data cleared!")
            return True
        except Exception as e:
            logger.error(f"Failed to clear data: {e}")
            return False


# Global database instance (singleton)
game_db = GameDatabase()
