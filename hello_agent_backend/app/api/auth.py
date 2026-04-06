"""
Authentication API Routes

Provides user registration, login, token refresh, and profile management.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any

from app.core.security import (
    Token,
    TokenData,
    UserCreate,
    UserLogin,
    UserResponse,
    create_access_token,
    create_refresh_token,
    decode_token,
    authenticate_user,
    create_user,
    get_current_active_user,
    create_default_admin
)
from app.core.config import settings


router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
    responses={401: {"description": "Unauthorized"}, 403: {"description": "Forbidden"}}
)


# ============================================================================
# Authentication Endpoints
# ============================================================================

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate):
    """
    Register a new user account

    Creates a new player account with username and password.
    Returns user information (without password).
    """
    try:
        user = await create_user(
            username=user_data.username,
            password=user_data.password,
            email=user_data.email,
            role="player"
        )
        return user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/login", response_model=Token)
async def login(credentials: UserLogin):
    """
    Authenticate user and return JWT tokens

    Validates username/password and returns access + refresh tokens.
    Access token expires in 30 minutes, refresh token in 7 days.
    """
    # Authenticate user
    user = await authenticate_user(credentials.username, credentials.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if user is active
    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled"
        )

    # Create tokens
    token_data = {
        "sub": user["id"],
        "username": user["username"],
        "role": user["role"]
    }

    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=1800  # 30 minutes in seconds
    )


@router.post("/refresh", response_model=Token)
async def refresh_token(refresh_token: str):
    """
    Refresh an access token using a valid refresh token

    Returns new access and refresh tokens.
    """
    try:
        # Decode and validate refresh token
        token_data = decode_token(refresh_token)

        # Verify it's a refresh token
        decoded = decode_token(refresh_token)
        if decoded.user_id is None:
            raise ValueError("Invalid token")

        # Create new tokens
        new_token_data = {
            "sub": decoded.user_id,
            "username": decoded.username,
            "role": decoded.role
        }

        new_access_token = create_access_token(new_token_data)
        new_refresh_token = create_refresh_token(new_token_data)

        return Token(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            token_type="bearer",
            expires_in=1800
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: TokenData = Depends(get_current_active_user)):
    """
    Get current user's profile information

    Requires valid access token in Authorization header.
    """
    # In production, fetch from database
    # For now, return data from token
    return UserResponse(
        id=current_user.user_id or "",
        username=current_user.username or "",
        role=current_user.role or "player"
    )


@router.post("/logout")
async def logout(current_user: TokenData = Depends(get_current_active_user)):
    """
    Logout current user

    In production, add token to blacklist.
    For now, client should just discard the token.
    """
    return {"message": "Successfully logged out"}


# ============================================================================
# Admin Endpoints
# ============================================================================

@router.get("/users", response_model=list[UserResponse])
async def list_users(admin_user: TokenData = Depends(lambda: None)):
    """
    List all users (admin only)

    TODO: Implement proper admin role checking
    """
    # Placeholder - implement with database query
    return []


@router.post("/init-admin")
async def initialize_admin():
    """
    Initialize default admin account

    Only call this once during setup.
    Default credentials: admin / admin123
    CHANGE THIS IN PRODUCTION!
    """
    await create_default_admin()
    return {
        "message": "Admin account created",
        "username": "admin",
        "password": "admin123",
        "warning": "Change default password immediately!"
    }
