extends Node
## AgenticChainStorage - Manages storage and persistence of agentic chain templates.
## Handles runtime chains, manual queue, and file I/O operations.
##
## Responsibilities:
## - Runtime chain template CRUD operations
## - Manual chain inbox management
## - Persistent storage (load/save)
## - Chain ID tracking

# === 常量 ===

const RUNTIME_STORE_PATH := "user://runtime_chain_templates.json"
const MANUAL_INBOX_PATH := "user://manual_chain_inbox.json"

# === 成员变量 ===

var _runtime_chain_ids: Array[String] = []
var _manual_queue: Array[Dictionary] = []

# === 信号 ===

signal runtime_chain_added(chain_id: String)
signal runtime_chain_removed(chain_id: String)
signal manual_chain_queued(chain_data: Dictionary)
signal storage_saved()
signal storage_loaded()

# === 生命周期方法 ===

func _ready() -> void:
	_load_runtime_store()
	_load_manual_inbox()

# === 公共方法 ===

## Add a runtime chain ID to tracking
func add_runtime_chain(chain_id: String) -> void:
	if not _runtime_chain_ids.has(chain_id):
		_runtime_chain_ids.append(chain_id)
		emit_signal("runtime_chain_added", chain_id)
		_save_runtime_store()

## Remove a runtime chain ID from tracking
func remove_runtime_chain(chain_id: String) -> void:
	if _runtime_chain_ids.has(chain_id):
		_runtime_chain_ids.erase(chain_id)
		emit_signal("runtime_chain_removed", chain_id)
		_save_runtime_store()

## Get all tracked runtime chain IDs
func get_runtime_chain_ids() -> Array[String]:
	return _runtime_chain_ids.duplicate()

## Check if chain ID is tracked
func has_runtime_chain(chain_id: String) -> bool:
	return _runtime_chain_ids.has(chain_id)

## Add a chain to manual inbox queue
func queue_manual_chain(chain_data: Dictionary) -> void:
	_manual_queue.append(chain_data)
	_save_manual_inbox()
	emit_signal("manual_chain_queued", chain_data)

## Take the first chain from manual inbox (FIFO)
func take_manual_chain() -> Dictionary:
	if _manual_queue.is_empty():
		return {}
	
	var chain = _manual_queue.pop_front()
	_save_manual_inbox()
	return chain

## Get manual queue size
func get_manual_queue_size() -> int:
	return _manual_queue.size()

## Save runtime store to disk
func save_runtime_store() -> void:
	_save_runtime_store()

## Save manual inbox to disk
func save_manual_inbox() -> void:
	_save_manual_inbox()

## Clear all runtime chains
func clear_runtime_chains() -> void:
	_runtime_chain_ids.clear()
	_save_runtime_store()

## Clear manual queue
func clear_manual_queue() -> void:
	_manual_queue.clear()
	_save_manual_inbox()

# === 私有方法 ===

func _load_runtime_store() -> void:
	"""Load runtime chain IDs from disk"""
	if not FileAccess.file_exists(RUNTIME_STORE_PATH):
		return
	
	var file = FileAccess.open(RUNTIME_STORE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[AgenticChainStorage] Failed to open runtime store")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data is Dictionary and data.has("runtime_chain_ids"):
		_runtime_chain_ids = data.runtime_chain_ids as Array[String]
		emit_signal("storage_loaded")

func _save_runtime_store() -> void:
	"""Save runtime chain IDs to disk"""
	var data = {
		"runtime_chain_ids": _runtime_chain_ids,
		"saved_at": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(RUNTIME_STORE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[AgenticChainStorage] Failed to save runtime store")
		return
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	emit_signal("storage_saved")

func _load_manual_inbox() -> void:
	"""Load manual chain inbox from disk"""
	if not FileAccess.file_exists(MANUAL_INBOX_PATH):
		return
	
	var file = FileAccess.open(MANUAL_INBOX_PATH, FileAccess.READ)
	if file == null:
		push_warning("[AgenticChainStorage] Failed to open manual inbox")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data is Dictionary and data.has("queue"):
		_manual_queue = data.queue as Array[Dictionary]

func _save_manual_inbox() -> void:
	"""Save manual chain inbox to disk"""
	var data = {
		"queue": _manual_queue,
		"size": _manual_queue.size(),
		"saved_at": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(MANUAL_INBOX_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[AgenticChainStorage] Failed to save manual inbox")
		return
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
