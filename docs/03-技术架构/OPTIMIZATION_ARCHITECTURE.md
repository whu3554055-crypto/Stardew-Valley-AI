# Optimization Architecture Overview

Visual guide to understanding how all optimizations work together.

---

## System Architecture Before vs After Optimization

### BEFORE OPTIMIZATION (Current State)

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN GAME LOOP                            │
│                   (60 FPS Target)                            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│  All NPCs    │    │   Tilemap    │    │ Narrative System │
│ _process()   │    │ 4000 tiles   │    │ (SYNCHRONOUS!)   │
│ EVERY FRAME  │    │ ALL rendered │    │ Blocks 30s       │
│              │    │              │    │                  │
│ ❌ Wasteful  │    │ ❌ Overdraw  │    │ ❌ FREEZE!       │
└──────────────┘    └──────────────┘    └──────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    AI LLM Requests                           │
│                 (Unbounded Cache)                            │
│                                                              │
│  ❌ Memory Leak → Grows forever                             │
│  ❌ O(n²) social checks                                     │
└─────────────────────────────────────────────────────────────┘

PROBLEMS:
- Frame drops during narrative generation
- High CPU usage from unnecessary NPC updates
- GPU overdraw from rendering off-screen tiles
- Memory bloat from unbounded caches
- Performance degrades exponentially with more NPCs
```

---

### AFTER OPTIMIZATION (Target State)

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN GAME LOOP                            │
│                   (60 FPS Stable)                            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│ Smart NPC    │    │   Tilemap    │    │ Async Narrative  │
│ Update System│    │ Chunk Cull   │    │ Generator        │
│              │    │              │    │                  │
│ ✓ Distance-  │    │ ✓ Only near  │    │ ✓ Background     │
│   based      │    │   chunks     │    │   thread         │
│ ✓ State-     │    │ ✓ Margin for │    │ ✓ Progress UI    │
│   based      │    │   smoothness │    │ ✓ Zero freezes   │
└──────────────┘    └──────────────┘    └──────────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
│ Spatial Grid │    │ Bounded LRU  │    │ Quality Manager  │
│              │    │ Cache        │    │                  │
│ ✓ O(n log n) │    │ ✓ Max 100    │    │ ✓ Auto-detect    │
│ ✓ Fast prox- │    │ ✓ 5min TTL   │    │   hardware       │
│   imity      │    │ ✓ Auto-clea- │    │ ✓ Adjust NPC     │
│ ✓ Scalable   │    │   nup        │    │   count, effects │
└──────────────┘    └──────────────┘    └──────────────────┘

BENEFITS:
- Smooth 60 FPS on mid-range hardware
- 60-80% reduction in CPU usage
- 60-70% reduction in GPU rendering load
- Memory capped at ~500MB with no leaks
- Supports 20+ NPCs without performance degradation
```

---

## Data Flow: Async Narrative Generation

```
USER TRIGGERS STORY
        │
        ▼
┌─────────────────────┐
│ DailyNarrativeSys   │
│ generate_async()    │──── Signal: narrative_generation_started
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│ Loading Screen UI   │ ←── Shows: "Creating today's story..."
│ (Progress Bar)      │ ←── Displays lore text & tips
└─────────────────────┘
        │
        ├─ Step 1: Theme Selection (instant) ──── Progress: 10%
        │
        ├─ Step 2: Scenario Matching (instant) ── Progress: 20%
        │
        ├─ Step 3: NPC Casting (instant) ──────── Progress: 30%
        │
        ├─ Step 4: Script Generation (ASYNC!)
        │         │
        │         ├─ Request sent to Ollama LLM
        │         ├─ Wait with timeout (yields each frame)
        │         ├─ Stream partial results (optional)
        │         └─ Complete after 3-10 seconds ─ Progress: 80%
        │
        ├─ Step 5: Scene Assembly (instant) ───── Progress: 90%
        │
        └─ Step 6: Finalization ───────────────── Progress: 100%
                  │
                  ▼
        ┌─────────────────────┐
        │ Signal: completed   │──── Hides loading screen
        └─────────────────────┘
                  │
                  ▼
        Story ready to present!

KEY POINTS:
- Main thread never blocks
- Player sees continuous feedback
- Can cancel if needed
- Feels much faster than it is
```

---

## NPC Update Priority System

```
                    PLAYER POSITION
                         ★
                        /|\
                       / | \
                      /  |  \
                     /   |   \
                    /    |    \
                   /     |     \
                  /      |      \
                 /       |       \
                /        |        \
               /         |         \
              /          |          \
             /           |           \
            /            |            \
           /             |             \
          /              |              \
         /               |               \
        /                |                \
       /                 |                 \
      /                  |                  \
     /                   |                   \
    /                    |                    \
   /                     |                     \
  /                      |                      \
 /                       |                       \
/                        |                        \

ZONE 1: VISIBLE (High Priority - 10 updates/sec)
├─ NPCs update every 0.1s
├─ Full behavior processing
├─ Animation updates
└─ Social interaction checks

ZONE 2: SAME AREA (Medium Priority - 2 updates/sec)
├─ NPCs update every 0.5s
├─ Basic movement only
├─ Emotion decay
└─ Schedule checks

ZONE 3: ADJACENT ZONE (Low Priority - 0.5 updates/sec)
├─ NPCs update every 2s
├─ Position tracking only
└─ Important events only

ZONE 4: OFF-SCREEN (Idle - 0.2 updates/sec)
├─ NPCs update every 5s
├─ Minimal processing
└─ Skip if nothing important

CPU SAVINGS:
- 6 NPCs visible: 60 updates/sec (vs 360 without throttling)
- 10 NPCs in area: 20 updates/sec (vs 600 without throttling)
- Total: ~80 updates/sec vs ~960 = 92% reduction!
```

---

## Spatial Partitioning for Social Checks

```
WITHOUT SPATIAL GRID (O(n²)):
NPC1 checks distance to: NPC2, NPC3, NPC4, NPC5, NPC6, ... NPC20
NPC2 checks distance to: NPC1, NPC3, NPC4, NPC5, NPC6, ... NPC20
...
Total comparisons: 20 × 19 = 380 checks

WITH SPATIAL GRID (O(n log n)):
Grid cells (32x32 tiles each):
┌──────┬──────┬──────┬──────┐
│      │ NPC3 │      │      │
├──────┼──────┼──────┼──────┤
│ NPC1 │ NPC2 │      │ NPC5 │  ← Only check these 2
├──────┼──────┼──────┼──────┤
│      │      │ NPC4 │      │
├──────┼──────┼──────┼──────┤
│      │      │      │ NPC6 │
└──────┴──────┴──────┴──────┘

For NPC1:
- Calculate cell position: (2, 1)
- Check surrounding cells: (1,0), (1,1), (1,2), (2,0), (2,2), (3,0), (3,1), (3,2)
- Only find NPC2 in adjacent cell
- Distance check: NPC1 ↔ NPC2 = 5 tiles (within threshold)
- Trigger interaction!

Total comparisons: ~20 × 3 = 60 checks (84% reduction!)

SCALABILITY:
- 20 NPCs: 380 → 60 checks
- 50 NPCs: 2450 → 150 checks
- 100 NPCs: 9900 → 300 checks
```

---

## Memory Management: LRU Cache

```
CACHE STATE OVER TIME:

t=0s (Empty):
┌───┬───┬───┬───┬───┐
│   │   │   │   │   │ ... (100 slots)
└───┴───┴───┴───┴───┘

t=60s (Some entries):
┌────────┬────────┬────────┬───┬───┐
│hash_A  │hash_B  │hash_C  │   │   │
│(age:5s)│(age:3s)│(age:1s)│   │   │
└────────┴────────┴────────┴───┴───┘
Access order: [A, B, C]

t=300s (Cache full):
┌────────┬────────┬───┬────────┬────────┐
│hash_X  │hash_Y  │...│hash_Z  │hash_W  │
│(old!)  │        │   │        │(new!)  │
└────────┴────────┴───┴────────┴────────┘
Access order: [X, Y, ..., Z, W]

NEW REQUEST ARRIVES:
1. Check if hash exists in cache
2. If YES: Move to end of access order (most recently used)
3. If NO and cache full:
   a. Evict FIRST entry in access order (LRU = hash_X)
   b. Insert new entry at end
   c. Update access order

t=301s (After eviction):
┌────────┬────────┬───┬────────┬────────┐
│hash_Y  │...     │...│hash_W  │hash_NEW│
│(now LRU)│       │   │        │(fresh) │
└────────┴────────┴───┴────────┴────────┘
Access order: [Y, ..., Z, W, NEW]

PERIODIC CLEANUP (every 120s):
- Scan all entries
- Remove any older than 300s (TTL)
- Free memory immediately

MEMORY USAGE:
- Each cache entry: ~100KB (prompt + response)
- Max 100 entries: ~10MB total
- Old system: Unlimited → Could grow to 100MB+
```

---

## Tilemap Chunk Culling

```
VIEWPORT (1280x720) shown as rectangle:

FULL MAP (80x50 tiles = 4000 tiles):
╔════════════════════════════════════════╗
║ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ║
║ ░░┌──────────────────────┐░░░░░░░░░░░ ║
║ ░░│                      │░░░░░░░░░░░ ║
║ ░░│   VIEWPORT           │░░░░░░░░░░░ ║
║ ░░│   (visible)          │░░░░░░░░░░░ ║
║ ░░│                      │░░░░░░░░░░░ ║
║ ░░│   ~640 tiles         │░░░░░░░░░░░ ║
║ ░░│                      │░░░░░░░░░░░ ║
║ ░░└──────────────────────┘░░░░░░░░░░░ ║
║ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ║
╚════════════════════════════════════════╝

Chunk size: 16x16 tiles
Viewport covers: ~40 chunks
With margin (2 chunks): ~72 chunks rendered
Hidden: ~200 chunks (2800 tiles not rendered!)

RENDERING COMPARISON:

Without culling:
- Tiles processed: 4000
- Draw calls: 4000
- GPU memory: High

With chunk culling:
- Tiles processed: ~1150 (72 chunks × 16 tiles)
- Draw calls: ~1150
- GPU memory: 70% less

CAMERA MOVEMENT:
Frame 1: Render chunks A, B, C, D
Frame 2: Camera moves right
         Hide chunk A (off-screen)
         Show chunk E (now in view)
         Keep B, C, D (still visible)

SMOOTH TRANSITION:
- Margin ensures chunks load before visible
- No pop-in artifacts
- Seamless scrolling
```

---

## Quality Level Comparison

```
┌─────────────┬──────────┬──────────┬──────────┬──────────┐
│ Feature     │ LOW      │ MEDIUM   │ HIGH     │ ULTRA    │
├─────────────┼──────────┼──────────┼──────────┼──────────┤
│ Max NPCs    │ 4        │ 8        │ 12       │ 20       │
│ Update Rate │ 0.5s     │ 0.2s     │ 0.1s     │ 0.05s    │
│ Shadows     │ OFF      │ ON       │ ON       │ ON       │
│ Particles   │ 20       │ 50       │ 100      │ 200      │
│ Render Dist │ 512px    │ 768px    │ 1024px   │ 1536px   │
│ Post-FX     │ OFF      │ OFF      │ ON       │ ON       │
│ Target FPS  │ 30+      │ 60+      │ 60+      │ 60+      │
│ VRAM Usage  │ <1GB     │ <2GB     │ <3GB     │ <4GB     │
└─────────────┴──────────┴──────────┴──────────┴──────────┘

AUTO-DETECTION LOGIC:

Score calculation:
  VRAM > 4GB?    +3 points
  VRAM > 2GB?    +2 points
  VRAM > 1GB?    +1 point
  CPU cores ≥8?  +2 points
  CPU cores ≥4?  +1 point

Total score:
  ≥5 points → ULTRA
  ≥4 points → HIGH
  ≥2 points → MEDIUM
  <2 points → LOW

Example detections:
  Integrated GPU (512MB VRAM, 4 cores):
    Score = 0 + 1 = 1 → LOW

  Mid laptop (2GB VRAM, 6 cores):
    Score = 2 + 1 = 3 → MEDIUM

  Gaming PC (6GB VRAM, 8 cores):
    Score = 3 + 2 = 5 → ULTRA
```

---

## Performance Monitoring Dashboard (F3 Key)

```
┌─────────────────────────────────────────┐
│ === PERFORMANCE MONITOR ===             │
│                                         │
│ FPS: 58.3 (avg: 59.1)                  │
│ Memory: 387.2 MB (peak: 412.5 MB)      │
│ Active NPCs: 8                          │
│ AI Cache Size: 42                       │
│ Rendered Chunks: 68                     │
│                                         │
│ System Info:                            │
│ GPU: Intel Iris Xe Graphics            │
│ VRAM: 2048 MB                           │
│ CPU Cores: 8                            │
└─────────────────────────────────────────┘

Color coding:
  🟢 Green:  Optimal performance
  🟡 Yellow: Warning (FPS < 45 or Memory > 400MB)
  🔴 Red:    Critical (FPS < 30 or Memory > 600MB)

CONSOLE OUTPUT (print_performance_report()):

==================================================
PERFORMANCE REPORT
==================================================
FPS: 59.1 (avg) | 58 (current)
Memory: 387.2 MB (current) | 412.5 MB (peak)
Active NPCs: 8
AI Cache: 42 entries
Rendered Chunks: 68
GPU: Intel Iris Xe Graphics (2048 MB VRAM)
==================================================
```

---

## Implementation Dependency Graph

```
START HERE
    │
    ▼
┌─────────────────────┐
│ Phase 1: Critical   │
│                     │
│ 1.1 Async Narrative │──────────┐
│ 1.2 NPC Throttling  │───┐     │
│ 1.3 LRU Cache       │───┼──┐  │
└─────────────────────┘   │  │  │
    │                     │  │  │
    ▼                     │  │  │
┌─────────────────────┐   │  │  │
│ Phase 2: Scaling    │◄──┘  │  │
│                     │      │  │
│ 2.1 Spatial Grid    │──────┘  │
│ 2.2 Chunk Culling   │         │
│ 2.3 Lazy Loading    │─────────┘
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Phase 3: UX Polish  │
│                     │
│ 3.1 Typewriter FX   │ (independent)
│ 3.2 Loading Screens │ (needs 1.1)
│ 3.3 Quality Manager │ (independent)
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│ Testing & Profiling │
│                     │
│ • Steam Deck        │
│ • Low-end laptop    │
│ • High-end desktop  │
└─────────────────────┘

DEPENDENCIES:
- Phase 2 requires Phase 1 complete
- 3.2 Loading Screen requires 1.1 Async Narrative
- All other Phase 3 tasks are independent
- Can skip phases if not needed
```

---

## Summary: Impact vs Effort Matrix

```
HIGH IMPACT
    │
    │  ⭐ 1.1 Async Narrative    ⭐ 2.1 Spatial Grid
    │  ⭐ 1.2 NPC Throttling     ⭐ 2.2 Chunk Culling
    │
    ├────────────────────────────────────────────
    │
    │  📝 1.3 LRU Cache         📝 3.3 Quality Mgr
    │  📝 2.3 Lazy Loading      📝 3.1 Typewriter
    │
LOW     ──────────────────────────────────────→ HIGH
IMPACT         LOW EFFORT          EFFORT

LEGEND:
⭐ = Must implement (critical for performance)
📝 = Should implement (significant improvements)
💡 = Nice to have (polish features)

RECOMMENDED ORDER:
1. Start with top-left quadrant (high impact, low effort)
2. Then move right (high impact, higher effort)
3. Finally add polish features as time allows
```

---

This visual guide should help you understand how all the optimizations fit together and prioritize implementation based on your specific needs!
