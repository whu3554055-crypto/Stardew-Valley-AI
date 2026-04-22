extends RefCounted
class_name AgenticChainSchemaTranslator

## Converts generated chain payloads into QuestSystem registration schema.
## Keeps compatibility logic out of the orchestrator core.

static func normalize_for_registration(chain_data: Dictionary) -> Dictionary:
	if chain_data.has("steps"):
		return chain_data.duplicate(true)

	var out: Dictionary = chain_data.duplicate(true)
	var objectives: Array = chain_data.get("objectives", [])
	var rewards: Dictionary = chain_data.get("rewards", {})
	var steps: Array[Dictionary] = []
	var chain_id: String = str(out.get("id", "runtime_chain_%d" % int(Time.get_unix_time_from_system())))

	for i in range(objectives.size()):
		if not (objectives[i] is Dictionary):
			continue
		var obj: Dictionary = (objectives[i] as Dictionary).duplicate(true)
		var objective_type: String = str(obj.get("type", "harvest")).strip_edges()
		var count: int = int(obj.get("count", obj.get("target_count", 1)))
		var step_id: String = "%s_s%d" % [chain_id, i + 1]
		var step: Dictionary = {
			"id": step_id,
			"title": str(obj.get("title", "Step %d" % (i + 1))),
			"description": str(obj.get("description", "Complete objective %d." % (i + 1))),
			"objective": {"type": objective_type, "count": max(1, count)},
			"reward": {"gold": 0, "items": []}
		}
		if obj.has("npc_id"):
			step["objective"]["npc_id"] = obj.get("npc_id")
		if obj.has("crop_id"):
			step["objective"]["crop_id"] = obj.get("crop_id")
		if obj.has("ore_id"):
			step["objective"]["ore_id"] = obj.get("ore_id")
		if obj.has("fish_id"):
			step["objective"]["fish_id"] = obj.get("fish_id")
		steps.append(step)

	if steps.is_empty():
		steps = [{
			"id": "%s_s1" % chain_id,
			"title": "Daily Task",
			"description": "Harvest 3 crops.",
			"objective": {"type": "harvest", "count": 3},
			"reward": {"gold": 50, "items": []}
		}]

	var step_gold: int = int(rewards.get("gold", 0)) / max(1, steps.size())
	var items: Array = rewards.get("items", [])
	for i in range(steps.size()):
		steps[i]["reward"]["gold"] = step_gold
		steps[i]["reward"]["items"] = items.duplicate()

	out["steps"] = steps
	out["display_name"] = str(out.get("display_name", out.get("title", "Runtime Chain")))
	out["preferred_themes"] = [str(out.get("theme", "joyful"))]
	out["cooldown_days"] = int(out.get("cooldown_days", 1))
	return out

static func validate_registration_shape(chain_data: Dictionary) -> Dictionary:
	if not chain_data.has("steps"):
		return {"ok": false, "error": "missing_steps"}

	var chain_id: String = str(chain_data.get("id", "")).strip_edges()
	if chain_id.is_empty():
		return {"ok": false, "error": "missing_chain_id"}

	var steps: Array = chain_data.get("steps", [])
	if steps.is_empty():
		return {"ok": false, "error": "missing_steps"}

	for i in range(steps.size()):
		if not (steps[i] is Dictionary):
			return {"ok": false, "error": "step_not_dict"}
		var step: Dictionary = steps[i]
		if str(step.get("id", "")).strip_edges().is_empty():
			return {"ok": false, "error": "missing_step_id"}
		var objective: Dictionary = step.get("objective", {})
		if str(objective.get("type", "")).strip_edges().is_empty():
			return {"ok": false, "error": "missing_objective_type"}

	return {"ok": true}

