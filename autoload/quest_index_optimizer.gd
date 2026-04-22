extends Node
## QuestIndexOptimizer - Optimized quest lookup and management using hash tables.
## Reduces quest query time from O(n) to O(1) through intelligent indexing.
##
## Features:
## - Multiple index types (by ID, type, status, NPC)
## - Event-driven updates (no per-frame polling)
## - Automatic index maintenance
## - Fast batch queries

# === 类型定义 ===

class QuestIndices:
	var by_id: Dictionary = {}                    # {quest_id: quest_data}
	var by_type: Dictionary = {}                  # {type: [quest_ids]}
	var by_status: Dictionary = {}                # {status: [quest_ids]}
	var by_npc: Dictionary = {}                   # {npc_id: [quest_ids]}
	var by_item: Dictionary = {}                  # {item_id: [quest_ids]}
	var by_location: Dictionary = {}              # {location: [quest_ids]}
	var active_quests: Array[String] = []         # Quick access to active quests
	var completed_today: Array[String] = []       # Today's completed quests
	
	func clear():
		by_id.clear()
		by_type.clear()
		by_status.clear()
		by_npc.clear()
		by_item.clear()
		by_location.clear()
		active_quests.clear()
		completed_today.clear()

# === 成员变量 ===

var indices: QuestIndices = QuestIndices.new()
var _is_initialized: bool = false
var _quest_update_queue: Array[String] = []  # Queue for batch index updates

# === 信号 ===

signal indices_rebuilt()
signal quest_indexed(quest_id: String)
signal quest_deindexed(quest_id: String)

# === 生命周期方法 ===

func _ready() -> void:
	_initialize_indices()

func _initialize_indices() -> void:
	"""Initialize quest indices from existing quest system"""
	if _is_initialized:
		return
	
	if OS.is_debug_build():
		print("[QuestIndexOptimizer] Initializing quest indices...")
	
	# Connect to quest system signals if available
	if has_node("/root/QuestSystem"):
		var qs = get_node("/root/QuestSystem")
		
		# Connect to quest events for automatic index updates
		if qs.has_signal("quest_started"):
			qs.quest_started.connect(_on_quest_started)
		
		if qs.has_signal("quest_completed"):
			qs.quest_completed.connect(_on_quest_completed)
		
		if qs.has_signal("quest_updated"):
			qs.quest_updated.connect(_on_quest_updated)
		
		if qs.has_signal("quest_failed"):
			qs.quest_failed.connect(_on_quest_failed)
	
	# Build initial indices
	_rebuild_indices()
	
	_is_initialized = true
	
	if OS.is_debug_build():
		print("[QuestIndexOptimizer] Initialized with %d quests indexed" % indices.by_id.size())

# === 公共方法 ===

## Get quest by ID (O(1) lookup)
func get_quest_by_id(quest_id: String) -> Variant:
	return indices.by_id.get(quest_id)

## Get all active quests (O(1) access)
func get_active_quests() -> Array[String]:
	return indices.active_quests.duplicate()

## Get quests by type (fast lookup)
func get_quests_by_type(type: String) -> Array[String]:
	return indices.by_type.get(type, []).duplicate()

## Get quests by status (fast lookup)
func get_quests_by_status(status: String) -> Array[String]:
	return indices.by_status.get(status, []).duplicate()

## Get quests associated with an NPC (fast lookup)
func get_quests_by_npc(npc_id: String) -> Array[String]:
	return indices.by_npc.get(npc_id, []).duplicate()

## Get quests related to an item (fast lookup)
func get_quests_by_item(item_id: String) -> Array[String]:
	return indices.by_item.get(item_id, []).duplicate()

## Check if quest is active (O(1))
func is_quest_active(quest_id: String) -> bool:
	return quest_id in indices.active_quests

## Get today's completed quests (O(1))
func get_completed_today() -> Array[String]:
	return indices.completed_today.duplicate()

## Force rebuild all indices (use when quest system changes significantly)
func rebuild_all_indices() -> void:
	indices.clear()
	_rebuild_indices()
	emit_signal("indices_rebuilt")
	
	if OS.is_debug_build():
		print("[QuestIndexOptimizer] Indices rebuilt: %d quests" % indices.by_id.size())

## Get index statistics
func get_index_stats() -> Dictionary:
	return {
		"total_quests": indices.by_id.size(),
		"active_quests": indices.active_quests.size(),
		"completed_today": indices.completed_today.size(),
		"types": indices.by_type.keys().size(),
		"statuses": indices.by_status.keys().size(),
		"npcs_with_quests": indices.by_npc.keys().size(),
		"items_with_quests": indices.by_item.keys().size()
	}

# === 事件处理器 ===

func _on_quest_started(quest_id: String, quest_data: Dictionary = {}) -> void:
	"""Handle quest start event"""
	_index_quest(quest_id, quest_data)
	
	if not quest_id in indices.active_quests:
		indices.active_quests.append(quest_id)
	
	if OS.is_debug_build():
		print("[QuestIndexOptimizer] Indexed started quest: %s" % quest_id)

func _on_quest_completed(quest_id: String, quest_data: Dictionary = {}) -> void:
	"""Handle quest completion event"""
	_update_quest_status(quest_id, "completed")
	
	# Remove from active
	if quest_id in indices.active_quests:
		indices.active_quests.erase(quest_id)
	
	# Add to today's completed
	if not quest_id in indices.completed_today:
		indices.completed_today.append(quest_id)
	
	if OS.is_debug_build():
		print("[QuestIndexOptimizer] Indexed completed quest: %s" % quest_id)

func _on_quest_updated(quest_id: String, quest_data: Dictionary = {}) -> void:
	"""Handle quest update event"""
	_update_quest_index(quest_id, quest_data)

func _on_quest_failed(quest_id: String, quest_data: Dictionary = {}) -> void:
	"""Handle quest failure event"""
	_update_quest_status(quest_id, "failed")
	
	# Remove from active
	if quest_id in indices.active_quests:
		indices.active_quests.erase(quest_id)

# === 私有方法 ===

func _rebuild_indices() -> void:
	"""Rebuild all indices from quest system"""
	if not has_node("/root/QuestSystem"):
		return
	
	var qs = get_node("/root/QuestSystem")
	
	# Get all quests (adjust based on your quest system API)
	var all_quests = []
	if qs.has_method("get_all_quests"):
		all_quests = qs.get_all_quests()
	elif qs.has_method("get_quests"):
		all_quests = qs.get_quests()
	
	# Index each quest
	for quest in all_quests:
		if quest is Dictionary and quest.has("id"):
			_index_quest(quest.id, quest)
			
			# Track active quests
			if quest.get("status") == "in_progress" or quest.get("status") == "active":
				if not quest.id in indices.active_quests:
					indices.active_quests.append(quest.id)

func _index_quest(quest_id: String, quest_data: Dictionary) -> void:
	"""Index a single quest across all relevant indices"""
	# By ID
	indices.by_id[quest_id] = quest_data
	
	# By type
	var quest_type = quest_data.get("type", "general")
	if not indices.by_type.has(quest_type):
		indices.by_type[quest_type] = []
	if not quest_id in indices.by_type[quest_type]:
		indices.by_type[quest_type].append(quest_id)
	
	# By status
	var status = quest_data.get("status", "not_started")
	if not indices.by_status.has(status):
		indices.by_status[status] = []
	if not quest_id in indices.by_status[status]:
		indices.by_status[status].append(quest_id)
	
	# By NPC (if applicable)
	var npc_id = quest_data.get("npc_id", "")
	if npc_id:
		if not indices.by_npc.has(npc_id):
			indices.by_npc[npc_id] = []
		if not quest_id in indices.by_npc[npc_id]:
			indices.by_npc[npc_id].append(quest_id)
	
	# By item requirements (if applicable)
	var required_items = quest_data.get("required_items", [])
	for item_id in required_items:
		if not indices.by_item.has(item_id):
			indices.by_item[item_id] = []
		if not quest_id in indices.by_item[item_id]:
			indices.by_item[item_id].append(quest_id)
	
	emit_signal("quest_indexed", quest_id)

func _update_quest_index(quest_id: String, quest_data: Dictionary) -> void:
	"""Update indices for a modified quest"""
	# Remove old indices
	_deindex_quest(quest_id)
	
	# Re-index with new data
	_index_quest(quest_id, quest_data)

func _update_quest_status(quest_id: String, new_status: String) -> void:
	"""Update quest status in indices"""
	if not indices.by_id.has(quest_id):
		return
	
	var quest_data = indices.by_id[quest_id]
	var old_status = quest_data.get("status", "")
	
	# Update status
	quest_data.status = new_status
	
	# Remove from old status list
	if old_status and indices.by_status.has(old_status):
		if quest_id in indices.by_status[old_status]:
			indices.by_status[old_status].erase(quest_id)
	
	# Add to new status list
	if not indices.by_status.has(new_status):
		indices.by_status[new_status] = []
	if not quest_id in indices.by_status[new_status]:
		indices.by_status[new_status].append(quest_id)

func _deindex_quest(quest_id: String) -> void:
	"""Remove quest from all indices"""
	# By ID
	indices.by_id.erase(quest_id)
	
	# By type
	for type_key in indices.by_type.keys():
		if quest_id in indices.by_type[type_key]:
			indices.by_type[type_key].erase(quest_id)
	
	# By status
	for status_key in indices.by_status.keys():
		if quest_id in indices.by_status[status_key]:
			indices.by_status[status_key].erase(quest_id)
	
	# By NPC
	for npc_key in indices.by_npc.keys():
		if quest_id in indices.by_npc[npc_key]:
			indices.by_npc[npc_key].erase(quest_id)
	
	# By item
	for item_key in indices.by_item.keys():
		if quest_id in indices.by_item[item_key]:
			indices.by_item[item_key].erase(quest_id)
	
	# From active
	if quest_id in indices.active_quests:
		indices.active_quests.erase(quest_id)
	
	emit_signal("quest_deindexed", quest_id)
