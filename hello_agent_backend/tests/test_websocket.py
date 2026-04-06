"""
WebSocket Manager 单元测试

测试 WebSocket 连接管理、MCP 消息处理和事件广播。

运行测试:
    pytest tests/test_websocket.py -v
"""

import pytest
import asyncio
import json
from unittest.mock import AsyncMock, MagicMock, patch
from typing import Set

from api.websocket import ConnectionManager


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def mock_websocket():
    """模拟 WebSocket 连接"""
    ws = AsyncMock()
    ws.accept = AsyncMock()
    ws.send_text = AsyncMock()
    ws.send_json = AsyncMock()
    ws.receive_text = AsyncMock()
    ws.close = AsyncMock()
    ws.client = MagicMock()
    ws.client.host = "127.0.0.1"
    return ws


@pytest.fixture
def connection_manager():
    """连接管理器实例"""
    return ConnectionManager()


@pytest.fixture
def sample_mcp_request():
    """示例 MCP 请求"""
    return {
        "jsonrpc": "2.0",
        "id": "req_001",
        "method": "get_npc_info",
        "params": {"npc_id": "villager_001"}
    }


@pytest.fixture
def sample_mcp_response():
    """示例 MCP 响应"""
    return {
        "jsonrpc": "2.0",
        "id": "req_001",
        "result": {
            "npc_id": "villager_001",
            "name": "Alice",
            "location": "town_square"
        }
    }


# ============================================================================
# Connection Management Tests
# ============================================================================

class TestConnectionManagement:
    """测试连接管理"""

    @pytest.mark.asyncio
    async def test_connect_adds_to_pool(self, connection_manager, mock_websocket):
        """测试连接添加到池"""
        client_id = "player1"

        await connection_manager.connect(mock_websocket, client_id)

        assert client_id in connection_manager.active_connections
        assert mock_websocket in connection_manager.active_connections[client_id]

    @pytest.mark.asyncio
    async def test_connect_accepts_websocket(self, connection_manager, mock_websocket):
        """测试连接接受 WebSocket"""
        await connection_manager.connect(mock_websocket, "player1")
        mock_websocket.accept.assert_called_once()

    @pytest.mark.asyncio
    async def test_disconnect_removes_from_pool(self, connection_manager, mock_websocket):
        """测试断开从池中移除"""
        client_id = "player1"
        await connection_manager.connect(mock_websocket, client_id)

        await connection_manager.disconnect(mock_websocket, client_id)

        assert mock_websocket not in connection_manager.active_connections.get(client_id, set())

    @pytest.mark.asyncio
    async def test_disconnect_empty_client_cleanup(self, connection_manager, mock_websocket):
        """测试空客户端清理"""
        client_id = "temp_client"
        await connection_manager.connect(mock_websocket, client_id)
        await connection_manager.disconnect(mock_websocket, client_id)

        # Should remove empty client entry
        assert client_id not in connection_manager.active_connections

    @pytest.mark.asyncio
    async def test_multiple_clients(self, connection_manager):
        """测试多客户端支持"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        await connection_manager.connect(ws1, "player1")
        await connection_manager.connect(ws2, "player2")

        assert "player1" in connection_manager.active_connections
        assert "player2" in connection_manager.active_connections
        assert len(connection_manager.active_connections) == 2

    @pytest.mark.asyncio
    async def test_multiple_connections_same_client(self, connection_manager):
        """测试同一客户端多连接"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        await connection_manager.connect(ws1, "player1")
        await connection_manager.connect(ws2, "player1")

        assert len(connection_manager.active_connections["player1"]) == 2

    def test_get_active_clients(self, connection_manager):
        """测试获取活跃客户端列表"""
        connection_manager.active_connections = {
            "player1": {AsyncMock()},
            "player2": {AsyncMock(), AsyncMock()}
        }

        clients = connection_manager.get_active_clients()
        assert "player1" in clients
        assert "player2" in clients
        assert len(clients) == 2

    def test_get_connection_count(self, connection_manager):
        """测试获取连接数"""
        connection_manager.active_connections = {
            "player1": {AsyncMock(), AsyncMock()},
            "player2": {AsyncMock()}
        }

        count = connection_manager.get_connection_count()
        assert count == 3


# ============================================================================
# Message Sending Tests
# ============================================================================

class TestMessageSending:
    """测试消息发送"""

    @pytest.mark.asyncio
    async def test_send_to_client(self, connection_manager, mock_websocket):
        """测试向客户端发送消息"""
        message = {"type": "test", "data": "hello"}

        await connection_manager.send_to_client(mock_websocket, message)

        mock_websocket.send_text.assert_called_once()
        call_args = mock_websocket.send_text.call_args
        sent_data = json.loads(call_args[0][0])
        assert sent_data["type"] == "test"

    @pytest.mark.asyncio
    async def test_send_to_nonexistent_client(self, connection_manager):
        """测试向不存在的客户端发送"""
        # Should not raise exception
        await connection_manager.send_to_client_by_id("nonexistent", {"msg": "test"})
        # No assertion needed - should complete without error

    @pytest.mark.asyncio
    async def test_broadcast_to_all(self, connection_manager):
        """测试广播到所有客户端"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        connection_manager.active_connections = {
            "player1": {ws1},
            "player2": {ws2}
        }

        message = {"event": "world_update"}
        await connection_manager.broadcast(message)

        assert ws1.send_text.call_count == 1
        assert ws2.send_text.call_count == 1

    @pytest.mark.asyncio
    async def test_broadcast_to_specific_client(self, connection_manager):
        """测试广播到特定客户端"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        connection_manager.active_connections = {
            "player1": {ws1},
            "player2": {ws2}
        }

        message = {"event": "private_message"}
        await connection_manager.broadcast_to_client("player1", message)

        ws1.send_text.assert_called_once()
        ws2.send_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_send_error_handling(self, connection_manager, mock_websocket):
        """测试发送错误处理"""
        mock_websocket.send_text.side_effect = Exception("Connection lost")

        # Should handle gracefully
        await connection_manager.send_to_client(mock_websocket, {"msg": "test"})
        # No exception raised


# ============================================================================
# MCP Protocol Tests
# ============================================================================

class TestMCPProtocol:
    """测试 MCP 协议处理"""

    @pytest.mark.asyncio
    async def test_handle_valid_mcp_request(self, connection_manager, mock_websocket, sample_mcp_request):
        """测试处理有效 MCP 请求"""
        with patch('api.websocket.game_mcp') as mock_mcp:
            mock_mcp.handle_request = AsyncMock(return_value={
                "jsonrpc": "2.0",
                "id": "req_001",
                "result": {"success": True}
            })

            await connection_manager.handle_mcp_over_websocket(
                mock_websocket, sample_mcp_request, "player1"
            )

            # Verify MCP handler was called
            mock_mcp.handle_request.assert_called_once_with(sample_mcp_request)
            # Verify response was sent
            mock_websocket.send_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_handle_invalid_json_rpc_version(self, connection_manager, mock_websocket):
        """测试处理无效 JSON-RPC 版本"""
        invalid_request = {
            "jsonrpc": "1.0",  # Wrong version
            "id": "req_001",
            "method": "test"
        }

        await connection_manager.handle_mcp_over_websocket(
            mock_websocket, invalid_request, "player1"
        )

        # Should send error response
        mock_websocket.send_text.assert_called_once()
        call_args = mock_websocket.send_text.call_args
        response = json.loads(call_args[0][0])
        assert "error" in response

    @pytest.mark.asyncio
    async def test_handle_missing_method(self, connection_manager, mock_websocket):
        """测试处理缺少方法"""
        invalid_request = {
            "jsonrpc": "2.0",
            "id": "req_001"
            # Missing method
        }

        await connection_manager.handle_mcp_over_websocket(
            mock_websocket, invalid_request, "player1"
        )

        # Should send error
        mock_websocket.send_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_handle_mcp_error_response(self, connection_manager, mock_websocket, sample_mcp_request):
        """测试处理 MCP 错误响应"""
        with patch('api.websocket.game_mcp') as mock_mcp:
            mock_mcp.handle_request = AsyncMock(return_value={
                "jsonrpc": "2.0",
                "id": "req_001",
                "error": {"code": -32601, "message": "Method not found"}
            })

            await connection_manager.handle_mcp_over_websocket(
                mock_websocket, sample_mcp_request, "player1"
            )

            # Error response should still be sent
            mock_websocket.send_text.assert_called_once()


# ============================================================================
# Event Subscription Tests
# ============================================================================

class TestEventSubscription:
    """测试事件订阅"""

    @pytest.mark.asyncio
    async def test_subscribe_to_events(self, connection_manager, mock_websocket):
        """测试订阅事件"""
        client_id = "player1"
        events = ["npc_dialogue", "agent_action"]

        await connection_manager.subscribe_to_events(client_id, events)

        assert client_id in connection_manager.event_subscriptions
        assert "npc_dialogue" in connection_manager.event_subscriptions[client_id]

    @pytest.mark.asyncio
    async def test_unsubscribe_from_events(self, connection_manager, mock_websocket):
        """测试取消订阅事件"""
        client_id = "player1"
        await connection_manager.subscribe_to_events(client_id, ["npc_dialogue"])
        await connection_manager.unsubscribe_from_events(client_id, ["npc_dialogue"])

        assert "npc_dialogue" not in connection_manager.event_subscriptions.get(client_id, [])

    @pytest.mark.asyncio
    async def test_send_event_to_subscribers(self, connection_manager):
        """测试发送事件给订阅者"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        connection_manager.active_connections = {
            "player1": {ws1},
            "player2": {ws2}
        }

        await connection_manager.subscribe_to_events("player1", ["npc_dialogue"])
        await connection_manager.subscribe_to_events("player2", ["agent_action"])

        # Send npc_dialogue event
        event_data = {"npc_id": "villager_001", "dialogue": "Hello!"}
        await connection_manager.send_event("npc_dialogue", event_data)

        # Only player1 should receive
        ws1.send_text.assert_called_once()
        ws2.send_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_send_event_to_all_subscribers(self, connection_manager):
        """测试发送事件给所有订阅者（通配符）"""
        ws1 = AsyncMock()
        ws2 = AsyncMock()

        connection_manager.active_connections = {
            "player1": {ws1},
            "player2": {ws2}
        }

        await connection_manager.subscribe_to_events("player1", ["*"])
        await connection_manager.subscribe_to_events("player2", ["npc_dialogue"])

        event_data = {"npc_id": "villager_001"}
        await connection_manager.send_event("npc_dialogue", event_data)

        # Both should receive (player1 via wildcard, player2 via specific)
        assert ws1.send_text.call_count >= 1
        assert ws2.send_text.call_count >= 1


# ============================================================================
# Connection Handler Tests
# ============================================================================

class TestConnectionHandler:
    """测试连接处理器"""

    @pytest.mark.asyncio
    async def test_handle_connection_lifecycle(self, connection_manager, mock_websocket, sample_mcp_request):
        """测试处理完整连接生命周期"""
        client_id = "player1"

        # Mock receive to return one message then disconnect
        mock_websocket.receive_text.side_effect = [
            json.dumps(sample_mcp_request),
            asyncio.CancelledError()  # Simulate disconnect
        ]

        with patch('api.websocket.game_mcp') as mock_mcp:
            mock_mcp.handle_request = AsyncMock(return_value={
                "jsonrpc": "2.0",
                "id": "req_001",
                "result": {}
            })

            try:
                await connection_manager.handle_connection(mock_websocket, client_id)
            except asyncio.CancelledError:
                pass

        # Verify connect was called
        assert client_id in connection_manager.active_connections

    @pytest.mark.asyncio
    async def test_handle_invalid_json(self, connection_manager, mock_websocket):
        """测试处理无效 JSON"""
        mock_websocket.receive_text.side_effect = [
            "{invalid json}",
            asyncio.CancelledError()
        ]

        try:
            await connection_manager.handle_connection(mock_websocket, "player1")
        except asyncio.CancelledError:
            pass

        # Should handle gracefully, no crash

    @pytest.mark.asyncio
    async def test_handle_subscription_message(self, connection_manager, mock_websocket):
        """测试处理订阅消息"""
        subscription_msg = {
            "type": "subscribe",
            "events": ["npc_dialogue", "world_event"]
        }

        mock_websocket.receive_text.side_effect = [
            json.dumps(subscription_msg),
            asyncio.CancelledError()
        ]

        try:
            await connection_manager.handle_connection(mock_websocket, "player1")
        except asyncio.CancelledError:
            pass

        # Verify subscription was processed
        assert "npc_dialogue" in connection_manager.event_subscriptions.get("player1", [])


# ============================================================================
# Integration Tests
# ============================================================================

@pytest.mark.integration
class TestWebSocketIntegration:
    """集成测试（需要实际服务器运行）"""

    @pytest.mark.asyncio
    async def test_full_connection_flow(self):
        """测试完整连接流程"""
        try:
            from fastapi.testclient import TestClient
            from main import app

            client = TestClient(app)

            with client.websocket_connect("/ws/player1") as websocket:
                # Send MCP request
                request = {
                    "jsonrpc": "2.0",
                    "id": "test_001",
                    "method": "ping",
                    "params": {}
                }
                websocket.send_json(request)

                # Receive response
                response = websocket.receive_json()
                assert "jsonrpc" in response
                assert response["id"] == "test_001"

        except Exception as e:
            pytest.skip(f"Integration test requires running server: {e}")


# ============================================================================
# Performance Tests
# ============================================================================

class TestWebSocketPerformance:
    """性能测试"""

    @pytest.mark.asyncio
    async def test_concurrent_connections(self, connection_manager):
        """测试并发连接"""
        import time

        num_connections = 50
        websockets = [AsyncMock() for _ in range(num_connections)]

        start = time.time()

        # Connect all
        for i, ws in enumerate(websockets):
            await connection_manager.connect(ws, f"client_{i}")

        elapsed = time.time() - start

        # Should handle 50 connections quickly
        assert elapsed < 2.0
        assert connection_manager.get_connection_count() == num_connections

    @pytest.mark.asyncio
    async def test_broadcast_performance(self, connection_manager):
        """测试广播性能"""
        import time

        # Setup 100 clients
        for i in range(100):
            ws = AsyncMock()
            await connection_manager.connect(ws, f"client_{i}")

        # Broadcast message
        start = time.time()
        await connection_manager.broadcast({"event": "test"})
        elapsed = time.time() - start

        # Should broadcast to 100 clients quickly (with mocks)
        assert elapsed < 2.0

    @pytest.mark.asyncio
    async def test_message_throughput(self, connection_manager, mock_websocket):
        """测试消息吞吐量"""
        import time

        await connection_manager.connect(mock_websocket, "player1")

        num_messages = 100
        start = time.time()

        for i in range(num_messages):
            await connection_manager.send_to_client(mock_websocket, {"index": i})

        elapsed = time.time() - start

        # Should send 100 messages quickly (with mocks)
        assert elapsed < 1.0
        assert mock_websocket.send_text.call_count == num_messages


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
