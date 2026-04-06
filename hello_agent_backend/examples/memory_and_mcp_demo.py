"""
Memory System and MCP Protocol Usage Examples

Demonstrates:
1. Vector memory storage and retrieval
2. Semantic search for NPC memories
3. MCP tool registration and invocation
4. Integration with NPC dialogue system

Run this example:
    python examples/memory_and_mcp_demo.py
"""

import asyncio
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.services.memory_store import VectorMemoryStore
from app.core.mcp_protocol import game_mcp


async def example_1_memory_basics():
    """Example 1: Basic memory operations"""
    print("\n" + "="*60)
    print("Example 1: Basic Memory Operations")
    print("="*60)
    
    store = VectorMemoryStore("data/vector_store")
    
    # Clear old memories for clean demo
    await store.clear_all_memories()
    
    # Add some memories for Pierre
    print("\n📝 Adding memories for Pierre...")
    
    memories_to_add = [
        {
            "npc_id": "pierre",
            "content": "Player gave me a parsnip as a gift today",
            "metadata": {
                "emotion": "happy",
                "importance": 0.9,
                "day": 5,
                "type": "gift_received",
                "item": "parsnip"
            }
        },
        {
            "npc_id": "pierre",
            "content": "Player helped me water my crops when I was sick",
            "metadata": {
                "emotion": "grateful",
                "importance": 0.95,
                "day": 10,
                "type": "favor_received"
            }
        },
        {
            "npc_id": "pierre",
            "content": "Player bought 10 cauliflower seeds from my store",
            "metadata": {
                "emotion": "neutral",
                "importance": 0.4,
                "day": 12,
                "type": "transaction"
            }
        },
        {
            "npc_id": "pierre",
            "content": "Player mentioned they love growing ancient fruit",
            "metadata": {
                "emotion": "interested",
                "importance": 0.7,
                "day": 14,
                "type": "conversation"
            }
        }
    ]
    
    for mem in memories_to_add:
        memory_id = await store.add_memory(
            npc_id=mem["npc_id"],
            content=mem["content"],
            metadata=mem["metadata"]
        )
        print(f"  ✓ Added memory: {memory_id[:8]}... - '{mem['content'][:50]}...'")
    
    print("\n✅ Successfully added 4 memories")


async def example_2_semantic_search():
    """Example 2: Semantic memory search"""
    print("\n" + "="*60)
    print("Example 2: Semantic Memory Search")
    print("="*60)
    
    store = VectorMemoryStore("data/vector_store")
    
    # Search for memories about player helping
    print("\n🔍 Searching for memories about 'player helping'...")
    
    similar_memories = await store.search_similar(
        query="player helped me with something kind",
        npc_id="pierre",
        limit=3,
        min_importance=0.5
    )
    
    print(f"\nFound {len(similar_memories)} relevant memories:")
    for i, mem in enumerate(similar_memories, 1):
        print(f"\n{i}. Importance: {mem.importance:.2f}, Emotion: {mem.emotion}")
        print(f"   Content: {mem.content}")
        print(f"   Day: {mem.day}, Type: {mem.memory_type}")
    
    # Search for gift-related memories
    print("\n\n🔍 Searching for memories about 'gifts'...")
    
    gift_memories = await store.search_similar(
        query="player gave me a present",
        npc_id="pierre",
        limit=2
    )
    
    print(f"\nFound {len(gift_memories)} gift-related memories:")
    for i, mem in enumerate(gift_memories, 1):
        print(f"{i}. {mem.content} (emotion: {mem.emotion})")


async def example_3_memory_stats():
    """Example 3: Memory statistics"""
    print("\n" + "="*60)
    print("Example 3: Memory Statistics")
    print("="*60)
    
    store = VectorMemoryStore("data/vector_store")
    
    stats = await store.get_memory_stats()
    
    print("\n📊 Memory Store Statistics:")
    print(f"  Total memories: {stats['total_memories']}")
    print(f"  Average importance: {stats['average_importance']:.3f}")
    print(f"  Embedding dimension: {stats['embedding_dimension']}")
    
    if 'memories_by_npc' in stats:
        print(f"\n  Memories by NPC:")
        for npc_id, count in stats['memories_by_npc'].items():
            print(f"    - {npc_id}: {count} memories")


async def example_4_mcp_tools():
    """Example 4: MCP tool listing and invocation"""
    print("\n" + "="*60)
    print("Example 4: MCP Tool Registry")
    print("="*60)
    
    # List all registered tools
    print("\n🛠️  Registered MCP Tools:")
    tools = game_mcp.list_tools()
    
    for name, info in tools.items():
        print(f"\n  Tool: {name}")
        print(f"  Description: {info['description']}")
        print(f"  Parameters: {info['parameters']}")
    
    # Call a tool
    print("\n\n🔧 Calling MCP tool: get_npc_info")
    
    response = await game_mcp.handle_request({
        "jsonrpc": "2.0",
        "id": "test-req-1",
        "method": "get_npc_info",
        "params": {"npc_id": "pierre"}
    })
    
    print(f"\nResponse:")
    print(f"  ID: {response['id']}")
    print(f"  Result: {response['result']}")
    print(f"  Error: {response['error']}")
    
    # Call another tool
    print("\n\n🔧 Calling MCP tool: get_world_state")
    
    response = await game_mcp.handle_request({
        "jsonrpc": "2.0",
        "id": "test-req-2",
        "method": "get_world_state",
        "params": {}
    })
    
    print(f"\nWorld State: {response['result']}")


async def example_5_integrated_dialogue():
    """Example 5: Integrated dialogue with memory"""
    print("\n" + "="*60)
    print("Example 5: Integrated Dialogue with Memory")
    print("="*60)
    
    print("\n💬 Simulating NPC dialogue with memory retrieval...")
    print("(This would be called via the API endpoint)")
    
    # Example of what happens in /api/v1/npc/dialogue:
    # 1. Player says something
    player_message = "Hey Pierre! How are you doing today?"
    
    # 2. System retrieves relevant memories
    store = VectorMemoryStore("data/vector_store")
    relevant_memories = await store.search_similar(
        query=player_message,
        npc_id="pierre",
        limit=2
    )
    
    print(f"\nPlayer: {player_message}")
    print(f"\nRetrieved {len(relevant_memories)} relevant memories:")
    for mem in relevant_memories:
        print(f"  - {mem.content} (Day {mem.day})")
    
    # 3. Build prompt with memories (simplified example)
    prompt = f"You are Pierre. Relevant memories: "
    for mem in relevant_memories:
        prompt += f"{mem.content}. "
    prompt += f"\nPlayer says: {player_message}"
    
    print(f"\nGenerated prompt (first 200 chars):")
    print(f"  {prompt[:200]}...")
    
    # 4. LLM would generate response here
    # 5. New conversation stored as memory
    await store.add_memory(
        npc_id="pierre",
        content=f"Conversation with player: '{player_message}'",
        metadata={
            "type": "conversation",
            "day": 15,
            "emotion": "friendly"
        }
    )
    print("\n✓ New conversation stored as memory")


async def main():
    """Run all examples"""
    print("\n" + "="*60)
    print("  Memory System & MCP Protocol Examples")
    print("  Stardew Valley AI Agent")
    print("="*60)
    
    examples = [
        ("Basic Memory Operations", example_1_memory_basics),
        ("Semantic Memory Search", example_2_semantic_search),
        ("Memory Statistics", example_3_memory_stats),
        ("MCP Tool Registry", example_4_mcp_tools),
        ("Integrated Dialogue", example_5_integrated_dialogue),
    ]
    
    for name, func in examples:
        try:
            await func()
        except KeyboardInterrupt:
            print("\n\nUser interrupted")
            break
        except Exception as e:
            print(f"\n❌ Example '{name}' failed: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "="*60)
    print("  Examples Complete!")
    print("="*60 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
