"""
Hello-Agent Backend - FastAPI Application

Stardew Valley AI Agent Service with multi-LLM provider support.
Provides intelligent NPC dialogue, story generation, and game assistance.
"""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import router as api_router
from app.core.config import settings
from app.core.cache import cache

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

    yield

    # Shutdown
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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
