"""
API Routes for LLM Services

Provides REST endpoints for chat, NPC dialogue, story generation, and embeddings.
Integrates with the multi-LLM router for intelligent provider selection.
"""

import logging
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

from llm.providers.base import LLMMessage
from llm.router import LLMRouter
from app.services.memory_store import VectorMemoryStore
from app.core.mcp_protocol import game_mcp, MCPRequest

logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize LLM Router (singleton)
llm_router = LLMRouter("config/llm_config.json")

# Initialize Memory Store (singleton)
memory_store = VectorMemoryStore("data/vector_store")


# ============================================================================
# Request/Response Models
# ============================================================================

class ChatRequest(BaseModel):
    """Chat completion request"""
    messages: List[Dict[str, str]] = Field(..., description="Message list")
    task_type: str = Field(default="general", description="Task type for routing")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(default=None, ge=1)
    force_provider: Optional[str] = Field(default=None, description="Force specific provider")


class ChatResponse(BaseModel):
    """Chat completion response"""
    content: str
    model: str
    provider: str
    usage: Dict[str, int]
    cost: float
    latency_ms: float


class NPCDialogueRequest(BaseModel):
    """NPC dialogue request"""
    npc_id: str = Field(..., description="NPC identifier")
    npc_name: str = Field(..., description="NPC display name")
    personality: Dict[str, Any] = Field(default_factory=dict, description="Personality traits")
    context: Dict[str, Any] = Field(default_factory=dict, description="Game context")
    player_message: str = Field(..., description="Player's message")
    conversation_history: List[Dict[str, str]] = Field(default_factory=list, description="Previous messages")


class NPCDialogueResponse(BaseModel):
    """NPC dialogue response"""
    npc_id: str
    dialogue: str
    emotion: Optional[str] = None
    provider: str
    latency_ms: float


class StoryGenerationRequest(BaseModel):
    """Story generation request"""
    prompt: str = Field(..., description="Story prompt or scenario")
    genre: str = Field(default="fantasy", description="Story genre")
    length: str = Field(default="medium", description="short/medium/long")
    style: str = Field(default="narrative", description="Writing style")


class StoryResponse(BaseModel):
    """Generated story response"""
    story: str
    genre: str
    provider: str
    word_count: int
    latency_ms: float


class EmbeddingRequest(BaseModel):
    """Embedding generation request"""
    texts: List[str] = Field(..., description="Texts to embed")
    force_provider: Optional[str] = Field(default=None)


class EmbeddingResponse(BaseModel):
    """Embedding response"""
    embeddings: List[List[float]]
    model: str
    provider: str
    total_tokens: int


# ============================================================================
# Chat Endpoints
# ============================================================================

@router.post("/chat", response_model=ChatResponse)
async def chat_completion(request: ChatRequest):
    """
    General chat completion with intelligent provider routing.

    - **messages**: List of conversation messages
    - **task_type**: Task type for smart routing (npc_dialogue, story_generation, etc.)
    - **temperature**: Creativity level (0.0-2.0)
    - **force_provider**: Override automatic routing
    """
    try:
        # Convert messages to LLMMessage format
        messages = [
            LLMMessage(role=msg["role"], content=msg["content"])
            for msg in request.messages
        ]

        # Call LLM router
        response = await llm_router.chat_completion(
            messages=messages,
            task_type=request.task_type,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            force_provider=request.force_provider
        )

        return ChatResponse(
            content=response.content,
            model=response.model,
            provider=response.provider,
            usage=response.usage,
            cost=response.cost,
            latency_ms=response.latency_ms
        )

    except Exception as e:
        logger.error(f"Chat completion failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# NPC Dialogue Endpoint
# ============================================================================

@router.post("/npc/dialogue", response_model=NPCDialogueResponse)
async def generate_npc_dialogue(request: NPCDialogueRequest):
    """
    Generate NPC dialogue with personality, context, and memory awareness.

    Features:
    1. Retrieves relevant memories via semantic search
    2. Injects memories into LLM prompt for context-aware responses
    3. Stores new conversation as memory after generation
    4. Routes to optimal LLM provider based on task complexity
    """
    try:
        # Step 1: Retrieve relevant memories from vector store
        relevant_memories = []
        try:
            relevant_memories = await memory_store.search_similar(
                query=request.player_message,
                npc_id=request.npc_id,
                limit=3
            )
            logger.info(f"Retrieved {len(relevant_memories)} memories for {request.npc_id}")
        except Exception as mem_err:
            logger.warning(f"Memory retrieval failed: {mem_err}, continuing without memories")

        # Step 2: Build system prompt with NPC personality and memories
        personality_str = ", ".join(
            f"{k}: {v}" for k, v in request.personality.items()
        )

        system_prompt = (
            f"You are {request.npc_name} from Stardew Valley. "
            f"Your personality: {personality_str}. "
            f"Stay in character and respond naturally to the player."
        )

        # Add relevant memories to context if available
        if relevant_memories:
            system_prompt += "\n\nRelevant memories about the player:\n"
            for i, mem in enumerate(relevant_memories, 1):
                system_prompt += f"- {mem.content}\n"
            logger.debug(f"Added {len(relevant_memories)} memories to prompt context")

        # Step 3: Build message history
        messages = [LLMMessage(role="system", content=system_prompt)]

        # Add conversation history
        for msg in request.conversation_history:
            messages.append(LLMMessage(role=msg["role"], content=msg["content"]))

        # Add current player message
        messages.append(LLMMessage(role="user", content=request.player_message))

        # Step 4: Generate dialogue using LLM router
        response = await llm_router.chat_completion(
            messages=messages,
            task_type="npc_dialogue",
            temperature=0.7,
            max_tokens=150
        )

        # Step 5: Store new conversation as memory
        try:
            memory_content = f"Player said: '{request.player_message}'. I responded: '{response.content}'"
            await memory_store.add_memory(
                npc_id=request.npc_id,
                content=memory_content,
                metadata={
                    "type": "conversation",
                    "day": request.context.get("day", 0),
                    "season": request.context.get("season", "spring"),
                    "player_message": request.player_message,
                    "npc_response": response.content
                }
            )
            logger.info(f"Stored new memory for {request.npc_id}")
        except Exception as mem_err:
            logger.warning(f"Failed to store memory: {mem_err}")

        # Step 6: Detect emotion from response
        emotion = _detect_emotion(response.content)

        return NPCDialogueResponse(
            npc_id=request.npc_id,
            dialogue=response.content,
            emotion=emotion,
            provider=response.provider,
            latency_ms=response.latency_ms
        )

    except Exception as e:
        logger.error(f"NPC dialogue generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Story Generation Endpoint
# ============================================================================

@router.post("/story/generate", response_model=StoryResponse)
async def generate_story(request: StoryGenerationRequest):
    """
    Generate creative stories for game narratives.

    Uses cloud providers (Qwen/Gemini) for higher quality creative writing.
    """
    try:
        # Build story prompt
        length_map = {
            "short": "100-200 words",
            "medium": "300-500 words",
            "long": "600-1000 words"
        }

        prompt = f"""
        Write a {request.genre} story with the following scenario:
        {request.prompt}

        Requirements:
        - Length: {length_map.get(request.length, "300-500 words")}
        - Style: {request.style}
        - Make it engaging and suitable for a farming simulation game
        - Include character development and plot progression
        """

        messages = [
            LLMMessage(role="system", content="You are a talented storyteller specializing in interactive narratives."),
            LLMMessage(role="user", content=prompt)
        ]

        response = await llm_router.chat_completion(
            messages=messages,
            task_type="story_generation",
            temperature=0.9,
            max_tokens=1000
        )

        word_count = len(response.content.split())

        return StoryResponse(
            story=response.content,
            genre=request.genre,
            provider=response.provider,
            word_count=word_count,
            latency_ms=response.latency_ms
        )

    except Exception as e:
        logger.error(f"Story generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Embedding Endpoint
# ============================================================================

@router.post("/embedding", response_model=EmbeddingResponse)
async def generate_embedding(request: EmbeddingRequest):
    """
    Generate text embeddings for semantic search and memory retrieval.

    Prefers local Ollama for cost efficiency.
    """
    try:
        response = await llm_router.get_embedding(
            texts=request.texts,
            force_provider=request.force_provider
        )

        return EmbeddingResponse(
            embeddings=response.embeddings,
            model=response.model,
            provider=response.provider,
            total_tokens=response.usage.get("total_tokens", 0)
        )

    except Exception as e:
        logger.error(f"Embedding generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Provider Management Endpoints
# ============================================================================

@router.get("/providers")
async def list_providers():
    """List all configured LLM providers and their status"""
    try:
        availability = await llm_router.check_all_providers()
        info = llm_router.get_info()

        providers = []
        for name, provider_info in info["providers"].items():
            providers.append({
                "name": name,
                "available": availability.get(name, False),
                **provider_info
            })

        return {
            "providers": providers,
            "default": llm_router.config.get("providers", {}).get("ollama", {}).get("model", "unknown"),
            "routing_mode": info["routing_mode"]
        }

    except Exception as e:
        logger.error(f"Failed to list providers: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_statistics():
    """Get usage statistics and performance metrics"""
    try:
        stats = llm_router.get_provider_stats()
        budget = llm_router.get_budget_info()

        return {
            "providers": stats,
            "budget": budget,
            "timestamp": __import__("time").time()
        }

    except Exception as e:
        logger.error(f"Failed to get statistics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reset-budget")
async def reset_budget():
    """Reset daily budget counter (admin operation)"""
    try:
        llm_router.reset_daily_cost()
        return {"status": "success", "message": "Budget counter reset"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# MCP (Model Context Protocol) Endpoints
# ============================================================================

@router.get("/mcp/tools")
async def list_mcp_tools():
    """List all registered MCP tools"""
    return {
        "tools": game_mcp.list_tools(),
        "stats": game_mcp.get_stats()
    }


@router.post("/mcp/call")
async def call_mcp_tool(request: dict):
    """
    Call an MCP tool (JSON-RPC 2.0 format)
    
    Request format:
    {
        "jsonrpc": "2.0",
        "id": "req-123",
        "method": "tool_name",
        "params": {...}
    }
    
    Response format:
    {
        "jsonrpc": "2.0",
        "id": "req-123",
        "result": {...},
        "error": null
    }
    """
    try:
        response = await game_mcp.handle_request(request)
        return response
    
    except Exception as e:
        logger.error(f"MCP tool call failed: {e}")
        return {
            "jsonrpc": "2.0",
            "id": request.get("id", "unknown"),
            "result": None,
            "error": {
                "code": -32000,
                "message": str(e)
            }
        }


@router.get("/mcp/stats")
async def get_mcp_stats():
    """Get MCP server statistics"""
    return game_mcp.get_stats()


# ============================================================================
# Memory Management Endpoints
# ============================================================================

@router.get("/memory/stats")
async def get_memory_stats():
    """Get memory store statistics"""
    try:
        stats = await memory_store.get_memory_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/memory/{npc_id}/recent")
async def get_recent_memories(npc_id: str, limit: int = 10):
    """Get recent memories for an NPC"""
    try:
        memories = await memory_store.get_recent_memories(npc_id, limit=limit)
        return {
            "npc_id": npc_id,
            "memories": [mem.to_dict() for mem in memories]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/memory/{npc_id}")
async def clear_npc_memories(npc_id: str):
    """Clear all memories for an NPC (admin operation)"""
    try:
        await memory_store.clear_all_memories(npc_id)
        return {"status": "success", "message": f"Cleared memories for {npc_id}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Helper Functions
# ============================================================================

def _detect_emotion(text: str) -> Optional[str]:
    """
    Simple emotion detection from text.
    Can be replaced with more sophisticated analysis.
    """
    text_lower = text.lower()

    emotion_keywords = {
        "happy": ["happy", "glad", "joy", "wonderful", "great", "excellent"],
        "sad": ["sad", "unfortunately", "sorry", "regret", "miss"],
        "angry": ["angry", "frustrated", "annoyed", "upset"],
        "excited": ["excited", "amazing", "fantastic", "love", "can't wait"],
        "neutral": []
    }

    for emotion, keywords in emotion_keywords.items():
        if any(keyword in text_lower for keyword in keywords):
            return emotion

    return "neutral"
