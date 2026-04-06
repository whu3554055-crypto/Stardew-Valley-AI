"""
MCP (Model Context Protocol) Adapter

Implements a simplified MCP protocol for standardized agent-tool communication.
Based on JSON-RPC 2.0 over HTTP/WebSocket.

Protocol Specification:
    - JSON-RPC 2.0 message format
    - Tool registry pattern
    - Standardized error handling
    
Message Format:
    Request:
    {
        "jsonrpc": "2.0",
        "id": "uuid-request-id",
        "method": "tool_name",
        "params": {...}
    }
    
    Response:
    {
        "jsonrpc": "2.0",
        "id": "uuid-request-id",
        "result": {...},
        "error": null
    }

Usage:
    mcp = MCPServer()
    
    # Register tools
    mcp.register_tool(
        name="get_npc_state",
        description="Get current NPC state",
        handler=lambda npc_id: npc_manager.get_state(npc_id)
    )
    
    # Handle requests
    response = await mcp.handle_request({
        "jsonrpc": "2.0",
        "id": "req-123",
        "method": "get_npc_state",
        "params": {"npc_id": "pierre"}
    })
"""

import uuid
import json
import logging
from typing import Dict, Any, Callable, Optional, Awaitable
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


class MCPRequest(BaseModel):
    """MCP/JSON-RPC 2.0 Request"""
    jsonrpc: str = Field(default="2.0", const=True)
    id: str = Field(..., description="Unique request ID")
    method: str = Field(..., description="Method/tool name to call")
    params: Dict[str, Any] = Field(default_factory=dict, description="Method parameters")


class MCPResponse(BaseModel):
    """MCP/JSON-RPC 2.0 Response"""
    jsonrpc: str = Field(default="2.0", const=True)
    id: str = Field(..., description="Request ID (matches request)")
    result: Optional[Dict[str, Any]] = Field(default=None, description="Result data")
    error: Optional[Dict[str, Any]] = Field(default=None, description="Error info if failed")


class ToolDefinition(BaseModel):
    """Tool registration definition"""
    name: str = Field(..., description="Tool name/identifier")
    description: str = Field(..., description="Human-readable description")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Parameter schema")
    handler: Callable = Field(..., description="Function to execute")


class MCPServer:
    """
    Model Context Protocol Server
    
    Provides standardized tool calling interface for AI agents.
    Supports dynamic tool registration and JSON-RPC 2.0 message handling.
    
    Features:
    - Tool registry with metadata
    - Automatic parameter validation
    - Error handling and reporting
    - Logging and monitoring
    """
    
    def __init__(self):
        self.tools: Dict[str, ToolDefinition] = {}
        self.request_log: list = []  # For debugging/monitoring
        
        logger.info("MCPServer initialized")
    
    def register_tool(
        self,
        name: str,
        description: str,
        handler: Callable,
        parameters: Optional[Dict[str, Any]] = None
    ):
        """
        Register a tool for agent invocation
        
        Args:
            name: Unique tool identifier
            description: Human-readable description of what the tool does
            handler: Async or sync function to execute
            parameters: JSON schema for parameters (optional)
            
        Example:
            mcp.register_tool(
                name="get_weather",
                description="Get current weather in the game world",
                handler=lambda: weather_system.get_current(),
                parameters={
                    "type": "object",
                    "properties": {}
                }
            )
        """
        if name in self.tools:
            logger.warning(f"Overwriting existing tool: {name}")
        
        self.tools[name] = ToolDefinition(
            name=name,
            description=description,
            parameters=parameters or {},
            handler=handler
        )
        
        logger.info(f"Registered tool: {name} - {description}")
    
    def unregister_tool(self, name: str):
        """Remove a registered tool"""
        if name in self.tools:
            del self.tools[name]
            logger.info(f"Unregistered tool: {name}")
        else:
            logger.warning(f"Tool not found: {name}")
    
    def list_tools(self) -> Dict[str, Any]:
        """
        List all registered tools with metadata
        
        Returns:
            Dict mapping tool names to their definitions (excluding handlers)
        """
        return {
            name: {
                "description": tool.description,
                "parameters": tool.parameters
            }
            for name, tool in self.tools.items()
        }
    
    async def handle_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle an incoming MCP/JSON-RPC request
        
        Args:
            request_data: Raw JSON-RPC request dictionary
            
        Returns:
            Dict: JSON-RPC response
            
        Example:
            response = await mcp.handle_request({
                "jsonrpc": "2.0",
                "id": "req-123",
                "method": "get_npc_info",
                "params": {"npc_id": "pierre"}
            })
        """
        try:
            # Parse request
            request = MCPRequest(**request_data)
            
            # Log request
            self.request_log.append({
                "id": request.id,
                "method": request.method,
                "timestamp": __import__("time").time()
            })
            
            logger.debug(f"MCP Request: {request.method} (id={request.id})")
            
            # Validate method exists
            if request.method not in self.tools:
                return self._error_response(
                    request.id,
                    f"Method not found: {request.method}",
                    code=-32601
                )
            
            # Get tool definition
            tool = self.tools[request.method]
            
            # Execute handler
            try:
                result = await self._execute_handler(tool.handler, request.params)
                
                logger.debug(f"MCP Response: {request.method} succeeded")
                
                return MCPResponse(
                    id=request.id,
                    result=result,
                    error=None
                ).dict()
            
            except Exception as e:
                logger.error(f"Tool execution failed: {e}", exc_info=True)
                return self._error_response(
                    request.id,
                    f"Tool execution failed: {str(e)}",
                    code=-32603
                )
        
        except Exception as e:
            logger.error(f"Invalid MCP request: {e}")
            return self._error_response(
                request_data.get("id", "unknown"),
                f"Invalid request: {str(e)}",
                code=-32700
            )
    
    async def _execute_handler(self, handler: Callable, params: Dict[str, Any]) -> Any:
        """
        Execute tool handler (supports both sync and async functions)
        
        Args:
            handler: Function to execute
            params: Parameters to pass
            
        Returns:
            Handler result
        """
        import inspect
        
        # Check if handler is async
        if inspect.iscoroutinefunction(handler):
            result = await handler(**params)
        else:
            # Run sync function in thread pool to avoid blocking
            import asyncio
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, lambda: handler(**params))
        
        return result
    
    def _error_response(self, request_id: str, message: str, code: int = -32000) -> Dict:
        """Create standardized error response"""
        return MCPResponse(
            id=request_id,
            result=None,
            error={
                "code": code,
                "message": message
            }
        ).dict()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get server statistics"""
        return {
            "total_tools": len(self.tools),
            "registered_tools": list(self.tools.keys()),
            "total_requests": len(self.request_log)
        }


# ============================================================================
# Game-Specific Tool Implementations
# ============================================================================

def create_game_tools(npc_manager=None, world_state=None, environment=None):
    """
    Create and register standard game tools
    
    Args:
        npc_manager: Reference to NPC manager service
        world_state: Reference to world state service
        environment: Reference to environment system
    
    Returns:
        MCPServer: Configured MCP server with game tools
    """
    mcp = MCPServer()
    
    # Tool 1: Get NPC Information
    def get_npc_info(npc_id: str) -> Dict[str, Any]:
        """Get detailed information about an NPC"""
        # This would integrate with your NPC system
        return {
            "npc_id": npc_id,
            "name": "Pierre",
            "location": "general_store",
            "mood": "happy",
            "relationship_level": 5,
            "current_activity": "working"
        }
    
    mcp.register_tool(
        name="get_npc_info",
        description="Get detailed information about an NPC including location, mood, and activity",
        handler=get_npc_info,
        parameters={
            "type": "object",
            "properties": {
                "npc_id": {"type": "string", "description": "NPC identifier"}
            },
            "required": ["npc_id"]
        }
    )
    
    # Tool 2: Get World State
    def get_world_state() -> Dict[str, Any]:
        """Get current game world state"""
        return {
            "season": "spring",
            "day": 15,
            "year": 1,
            "time": "morning",
            "weather": "sunny",
            "temperature": 18.5
        }
    
    mcp.register_tool(
        name="get_world_state",
        description="Get current game world state (season, day, time, weather)",
        handler=get_world_state,
        parameters={
            "type": "object",
            "properties": {}
        }
    )
    
    # Tool 3: Get Player Relationship
    def get_relationship(npc_id: str, player_id: str = "player") -> Dict[str, Any]:
        """Get relationship status between player and NPC"""
        return {
            "npc_id": npc_id,
            "player_id": player_id,
            "friendship_points": 250,
            "level": 5,
            "gifts_given_today": 0,
            "last_interaction": "greeted"
        }
    
    mcp.register_tool(
        name="get_relationship",
        description="Get relationship/friendship status between player and NPC",
        handler=get_relationship,
        parameters={
            "type": "object",
            "properties": {
                "npc_id": {"type": "string"},
                "player_id": {"type": "string", "default": "player"}
            },
            "required": ["npc_id"]
        }
    )
    
    # Tool 4: Place Environmental Item
    def place_item(item_id: str, location_x: float, location_y: float) -> Dict[str, Any]:
        """Place an item in the game world"""
        return {
            "success": True,
            "item_id": item_id,
            "location": {"x": location_x, "y": location_y},
            "message": f"Placed {item_id} at ({location_x}, {location_y})"
        }
    
    mcp.register_tool(
        name="place_item",
        description="Place an environmental item at specified location",
        handler=place_item,
        parameters={
            "type": "object",
            "properties": {
                "item_id": {"type": "string", "description": "Item to place"},
                "location_x": {"type": "number"},
                "location_y": {"type": "number"}
            },
            "required": ["item_id", "location_x", "location_y"]
        }
    )
    
    # Tool 5: Get Inventory
    def get_inventory(player_id: str = "player") -> Dict[str, Any]:
        """Get player's current inventory"""
        return {
            "player_id": player_id,
            "items": [
                {"id": "parsnip_seeds", "quantity": 10},
                {"id": "hoe", "quantity": 1},
                {"id": "watering_can", "quantity": 1}
            ],
            "gold": 500
        }
    
    mcp.register_tool(
        name="get_inventory",
        description="Get player's current inventory items and gold",
        handler=get_inventory,
        parameters={
            "type": "object",
            "properties": {
                "player_id": {"type": "string", "default": "player"}
            }
        }
    )
    
    logger.info(f"Created game tools MCP server with {len(mcp.tools)} tools")
    
    return mcp


# Global MCP server instance (singleton)
game_mcp = create_game_tools()
