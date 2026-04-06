extends Node

class_name NPCPluginManager

# ============================================
# NPC Plugin Manager - Hybrid Modular Architecture
# Manages pluggable trait components for NPCs
# ============================================

signal plugin_loaded(npc_id, plugin_name)
signal plugin_unloaded(npc_id, plugin_name)
signal plugin_error(npc_id, plugin_name, error_message)

# Plugin registry
var registered_plugins = {}

# Active plugins per NPC
var npc_active_plugins = {}

# Plugin instances cache
var plugin_instances = {}

# ============================================
# PLUGIN REGISTRATION
# ============================================

func register_plugin(plugin_name: String, plugin_script: GDScript, config: Dictionary = {}):
	"""Register a new plugin type"""
	registered_plugins[plugin_name] = {
		"script": plugin_script,
		"config": config,
		"description": config.get("description", ""),
		"version": config.get("version", "1.0.0"),
		"dependencies": config.get("dependencies", []),
		"optional": config.get("optional", true),
		"auto_load": config.get("auto_load", false)
	}
	
	print("[NPCPluginManager] Registered plugin: ", plugin_name)

func unregister_plugin(plugin_name: String):
	"""Unregister a plugin type"""
	if registered_plugins.has(plugin_name):
		registered_plugins.erase(plugin_name)
		
		# Unload from all NPCs
		for npc_id in npc_active_plugins.keys():
			unload_plugin_from_npc(npc_id, plugin_name)

# ============================================
# PLUGIN LIFECYCLE MANAGEMENT
# ============================================

func load_plugin_for_npc(npc_id: String, plugin_name: String, config_override: Dictionary = {}) -> bool:
	"""Load a plugin for a specific NPC"""
	# Check if plugin exists
	if not registered_plugins.has(plugin_name):
		push_error("[NPCPluginManager] Unknown plugin: " + plugin_name)
		plugin_error.emit(npc_id, plugin_name, "Unknown plugin")
		return false
	
	# Check dependencies
	var plugin_info = registered_plugins[plugin_name]
	for dep in plugin_info.dependencies:
		if not is_plugin_loaded_for_npc(npc_id, dep):
			push_error("[NPCPluginManager] Missing dependency: " + dep)
			plugin_error.emit(npc_id, plugin_name, "Missing dependency: " + dep)
			return false
	
	# Initialize NPC's plugin list if needed
	if not npc_active_plugins.has(npc_id):
		npc_active_plugins[npc_id] = {}
	
	# Check if already loaded
	if npc_active_plugins[npc_id].has(plugin_name):
		return true
	
	# Create plugin instance
	var plugin_instance = plugin_info.script.new()
	
	# Merge configs
	var final_config = plugin_info.config.duplicate(true)
	final_config.merge(config_override, true)
	plugin_instance.plugin_config = final_config
	plugin_instance.npc_id = npc_id
	plugin_instance.plugin_name = plugin_name
	
	# Initialize plugin
	if plugin_instance.has_method("_plugin_init"):
		var result = plugin_instance._plugin_init()
		if result == false:
			push_error("[NPCPluginManager] Plugin initialization failed: " + plugin_name)
			plugin_error.emit(npc_id, plugin_name, "Initialization failed")
			return false
	
	# Store instance
	npc_active_plugins[npc_id][plugin_name] = plugin_instance
	plugin_instances[plugin_name + "_" + npc_id] = plugin_instance
	
	plugin_loaded.emit(npc_id, plugin_name)
	print("[NPCPluginManager] Loaded plugin '", plugin_name, "' for NPC: ", npc_id)
	
	return true

func unload_plugin_from_npc(npc_id: String, plugin_name: String) -> bool:
	"""Unload a plugin from an NPC"""
	if not npc_active_plugins.has(npc_id):
		return false
	
	if not npc_active_plugins[npc_id].has(plugin_name):
		return false
	
	var plugin_instance = npc_active_plugins[npc_id][plugin_name]
	
	# Call cleanup if exists
	if plugin_instance.has_method("_plugin_cleanup"):
		plugin_instance._plugin_cleanup()
	
	# Remove from tracking
	npc_active_plugins[npc_id].erase(plugin_name)
	plugin_instances.erase(plugin_name + "_" + npc_id)
	
	plugin_unloaded.emit(npc_id, plugin_name)
	print("[NPCPluginManager] Unloaded plugin '", plugin_name, "' from NPC: ", npc_id)
	
	return true

func reload_plugin_for_npc(npc_id: String, plugin_name: String) -> bool:
	"""Reload a plugin (unload then load)"""
	unload_plugin_from_npc(npc_id, plugin_name)
	return load_plugin_for_npc(npc_id, plugin_name)

# ============================================
# PLUGIN QUERYING
# ============================================

func is_plugin_loaded_for_npc(npc_id: String, plugin_name: String) -> bool:
	"""Check if a plugin is loaded for an NPC"""
	if not npc_active_plugins.has(npc_id):
		return false
	return npc_active_plugins[npc_id].has(plugin_name)

func get_plugin_for_npc(npc_id: String, plugin_name: String):
	"""Get plugin instance for an NPC"""
	if not npc_active_plugins.has(npc_id):
		return null
	return npc_active_plugins[npc_id].get(plugin_name, null)

func get_all_plugins_for_npc(npc_id: String) -> Array:
	"""Get all loaded plugins for an NPC"""
	if not npc_active_plugins.has(npc_id):
		return []
	return npc_active_plugins[npc_id].keys()

func get_npc_count_for_plugin(plugin_name: String) -> int:
	"""Get number of NPCs using a plugin"""
	var count = 0
	for npc_id in npc_active_plugins.keys():
		if npc_active_plugins[npc_id].has(plugin_name):
			count += 1
	return count

# ============================================
# BATCH OPERATIONS
# ============================================

func load_plugin_for_all_npcs(plugin_name: String, config_override: Dictionary = {}) -> int:
	"""Load a plugin for all registered NPCs"""
	var success_count = 0
	
	# Get all NPCs from behavior controller
	if NPCBehaviorController:
		var all_npcs = NPCBehaviorController.get_all_npc_ids()
		for npc_id in all_npcs:
			if load_plugin_for_npc(npc_id, plugin_name, config_override):
				success_count += 1
	
	return success_count

func unload_plugin_from_all_npcs(plugin_name: String) -> int:
	"""Unload a plugin from all NPCs"""
	var success_count = 0
	
	for npc_id in npc_active_plugins.keys():
		if unload_plugin_from_npc(npc_id, plugin_name):
			success_count += 1
	
	return success_count

# ============================================
# PLUGIN COMMUNICATION
# ============================================

func call_plugin_method(npc_id: String, plugin_name: String, method: String, args: Array = []):
	"""Call a method on a specific plugin"""
	var plugin = get_plugin_for_npc(npc_id, plugin_name)
	if not plugin:
		return null
	
	if not plugin.has_method(method):
		return null
	
	return plugin.callv(method, args)

func broadcast_to_plugin(plugin_name: String, method: String, args: Array = []) -> Dictionary:
	"""Call a method on all instances of a plugin"""
	var results = {}
	
	for npc_id in npc_active_plugins.keys():
		if npc_active_plugins[npc_id].has(plugin_name):
			var result = call_plugin_method(npc_id, plugin_name, method, args)
			results[npc_id] = result
	
	return results

# ============================================
# AUTO-LOAD MANAGEMENT
# ============================================

func auto_load_plugins_for_npc(npc_id: String):
	"""Auto-load plugins marked for auto-loading"""
	for plugin_name in registered_plugins.keys():
		if registered_plugins[plugin_name].auto_load:
			load_plugin_for_npc(npc_id, plugin_name)

# ============================================
# PLUGIN DISCOVERY
# ============================================

func get_available_plugins() -> Array:
	"""Get list of all registered plugins"""
	var plugins = []
	for plugin_name in registered_plugins.keys():
		plugins.append({
			"name": plugin_name,
			"description": registered_plugins[plugin_name].description,
			"version": registered_plugins[plugin_name].version,
			"optional": registered_plugins[plugin_name].optional,
			"active_count": get_npc_count_for_plugin(plugin_name)
		})
	return plugins

func get_plugin_info(plugin_name: String) -> Dictionary:
	"""Get detailed info about a plugin"""
	if not registered_plugins.has(plugin_name):
		return {}
	
	var info = registered_plugins[plugin_name].duplicate()
	info["active_count"] = get_npc_count_for_plugin(plugin_name)
	return info

# ============================================
# SERIALIZATION
# ============================================

func save_plugin_state(npc_id: String) -> Dictionary:
	"""Save plugin state for an NPC"""
	var state = {}
	
	if npc_active_plugins.has(npc_id):
		for plugin_name in npc_active_plugins[npc_id].keys():
			var plugin = npc_active_plugins[npc_id][plugin_name]
			if plugin.has_method("_plugin_save_state"):
				state[plugin_name] = plugin._plugin_save_state()
			else:
				state[plugin_name] = {}
	
	return state

func load_plugin_state(npc_id: String, state: Dictionary):
	"""Load plugin state for an NPC"""
	for plugin_name in state.keys():
		if npc_active_plugins.has(npc_id) and npc_active_plugins[npc_id].has(plugin_name):
			var plugin = npc_active_plugins[npc_id][plugin_name]
			if plugin.has_method("_plugin_load_state"):
				plugin._plugin_load_state(state[plugin_name])

# ============================================
# BUILT-IN PLUGINS REGISTRATION
# ============================================

func _ready():
	"""Register built-in plugins"""
	register_builtin_plugins()
	print("[NPCPluginManager] Initialized with ", registered_plugins.size(), " plugins")

func register_builtin_plugins():
	"""Register all built-in plugin types"""
	
	# Mood Plugin
	register_plugin("mood_enhanced", preload("res://plugins/mood_enhanced_plugin.gd"), {
		"description": "Advanced mood management with emotional intelligence",
		"version": "1.0.0",
		"auto_load": true,
		"optional": false
	})
	
	# Social Plugin
	register_plugin("social_dynamics", preload("res://plugins/social_dynamics_plugin.gd"), {
		"description": "Manages social interactions and group dynamics",
		"version": "1.0.0",
		"auto_load": true,
		"optional": false
	})
	
	# Economy Plugin
	register_plugin("economy_trader", preload("res://plugins/economy_trader_plugin.gd"), {
		"description": "Dynamic trading and economic behavior",
		"version": "1.0.0",
		"auto_load": false,
		"optional": true,
		"dependencies": ["mood_enhanced"]
	})
	
	# Quest Plugin
	register_plugin("quest_giver", preload("res://plugins/quest_giver_plugin.gd"), {
		"description": "AI-driven quest generation and management",
		"version": "1.0.0",
		"auto_load": false,
		"optional": true
	})
	
	# Memory Plugin
	register_plugin("memory_enhanced", preload("res://plugins/memory_enhanced_plugin.gd"), {
		"description": "Enhanced memory with semantic search",
		"version": "1.0.0",
		"auto_load": true,
		"optional": false
	})
	
	# Schedule Plugin
	register_plugin("schedule_manager", preload("res://plugins/schedule_manager_plugin.gd"), {
		"description": "Advanced scheduling with flexibility",
		"version": "1.0.0",
		"auto_load": true,
		"optional": false
	})
	
	# Rumor Plugin
	register_plugin("rumor_system", preload("res://plugins/rumor_system_plugin.gd"), {
		"description": "Spreads and manages rumors between NPCs",
		"version": "1.0.0",
		"auto_load": false,
		"optional": true,
		"dependencies": ["social_dynamics"]
	})
	
	# Skill Plugin
	register_plugin("skill_mastery", preload("res://plugins/skill_mastery_plugin.gd"), {
		"description": "Advanced skill progression and mastery",
		"version": "1.0.0",
		"auto_load": false,
		"optional": true
	})
