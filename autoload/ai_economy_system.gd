extends Node

class_name AIEconomySystem

# ============================================
# AI-Driven Economy System
# Dynamic prices, supply/demand, NPC trading behaviors
# Fully autonomous economic simulation
# ============================================

signal price_changed(item_id, old_price, new_price, reason)
signal market_trend_updated(trend_data)
signal npc_trade_executed(trader_id, item_id, quantity, price)
signal economic_event_triggered(event_type, impact_data)

# Market data
var market_state = {
	"items": {},           # Item prices and stats
	"vendors": {},         # Vendor inventory and behaviors
	"global_trends": [],   # Economic trends
	"season_factors": {},  # Seasonal modifiers
	"weather_impact": {},  # Weather effects on prices
	"supply_chains": {},   # Production/distribution networks
	"consumer_behavior": {} # Buying patterns
}

# AI decision history
var ai_decisions = []
const MAX_DECISION_HISTORY = 100

# Economic simulation parameters
var sim_params = {
	"price_volatility": 0.15,      # How much prices fluctuate
	"demand_sensitivity": 0.8,     # How responsive demand is to price
	"supply_elasticity": 0.6,      # How quickly supply adjusts
	"market_efficiency": 0.7,      # How quickly information spreads
	"npc_rationality": 0.8         # How rational NPC economic decisions are
}

func _ready():
	initialize_economy()
	start_autonomous_simulation()

func initialize_economy():
	"""Initialize the economy with base items and vendors"""
	print("[AIEconomySystem] Initializing autonomous economy...")
	
	# Initialize items from database
	if ItemDatabase:
		for item_id in ItemDatabase.get_all_item_ids():
			initialize_item_market(item_id)
	
	# Initialize vendors (shopkeepers)
	initialize_vendors()
	
	# Set seasonal factors
	set_seasonal_factors("spring")
	
	print("[AIEconomySystem] Economy initialized with ", 
		market_state.items.size(), " items and ",
		market_state.vendors.size(), " vendors")

func initialize_item_market(item_id: String):
	"""Initialize market data for an item"""
	var base_price = 100  # Default
	
	if ItemDatabase:
		var item = ItemDatabase.get_item_by_id(item_id)
		if item:
			base_price = item.get("sell_price", 100)
	
	market_state.items[item_id] = {
		"base_price": base_price,
		"current_price": base_price,
		"price_history": [],
		"supply": randf_range(50, 150),  # Available quantity
		"demand": randf_range(30, 100),  # Demand level
		"volatility": randf_range(0.1, 0.3),
		"seasonal_modifier": 1.0,
		"weather_modifier": 1.0,
		"trend": "stable",  # rising, falling, stable, volatile
		"last_updated": Time.get_unix_time_from_system()
	}

func initialize_vendors():
	"""Initialize vendor economic agents"""
	# Pierre's General Store
	market_state.vendors["pierre"] = {
		"type": "general_store",
		"inventory": {},
		"markup": 1.5,
		"restock_schedule": "daily",
		"price_sensitivity": 0.7,
		"customer_loyalty": 0.6,
		"capital": 5000,
		"business_goals": ["profit_maximization", "customer_satisfaction"]
	}
	
	# Blacksmith (if exists)
	market_state.vendors["blacksmith"] = {
		"type": "specialty_shop",
		"inventory": {},
		"markup": 2.0,
		"restock_schedule": "weekly",
		"price_sensitivity": 0.5,
		"customer_loyalty": 0.8,
		"capital": 10000,
		"business_goals": ["quality_focus", "niche_market"]
	}

# ============================================
# AUTONOMOUS PRICE ADJUSTMENT
# ============================================

func start_autonomous_simulation():
	"""Start the autonomous economic simulation"""
	# Update economy every 10 in-game minutes
	if GameManager:
		GameManager.connect("time_changed", Callable(self, "_on_time_changed"))
	
	# Also update on weather changes
	if WeatherSystem:
		WeatherSystem.connect("weather_changed", Callable(self, "_on_weather_changed"))

func _on_time_changed(new_time: float):
	"""Respond to time changes - update economy periodically"""
	# Update every 60 minutes (once per in-game hour)
	if int(new_time * 10) % 6 == 0:
		update_economy_simulation()

func update_economy_simulation():
	"""Run one tick of the economic simulation"""
	var updates = {
		"prices_changed": 0,
		"trends_identified": [],
		"events_triggered": []
	}
	
	# 1. Update supply and demand
	update_supply_and_demand()
	
	# 2. Adjust prices based on market forces
	adjust_prices_autonomously()
	
	# 3. Identify market trends
	identify_market_trends()
	
	# 4. Check for economic events
	check_economic_events()
	
	# 5. NPC vendors make autonomous decisions
	vendor_autonomous_decisions()
	
	print("[AIEconomy] Simulation tick complete: ", updates.prices_changed, " prices updated")

func update_supply_and_demand():
	"""Update supply and demand dynamics"""
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		
		# Natural supply decay (perishables, consumption)
		item.supply *= randf_range(0.95, 0.99)
		
		# Demand fluctuation based on various factors
		var demand_change = 0.0
		
		# Time-based demand (breakfast items in morning, etc.)
		if GameManager:
			var hour = int(GameManager.current_time)
			demand_change += get_time_based_demand(item_id, hour)
		
		# Weather influence
		if WeatherSystem:
			var weather = WeatherSystem.get_weather_name().to_lower()
			demand_change += get_weather_demand_modifier(item_id, weather)
		
		# Season influence
		if GameManager and GameManager.player_data:
			var season = GameManager.player_data.season
			demand_change += get_seasonal_demand_modifier(item_id, season)
		
		item.demand = clamp(item.demand + demand_change, 10, 200)
		
		# Supply replenishment for vendors
		replenish_supply(item_id)

func replenish_supply(item_id: String):
	"""Vendors autonomously replenish supply"""
	var item = market_state.items[item_id]
	
	# If supply is low and demand is high, restock
	if item.supply < item.demand * 0.5:
		var restock_amount = item.demand * randf_range(0.8, 1.5)
		item.supply += restock_amount
		
		# Record restocking event
		record_ai_decision("restock", {
			"item": item_id,
			"amount": restock_amount,
			"reason": "Low supply relative to demand"
		})

func adjust_prices_autonomously():
	"""AI-driven price adjustment based on market conditions"""
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		var old_price = item.current_price
		
		# Calculate fair price based on supply/demand ratio
		var supply_demand_ratio = item.supply / max(1, item.demand)
		
		var target_price = item.base_price
		if supply_demand_ratio < 0.5:
			# High demand, low supply -> price increase
			target_price = item.base_price * (1.0 + (0.5 - supply_demand_ratio))
		elif supply_demand_ratio > 2.0:
			# Low demand, high supply -> price decrease
			target_price = item.base_price * (1.0 - (supply_demand_ratio - 2.0) * 0.2)
		
		# Apply modifiers
		target_price *= item.seasonal_modifier
		target_price *= item.weather_modifier
		
		# Smooth price transitions (prevent shock)
		var max_change = item.base_price * item.volatility * sim_params.price_volatility
		var price_change = clamp(target_price - old_price, -max_change, max_change)
		
		item.current_price = max(1, old_price + price_change)
		
		# Determine trend
		if abs(price_change) < item.base_price * 0.02:
			item.trend = "stable"
		elif price_change > 0:
			item.trend = "rising"
		else:
			item.trend = "falling"
		
		# Record price history
		item.price_history.append({
			"price": item.current_price,
			"timestamp": Time.get_unix_time_from_system()
		})
		
		# Keep history manageable
		if item.price_history.size() > 100:
			item.price_history.pop_front()
		
		# Emit signal if significant change
		if abs(price_change) > item.base_price * 0.05:
			price_changed.emit(item_id, old_price, item.current_price, 
				"Supply/demand adjustment")

# ============================================
# MARKET TREND ANALYSIS
# ============================================

func identify_market_trends():
	"""AI identifies emerging market trends"""
	var trends = []
	
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		
		# Analyze price history for patterns
		if item.price_history.size() >= 10:
			var pattern = analyze_price_pattern(item.price_history)
			
			if pattern != "none":
				trends.append({
					"item": item_id,
					"pattern": pattern,
					"confidence": calculate_trend_confidence(item),
					"prediction": predict_future_movement(item)
				})
	
	# Store global trends
	market_state.global_trends = trends
	
	if not trends.is_empty():
		market_trend_updated.emit({
			"trends": trends,
			"timestamp": Time.get_unix_time_from_system()
		})

func analyze_price_pattern(history: Array) -> String:
	"""Analyze price history for patterns"""
	if history.size() < 10:
		return "none"
	
	var recent = history.slice(-10)
	var prices = []
	for entry in recent:
		prices.append(entry.price)
	
	# Calculate trend direction
	var increases = 0
	var decreases = 0
	for i in range(1, prices.size()):
		if prices[i] > prices[i-1]:
			increases += 1
		elif prices[i] < prices[i-1]:
			decreases += 1
	
	# Identify pattern
	if increases >= 7:
		return "strong_uptrend"
	elif increases >= 5:
		return "moderate_uptrend"
	elif decreases >= 7:
		return "strong_downtrend"
	elif decreases >= 5:
		return "moderate_downtrend"
	elif abs(increases - decreases) <= 2:
		return "sideways"
	else:
		return "volatile"

func calculate_trend_confidence(item: Dictionary) -> float:
	"""Calculate confidence in identified trend"""
	var consistency = 0.0
	
	if item.price_history.size() >= 20:
		consistency = 0.8
	elif item.price_history.size() >= 10:
		consistency = 0.6
	else:
		consistency = 0.4
	
	# Volatility reduces confidence
	var volatility_penalty = item.volatility * 0.3
	
	return clamp(consistency - volatility_penalty, 0.0, 1.0)

func predict_future_movement(item: Dictionary) -> Dictionary:
	"""Predict future price movement"""
	var prediction = {
		"direction": "stable",
		"magnitude": 0.0,
		"timeframe": "short_term"
	}
	
	match item.trend:
		"rising":
			prediction.direction = "up"
			prediction.magnitude = item.volatility * 0.5
		"falling":
			prediction.direction = "down"
			prediction.magnitude = item.volatility * 0.5
		"volatile":
			prediction.direction = "uncertain"
			prediction.magnitude = item.volatility
	
	return prediction

# ============================================
# VENDOR AI DECISIONS
# ============================================

func vendor_autonomous_decisions():
	"""Vendors make autonomous business decisions"""
	for vendor_id in market_state.vendors.keys():
		var vendor = market_state.vendors[vendor_id]
		
		# Decision 1: Adjust markup based on competition and demand
		adjust_vendor_markup(vendor_id, vendor)
		
		# Decision 2: Decide what to stock
		optimize_vendor_inventory(vendor_id, vendor)
		
		# Decision 3: Special promotions or sales
		consider_promotions(vendor_id, vendor)

func adjust_vendor_markup(vendor_id: String, vendor: Dictionary):
	"""Vendor autonomously adjusts pricing markup"""
	var current_markup = vendor.markup
	var target_markup = current_markup
	
	# If customer loyalty is high, can charge more
	if vendor.customer_loyalty > 0.7:
		target_markup += 0.1
	
	# If business is slow (hypothetical metric), reduce markup
	# In a full implementation, track actual sales data
	if randf() < 0.3:  # Simulated slow business
		target_markup -= 0.05
	
	# Smooth adjustment
	vendor.markup = lerp(current_markup, target_markup, 0.1)
	vendor.markup = clamp(vendor.markup, 1.2, 3.0)

func optimize_vendor_inventory(vendor_id: String, vendor: Dictionary):
	"""Vendor decides what items to stock"""
	# Get top demanded items
	var top_items = get_top_demanded_items(5)
	
	for item_id in top_items:
		var item = market_state.items[item_id]
		
		# Stock more of high-demand items
		if item.demand > 80 and item.supply < item.demand:
			vendor.inventory[item_id] = vendor.inventory.get(item_id, 0) + 10
			
			record_ai_decision("inventory_increase", {
				"vendor": vendor_id,
				"item": item_id,
				"reason": "High demand detected"
			})

func consider_promotions(vendor_id: String, vendor: Dictionary):
	"""Vendor considers running promotions"""
	# Random chance to run promotion
	if randf() < 0.05:  # 5% chance per check
		var promotion_type = ["discount", "bundle", "loyalty_reward"][randi() % 3]
		
		record_ai_decision("promotion", {
			"vendor": vendor_id,
			"type": promotion_type,
			"duration_hours": randi_range(4, 24)
		})

# ============================================
# SEASONAL AND WEATHER EFFECTS
# ============================================

func set_seasonal_factors(season: String):
	"""Set economic factors for a season"""
	market_state.season_factors = {
		"spring": {
			"crops": 1.2,    # High demand for seeds
			"fish": 1.0,
			"minerals": 0.9
		},
		"summer": {
			"crops": 1.0,
			"fish": 1.3,     # Fishing season
			"minerals": 0.8
		},
		"fall": {
			"crops": 1.5,    # Harvest season
			"fish": 0.9,
			"minerals": 1.0
		},
		"winter": {
			"crops": 0.5,    # No farming
			"fish": 0.7,
			"minerals": 1.4  # Mining season
		}
	}.get(season, {})
	
	# Apply seasonal modifiers to items
	apply_seasonal_modifiers()

func apply_seasonal_modifiers():
	"""Apply seasonal price modifiers"""
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		
		# Determine item category
		var category = categorize_item(item_id)
		
		if market_state.season_factors.has(category):
			item.seasonal_modifier = market_state.season_factors[category]

func _on_weather_changed(weather_data: Dictionary):
	"""Respond to weather changes"""
	var weather = weather_data.get("weather", "sunny").to_lower()
	
	# Update weather modifiers
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		item.weather_modifier = get_weather_price_modifier(item_id, weather)

func get_weather_price_modifier(item_id: String, weather: String) -> float:
	"""Get price modifier based on weather"""
	match weather:
		"rain":
			if item_id.contains("seed") or item_id.contains("crop"):
				return 1.3  # Rainy day gardening supplies
			elif item_id.contains("fish"):
				return 1.2  # Good fishing weather
		"snow":
			if item_id.contains("tool"):
				return 1.2  # Snow removal tools
		"storm":
			if item_id.contains("food"):
				return 1.15  # Storm preparation
		
	return 1.0

# ============================================
# ECONOMIC EVENTS
# ============================================

func check_economic_events():
	"""Check for and trigger economic events"""
	# Event 1: Supply shortage
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		if item.supply < 10 and item.demand > 50:
			trigger_economic_event("supply_shortage", {
				"item": item_id,
				"severity": "high",
				"estimated_duration": "3_days"
			})
	
	# Event 2: Demand spike
	for item_id in market_state.items.keys():
		var item = market_state.items[item_id]
		if item.demand > 150:
			trigger_economic_event("demand_spike", {
				"item": item_id,
				"cause": "seasonal_or_festival",
				"opportunity": "increase_prices"
			})

func trigger_economic_event(event_type: String, impact_data: Dictionary):
	"""Trigger an economic event"""
	economic_event_triggered.emit(event_type, impact_data)
	
	record_ai_decision("event_trigger", {
		"type": event_type,
		"data": impact_data
	})
	
	# Apply event effects
	apply_event_effects(event_type, impact_data)

func apply_event_effects(event_type: String, impact_data: Dictionary):
	"""Apply effects of economic events"""
	match event_type:
		"supply_shortage":
			var item = market_state.items.get(impact_data.item)
			if item:
				item.current_price *= 1.5
				item.trend = "rising"
		
		"demand_spike":
			var item = market_state.items.get(impact_data.item)
			if item:
				item.current_price *= 1.3
				item.demand *= 1.2

# ============================================
# UTILITY FUNCTIONS
# ============================================

func get_current_price(item_id: String) -> int:
	"""Get current market price for an item"""
	if market_state.items.has(item_id):
		return int(market_state.items[item_id].current_price)
	return 100  # Default

func get_price_trend(item_id: String) -> String:
	"""Get price trend for an item"""
	if market_state.items.has(item_id):
		return market_state.items[item_id].trend
	return "stable"

func get_top_demanded_items(count: int) -> Array:
	"""Get items with highest demand"""
	var sorted_items = []
	
	for item_id in market_state.items.keys():
		sorted_items.append({
			"id": item_id,
			"demand": market_state.items[item_id].demand
		})
	
	sorted_items.sort_custom(func(a, b): return a.demand > b.demand)
	
	var result = []
	for i in range(min(count, sorted_items.size())):
		result.append(sorted_items[i].id)
	
	return result

func categorize_item(item_id: String) -> String:
	"""Categorize an item for economic analysis"""
	if item_id.contains("seed") or item_id.contains("crop"):
		return "crops"
	elif item_id.contains("fish"):
		return "fish"
	elif item_id.contains("mineral") or item_id.contains("gem"):
		return "minerals"
	else:
		return "general"

func get_time_based_demand(item_id: String, hour: int) -> float:
	"""Get demand modifier based on time of day"""
	var modifier = 0.0
	
	# Breakfast items in morning
	if hour >= 6 and hour <= 9:
		if item_id.contains("breakfast") or item_id.contains("coffee"):
			modifier += 20
	
	# Lunch items midday
	if hour >= 11 and hour <= 13:
		if item_id.contains("lunch") or item_id.contains("sandwich"):
			modifier += 20
	
	# Evening items
	if hour >= 18 and hour <= 22:
		if item_id.contains("dinner") or item_id.contains("wine"):
			modifier += 15
	
	return modifier

func get_weather_demand_modifier(item_id: String, weather: String) -> float:
	"""Get demand modifier based on weather"""
	var modifier = 0.0
	
	match weather:
		"rain":
			if item_id.contains("umbrella") or item_id.contains("raincoat"):
				modifier += 30
			elif item_id.contains("indoor") or item_id.contains("book"):
				modifier += 15
		"sunny":
			if item_id.contains("outdoor") or item_id.contains("sport"):
				modifier += 20
	
	return modifier

func record_ai_decision(decision_type: String, data: Dictionary):
	"""Record AI economic decision for analysis"""
	ai_decisions.append({
		"type": decision_type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Keep history manageable
	if ai_decisions.size() > MAX_DECISION_HISTORY:
		ai_decisions.pop_front()

func get_ai_decision_history(count: int = 10) -> Array:
	"""Get recent AI decisions"""
	return ai_decisions.slice(-count)
