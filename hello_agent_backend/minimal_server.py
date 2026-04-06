"""
Minimal FastAPI server for Cyber Town development
Provides essential endpoints without heavy dependencies (lancedb, langchain, etc.)
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import time
import random

app = FastAPI(
    title="Cyber Town API",
    description="Minimal backend for Godot client development",
    version="1.0.0"
)

# CORS for Godot client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# NPC Dialogue Templates
NPC_TEMPLATES = {
    "pierre": {
        "name": "Pierre",
        "responses": [
            "欢迎来到我的杂货店！今天的种子特价哦。",
            " farming是个好职业，勤劳就能致富！",
            "你需要什么？种子、工具，还是其他东西？",
            "天气不错，适合在田里干活。",
            "我女儿Abigail最近又在到处冒险了..."
        ]
    },
    "abigail": {
        "name": "Abigail",
        "responses": [
            "嘿！你也喜欢冒险吗？一起去矿洞吧！",
            "我刚发现了一个神秘的地方，超酷的！",
            "爸爸总是担心我，但我已经长大了。",
            "你喜欢玩游戏吗？我最近在玩一款新游戏。",
            "紫色的东西最棒了！比如我的头发~"
        ]
    },
    "lewis": {
        "name": "Lewis镇长",
        "responses": [
            "欢迎来到星露谷小镇！这里是最美好的地方。",
            "作为镇长，我要确保每个人都过得开心。",
            "Marnie今天做了美味的蓝莓派...",
            "小镇需要更多的发展，你有什么建议吗？",
            "记住，社区的力量是最重要的！"
        ]
    }
}

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "cyber-town-api",
        "version": "1.0.0",
        "timestamp": time.time()
    }

@app.post("/api/v1/npc/dialogue")
async def npc_dialogue(request: Request):
    """Generate NPC dialogue response"""
    try:
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    npc_id = data.get("npc_id", "").lower()
    npc_name = data.get("npc_name", "NPC")

    # Use template if available
    if npc_id in NPC_TEMPLATES:
        template = NPC_TEMPLATES[npc_id]
        response = random.choice(template["responses"])
    else:
        # Generic fallback
        response = f"你好！我是{npc_name}。很高兴见到你！"

    # Determine emotion based on response content
    emotion = "neutral"
    if any(word in response for word in ["高兴", "棒", "好", "喜欢"]):
        emotion = "happy"
    elif any(word in response for word in ["担心", "烦恼", "可惜"]):
        emotion = "sad"

    return {
        "dialogue": response,
        "emotion": emotion,
        "npc_id": npc_id,
        "npc_name": npc_name,
        "timestamp": time.time()
    }

@app.post("/api/v1/chat")
async def chat_completion(request: Request):
    """General chat completion endpoint"""
    try:
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    messages = data.get("messages", [])
    last_message = messages[-1] if messages else {"role": "user", "content": ""}

    return {
        "response": f"我收到了你的消息：{last_message.get('content', '')}",
        "task_type": data.get("task_type", "general"),
        "metadata": {
            "message_count": len(messages),
            "temperature": data.get("temperature", 0.7)
        }
    }

@app.get("/api/v1/game/state")
def get_game_state():
    """Get current game state (placeholder)"""
    return {
        "season": "spring",
        "day": 1,
        "year": 1,
        "time": 8.0,
        "weather": "sunny"
    }

@app.post("/api/v1/game/save")
async def save_game(request: Request):
    """Save game state (placeholder)"""
    return {"status": "success", "message": "Game saved"}

@app.post("/api/v1/game/load")
async def load_game(request: Request):
    """Load game state (placeholder)"""
    return {
        "status": "success",
        "game_state": {
            "season": "spring",
            "day": 1,
            "time": 8.0
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8080)
