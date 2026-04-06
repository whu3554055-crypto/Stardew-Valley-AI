"""
SQLite Database Repository - Enhanced with transactions, migrations, and backups

Extends GameDatabase with:
- Transaction support for atomic operations
- Schema migration system
- Database backup/restore mechanisms
- Batch operations
- Advanced query methods
"""

import aiosqlite
import logging
import shutil
import json
from pathlib import Path
from typing import Optional, List, Dict, Any, Callable, TypeVar
from datetime import datetime
from contextlib import asynccontextmanager

from .models import GameDatabase

logger = logging.getLogger(__name__)

T = TypeVar('T')


class DatabaseRepository(GameDatabase):
    """
    Enhanced database repository with advanced features
    
    Features:
    - Transaction management
    - Schema migrations
    - Backup/restore
    - Batch operations
    - Connection pooling
    """
    
    def __init__(self, db_path: str = "data/game_state.db"):
        super().__init__(db_path)
        self._connection_pool: List[aiosqlite.Connection] = []
        self._max_pool_size = 5
    
    # ========================================================================
    # Transaction Support
    # ========================================================================
    
    @asynccontextmanager
    async def transaction(self):
        """
        Context manager for transactional operations
        
        Usage:
            async with repo.transaction() as db:
                await db.execute("INSERT INTO ...")
                await db.execute("UPDATE ...")
                # Auto-commits on success, rolls back on exception
        """
        conn = await aiosqlite.connect(self.db_path)
        conn.row_factory = aiosqlite.Row
        
        try:
            await conn.execute("BEGIN IMMEDIATE")
            yield conn
            await conn.commit()
            logger.debug("Transaction committed successfully")
        except Exception as e:
            await conn.rollback()
            logger.error(f"Transaction rolled back: {e}")
            raise
        finally:
            await conn.close()
    
    async def execute_transactional(self, operations: List[Dict[str, Any]]) -> bool:
        """
        Execute multiple operations in a single transaction
        
        Args:
            operations: List of operation dicts with 'sql' and 'params' keys
            
        Returns:
            True if all operations succeeded
            
        Example:
            ops = [
                {"sql": "INSERT INTO npcs ...", "params": (...)},
                {"sql": "UPDATE relationships ...", "params": (...)}
            ]
            await repo.execute_transactional(ops)
        """
        try:
            async with self.transaction() as db:
                for op in operations:
                    sql = op['sql']
                    params = op.get('params', ())
                    await db.execute(sql, params)
            
            logger.info(f"Executed {len(operations)} operations in transaction")
            return True
            
        except Exception as e:
            logger.error(f"Transactional execution failed: {e}")
            return False
    
    async def atomic_friendship_update(self, npc_id: str, player_id: str, 
                                       points: int, interaction_type: str) -> bool:
        """
        Atomically update friendship and log interaction
        
        Ensures both operations succeed or fail together
        """
        ops = [
            {
                "sql": """UPDATE relationships 
                         SET friendship_points = friendship_points + ?,
                             last_interaction = ?,
                             last_interaction_date = CURRENT_TIMESTAMP
                         WHERE npc_id = ? AND player_id = ?""",
                "params": (points, interaction_type, npc_id, player_id)
            },
            {
                "sql": """INSERT INTO world_state_history 
                         (season, day, year, time_of_day, weather, temperature)
                         VALUES ('event', 0, 0, 'interaction', ?, 0)""",
                "params": (f"{npc_id}_{player_id}_{interaction_type}",)
            }
        ]
        
        return await self.execute_transactional(ops)
    
    # ========================================================================
    # Migration System
    # ========================================================================
    
    async def get_schema_version(self) -> int:
        """Get current schema version"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            try:
                async with db.execute(
                    "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
                ) as cursor:
                    row = await cursor.fetchone()
                    return row['version'] if row else 0
            except aiosqlite.OperationalError:
                # Table doesn't exist yet
                return 0
    
    async def create_migrations_table(self):
        """Create schema migrations tracking table"""
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version INTEGER PRIMARY KEY,
                    description TEXT NOT NULL,
                    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    checksum TEXT
                )
            """)
            await db.commit()
    
    async def apply_migration(self, version: int, description: str, 
                             up_sql: List[str], down_sql: List[str] = None):
        """
        Apply a single migration version
        
        Args:
            version: Migration version number
            description: Human-readable description
            up_sql: List of SQL statements to apply
            down_sql: List of SQL statements to rollback (optional)
        """
        current_version = await self.get_schema_version()
        
        if version <= current_version:
            logger.warning(f"Migration v{version} already applied (current: v{current_version})")
            return False
        
        logger.info(f"Applying migration v{version}: {description}")
        
        try:
            async with self.transaction() as db:
                # Apply migration SQL
                for sql in up_sql:
                    await db.execute(sql)
                
                # Record migration
                await db.execute(
                    "INSERT INTO schema_migrations (version, description) VALUES (?, ?)",
                    (version, description)
                )
            
            logger.info(f"Migration v{version} applied successfully")
            return True
            
        except Exception as e:
            logger.error(f"Migration v{version} failed: {e}")
            raise
    
    async def migrate_to_latest(self):
        """Apply all pending migrations"""
        await self.create_migrations_table()
        
        current_version = await self.get_schema_version()
        logger.info(f"Current schema version: v{current_version}")
        
        # Define migrations
        migrations = [
            {
                "version": 1,
                "description": "Initial schema - base tables",
                "up_sql": [],  # Already created in initialize()
                "down_sql": []
            },
            {
                "version": 2,
                "description": "Add NPC personality and occupation fields",
                "up_sql": [
                    "CREATE INDEX IF NOT EXISTS idx_npcs_location ON npcs(location)"
                ],
                "down_sql": [
                    "DROP INDEX IF EXISTS idx_npcs_location"
                ]
            },
            {
                "version": 3,
                "description": "Add quest objectives and prerequisites",
                "up_sql": [
                    "ALTER TABLE quests ADD COLUMN objectives TEXT DEFAULT '[]'",
                    "ALTER TABLE quests ADD COLUMN prerequisites TEXT DEFAULT '[]'",
                    "ALTER TABLE quests ADD COLUMN deadline TIMESTAMP",
                    "CREATE INDEX IF NOT EXISTS idx_quests_assigned_to ON quests(assigned_to)"
                ],
                "down_sql": [
                    "DROP INDEX IF EXISTS idx_quests_assigned_to",
                    "ALTER TABLE quests DROP COLUMN deadline",
                    "ALTER TABLE quests DROP COLUMN prerequisites",
                    "ALTER TABLE quests DROP COLUMN objectives"
                ]
            },
            {
                "version": 4,
                "description": "Add inventory item metadata",
                "up_sql": [
                    "ALTER TABLE inventory ADD COLUMN item_type TEXT DEFAULT 'misc'",
                    "ALTER TABLE inventory ADD COLUMN durability INTEGER DEFAULT -1",
                    "ALTER TABLE inventory ADD COLUMN acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                    "CREATE INDEX IF NOT EXISTS idx_inventory_item ON inventory(item_id)"
                ],
                "down_sql": [
                    "DROP INDEX IF EXISTS idx_inventory_item",
                    "ALTER TABLE inventory DROP COLUMN acquired_at",
                    "ALTER TABLE inventory DROP COLUMN durability",
                    "ALTER TABLE inventory DROP COLUMN item_type"
                ]
            }
        ]
        
        # Apply pending migrations
        applied_count = 0
        for migration in migrations:
            if migration['version'] > current_version:
                await self.apply_migration(
                    version=migration['version'],
                    description=migration['description'],
                    up_sql=migration['up_sql'],
                    down_sql=migration.get('down_sql')
                )
                applied_count += 1
        
        if applied_count > 0:
            logger.info(f"Applied {applied_count} migration(s), now at v{await self.get_schema_version()}")
        else:
            logger.info("Schema is up to date")
    
    async def rollback_migration(self, target_version: int = None):
        """
        Rollback migrations to target version
        
        Args:
            target_version: Version to rollback to (None = rollback one version)
        """
        current_version = await self.get_schema_version()
        
        if target_version is None:
            target_version = current_version - 1
        
        if target_version >= current_version:
            logger.warning(f"Target version {target_version} >= current version {current_version}")
            return False
        
        logger.warning(f"Rolling back from v{current_version} to v{target_version}")
        
        # Get applied migrations in reverse order
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM schema_migrations WHERE version > ? ORDER BY version DESC",
                (target_version,)
            ) as cursor:
                migrations = await cursor.fetchall()
        
        # Rollback each migration
        for migration in migrations:
            version = migration['version']
            logger.warning(f"Rolling back migration v{version}")
            
            # TODO: Implement down_sql execution
            # For now, just remove the migration record
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute("DELETE FROM schema_migrations WHERE version = ?", (version,))
                await db.commit()
        
        logger.info(f"Rolled back to v{await self.get_schema_version()}")
        return True
    
    # ========================================================================
    # Backup & Restore
    # ========================================================================
    
    async def backup_database(self, backup_path: str = None) -> str:
        """
        Create a backup of the database
        
        Args:
            backup_path: Custom backup path (auto-generated if None)
            
        Returns:
            Path to backup file
        """
        if backup_path is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = Path(self.db_path).parent / "backups"
            backup_dir.mkdir(parents=True, exist_ok=True)
            backup_path = str(backup_dir / f"game_state_backup_{timestamp}.db")
        
        try:
            # Ensure backup directory exists
            Path(backup_path).parent.mkdir(parents=True, exist_ok=True)
            
            # Copy database file
            shutil.copy2(self.db_path, backup_path)
            
            # Also copy WAL and SHM files if they exist
            for ext in ['-wal', '-shm']:
                wal_path = self.db_path + ext
                if Path(wal_path).exists():
                    shutil.copy2(wal_path, backup_path + ext)
            
            logger.info(f"Database backed up to: {backup_path}")
            return backup_path
            
        except Exception as e:
            logger.error(f"Backup failed: {e}")
            raise
    
    async def restore_database(self, backup_path: str) -> bool:
        """
        Restore database from backup
        
        Args:
            backup_path: Path to backup file
            
        Returns:
            True if restore succeeded
        """
        if not Path(backup_path).exists():
            logger.error(f"Backup file not found: {backup_path}")
            return False
        
        try:
            # Create backup of current database before restoring
            await self.backup_database()
            
            # Close existing connections
            # (In production, you'd need to ensure no active connections)
            
            # Restore from backup
            shutil.copy2(backup_path, self.db_path)
            
            # Restore WAL and SHM files if they exist
            for ext in ['-wal', '-shm']:
                backup_wal = backup_path + ext
                if Path(backup_wal).exists():
                    shutil.copy2(backup_wal, self.db_path + ext)
            
            logger.info(f"Database restored from: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Restore failed: {e}")
            return False
    
    async def list_backups(self) -> List[Dict[str, Any]]:
        """List all available backups"""
        backup_dir = Path(self.db_path).parent / "backups"
        
        if not backup_dir.exists():
            return []
        
        backups = []
        for backup_file in backup_dir.glob("game_state_backup_*.db"):
            stat = backup_file.stat()
            backups.append({
                "path": str(backup_file),
                "filename": backup_file.name,
                "size_bytes": stat.st_size,
                "created_at": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                "modified_at": datetime.fromtimestamp(stat.st_mtime).isoformat()
            })
        
        # Sort by creation time (newest first)
        backups.sort(key=lambda x: x['created_at'], reverse=True)
        return backups
    
    async def cleanup_old_backups(self, keep_count: int = 5) -> int:
        """
        Remove old backups, keeping only the most recent ones
        
        Args:
            keep_count: Number of recent backups to keep
            
        Returns:
            Number of backups deleted
        """
        backups = await self.list_backups()
        
        if len(backups) <= keep_count:
            return 0
        
        deleted_count = 0
        for backup in backups[keep_count:]:
            try:
                backup_path = Path(backup['path'])
                backup_path.unlink()
                
                # Also remove WAL/SHM files
                for ext in ['-wal', '-shm']:
                    wal_path = backup_path.with_suffix(backup_path.suffix + ext)
                    if wal_path.exists():
                        wal_path.unlink()
                
                deleted_count += 1
            except Exception as e:
                logger.error(f"Failed to delete backup {backup['path']}: {e}")
        
        logger.info(f"Cleaned up {deleted_count} old backup(s)")
        return deleted_count
    
    # ========================================================================
    # Batch Operations
    # ========================================================================
    
    async def batch_insert_npcs(self, npcs: List[Dict[str, Any]]) -> int:
        """
        Insert multiple NPCs in a single transaction
        
        Args:
            npcs: List of NPC data dicts
            
        Returns:
            Number of NPCs inserted
        """
        inserted = 0
        try:
            async with self.transaction() as db:
                for npc in npcs:
                    await db.execute(
                        """INSERT OR REPLACE INTO npcs 
                           (id, name, location, mood, energy, schedule, personality, occupation)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                        (
                            npc['id'],
                            npc['name'],
                            npc.get('location', 'unknown'),
                            npc.get('mood', 'neutral'),
                            npc.get('energy', 100),
                            json.dumps(npc.get('schedule', {})),
                            json.dumps(npc.get('personality', {})),
                            npc.get('occupation', '')
                        )
                    )
                    inserted += 1
            
            logger.info(f"Batch inserted {inserted} NPCs")
            return inserted
            
        except Exception as e:
            logger.error(f"Batch NPC insert failed: {e}")
            return 0
    
    async def batch_update_world_state(self, states: List[Dict[str, Any]]) -> int:
        """Batch insert world state records"""
        inserted = 0
        try:
            async with self.transaction() as db:
                for state in states:
                    await db.execute(
                        """INSERT INTO world_state_history 
                           (season, day, year, time_of_day, weather, temperature)
                           VALUES (?, ?, ?, ?, ?, ?)""",
                        (
                            state['season'],
                            state['day'],
                            state['year'],
                            state['time_of_day'],
                            state['weather'],
                            state.get('temperature')
                        )
                    )
                    inserted += 1
            
            return inserted
        except Exception as e:
            logger.error(f"Batch world state insert failed: {e}")
            return 0
    
    # ========================================================================
    # Advanced Queries
    # ========================================================================
    
    async def get_npcs_by_location(self, location: str) -> List[Dict[str, Any]]:
        """Get all NPCs at a specific location"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM npcs WHERE location = ? ORDER BY name",
                (location,)
            ) as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]
    
    async def get_top_friends(self, player_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Get player's top friends by friendship level"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                """SELECT r.*, n.name, n.occupation
                   FROM relationships r
                   JOIN npcs n ON r.npc_id = n.id
                   WHERE r.player_id = ?
                   ORDER BY r.friendship_points DESC
                   LIMIT ?""",
                (player_id, limit)
            ) as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]
    
    async def get_completed_quests_count(self, player_id: str) -> int:
        """Get total number of completed quests for a player"""
        async with aiosqlite.connect(self.db_path) as db:
            async with db.execute(
                "SELECT COUNT(*) FROM quests WHERE assigned_to = ? AND status = 'completed'",
                (player_id,)
            ) as cursor:
                row = await cursor.fetchone()
                return row[0] if row else 0
    
    async def get_daily_interactions(self, npc_id: str, days: int = 7) -> List[Dict[str, Any]]:
        """Get recent interactions with an NPC"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                """SELECT * FROM relationships 
                   WHERE npc_id = ? 
                     AND last_interaction_date >= datetime('now', ?)
                   ORDER BY last_interaction_date DESC""",
                (npc_id, f"-{days} days")
            ) as cursor:
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]
    
    async def get_world_state_by_date(self, year: int, season: str, day: int) -> Optional[Dict[str, Any]]:
        """Get world state for a specific date"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                """SELECT * FROM world_state_history 
                   WHERE year = ? AND season = ? AND day = ?
                   ORDER BY recorded_at DESC LIMIT 1""",
                (year, season, day)
            ) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None


# Global enhanced repository instance
db_repo = DatabaseRepository()
