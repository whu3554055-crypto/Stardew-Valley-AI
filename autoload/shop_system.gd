extends Node

# Shop inventory
var shop_stock = {}
const STOCK_CONFIG_PATH := "res://data/shop/stock.json"
const WEEKLY_STRATEGIES := ["balanced", "promotion", "tight_margin"]
var weekly_strategy: String = "balanced"
var _last_strategy_week_key: int = -1

signal shop_opened
signal item_purchased(item_id, quantity)
signal item_sold(item_id, quantity)

func _ready():
	initialize_shop()
	if GameManager:
		GameManager.season_changed.connect(_on_season_changed)
		GameManager.day_changed.connect(_on_day_changed)

func initialize_shop():
	shop_stock = _load_stock_from_json()

func open_shop():
	_update_weekly_strategy()
	shop_opened.emit()
	return get_display_stock(false)


func get_display_stock(include_unavailable: bool = false) -> Dictionary:
	var visible: Dictionary = {}
	for item_id in shop_stock.keys():
		var row: Dictionary = shop_stock[item_id]
		var available: bool = _is_item_available_now(item_id)
		if available or include_unavailable:
			var out_row: Dictionary = row.duplicate(true)
			out_row["available"] = available
			visible[item_id] = out_row
	return visible

func get_buy_price(item_id: String) -> int:
	if not shop_stock.has(item_id):
		return 0
	var catalog: int = int(shop_stock[item_id].price)
	catalog = _apply_weekly_buy_strategy(catalog)
	if AIEconomySystem:
		return AIEconomySystem.get_shop_buy_price(item_id, catalog)
	return catalog

func purchase_item(item_id: String, quantity: int = 1) -> bool:
	if not shop_stock.has(item_id):
		return false
	if not _is_item_available_now(item_id):
		return false

	var item_data = shop_stock[item_id]
	var unit = get_buy_price(item_id)
	var total_cost = unit * quantity

	if GameManager.player_data.gold < total_cost:
		return false

	if item_data.stock < quantity:
		return false

	# Process transaction
	GameManager.player_data.gold -= total_cost
	item_data.stock -= quantity

	# Add to player inventory
	var item_template = ItemDatabase.get_item(item_id)
	if item_template.is_empty():
		return false

	for i in range(quantity):
		InventoryManager.add_item(item_template.duplicate(true))

	item_purchased.emit(item_id, quantity)
	if AIEconomySystem:
		AIEconomySystem.on_shop_trade(item_id, quantity, true)
	return true

func get_sell_price_per_unit(item_id: String) -> int:
	var item_template: Dictionary = ItemDatabase.get_item(item_id)
	var base: int = int(item_template.get("sell_price", 0))
	if base <= 0:
		return 0
	base = _apply_weekly_sell_strategy(base)
	if AIEconomySystem:
		return AIEconomySystem.get_shop_sell_price(item_id, base)
	return base

func get_weekly_strategy_label() -> String:
	return weekly_strategy

func _on_day_changed(_new_day: int) -> void:
	_update_weekly_strategy()

func _update_weekly_strategy() -> void:
	var wkey: int = _current_week_key()
	if wkey == _last_strategy_week_key:
		return
	_last_strategy_week_key = wkey
	if WEEKLY_STRATEGIES.is_empty():
		weekly_strategy = "balanced"
		return
	weekly_strategy = WEEKLY_STRATEGIES[wkey % WEEKLY_STRATEGIES.size()]

func _current_week_key() -> int:
	if not GameManager:
		return 0
	var year: int = int(GameManager.player_data.get("year", 1))
	var day: int = int(GameManager.player_data.get("day", 1))
	var season: String = str(GameManager.player_data.get("season", "spring"))
	var season_idx: int = ["spring", "summer", "fall", "winter"].find(season)
	if season_idx < 0:
		season_idx = 0
	var day_index: int = (year - 1) * 112 + season_idx * 28 + day
	return int(day_index / 7)

func _apply_weekly_buy_strategy(base_price: int) -> int:
	match weekly_strategy:
		"promotion":
			return int(round(base_price * 0.92))
		"tight_margin":
			return int(round(base_price * 1.08))
		_:
			return base_price

func _apply_weekly_sell_strategy(base_price: int) -> int:
	match weekly_strategy:
		"promotion":
			return int(round(base_price * 1.04))
		"tight_margin":
			return int(round(base_price * 0.94))
		_:
			return base_price

func sell_item(item_id: String, quantity: int = 1) -> bool:
	var item_template = ItemDatabase.get_item(item_id)
	if item_template.is_empty():
		return false

	var unit: int = get_sell_price_per_unit(item_id)
	var sell_price: int = unit * quantity

	# Remove from inventory and add gold
	for i in range(quantity):
		# Find and remove item from inventory
		for slot in range(InventoryManager.INVENTORY_SIZE):
			var item = InventoryManager.get_item(slot)
			if item and item.id == item_id:
				InventoryManager.remove_item(slot)
				break

	GameManager.player_data.gold += sell_price
	item_sold.emit(item_id, quantity)
	if AIEconomySystem:
		AIEconomySystem.on_shop_trade(item_id, quantity, false)
	if QuestSystem:
		QuestSystem.track_event("earn_gold", {"gold": sell_price})
	return true


func sell_from_slot(slot: int, quantity: int = 1) -> bool:
	"""Sell from a specific inventory slot (e.g. selected slot)."""
	var item = InventoryManager.get_item(slot)
	if item == null:
		return false
	var item_id: String = str(item.get("id", ""))
	if item_id.is_empty():
		return false
	var unit: int = get_sell_price_per_unit(item_id)
	if unit <= 0:
		return false
	var stack: int = int(item.get("stack", 1))
	var q: int = mini(maxi(quantity, 1), stack)
	if q <= 0:
		return false
	var sell_price: int = unit * q
	if not InventoryManager.remove_item(slot, q):
		return false
	GameManager.player_data.gold += sell_price
	item_sold.emit(item_id, q)
	if AIEconomySystem:
		AIEconomySystem.on_shop_trade(item_id, q, false)
	if QuestSystem:
		QuestSystem.track_event("earn_gold", {"gold": sell_price})
	return true

func get_sell_value(item_id: String) -> int:
	return get_sell_price_per_unit(item_id)


func _load_stock_from_json() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open(STOCK_CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("ShopSystem: missing %s, using fallback stock." % STOCK_CONFIG_PATH)
		return _fallback_stock()
	var txt: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_warning("ShopSystem: failed to parse %s, using fallback stock." % STOCK_CONFIG_PATH)
		return _fallback_stock()
	var d: Dictionary = json.data
	var arr: Array = d.get("items", [])
	for row in arr:
		if not (row is Dictionary):
			continue
		var item_id: String = str(row.get("id", ""))
		if item_id.is_empty():
			continue
		out[item_id] = {
			"price": int(row.get("price", 0)),
			"stock": int(row.get("stock", 0)),
			"seasons": row.get("seasons", [])
		}
	if out.is_empty():
		return _fallback_stock()
	return out


func _fallback_stock() -> Dictionary:
	return {
		"parsnip_seeds": {"price": 20, "stock": 99, "seasons": ["spring"]},
		"cauliflower_seeds": {"price": 80, "stock": 99, "seasons": ["spring"]},
		"potato_seeds": {"price": 50, "stock": 99, "seasons": ["spring"]},
		"corn_seeds": {"price": 150, "stock": 99, "seasons": ["summer"]},
		"pumpkin_seeds": {"price": 120, "stock": 99, "seasons": ["fall"]},
		"basic_fertilizer": {"price": 35, "stock": 99, "seasons": ["spring"]},
		"bread": {"price": 50, "stock": 99},
		"fishing_rod": {"price": 120, "stock": 10},
		"worm_bait": {"price": 8, "stock": 99},
		"premium_bait": {"price": 26, "stock": 40},
		"pickaxe_iron": {"price": 800, "stock": 3}
	}


func _is_item_available_now(item_id: String) -> bool:
	if not shop_stock.has(item_id):
		return false
	var row: Dictionary = shop_stock[item_id]
	var seasons: Variant = row.get("seasons", [])
	if seasons is Array and seasons.size() > 0 and GameManager:
		var cur: String = str(GameManager.player_data.get("season", "spring"))
		return cur in seasons
	return true


func _on_season_changed(_new_season) -> void:
	pass
