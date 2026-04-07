extends Node

# Backend API Client for Godot
# Handles HTTP requests to FastAPI backend

signal request_completed(request_id: String, result: Dictionary)
signal request_failed(request_id: String, error: String)

var base_url: String = "http://localhost:8080/api/v1"
var http_client: HTTPRequest
var request_counter: int = 0

func _ready():
	http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_request_completed)

func set_base_url(url: String):
	base_url = url

func _generate_request_id() -> String:
	request_counter += 1
	return "req_%d" % request_counter

func npc_dialogue(npc_id: String, npc_name: String, player_message: String, context: Dictionary = {}, personality: Dictionary = {}) -> String:
	"""Generate NPC dialogue via backend API"""
	var request_id = _generate_request_id()
	var url = base_url + "/npc/dialogue"

	var body = {
		"npc_id": npc_id,
		"npc_name": npc_name,
		"player_message": player_message,
		"context": context,
		"personality": personality,
		"conversation_history": []
	}

	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]

	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		emit_signal("request_failed", request_id, "HTTP request failed: " + str(error))
		return ""

	# Wait for response (simplified - in production use async callbacks)
	await http_client.request_completed

	return request_id

func get_npc_dialogue_sync(npc_id: String, npc_name: String, player_message: String, context: Dictionary = {}, personality: Dictionary = {}) -> Dictionary:
	"""Synchronous NPC dialogue request (blocks until response)"""
	var url = base_url + "/npc/dialogue"

	var body = {
		"npc_id": npc_id,
		"npc_name": npc_name,
		"player_message": player_message,
		"context": context,
		"personality": personality,
		"conversation_history": []
	}

	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]

	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		return {"error": "HTTP request failed", "code": error}

	# Wait for completion
	var result = await http_client.request_completed
	var response_code = result[1]
	var response_body = result[3]

	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(response_body.get_string_from_utf8())
		if parse_error == OK:
			return json.data
		else:
			return {"error": "JSON parse failed", "code": parse_error}
	else:
		return {"error": "HTTP error", "code": response_code}

func chat_completion(messages: Array, task_type: String = "general") -> Dictionary:
	"""General chat completion"""
	var url = base_url + "/chat"

	var body = {
		"messages": messages,
		"task_type": task_type,
		"temperature": 0.7
	}

	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]

	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		return {"error": "HTTP request failed", "code": error}

	var result = await http_client.request_completed
	var response_code = result[1]
	var response_body = result[3]

	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(response_body.get_string_from_utf8())
		if parse_error == OK:
			return json.data
		else:
			return {"error": "JSON parse failed"}
	else:
		return {"error": "HTTP error", "code": response_code}

func health_check() -> Dictionary:
	"""Check backend health"""
	var url = base_url.replace("/api/v1", "") + "/health"

	var error = http_client.request(url)
	if error != OK:
		return {"status": "unreachable", "error": str(error)}

	var result = await http_client.request_completed
	var response_code = result[1]
	var response_body = result[3]

	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(response_body.get_string_from_utf8())
		if parse_error == OK:
			return json.data
		else:
			return {"status": "error", "message": "Invalid response"}
	else:
		return {"status": "error", "code": response_code}

func generate_tts(npc_id: String, text: String, emotion: String = "neutral") -> Dictionary:
	"""Request backend TTS (with backend-controlled fallback mode)."""
	var url = base_url + "/tts/generate"
	var body = {
		"npc_id": npc_id,
		"text": text,
		"emotion": emotion
	}
	var error = http_client.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		return {"success": false, "error": "HTTP request failed", "code": error}
	
	var result = await http_client.request_completed
	var response_code = result[1]
	var response_body = result[3]
	if response_code != 200:
		return {"success": false, "error": "HTTP error", "code": response_code}
	
	var json = JSON.new()
	var parse_error = json.parse(response_body.get_string_from_utf8())
	if parse_error != OK:
		return {"success": false, "error": "JSON parse failed", "code": parse_error}
	return json.data

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle async request completion"""
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())
		if parse_error == OK:
			emit_signal("request_completed", "async_req", json.data)
		else:
			emit_signal("request_failed", "async_req", "JSON parse error")
	else:
		emit_signal("request_failed", "async_req", "HTTP error: " + str(response_code))
