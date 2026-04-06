"""
Pytest configuration and shared fixtures.

This file ensures proper module imports and provides shared test utilities.
"""

import sys
import os
from pathlib import Path

# Add the app directory to Python path for imports BEFORE any other imports
project_root = Path(__file__).resolve().parent.parent
app_dir = project_root / "app"

# Ensure paths are added at the very beginning
for path in [str(app_dir), str(project_root)]:
    if path not in sys.path:
        sys.path.insert(0, path)

# Verify imports work
try:
    from core.cache import CacheManager
    print("✓ Core imports successful")
except ImportError as e:
    print(f"✗ Core import failed: {e}")
    print(f"  sys.path: {sys.path[:3]}")
    print(f"  app_dir exists: {app_dir.exists()}")


import pytest


@pytest.fixture
def event_loop():
    """Create an instance of the default event loop for each test."""
    import asyncio
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()
