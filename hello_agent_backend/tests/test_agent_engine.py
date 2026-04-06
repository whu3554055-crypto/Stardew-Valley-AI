"""
Autonomous Agent Engine 单元测试

测试自主 NPC 决策引擎的感知、决策、执行和记忆循环。

运行测试:
    pytest tests/test_agent_engine.py -v
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from services.agent_engine import AgentEngine, AgentContext, DecisionResult


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def mock_llm_router():
    """模拟 LLM 路由器"""
    router = AsyncMock()
    router.chat_completion = AsyncMock(return_value=MagicMock(
        content='{"action": "move_to", "target": "town_square", "reasoning": "Going to socialize"}',
        provider="ollama",
        cost=0.0,
        latency_ms=150
    ))
    return router


@pytest.fixture
def mock_mcp_handler():
    """模拟 MCP 处理器"""
    handler = AsyncMock()
    handler.handle_request = AsyncMock(return_value={
        "jsonrpc": "2.0",
        "id": "test",
        "result": {"success": True}
    })
    return handler


@pytest.fixture
def mock_memory_store():
    """模拟向量记忆存储"""
    store = AsyncMock()
    store.search = AsyncMock(return_value=[
        {"text": "Met player yesterday", "score": 0.85},
        {"text": "Town festival is tomorrow", "score": 0.72}
    ])
    store.add = AsyncMock(return_value=True)
    return store


@pytest.fixture
def mock_database():
    """模拟数据库"""
    db = AsyncMock()
    db.get_npc = AsyncMock(return_value={
        "id": "villager_001",
        "name": "Alice",
        "personality": {"traits": ["friendly", "curious"]},
        "location": "home",
        "schedule": {}
    })
    db.update_npc_location = AsyncMock(return_value=True)
    db.add_relationship_event = AsyncMock(return_value=True)
    return db


@pytest.fixture
def agent_engine(mock_llm_router, mock_mcp_handler, mock_memory_store, mock_database):
    """代理引擎实例"""
    engine = AgentEngine()
    engine.llm_router = mock_llm_router
    engine.mcp_handler = mock_mcp_handler
    engine.memory_store = mock_memory_store
    engine.database = mock_database
    return engine


@pytest.fixture
def sample_context():
    """示例感知上下文"""
    return AgentContext(
        npc_id="villager_001",
        timestamp=datetime.now(),
        location="town_square",
        nearby_npcs=["villager_002", "player1"],
        time_of_day="morning",
        weather="sunny",
        current_quest=None,
        inventory=[]
    )


@pytest.fixture
def sample_decision():
    """示例决策结果"""
    return DecisionResult(
        action="move_to",
        target="market",
        reasoning="Need to buy supplies",
        priority=0.8,
        metadata={"duration_minutes": 15}
    )


# ============================================================================
# Agent Engine Initialization Tests
# ============================================================================

class TestAgentEngineInitialization:
    """测试代理引擎初始化"""

    def test_initialization(self, agent_engine):
        """测试基本初始化"""
        assert agent_engine is not None
        assert agent_engine.active_agents == {}

    def test_default_configuration(self, agent_engine):
        """测试默认配置"""
        assert agent_engine.default_interval == 10.0
        assert agent_engine.max_active_agents == 50


# ============================================================================
# Agent Lifecycle Tests
# ============================================================================

class TestAgentLifecycle:
    """测试代理生命周期管理"""

    @pytest.mark.asyncio
    async def test_start_agent(self, agent_engine):
        """测试启动代理"""
        personality = {"traits": ["friendly"], "goals": ["socialize"]}

        await agent_engine.start_agent("villager_001", interval=5.0, personality=personality)

        assert "villager_001" in agent_engine.active_agents
        assert agent_engine.active_agents["villager_001"]["running"] is True
        assert agent_engine.active_agents["villager_001"]["interval"] == 5.0

    @pytest.mark.asyncio
    async def test_stop_agent(self, agent_engine):
        """测试停止代理"""
        # Start first
        await agent_engine.start_agent("villager_001")

        # Then stop
        await agent_engine.stop_agent("villager_001")

        assert agent_engine.active_agents["villager_001"]["running"] is False

    @pytest.mark.asyncio
    async def test_stop_nonexistent_agent(self, agent_engine):
        """测试停止不存在的代理"""
        result = await agent_engine.stop_agent("nonexistent")
        assert result is False

    @pytest.mark.asyncio
    async def test_get_agent_status(self, agent_engine):
        """测试获取代理状态"""
        await agent_engine.start_agent("villager_001")

        status = agent_engine.get_agent_status("villager_001")
        assert status is not None
        assert "running" in status
        assert "start_time" in status

    @pytest.mark.asyncio
    async def test_get_all_active_agents(self, agent_engine):
        """测试获取所有活跃代理"""
        await agent_engine.start_agent("villager_001")
        await agent_engine.start_agent("villager_002")

        active = agent_engine.get_all_active_agents()
        assert len(active) >= 2

    @pytest.mark.asyncio
    async def test_max_agents_limit(self, agent_engine):
        """测试最大代理数限制"""
        agent_engine.max_active_agents = 2

        await agent_engine.start_agent("npc_001")
        await agent_engine.start_agent("npc_002")

        # Third should fail or be rejected
        with pytest.raises(Exception):
            await agent_engine.start_agent("npc_003")


# ============================================================================
# Perception Phase Tests
# ============================================================================

class TestPerceptionPhase:
    """测试感知阶段"""

    @pytest.mark.asyncio
    async def test_perceive_gathers_context(self, agent_engine):
        """测试感知收集上下文"""
        context = await agent_engine._perceive("villager_001")

        assert isinstance(context, AgentContext)
        assert context.npc_id == "villager_001"
        assert context.location is not None
        assert context.timestamp is not None

    @pytest.mark.asyncio
    async def test_perceive_includes_nearby_npcs(self, agent_engine):
        """测试感知包含附近 NPC"""
        context = await agent_engine._perceive("villager_001")

        # Should query for nearby NPCs via MCP
        assert agent_engine.mcp_handler.handle_request.called

    @pytest.mark.asyncio
    async def test_perceive_handles_errors(self, agent_engine):
        """测试感知错误处理"""
        agent_engine.database.get_npc.side_effect = Exception("DB error")

        context = await agent_engine._perceive("villager_001")

        # Should handle gracefully and return partial context
        assert context is not None
        assert context.npc_id == "villager_001"


# ============================================================================
# Memory Retrieval Tests
# ============================================================================

class TestMemoryRetrieval:
    """测试记忆检索"""

    @pytest.mark.asyncio
    async def test_retrieve_memories(self, agent_engine, sample_context):
        """测试检索相关记忆"""
        memories = await agent_engine._retrieve_memories("villager_001", sample_context)

        assert isinstance(memories, list)
        assert len(memories) > 0
        assert "text" in memories[0]
        assert "score" in memories[0]

    @pytest.mark.asyncio
    async def test_retrieve_memories_empty(self, agent_engine, sample_context):
        """测试空记忆检索"""
        agent_engine.memory_store.search.return_value = []

        memories = await agent_engine._retrieve_memories("villager_001", sample_context)
        assert memories == []

    @pytest.mark.asyncio
    async def test_memory_search_query_construction(self, agent_engine, sample_context):
        """测试记忆搜索查询构建"""
        await agent_engine._retrieve_memories("villager_001", sample_context)

        # Verify search was called with appropriate query
        agent_engine.memory_store.search.assert_called_once()
        call_args = agent_engine.memory_store.search.call_args
        query = call_args[0][0]
        assert "villager_001" in query or "town_square" in query


# ============================================================================
# Decision Phase Tests
# ============================================================================

class TestDecisionPhase:
    """测试决策阶段"""

    @pytest.mark.asyncio
    async def test_decide_returns_valid_action(self, agent_engine, sample_context):
        """测试决策返回有效动作"""
        decision = await agent_engine._decide("villager_001", sample_context, [])

        assert isinstance(decision, DecisionResult)
        assert decision.action is not None
        assert decision.reasoning is not None

    @pytest.mark.asyncio
    async def test_decide_uses_llm(self, agent_engine, sample_context):
        """测试决策使用 LLM"""
        await agent_engine._decide("villager_001", sample_context, [])

        # Verify LLM was called
        agent_engine.llm_router.chat_completion.assert_called_once()

    @pytest.mark.asyncio
    async def test_decide_includes_memories_in_prompt(self, agent_engine, sample_context):
        """测试决策在提示中包含记忆"""
        memories = [{"text": "Previous interaction", "score": 0.9}]
        await agent_engine._decide("villager_001", sample_context, memories)

        # Verify memories were included in LLM call
        call_args = agent_engine.llm_router.chat_completion.call_args
        messages = call_args[1]["messages"]
        prompt_text = str(messages)
        assert "Previous interaction" in prompt_text

    @pytest.mark.asyncio
    async def test_decide_handles_llm_error(self, agent_engine, sample_context):
        """测试决策处理 LLM 错误"""
        agent_engine.llm_router.chat_completion.side_effect = Exception("LLM error")

        decision = await agent_engine._decide("villager_001", sample_context, [])

        # Should return fallback decision
        assert decision is not None
        assert decision.action == "idle"  # Fallback action


# ============================================================================
# Action Execution Tests
# ============================================================================

class TestActionExecution:
    """测试动作执行"""

    @pytest.mark.asyncio
    async def test_execute_move_to(self, agent_engine, sample_decision):
        """测试执行移动动作"""
        sample_decision.action = "move_to"
        sample_decision.target = "market"

        result = await agent_engine._execute("villager_001", sample_decision)

        assert result is not None
        assert "success" in result or "result" in result

    @pytest.mark.asyncio
    async def test_execute_interact_with(self, agent_engine):
        """测试执行交互动作"""
        decision = DecisionResult(
            action="interact_with",
            target="villager_002",
            reasoning="Want to chat"
        )

        result = await agent_engine._execute("villager_001", decision)
        assert result is not None

    @pytest.mark.asyncio
    async def test_execute_say_something(self, agent_engine):
        """测试执行说话动作"""
        decision = DecisionResult(
            action="say_something",
            target="player1",
            reasoning="Greet player",
            metadata={"dialogue": "Hello there!"}
        )

        result = await agent_engine._execute("villager_001", decision)
        assert result is not None

    @pytest.mark.asyncio
    async def test_execute_unknown_action(self, agent_engine):
        """测试执行未知动作"""
        decision = DecisionResult(
            action="unknown_action",
            target=None,
            reasoning="Testing"
        )

        result = await agent_engine._execute("villager_001", decision)
        assert result is not None
        assert "error" in result or "success" in result


# ============================================================================
# Memory Storage Tests
# ============================================================================

class TestMemoryStorage:
    """测试记忆存储"""

    @pytest.mark.asyncio
    async def test_remember_stores_interaction(self, agent_engine, sample_context, sample_decision):
        """测试记住存储交互"""
        result = {"success": True}

        await agent_engine._remember("villager_001", sample_context, sample_decision, result)

        # Verify memory was added
        agent_engine.memory_store.add.assert_called_once()

    @pytest.mark.asyncio
    async def test_remember_creates_embedding_text(self, agent_engine, sample_context, sample_decision):
        """测试记住创建嵌入文本"""
        result = {"success": True}

        await agent_engine._remember("villager_001", sample_context, sample_decision, result)

        call_args = agent_engine.memory_store.add.call_args
        text = call_args[0][0]

        # Should contain relevant information
        assert "villager_001" in text or sample_decision.action in text


# ============================================================================
# Agent Loop Tests
# ============================================================================

class TestAgentLoop:
    """测试代理循环"""

    @pytest.mark.asyncio
    async def test_loop_runs_continuously(self, agent_engine):
        """测试循环持续运行"""
        # Start agent with short interval
        await agent_engine.start_agent("villager_001", interval=0.1)

        # Let it run briefly
        await asyncio.sleep(0.3)

        # Should have executed at least once
        assert agent_engine.mcp_handler.handle_request.call_count > 0

        # Stop it
        await agent_engine.stop_agent("villager_001")

    @pytest.mark.asyncio
    async def test_loop_respects_interval(self, agent_engine):
        """测试循环遵守间隔"""
        start_time = asyncio.get_event_loop().time()
        execution_count = 0

        original_perceive = agent_engine._perceive

        async def counting_perceive(npc_id):
            nonlocal execution_count
            execution_count += 1
            return await original_perceive(npc_id)

        agent_engine._perceive = counting_perceive

        await agent_engine.start_agent("villager_001", interval=0.2)
        await asyncio.sleep(0.5)
        await agent_engine.stop_agent("villager_001")

        # Should have executed 2-3 times in 0.5 seconds with 0.2s interval
        assert 2 <= execution_count <= 4

    @pytest.mark.asyncio
    async def test_loop_handles_exceptions(self, agent_engine):
        """测试循环处理异常"""
        # Make perceive raise exception
        agent_engine._perceive = AsyncMock(side_effect=Exception("Test error"))

        # Should not crash
        await agent_engine.start_agent("villager_001", interval=0.1)
        await asyncio.sleep(0.3)
        await agent_engine.stop_agent("villager_001")

        # Agent should still be manageable
        assert "villager_001" in agent_engine.active_agents


# ============================================================================
# Integration Tests
# ============================================================================

@pytest.mark.integration
class TestAgentEngineIntegration:
    """集成测试（需要实际服务运行）"""

    @pytest.mark.asyncio
    async def test_full_agent_cycle(self):
        """测试完整代理周期"""
        try:
            from llm.router import LLMRouter
            from core.mcp import MCPHandler
            from services.vector_memory import VectorMemoryStore
            from db.repository import GameDatabase

            # Initialize real components
            llm_router = LLMRouter("config/llm_config.json")
            mcp_handler = MCPHandler()
            memory_store = VectorMemoryStore()
            database = GameDatabase()

            engine = AgentEngine()
            engine.llm_router = llm_router
            engine.mcp_handler = mcp_handler
            engine.memory_store = memory_store
            engine.database = database

            # Start agent briefly
            await engine.start_agent("test_npc", interval=1.0)
            await asyncio.sleep(2.0)
            await engine.stop_agent("test_npc")

            # Verify it ran
            status = engine.get_agent_status("test_npc")
            assert status is not None

        except Exception as e:
            pytest.skip(f"Integration test requires running services: {e}")


# ============================================================================
# Performance Tests
# ============================================================================

class TestAgentPerformance:
    """性能测试"""

    @pytest.mark.asyncio
    async def test_decision_latency(self, agent_engine, sample_context):
        """测试决策延迟"""
        import time

        start = time.time()
        await agent_engine._decide("villager_001", sample_context, [])
        elapsed = time.time() - start

        # With mock LLM, should be fast
        assert elapsed < 1.0

    @pytest.mark.asyncio
    async def test_multiple_agents_overhead(self, agent_engine):
        """测试多代理开销"""
        import time

        # Start multiple agents
        start = time.time()
        for i in range(10):
            await agent_engine.start_agent(f"npc_{i:03d}", interval=1.0)
        elapsed = time.time() - start

        # Starting 10 agents should be fast
        assert elapsed < 2.0

        # Clean up
        for i in range(10):
            await agent_engine.stop_agent(f"npc_{i:03d}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
