"""
JWT Authentication & Authorization for Hello-Agent Backend

Provides secure token-based authentication with role-based access control.
"""

from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel

from app.core.config import settings


# ============================================================================
# Configuration
# ============================================================================

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT configuration
SECRET_KEY = settings.SECRET_KEY or "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ============================================================================
# Models
# ============================================================================

class Token(BaseModel):
    """Authentication token response"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenData(BaseModel):
    """Decoded token data"""
    user_id: Optional[str] = None
    username: Optional[str] = None
    role: Optional[str] = "player"


class UserCreate(BaseModel):
    """User registration data"""
    username: str
    password: str
    email: Optional[str] = None


class UserLogin(BaseModel):
    """User login data"""
    username: str
    password: str


class UserResponse(BaseModel):
    """User information response"""
    id: str
    username: str
    email: Optional[str] = None
    role: str
    created_at: str


# ============================================================================
# Password Utilities
# ============================================================================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)


# ============================================================================
# JWT Token Management
# ============================================================================

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access"
    })

    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: Dict[str, Any]) -> str:
    """Create a JWT refresh token"""
    to_encode = data.copy()

    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)

    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "refresh"
    })

    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> TokenData:
    """Decode and validate a JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        user_id: str = payload.get("sub")
        username: str = payload.get("username")
        role: str = payload.get("role", "player")
        token_type: str = payload.get("type")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing user ID",
                headers={"WWW-Authenticate": "Bearer"},
            )

        return TokenData(user_id=user_id, username=username, role=role)

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ============================================================================
# Authentication Dependencies
# ============================================================================

async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenData:
    """Get current authenticated user from token"""
    return decode_token(token)


async def get_current_active_user(current_user: TokenData = Depends(get_current_user)) -> TokenData:
    """Verify user is active (placeholder for future user status check)"""
    return current_user


def require_role(required_role: str):
    """Dependency factory for role-based access control"""
    async def role_checker(current_user: TokenData = Depends(get_current_user)):
        # Admin can access everything
        if current_user.role == "admin":
            return current_user

        # Check specific role
        if current_user.role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required role: {required_role}"
            )

        return current_user
    return role_checker


# ============================================================================
# User Management (In-memory for now, should use database)
# ============================================================================

# Temporary user store - replace with database in production
_users_db: Dict[str, Dict[str, Any]] = {}


async def authenticate_user(username: str, password: str) -> Optional[Dict]:
    """Authenticate user credentials"""
    user = _users_db.get(username)

    if not user:
        return None

    if not verify_password(password, user["hashed_password"]):
        return None

    return user


async def create_user(username: str, password: str, email: Optional[str] = None, role: str = "player") -> Dict:
    """Create a new user"""
    if username in _users_db:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already registered"
        )

    hashed_password = get_password_hash(password)
    user_id = f"user_{len(_users_db) + 1:04d}"

    user_data = {
        "id": user_id,
        "username": username,
        "email": email,
        "hashed_password": hashed_password,
        "role": role,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_active": True
    }

    _users_db[username] = user_data

    return {
        "id": user_id,
        "username": username,
        "email": email,
        "role": role,
        "created_at": user_data["created_at"]
    }


async def create_default_admin():
    """Create default admin user if not exists"""
    if "admin" not in _users_db:
        await create_user(
            username="admin",
            password="admin123",  # Change this in production!
            email="admin@cybertown.game",
            role="admin"
        )
