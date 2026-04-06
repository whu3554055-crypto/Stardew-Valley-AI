import asyncio
from app.core.cache import cache

async def test():
    await cache.connect()
    print("Redis connected:", cache._connected)

    await cache.set('test', {'value': 123}, ttl=60)
    result = await cache.get('test')
    print("Set/Get test:", "PASS" if result['value'] == 123 else "FAIL")

    stats = cache.get_stats()
    print("Cache stats - hits:", stats['hits'], "misses:", stats['misses'])

    await cache.clear_all()
    print("All tests PASSED!")

asyncio.run(test())
