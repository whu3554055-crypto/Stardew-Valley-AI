import json

import pytest

from app.db.repository import DatabaseRepository
from app.services import quest_manager as quest_manager_module
from app.services.quest_manager import QuestManager


@pytest.fixture
async def quest_env(tmp_path, monkeypatch):
    db_path = tmp_path / "quest_test.db"
    repo = DatabaseRepository(str(db_path))
    await repo.initialize()
    await repo.migrate_v1_to_v2()

    await repo.create_npc("pierre", "Pierre")
    await repo.create_player("player1", "Player One", 100)
    await repo.create_quest("quest_collect", "Collect Wood", "Bring wood", "player1", "pierre", 50)
    await repo.transactional_update([
        (
            "UPDATE quests SET objectives = ?, progress = ? WHERE id = ?",
            (
                json.dumps([
                    {"type": "collect_item", "item_id": "wood", "required": 10},
                    {"type": "talk_to_npc", "npc_id": "pierre"},
                ]),
                json.dumps({}),
                "quest_collect",
            ),
        )
    ])

    monkeypatch.setattr(quest_manager_module, "db_repo", repo)
    manager = QuestManager()
    return manager, repo


@pytest.mark.asyncio
async def test_verify_quest_objectives_partial_completion(quest_env):
    manager, repo = quest_env
    result = await manager.verify_quest_objectives(
        quest_id="quest_collect",
        player_id="player1",
        player_state={
            "inventory": {"wood": 10},
            "talked_to_npcs": [],
        },
    )

    assert result["success"] is True
    assert result["all_completed"] is False
    assert result["progress"]["objective_0"] is True
    assert result["progress"]["objective_1"] is False

    quest = await repo.get_quest("quest_collect")
    assert quest is not None
    persisted_progress = json.loads(quest["progress"])
    assert persisted_progress["objective_0"] is True
    assert persisted_progress["objective_1"] is False


@pytest.mark.asyncio
async def test_verify_quest_objectives_auto_completes_and_rewards(quest_env):
    manager, repo = quest_env
    before = await repo.get_player("player1")
    assert before is not None
    before_gold = before["gold"]

    result = await manager.verify_quest_objectives(
        quest_id="quest_collect",
        player_id="player1",
        player_state={
            "inventory": {"wood": 12},
            "talked_to_npcs": ["pierre"],
        },
    )

    assert result["success"] is True
    assert result["all_completed"] is True
    assert result["completion"]["success"] is True

    quest = await repo.get_quest("quest_collect")
    assert quest is not None
    assert quest["status"] == "completed"

    after = await repo.get_player("player1")
    assert after is not None
    assert after["gold"] == before_gold + 50
