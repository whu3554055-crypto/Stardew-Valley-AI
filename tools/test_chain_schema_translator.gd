extends SceneTree

const Translator = preload("res://autoload/agentic_chain_schema_translator.gd")

func _init() -> void:
	var failures: Array[String] = []

	# Case 1: Legacy schema should remain usable.
	var legacy_chain := {
		"id": "legacy_chain_1",
		"steps": [{
			"id": "legacy_chain_1_s1",
			"title": "Legacy Step",
			"description": "Legacy flow",
			"objective": {"type": "harvest", "count": 1},
			"reward": {"gold": 10, "items": []}
		}]
	}
	var norm_legacy: Dictionary = Translator.normalize_for_registration(legacy_chain)
	_assert(Translator.validate_registration_shape(norm_legacy).get("ok", false), "legacy schema validation", failures)

	# Case 2: New schema should be translated to steps.
	var modern_chain := {
		"id": "modern_chain_1",
		"title": "Modern Chain",
		"theme": "joyful",
		"objectives": [
			{"type": "harvest", "count": 2, "description": "Harvest crops"},
			{"type": "talk", "count": 1, "npc_id": "pierre", "description": "Talk to Pierre"}
		],
		"rewards": {"gold": 120, "items": ["bread:1"]}
	}
	var norm_modern: Dictionary = Translator.normalize_for_registration(modern_chain)
	_assert(norm_modern.has("steps"), "modern schema creates steps", failures)
	_assert((norm_modern.get("steps", []) as Array).size() == 2, "modern schema step count", failures)
	_assert(Translator.validate_registration_shape(norm_modern).get("ok", false), "modern schema validation", failures)

	# Case 3: Empty objectives should fallback to a safe step.
	var empty_chain := {
		"id": "empty_chain_1",
		"title": "Empty Chain",
		"objectives": [],
		"rewards": {"gold": 30}
	}
	var norm_empty: Dictionary = Translator.normalize_for_registration(empty_chain)
	var empty_steps: Array = norm_empty.get("steps", [])
	_assert(empty_steps.size() == 1, "empty objectives fallback step", failures)
	_assert(Translator.validate_registration_shape(norm_empty).get("ok", false), "empty schema fallback validation", failures)

	if failures.is_empty():
		print("[PASS] ChainSchemaTranslator tests")
		quit(0)
		return

	for f in failures:
		push_error("[FAIL] %s" % f)
	quit(1)

func _assert(condition: bool, name: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(name)

