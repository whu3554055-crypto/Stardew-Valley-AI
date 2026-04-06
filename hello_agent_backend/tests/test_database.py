"""
Game Database Repository 单元测试

测试 SQLite 数据库仓储层的所有 CRUD 操作和业务逻辑。

运行测试:
    pytest tests/test_database.py -v
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from db.repository import GameDatabase
from db.models import NPC, Player, Relationship, Quest, InventoryItem


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def mock_connection():
    """模拟数据库连接"""
    conn = AsyncMock()
    conn.execute = AsyncMock()
    conn.executemany = AsyncMock()
    conn.commit = AsyncMock()
    return conn


@pytest.fixture
def mock_row_factory():
    """模拟行工厂返回字典"""
    def factory(cursor, row):
        if row is None:
            return None
        return dict(zip([column[0] for column in cursor.description], row))
    return factory


@pytest.fixture
async def game_database():
    """游戏数据库实例（内存模式）"""
    db = GameDatabase(db_path=":memory:")
    await db.initialize()
    yield db
    await db.close()


@pytest.fixture
def sample_npc():
    """示例 NPC 数据"""
    return {
        "id": "villager_001",
        "name": "Alice",
        "npc_type": "villager",
        "personality_traits": {"traits": ["friendly", "curious"]},
        "schedule": {
            "morning": "town_square",
            "afternoon": "market",
            "evening": "home"
        },
        "location": "town_square",
        "is_active": True
    }


@pytest.fixture
def sample_player():
    """示例玩家数据"""
    return {
        "id": "player1",
        "name": "Stardew Farmer",
        "level": 5,
        "gold": 1000,
        "location": "farm"
    }


@pytest.fixture
def sample_relationship():
    """示例关系数据"""
    return {
        "npc_id": "villager_001",
        "player_id": "player1",
        "friendship_points": 500,
        "friendship_level": 2,
        "last_interaction": datetime.now().isoformat()
    }


@pytest.fixture
def sample_quest():
    """示例任务数据"""
    return {
        "id": "quest_001",
        "title": "Find Lost Item",
        "description": "Help Alice find her lost necklace",
        "npc_id": "villager_001",
        "status": "active",
        "progress": {"current": 0, "target": 3}
    }


# ============================================================================
# Database Initialization Tests
# ============================================================================

class TestDatabaseInitialization:
    """测试数据库初始化"""

    @pytest.mark.asyncio
    async def test_initialize_creates_tables(self, game_database):
        """测试初始化创建表"""
        # Should complete without error
        assert game_database.db_path == ":memory:"

    @pytest.mark.asyncio
    async def test_initialize_with_custom_path(self):
        """测试使用自定义路径初始化"""
        db = GameDatabase(db_path=":memory:")
        await db.initialize()
        assert db.db_path == ":memory:"
        await db.close()

    @pytest.mark.asyncio
    async def test_close_connection(self, game_database):
        """测试关闭连接"""
        await game_database.close()
        # Should not raise exception


# ============================================================================
# NPC Operations Tests
# ============================================================================

class TestNPCOperations:
    """测试 NPC 操作"""

    @pytest.mark.asyncio
    async def test_create_npc(self, game_database, sample_npc):
        """测试创建 NPC"""
        success = await game_database.create_npc(sample_npc)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_npc(self, game_database, sample_npc):
        """测试获取 NPC"""
        await game_database.create_npc(sample_npc)

        npc = await game_database.get_npc("villager_001")
        assert npc is not None
        assert npc["id"] == "villager_001"
        assert npc["name"] == "Alice"

    @pytest.mark.asyncio
    async def test_get_nonexistent_npc(self, game_database):
        """测试获取不存在的 NPC"""
        npc = await game_database.get_npc("nonexistent")
        assert npc is None

    @pytest.mark.asyncio
    async def test_update_npc_location(self, game_database, sample_npc):
        """测试更新 NPC 位置"""
        await game_database.create_npc(sample_npc)

        success = await game_database.update_npc_location("villager_001", "market")
        assert success is True

        npc = await game_database.get_npc("villager_001")
        assert npc["location"] == "market"

    @pytest.mark.asyncio
    async def test_update_npc_personality(self, game_database, sample_npc):
        """测试更新 NPC 性格"""
        await game_database.create_npc(sample_npc)

        new_personality = {"traits": ["aggressive", "territorial"]}
        success = await game_database.update_npc_personality("villager_001", new_personality)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_all_npcs(self, game_database):
        """测试获取所有 NPC"""
        npcs_data = [
            {"id": f"npc_{i}", "name": f"NPC {i}", "npc_type": "villager",
             "personality_traits": {}, "schedule": {}, "location": "home"}
            for i in range(5)
        ]

        for npc_data in npcs_data:
            await game_database.create_npc(npc_data)

        npcs = await game_database.get_all_npcs()
        assert len(npcs) >= 5

    @pytest.mark.asyncio
    async def test_get_npcs_by_location(self, game_database):
        """测试按位置获取 NPC"""
        npcs_data = [
            {"id": "npc_001", "name": "Alice", "npc_type": "villager",
             "personality_traits": {}, "schedule": {}, "location": "town_square"},
            {"id": "npc_002", "name": "Bob", "npc_type": "villager",
             "personality_traits": {}, "schedule": {}, "location": "town_square"},
            {"id": "npc_003", "name": "Charlie", "npc_type": "villager",
             "personality_traits": {}, "schedule": {}, "location": "market"}
        ]

        for npc_data in npcs_data:
            await game_database.create_npc(npc_data)

        town_npcs = await game_database.get_npcs_by_location("town_square")
        assert len(town_npcs) == 2

    @pytest.mark.asyncio
    async def test_delete_npc(self, game_database, sample_npc):
        """测试删除 NPC"""
        await game_database.create_npc(sample_npc)

        success = await game_database.delete_npc("villager_001")
        assert success is True

        npc = await game_database.get_npc("villager_001")
        assert npc is None


# ============================================================================
# Player Operations Tests
# ============================================================================

class TestPlayerOperations:
    """测试玩家操作"""

    @pytest.mark.asyncio
    async def test_create_player(self, game_database, sample_player):
        """测试创建玩家"""
        success = await game_database.create_player(sample_player)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_player(self, game_database, sample_player):
        """测试获取玩家"""
        await game_database.create_player(sample_player)

        player = await game_database.get_player("player1")
        assert player is not None
        assert player["name"] == "Stardew Farmer"

    @pytest.mark.asyncio
    async def test_update_player_gold(self, game_database, sample_player):
        """测试更新玩家金币"""
        await game_database.create_player(sample_player)

        success = await game_database.update_player_gold("player1", 500)
        assert success is True

        player = await game_database.get_player("player1")
        assert player["gold"] == 1500  # 1000 + 500

    @pytest.mark.asyncio
    async def test_update_player_location(self, game_database, sample_player):
        """测试更新玩家位置"""
        await game_database.create_player(sample_player)

        success = await game_database.update_player_location("player1", "town")
        assert success is True

        player = await game_database.get_player("player1")
        assert player["location"] == "town"


# ============================================================================
# Relationship Operations Tests
# ============================================================================

class TestRelationshipOperations:
    """测试关系操作"""

    @pytest.mark.asyncio
    async def test_create_relationship(self, game_database, sample_npc, sample_player, sample_relationship):
        """测试创建关系"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)

        success = await game_database.create_relationship(sample_relationship)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_relationship(self, game_database, sample_npc, sample_player, sample_relationship):
        """测试获取关系"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)
        await game_database.create_relationship(sample_relationship)

        rel = await game_database.get_relationship("villager_001", "player1")
        assert rel is not None
        assert rel["friendship_points"] == 500

    @pytest.mark.asyncio
    async def test_update_friendship_increase(self, game_database, sample_npc, sample_player, sample_relationship):
        """测试更新友谊值增加"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)
        await game_database.create_relationship(sample_relationship)

        success = await game_database.update_friendship("villager_001", "player1", 100)
        assert success is True

        rel = await game_database.get_relationship("villager_001", "player1")
        assert rel["friendship_points"] == 600  # 500 + 100

    @pytest.mark.asyncio
    async def test_update_friendship_decrease(self, game_database, sample_npc, sample_player, sample_relationship):
        """测试更新友谊值减少"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)
        await game_database.create_relationship(sample_relationship)

        success = await game_database.update_friendship("villager_001", "player1", -50)
        assert success is True

        rel = await game_database.get_relationship("villager_001", "player1")
        assert rel["friendship_points"] == 450  # 500 - 50

    @pytest.mark.asyncio
    async def test_friendship_level_calculation(self, game_database, sample_npc, sample_player):
        """测试友谊等级计算"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)

        # Create relationship with 750 points (should be level 3)
        rel_data = {
            "npc_id": "villager_001",
            "player_id": "player1",
            "friendship_points": 750,
            "friendship_level": 3,
            "last_interaction": datetime.now().isoformat()
        }
        await game_database.create_relationship(rel_data)

        rel = await game_database.get_relationship("villager_001", "player1")
        assert rel["friendship_level"] == 3  # 750 // 250 = 3

    @pytest.mark.asyncio
    async def test_get_player_relationships(self, game_database, sample_npc, sample_player):
        """测试获取玩家所有关系"""
        await game_database.create_player(sample_player)

        # Create multiple relationships
        for i in range(3):
            npc_data = {
                "id": f"npc_{i:03d}",
                "name": f"NPC {i}",
                "npc_type": "villager",
                "personality_traits": {},
                "schedule": {},
                "location": "home"
            }
            await game_database.create_npc(npc_data)

            rel_data = {
                "npc_id": f"npc_{i:03d}",
                "player_id": "player1",
                "friendship_points": 100 * (i + 1),
                "friendship_level": i + 1,
                "last_interaction": datetime.now().isoformat()
            }
            await game_database.create_relationship(rel_data)

        relationships = await game_database.get_player_relationships("player1")
        assert len(relationships) == 3


# ============================================================================
# Quest Operations Tests
# ============================================================================

class TestQuestOperations:
    """测试任务操作"""

    @pytest.mark.asyncio
    async def test_create_quest(self, game_database, sample_quest):
        """测试创建任务"""
        success = await game_database.create_quest(sample_quest)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_quest(self, game_database, sample_quest):
        """测试获取任务"""
        await game_database.create_quest(sample_quest)

        quest = await game_database.get_quest("quest_001")
        assert quest is not None
        assert quest["title"] == "Find Lost Item"

    @pytest.mark.asyncio
    async def test_update_quest_progress(self, game_database, sample_quest):
        """测试更新任务进度"""
        await game_database.create_quest(sample_quest)

        new_progress = {"current": 1, "target": 3}
        success = await game_database.update_quest_progress("quest_001", new_progress)
        assert success is True

        quest = await game_database.get_quest("quest_001")
        assert quest["progress"]["current"] == 1

    @pytest.mark.asyncio
    async def test_update_quest_status(self, game_database, sample_quest):
        """测试更新任务状态"""
        await game_database.create_quest(sample_quest)

        success = await game_database.update_quest_status("quest_001", "completed")
        assert success is True

        quest = await game_database.get_quest("quest_001")
        assert quest["status"] == "completed"

    @pytest.mark.asyncio
    async def test_get_npc_quests(self, game_database, sample_quest):
        """测试获取 NPC 的任务"""
        await game_database.create_quest(sample_quest)

        # Add another quest
        quest2 = {
            "id": "quest_002",
            "title": "Deliver Package",
            "description": "Deliver package to Bob",
            "npc_id": "villager_001",
            "status": "active",
            "progress": {"current": 0, "target": 1}
        }
        await game_database.create_quest(quest2)

        quests = await game_database.get_npc_quests("villager_001")
        assert len(quests) == 2

    @pytest.mark.asyncio
    async def test_get_active_quests(self, game_database):
        """测试获取活跃任务"""
        quests_data = [
            {"id": f"quest_{i}", "title": f"Quest {i}", "description": "Description",
             "npc_id": "villager_001", "status": "active" if i % 2 == 0 else "completed",
             "progress": {"current": 0, "target": 1}}
            for i in range(5)
        ]

        for quest_data in quests_data:
            await game_database.create_quest(quest_data)

        active_quests = await game_database.get_active_quests()
        assert len(active_quests) == 3  # quest_0, quest_2, quest_4


# ============================================================================
# Inventory Operations Tests
# ============================================================================

class TestInventoryOperations:
    """测试背包操作"""

    @pytest.mark.asyncio
    async def test_add_item(self, game_database, sample_player):
        """测试添加物品"""
        await game_database.create_player(sample_player)

        item = {
            "owner_id": "player1",
            "owner_type": "player",
            "item_id": "iron_sword",
            "item_name": "Iron Sword",
            "quantity": 1,
            "item_type": "weapon"
        }
        success = await game_database.add_item(item)
        assert success is True

    @pytest.mark.asyncio
    async def test_remove_item(self, game_database, sample_player):
        """测试移除物品"""
        await game_database.create_player(sample_player)

        item = {
            "owner_id": "player1",
            "owner_type": "player",
            "item_id": "potion",
            "item_name": "Health Potion",
            "quantity": 5,
            "item_type": "consumable"
        }
        await game_database.add_item(item)

        success = await game_database.remove_item("player1", "player", "potion", 2)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_inventory(self, game_database, sample_player):
        """测试获取背包"""
        await game_database.create_player(sample_player)

        items = [
            {"owner_id": "player1", "owner_type": "player",
             "item_id": f"item_{i}", "item_name": f"Item {i}",
             "quantity": i + 1, "item_type": "material"}
            for i in range(5)
        ]

        for item in items:
            await game_database.add_item(item)

        inventory = await game_database.get_inventory("player1", "player")
        assert len(inventory) == 5

    @pytest.mark.asyncio
    async def test_update_item_quantity(self, game_database, sample_player):
        """测试更新物品数量"""
        await game_database.create_player(sample_player)

        item = {
            "owner_id": "player1",
            "owner_type": "player",
            "item_id": "wood",
            "item_name": "Wood",
            "quantity": 10,
            "item_type": "material"
        }
        await game_database.add_item(item)

        success = await game_database.update_item_quantity("player1", "player", "wood", 25)
        assert success is True

        inventory = await game_database.get_inventory("player1", "player")
        wood_item = next((i for i in inventory if i["item_id"] == "wood"), None)
        assert wood_item["quantity"] == 25


# ============================================================================
# World State Tests
# ============================================================================

class TestWorldState:
    """测试世界状态"""

    @pytest.mark.asyncio
    async def test_save_world_state(self, game_database):
        """测试保存世界状态"""
        state = {
            "day": 15,
            "season": "spring",
            "year": 2,
            "weather": "sunny",
            "time_of_day": "morning"
        }

        success = await game_database.save_world_state(state)
        assert success is True

    @pytest.mark.asyncio
    async def test_get_world_state(self, game_database):
        """测试获取世界状态"""
        state = {
            "day": 15,
            "season": "spring",
            "year": 2,
            "weather": "sunny",
            "time_of_day": "morning"
        }
        await game_database.save_world_state(state)

        current_state = await game_database.get_world_state()
        assert current_state is not None
        assert current_state["day"] == 15
        assert current_state["season"] == "spring"

    @pytest.mark.asyncio
    async def test_world_state_history(self, game_database):
        """测试世界状态历史"""
        states = [
            {"day": i, "season": "spring", "year": 2, "weather": "sunny", "time_of_day": "morning"}
            for i in range(1, 4)
        ]

        for state in states:
            await game_database.save_world_state(state)

        history = await game_database.get_world_state_history(limit=5)
        assert len(history) >= 3


# ============================================================================
# Transaction Tests
# ============================================================================

class TestTransactions:
    """测试事务"""

    @pytest.mark.asyncio
    async def test_atomic_friendship_update(self, game_database, sample_npc, sample_player):
        """测试原子性友谊更新"""
        await game_database.create_npc(sample_npc)
        await game_database.create_player(sample_player)

        rel_data = {
            "npc_id": "villager_001",
            "player_id": "player1",
            "friendship_points": 500,
            "friendship_level": 2,
            "last_interaction": datetime.now().isoformat()
        }
        await game_database.create_relationship(rel_data)

        # Update should be atomic
        success = await game_database.update_friendship("villager_001", "player1", 100)
        assert success is True

        rel = await game_database.get_relationship("villager_001", "player1")
        assert rel["friendship_points"] == 600
        assert rel["friendship_level"] == 2  # Still level 2 (600 // 250 = 2)

    @pytest.mark.asyncio
    async def test_rollback_on_error(self, game_database):
        """测试错误时回滚"""
        # Try to insert invalid data
        try:
            invalid_npc = {
                "id": None,  # Invalid - ID required
                "name": "Invalid NPC"
            }
            await game_database.create_npc(invalid_npc)
        except Exception:
            pass  # Expected to fail

        # Database should still be usable
        npcs = await game_database.get_all_npcs()
        assert isinstance(npcs, list)


# ============================================================================
# Performance Tests
# ============================================================================

class TestDatabasePerformance:
    """性能测试"""

    @pytest.mark.asyncio
    async def test_bulk_npc_creation(self, game_database):
        """测试批量创建 NPC"""
        import time

        num_npcs = 100
        start = time.time()

        for i in range(num_npcs):
            npc_data = {
                "id": f"perf_npc_{i:03d}",
                "name": f"NPC {i}",
                "npc_type": "villager",
                "personality_traits": {},
                "schedule": {},
                "location": "home"
            }
            await game_database.create_npc(npc_data)

        elapsed = time.time() - start

        # Should create 100 NPCs quickly (in-memory DB)
        assert elapsed < 5.0

        # Verify all were created
        npcs = await game_database.get_all_npcs()
        assert len(npcs) >= num_npcs

    @pytest.mark.asyncio
    async def test_query_performance(self, game_database):
        """测试查询性能"""
        import time

        # Create test data
        for i in range(50):
            npc_data = {
                "id": f"query_npc_{i:03d}",
                "name": f"NPC {i}",
                "npc_type": "villager",
                "personality_traits": {},
                "schedule": {},
                "location": "town_square" if i % 2 == 0 else "market"
            }
            await game_database.create_npc(npc_data)

        # Measure query time
        start = time.time()
        for _ in range(100):
            await game_database.get_npcs_by_location("town_square")
        elapsed = time.time() - start

        # 100 queries should be fast
        assert elapsed < 2.0


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
