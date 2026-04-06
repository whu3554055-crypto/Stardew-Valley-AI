"""
Prometheus Metrics Middleware for FastAPI

Provides application monitoring and observability.
"""

import time
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


# HTTP Metrics
HTTP_REQUESTS = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'path', 'status']
)

HTTP_REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'path']
)

HTTP_REQUEST_IN_PROGRESS = Gauge(
    'http_requests_in_progress',
    'HTTP requests in progress',
    ['method', 'path']
)

# Application Metrics
ACTIVE_PLAYERS = Gauge(
    'active_players_total',
    'Number of active players'
)

NPC_INTERACTIONS = Counter(
    'npc_interactions_total',
    'Total NPC interactions',
    ['npc_id', 'interaction_type']
)

QUEST_COMPLETIONS = Counter(
    'quest_completions_total',
    'Total quest completions',
    ['quest_type', 'difficulty']
)

ITEM_TRANSACTIONS = Counter(
    'item_transactions_total',
    'Total item transactions',
    ['transaction_type', 'item_id']
)

# Database Metrics
DB_QUERY_DURATION = Histogram(
    'db_query_duration_seconds',
    'Database query duration',
    ['query_type']
)

DB_CONNECTIONS = Gauge(
    'db_connections_active',
    'Active database connections'
)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Middleware to collect HTTP request metrics"""

    async def dispatch(self, request: Request, call_next):
        # Skip metrics endpoint itself
        if request.url.path == '/metrics':
            return await call_next(request)

        method = request.method
        path = request.url.path

        # Track in-progress requests
        HTTP_REQUEST_IN_PROGRESS.labels(method=method, path=path).inc()

        # Measure request duration
        start_time = time.time()

        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            status_code = 500
            raise
        finally:
            duration = time.time() - start_time

            # Record metrics
            HTTP_REQUESTS.labels(
                method=method,
                path=path,
                status=status_code
            ).inc()

            HTTP_REQUEST_DURATION.labels(
                method=method,
                path=path
            ).observe(duration)

            HTTP_REQUEST_IN_PROGRESS.labels(
                method=method,
                path=path
            ).dec()

        return response


def create_metrics_endpoint():
    """Create a FastAPI route handler for /metrics endpoint"""
    async def metrics_endpoint():
        return Response(
            content=generate_latest(),
            media_type=CONTENT_TYPE_LATEST
        )
    return metrics_endpoint


# Helper functions for custom metrics
def record_npc_interaction(npc_id: str, interaction_type: str = "talk"):
    """Record an NPC interaction"""
    NPC_INTERACTIONS.labels(
        npc_id=npc_id,
        interaction_type=interaction_type
    ).inc()


def record_quest_completion(quest_type: str, difficulty: str):
    """Record a quest completion"""
    QUEST_COMPLETIONS.labels(
        quest_type=quest_type,
        difficulty=difficulty
    ).inc()


def record_item_transaction(transaction_type: str, item_id: str):
    """Record an item transaction (buy/sell/use)"""
    ITEM_TRANSACTIONS.labels(
        transaction_type=transaction_type,
        item_id=item_id
    ).inc()


def update_active_players(count: int):
    """Update active player count"""
    ACTIVE_PLAYERS.set(count)


def observe_db_query(query_type: str, duration: float):
    """Record database query duration"""
    DB_QUERY_DURATION.labels(query_type=query_type).observe(duration)
