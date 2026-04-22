extends SceneTree

const Translator = preload("res://autoload/agentic_chain_schema_translator.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var qs: Node = root.get_node_or_null("QuestSystem")
	if qs == null:
		push_error("[FAIL] QuestSystem not found")
		quit(1)
		return

	var src := {
		"id": "reg_test_%d" % int(Time.get_unix_time_from_system()),
		"title": "Registration Test Chain",
		"theme": "joyful",
		"objectives": [
			{"type": "harvest", "count": 2, "description": "Harvest two crops"},
			{"type": "talk", "count": 1, "npc_id": "pierre", "description": "Talk to Pierre"}
		],
		"rewards": {"gold": 90, "items": ["bread:1"]}
	}

	var normalized: Dictionary = Translator.normalize_for_registration(src)
	var check: Dictionary = Translator.validate_registration_shape(normalized)
	if not bool(check.get("ok", false)):
		push_error("[FAIL] Shape validation failed: %s" % str(check))
		quit(1)
		return

	var reg: Dictionary = qs.register_runtime_chain_template(normalized, "runtime_agentic")
	if not bool(reg.get("ok", false)):
		push_error("[FAIL] Runtime registration failed: %s" % str(reg))
		quit(1)
		return

	print("[PASS] Runtime registration test")
	quit(0)

