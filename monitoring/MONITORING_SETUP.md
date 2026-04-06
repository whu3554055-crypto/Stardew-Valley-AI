# Monitoring Setup - Cyber Town

This directory contains Prometheus + Grafana monitoring infrastructure for the Cyber Town game server.

## Components

- **Prometheus**: Metrics collection and storage (port 9090)
- **Grafana**: Visualization dashboards (port 3000)
- **FastAPI Middleware**: Custom metrics exporter (/metrics endpoint)

## Quick Start

### 1. Install Python Dependencies

```bash
cd hello_agent_backend
pip install -r requirements.txt
```

### 2. Start Monitoring Stack

```bash
docker-compose -f monitoring/docker-compose.monitoring.yml up -d
```

### 3. Access Dashboards

- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `admin`

- **Prometheus**: http://localhost:9090

### 4. Start Game Server

The FastAPI application automatically exposes metrics at `/metrics`:

```bash
cd hello_agent_backend
uvicorn app.main:app --reload
```

Verify metrics are working:
```bash
curl http://localhost:8000/metrics
```

## Available Metrics

### HTTP Metrics
- `http_requests_total` - Total HTTP requests by method, path, status
- `http_request_duration_seconds` - Request latency histogram
- `http_requests_in_progress` - Currently active requests

### Application Metrics
- `active_players_total` - Number of active players
- `npc_interactions_total` - NPC interaction counts by type
- `quest_completions_total` - Quest completion counts
- `item_transactions_total` - Item buy/sell/use transactions

### Database Metrics
- `db_query_duration_seconds` - Query execution time
- `db_connections_active` - Active database connections

## Custom Metrics Integration

To record custom metrics in your code:

```python
from app.middleware.metrics import (
    record_npc_interaction,
    record_quest_completion,
    record_item_transaction,
    update_active_players,
    observe_db_query
)

# Example: Record NPC interaction
record_npc_interaction("pierre", "talk")

# Example: Record quest completion
record_quest_completion("daily", "easy")

# Example: Record item transaction
record_item_transaction("buy", "parsnip_seeds")

# Example: Update active player count
update_active_players(42)
```

## Dashboard Configuration

Dashboards are auto-provisioned from:
- `grafana/dashboards/cyber_town_dashboard.json`

To add custom panels:
1. Edit the JSON file
2. Or use Grafana UI (changes persist in volume)

## Prometheus Configuration

Edit `prometheus.yml` to:
- Change scrape interval (default: 15s)
- Add new targets
- Configure alerting rules

## Stopping Monitoring

```bash
docker-compose -f monitoring/docker-compose.monitoring.yml down
```

To remove all data:
```bash
docker-compose -f monitoring/docker-compose.monitoring.yml down -v
```

## Troubleshooting

### No metrics showing in Grafana
1. Check Prometheus target status: http://localhost:9090/targets
2. Verify game server is running and /metrics endpoint responds
3. Check Docker network connectivity

### Grafana can't connect to Prometheus
1. Ensure both containers are on same network
2. Check datasource URL: `http://prometheus:9090`
3. Restart Grafana container

### High memory usage
1. Reduce scrape interval in prometheus.yml
2. Configure retention period: `--storage.tsdb.retention.time=7d`
3. Add recording rules to aggregate old data

## Production Considerations

For production deployment:
1. Change default Grafana admin password
2. Enable HTTPS/TLS
3. Configure alerting (email, Slack, PagerDuty)
4. Set up backup for Prometheus data
5. Use persistent volumes
6. Add authentication to /metrics endpoint
