# Quick Reference Card - hello-agent Cyber Town

## 🚀 Common Commands

### Local Development

```bash
# Start entire stack (backend + redis)
docker-compose up

# Start with monitoring
docker-compose --profile monitoring up

# View logs
docker-compose logs -f backend

# Restart backend only
docker-compose restart backend

# Stop everything
docker-compose down
```

### Testing

```bash
# Run all tests
cd hello_agent_backend
python -m pytest tests/ -v

# Run only unit tests (fast)
python -m pytest tests/ -v -m "not integration"

# Run specific test file
python -m pytest tests/test_cache.py -v

# Run with coverage
python -m pytest tests/ --cov=app --cov-report=html

# View HTML coverage report
open htmlcov/index.html  # Mac/Linux
start htmlcov/index.html  # Windows
```

### Godot Integration

```gdscript
# In your Godot scene _ready():
var ai = get_node("/root/AIAgentManager")

# Setup WebSocket
ai.setup_websocket("player1")
ai.subscribe_to_events(["npc_dialogue", "agent_action"])

# Start autonomous NPC
ai.start_autonomous_agent("villager_001", interval=10.0)

# Check cache stats
var stats = await ai.get_cache_stats()
print("Hit rate: ", stats.hit_rate)
```

### Backend API

```bash
# Health check
curl http://localhost:8080/api/v1/health

# Get NPC info
curl http://localhost:8080/api/v1/npcs/villager_001

# Start agent
curl -X POST http://localhost:8080/api/v1/agent/villager_001/start \
  -H "Content-Type: application/json" \
  -d '{"interval": 10.0}'

# Cache stats
curl http://localhost:8080/api/v1/cache/stats

# WebSocket connection
wscat -c ws://localhost:8080/ws/player1
```

### Docker Operations

```bash
# Build custom image
docker build -t hello-agent-backend ./hello_agent_backend

# Run single container
docker run -p 8080:8080 hello-agent-backend

# Enter running container
docker exec -it hello-agent-backend bash

# View container logs
docker logs hello-agent-backend

# Clean up volumes
docker-compose down -v
```

### Git Workflow

```bash
# Commit changes
git add .
git commit -m "feat: add new feature"

# Push to GitHub
git push origin main

# View CI/CD status
gh run list  # GitHub CLI
```

---

## 📁 Project Structure

```
stardew_valley/
├── autoload/                    # Godot singletons
│   ├── websocket_client.gd     # WebSocket client (NEW)
│   └── ai_agent_manager.gd     # AI manager (ENHANCED)
├── hello_agent_backend/
│   ├── app/
│   │   ├── core/
│   │   │   └── cache.py        # Redis cache manager
│   │   ├── services/
│   │   │   ├── agent_engine.py # Autonomous agents
│   │   │   └── memory_store.py # Vector memory
│   │   ├── api/
│   │   │   └── websocket.py    # WebSocket handler
│   │   └── db/
│   │       ├── models.py       # SQLite models
│   │       └── repository.py   # Data access
│   ├── tests/
│   │   ├── test_cache.py       # Cache tests (NEW)
│   │   ├── test_agent_engine.py# Agent tests (NEW)
│   │   ├── test_websocket.py   # WS tests (NEW)
│   │   └── test_database.py    # DB tests (NEW)
│   └── Dockerfile
├── .github/workflows/
│   └── ci.yml                  # CI/CD pipeline (ENHANCED)
├── docker-compose.yml          # Docker orchestration (NEW)
├── GODOT_INTEGRATION_GUIDE.md  # Godot docs (NEW)
└── IMPLEMENTATION_SUMMARY.md   # This summary (NEW)
```

---

## 🔧 Environment Variables

Create `.env` file in project root:

```bash
# LLM Provider
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
QWEN_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here

# Backend
LOG_LEVEL=info
HOST=0.0.0.0
PORT=8080

# Database
DATABASE_URL=sqlite+aiosqlite:///data/game.db

# Redis
REDIS_URL=redis://localhost:6379

# Monitoring
GRAFANA_PASSWORD=admin
```

---

## 🐛 Troubleshooting

### WebSocket Connection Fails
```bash
# Check if backend is running
docker ps | grep backend

# Check backend logs
docker logs hello-agent-backend

# Test WebSocket endpoint
wscat -c ws://localhost:8080/ws/test
```

### Redis Connection Issues
```bash
# Check Redis is running
docker ps | grep redis

# Test Redis connection
docker exec -it hello-agent-redis redis-cli ping

# View Redis memory usage
docker exec -it hello-agent-redis redis-cli INFO memory
```

### Tests Failing
```bash
# Run single test to see error
python -m pytest tests/test_cache.py::TestCacheOperations::test_set_and_get -v

# Check Python version
python --version  # Should be 3.11+

# Reinstall dependencies
pip install -r requirements.txt
```

### Docker Build Fails
```bash
# Clear Docker cache
docker system prune -a

# Build without cache
docker-compose build --no-cache

# Check Docker daemon
docker info
```

---

## 📊 Monitoring

### Prometheus Metrics
```bash
# Access Prometheus
open http://localhost:9090

# Query example
rate(http_requests_total[5m])
```

### Grafana Dashboards
```bash
# Access Grafana
open http://localhost:3000
# Username: admin
# Password: (from .env or 'admin')
```

### Redis Monitoring
```bash
# Real-time Redis stats
docker exec -it hello-agent-redis redis-cli MONITOR

# Cache hit/miss ratio
docker exec -it hello-agent-redis redis-cli INFO stats
```

---

## 🎯 Key Features Checklist

### Phase 1: Core Backend ✅
- [x] Multi-LLM routing (Ollama, Qwen, Gemini)
- [x] Redis caching layer
- [x] Vector memory with LanceDB
- [x] Autonomous agent decision engine
- [x] REST API with FastAPI
- [x] SQLite database persistence

### Phase 2: Real-Time Communication ✅
- [x] WebSocket support
- [x] MCP protocol over WebSocket
- [x] Event subscription system
- [x] Connection pool management
- [x] Game state persistence

### Phase 3: Frontend Integration ✅
- [x] Godot WebSocket client
- [x] AIAgentManager enhancements
- [x] Event-driven architecture
- [x] Cache management from Godot
- [x] Comprehensive documentation

### DevOps & Quality ✅
- [x] Unit test suite (135+ tests)
- [x] CI/CD pipeline
- [x] Docker containerization
- [x] Security scanning
- [x] Performance benchmarks
- [x] Monitoring setup

---

## 📞 Support

- **Documentation**: See `GODOT_INTEGRATION_GUIDE.md`
- **Tests**: See `hello_agent_backend/tests/TEST_SUMMARY.md`
- **Roadmap**: See `NEXT_STEPS_ROADMAP.md`
- **Issues**: https://github.com/whu3554055-crypto/stardew_valley/issues

---

**Last Updated**: April 6, 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
