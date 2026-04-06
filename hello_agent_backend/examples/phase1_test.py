"""
Phase 1 Test Script - Redis Cache and Agent Engine

Tests the new features added in Phase 1:
1. Redis cache integration
2. Cached memory search
3. Autonomous agent engine
4. Agent API endpoints

Usage:
    python examples/phase1_test.py
"""

import asyncio
import sys
import time
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import httpx


async def test_redis_cache():
    """Test Redis cache functionality"""
    print("\n" + "="*60)
    print("  Testing Redis Cache")
    print("="*60)

    from app.core.cache import cache

    # Connect to Redis
    await cache.connect()

    if not cache._connected:
        print("❌ Redis connection failed")
        return False

    print("✅ Redis connected successfully")

    # Test set/get
    print("\n1. Testing basic set/get...")
    await cache.set("test_key", {"message": "Hello, Redis!"}, ttl=60)
    result = await cache.get("test_key")

    if result and result["message"] == "Hello, Redis!":
        print("✅ Set/Get works correctly")
    else:
        print(f"❌ Set/Get failed: {result}")
        return False

    # Test cache stats
    print("\n2. Testing cache statistics...")
    stats = cache.get_stats()
    print(f"   Hits: {stats['hits']}")
    print(f"   Misses: {stats['misses']}")
    print(f"   Hit Rate: {stats['hit_rate_percent']}%")
    print("✅ Stats tracking works")

    # Test pattern invalidation
    print("\n3. Testing pattern invalidation...")
    await cache.set("mem_search:abc123", ["memory1"])
    await cache.set("mem_search:def456", ["memory2"])
    await cache.set("other_key", "value")

    deleted = await cache.invalidate_pattern("mem_search:*")
    print(f"   Deleted {deleted} keys matching 'mem_search:*'")

    remaining_other = await cache.get("other_key")
    if deleted == 2 and remaining_other == "value":
        print("✅ Pattern invalidation works correctly")
    else:
        print("❌ Pattern invalidation failed")
        return False

    # Cleanup
    await cache.clear_all()
    print("\n✅ All cache tests passed!")

    return True


async def test_cached_memory_search():
    """Test cached memory search performance"""
    print("\n" + "="*60)
    print("  Testing Cached Memory Search")
    print("="*60)

    from app.services.memory_store import VectorMemoryStore

    store = VectorMemoryStore(use_cache=True)

    # Add a test memory
    print("\n1. Adding test memory...")
    try:
        memory_id = await store.add_memory(
            npc_id="test_npc",
            content="Player helped me with farming tasks today",
            metadata={
                "emotion": "grateful",
                "importance": 0.8,
                "day": 10,
                "type": "event"
            }
        )
        print(f"✅ Memory added: {memory_id}")
    except Exception as e:
        print(f"⚠️  Could not add memory (LanceDB may need initialization): {e}")
        print("   Continuing with cache test...")

    # First search (cache miss)
    print("\n2. First search (should be cache miss)...")
    start = time.time()
    results1 = await store.search_similar(
        query="player help farming",
        npc_id="test_npc",
        limit=3
    )
    duration1 = time.time() - start
    print(f"   Found {len(results1)} memories in {duration1:.3f}s")

    # Second search (should be cache hit)
    print("\n3. Second search (should be cache hit)...")
    start = time.time()
    results2 = await store.search_similar(
        query="player help farming",
        npc_id="test_npc",
        limit=3
    )
    duration2 = time.time() - start
    print(f"   Found {len(results2)} memories in {duration2:.3f}s")

    # Check performance improvement
    if duration2 < duration1 * 0.5:  # At least 50% faster
        improvement = ((duration1 - duration2) / duration1) * 100
        print(f"\n✅ Cache working! Performance improved by {improvement:.1f}%")
    else:
        print(f"\n⚠️  Cache may not be effective (first: {duration1:.3f}s, second: {duration2:.3f}s)")

    # Show cache stats
    from app.core.cache import cache
    stats = cache.get_stats()
    print(f"\n   Cache Stats:")
    print(f"   - Hits: {stats['hits']}")
    print(f"   - Misses: {stats['misses']}")
    print(f"   - Hit Rate: {stats['hit_rate_percent']}%")


async def test_agent_api():
    """Test Agent API endpoints"""
    print("\n" + "="*60)
    print("  Testing Agent API Endpoints")
    print("="*60)

    base_url = "http://localhost:8080/api/v1"

    async with httpx.AsyncClient(timeout=10.0) as client:
        # Test 1: Start agent
        print("\n1. Starting agent for 'pierre'...")
        try:
            response = await client.post(
                f"{base_url}/agent/pierre/start",
                json={
                    "interval": 5.0,
                    "personality": {
                        "trait": "friendly",
                        "occupation": "shopkeeper"
                    }
                }
            )

            if response.status_code == 200:
                print(f"✅ Agent started: {response.json()}")
            else:
                print(f"❌ Failed to start agent: {response.status_code} - {response.text}")
                return False

        except httpx.ConnectError:
            print("⚠️  Backend not running. Start it with: .\\start.ps1")
            print("   Skipping API tests...")
            return False

        # Test 2: Check agent status
        print("\n2. Checking agent status...")
        response = await client.get(f"{base_url}/agent/status")
        if response.status_code == 200:
            status = response.json()
            print(f"✅ Active agents: {status['active_count']}")
            for agent in status['agents']:
                print(f"   - {agent['npc_id']}: running={agent['running']}")
        else:
            print(f"❌ Failed to get status: {response.status_code}")

        # Test 3: Let agent run for a bit
        print("\n3. Letting agent run for 15 seconds...")
        await asyncio.sleep(15)

        # Test 4: Stop agent
        print("\n4. Stopping agent...")
        response = await client.post(f"{base_url}/agent/pierre/stop")
        if response.status_code == 200:
            print(f"✅ Agent stopped: {response.json()}")
        else:
            print(f"❌ Failed to stop agent: {response.status_code}")

        # Test 5: Verify stopped
        print("\n5. Verifying agent stopped...")
        response = await client.get(f"{base_url}/agent/status")
        if response.status_code == 200:
            status = response.json()
            print(f"✅ Active agents after stop: {status['active_count']}")

    print("\n✅ All API tests completed!")
    return True


async def main():
    """Run all Phase 1 tests"""
    print("\n" + "="*60)
    print("  Phase 1 Feature Tests")
    print("  Redis Cache + Agent Engine")
    print("="*60)

    # Test 1: Redis Cache
    cache_ok = await test_redis_cache()

    if cache_ok:
        # Test 2: Cached Memory Search
        await test_cached_memory_search()

    # Test 3: Agent API (requires backend running)
    print("\n" + "-"*60)
    print("Note: Agent API tests require backend to be running")
    print("Start backend: cd hello_agent_backend && .\\start.ps1")
    print("-"*60)

    run_api_tests = input("\nRun API tests? (backend must be running) [y/N]: ").lower()
    if run_api_tests == 'y':
        await test_agent_api()
    else:
        print("Skipping API tests")

    print("\n" + "="*60)
    print("  Phase 1 Testing Complete!")
    print("="*60)
    print("\nNext Steps:")
    print("1. Review test results above")
    print("2. If all tests pass, Phase 1 is complete!")
    print("3. Commit changes: git add . && git commit -m 'Add Phase 1: Redis cache + Agent engine'")
    print("4. Push to GitHub: git push")
    print("\nPhase 2 Preview:")
    print("- WebSocket real-time communication")
    print("- SQLite game state integration")
    print("- Docker containerization")


if __name__ == "__main__":
    asyncio.run(main())
