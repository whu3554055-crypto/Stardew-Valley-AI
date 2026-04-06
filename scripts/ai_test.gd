extends Node

# Quick test script to verify AI integration
# Attach this to a test scene or run from main scene

func _ready():
	print("======================================")
	print("  AI NPC System Test")
	print("======================================")
	print("")
	
	test_ollama_connection()
	await get_tree().create_timer(2.0).timeout
	
	test_ai_dialogue()

func test_ollama_connection():
	print("[Test 1] Checking Ollama connection...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = "http://localhost:11434/api/tags"
	var error = http.request(url)
	
	if error != OK:
		print("  ❌ Failed to connect to Ollama")
		print("  Make sure Ollama is running: ollama serve")
		http.queue_free()
		return
	
	var result = await http.request_completed
	
	if result[1] == 200:
		print("  ✅ Ollama is running!")
		var response = JSON.parse_string(result[3].get_string_from_utf8())
		if response and response.has("models"):
			print("  Available models:")
			for model in response.models:
				print("    - ", model.name)
	else:
		print("  ❌ Ollama connection failed (HTTP ", result[1], ")")
	
	http.queue_free()

func test_ai_dialogue():
	print("")
	print("[Test 2] Testing AI dialogue generation...")
	
	if not AIAgentManager:
		print("  ❌ AIAgentManager not loaded")
		return
	
	print("  Configuration:")
	print("    Model: ", AIAgentManager.api_config.model)
	print("    URL: ", AIAgentManager.api_config.base_url)
	print("")
	
	# Connect to signal
	AIAgentManager.dialogue_generated.connect(_on_test_dialogue)
	AIAgentManager.agent_error.connect(_on_test_error)
	
	# Send test request
	print("  Sending test request...")
	AIAgentManager.quick_chat(
		"test_npc",
		"TestNPC",
		"Hello! How are you today?",
		{
			"traits": ["friendly", "helpful"],
			"occupation": "Tester",
			"backstory": "A test character.",
			"speech_style": "casual",
			"interests": ["testing"]
		},
		{
			"time": "morning",
			"weather": "sunny",
			"season": "spring",
			"location": "town",
			"relationship": 5
		}
	)
	
	print("  Waiting for response...")

func _on_test_dialogue(npc_id: String, dialogue: String):
	print("  ✅ AI Response received!")
	print("  NPC: ", dialogue)
	print("")
	print("======================================")
	print("  All tests completed!")
	print("======================================")

func _on_test_error(npc_id: String, error: String):
	print("  ❌ AI Error: ", error)
	print("")
	print("Troubleshooting:")
	print("  1. Check Ollama is running: ollama serve")
	print("  2. Verify model exists: ollama list")
	print("  3. Check model name matches: qwen3.5:9b")
