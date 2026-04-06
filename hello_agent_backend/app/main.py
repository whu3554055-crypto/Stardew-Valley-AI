"""
Hello-Agent Backend - FastAPI Application

Stardew Valley AI Agent Service with multi-LLM provider support.
Provides intelligent NPC dialogue, story generation, and game assistance.
"""

import json
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import router as api_router
from app.core.config import settings
from app.core.cache import cache
from app.api.websocket import manager
from app.db.models import game_db
from fastapi import WebSocket, WebSocketDisconnect

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(settings.LOG_FILE),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("="*60)
    logger.info("Starting Hello-Agent Backend Service")
    logger.info(f"Host: {settings.HOST}:{settings.PORT}")
    logger.info(f"Log Level: {settings.LOG_LEVEL}")
    logger.info(f"Default LLM Provider: {settings.DEFAULT_LLM_PROVIDER}")
    logger.info("="*60)

    # Initialize Redis cache
    await cache.connect()
    if cache._connected:
        logger.info("Redis cache initialized successfully")
    else:
        logger.warning("Redis cache unavailable, running without caching")

    # Initialize SQLite database
    await game_db.initialize()
    logger.info("SQLite database initialized successfully")

    yield

    # Shutdown
    await cache.disconnect()
    logger.info("Shutting down Hello-Agent Backend Service")


# Create FastAPI application
app = FastAPI(
    title="Hello-Agent Backend",
    description="Stardew Valley AI Agent Service with multi-LLM provider support",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint - service info"""
    return {
        "service": "Hello-Agent Backend",
        "version": "1.0.0",
        "status": "running",
        "llm_providers": ["ollama", "qwen", "gemini"],
        "default_provider": settings.DEFAULT_LLM_PROVIDER
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "hello-agent-backend"
    }


@app.get("/api/info")
async def api_info():
    """API information and available endpoints"""
    return {
        "endpoints": {
            "chat": "/api/v1/chat",
            "npc_dialogue": "/api/v1/npc/dialogue",
            "story_generation": "/api/v1/story/generate",
            "embedding": "/api/v1/embedding",
            "providers": "/api/v1/providers",
            "stats": "/api/v1/stats"
        },
        "documentation": "/docs"
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An unexpected error occurred"
        }
    )


# ============================================================================
# WebSocket Endpoints (Phase 2)
# ============================================================================

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    """
    WebSocket endpoint for real-time communication

    Supports:
    - MCP protocol over WebSocket (JSON-RPC 2.0)
    - Event subscriptions
    - Real-time agent status updates

    Usage:
        const ws = new WebSocket('ws://localhost:8080/ws/player1');
        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            console.log(data);
        };
    """
    await manager.connect(websocket, client_id)

    try:
        while True:
            # Receive messages from client
            data = await websocket.receive_text()
            message = json.loads(data)

            # Handle different message types
            msg_type = message.get("type")

            if message.get("jsonrpc") == "2.0":
                # MCP protocol over WebSocket
                await manager.handle_mcp_over_websocket(websocket, message, client_id)

            elif msg_type == "subscribe":
                # Subscribe to specific events
                event_type = message.get("event")
                logger.info(f"Client {client_id} subscribed to: {event_type}")
                await manager.send_to_client(websocket, {
                    "type": "system",
                    "event": "subscribed",
                    "data": {"event": event_type}
                })

            elif msg_type == "ping":
                # Heartbeat
                await manager.send_to_client(websocket, {
                    "type": "system",
                    "event": "pong",
                    "data": {"timestamp": __import__("time").time()}
                })

            else:
                # Unknown message type
                await manager.send_to_client(websocket, {
                    "type": "error",
                    "message": f"Unknown message type: {msg_type}"
                })

    except WebSocketDisconnect:
        manager.disconnect(websocket, client_id)
    except Exception as e:
        logger.error(f"WebSocket error for {client_id}: {e}")
        manager.disconnect(websocket, client_id)


@app.get("/ws/stats")
async def websocket_stats():
    """Get WebSocket connection statistics"""
    return manager.get_stats()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
