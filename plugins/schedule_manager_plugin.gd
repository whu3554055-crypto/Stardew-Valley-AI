extends RefCounted

## Stub plugin — optional schedule manager.

var plugin_config: Dictionary = {}
var npc_id: String = ""
var plugin_name: String = "schedule_manager"

func _plugin_init() -> bool:
	return true
