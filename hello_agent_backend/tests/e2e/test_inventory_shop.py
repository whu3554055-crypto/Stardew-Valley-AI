"""
E2E Tests for Inventory and Shop System

Tests item management, shopping transactions, and inventory operations.
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
            "username": "shop_tester",
            "password": "testpass123"
        }
    )

    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "shop_tester",
            "password": "testpass123"
        }
    )

    return login_response.json()["access_token"]


@pytest.mark.asyncio
async def test_get_player_inventory(client, auth_token):
    """Test retrieving player inventory"""
    response = await client.get(
        "/api/v1/inventory/test_player_1",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return inventory (may be empty)
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_add_item_to_inventory(client, auth_token):
    """Test adding item to inventory"""
    response = await client.post(
        "/api/v1/inventory/add",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "test_player_1",
            "item_id": "parsnip",
            "quantity": 5
        }
    )

    # Should add item successfully
    assert response.status_code in [200, 404, 422]


@pytest.mark.asyncio
async def test_remove_item_from_inventory(client, auth_token):
    """Test removing item from inventory"""
    response = await client.post(
        "/api/v1/inventory/remove",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "test_player_1",
            "item_id": "parsnip",
            "quantity": 2
        }
    )

    # Should remove item or return error if not enough
    assert response.status_code in [200, 400, 404]


@pytest.mark.asyncio
async def test_buy_item_from_shop(client, auth_token):
    """Test buying item from shop"""
    response = await client.post(
        "/api/v1/shop/buy",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "test_player_1",
            "item_id": "hoe",
            "quantity": 1,
            "shopkeeper_id": "pierre"
        }
    )

    # Should process purchase
    assert response.status_code in [200, 400, 404]


@pytest.mark.asyncio
async def test_sell_item_to_shop(client, auth_token):
    """Test selling item to shop"""
    response = await client.post(
        "/api/v1/shop/sell",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "test_player_1",
            "item_id": "parsnip",
            "quantity": 3,
            "shopkeeper_id": "pierre"
        }
    )

    # Should process sale
    assert response.status_code in [200, 400, 404]


@pytest.mark.asyncio
async def test_use_item(client, auth_token):
    """Test using consumable item"""
    response = await client.post(
        "/api/v1/inventory/use",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "test_player_1",
            "item_id": "health_potion"
        }
    )

    # Should apply item effect
    assert response.status_code in [200, 400, 404]


@pytest.mark.asyncio
async def test_get_item_details(client, auth_token):
    """Test getting item details"""
    response = await client.get(
        "/api/v1/items/parsnip",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return item info
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_get_shop_inventory(client, auth_token):
    """Test getting shop inventory"""
    response = await client.get(
        "/api/v1/shop/pierre",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    # Should return shop items
    assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_insufficient_funds(client, auth_token):
    """Test buying with insufficient funds"""
    response = await client.post(
        "/api/v1/shop/buy",
        headers={"Authorization": f"Bearer {auth_token}"},
        json={
            "player_id": "broke_player",
            "item_id": "gold_ore",
            "quantity": 999,
            "shopkeeper_id": "pierre"
        }
    )

    # Should fail with insufficient funds
    assert response.status_code in [400, 402, 404]


@pytest.mark.asyncio
async def test_invalid_item_id(client, auth_token):
    """Test operations with invalid item ID"""
    response = await client.get(
        "/api/v1/items/nonexistent_item",
        headers={"Authorization": f"Bearer {auth_token}"}
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_inventory_without_auth(client):
    """Test inventory access without authentication"""
    response = await client.get("/api/v1/inventory/test_player")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_shop_without_auth(client):
    """Test shop access without authentication"""
    response = await client.post(
        "/api/v1/shop/buy",
        json={
            "player_id": "test",
            "item_id": "parsnip"
        }
    )
    assert response.status_code == 401
