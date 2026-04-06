"""
Rate Limiting Middleware for FastAPI

Provides request throttling to prevent API abuse and ensure fair usage.
Uses sliding window algorithm with Redis backend for distributed rate limiting.
"""

import time
import hashlib
from typing import Optional, Dict, Tuple
from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from app.core.cache import cache


# ============================================================================
# Rate Limit Configuration
# ============================================================================

class RateLimitConfig:
    """Rate limit configuration for different endpoint categories"""

    # Default limits (requests per minute)
    DEFAULT_LIMIT = 60  # 60 requests/minute for general endpoints
    AUTH_LIMIT = 10     # 10 login attempts/minute
    CHAT_LIMIT = 30     # 30 chat messages/minute
    NPC_LIMIT = 20      # 20 NPC interactions/minute
    UPLOAD_LIMIT = 5    # 5 uploads/minute

    # Window size in seconds
    WINDOW_SIZE = 60

    # Ban settings
    BAN_THRESHOLD = 100  # Number of violations before temporary ban
    BAN_DURATION = 3600  # Ban duration in seconds (1 hour)


# ============================================================================
# Rate Limiter
# ============================================================================

class RateLimiter:
    """Sliding window rate limiter with Redis backend"""

    def __init__(self):
        self.config = RateLimitConfig()

    def _get_client_id(self, request: Request) -> str:
        """Extract client identifier from request"""
        # Try to get user ID from JWT token first
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            # Use token hash as identifier for authenticated users
            token_hash = hashlib.sha256(auth_header[7:].encode()).hexdigest()[:16]
            return f"user:{token_hash}"

        # Fallback to IP address for unauthenticated users
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            ip = forwarded.split(",")[0].strip()
        else:
            ip = request.client.host if request.client else "unknown"

        return f"ip:{ip}"

    def _get_rate_limit_key(self, client_id: str, endpoint_category: str) -> str:
        """Generate Redis key for rate limit tracking"""
        window = int(time.time() // self.config.WINDOW_SIZE)
        return f"rate_limit:{client_id}:{endpoint_category}:{window}"

    def _get_ban_key(self, client_id: str) -> str:
        """Generate Redis key for ban tracking"""
        return f"ban:{client_id}"

    async def is_banned(self, client_id: str) -> bool:
        """Check if client is temporarily banned"""
        ban_key = self._get_ban_key(client_id)
        banned = await cache.get(ban_key)
        return banned is not None

    async def ban_client(self, client_id: str, duration: Optional[int] = None):
        """Temporarily ban a client"""
        ban_key = self._get_ban_key(client_id)
        duration = duration or self.config.BAN_DURATION
        await cache.set(ban_key, "banned", expire=duration)

    async def check_rate_limit(
        self,
        request: Request,
        endpoint_category: str = "default",
        custom_limit: Optional[int] = None
    ) -> Tuple[bool, Dict[str, int]]:
        """
        Check if request is within rate limit

        Returns:
            Tuple of (is_allowed, rate_limit_info)
        """
        client_id = self._get_client_id(request)

        # Check if client is banned
        if await self.is_banned(client_id):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. You have been temporarily banned.",
                headers={"Retry-After": str(self.config.BAN_DURATION)}
            )

        # Get rate limit for category
        limit = custom_limit or getattr(self.config, f"{endpoint_category.upper()}_LIMIT", self.config.DEFAULT_LIMIT)

        # Get current window key
        rate_key = self._get_rate_limit_key(client_id, endpoint_category)

        # Get current count
        current_count = await cache.get(rate_key)
        if current_count is None:
            current_count = 0

        # Calculate remaining requests
        remaining = max(0, limit - current_count)

        # Check if limit exceeded
        if current_count >= limit:
            # Increment violation counter
            violation_key = f"violations:{client_id}"
            violations = await cache.get(violation_key) or 0
            violations += 1
            await cache.set(violation_key, violations, expire=3600)

            # Ban if too many violations
            if violations >= self.config.BAN_THRESHOLD:
                await self.ban_client(client_id)
                await cache.delete(violation_key)

            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Maximum {limit} requests per minute.",
                headers={
                    "Retry-After": str(self.config.WINDOW_SIZE),
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(int(time.time()) + self.config.WINDOW_SIZE)
                }
            )

        # Increment counter
        await cache.set(rate_key, current_count + 1, expire=self.config.WINDOW_SIZE * 2)

        # Reset violation counter on successful request
        violation_key = f"violations:{client_id}"
        await cache.delete(violation_key)

        # Return rate limit info
        rate_info = {
            "limit": limit,
            "remaining": remaining - 1,
            "reset": int(time.time()) + self.config.WINDOW_SIZE
        }

        return True, rate_info


# ============================================================================
# Middleware
# ============================================================================

class RateLimitMiddleware(BaseHTTPMiddleware):
    """FastAPI middleware for automatic rate limiting"""

    def __init__(self, app, limiter: Optional[RateLimiter] = None):
        super().__init__(app)
        self.limiter = limiter or RateLimiter()

        # Map endpoint patterns to categories
        self.endpoint_categories = {
            "/api/v1/auth/login": "auth",
            "/api/v1/auth/register": "auth",
            "/api/v1/chat": "chat",
            "/api/v1/npc": "npc",
            "/api/v1/upload": "upload",
        }

    async def dispatch(self, request: Request, call_next):
        # Skip rate limiting for certain endpoints
        path = request.url.path

        if path in ["/health", "/metrics", "/", "/docs", "/openapi.json"]:
            return await call_next(request)

        # Determine endpoint category
        category = "default"
        for pattern, cat in self.endpoint_categories.items():
            if path.startswith(pattern):
                category = cat
                break

        try:
            # Check rate limit
            is_allowed, rate_info = await self.limiter.check_rate_limit(request, category)

            # Process request
            response = await call_next(request)

            # Add rate limit headers to response
            response.headers["X-RateLimit-Limit"] = str(rate_info["limit"])
            response.headers["X-RateLimit-Remaining"] = str(rate_info["remaining"])
            response.headers["X-RateLimit-Reset"] = str(rate_info["reset"])

            return response

        except HTTPException:
            raise
        except Exception as e:
            # If Redis is unavailable, allow request but log warning
            print(f"Rate limiter error (allowing request): {e}")
            return await call_next(request)


# ============================================================================
# Dependency for Manual Rate Limiting
# ============================================================================

rate_limiter = RateLimiter()


async def require_rate_limit(
    request: Request,
    category: str = "default",
    limit: Optional[int] = None
):
    """
    Dependency for manual rate limiting in route handlers

    Usage:
        @router.post("/special-endpoint")
        async def special_endpoint(
            request: Request,
            _: None = Depends(lambda r: require_rate_limit(r, "chat"))
        ):
            ...
    """
    return await rate_limiter.check_rate_limit(request, category, limit)
