# Godot Integration Guide - hello-agent Cyber Town

This guide explains how to integrate the hello-agent backend (Phase 1 & 2 features) with your Godot frontend using WebSocket real-time communication and REST API calls.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [WebSocket Real-Time Communication](#websocket-real-time-communication)
- [Autonomous Agent Control](#autonomous-agent-control)
- [Cache Management](#cache-management)
- [Event Subscription System](#event-subscription-system)
- [API Reference](#api-reference)
- [Sample Scenes](#sample-scenes)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Godot integration provides:

- **Real-time bidirectional communication** via WebSocket (JSON-RPC 2.0 / MCP protocol)
- **Autonomous NPC agent control** (start/stop AI decision loops)
- **Redis cache monitoring** (performance stats, cache clearing)
- **Event-driven architecture** (subscribe to NPC dialogue, agent actions, world events)
- **Automatic reconnection** with exponential backoff

### Prerequisites

- Godot Engine 4.2+
- Backend server running on `http://localhost:8080` (REST API + WebSocket)
- Redis 7.x running on `localhost:6379`

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Godot Frontend                      │
│  ┌──────────────────┐    ┌──────────────────────┐   │
│  │ AIAgentManager   │◄──►│  WebSocketClient     │   │
│  │ (Singleton)      │    │  (Singleton)         │   │
│  └────────┬─────────┘    └──────────┬───────────┘   │
│           │                         │                │
│           ▼                         ▼                │
│  ┌──────────────────────────────────────────────┐   │
│  │         Game Scenes & NPCs                   │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   │
          WebSocket (ws://localhost:8080/ws/)
          HTTP REST (http://localhost:8080/api/v1/)
                   │
┌──────────────────▼──────────────────────────────────┐
│              Python Backend                          │
│  FastAPI + Redis + LanceDB + SQLite                 │
└─────────────────────────────────────────────────────┘
```

---

## Quick Start

### Step 1: Initialize in Your Game

Add this to your main scene's `_ready()` function:

```gdscript
extends Node

func _ready():
    # Initialize AI Agent Manager (autoloaded as singleton)
    var ai_manager = get_node("/root/AIAgentManager")

    # Setup WebSocket for real-time communication
    ai_manager.setup_websocket("player1")

    # Subscribe to events you care about
    ai_manager.subscribe_to_events(["npc_dialogue", "agent_action", "world_event"])

    print("Godot hello-agent integration initialized!")
```

### Step 2: Start Autonomous NPCs

```gdscript
# Start an autonomous agent for an NPC
var npc_id = "villager_001"
var personality = {
    "traits": ["friendly", "curious", "helpful"],
    "goals": ["explore", "socialize", "gather_resources"]
}

ai_manager.start_autonomous_agent(npc_id, interval=10.0, personality=personality)
```

### Step 3: Handle Events

Connect signals in your scene:

```gdscript
func _on_npc_dialogue(npc_id: String, dialogue: String, emotion: String):
    print("NPC %s says: %s (emotion: %s)" % [npc_id, dialogue, emotion])
    # Update your dialogue UI here

func _on_agent_action(npc_id: String, action: String, result: Dictionary):
    print("NPC %s performed: %s" % [npc_id, action])
    # Update game state based on action

func _on_world_event(event_type: String, data: Dictionary):
    print("World event: %s" % event_type)
    # Handle world changes
```

---

## WebSocket Real-Time Communication

### Connection Management

The `WebSocketClient` singleton handles connection lifecycle automatically:

```gdscript
# Check connection status
var ws_client = get_node("/root/WebSocketClient")
if ws_client.connected:
    print("Connected to backend!")
else:
    print("Connecting...")

# Manual reconnect if needed
ws_client.connect_to_server()
```

### Sending MCP Requests

Use JSON-RPC 2.0 format for structured requests:

```gdscript
# Example: Get NPC info via WebSocket
var success = ai_manager.send_mcp_request(
    method="get_npc_info",
    params={"npc_id": "villager_001"},
    request_id="req_001"
)

if success:
    print("Request sent successfully")
```

### Receiving Responses

Responses arrive via signals:

```gdscript
# Connect to response signal
ws_client.mcp_response_received.connect(_on_mcp_response)

func _on_mcp_response(response: Dictionary):
    if response.get("error"):
        print("Error: ", response.error.message)
    else:
        print("Result: ", response.result)
```

---

## Autonomous Agent Control

### Starting Agents

Start an autonomous decision-making loop for any NPC:

```gdscript
# Basic usage
ai_manager.start_autonomous_agent("villager_001")

# With custom interval (seconds between decisions)
ai_manager.start_autonomous_agent("villager_001", interval=5.0)

# With personality configuration
var personality = {
    "traits": ["aggressive", "territorial"],
    "goals": ["defend_area", "patrol"],
    "schedule": {
        "morning": "patrol_north",
        "afternoon": "guard_gate",
        "evening": "return_home"
    }
}
ai_manager.start_autonomous_agent("guard_001", interval=15.0, personality=personality)
```

**What happens:**
1. Backend starts async loop: Perception → Decision → Action → Memory
2. NPC makes autonomous decisions every `interval` seconds
3. Actions are sent to Godot via WebSocket in real-time
4. Results are stored in vector memory for future context

### Stopping Agents

```gdscript
# Stop a specific NPC's agent
ai_manager.stop_autonomous_agent("villager_001")

# Stop all agents (e.g., when quitting game)
for npc_id in active_agents:
    ai_manager.stop_autonomous_agent(npc_id)
```

### Checking Agent Status

```gdscript
# Check if an NPC has an active agent
var url = "%s/api/v1/agent/%s/status" % [api_config.backend_url, npc_id]
var http = HTTPRequest.new()
add_child(http)
http.request(url)
var response = await http.request_completed
var status = JSON.parse_string(response[3].get_string_from_utf8())

if status.is_running:
    print("Agent is running, uptime: %ds" % status.uptime_seconds)
```

---

## Cache Management

Monitor and control Redis cache performance:

### Getting Cache Stats

```gdscript
# Retrieve cache statistics
var stats = await ai_manager.get_cache_stats()

print("Cache hits: ", stats.hits)
print("Cache misses: ", stats.misses)
print("Hit rate: %.2f%%" % (stats.hit_rate * 100))
print("Memory usage: ", stats.memory_human)
print("Key count: ", stats.key_count)
```

**Example output:**
```json
{
    "hits": 1523,
    "misses": 234,
    "hit_rate": 0.867,
    "memory_used_bytes": 2458624,
    "memory_human": "2.34 MB",
    "key_count": 156,
    "avg_ttl_remaining": 45.2
}
```

### Clearing Cache

```gdscript
# Clear server-side cache (Redis)
await ai_manager.clear_cache()

# Clear local Godot cache (in-memory dictionaries)
ai_manager._clear_local_cache()

# Both at once
await ai_manager.clear_cache(clear_local=true)
```

### When to Clear Cache

- After major game state changes (quest completion, relationship updates)
- When debugging stale data issues
- Before saving/loading game to ensure consistency

---

## Event Subscription System

Subscribe to specific event types to receive real-time updates:

### Available Event Types

| Event Type | Description | Data Structure |
|------------|-------------|----------------|
| `npc_dialogue` | NPC generates dialogue | `{npc_id, dialogue, emotion, target}` |
| `agent_action` | NPC performs action | `{npc_id, action, result, timestamp}` |
| `world_event` | World state changes | `{event_type, location, affected_npcs}` |
| `relationship_change` | Friendship updates | `{npc_id, player_id, old_level, new_level}` |
| `quest_update` | Quest progress | `{quest_id, npc_id, status, progress}` |

### Subscribing to Events

```gdscript
# Subscribe to specific events
ai_manager.subscribe_to_events(["npc_dialogue", "agent_action"])

# Subscribe to all events
ai_manager.subscribe_to_events(["*"])

# Unsubscribe from specific event
ai_manager.unsubscribe_from_events(["world_event"])
```

### Handling Events

Connect signals in your scene's `_ready()`:

```gdscript
func _ready():
    var ai_manager = get_node("/root/AIAgentManager")

    # Connect all event handlers
    ai_manager.npc_dialogue_received.connect(_on_npc_dialogue)
    ai_manager.agent_action_received.connect(_on_agent_action)
    ai_manager.world_event_received.connect(_on_world_event)
    ai_manager.relationship_changed.connect(_on_relationship_change)
    ai_manager.quest_updated.connect(_on_quest_update)

# Example handlers
func _on_npc_dialogue(npc_id: String, dialogue: String, emotion: String):
    # Update dialogue box UI
    $DialogueBox.show_dialogue(npc_id, dialogue, emotion)

    # Play emotion-based animation
    var npc = get_node("NPCs/" + npc_id)
    npc.play_emotion(emotion)

func _on_agent_action(npc_id: String, action: String, result: Dictionary):
    # Execute action in game world
    match action:
        "move_to":
            var npc = get_node("NPCs/" + npc_id)
            npc.move_to(result.location)
        "give_item":
            $Inventory.add_item(result.item_id, result.quantity)
        "start_quest":
            $QuestLog.add_quest(result.quest_data)

func _on_world_event(event_type: String, data: Dictionary):
    match event_type:
        "weather_change":
            $WeatherSystem.set_weather(data.weather_type)
        "time_advance":
            $TimeManager.advance_time(data.hours)
        "location_unlock":
            $Map.unlock_area(data.location_id)

func _on_relationship_change(npc_id: String, player_id: String, old_level: int, new_level: int):
    print("Relationship with %s changed: %d → %d" % [npc_id, old_level, new_level])
    $RelationshipUI.update_friendship(npc_id, new_level)

func _on_quest_update(quest_id: String, npc_id: String, status: String, progress: Dictionary):
    $QuestLog.update_progress(quest_id, status, progress)
```

---

## API Reference

### AIAgentManager Methods

#### `setup_websocket(client_id: String = "player1") -> void`

Initialize WebSocket connection for real-time communication.

**Parameters:**
- `client_id`: Unique identifier for this client (default: "player1")

**Example:**
```gdscript
ai_manager.setup_websocket("player1")
```

---

#### `start_autonomous_agent(npc_id: String, interval: float = 10.0, personality: Dictionary = {}) -> void`

Start autonomous decision-making agent for an NPC.

**Parameters:**
- `npc_id`: Unique NPC identifier
- `interval`: Seconds between decision cycles (default: 10.0)
- `personality`: Optional personality traits and goals

**Example:**
```gdscript
ai_manager.start_autonomous_agent("villager_001", 15.0, {
    "traits": ["friendly"],
    "goals": ["socialize"]
})
```

---

#### `stop_autonomous_agent(npc_id: String) -> void`

Stop autonomous agent for an NPC.

**Parameters:**
- `npc_id`: NPC identifier to stop

**Example:**
```gdscript
ai_manager.stop_autonomous_agent("villager_001")
```

---

#### `get_cache_stats() -> Dictionary`

Get Redis cache statistics.

**Returns:**
```gdscript
{
    "hits": 1523,
    "misses": 234,
    "hit_rate": 0.867,
    "memory_used_bytes": 2458624,
    "memory_human": "2.34 MB",
    "key_count": 156
}
```

**Example:**
```gdscript
var stats = await ai_manager.get_cache_stats()
print("Hit rate: %.2f%%" % (stats.hit_rate * 100))
```

---

#### `clear_cache(clear_local: bool = false) -> void`

Clear cache (server-side and optionally local).

**Parameters:**
- `clear_local`: Also clear local Godot cache (default: false)

**Example:**
```gdscript
await ai_manager.clear_cache(clear_local=true)
```

---

#### `subscribe_to_events(event_types: Array) -> void`

Subscribe to WebSocket events.

**Parameters:**
- `event_types`: Array of event type strings (see table above)

**Example:**
```gdscript
ai_manager.subscribe_to_events(["npc_dialogue", "agent_action"])
```

---

#### `unsubscribe_from_events(event_types: Array) -> void`

Unsubscribe from WebSocket events.

**Parameters:**
- `event_types`: Array of event type strings to unsubscribe

**Example:**
```gdscript
ai_manager.unsubscribe_from_events(["world_event"])
```

---

#### `send_mcp_request(method: String, params: Dictionary, request_id: String = "") -> bool`

Send MCP (JSON-RPC 2.0) request over WebSocket.

**Parameters:**
- `method`: MCP method name (e.g., "get_npc_info", "search_memories")
- `params`: Method parameters
- `request_id`: Optional request ID for tracking

**Returns:** `true` if request sent successfully

**Example:**
```gdscript
var success = ai_manager.send_mcp_request(
    "search_memories",
    {"query": "town festival", "npc_id": "villager_001"},
    "req_123"
)
```

---

### WebSocketClient Signals

| Signal | Parameters | Description |
|--------|-----------|-------------|
| `connection_status_changed` | `(status: String)` | Emitted when connection state changes |
| `npc_dialogue_received` | `(npc_id, dialogue, emotion)` | NPC generated dialogue |
| `agent_action_received` | `(npc_id, action, result)` | NPC performed action |
| `world_event_received` | `(event_type, data)` | World state changed |
| `mcp_response_received` | `(response: Dictionary)` | MCP request response |

---

## Sample Scenes

### Example 1: NPC Dialogue Scene

```gdscript
# scenes/npc_dialogue_scene.gd
extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var npc_sprite = $NPCSprite

var current_npc_id: String

func _ready():
    var ai_manager = get_node("/root/AIAgentManager")
    ai_manager.npc_dialogue_received.connect(_on_npc_dialogue)

func start_conversation(npc_id: String):
    current_npc_id = npc_id

    # Request NPC to generate opening dialogue
    ai_manager.send_mcp_request(
        "generate_dialogue",
        {
            "npc_id": npc_id,
            "context": "player_greeting",
            "emotion_hint": "neutral"
        },
        "dialogue_req_" + npc_id
    )

func _on_npc_dialogue(npc_id: String, dialogue: String, emotion: String):
    if npc_id != current_npc_id:
        return  # Ignore dialogue from other NPCs

    # Update UI
    dialogue_box.show_dialogue(dialogue, emotion)

    # Update sprite expression
    npc_sprite.set_emotion(emotion)

    # Store in conversation history
    conversation_history.append({
        "speaker": npc_id,
        "text": dialogue,
        "emotion": emotion,
        "timestamp": Time.get_unix_time_from_system()
    })
```

---

### Example 2: Autonomous NPC Controller

```gdscript
# scenes/autonomous_npc_controller.gd
extends Node2D

var managed_npcs: Array = []

func _ready():
    var ai_manager = get_node("/root/AIAgentManager")

    # Setup WebSocket
    ai_manager.setup_websocket("player1")
    ai_manager.subscribe_to_events(["agent_action", "world_event"])

    # Connect signals
    ai_manager.agent_action_received.connect(_on_agent_action)
    ai_manager.world_event_received.connect(_on_world_event)

    # Start autonomous agents for all NPCs in scene
    for npc in get_tree().get_nodes_in_group("npcs"):
        var npc_id = npc.name
        var personality = npc.get_personality()

        ai_manager.start_autonomous_agent(npc_id, interval=10.0, personality=personality)
        managed_npcs.append(npc_id)

func _on_agent_action(npc_id: String, action: String, result: Dictionary):
    var npc = get_node_or_null("NPCs/" + npc_id)
    if not npc:
        return

    # Execute action in game world
    match action:
        "move_to":
            npc.move_to_position(result.position)
        "interact_with":
            var target = get_node_or_null("Objects/" + result.target_id)
            if target:
                npc.interact(target)
        "say_something":
            # Trigger dialogue system
            npc.start_dialogue(result.dialogue)
        "use_item":
            npc.use_item(result.item_id)

func _on_world_event(event_type: String, data: Dictionary):
    match event_type:
        "night_fall":
            # Send all NPCs home
            for npc_id in managed_npcs:
                ai_manager.send_mcp_request(
                    "send_npc_home",
                    {"npc_id": npc_id}
                )
        "festival_start":
            # Gather NPCs at festival location
            for npc_id in managed_npcs:
                ai_manager.send_mcp_request(
                    "send_npc_to_event",
                    {"npc_id": npc_id, "location": "town_square"}
                )

func _exit_tree():
    # Clean up: stop all agents
    var ai_manager = get_node("/root/AIAgentManager")
    for npc_id in managed_npcs:
        ai_manager.stop_autonomous_agent(npc_id)
```

---

### Example 3: Cache Monitor UI

```gdscript
# ui/cache_monitor.gd
extends PanelContainer

@onready var hit_rate_label = $VBoxContainer/HitRateLabel
@onready var memory_label = $VBoxContainer/MemoryLabel
@onready var key_count_label = $VBoxContainer/KeyCountLabel
@onready var clear_button = $VBoxContainer/ClearButton

var update_timer: Timer

func _ready():
    clear_button.pressed.connect(_on_clear_cache_pressed)

    # Update stats every 5 seconds
    update_timer = Timer.new()
    update_timer.wait_time = 5.0
    update_timer.timeout.connect(_update_stats)
    add_child(update_timer)
    update_timer.start()

    _update_stats()  # Initial update

func _update_stats():
    var ai_manager = get_node("/root/AIAgentManager")
    var stats = await ai_manager.get_cache_stats()

    hit_rate_label.text = "Hit Rate: %.1f%%" % (stats.hit_rate * 100)
    memory_label.text = "Memory: %s" % stats.memory_human
    key_count_label.text = "Keys: %d" % stats.key_count

    # Color-code hit rate
    if stats.hit_rate > 0.8:
        hit_rate_label.modulate = Color.GREEN
    elif stats.hit_rate > 0.5:
        hit_rate_label.modulate = Color.YELLOW
    else:
        hit_rate_label.modulate = Color.RED

func _on_clear_cache_pressed():
    var ai_manager = get_node("/root/AIAgentManager")
    await ai_manager.clear_cache()
    _update_stats()  # Refresh display
```

---

## Troubleshooting

### Issue: WebSocket Connection Fails

**Symptoms:**
- Console shows: `[WebSocketClient] Connection failed, status: 3`
- `connected` property remains `false`

**Solutions:**
1. Verify backend is running:
   ```bash
   curl http://localhost:8080/api/v1/health
   ```

2. Check WebSocket endpoint:
   ```bash
   wscat -c ws://localhost:8080/ws/
   ```

3. Ensure correct URL in `websocket_client.gd`:
   ```gdscript
   server_url = "ws://localhost:8080/ws/"  # Not https!
   ```

4. Check firewall settings (Windows may block port 8080)

---

### Issue: Agent Doesn't Start

**Symptoms:**
- `start_autonomous_agent()` returns without error but NPC doesn't act
- No WebSocket messages received

**Solutions:**
1. Check backend logs for errors:
   ```bash
   docker logs hello-agent-backend
   ```

2. Verify NPC exists in database:
   ```bash
   curl http://localhost:8080/api/v1/npcs/villager_001
   ```

3. Check LLM provider is configured:
   ```bash
   # In .env file
   LLM_PROVIDER=ollama  # or qwen, gemini
   OLLAMA_BASE_URL=http://host.docker.internal:11434
   ```

4. Test agent endpoint directly:
   ```bash
   curl -X POST http://localhost:8080/api/v1/agent/villager_001/start \
     -H "Content-Type: application/json" \
     -d '{"interval": 10.0}'
   ```

---

### Issue: Stale Data / Cache Not Updating

**Symptoms:**
- NPC dialogue references outdated information
- Relationship levels don't reflect recent changes

**Solutions:**
1. Clear cache after major state changes:
   ```gdscript
   # After completing a quest
   await ai_manager.clear_cache()
   ```

2. Use shorter TTL for frequently-changing data:
   ```python
   # In backend cache configuration
   @cache.cached(key_prefix="npc_state", ttl=30)  # 30 seconds instead of 300
   ```

3. Invalidate specific patterns:
   ```bash
   curl -X POST http://localhost:8080/api/v1/cache/invalidate \
     -d '{"pattern": "npc_state:*"}'
   ```

---

### Issue: High Memory Usage

**Symptoms:**
- Redis memory grows continuously
- Godot client slows down over time

**Solutions:**
1. Monitor Redis memory:
   ```bash
   redis-cli INFO memory
   ```

2. Set max memory limit in `redis.conf`:
   ```conf
   maxmemory 256mb
   maxmemory-policy allkeys-lru
   ```

3. Clear local Godot cache periodically:
   ```gdscript
   ai_manager._clear_local_cache()
   ```

4. Reduce vector memory retention:
   ```python
   # In backend config
   VECTOR_MEMORY_TTL = 3600  # 1 hour instead of 24 hours
   ```

---

### Issue: Message Ordering Problems

**Symptoms:**
- Actions execute out of order
- Dialogue appears before movement completes

**Solutions:**
1. Use request IDs to track message order:
   ```gdscript
   var req_id = "move_%d" % Time.get_ticks_msec()
   ai_manager.send_mcp_request("move_to", {...}, req_id)
   ```

2. Implement action queue in Godot:
   ```gdscript
   var action_queue: Array = []

   func _on_agent_action(npc_id, action, result):
       action_queue.append({"action": action, "result": result})
       if action_queue.size() == 1:
           _process_next_action()

   func _process_next_action():
       if action_queue.is_empty():
           return
       var action = action_queue.pop_front()
       # Execute action...
       # On completion:
       _process_next_action()  # Process next in queue
   ```

---

## Best Practices

### 1. Connection Lifecycle

```gdscript
# Good: Connect once in main scene, reuse everywhere
func _ready():
    ai_manager.setup_websocket("player1")

# Bad: Creating multiple WebSocket clients
func some_function():
    var ws = WebSocketClient.new()  # Don't do this!
```

### 2. Error Handling

```gdscript
# Good: Handle connection failures gracefully
func send_safe_request(method, params):
    var ws = get_node("/root/WebSocketClient")
    if not ws.connected:
        print("Not connected, queuing request")
        pending_requests.append({"method": method, "params": params})
        return

    ai_manager.send_mcp_request(method, params)
```

### 3. Resource Cleanup

```gdscript
# Good: Stop agents when leaving scene
func _exit_tree():
    for npc_id in active_npcs:
        ai_manager.stop_autonomous_agent(npc_id)
```

### 4. Performance Monitoring

```gdscript
# Good: Monitor cache hit rate to detect issues
func _on_cache_stats_update(stats):
    if stats.hit_rate < 0.5:
        print("WARNING: Low cache hit rate, consider increasing TTL")
```

---

## Next Steps

After integrating these features:

1. **Test thoroughly**: Use the test suite in `tests/` directory
2. **Monitor performance**: Watch Redis memory and cache hit rates
3. **Customize personalities**: Experiment with different NPC traits
4. **Extend events**: Add custom event types for your game mechanics
5. **Optimize intervals**: Adjust agent decision frequency based on NPC importance

For advanced topics (custom MCP tools, vector memory tuning, multi-player sync), see:
- `hello_agent_backend/docs/mcp_protocol.md`
- `hello_agent_backend/docs/vector_memory.md`
- `NEXT_STEPS_ROADMAP.md`

---

## Support

If you encounter issues:

1. Check backend logs: `docker logs hello-agent-backend`
2. Verify Redis is running: `redis-cli ping`
3. Review this guide's troubleshooting section
4. Check GitHub issues: https://github.com/whu3554055-crypto/stardew_valley/issues

Happy coding! 🎮
