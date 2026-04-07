extends Node2D

@onready var player = $Player
@onready var tilemap = $TileMap
@onready var farm_manager = $FarmManager
@onready var ui_layer = $UILayer
@onready var time_label = $UILayer/TimeLabel
@onready var gold_label = $UILayer/GoldLabel
@onready var dialogue_box = $UILayer/DialogueBox
@onready var weather_label = $UILayer/WeatherLabel
@onready var season_label = $UILayer/SeasonLabel
@onready var day_label = $UILayer/DayLabel
@onready var ai_config_button = $UILayer/AIConfigButton

var current_npc = null
var ai_config_scene = preload("res://scenes/ai_config_ui.tscn")
var ai_config_instance = null

func _ready():
	# Connect signals
	player.interacted.connect(_on_player_interact)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.season_changed.connect(_on_season_changed)
	
	# Connect farming signals for quest tracking
	farm_manager.crop_planted.connect(_on_crop_planted)
	farm_manager.crop_harvested.connect(_on_crop_harvested)
	
	# Initialize systems
	update_ui()
	initialize_playable_first_loop()
	
	# Give starter items
	give_starter_items()
	
	# Setup AI config button
	if ai_config_button:
		ai_config_button.pressed.connect(_on_ai_config_pressed)
	
	print("======================================")
	print("  Stardew Valley Clone - AI Edition")
	print("======================================")
	print("AI Model: ", AIAgentManager.api_config.model if AIAgentManager else "Not loaded")
	print("NPCs with AI: Pierre, Abigail, Lewis")
	print("Press E to interact with NPCs")
	print("======================================")

func initialize_playable_first_loop():
	"""
	Playable-first bootstrap:
	- Start one beginner quest immediately
	- Generate one daily narrative seed
	"""
	if QuestSystem:
		QuestSystem.start_quest("tutorial_plant")
	
	if DailyNarrativeSystem:
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		if not narrative.is_empty():
			show_dialogue("Today's story: " + str(narrative.get("title", "A new day begins")))
			_apply_narrative_daily_quest(narrative)

	if QuestSystem:
		QuestSystem.quest_completed.connect(_on_quest_completed)

func give_starter_items():
	var hoe_item = ItemDatabase.get_item("hoe")
	var watering_item = ItemDatabase.get_item("watering_can")
	var parsnip_seeds = ItemDatabase.get_item("parsnip_seeds")
	
	if not hoe_item.is_empty():
		InventoryManager.add_item(hoe_item.duplicate(true))
	if not watering_item.is_empty():
		InventoryManager.add_item(watering_item.duplicate(true))
	if not parsnip_seeds.is_empty():
		for i in range(5):
			InventoryManager.add_item(parsnip_seeds.duplicate(true))

func _on_player_interact(tile_position: Vector2):
	var tile_coords = tilemap.local_to_map(tile_position)

	# Check for NPC interaction first
	if current_npc:
		var dialogue = current_npc.interact()
		show_dialogue(dialogue)
		return

	# Farming interactions
	var selected_item = InventoryManager.get_selected_item()

	if selected_item:
		if selected_item.type == "seed":
			if farm_manager.can_plant_here(tile_coords):
				farm_manager.plant_seed(tile_coords, selected_item.id)
				InventoryManager.remove_item(InventoryManager.selected_slot)
				QuestSystem.track_event("plant", {"crop_id": selected_item.id, "count": 1})
		elif selected_item.id == "hoe":
			farm_manager.till_soil(tile_coords)
		elif selected_item.id == "watering_can":
			farm_manager.water_plant(tile_coords)

func _on_time_changed(new_time):
	update_ui()

func _on_day_changed(new_day):
	update_ui()
	# Auto-water crops if raining
	if WeatherSystem.is_raining():
		auto_water_crops()
	
	# Lightweight daily refresh keeps the game feeling alive.
	if DailyNarrativeSystem:
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		_apply_narrative_daily_quest(narrative)

func _on_quest_completed(quest_id: String):
	if QuestSystem and QuestSystem.quests.has(quest_id):
		var title = QuestSystem.quests[quest_id].get("title", quest_id)
		show_dialogue("Quest completed: " + str(title))

func _apply_narrative_daily_quest(narrative: Dictionary):
	if narrative.is_empty():
		return
	if not QuestSystem:
		return
	var events = narrative.get("events", [])
	if events is Array and events.size() > 0:
		QuestSystem.add_story_daily_quest(events[0])

func _on_season_changed(new_season):
	update_ui()

func auto_water_crops():
	for position in farm_manager.planted_crops:
		farm_manager.water_plant(position)

func _on_crop_planted(position, crop_id):
	QuestSystem.track_event("plant", {"crop_id": crop_id, "count": 1})

func _on_crop_harvested(position, crop_id, quantity):
	QuestSystem.track_event("harvest", {"crop_id": crop_id, "count": quantity})

func _on_time_changed(new_time):
	update_ui()

func update_ui():
	time_label.text = GameManager.get_time_string()
	gold_label.text = "Gold: %d" % GameManager.player_data.gold
	weather_label.text = "Weather: %s" % WeatherSystem.get_weather_name()
	season_label.text = "Season: %s" % GameManager.player_data.season.capitalize()
	day_label.text = "Day %d, Year %d" % [GameManager.player_data.day, GameManager.player_data.year]

func show_dialogue(text: String):
	dialogue_box.text = text
	dialogue_box.visible = true
	await get_tree().create_timer(3.0).timeout
	dialogue_box.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_cancel"):
		save_game()

func toggle_inventory():
	var inventory_ui = $UILayer/InventoryUI
	inventory_ui.visible = not inventory_ui.visible

func save_game():
	GameManager.save_game()
	var farm_data = farm_manager.save_farm_data()
	# Save NPC memories and emotions
	if NPCMemorySystem:
		NPCMemorySystem.save_memories()
	if NPCEmotionSystem:
		NPCEmotionSystem.save_emotion_state()
	print("Game saved!")

func _on_ai_config_pressed():
	if not ai_config_instance:
		ai_config_instance = ai_config_scene.instantiate()
		add_child(ai_config_instance)
	
	ai_config_instance.open_config()

