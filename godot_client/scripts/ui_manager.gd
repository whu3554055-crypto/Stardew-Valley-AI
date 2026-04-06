extends CanvasLayer

# UI Manager - Main Game UI
# Manages HUD, inventory panel, quest log, and status displays

signal ui_opened(ui_type: String)
signal ui_closed(ui_type: String)

var is_inventory_open = false
var is_quest_log_open = false
var is_status_open = false

@onready var hud = $HUD
@onready var gold_label = $HUD/GoldLabel
@onready var time_label = $HUD/TimeLabel
@onready var season_label = $HUD/SeasonLabel

@onready var inventory_panel = $InventoryPanel
@onready var inventory_list = $InventoryPanel/ItemList
@onready var inventory_gold = $InventoryPanel/GoldDisplay
@onready var close_inventory_btn = $InventoryPanel/CloseButton

@onready var quest_panel = $QuestLogPanel
@onready var quest_list = $QuestLogPanel/QuestList
@onready var close_quest_btn = $QuestLogPanel/CloseButton

@onready var status_panel = $StatusPanel
@onready var energy_bar = $StatusPanel/EnergyBar
@onready var health_bar = $StatusPanel/HealthBar

var inventory_system = null
var quest_system = null
var main_node = null

func _ready():
	# Hide panels initially
	inventory_panel.visible = false
	quest_panel.visible = false
	status_panel.visible = false

	# Connect buttons
	close_inventory_btn.pressed.connect(close_inventory)
	close_quest_btn.pressed.connect(close_quest_log)

	find_systems()
	update_hud()

func find_systems():
	"""Find required systems"""
	main_node = get_tree().root.get_node_or_null("Main")
	if main_node:
		var town_square = main_node.get_node_or_null("TownSquare")
		if town_square:
			if town_square.has_node("InventorySystem"):
				inventory_system = town_square.get_node("InventorySystem")
				inventory_system.gold_changed.connect(update_hud)
				inventory_system.inventory_updated.connect(update_inventory_display)
			if town_square.has_node("QuestSystem"):
				quest_system = town_square.get_node("QuestSystem")

func update_hud():
	"""Update HUD display"""
	if not main_node:
		return

	if inventory_system:
		gold_label.text = "%dg" % inventory_system.player_gold

	if main_node.has_node("game_state"):
		var game_state = main_node.game_state
		time_label.text = format_time(game_state.time)
		season_label.text = "%s 第%d天" % [get_season_name(game_state.season), game_state.day]

func format_time(game_time: float) -> String:
	"""Format game time to HH:MM"""
	var hours = int(game_time)
	var minutes = int((game_time - hours) * 60)
	return "%02d:%02d" % [hours, minutes]

func get_season_name(season_id: String) -> String:
	match season_id:
		"spring": return "春季"
		"summer": return "夏季"
		"fall": return "秋季"
		"winter": return "冬季"
		_: return season_id

func toggle_inventory():
	"""Toggle inventory panel"""
	if is_inventory_open:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	"""Open inventory panel"""
	is_inventory_open = true
	inventory_panel.visible = true
	update_inventory_display()
	emit_signal("ui_opened", "inventory")

func close_inventory():
	"""Close inventory panel"""
	is_inventory_open = false
	inventory_panel.visible = false
	emit_signal("ui_closed", "inventory")

func update_inventory_display():
	"""Update inventory list display"""
	if not inventory_system or not inventory_list:
		return

	inventory_list.clear()

	var summary = inventory_system.get_inventory_summary()
	inventory_gold.text = "金钱: %dg" % summary["gold"]

	if summary["items"].is_empty():
		inventory_list.add_item("背包是空的")
		return

	for item in summary["items"]:
		var type_icon = get_type_icon(item["type"])
		var text = "%s %s x%d (%dg)" % [
			type_icon,
			item["name"],
			item["quantity"],
			item["value"] * item["quantity"]
		]
		inventory_list.add_item(text)

func get_type_icon(item_type: String) -> String:
	match item_type:
		"seed": return "[种子]"
		"crop": return "[作物]"
		"tool": return "[工具]"
		_: return "[物品]"

func toggle_quest_log():
	"""Toggle quest log panel"""
	if is_quest_log_open:
		close_quest_log()
	else:
		open_quest_log()

func open_quest_log():
	"""Open quest log panel"""
	is_quest_log_open = true
	quest_panel.visible = true
	update_quest_display()
	emit_signal("ui_opened", "quest_log")

func close_quest_log():
	"""Close quest log panel"""
	is_quest_log_open = false
	quest_panel.visible = false
	emit_signal("ui_closed", "quest_log")

func update_quest_display():
	"""Update quest list display"""
	if not quest_system or not quest_list:
		return

	quest_list.clear()

	var active_quests = quest_system.get_active_quests_info()

	if active_quests.is_empty():
		quest_list.add_item("当前没有进行中的任务")
		quest_list.add_item("")
		quest_list.add_item("提示：与NPC对话接受任务！")
		return

	for quest in active_quests:
		# Add quest title with type indicator
		var type_tag = get_quest_type_tag(quest["type"])
		quest_list.add_item("%s %s" % [type_tag, quest["title"]])

		# Add objectives
		for obj in quest["objectives"]:
			var status = "[完成]" if obj["completed"] else "[%d/%d]" % [obj["progress"], obj["target"]]
			quest_list.add_item("  %s %s" % [status, obj["description"]])

		quest_list.add_item("")  # Empty line between quests

func get_quest_type_tag(quest_type: String) -> String:
	match quest_type:
		"tutorial": return "[教程]"
		"daily": return "[日常]"
		"npc": return "[委托]"
		_: return "[任务]"

func toggle_status():
	"""Toggle status panel"""
	if is_status_open:
		close_status()
	else:
		open_status()

func open_status():
	"""Open status panel"""
	is_status_open = true
	status_panel.visible = true
	emit_signal("ui_opened", "status")

func close_status():
	"""Close status panel"""
	is_status_open = false
	status_panel.visible = false
	emit_signal("ui_closed", "status")

func update_energy(value: float):
	"""Update energy bar"""
	if energy_bar:
		energy_bar.value = value

func update_health(value: float):
	"""Update health bar"""
	if health_bar:
		health_bar.value = value

func show_notification(message: String, duration: float = 3.0):
	"""Show temporary notification"""
	# TODO: Implement notification system
	print("[通知] ", message)

func _input(event):
	"""Handle input for UI toggles"""
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_quest"):
		toggle_quest_log()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_status"):
		toggle_status()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if is_inventory_open:
			close_inventory()
		elif is_quest_log_open:
			close_quest_log()
		elif is_status_open:
			close_status()
