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
@onready var stamina_label = $UILayer/StaminaLabel
@onready var ai_config_button = $UILayer/AIConfigButton
@onready var world_event_feed_label = $UILayer/WorldEventFeed/Content
@onready var quick_tip_label = $UILayer/QuickTipLabel
@onready var quick_tip_timer = $UILayer/QuickTipTimer
@onready var fx_fish = $FXLayer/FishSplash
@onready var fx_mine = $FXLayer/MineSpark
@onready var almanac_panel = $UILayer/AlmanacPanel

var current_npc = null
var ai_config_scene = preload("res://scenes/ai_config_ui.tscn")
var ai_config_instance = null
var world_event_feed: Array[String] = []
const WORLD_EVENT_FEED_MAX := 6
const WORLD_EVENT_FEED_SAVE_PATH := "user://world_event_feed.save"

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
	if GatheringAlmanac:
		GatheringAlmanac.load_data()
	_load_world_event_feed()
	_refresh_world_event_feed_ui()
	initialize_playable_first_loop()
	
	# Give starter items
	give_starter_items()
	
	# Setup AI config button
	if ai_config_button:
		ai_config_button.pressed.connect(_on_ai_config_pressed)
	if quick_tip_timer:
		quick_tip_timer.timeout.connect(_on_quick_tip_timeout)
	
	print("======================================")
	print("  Stardew Valley Clone - AI Edition")
	print("======================================")
	print("AI Model: ", AIAgentManager.api_config.model if AIAgentManager else "Not loaded")
	print("NPCs with AI: Pierre, Abigail, Lewis")
	print("Press E: NPCs | harvest | kitchen | smelter | workbench craft | fish | mine | chop (axe, west) | eat | J = collection")
	print("======================================")

func initialize_playable_first_loop():
	"""
	Playable-first bootstrap:
	- Start one beginner quest immediately
	- Generate one daily narrative seed
	"""
	if QuestSystem:
		QuestSystem.start_quest("tutorial_plant")
		QuestSystem.start_quest("intro_fish")
		QuestSystem.start_quest("intro_mine")
		QuestSystem.start_quest("intro_smelt")
		QuestSystem.start_quest("intro_eat")
		QuestSystem.start_quest("intro_cook")
		QuestSystem.start_quest("intro_chop")
		QuestSystem.start_quest("intro_craft")
	
	if DailyNarrativeSystem:
		var narrative = await DailyNarrativeSystem.generate_daily_narrative_playable()
		if not narrative.is_empty():
			show_dialogue("Today's story: " + str(narrative.get("title", "A new day begins")))
			record_world_event("Daily story generated: %s" % str(narrative.get("title", "A new day begins")))
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
	var pickaxe_item = ItemDatabase.get_item("pickaxe")
	if not pickaxe_item.is_empty():
		InventoryManager.add_item(pickaxe_item.duplicate(true))
	var rod = ItemDatabase.get_item("fishing_rod")
	if not rod.is_empty():
		InventoryManager.add_item(rod.duplicate(true))
	var bait = ItemDatabase.get_item("worm_bait")
	if not bait.is_empty():
		for i in range(5):
			InventoryManager.add_item(bait.duplicate(true))
	var bread = ItemDatabase.get_item("bread")
	if not bread.is_empty():
		InventoryManager.add_item(bread.duplicate(true))
	var axe_item = ItemDatabase.get_item("axe")
	if not axe_item.is_empty():
		InventoryManager.add_item(axe_item.duplicate(true))

func _try_eat_selected_food() -> bool:
	var slot: int = InventoryManager.selected_slot
	var item = InventoryManager.get_item(slot)
	if item == null or float(item.get("stamina_restore", 0.0)) <= 0.0:
		return false
	var amt: float = float(item.get("stamina_restore", 0.0))
	var item_id: String = str(item.get("id", ""))
	var nm: String = str(item.get("name", "Food"))
	if GameManager:
		GameManager.restore_stamina(amt)
	InventoryManager.remove_item(slot, 1)
	show_quick_tip("Ate %s (+%d energy)" % [nm, int(ceil(amt))])
	update_ui()
	if QuestSystem:
		QuestSystem.track_event("consume_food", {"item_id": item_id, "count": 1})
	return true

func _try_harvest_facing_tile(tile_coords: Vector2i) -> bool:
	if not farm_manager:
		return false
	var h: Dictionary = farm_manager.harvest_crop(tile_coords)
	if h.is_empty() or not h.has("product"):
		return false
	var product_id: String = str(h.get("product", ""))
	if product_id.is_empty():
		return false
	var count: int = int(h.get("count", 1))
	var template: Dictionary = ItemDatabase.get_item(product_id)
	if template.is_empty():
		show_dialogue("Harvest failed (unknown crop).")
		return true
	for i in range(count):
		if not InventoryManager.add_item(template.duplicate(true)):
			show_dialogue("Inventory full.")
			return true
	var pnm: String = str(template.get("name", product_id))
	show_dialogue("Harvested: %s ×%d" % [pnm, count])
	record_world_event("Harvested %s ×%d" % [product_id, count])
	update_ui()
	return true

func _on_player_interact(tile_position: Vector2):
	var tile_coords = tilemap.local_to_map(tile_position)

	# Check for NPC interaction first
	if current_npc:
		var dialogue = current_npc.interact()
		show_dialogue(dialogue)
		if QuestSystem:
			QuestSystem.track_event("talk", {"npc_id": current_npc.npc_id, "count": 1})
		return

	var selected_item = InventoryManager.get_selected_item()

	# Harvest ripe crop (empty hands only — avoids conflict with eating while holding food)
	if selected_item == null and _try_harvest_facing_tile(tile_coords):
		return

	# Kitchen / cooking (empty hands, counter south-east)
	if selected_item == null and CookingSystem:
		if CookingSystem.can_cook_here(player.global_position):
			var cook_result: Dictionary = CookingSystem.try_cook_one()
			var ck_msg: String = str(cook_result.get("message", ""))
			if cook_result.get("ok", false):
				show_dialogue(ck_msg)
				record_world_event(ck_msg)
				return
			if not ck_msg.is_empty():
				show_dialogue(ck_msg)
				return

	# Furnace / smelting (empty hands, brown slab north of farm)
	if selected_item == null and SmeltingSystem:
		if SmeltingSystem.can_smelt_here(player.global_position):
			var smelt_result: Dictionary = SmeltingSystem.try_smelt_one()
			var sm_msg: String = str(smelt_result.get("message", ""))
			if smelt_result.get("ok", false):
				show_dialogue(sm_msg)
				record_world_event(sm_msg)
				return
			if not sm_msg.is_empty():
				show_dialogue(sm_msg)
				return

	# Workbench / crafting (empty hands, east of kitchen)
	if selected_item == null and CraftingSystem:
		if CraftingSystem.can_craft_here(player.global_position):
			var craft_result: Dictionary = CraftingSystem.try_craft_one()
			var cr_msg: String = str(craft_result.get("message", ""))
			if craft_result.get("ok", false):
				show_dialogue(cr_msg)
				record_world_event(cr_msg)
				return
			if not cr_msg.is_empty():
				show_dialogue(cr_msg)
				return

	# Fishing: equip rod; ocean (south) or river (right); bite QTE — second E in time window
	if selected_item and str(selected_item.get("id", "")) == "fishing_rod" and FishingSystem:
		if FishingSystem.can_fish_here(player.global_position):
			var catch_result: Dictionary = FishingSystem.handle_fish_input(player.global_position)
			if str(catch_result.get("phase", "")) == "hook_prompt":
				show_quick_tip(str(catch_result.get("message", "Press E!")))
				return
			var fish_msg: String = str(catch_result.get("message", ""))
			if catch_result.get("ok", false):
				show_dialogue(fish_msg)
				record_world_event(fish_msg)
				_play_fx_fish()
				return
			if not fish_msg.is_empty():
				show_dialogue(fish_msg)
				return

	# Mining: pickaxe (basic or iron), Y band = depth; iron pick for deep gold
	if selected_item and str(selected_item.get("id", "")) in ["pickaxe", "pickaxe_iron"] and MiningSystem:
		if MiningSystem.can_mine_here(player.global_position):
			var mine_result: Dictionary = MiningSystem.try_swing(
				player.global_position,
				str(selected_item.get("id", ""))
			)
			var mine_msg: String = str(mine_result.get("message", ""))
			if mine_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				show_dialogue(mine_msg)
				record_world_event(mine_msg)
				_play_fx_mine()
				return
			if not mine_msg.is_empty():
				show_dialogue(mine_msg)
				return

	# Chopping: axe in forest (west, below mine entrance)
	if selected_item and str(selected_item.get("id", "")) == "axe" and ChoppingSystem:
		if ChoppingSystem.can_chop_here(player.global_position):
			var chop_result: Dictionary = ChoppingSystem.try_chop_one()
			var ch_msg: String = str(chop_result.get("message", ""))
			if chop_result.get("ok", false):
				InventoryManager.damage_tool_slot(InventoryManager.selected_slot, 1)
				show_dialogue(ch_msg)
				record_world_event(ch_msg)
				_play_fx_mine()
				return
			if not ch_msg.is_empty():
				show_dialogue(ch_msg)
				return

	# Eat food / crops / fish with stamina_restore (select item, press E)
	if selected_item and _try_eat_selected_food():
		return

	# Farming interactions
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
		record_world_event("New day, new story seed is ready.")
		_apply_narrative_daily_quest(narrative)

func _on_quest_completed(quest_id: String):
	if QuestSystem and QuestSystem.quests.has(quest_id):
		var quest_data: Dictionary = QuestSystem.quests[quest_id]
		var title = quest_data.get("title", quest_id)
		show_dialogue("Quest completed: " + str(title))
		_apply_story_completion_feedback(quest_data)

func _apply_story_completion_feedback(quest_data: Dictionary) -> void:
	if quest_data.get("source", "") != "daily_narrative":
		return

	var story_npc_id: String = str(quest_data.get("story_npc_id", ""))
	if story_npc_id.is_empty():
		return
	var quest_id: String = str(quest_data.get("id", ""))

	# Immediate "world reacts to player action" feedback.
	if NPCEmotionSystem:
		NPCEmotionSystem.set_emotion(
			story_npc_id,
			NPCEmotionSystem.BasicEmotion.HAPPY,
			0.8,
			120.0,
			"player_story_help"
		)
		var spread_results: Array = NPCEmotionSystem.propagate_emotion_to_social_circle(
			story_npc_id,
			NPCEmotionSystem.BasicEmotion.HAPPY,
			0.6,
			"story_emotion_spread"
		)
		for result in spread_results:
			var neighbor_id: String = str(result.get("npc_id", ""))
			if not neighbor_id.is_empty():
				record_world_event("%s was uplifted after hearing about your help to %s." % [neighbor_id.capitalize(), story_npc_id.capitalize()])
				if NPCMemorySystem:
					NPCMemorySystem.record_event(
						neighbor_id,
						"I heard the player helped %s with today's story. People are talking about it." % story_npc_id.capitalize(),
						0.78,
						"happy",
						["player", story_npc_id, neighbor_id, "daily_narrative", quest_id]
					)
		if NPCMemorySystem:
			NPCMemorySystem.record_event(
				story_npc_id,
				"The player helped me with today's story quest. I'm grateful.",
				0.82,
				"happy",
				["player", story_npc_id, "daily_narrative", quest_id]
			)

	if NPCAudioManager:
		NPCAudioManager.speak(story_npc_id, "Thanks! Today's story moved forward because of you.", "happy")

	var feedback_line := "%s now feels encouraged by your help." % story_npc_id.capitalize()
	record_world_event(feedback_line)
	show_dialogue(feedback_line)

func record_world_event(event_text: String) -> void:
	var timestamp := ""
	if GameManager:
		timestamp = str(GameManager.get_time_string())
	var line := "[%s] %s" % [timestamp if not timestamp.is_empty() else "--:--", event_text]
	world_event_feed.push_front(line)
	if world_event_feed.size() > WORLD_EVENT_FEED_MAX:
		world_event_feed.resize(WORLD_EVENT_FEED_MAX)
	_refresh_world_event_feed_ui()
	_save_world_event_feed()

func _refresh_world_event_feed_ui() -> void:
	if not world_event_feed_label:
		return
	if world_event_feed.is_empty():
		world_event_feed_label.text = "No events yet."
		return
	world_event_feed_label.text = "\n".join(world_event_feed)

func _save_world_event_feed() -> void:
	var save_file = FileAccess.open(WORLD_EVENT_FEED_SAVE_PATH, FileAccess.WRITE)
	if not save_file:
		return
	save_file.store_var(world_event_feed)
	save_file.close()

func _load_world_event_feed() -> void:
	if not FileAccess.file_exists(WORLD_EVENT_FEED_SAVE_PATH):
		return
	var save_file = FileAccess.open(WORLD_EVENT_FEED_SAVE_PATH, FileAccess.READ)
	if not save_file:
		return
	var loaded = save_file.get_var()
	save_file.close()
	if loaded is Array:
		world_event_feed.clear()
		for item in loaded:
			world_event_feed.append(str(item))
		if world_event_feed.size() > WORLD_EVENT_FEED_MAX:
			world_event_feed.resize(WORLD_EVENT_FEED_MAX)

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
	if stamina_label:
		var s: float = float(GameManager.player_data.get("stamina", 100.0))
		var sm: float = float(GameManager.player_data.get("stamina_max", 100.0))
		stamina_label.text = "Stamina: %d / %d" % [int(s), int(sm)]
	weather_label.text = "Weather: %s" % WeatherSystem.get_weather_name()
	season_label.text = "Season: %s" % GameManager.player_data.season.capitalize()
	day_label.text = "Day %d, Year %d" % [GameManager.player_data.day, GameManager.player_data.year]

func show_dialogue(text: String):
	dialogue_box.text = text
	dialogue_box.visible = true
	await get_tree().create_timer(3.0).timeout
	dialogue_box.visible = false

func show_quick_tip(text: String, duration: float = 1.35) -> void:
	if not quick_tip_label or not quick_tip_timer:
		return
	quick_tip_label.text = text
	quick_tip_label.visible = true
	quick_tip_timer.stop()
	quick_tip_timer.wait_time = duration
	quick_tip_timer.start()

func _on_quick_tip_timeout() -> void:
	if quick_tip_label:
		quick_tip_label.visible = false

func _play_fx_fish() -> void:
	if fx_fish:
		fx_fish.global_position = player.global_position
		fx_fish.restart()
		fx_fish.emitting = true

func _play_fx_mine() -> void:
	if fx_mine:
		fx_mine.global_position = player.global_position
		fx_mine.restart()
		fx_mine.emitting = true

func _unhandled_input(event):
	if event.is_action_pressed("toggle_almanac") and almanac_panel:
		almanac_panel.visible = not almanac_panel.visible
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_cancel"):
		save_game()

func toggle_inventory():
	var inventory_ui = $UILayer/InventoryUI
	inventory_ui.visible = not inventory_ui.visible

func save_game():
	GameManager.save_game()
	_save_world_event_feed()
	var farm_data = farm_manager.save_farm_data()
	# Save NPC memories and emotions
	if NPCMemorySystem:
		NPCMemorySystem.save_memories()
	if NPCEmotionSystem:
		NPCEmotionSystem.save_emotion_state()
	if GatheringAlmanac:
		GatheringAlmanac.save_data()
	print("Game saved!")

func _on_ai_config_pressed():
	if not ai_config_instance:
		ai_config_instance = ai_config_scene.instantiate()
		add_child(ai_config_instance)
	
	ai_config_instance.open_config()

