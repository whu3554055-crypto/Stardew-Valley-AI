extends RefCounted

## Stub plugin — optional economy behavior (register_builtin_plugins).

var plugin_config: Dictionary = {}
var npc_id: String = ""
var plugin_name: String = "economy_trader"

func _plugin_init() -> bool:
	return true
