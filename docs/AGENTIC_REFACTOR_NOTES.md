# Agentic Refactor Notes

## Why this refactor

The previous orchestrator refactor reduced file size, but mixed multiple concerns in one place:

- orchestration flow
- legacy compatibility APIs
- schema conversion
- status/hint text formatting

That made debugging and future iteration expensive.

## New structure

- `autoload/agentic_content_orchestrator.gd`
  - Core orchestration only
  - Decides when to generate
  - Coordinates storage/validator/theme/performance/fallback modules
- `autoload/agentic_chain_schema_translator.gd`
  - Translates chain payloads to `QuestSystem.register_runtime_chain_template()` shape
  - Performs basic registration-shape validation
- `autoload/agentic_runtime_status_service.gd`
  - Builds status line text
  - Provides recovery hint text from failure reasons
- `autoload/agentic_orchestrator_legacy_facade.gd`
  - Stable entry for callers during migration
  - Forwards calls/signals to `AgenticContentOrchestrator`
- `autoload/agentic_chain_storage.gd`
  - Added storage schema versioning and compatibility load paths
  - Supports migration from older key layouts

## Caller contract

Main scene now uses facade access:

- `AgenticOrchestratorFacade.maybe_generate_for_day(...)`
- `AgenticOrchestratorFacade.get_status_line()`
- `AgenticOrchestratorFacade.get_recovery_hint(reason)`

Legacy aliases remain in facade for transition:

- `get_runtime_status_line()`
- `get_recovery_guidance(reason)`

## Regression checks

Added executable checks:

- `tools/test_chain_schema_translator.gd`
- `tools/test_runtime_chain_registration.gd`
- `tools/run_agentic_regression.ps1` (runs both tests + smoke)

Suggested routine:

```powershell
powershell -ExecutionPolicy Bypass -File "tools/run_agentic_regression.ps1"
```

## Next cleanup opportunities

- Move any remaining compatibility aliases from facade to dedicated deprecation window.
- Add schema migration telemetry (count and timestamp) if needed for production diagnostics.
- If stable for 1-2 iterations, remove legacy alias methods from facade.

