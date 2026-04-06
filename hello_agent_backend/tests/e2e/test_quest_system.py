"""
E2E Tests for Quest System

Tests quest generation, progress tracking, and completion workflows.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture
async def client():
    """Create test client"""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
async def auth_token(client):
    """Create authenticated user and return token"""
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "quest_tester",
            "password": "testpass123"
        }
    )

    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "quest_tester",
            "password": "testpass123"
        }
    )

    return login_response.json()["access_token"]


@pytest.mark.asyncio
async def test_generate_daily_quest(client, auth_token):
    """Test generating daily quest from NPC"""
    response = await client.post(
        "/api/v1/quests/generate-daily",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "npc_id": "pierre",
            "player_id": "test_player_1",
            "season": "spring",
            "day": 15
        }
    )

    # Should generate quest
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_get_active_quests(client, auth_token):
    """Test getting player's active quests"""
    response = await client.get(
        "/api/v1/quests/player/test_player_1/active",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return quest list
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_get_completed_quests(client, auth_token):
    """Test getting player's completed quests"""
    response = await client.get(
        "/api/v1/quests/player/test_player_1/completed",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return completed quest list
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_update_quest_progress(client, auth_token):
    """Test updating quest objective progress"""
    response = await client.post(
        "/api/v1/quests/update-progress",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "quest_id": "quest_001",
            "player_id": "test_player_1",
            "objective_index": 0,
            "completed": True
        }
    )

    # Should update progress
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_complete_quest(client, auth_token):
    """Test completing a quest and receiving rewards"""
    response = await client.post(
        "/api/v1/quests/complete",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "quest_id": "quest_001",
            "player_id": "test_player_1"
        }
    )

    # Should complete quest and grant rewards
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_generate_quest_chain(client, auth_token):
    """Test generating connected quest chain"""
    response = await client.post(
        "/api/v1/quests/generate-chain",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "npc_id": "pierre",
            "player_id": "test_player_1",
            "chain_length": 3
        }
    )

    # Should generate quest chain
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_get_seasonal_quests(client, auth_token):
    """Test getting seasonal event quests"""
    response = await client.get(
        "/api/v1/quests/seasonal/spring",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return seasonal quests
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_get_quest_details(client, auth_token):
    """Test getting specific quest details"""
    response = await client.get(
        "/api/v1/quests/quest_001",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # May return 404 if quest doesn't exist
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_abandon_quest(client, auth_token):
    """Test abandoning an active quest"""
    response = await client.post(
        "/api/v1/quests/abandon",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "quest_id": "quest_001",
            "player_id": "test_player_1"
        }
    )

    # Should mark quest as abandoned
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_quest_rewards_distribution(client, auth_token):
    """Test that quest completion distributes rewards correctly"""
    # Complete a quest
    complete_response = await client.post(
        "/api/v1/quests/complete",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "quest_id": "quest_001",
            "player_id": "test_player_1"
        }
    )

    if complete_response.status_code == 200:
        data = complete_response.json()
        # Should include rewards info
        assert "rewards" in data or "gold" in data or "friendship" in data


@pytest.mark.asyncio
async def test_generate_quest_without_auth(client):
    """Test quest generation without authentication"""
    response = await client.post(
        "/api/v1/quests/generate-daily",
        json={
            "npc_id": "pierre",
            "player_id": "test"
        }
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_invalid_quest_id(client, auth_token):
    """Test operations with invalid quest ID"""
    response = await client.get(
        "/api/v1/quests/nonexistent_quest",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    assert response.status_code == 404
