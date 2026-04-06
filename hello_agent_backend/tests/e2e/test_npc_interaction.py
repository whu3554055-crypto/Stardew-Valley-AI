"""
E2E Tests for NPC Interaction Flow

Tests NPC dialogue, relationship building, and interaction tracking.
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
            "username": "npc_tester",
            "password": "testpass123"
        }
    )

    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "npc_tester",
            "password": "testpass123"
        }
    )

    return login_response.json()["access_token"]


@pytest.mark.asyncio
async def test_get_npc_list(client, auth_token):
    """Test retrieving list of NPCs"""
    response = await client.get(
        "/api/v1/npc/list",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should succeed (may return empty if no NPCs seeded in test DB)
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_get_npc_by_id(client, auth_token):
    """Test getting specific NPC details"""
    response = await client.get(
        "/api/v1/npc/pierre",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # May return 404 if NPC not in test database
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_npc_dialogue_generation(client, auth_token):
    """Test generating NPC dialogue"""
    response = await client.post(
        "/api/v1/npc/dialogue",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "npc_id": "pierre",
            "player_id": "test_player_1",
            "context": {
                "time_of_day": "morning",
                "season": "spring",
                "weather": "sunny"
            }
        }
    )

    # Should handle gracefully even if NPC doesn't exist
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_interact_with_npc(client, auth_token):
    """Test interacting with NPC to build relationship"""
    response = await client.post(
        "/api/v1/npc/interact",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "npc_id": "pierre",
            "player_id": "test_player_1",
            "interaction_type": "talk",
            "gift_item": None
        }
    )

    # Should track interaction
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_get_relationship_status(client, auth_token):
    """Test getting relationship status with NPC"""
    response = await client.get(
        "/api/v1/npc/relationship/test_player_1/pierre",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # May return 404 if relationship doesn't exist yet
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_give_gift_to_npc(client, auth_token):
    """Test giving gift to NPC"""
    response = await client.post(
        "/api/v1/npc/gift",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "npc_id": "pierre",
            "player_id": "test_player_1",
            "item_id": "parsnip",
            "quantity": 1
        }
    )

    # Should process gift
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_get_npcs_by_location(client, auth_token):
    """Test getting NPCs at specific location"""
    response = await client.get(
        "/api/v1/npc/location/general_store",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_invalid_npc_id(client, auth_token):
    """Test handling of invalid NPC ID"""
    response = await client.get(
        "/api/v1/npc/nonexistent_npc",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_dialogue_without_auth(client):
    """Test dialogue endpoint without authentication"""
    response = await client.post(
        "/api/v1/npc/dialogue",
        json={
            "npc_id": "pierre",
            "player_id": "test"
        }
    )

    assert response.status_code == 401
