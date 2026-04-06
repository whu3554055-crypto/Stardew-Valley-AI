"""
E2E Test Configuration and Fixtures

Provides shared fixtures and test setup for end-to-end tests.
"""

import pytest
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db.models import game_db
from app.core.cache import cache


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def test_app():
    """Initialize test database and cache"""
    # Use test database
    game_db.db_path = "data/test_game_state.db"

    # Initialize database
    await game_db.initialize()

    # Try to connect to cache (may fail in test environment)
    try:
        await cache.connect()
    except Exception:
        pass

    yield app

    # Cleanup
    await cache.disconnect()


@pytest.fixture
async def client(test_app) -> AsyncGenerator[AsyncClient, None]:
    """Create HTTP test client"""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
async def authenticated_client(client: AsyncClient) -> tuple[AsyncClient, str]:
    """Create authenticated test client with valid token"""
    # Register user
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "e2e_test_user",
            "password": "test_password_123",
            "email": "e2e@test.com"
        }
    )

    # Login
    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "e2e_test_user",
            "password": "test_password_123"
        }
    )

    token = login_response.json()["access_token"]

    # Add auth header to client
    client.headers.update({"Authorization": f"Bearer {token}"})

    return client, token


@pytest.fixture
def sample_player_data():
    """Sample player data for tests"""
    return {
        "player_id": "test_player_e2e",
        "username": "test_farmer",
        "gold": 500,
        "energy": 100,
        "health": 100
    }


@pytest.fixture
def sample_npc_data():
    """Sample NPC data for tests"""
    return {
        "npc_id": "pierre",
        "name": "Pierre",
        "location": "general_store",
        "occupation": "shopkeeper"
    }


@pytest.fixture
def sample_item_data():
    """Sample item data for tests"""
    return {
        "item_id": "parsnip",
        "name": "防风草",
        "type": "crop",
        "quantity": 10
    }


@pytest.fixture
def sample_quest_data():
    """Sample quest data for tests"""
    return {
        "quest_id": "test_quest_001",
        "title": "Test Quest",
        "description": "A test quest for E2E testing",
        "objectives": [
            {"description": "Collect 5 parsnips", "completed": False}
        ],
        "rewards": {
            "gold": 100,
            "friendship": 10
        }
    }


@pytest.mark.asyncio
async def test_health_endpoint(client):
    """Test health check endpoint"""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


@pytest.mark.asyncio
async def test_root_endpoint(client):
    """Test root endpoint"""
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "service" in data
    assert data["service"] == "Hello-Agent Backend"


@pytest.mark.asyncio
async def test_api_info_endpoint(client):
    """Test API info endpoint"""
    response = await client.get("/api/info")
    assert response.status_code == 200
    data = response.json()
    assert "endpoints" in data


@pytest.mark.asyncio
async def test_metrics_endpoint(client):
    """Test Prometheus metrics endpoint"""
    response = await client.get("/metrics")
    assert response.status_code == 200
    # Metrics should be in text format
    assert "text/plain" in response.headers.get("content-type", "")


@pytest.mark.asyncio
async def test_websocket_stats_endpoint(client):
    """Test WebSocket stats endpoint"""
    response = await client.get("/ws/stats")
    assert response.status_code == 200
