"""
E2E Tests for Authentication Flow

Tests complete user registration, login, and token management workflows.
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


@pytest.mark.asyncio
async def test_register_new_user(client):
    """Test user registration"""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "test_player",
            "password": "securepass123",
            "email": "test@example.com"
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "test_player"
    assert data["email"] == "test@example.com"
    assert data["role"] == "player"
    assert "id" in data


@pytest.mark.asyncio
async def test_register_duplicate_user(client):
    """Test registration with duplicate username"""
    # First registration
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "duplicate_user",
            "password": "pass123"
        }
    )

    # Second registration with same username
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "duplicate_user",
            "password": "pass456"
        }
    )

    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client):
    """Test successful login"""
    # Register first
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "login_test",
            "password": "testpass123"
        }
    )

    # Login
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "login_test",
            "password": "testpass123"
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] == 1800


@pytest.mark.asyncio
async def test_login_wrong_password(client):
    """Test login with wrong password"""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "nonexistent",
            "password": "wrongpass"
        }
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_current_user_profile(client):
    """Test getting current user profile with token"""
    # Register and login
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "profile_test",
            "password": "testpass123"
        }
    )

    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "profile_test",
            "password": "testpass123"
        }
    )

    token = login_response.json()["access_token"]

    # Get profile
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "profile_test"
    assert data["role"] == "player"


@pytest.mark.asyncio
async def test_refresh_token(client):
    """Test token refresh"""
    # Register and login
    await client.post(
        "/api/v1/auth/register",
        json={
            "username": "refresh_test",
            "password": "testpass123"
        }
    )

    login_response = await client.post(
        "/api/v1/auth/login",
        json={
            "username": "refresh_test",
            "password": "testpass123"
        }
    )

    refresh_token = login_response.json()["refresh_token"]

    # Refresh token
    response = await client.post(
        "/api/v1/auth/refresh",
        params={"refresh_token": refresh_token}
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_access_protected_endpoint_without_token(client):
    """Test accessing protected endpoint without authentication"""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_access_with_invalid_token(client):
    """Test accessing endpoint with invalid token"""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token_here"}
    )
    assert response.status_code == 401
