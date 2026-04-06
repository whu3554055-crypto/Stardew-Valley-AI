"""
Agent Decision Engine - Autonomous NPC behavior system

Implements a complete perception-decision-action-memory loop for autonomous NPCs.
NPCs can make decisions based on context, memories, and personality.

Architecture:
    Perception → Memory Retrieval → Decision Making → Action Execution → Memory Formation

Features:
    - Autonomous decision making via LLM
    - Context-aware behavior (time, weather, location)
    - Memory-informed decisions
    - MCP tool-based action execution
    - Configurable decision intervals

Usage:
    engine = AgentEngine()
    await engine.start_agent("pierre", interval=10.0)  # Decide every 10 seconds
    await engine.stop_agent("pierre")
"""

import asyncio
import json
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

from llm.router import LLMRouter
from llm.providers.base import LLMMessage
from app.services.memory_store import VectorMemoryStore
from app.core.mcp_protocol import game_mcp

logger = logging.getLogger(__name__)


class AgentEngine:
    """
    Autonomous agent decision engine for NPCs

    Manages multiple NPC agents running concurrent decision loops.
    Each agent perceives context, retrieves memories, decides actions,
    executes via MCP tools, and forms new memories.
    """

    def __init__(self):
        self.llm_router = LLMRouter("config/llm_config.json")
        self.memory_store = VectorMemoryStore()
        self.active_agents: Dict[str, asyncio.Task] = {}
        self.agent_configs: Dict[str, Dict[str, Any]] = {}

    async def start_agent(
        self,
        npc_id: str,
        interval: float = 10.0,
        personality: Optional[Dict[str, Any]] = None
    ):
        """
        Start autonomous agent loop for an NPC

        Args:
            npc_id: NPC identifier
            interval: Decision loop interval in seconds
            personality: NPC personality traits (optional)
        """
        if npc_id in self.active_agents:
            logger.warning(f"Agent already running for {npc_id}")
            return

        # Store configuration
        self.agent_configs[npc_id] = {
            "interval": interval,
            "personality": personality or {},
            "started_at": datetime.now().isoformat()
        }

        # Start decision loop
        task = asyncio.create_task(
            self._agent_loop(npc_id, interval),
            name=f"agent-{npc_id}"
        )
        self.active_agents[npc_id] = task

        logger.info(f"Started agent for {npc_id} (interval={interval}s)")

    async def stop_agent(self, npc_id: str):
        """
        Stop autonomous agent loop for an NPC

        Args:
            npc_id: NPC identifier
        """
        if npc_id in self.active_agents:
            self.active_agents[npc_id].cancel()
            try:
                await self.active_agents[npc_id]
            except asyncio.CancelledError:
                pass

            del self.active_agents[npc_id]
            if npc_id in self.agent_configs:
                del self.agent_configs[npc_id]

            logger.info(f"Stopped agent for {npc_id}")

    async def stop_all_agents(self):
        """Stop all active agents"""
        npc_ids = list(self.active_agents.keys())
        for npc_id in npc_ids:
            await self.stop_agent(npc_id)
        logger.info(f"Stopped all {len(npc_ids)} agents")

    async def _agent_loop(self, npc_id: str, interval: float):
        """
        Main agent loop: Perceive → Decide → Act → Remember

        Args:
            npc_id: NPC identifier
            interval: Loop interval in seconds
        """
        logger.info(f"Agent loop started for {npc_id}")

        while True:
            try:
                # Step 1: Perception - Gather current context
                context = await self._perceive(npc_id)

                # Step 2: Memory Retrieval - Get relevant memories
                memories = await self._retrieve_memories(npc_id, context)

                # Step 3: Decision Making - LLM decides action
                decision = await self._decide(npc_id, context, memories)

                # Step 4: Action Execution - Execute via MCP tools
                result = await self._execute(npc_id, decision)

                # Step 5: Memory Formation - Store decision and outcome
                await self._remember(npc_id, context, decision, result)

                # Wait for next cycle
                await asyncio.sleep(interval)

            except asyncio.CancelledError:
                logger.info(f"Agent loop cancelled for {npc_id}")
                break

            except Exception as e:
                logger.error(f"Agent loop error for {npc_id}: {e}", exc_info=True)
                # Continue loop after error (don't crash the agent)
                await asyncio.sleep(interval)

    async def _perceive(self, npc_id: str) -> Dict[str, Any]:
        """
        Gather current context via MCP tools

        Returns:
            Dict containing world state, NPC info, and timestamp
        """
        context = {
            "timestamp": datetime.now().isoformat(),
            "npc_id": npc_id
        }

        try:
            # Get world state
            world_response = await game_mcp.handle_request({
                "jsonrpc": "2.0",
                "id": f"perceive-world-{npc_id}",
                "method": "get_world_state",
                "params": {}
            })

            if world_response.get("result"):
                context["world"] = world_response["result"]
            else:
                context["world"] = {
                    "season": "spring",
                    "day": 1,
                    "time": "morning",
                    "weather": "sunny"
                }

        except Exception as e:
            logger.warning(f"Failed to get world state: {e}")
            context["world"] = {"error": str(e)}

        try:
            # Get NPC info
            npc_response = await game_mcp.handle_request({
                "jsonrpc": "2.0",
                "id": f"perceive-npc-{npc_id}",
                "method": "get_npc_info",
                "params": {"npc_id": npc_id}
            })

            if npc_response.get("result"):
                context["npc"] = npc_response["result"]
            else:
                context["npc"] = {"npc_id": npc_id, "name": npc_id}

        except Exception as e:
            logger.warning(f"Failed to get NPC info: {e}")
            context["npc"] = {"npc_id": npc_id, "error": str(e)}

        return context

    async def _retrieve_memories(
        self,
        npc_id: str,
        context: Dict[str, Any]
    ) -> List:
        """
        Retrieve relevant memories based on current context

        Args:
            npc_id: NPC identifier
            context: Current context from perception

        Returns:
            List of relevant MemoryEntry objects
        """
        try:
            # Build search query from context
            world = context.get("world", {})
            npc = context.get("npc", {})

            query_parts = []

            # Add mood if available
            if npc.get("mood"):
                query_parts.append(npc["mood"])

            # Add time/season context
            if world.get("time"):
                query_parts.append(world["time"])
            if world.get("season"):
                query_parts.append(world["season"])

            # Add weather
            if world.get("weather"):
                query_parts.append(world["weather"])

            query = " ".join(query_parts) if query_parts else "general"

            # Search memories
            memories = await self.memory_store.search_similar(
                query=query,
                npc_id=npc_id,
                limit=3,
                min_importance=0.3
            )

            logger.debug(f"Retrieved {len(memories)} memories for {npc_id}")
            return memories

        except Exception as e:
            logger.error(f"Failed to retrieve memories: {e}")
            return []

    async def _decide(
        self,
        npc_id: str,
        context: Dict[str, Any],
        memories: List
    ) -> Dict[str, Any]:
        """
        LLM makes decision based on context and memories

        Args:
            npc_id: NPC identifier
            context: Current context
            memories: Relevant memories

        Returns:
            Decision dict with action, reason, and parameters
        """
        # Build memory context string
        memory_context = ""
        if memories:
            memory_context = "\nRelevant Memories:\n"
            for i, mem in enumerate(memories, 1):
                memory_context += f"{i}. {mem.content}\n"

        # Get personality config
        personality = self.agent_configs.get(npc_id, {}).get("personality", {})
        personality_str = ", ".join(f"{k}: {v}" for k, v in personality.items())

        # Build decision prompt
        prompt = f"""You are an autonomous NPC agent controlling {npc_id}.

Current Context:
- World State: {json.dumps(context.get('world', {}), indent=2)}
- NPC State: {json.dumps(context.get('npc', {}), indent=2)}
- Personality: {personality_str if personality_str else 'Not specified'}
{memory_context}

Available Actions:
1. "idle" - Do nothing, wait and observe
2. "work" - Perform job-related activity (e.g., tend shop, farm)
3. "patrol" - Move to another location in town
4. "socialize" - Interact with nearby NPCs or players
5. "rest" - Take a break, relax
6. "chat" - Initiate conversation with player if nearby

Respond with JSON in this exact format:
{{
  "action": "action_name",
  "reason": "brief explanation of why this action was chosen",
  "parameters": {{}},
  "priority": "low|medium|high"
}}

Choose the most appropriate action based on context, time of day, and personality.
"""

        try:
            response = await self.llm_router.chat_completion(
                messages=[LLMMessage(role="user", content=prompt)],
                task_type="agent_decision",
                temperature=0.7,
                max_tokens=200
            )

            # Parse JSON response
            decision = json.loads(response.content)

            # Validate decision
            if "action" not in decision:
                decision = {"action": "idle", "reason": "Invalid decision format", "parameters": {}}

            logger.info(f"Decision for {npc_id}: {decision['action']} - {decision.get('reason', '')}")
            return decision

        except Exception as e:
            logger.error(f"Decision making failed for {npc_id}: {e}")
            # Fallback to idle
            return {
                "action": "idle",
                "reason": f"Error in decision making: {str(e)}",
                "parameters": {}
            }

    async def _execute(self, npc_id: str, decision: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the decided action via MCP tools

        Args:
            npc_id: NPC identifier
            decision: Decision dict from _decide()

        Returns:
            Execution result
        """
        action = decision.get("action", "idle")
        params = decision.get("parameters", {})

        logger.info(f"Executing action '{action}' for {npc_id}")

        # Map actions to MCP tools or direct execution
        try:
            if action == "idle":
                return {"status": "completed", "action": "idle", "message": "Waiting..."}

            elif action == "work":
                # Set NPC mood to working
                response = await game_mcp.handle_request({
                    "jsonrpc": "2.0",
                    "id": f"exec-work-{npc_id}",
                    "method": "set_npc_mood",
                    "params": {"npc_id": npc_id, "mood": "working"}
                })
                return response.get("result", {"status": "completed"})

            elif action == "patrol":
                # Could move NPC to different location (would need place_item or similar tool)
                return {"status": "completed", "action": "patrol", "message": "Moving to new location"}

            elif action == "socialize":
                return {"status": "completed", "action": "socialize", "message": "Looking for someone to talk to"}

            elif action == "rest":
                response = await game_mcp.handle_request({
                    "jsonrpc": "2.0",
                    "id": f"exec-rest-{npc_id}",
                    "method": "set_npc_mood",
                    "params": {"npc_id": npc_id, "mood": "relaxed"}
                })
                return response.get("result", {"status": "completed"})

            elif action == "chat":
                return {"status": "completed", "action": "chat", "message": "Ready to chat"}

            else:
                return {"status": "unknown_action", "action": action}

        except Exception as e:
            logger.error(f"Action execution failed: {e}")
            return {"status": "error", "error": str(e)}

    async def _remember(
        self,
        npc_id: str,
        context: Dict[str, Any],
        decision: Dict[str, Any],
        result: Dict[str, Any]
    ):
        """
        Store the decision and outcome as memory

        Args:
            npc_id: NPC identifier
            context: Context at decision time
            decision: The decision made
            result: Execution result
        """
        try:
            memory_content = (
                f"At {context.get('world', {}).get('time', 'unknown time')}, "
                f"I decided to {decision.get('action', 'do something')} because "
                f"{decision.get('reason', 'it seemed appropriate')}. "
                f"Outcome: {result.get('status', 'unknown')}"
            )

            await self.memory_store.add_memory(
                npc_id=npc_id,
                content=memory_content,
                metadata={
                    "type": "agent_decision",
                    "action": decision.get("action"),
                    "reason": decision.get("reason"),
                    "outcome": result.get("status"),
                    "day": context.get("world", {}).get("day", 0),
                    "importance": 0.4  # Lower importance for routine decisions
                }
            )

            logger.debug(f"Stored decision memory for {npc_id}")

        except Exception as e:
            logger.error(f"Failed to store decision memory: {e}")

    def get_active_agents(self) -> List[str]:
        """Get list of active agent NPC IDs"""
        return list(self.active_agents.keys())

    def get_agent_status(self) -> Dict[str, Any]:
        """Get status of all agents"""
        return {
            "active_count": len(self.active_agents),
            "agents": [
                {
                    "npc_id": npc_id,
                    "running": not task.done(),
                    "config": self.agent_configs.get(npc_id, {})
                }
                for npc_id, task in self.active_agents.items()
            ]
        }


# Global agent engine instance (singleton)
agent_engine = AgentEngine()
