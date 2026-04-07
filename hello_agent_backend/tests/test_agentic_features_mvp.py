import json

import pytest

from app.db.repository import DatabaseRepository
from app.services import quest_manager as quest_manager_module
from app.services.quest_manager import QuestManager
from app.services.social_manager import SocialManager


@pytest.fixture
async def agentic_repo(tmp_path):
    repo = DatabaseRepository(str(tmp_path / "agentic.db"))
    await repo.initialize()
    await repo.migrate_v1_to_v2()
    await repo.create_player("player1", "Player One", 200)
    await repo.create_npc("pierre", "Pierre")
    return repo


@pytest.mark.asyncio
async def test_social_event_updates_stage(agentic_repo):
    social = SocialManager()
    # monkeypatch global repository used by social manager
    from app.services import social_manager as social_module

    social_module.db_repo = agentic_repo

    result = await social.record_event("pierre", "player1", "gift")
    assert result["success"] is True
    assert result["relationship_stage"] in {"warming", "close"}


@pytest.mark.asyncio
async def test_daily_narrative_storage(agentic_repo):
    saved = await agentic_repo.save_daily_narrative(
        "spring",
        3,
        1,
        "今天村里发生了几件趣事。",
        [{"id": "evt_1", "title": "测试事件"}],
        "fallback",
    )
    assert saved is True

    loaded = await agentic_repo.get_daily_narrative("spring", 3, 1)
    assert loaded is not None
    assert loaded["summary"] == "今天村里发生了几件趣事。"


@pytest.mark.asyncio
async def test_verify_objective_location_and_time(agentic_repo, monkeypatch):
    await agentic_repo.create_quest(
        "quest_loc_time", "Window Quest", "Reach location at time", "player1", "pierre", 100
    )
    await agentic_repo.transactional_update(
        [
            (
                "UPDATE quests SET objectives = ?, progress = ? WHERE id = ?",
                (
                    json.dumps(
                        [
                            {"type": "reach_location", "location": "town_center"},
                            {"type": "time_window", "start_hour": 18, "end_hour": 22},
                        ]
                    ),
                    "{}",
                    "quest_loc_time",
                ),
            )
        ]
    )

    monkeypatch.setattr(quest_manager_module, "db_repo", agentic_repo)
    manager = QuestManager()
    result = await manager.verify_quest_objectives(
        "quest_loc_time",
        "player1",
        {"location": "town_center", "current_hour": 20},
    )
    assert result["success"] is True
    assert result["all_completed"] is True
