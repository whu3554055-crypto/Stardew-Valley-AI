# Docker 快速开始指南

## 🚀 一键启动所有服务

### 前置要求
- Docker Desktop 已安装并运行
- Docker Compose v2+ (包含在 Docker Desktop 中)

### 启动服务

```bash
cd hello_agent_backend

# 构建并启动所有服务
docker-compose up -d

# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f backend
```

### 访问服务

- **API 文档**: http://localhost:8080/docs
- **健康检查**: http://localhost:8080/health
- **WebSocket**: ws://localhost:8080/ws/player1
- **Redis**: localhost:6379

### 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（谨慎使用！）
docker-compose down -v
```

---

## 🔧 配置选项

### 环境变量

创建 `.env` 文件：

```env
# API Keys
QWEN_API_KEY=your_qwen_key_here
GEMINI_API_KEY=your_gemini_key_here

# Ollama (if using local LLM)
OLLAMA_BASE_URL=http://ollama:11434
```

### 启用本地 Ollama

编辑 `docker-compose.yml`，取消注释 ollama 服务部分：

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    # ... (uncomment all ollama sections)
```

然后启动：

```bash
docker-compose up -d
```

---

## 📊 监控和维护

### 查看资源使用

```bash
# 容器资源统计
docker stats

# 特定容器
docker stats hello-agent-backend
```

### 进入容器调试

```bash
# 进入 backend 容器
docker exec -it hello-agent-backend sh

# 查看数据库文件
ls -la /app/data/

# 查看日志
tail -f /app/data/logs/app.log
```

### 备份数据

```bash
# 备份向量数据库
docker cp hello-agent-backend:/app/data/vector_store ./backup/vector_store

# 备份游戏状态
docker cp hello-agent-backend:/app/data/game_state.db ./backup/game_state.db
```

---

## 🐛 故障排除

### 问题 1: 端口已被占用

**解决**: 修改 `docker-compose.yml` 中的端口映射

```yaml
ports:
  - "8081:8080"  # Change host port to 8081
```

### 问题 2: Redis 连接失败

**检查**:
```bash
docker-compose logs redis
docker exec -it hello-agent-redis redis-cli ping
```

### 问题 3: 内存不足

**解决**: 调整 `docker-compose.yml` 中的资源限制

```yaml
deploy:
  resources:
    limits:
      memory: 4G  # Increase memory limit
```

---

## 🎯 生产部署建议

1. **使用外部网络**
   ```yaml
   networks:
     default:
       external: true
       name: production-network
   ```

2. **启用 HTTPS**
   - 使用 Nginx 反向代理
   - Let's Encrypt 证书

3. **数据持久化**
   - 使用命名卷而非绑定挂载
   - 定期备份

4. **监控**
   - Prometheus + Grafana
   - ELK Stack for logs

---

**更多信息**: 参见 [SUPPLEMENTARY_IMPLEMENTATION_PLAN.md](SUPPLEMENTARY_IMPLEMENTATION_PLAN.md)
