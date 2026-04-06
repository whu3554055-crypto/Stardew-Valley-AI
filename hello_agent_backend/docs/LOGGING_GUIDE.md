# Structured Logging Guide

This document explains how to use the structured logging system in Hello-Agent Backend.

## Overview

The application uses `structlog` for structured, JSON-formatted logging with:
- Automatic timestamp and log level
- Exception tracking with full tracebacks
- Request context binding (request_id, user_id, etc.)
- Log rotation and file management
- Multiple output formats (JSON for production, colored console for development)

## Basic Usage

### Get a Logger

```python
from app.core.logging_config import get_logger

logger = get_logger(__name__)
```

### Log Messages at Different Levels

```python
# Debug level - detailed diagnostic information
logger.debug("Processing item", item_id="parsnip", quantity=5)

# Info level - general operational information
logger.info("User logged in", user_id="123", username="farmer_joe")

# Warning level - unexpected but handled situations
logger.warning("Cache miss, falling back to database", key="npc:pierre")

# Error level - errors that need attention
logger.error("Database query failed", query="SELECT * FROM npcs", error=str(e))

# Critical level - system failures
logger.critical("Redis connection lost", retry_count=3)
```

### Log with Context

```python
from app.core.logging_config import bind_context

# Bind context for all subsequent logs in this scope
bind_context(user_id="123", session_id="abc-def", request_id="req-001")

logger.info("Starting quest generation")  # Includes bound context
logger.info("Quest completed")            # Also includes bound context
```

### Log Exceptions

```python
try:
    result = await database.query(sql)
except Exception as e:
    logger.error(
        "Query execution failed",
        query=sql,
        exc_info=True  # Automatically captures exception details
    )
```

## Log Output Format

### Production (JSON)

```json
{
  "timestamp": "2026-04-06T10:30:45.123456+00:00",
  "level": "INFO",
  "logger": "app.api.routes",
  "module": "routes",
  "function": "chat_endpoint",
  "line": 125,
  "message": "Chat message processed",
  "request_id": "a1b2c3d4",
  "user_id": "user_0001",
  "duration_ms": 45.2
}
```

### Development (Colored Console)

```
INFO | 10:30:45 | app.api.routes | Chat message processed
ERROR | 10:30:46 | app.db.repository | Query execution failed
```

## Configuration

### Environment Variables

Set in `.env` file:

```bash
# Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL=INFO

# Log file path
LOG_FILE=logs/backend.log

# Log format: json or text
LOG_FORMAT=json

# Log rotation
LOG_MAX_BYTES=10485760    # 10 MB
LOG_BACKUP_COUNT=5        # Keep 5 backup files
```

### Programmatic Configuration

```python
from app.core.logging_config import setup_structlog

setup_structlog(
    log_level="DEBUG",
    log_file="logs/app.log",
    json_logs=True
)
```

## Request Logging

The `RequestLoggingMiddleware` automatically logs all HTTP requests:

```json
{
  "timestamp": "2026-04-06T10:30:45.000000+00:00",
  "level": "info",
  "event": "Request started: POST /api/v1/chat",
  "request_id": "a1b2c3d4",
  "method": "POST",
  "path": "/api/v1/chat"
}
```

```json
{
  "timestamp": "2026-04-06T10:30:45.123456+00:00",
  "level": "info",
  "event": "Request completed: POST /api/v1/chat [200]",
  "request_id": "a1b2c3d4",
  "method": "POST",
  "path": "/api/v1/chat",
  "status_code": 200
}
```

## Best Practices

### 1. Use Appropriate Log Levels

- **DEBUG**: Detailed diagnostic info (variable values, intermediate steps)
- **INFO**: Normal operational messages (user actions, successful operations)
- **WARNING**: Unexpected but handled situations (cache misses, retries)
- **ERROR**: Errors that need attention (failed queries, external API failures)
- **CRITICAL**: System failures requiring immediate action (database down, out of memory)

### 2. Include Context

Always include relevant context in log messages:

```python
# Bad
logger.error("Failed to process request")

# Good
logger.error(
    "Failed to process quest completion",
    quest_id="quest_001",
    player_id="user_123",
    reward_gold=100,
    error=str(e)
)
```

### 3. Don't Log Sensitive Data

Never log:
- Passwords or tokens
- Credit card numbers
- Personal identifiable information (PII)
- Secret keys

```python
# Bad
logger.info("User login", password=user_password)

# Good
logger.info("User login attempt", username=username, success=success)
```

### 4. Use Structured Data

Pass data as keyword arguments, not formatted strings:

```python
# Bad
logger.info(f"Player {player_id} bought {item_name} for {price} gold")

# Good
logger.info(
    "Item purchased",
    player_id=player_id,
    item_name=item_name,
    price=price,
    currency="gold"
)
```

### 5. Log Performance Metrics

```python
import time

start = time.time()
result = await expensive_operation()
duration_ms = (time.time() - start) * 1000

logger.info(
    "Operation completed",
    operation="generate_daily_quest",
    duration_ms=round(duration_ms, 2),
    npc_id=npc_id
)
```

## Log Analysis

### Search Logs with jq

```bash
# Find all errors
cat logs/backend.log | jq 'select(.level == "ERROR")'

# Find logs for specific user
cat logs/backend.log | jq 'select(.user_id == "user_123")'

# Find slow requests (>1000ms)
cat logs/backend.log | jq 'select(.duration_ms > 1000)'
```

### Search Logs with grep

```bash
# Find errors
grep '"level": "ERROR"' logs/backend.log

# Find specific request
grep "quest_001" logs/backend.log

# Count errors by module
grep '"level": "ERROR"' logs/backend.log | jq -r '.module' | sort | uniq -c
```

## Integration with Monitoring

Logs are automatically correlated with Prometheus metrics via `request_id`. When investigating issues:

1. Find the request_id in Grafana traces
2. Search logs for that request_id
3. See full request lifecycle with all context

## Log Rotation

Logs are automatically rotated when they reach `LOG_MAX_BYTES` (default: 10 MB). Old logs are kept based on `LOG_BACKUP_COUNT` (default: 5).

Rotated files:
- `backend.log` - Current log file
- `backend.log.1` - Most recent backup
- `backend.log.2` - Second most recent
- ... up to `backend.log.5`
