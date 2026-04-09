extends RefCounted

## Stub plugin — optional quest giver behavior.

var plugin_config: Dictionary = {}
var npc_id: String = ""
var plugin_name: String = "quest_giver"

func _plugin_init() -> bool:
	return true
