extends Node

class_name WebSocketClient

# WebSocket connection for real-time communication with backend
var ws: WebSocketPeer = null
var server_url: String = "ws://localhost:8080/ws/"
var client_id: String = "player1"
var connected: bool = false

# Event handlers
signal message_received(data: Dictionary)
signal connection_status_changed(status: bool)
signal npc_dialogue_received(npc_id: String, dialogue: String, emotion: String)
signal agent_action_received(npc_id: String, action: String, result: Dictionary)
signal world_event_received(event_type: String, data: Dictionary)

# Reconnection settings
var auto_reconnect: bool = true
var reconnect_interval: float = 5.0
var reconnect_timer: Timer = null

func _ready():
	_setup_reconnect_timer()
	connect_to_server()

func _setup_reconnect_timer():
	reconnect_timer = Timer.new()
	reconnect_timer.wait_time = reconnect_interval
	reconnect_timer.one_shot = true
	reconnect_timer.timeout.connect(_on_reconnect_timeout)
	add_child(reconnect_timer)

func connect_to_server(custom_client_id: String = ""):
	"""Connect to WebSocket server"""
	if custom_client_id != "":
		client_id = custom_client_id
	
	if ws:
		ws.close()
	
	ws = WebSocketPeer.new()
	var full_url = server_url + client_id
	var error = ws.connect_to_url(full_url)
	
	if error == OK:
		print("[WebSocket] Connecting to: ", full_url)
	else:
		print("[WebSocket] Connection failed: ", error)
		_try_reconnect()

func _process(delta):
	if not ws:
		return
	
	ws.poll()
	
	var state = ws.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				emit_signal("connection_status_changed", true)
				print("[WebSocket] Connected successfully!")
			
			# Process incoming messages
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var message_str = packet.get_string_from_utf8()
				_parse_message(message_str)
		
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				emit_signal("connection_status_changed", false)
				print("[WebSocket] Connection closed")
				_try_reconnect()
		
		WebSocketPeer.STATE_CONNECTING:
			pass  # Still connecting

func _parse_message(message_str: String):
	"""Parse incoming WebSocket message"""
	var json = JSON.new()
	var parse_result = json.parse(message_str)
	
	if parse_result != OK:
		print("[WebSocket] JSON parse error: ", parse_result)
		return
	
	var data = json.data
	
	# Handle different message types
	if data.has("type"):
		match data.type:
			"system":
				_handle_system_message(data)
			"npc_dialogue":
				_handle_npc_dialogue(data)
			"agent_action":
				_handle_agent_action(data)
			"world_event":
				_handle_world_event(data)
			_:
				# Generic message
				emit_signal("message_received", data)
	elif data.has("jsonrpc"):
		# MCP response
		emit_signal("message_received", data)

func _handle_system_message(data: Dictionary):
	"""Handle system messages"""
	if data.has("event"):
		match data.event:
			"connected":
				print("[WebSocket] Server acknowledged connection")
			"subscribed":
				print("[WebSocket] Subscribed to: ", data.data.get("event", "unknown"))
			"pong":
				pass  # Heartbeat response

func _handle_npc_dialogue(data: Dictionary):
	"""Handle NPC dialogue events"""
	if data.has("data"):
		var dialogue_data = data.data
		var npc_id = dialogue_data.get("npc_id", "unknown")
		var dialogue = dialogue_data.get("dialogue", "")
		var emotion = dialogue_data.get("emotion", "neutral")
		
		emit_signal("npc_dialogue_received", npc_id, dialogue, emotion)
		print("[WebSocket] NPC Dialogue from ", npc_id, ": ", dialogue)

func _handle_agent_action(data: Dictionary):
	"""Handle autonomous agent actions"""
	if data.has("data"):
		var action_data = data.data
		var npc_id = action_data.get("npc_id", "unknown")
		var action = action_data.get("action", "")
		var result = action_data.get("result", {})
		
		emit_signal("agent_action_received", npc_id, action, result)
		print("[WebSocket] Agent Action: ", npc_id, " -> ", action)

func _handle_world_event(data: Dictionary):
	"""Handle world events (weather change, time update, etc.)"""
	if data.has("data"):
		var event_type = data.get("event", "unknown")
		var event_data = data.data
		
		emit_signal("world_event_received", event_type, event_data)
		print("[WebSocket] World Event: ", event_type)

func _try_reconnect():
	"""Attempt to reconnect if auto_reconnect is enabled"""
	if auto_reconnect and not reconnect_timer.is_stopped():
		print("[WebSocket] Will reconnect in ", reconnect_interval, " seconds...")
		reconnect_timer.start()

func _on_reconnect_timeout():
	"""Reconnect timer callback"""
	if not connected:
		print("[WebSocket] Attempting to reconnect...")
		connect_to_server()

func disconnect_from_server():
	"""Manually disconnect from server"""
	auto_reconnect = false
	if ws:
		ws.close()
		ws = null
	connected = false
	print("[WebSocket] Disconnected by user")

func send_message(data: Dictionary) -> bool:
	"""Send message to server via WebSocket"""
	if not ws or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("[WebSocket] Not connected, cannot send message")
		return false
	
	var json_str = JSON.stringify(data)
	var error = ws.send_text(json_str)
	
	if error == OK:
		return true
	else:
		print("[WebSocket] Send failed: ", error)
		return false

func send_mcp_request(method: String, params: Dictionary, request_id: String = "") -> bool:
	"""Send MCP (JSON-RPC 2.0) request over WebSocket"""
	if request_id == "":
		request_id = "req-" + str(Time.get_ticks_msec())
	
	var mcp_message = {
		"jsonrpc": "2.0",
		"id": request_id,
		"method": method,
		"params": params
	}
	
	return send_message(mcp_message)

func subscribe_to_event(event_type: String) -> bool:
	"""Subscribe to specific event type"""
	var subscribe_msg = {
		"type": "subscribe",
		"event": event_type
	}
	
	return send_message(subscribe_msg)

func send_heartbeat() -> bool:
	"""Send heartbeat to keep connection alive"""
	var ping_msg = {
		"type": "ping"
	}
	
	return send_message(ping_msg)

func get_connection_stats() -> Dictionary:
	"""Get connection statistics"""
	return {
		"connected": connected,
		"state": ws.get_ready_state() if ws else -1,
		"client_id": client_id,
		"server_url": server_url
	}

func _exit_tree():
	"""Cleanup on exit"""
	disconnect_from_server()
	if reconnect_timer:
		reconnect_timer.stop()
		reconnect_timer.queue_free()
