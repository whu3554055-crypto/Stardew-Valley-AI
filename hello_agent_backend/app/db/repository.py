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
import sqlite3
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

    async def transactional_update(self, operations: List[tuple]) -> None:
        """
        Execute atomic batch operations from tuple inputs.

        Args:
            operations: List of `(sql, params)` tuples.

        Raises:
            Exception: Re-raises any SQL/connection exception after rollback.
        """
        if not operations:
            return

        async with aiosqlite.connect(self.db_path) as db:
            try:
                await db.execute("BEGIN IMMEDIATE")
                for op in operations:
                    sql: str = ""
                    params: tuple = ()
                    if isinstance(op, dict):
                        sql = str(op.get("sql", ""))
                        raw_params = op.get("params", ())
                        params = tuple(raw_params) if isinstance(raw_params, (list, tuple)) else (raw_params,)
                    elif isinstance(op, tuple) and len(op) >= 2:
                        sql = str(op[0])
                        raw_params2 = op[1]
                        params = tuple(raw_params2) if isinstance(raw_params2, (list, tuple)) else (raw_params2,)
                    else:
                        raise ValueError(f"Unsupported transactional operation: {op}")
                    if not sql.strip():
                        raise ValueError("Transactional SQL must not be empty")
                    await db.execute(sql, params)
                await db.commit()
                logger.debug("transactional_update committed %d operations", len(operations))
            except Exception:
                await db.rollback()
                raise
    
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

    async def _column_exists(self, db: aiosqlite.Connection, table: str, column: str) -> bool:
        """Check whether a column exists in a table."""
        async with db.execute(f"PRAGMA table_info({table})") as cursor:
            rows = await cursor.fetchall()
            return any(row[1] == column for row in rows)

    async def migrate_v1_to_v2(self) -> bool:
        """
        Perform idempotent schema/data migration from v1 to v2.

        v2 changes:
        - `quests.objectives` JSON text column
        - `quests.prerequisites` JSON text column
        - `quests.deadline` timestamp text column
        - index on `quests.assigned_to`
        """
        async with aiosqlite.connect(self.db_path) as db:
            try:
                await db.execute("BEGIN IMMEDIATE")

                if not await self._column_exists(db, "quests", "objectives"):
                    await db.execute("ALTER TABLE quests ADD COLUMN objectives TEXT DEFAULT '[]'")
                if not await self._column_exists(db, "quests", "prerequisites"):
                    await db.execute("ALTER TABLE quests ADD COLUMN prerequisites TEXT DEFAULT '[]'")
                if not await self._column_exists(db, "quests", "deadline"):
                    await db.execute("ALTER TABLE quests ADD COLUMN deadline TIMESTAMP")

                await db.execute(
                    "CREATE INDEX IF NOT EXISTS idx_quests_assigned_to ON quests(assigned_to)"
                )

                # Backfill existing rows for consistent downstream JSON parsing
                await db.execute(
                    "UPDATE quests SET objectives = '[]' WHERE objectives IS NULL OR objectives = ''"
                )
                await db.execute(
                    "UPDATE quests SET prerequisites = '[]' "
                    "WHERE prerequisites IS NULL OR prerequisites = ''"
                )

                await db.commit()
                logger.info("Migration v1 -> v2 completed")
                return True
            except Exception as e:
                await db.rollback()
                logger.error(f"Migration v1 -> v2 failed: {e}")
                raise
    
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
            
            # Use sqlite online backup API for consistency under concurrent access.
            src = sqlite3.connect(self.db_path)
            dst = sqlite3.connect(backup_path)
            try:
                src.backup(dst)
            finally:
                dst.close()
                src.close()
            
            # Also copy WAL and SHM files if they exist
            for ext in ['-wal', '-shm']:
                wal_path = self.db_path + ext
                if Path(wal_path).exists():
                    shutil.copy2(wal_path, backup_path + ext)
            
            await self._write_backup_manifest(backup_path)
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
            
            if not await self.verify_integrity():
                logger.error("Restore completed but integrity check failed")
                return False
            logger.info(f"Database restored from: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Restore failed: {e}")
            return False

    async def verify_integrity(self) -> bool:
        """Run SQLite integrity check and return boolean result."""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("PRAGMA integrity_check") as cursor:
                    row = await cursor.fetchone()
                    if not row:
                        return False
                    return str(row[0]).lower() == "ok"
        except Exception as e:
            logger.error(f"Integrity check failed: {e}")
            return False

    async def _write_backup_manifest(self, backup_path: str) -> None:
        """Write sidecar metadata for traceability/recovery operations."""
        p = Path(backup_path)
        payload = {
            "backup_file": str(p),
            "created_at": datetime.utcnow().isoformat() + "Z",
            "size_bytes": p.stat().st_size if p.exists() else 0,
            "source_db": str(Path(self.db_path)),
        }
        manifest_path = p.with_suffix(p.suffix + ".meta.json")
        manifest_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    
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

    # ========================================================================
    # Performance Optimization Methods
    # ========================================================================

    async def analyze_query_performance(self, query: str, params: tuple = ()) -> Dict[str, Any]:
        """Analyze query execution plan for optimization"""
        import time

        start_time = time.time()
        async with aiosqlite.connect(self.db_path) as db:
            # Get query plan
            async with db.execute(f"EXPLAIN QUERY PLAN {query}", params) as cursor:
                plan_rows = await cursor.fetchall()
                plan = [dict(row) for row in plan_rows]

            # Execute query to measure actual time
            db.row_factory = aiosqlite.Row
            async with db.execute(query, params) as cursor:
                rows = await cursor.fetchall()
                result_count = len(rows)

        duration_ms = (time.time() - start_time) * 1000

        return {
            "query": query,
            "params": params,
            "execution_time_ms": round(duration_ms, 2),
            "result_count": result_count,
            "query_plan": plan,
            "uses_index": any("USING INDEX" in str(row) for row in plan),
            "full_table_scan": any("SCAN TABLE" in str(row) for row in plan)
        }

    async def optimize_database(self):
        """Run database optimization (VACUUM, ANALYZE)"""
        try:
            async with aiosqlite.connect(self.db_path) as db:
                # Update statistics for query optimizer
                await db.execute("ANALYZE")

                # Rebuild database to reduce fragmentation
                await db.execute("VACUUM")

                logger.info("Database optimization completed")
                return True
        except Exception as e:
            logger.error(f"Database optimization failed: {e}")
            return False

    async def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics for monitoring"""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row

            # Table sizes
            async with db.execute("""
                SELECT name, 
                       (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=t.name) as exists_flag
                FROM sqlite_master t
                WHERE type='table'
                  AND name NOT LIKE 'sqlite_%'
            """) as cursor:
                tables = await cursor.fetchall()

            table_stats = {}
            for table in tables:
                table_name = table['name']
                async with db.execute(f"SELECT COUNT(*) as count FROM {table_name}") as cursor:
                    row = await cursor.fetchone()
                    table_stats[table_name] = row['count'] if row else 0

            # Database file size
            import os
            db_size = os.path.getsize(self.db_path) if os.path.exists(self.db_path) else 0

            return {
                "database_size_bytes": db_size,
                "database_size_mb": round(db_size / (1024 * 1024), 2),
                "table_row_counts": table_stats,
                "total_tables": len(table_stats)
            }

    async def create_performance_indexes(self):
        """Create additional indexes for common queries"""
        indexes = [
            # NPC queries
            ("idx_npcs_location", "npcs", "location"),
            ("idx_npcs_occupation", "npcs", "occupation"),

            # Player queries
            ("idx_players_username", "players", "username"),
            ("idx_players_gold", "players", "gold"),

            # Relationship queries
            ("idx_relationships_player", "relationships", "player_id"),
            ("idx_relationships_npc", "relationships", "npc_id"),
            ("idx_relationships_friendship", "relationships", "friendship_points"),

            # Quest queries
            ("idx_quests_player_status", "quests", "player_id, status"),
            ("idx_quests_completed", "quests", "completed_at"),

            # Inventory queries
            ("idx_inventory_player", "inventory", "player_id"),
            ("idx_inventory_item", "inventory", "item_id"),

            # World state queries
            ("idx_world_state_date", "world_state_history", "year, season, day"),
        ]

        created = 0
        async with aiosqlite.connect(self.db_path) as db:
            for idx_name, table, columns in indexes:
                try:
                    await db.execute(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table} ({columns})")
                    created += 1
                except Exception as e:
                    logger.warning(f"Failed to create index {idx_name}: {e}")

        logger.info(f"Created/verified {created} performance indexes")
        return created

    # ========================================================================
    # Agentic Social & Narrative Features
    # ========================================================================

    async def _ensure_agentic_tables(self) -> None:
        """Create social/narrative tables required by agentic features."""
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute(
                """
                CREATE TABLE IF NOT EXISTS relationship_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    npc_id TEXT NOT NULL,
                    player_id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    delta INTEGER NOT NULL,
                    metadata TEXT DEFAULT '{}',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            await db.execute(
                "CREATE INDEX IF NOT EXISTS idx_rel_events_npc_player "
                "ON relationship_events(npc_id, player_id, created_at)"
            )
            await db.execute(
                """
                CREATE TABLE IF NOT EXISTS daily_narratives (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    season TEXT NOT NULL,
                    day INTEGER NOT NULL,
                    year INTEGER NOT NULL,
                    summary TEXT NOT NULL,
                    events_json TEXT DEFAULT '[]',
                    source TEXT DEFAULT 'fallback',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(season, day, year)
                )
                """
            )
            await db.commit()

    async def record_relationship_event(
        self,
        npc_id: str,
        player_id: str,
        event_type: str,
        delta: int,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Persist a relationship event and update friendship atomically."""
        await self._ensure_agentic_tables()
        payload = json.dumps(metadata or {}, ensure_ascii=False)
        try:
            await self.transactional_update(
                [
                    (
                        """
                        INSERT INTO relationship_events (npc_id, player_id, event_type, delta, metadata)
                        VALUES (?, ?, ?, ?, ?)
                        """,
                        (npc_id, player_id, event_type, delta, payload),
                    ),
                    (
                        """
                        INSERT INTO relationships (npc_id, player_id, friendship_points, level)
                        VALUES (?, ?, ?, ?)
                        ON CONFLICT(npc_id, player_id) DO UPDATE SET
                            friendship_points = friendship_points + excluded.friendship_points,
                            level = (friendship_points + excluded.friendship_points) / 250,
                            last_interaction = excluded.player_id || ':' || excluded.npc_id,
                            last_interaction_date = CURRENT_TIMESTAMP
                        """,
                        (npc_id, player_id, delta, max(delta, 0) // 250),
                    ),
                ]
            )
            return True
        except Exception as e:
            logger.error(f"Failed recording relationship event: {e}")
            return False

    async def get_relationship_stage(self, npc_id: str, player_id: str) -> str:
        """Map friendship points into a coarse social stage."""
        relationship = await self.get_relationship(npc_id, player_id)
        points = relationship.get("friendship_points", 0) if relationship else 0
        if points >= 750:
            return "close"
        if points >= 250:
            return "warming"
        if points <= -250:
            return "conflict"
        if points < 0:
            return "tense"
        return "neutral"

    async def save_daily_narrative(
        self,
        season: str,
        day: int,
        year: int,
        summary: str,
        events: List[Dict[str, Any]],
        source: str = "llm",
    ) -> bool:
        """Upsert daily narrative summary/events."""
        await self._ensure_agentic_tables()
        try:
            await self.transactional_update(
                [
                    (
                        """
                        INSERT INTO daily_narratives (season, day, year, summary, events_json, source)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT(season, day, year) DO UPDATE SET
                            summary = excluded.summary,
                            events_json = excluded.events_json,
                            source = excluded.source,
                            created_at = CURRENT_TIMESTAMP
                        """,
                        (season, day, year, summary, json.dumps(events, ensure_ascii=False), source),
                    )
                ]
            )
            return True
        except Exception as e:
            logger.error(f"Failed saving daily narrative: {e}")
            return False

    async def get_daily_narrative(self, season: str, day: int, year: int) -> Optional[Dict[str, Any]]:
        """Retrieve narrative for a game day."""
        await self._ensure_agentic_tables()
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                "SELECT * FROM daily_narratives WHERE season = ? AND day = ? AND year = ?",
                (season, day, year),
            ) as cursor:
                row = await cursor.fetchone()
                return dict(row) if row else None


# Global enhanced repository instance
db_repo = DatabaseRepository()
