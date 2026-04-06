"""
WebSocket Manager - Real-time bidirectional communication

Provides WebSocket endpoints for:
- Real-time event pushing from server to client
- MCP protocol over WebSocket
- Agent status updates
- Game state synchronization

Architecture:
    - ConnectionManager: Manages active WebSocket connections
    - Event broadcasting to specific clients or all
    - MCP over WebSocket (JSON-RPC 2.0)
    - Automatic reconnection support

Usage (Client):
    const ws = new WebSocket('ws://localhost:8080/ws/player1');
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        console.log('Received:', data);
    };

Usage (Server):
    from app.api.websocket import manager
    await manager.broadcast({"type": "event", "data": {...}})
"""

import json
import logging
from typing import Dict, Set, Any, Optional
from fastapi import WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections with support for:
    - Multiple clients per user
    - Targeted messaging
    - Broadcasting
    - Connection lifecycle tracking
    """

    def __init__(self):
        # {client_id: set of WebSocket connections}
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # Track connection metadata
        self.connection_metadata: Dict[str, Dict[str, Any]] = {}

    async def connect(self, websocket: WebSocket, client_id: str, metadata: Optional[Dict] = None):
        """
        Accept and register a new WebSocket connection

        Args:
            websocket: The WebSocket connection
            client_id: Unique client identifier (e.g., player ID)
            metadata: Optional connection metadata
        """
        await websocket.accept()

        if client_id not in self.active_connections:
            self.active_connections[client_id] = set()

        self.active_connections[client_id].add(websocket)

        # Store metadata
        if metadata:
            self.connection_metadata[client_id] = metadata

        logger.info(f"WebSocket connected: {client_id} (total: {len(self.active_connections[client_id])})")

        # Send welcome message
        await self.send_to_client(websocket, {
            "type": "system",
            "event": "connected",
            "data": {
                "client_id": client_id,
                "message": "Connected to Stardew Valley AI Agent Service"
            }
        })

    def disconnect(self, websocket: WebSocket, client_id: str):
        """
        Remove a WebSocket connection

        Args:
            websocket: The WebSocket connection to remove
            client_id: Client identifier
        """
        if client_id in self.active_connections:
            self.active_connections[client_id].discard(websocket)

            # Clean up empty client entries
            if not self.active_connections[client_id]:
                del self.active_connections[client_id]
                if client_id in self.connection_metadata:
                    del self.connection_metadata[client_id]

            logger.info(f"WebSocket disconnected: {client_id} (remaining: {len(self.active_connections.get(client_id, set()))})")

    async def send_to_client(self, websocket: WebSocket, message: Dict[str, Any]):
        """
        Send message to a specific WebSocket connection

        Args:
            websocket: Target WebSocket connection
            message: Message dict (will be JSON serialized)
        """
        try:
            if websocket.client_state == WebSocketState.CONNECTED:
                await websocket.send_json(message)
        except Exception as e:
            logger.error(f"Failed to send message: {e}")

    async def send_to_user(self, client_id: str, message: Dict[str, Any]):
        """
        Send message to all connections of a specific user

        Args:
            client_id: Target client identifier
            message: Message dict
        """
        if client_id not in self.active_connections:
            logger.warning(f"No active connections for client: {client_id}")
            return False

        success_count = 0
        for connection in self.active_connections[client_id]:
            try:
                await self.send_to_client(connection, message)
                success_count += 1
            except Exception as e:
                logger.error(f"Failed to send to {client_id}: {e}")

        logger.debug(f"Sent message to {success_count} connections of {client_id}")
        return success_count > 0

    async def broadcast(self, message: Dict[str, Any], exclude_client: Optional[str] = None):
        """
        Broadcast message to all connected clients

        Args:
            message: Message dict to broadcast
            exclude_client: Optional client ID to exclude
        """
        success_count = 0
        for client_id in list(self.active_connections.keys()):
            if exclude_client and client_id == exclude_client:
                continue

            if await self.send_to_user(client_id, message):
                success_count += 1

        logger.debug(f"Broadcasted message to {success_count} clients")
        return success_count

    async def handle_mcp_over_websocket(self, websocket: WebSocket, message: Dict[str, Any], client_id: str):
        """
        Handle MCP (JSON-RPC 2.0) messages over WebSocket

        Args:
            websocket: Client WebSocket connection
            message: JSON-RPC 2.0 message
            client_id: Client identifier
        """
        from app.core.mcp_protocol import game_mcp

        # Validate JSON-RPC format
        if message.get("jsonrpc") != "2.0":
            await self.send_to_client(websocket, {
                "jsonrpc": "2.0",
                "id": message.get("id"),
                "result": None,
                "error": {
                    "code": -32600,
                    "message": "Invalid Request: jsonrpc version must be 2.0"
                }
            })
            return

        # Handle MCP request
        try:
            response = await game_mcp.handle_request(message)
            await self.send_to_client(websocket, response)

        except Exception as e:
            logger.error(f"MCP over WebSocket failed: {e}")
            await self.send_to_client(websocket, {
                "jsonrpc": "2.0",
                "id": message.get("id"),
                "result": None,
                "error": {
                    "code": -32000,
                    "message": str(e)
                }
            })

    def get_active_clients(self) -> list:
        """Get list of all connected client IDs"""
        return list(self.active_connections.keys())

    def get_connection_count(self) -> int:
        """Get total number of active connections"""
        return sum(len(conns) for conns in self.active_connections.values())

    def get_stats(self) -> Dict[str, Any]:
        """Get connection statistics"""
        return {
            "active_clients": len(self.active_connections),
            "total_connections": self.get_connection_count(),
            "client_ids": self.get_active_clients()
        }


# Global connection manager instance (singleton)
manager = ConnectionManager()
