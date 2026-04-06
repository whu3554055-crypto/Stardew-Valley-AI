# Backend API Integration Guide

## Current Status

The Godot client has full API integration code ready in `api_client.gd`. The backend requires additional dependencies that need Rust toolchain (lancedb). This document provides alternatives.

## Option 1: Run Backend with Full Dependencies (Recommended for Production)

### Prerequisites
1. Install Rust: https://rustup.rs/
2. Install Python dependencies:
```bash
cd hello_agent_backend
pip install -r requirements.txt
```

### Start Backend
```bash
cd hello_agent_backend
set PYTHONPATH=.
python -m uvicorn app.main:app --host 127.0.0.1 --port 8080
```

### Verify
```bash
curl http://127.0.0.1:8080/health
```

## Option 2: Lightweight Backend (Development Only)

Create a minimal FastAPI server without lancedb/langchain:

```python
# hello_agent_backend/minimal_server.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Cyber Town API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok", "service": "cyber-town-api"}

@app.post("/api/v1/npc/dialogue")
def npc_dialogue(request: dict):
    """Fallback dialogue endpoint"""
    npc_name = request.get("npc_name", "NPC")
    return {
        "dialogue": f"Hello! I'm {npc_name}. How can I help you today?",
        "emotion": "neutral",
        "timestamp": "2026-04-06T14:00:00"
    }

@app.post("/api/v1/chat")
def chat_completion(request: dict):
    """Fallback chat endpoint"""
    return {
        "response": "I understand. Tell me more!",
        "metadata": {}
    }
```

Run with:
```bash
cd hello_agent_backend
pip install fastapi uvicorn
python -m uvicorn minimal_server:app --host 127.0.0.1 --port 8080
```

## Godot Client Configuration

The Godot client's `APIClient` node is already configured to connect to `http://localhost:8080/api/v1`.

### Fallback Behavior
When the backend is unavailable, the dialogue system automatically falls back to local NPC dialogue configurations defined in `dialogue_system.gd`.

### Testing API Connection
In Godot, add this debug code to test connectivity:

```gdscript
# In any script
func _ready():
    if has_node("/root/Main/APIClient"):
        var result = await $"/root/Main/APIClient".health_check()
        print("Backend status: ", result)
```

## Error Handling

The `api_client.gd` includes comprehensive error handling:
- HTTP connection failures return error dictionaries
- JSON parse errors are caught and reported
- Dialogue system gracefully degrades to local config on failure

## Next Steps for Full Backend

1. Install Rust toolchain
2. Install all requirements: `pip install -r requirements.txt`
3. Configure `.env` file with LLM API keys
4. Initialize database: Create `hello_agent_backend/data/` directory
5. Start server and verify health endpoint
