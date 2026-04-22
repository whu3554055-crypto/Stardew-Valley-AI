# Godot Node Method Name Conflict Fix

**Date**: 2026-04-21  
**Commit**: `663e3f2`  
**Issue**: Runtime error - "The function signature doesn't match the parent. Parent signature is 'get(StringName) -> Variant'."

---

## Problem

When creating custom Autoload modules that extend `Node`, you cannot override built-in Node methods with different signatures. The `AIContentCache` module had several methods that conflicted with Node's built-in methods:

### Conflicting Methods Found

| Original Method | Node's Built-in | Error |
|----------------|-----------------|-------|
| `func get(key: String) -> Variant` | `func get(property: StringName) -> Variant` | ❌ Signature mismatch |
| `func set(key: String, data: Variant, ttl: float)` | `func set(property: StringName, value: Variant)` | ❌ Signature mismatch |
| `func has(key: String) -> bool` | `func has_node(path: NodePath) -> bool` (similar pattern) | ⚠️ Potential conflict |
| `func remove(key: String) -> bool` | N/A (no direct conflict) | ✅ Safe but renamed for consistency |

---

## Solution

Renamed all cache-related methods to use a `_cached` suffix to avoid conflicts:

### Method Renames

```gdscript
# Before (caused errors)
func get(key: String) -> Variant
func set(key: String, data: Variant, ttl_seconds: float = DEFAULT_TTL) -> void
func has(key: String) -> bool
func remove(key: String) -> bool

# After (no conflicts)
func get_cached(key: String) -> Variant
func set_cached(key: String, data: Variant, ttl_seconds: float = DEFAULT_TTL) -> void
func has_cached(key: String) -> bool
func remove_cached(key: String) -> bool
```

---

## Why This Happens

In Godot 4.x, when you extend `Node` (or any built-in class), you inherit all its methods. If you define a method with the same name but a different signature, Godot throws an error because it can't properly override the parent method.

### Common Node Methods to Avoid

These are common Node/Object methods that should **not** be overridden with different signatures:

- `get(property: StringName) -> Variant`
- `set(property: StringName, value: Variant) -> void`
- `has_node(path: NodePath) -> bool`
- `get_node(path: NodePath) -> Node`
- `add_child(node: Node) -> void`
- `remove_child(node: Node) -> void`
- `call(method: StringName, ...) -> Variant`
- `is_inside_tree() -> bool`
- `get_parent() -> Node`
- `queue_free() -> void`
- `connect(signal_name: StringName, ...)` 
- `disconnect(signal_name: StringName, ...)`
- `emit_signal(signal_name: StringName, ...)`

---

## Best Practices

### 1. Use Descriptive Prefixes/Suffixes

Instead of generic names like `get()`, `set()`, `has()`, use descriptive names:

```gdscript
# Good - Clear and no conflicts
func get_cached(key: String) -> Variant
func set_cached(key: String, data: Variant) -> void
func has_cached(key: String) -> bool

# Bad - Conflicts with Node methods
func get(key: String) -> Variant
func set(key: String, data: Variant) -> void
func has(key: String) -> bool
```

### 2. Check for Conflicts Early

Before creating methods in Node-based classes, check if the name conflicts:

```bash
# Search for potential conflicts
grep "^func \(get\|set\|has\|call\|add\|remove\)(" your_script.gd
```

### 3. Use Module-Specific Naming

Prefix methods with the module's purpose:

```gdscript
# AI Content Cache module
func cache_get(key: String) -> Variant
func cache_set(key: String, data: Variant) -> void
func cache_has(key: String) -> bool

# Quest Index Optimizer module
func index_get_by_id(quest_id: String) -> Dictionary
func index_add_quest(quest_id: String, data: Dictionary) -> void
```

### 4. Document Your API

Clearly document why you chose specific method names:

```gdscript
## Get cached content by key.
## Note: Uses 'get_cached' instead of 'get' to avoid conflict with Node.get()
func get_cached(key: String) -> Variant:
    # Implementation...
```

---

## Files Modified

- [autoload/ai_content_cache.gd](file://d:/repo/stardew_valley/autoload/ai_content_cache.gd)
  - Line 100: `get()` → `get_cached()`
  - Line 127: `set()` → `set_cached()`
  - Line 146: `has()` → `has_cached()`
  - Line 158: `remove()` → `remove_cached()`

---

## Impact Assessment

### Breaking Changes

⚠️ **If any code was already using these methods**, it needs to be updated:

```gdscript
# Old code (would break)
var data = AIContentCache.get("some_key")
AIContentCache.set("some_key", some_data)
if AIContentCache.has("some_key"):
    # ...
AIContentCache.remove("some_key")

# New code (correct)
var data = AIContentCache.get_cached("some_key")
AIContentCache.set_cached("some_key", some_data)
if AIContentCache.has_cached("some_key"):
    # ...
AIContentCache.remove_cached("some_key")
```

### Current Status

✅ **No breaking changes** - The `AIContentCache` module was just created and is not yet used anywhere in the codebase. No migration needed.

---

## Verification

To verify no other conflicts exist in newly created modules:

```powershell
# Check for potential method name conflicts
$nodeMethods = @('get', 'set', 'has', 'call', 'is_inside_tree', 'get_parent', 'get_node', 'add_child', 'remove_child', 'queue_free')
Get-ChildItem autoload\*.gd | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) } | ForEach-Object {
    $content = Get-Content $_.FullName
    $lineNum = 0
    foreach ($line in $content) {
        $lineNum++
        if ($line -match '^func\s+(\w+)\s*\(') {
            $methodName = $matches[1]
            if ($nodeMethods -contains $methodName) {
                Write-Host "$($_.Name):$lineNum - CONFLICT: func $methodName"
            }
        }
    }
}
```

---

## Related Issues

This fix was discovered during the AgenticContentOrchestrator refactoring verification process. The error message was:

```
错误 (100, 1)： The function signature doesn't match the parent. Parent signature is "get(StringName) -> Variant".
```

This pointed directly to line 100 in `ai_content_cache.gd`, which had the conflicting `get()` method.

---

## Lessons Learned

1. **Always check for method name conflicts** when extending built-in Godot classes
2. **Use descriptive, domain-specific method names** instead of generic ones
3. **Test early and often** - this error would have been caught immediately if the module was tested right after creation
4. **Document naming conventions** to help future developers avoid similar issues

---

**Status**: ✅ **RESOLVED**  
**Verified By**: Automated error detection + manual review  
**Next Steps**: None - issue fully resolved with no side effects
