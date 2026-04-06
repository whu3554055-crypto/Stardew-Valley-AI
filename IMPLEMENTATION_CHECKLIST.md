# Optimization Implementation Checklist

Quick-start guide for applying performance optimizations. Follow in order for best results.

---

## Phase 1: Critical Fixes (Do These First)

### ✅ Task 1.1: Async Narrative Generation

**Files to modify:**
- `autoload/daily_narrative_system.gd`
- Create: `scenes/ui/narrative_loading_screen.tscn`
- Create: `scenes/ui/narrative_loading_screen.gd`

**Steps:**

1. **Add signals to DailyNarrativeSystem:**
```gdscript
# At top of daily_narrative_system.gd, after class_name
signal narrative_generation_started
signal narrative_generation_completed(narrative_data)
signal narrative_generation_progress(progress_percent, status_text)
```

2. **Replace `generate_daily_narrative()` with async version:**
   - See Section 1.1 in OPTIMIZATION_GUIDE.md for full code
   - Key change: Add `await` keywords and progress emissions

3. **Create loading screen scene:**
```bash
# In Godot editor:
# 1. Create new scene → CanvasLayer
# 2. Add: Panel, ProgressBar, Label (status), Label (tip)
# 3. Attach narrative_loading_screen.gd script
# 4. Save as scenes/ui/narrative_loading_screen.tscn
```

4. **Wire up signals in main scene:**
```gdscript
# In scenes/main.gd _ready()
LoadingScreen = preload("res://scenes/ui/narrative_loading_screen.tscn").instantiate()
add_child(LoadingScreen)

DailyNarrativeSystem.narrative_generation_progress.connect(
    func(pct, status): LoadingScreen.update_progress(pct, status)
)
```

**Test:** Trigger narrative generation, verify no frame drops, progress bar updates smoothly.

---

### ✅ Task 1.2: NPC Update Throttling

**Files to modify:**
- `autoload/npc_behavior_controller.gd`

**Steps:**

1. **Add timer management system:**
   - Copy code from Section 1.2 in OPTIMIZATION_GUIDE.md
   - Add constants at top of file
   - Add `npc_update_timers` dictionary

2. **Modify `_process()` method:**
```gdscript
# Replace existing _process() with:
func _process(delta):
    # Only check social interactions every few seconds
    social_check_timer += delta
    if social_check_timer >= SOCIAL_CHECK_INTERVAL:
        check_social_interactions()
        social_check_timer = 0.0

    # Individual NPC updates are now timer-based (see setup_npc_update_timer)
```

3. **Initialize timers in `_ready()`:**
```gdscript
func _ready():
    # ... existing initialization ...

    # Setup update timers for all NPCs
    for npc_id in EnhancedPersonalitySystem.get_all_npc_ids():
        setup_npc_update_timer(npc_id)
```

**Test:** Run game with 6+ NPCs, monitor CPU usage (should drop 50-70%).

---

### ✅ Task 1.3: LRU Cache for AI Responses

**Files to modify:**
- `autoload/ai_agent_manager.gd`

**Steps:**

1. **Replace cache variables:**
```gdscript
# Old:
var response_cache = {}

# New:
const MAX_CACHE_SIZE = 100
const CACHE_TTL = 300.0

var response_cache = {}
var cache_access_order = []
var cache_timestamps = {}
```

2. **Update `get_cached_response()` and `cache_response()`:**
   - Copy implementations from Section 1.3 in OPTIMIZATION_GUIDE.md

3. **Add cleanup timer in `_ready()`:**
```gdscript
func _ready():
    # ... existing code ...

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 120.0
    cleanup_timer.timeout.connect(_on_cache_cleanup_timer_timeout)
    add_child(cleanup_timer)
    cleanup_timer.start()
```

**Test:** Play for 30+ minutes, check memory usage stays stable (<10MB for cache).

---

## Phase 2: Performance Scaling

### ✅ Task 2.1: Spatial Partitioning

**Files to modify:**
- `autoload/npc_behavior_controller.gd`

**Steps:**

1. **Add spatial grid system:**
   - Copy code from Section 2.1 in OPTIMIZATION_GUIDE.md
   - Add `spatial_grid` dictionary and constants

2. **Replace `check_social_interactions()`:**
```gdscript
# Old O(n^2) version - DELETE THIS
func check_social_interactions():
    for npc1 in npcs:
        for npc2 in npcs:
            if npc1.distance_to(npc2) < threshold:
                interact(npc1, npc2)

# New spatial version - USE THIS
func check_social_interactions():
    update_spatial_grid()

    for npc_id in active_npcs:
        var nearby = get_nearby_npcs(npc_id, radius_tiles=5)
        for other_id in nearby:
            attempt_social_interaction(npc_id, other_id)
```

**Test:** Add 15+ NPCs, verify FPS stays above 50.

---

### ✅ Task 2.2: Tilemap Chunk Culling

**Files to modify:**
- `scripts/game_tilemap.gd`

**Steps:**

1. **Add chunk system:**
   - Copy code from Section 2.2 in OPTIMIZATION_GUIDE.md
   - Add `chunk_tiles` and `visible_chunks` dictionaries

2. **Modify tile generation in `_ready()`:**
```gdscript
func _ready():
    generate_procedural_map()
    organize_tiles_into_chunks()  # Add this line
```

3. **Add `_process()` for culling:**
```gdscript
func _process(_delta):
    update_visible_chunks()
```

**Test:** Move camera around map, verify distant tiles disappear/reappear correctly.

---

### ✅ Task 2.3: Lazy Loading NPCs

**Files to modify:**
- `autoload/enhanced_personality_system.gd`
- Create: `data/npcs/*.json` (one per NPC)

**Steps:**

1. **Extract NPC data to JSON files:**

Create extraction script (`tools/extract_npcs.py`):
```python
import json
import re

# Read the GDScript file
with open('autoload/enhanced_personality_system.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Find NPC definitions (pattern matching)
npc_pattern = r'npc_database\["(\w+)"\]\s*=\s*(\{.*?\n\})'
matches = re.findall(npc_pattern, content, re.DOTALL)

for npc_id, npc_data_str in matches:
    # Convert GDScript dict to JSON (simplified - may need manual cleanup)
    # For now, manually extract each NPC to its own JSON file
    print(f"Found NPC: {npc_id}")
```

**Manual approach (recommended for accuracy):**

For each NPC (e.g., "elias"):
```json
// data/npcs/elias.json
{
    "basic_info": {
        "name": "Dr. Elias Thornwood",
        "age": 67,
        "occupation": "Research Scientist & Inventor"
        // ... rest of data
    }
    // ... all other sections
}
```

2. **Modify EnhancedPersonalitySystem:**
   - Copy lazy loading code from Section 2.3 in OPTIMIZATION_GUIDE.md
   - Add `npc_file_paths` registration

3. **Update references:**
   - Anywhere calling `get_npc()` will auto-load now
   - No other code changes needed

**Test:** Startup time should decrease, memory usage lower initially.

---

## Phase 3: UX Polish

### ✅ Task 3.1: Dialogue Streaming

**Files to modify:**
- `scenes/ui/dialogue_box.gd`
- `autoload/ai_agent_manager.gd` (optional, for true streaming)

**Steps:**

1. **Enhance dialogue box:**
   - Copy typewriter effect code from Section 3.1 in OPTIMIZATION_GUIDE.md
   - Add `typing_speed`, `display_index`, `is_typing` variables

2. **Modify `display_dialogue()`:**
```gdscript
# Old: Instant text display
text_label.text = full_text

# New: Typewriter effect
current_text = full_text
display_index = 0
is_typing = true
start_typing()
```

3. **Add input handling:**
```gdscript
func _input(event):
    if event.is_action_pressed("interact"):
        if is_typing:
            skip_typing()  # Show full text immediately
        elif continue_indicator.visible:
            hide_dialogue()
```

**Test:** Talk to NPCs, enjoy smooth text animation, press E to skip.

---

### ✅ Task 3.2: Loading Screens

**Files to create:**
- `scenes/ui/loading_screen.tscn`
- `scenes/ui/loading_screen.gd`

**Steps:**

1. **Create loading screen scene:**
```
CanvasLayer (loading_screen)
└── Panel (centered)
    ├── Label (title/status)
    ├── ProgressBar
    ├── Label (lore text)
    └── Label (tip text)
```

2. **Attach script:**
   - Copy code from Section 3.2 in OPTIMIZATION_GUIDE.md

3. **Integrate with operations:**
```gdscript
# Before long operation
LoadingScreen.show_loading("Generating story", 10.0)

# During operation
LoadingScreen.update_progress(50, "Halfway done...")

# After operation
LoadingScreen.hide_loading()
```

**Test:** Trigger narrative generation, see engaging loading screen instead of freeze.

---

### ✅ Task 3.3: Adaptive Quality

**Files to create:**
- `autoload/quality_manager.gd`

**Steps:**

1. **Create quality manager autoload:**
   - Copy code from Section 3.3 in OPTIMIZATION_GUIDE.md
   - Add to Project Settings → Autoload

2. **Configure systems to respect quality settings:**
```gdscript
# In NPCBehaviorController
var max_active_npcs = 8  # Will be overridden by QualityManager

# In GameTilemap
var render_distance = 768  # Will be overridden
```

3. **Add quality selector to options menu:**
```gdscript
# In settings UI
func _on_quality_dropdown_selected(index):
    QualityManager.change_quality(index)
```

**Test:** Change quality levels, observe NPC count and visual effects adjust.

---

## Verification Checklist

After implementing each phase, verify:

### Phase 1 Verification
- [ ] No frame freezes during narrative generation
- [ ] Progress bar updates smoothly
- [ ] CPU usage drops when NPCs idle
- [ ] Memory stable after 30 min play session

### Phase 2 Verification
- [ ] 15+ NPCs run at 50+ FPS
- [ ] Distant tiles cull correctly
- [ ] Startup time under 5 seconds
- [ ] Memory usage under 500MB

### Phase 3 Verification
- [ ] Dialogue types smoothly
- [ ] Can skip typing with E key
- [ ] Loading screens show during waits
- [ ] Quality changes apply immediately

---

## Troubleshooting

### Issue: Narrative generation still blocks
**Solution:** Ensure `await` keywords are present in async functions. Check that `generate_script_async()` uses `AdvancedAIManager.request_dialogue()` not synchronous call.

### Issue: NPCs stop updating entirely
**Solution:** Verify `setup_npc_update_timer()` is called for each NPC in `_ready()`. Check timer connections.

### Issue: Cache evicts too aggressively
**Solution:** Increase `MAX_CACHE_SIZE` from 100 to 200. Monitor cache hit rate.

### Issue: Spatial grid returns wrong neighbors
**Solution:** Verify `CELL_SIZE` matches your tile size. Debug draw grid cells to visualize.

### Issue: Chunk culling causes pop-in
**Solution:** Increase `RENDER_MARGIN` from 2 to 3 or 4 chunks.

---

## Next Steps After Implementation

1. **Profile on target hardware** (Steam Deck, low-end laptop)
2. **Gather user feedback** on perceived performance
3. **Fine-tune quality presets** based on real-world testing
4. **Document final benchmarks** for marketing materials
5. **Consider platform-specific optimizations** (mobile touch controls, console controllers)

---

## Estimated Time Investment

| Phase | Tasks | Time Required |
|-------|-------|---------------|
| Phase 1 | 3 critical fixes | 2-3 days |
| Phase 2 | 3 performance features | 3-4 days |
| Phase 3 | 3 UX enhancements | 2-3 days |
| Testing | Profiling & refinement | 2-3 days |
| **Total** | **9 optimizations** | **9-13 days** |

**Recommendation:** Implement Phase 1 first (biggest impact), release beta, gather feedback, then proceed with Phases 2-3.
