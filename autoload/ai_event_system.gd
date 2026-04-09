extends Node

# ============================================
# AI Event Generation System
# Autonomous event creation: weather, festivals, emergencies, social events
# Fully AI-driven world state management
# ============================================

signal event_generated(event_type, event_data)
signal event_started(event_id, event_info)
signal event_ended(event_id, outcome)
signal world_state_changed(change_type, change_data)

# Event categories
const EVENT_CATEGORIES = {
	"weather": ["storm", "heatwave", "cold_snap", "fog", "meteor_shower"],
	"social": ["festival", "gathering", "competition", "celebration", "memorial"],
	"emergency": ["fire", "flood", "illness_outbreak", "missing_person", "infestation"],
	"economic": ["market_boom", "recession", "shortage", "surplus", "new_business"],
	"personal": ["birthday", "anniversary", "achievement", "crisis", "opportunity"]
}

# Active events
var active_events = {}
var event_history = []
var pending_events = []

# World state tracking
var world_state = {
	"mood": 0.5,            # Overall town mood (0-1)
	"prosperity": 0.5,      # Economic health (0-1)
	"social_cohesion": 0.5, # Community bonds (0-1)
	"stress_level": 0.3,    # Town stress (0-1)
	"activity_level": 0.5,  # How active the town is (0-1)
	"recent_events": [],    # Last 20 events
	"event_patterns": {},   # Detected patterns
	"npc_states": {}        # Individual NPC states
}

# AI event generation parameters
var generation_params = {
	"min_event_interval": 3600,   # Minimum seconds between events
	"max_concurrent_events": 3,   # Max simultaneous events
	"event_probability": 0.3,     # Base probability per check
	"severity_distribution": {    # Distribution of event severities
		"minor": 0.5,
		"moderate": 0.35,
		"major": 0.12,
		"critical": 0.03
	},
	"seasonal_weights": {}        # Season-based event weighting
}

# Event templates database
var event_templates = {}

func _ready():
	initialize_event_system()
	start_autonomous_generation()

func initialize_event_system():
	"""Initialize the event generation system"""
	print("[AIEventSystem] Initializing autonomous event generation...")
	
	load_event_templates()
	initialize_seasonal_weights()
	initialize_world_state()
	
	print("[AIEventSystem] Ready with ", event_templates.size(), " event templates")

func load_event_templates():
	"""Load event templates from definition"""
	# Weather Events
	event_templates["storm"] = {
		"category": "weather",
		"name": "Thunderstorm",
		"description": "A severe thunderstorm sweeps through the valley",
		"duration_hours": randi_range(4, 12),
		"severity": "moderate",
		"effects": {
			"crops_watered": true,
			"outdoor_penalty": -0.3,
			"indoor_bonus": 0.2,
			"mood_impact": -0.1
		},
		"prerequisites": {
			"season": ["spring", "summer", "fall"],
			"min_days_between": 5
		},
		"ai_triggers": [
			"Low crop hydration levels",
			"High temperature buildup",
			"Atmospheric pressure changes"
		]
	}
	
	event_templates["meteor_shower"] = {
		"category": "weather",
		"name": "Meteor Shower",
		"description": "A beautiful meteor shower lights up the night sky",
		"duration_hours": randi_range(2, 4),
		"severity": "minor",
		"effects": {
			"night_activity_bonus": 0.5,
			"wishing_opportunity": true,
			"mood_impact": 0.3,
			"romance_bonus": 0.2
		},
		"prerequisites": {
			"time_of_day": "night",
			"weather_clear": true,
			"min_days_between": 15
		},
		"ai_triggers": [
			"Clear night forecast",
			"Astronomical alignment",
			"Community needs positive event"
		]
	}
	
	# Social Events
	event_templates["festival"] = {
		"category": "social",
		"name": "Spontaneous Festival",
		"description": "NPCs organize an impromptu celebration",
		"duration_hours": randi_range(6, 12),
		"severity": "major",
		"effects": {
			"social_cohesion_boost": 0.2,
			"mood_impact": 0.4,
			"economic_activity": 1.3,
			"tourism_increase": true
		},
		"prerequisites": {
			"min_social_cohesion": 0.6,
			"no_recent_festivals": 14,
			"town_prosperity": 0.5
		},
		"ai_triggers": [
			"High community morale",
			"Recent achievements unlocked",
			"Seasonal milestone reached",
			"Need for social bonding"
		]
	}
	
	event_templates["competition"] = {
		"category": "social",
		"name": "Skill Competition",
		"description": "Town residents compete in a friendly contest",
		"duration_hours": randi_range(3, 6),
		"severity": "minor",
		"effects": {
			"skill_motivation": 0.3,
			"social_interaction": 0.4,
			"rivalry_increase": 0.1,
			"entertainment_value": 0.5
		},
		"prerequisites": {
			"interested_npcs": 3,
			"venue_available": true
		},
		"ai_triggers": [
			"Multiple NPCs practicing same skill",
			"Low recent entertainment",
			"Healthy rivalry detected"
		]
	}
	
	# Emergency Events
	event_templates["fire"] = {
		"category": "emergency",
		"name": "Building Fire",
		"description": "A fire breaks out in a building!",
		"duration_hours": randi_range(2, 6),
		"severity": "major",
		"effects": {
			"stress_increase": 0.4,
			"community_response": true,
			"potential_damage": true,
			"heroism_opportunity": true
		},
		"prerequisites": {
			"building_present": true,
			"dry_conditions": true,
			"min_days_between": 20
		},
		"ai_triggers": [
			"Dry weather conditions",
			"Old building infrastructure",
			"Narrative tension needed",
			"Hero opportunity required"
		]
	}
	
	event_templates["missing_person"] = {
		"category": "emergency",
		"name": "Missing Person",
		"description": "An NPC has gone missing and needs to be found",
		"duration_hours": randi_range(12, 48),
		"severity": "major",
		"effects": {
			"concern_level": 0.5,
			"search_party_formation": true,
			"story_development": true,
			"relationship_building": true
		},
		"prerequisites": {
			"target_npc_available": true,
			"wilderness_accessible": true
		},
		"ai_triggers": [
			"NPC with wandering trait",
			"Story needs development",
			"Player needs engagement",
			"Relationship dynamics shift"
		]
	}
	
	# Economic Events
	event_templates["market_boom"] = {
		"category": "economic",
		"name": "Market Boom",
		"description": "Economic prosperity sweeps the town",
		"duration_hours": randi_range(48, 168),
		"severity": "moderate",
		"effects": {
			"price_increase": 1.2,
			"vendor_optimism": 0.3,
			"construction_projects": true,
			"employment_increase": true
		},
		"prerequisites": {
			"base_prosperity": 0.5,
			"positive_trend": true
		},
		"ai_triggers": [
			"Sustained economic growth",
			"New business openings",
			"Tourist influx",
			"Successful harvest season"
		]
	}
	
	event_templates["shortage"] = {
		"category": "economic",
		"name": "Resource Shortage",
		"description": "A critical resource becomes scarce",
		"duration_hours": randi_range(72, 240),
		"severity": "moderate",
		"effects": {
			"price_spike": 1.5,
			"substitution_behavior": true,
			"innovation_drive": 0.2,
			"frustration_increase": 0.3
		},
		"prerequisites": {
			"resource_dependency": true,
			"supply_chain_vulnerable": true
		},
		"ai_triggers": [
			"Supply chain disruption",
			"Overconsumption detected",
			"Seasonal scarcity",
			"Economic balance needed"
		]
	}

func initialize_seasonal_weights():
	"""Set event generation weights by season"""
	generation_params.seasonal_weights = {
		"spring": {
			"weather": 0.4,
			"social": 0.3,
			"emergency": 0.1,
			"economic": 0.2
		},
		"summer": {
			"weather": 0.3,
			"social": 0.4,
			"emergency": 0.15,
			"economic": 0.15
		},
		"fall": {
			"weather": 0.2,
			"social": 0.3,
			"emergency": 0.1,
			"economic": 0.4
		},
		"winter": {
			"weather": 0.5,
			"social": 0.2,
			"emergency": 0.2,
			"economic": 0.1
		}
	}

func initialize_world_state():
	"""Initialize world state from current game data"""
	if GameManager:
		world_state.prosperity = 0.5  # Could be calculated from player wealth
	
	if NPCTraitSystem:
		# Calculate average NPC mood
		var total_mood = 0.0
		var npc_count = 0
		
		# This would iterate through all NPCs
		world_state.mood = 0.5

# ============================================
# AUTONOMOUS EVENT GENERATION
# ============================================

func start_autonomous_generation():
	"""Start autonomous event generation loop"""
	# Check for event generation every 30 minutes of game time
	if GameManager:
		GameManager.connect("time_changed", Callable(self, "_on_time_check"))

func _on_time_check(new_time: float):
	"""Periodically check if events should be generated"""
	# Only check on the hour
	if int(new_time * 10) % 6 == 0:
		attempt_generate_event()

func attempt_generate_event():
	"""Attempt to generate a new event based on AI analysis"""
	# Check cooldown
	if not enough_time_since_last_event():
		return
	
	# Check concurrent event limit
	if active_events.size() >= generation_params.max_concurrent_events:
		return
	
	# Calculate generation probability
	var probability = calculate_generation_probability()
	
	if randf() < probability:
		var event_data = generate_intelligent_event()
		if event_data:
			execute_event(event_data)

func calculate_generation_probability() -> float:
	"""Calculate probability of generating an event"""
	var base_prob = generation_params.event_probability
	
	# Adjust based on world state
	if world_state.activity_level < 0.3:
		base_prob *= 1.5  # Need more activity
	
	if world_state.stress_level > 0.7:
		base_prob *= 0.5  # Reduce stress-inducing events
	
	if world_state.mood < 0.3:
		base_prob *= 1.3  # Generate mood-lifting events
	
	# Seasonal adjustment
	var season = get_current_season()
	if generation_params.seasonal_weights.has(season):
		var max_weight = 0.0
		for weight in generation_params.seasonal_weights[season].values():
			max_weight = max(max_weight, weight)
		base_prob *= (0.5 + max_weight * 0.5)
	
	return clamp(base_prob, 0.1, 0.8)

func generate_intelligent_event() -> Dictionary:
	"""Use AI to intelligently select and configure an event"""
	# Step 1: Analyze current situation
	var situation_analysis = analyze_current_situation()
	
	# Step 2: Determine event category needed
	var needed_category = determine_needed_category(situation_analysis)
	
	# Step 3: Select specific event template
	var template = select_event_template(needed_category, situation_analysis)
	
	if template.is_empty():
		return {}
	
	# Step 4: Configure event parameters
	var configured_event = configure_event(template, situation_analysis)
	
	# Step 5: Validate prerequisites
	if not validate_prerequisites(configured_event):
		return {}
	
	return configured_event

func analyze_current_situation() -> Dictionary:
	"""Analyze current game state for event planning"""
	var analysis = {
		"town_mood": world_state.mood,
		"prosperity": world_state.prosperity,
		"social_cohesion": world_state.social_cohesion,
		"stress_level": world_state.stress_level,
		"recent_event_types": [],
		"npc_needs": analyze_npc_needs(),
		"environmental_factors": get_environmental_factors(),
		"narrative_opportunities": identify_narrative_opportunities()
	}
	
	# Get recent event types
	for event in world_state.recent_events:
		if not analysis.recent_event_types.has(event.category):
			analysis.recent_event_types.append(event.category)
	
	return analysis

func analyze_npc_needs() -> Dictionary:
	"""Analyze what NPCs currently need"""
	var needs = {
		"social_interaction": 0.5,
		"excitement": 0.5,
		"security": 0.5,
		"achievement": 0.5
	}
	
	# In full implementation, query NPCTraitSystem for each NPC
	# and aggregate their needs
	
	return needs

func get_environmental_factors() -> Dictionary:
	"""Get current environmental conditions"""
	var factors = {
		"season": get_current_season(),
		"weather": get_current_weather(),
		"time_of_day": get_time_period(),
		"day_of_week": get_day_type()
	}
	
	return factors

func identify_narrative_opportunities() -> Array:
	"""Identify opportunities for narrative development"""
	var opportunities = []
	
	# Check for unresolved story threads
	# Check for relationship developments
	# Check for character arcs
	
	return opportunities

func determine_needed_category(situation: Dictionary) -> String:
	"""Determine which event category is most needed"""
	var scores = {
		"weather": 0.5,
		"social": 0.5,
		"emergency": 0.3,
		"economic": 0.5
	}
	
	# Adjust based on situation
	if situation.town_mood < 0.4:
		scores.social += 0.3  # Need social events to boost mood
	
	if situation.stress_level > 0.6:
		scores.emergency -= 0.2  # Avoid adding stress
	
	if situation.prosperity < 0.4:
		scores.economic += 0.2  # Need economic stimulation
	
	# Find highest scoring category
	var best_category = "social"
	var best_score = 0.0
	
	for category in scores.keys():
		if scores[category] > best_score:
			best_score = scores[category]
			best_category = category
	
	return best_category

func select_event_template(category: String, situation: Dictionary) -> Dictionary:
	"""Select appropriate event template"""
	var candidates = []
	
	for template_name in event_templates.keys():
		var template = event_templates[template_name]
		
		if template.category == category:
			# Check if template fits current situation
			if template_fits_situation(template, situation):
				candidates.append(template)
	
	if candidates.is_empty():
		return {}
	
	# Select based on variety (prefer less recently used)
	return weighted_random_selection(candidates)

func template_fits_situation(template: Dictionary, situation: Dictionary) -> bool:
	"""Check if a template fits current situation"""
	# Check prerequisites
	var prereqs = template.get("prerequisites", {})
	
	if prereqs.has("season"):
		var current_season = get_current_season()
		if not current_season in prereqs.season:
			return false
	
	if prereqs.has("min_social_cohesion"):
		if situation.social_cohesion < prereqs.min_social_cohesion:
			return false
	
	if prereqs.has("town_prosperity"):
		if situation.prosperity < prereqs.town_prosperity:
			return false
	
	return true

func weighted_random_selection(candidates: Array) -> Dictionary:
	"""Select from candidates with weighting for variety"""
	if candidates.size() == 1:
		return candidates[0]
	
	# Weight by recency (less recently used = higher weight)
	var weights = []
	for candidate in candidates:
		var last_used = get_last_event_time(candidate.name)
		var recency_weight = 1.0 / (1.0 + last_used)
		weights.append(recency_weight)
	
	# Normalize weights
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	for i in range(weights.size()):
		weights[i] /= total_weight
	
	# Select based on weights
	var roll = randf()
	var cumulative = 0.0
	
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]
	
	return candidates[candidates.size() - 1]

func configure_event(template: Dictionary, situation: Dictionary) -> Dictionary:
	"""Configure event with specific parameters"""
	var configured = template.duplicate(true)
	
	# Add runtime data
	configured.id = generate_event_id()
	configured.created_at = Time.get_unix_time_from_system()
	configured.status = "pending"
	configured.situation_context = situation
	
	# Adjust severity based on world state
	configured.severity = adjust_severity(template, situation)
	
	return configured

func adjust_severity(template: Dictionary, situation: Dictionary) -> String:
	"""Adjust event severity based on context"""
	var base_severity = template.severity
	
	# If town is stressed, reduce severity
	if situation.stress_level > 0.7 and base_severity in ["major", "critical"]:
		return "moderate"
	
	# If town needs excitement, increase severity
	if situation.town_mood < 0.3 and base_severity == "minor":
		return "moderate"
	
	return base_severity

func validate_prerequisites(event_data: Dictionary) -> bool:
	"""Validate that all prerequisites are met"""
	var prereqs = event_data.get("prerequisites", {})
	
	# Check timing
	if prereqs.has("min_days_between"):
		var last_similar = get_last_event_time(event_data.name)
		var days_since = last_similar / 86400.0  # Convert to days
		if days_since < prereqs.min_days_between:
			return false
	
	return true

# ============================================
# EVENT EXECUTION
# ============================================

func execute_event(event_data: Dictionary):
	"""Execute a generated event"""
	event_data.status = "active"
	event_data.started_at = Time.get_unix_time_from_system()
	
	active_events[event_data.id] = event_data
	
	# Emit signals
	event_generated.emit(event_data.category, event_data)
	event_started.emit(event_data.id, event_data)
	
	# Apply effects
	apply_event_effects(event_data)
	
	# Schedule end
	if event_data.has("duration_hours"):
		var timer = Timer.new()
		timer.wait_time = event_data.duration_hours * 3600.0 / 60.0  # Convert to real seconds (assuming 60x speed)
		timer.one_shot = true
		add_child(timer)
		timer.start()
		timer.timeout.connect(Callable(self, "_on_event_ended").bind(event_data.id))
	
	# Record in history
	world_state.recent_events.append({
		"id": event_data.id,
		"name": event_data.name,
		"category": event_data.category,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	if world_state.recent_events.size() > 20:
		world_state.recent_events.pop_front()
	
	print("[AIEventSystem] Event started: ", event_data.name)

func apply_event_effects(event_data: Dictionary):
	"""Apply the effects of an event to the world"""
	var effects = event_data.get("effects", {})
	
	# Update world state
	if effects.has("mood_impact"):
		world_state.mood = clamp(world_state.mood + effects.mood_impact, 0, 1)
	
	if effects.has("social_cohesion_boost"):
		world_state.social_cohesion = clamp(
			world_state.social_cohesion + effects.social_cohesion_boost, 0, 1)
	
	if effects.has("stress_increase"):
		world_state.stress_level = clamp(
			world_state.stress_level + effects.stress_increase, 0, 1)
	
	# Notify other systems
	world_state_changed.emit("event_effects", {
		"event": event_data.id,
		"effects": effects
	})
	
	# Apply to NPCs
	notify_npcs_of_event(event_data)

func notify_npcs_of_event(event_data: Dictionary):
	"""Notify NPCs about the event so they can react"""
	if not NPCBehaviorController:
		return
	
	# Get all NPCs
	var all_npcs = NPCBehaviorController.get_all_npc_ids()
	
	for npc_id in all_npcs:
		# Each NPC decides how to react based on personality
		var reaction = calculate_npc_reaction(npc_id, event_data)
		
		if reaction.should_respond:
			NPCBehaviorController.trigger_event_response(npc_id, event_data, reaction)

func calculate_npc_reaction(npc_id: String, event_data: Dictionary) -> Dictionary:
	"""Calculate how an NPC should react to an event"""
	var reaction = {
		"should_respond": false,
		"response_type": "observe",
		"intensity": 0.5
	}
	
	# Get NPC traits
	if NPCTraitSystem:
		var mood = NPCTraitSystem.get_mood_state(npc_id)
		
		# Excitable NPCs respond more
		if mood.get("volatility", 0.5) > 0.7:
			reaction.should_respond = true
			reaction.intensity = 0.8
	
	return reaction

func _on_event_ended(event_id: String):
	"""Handle event ending"""
	if not active_events.has(event_id):
		return
	
	var event_data = active_events[event_id]
	event_data.status = "ended"
	event_data.ended_at = Time.get_unix_time_from_system()
	
	# Move to history
	event_history.append(event_data.duplicate())
	active_events.erase(event_id)
	
	# Emit signal
	event_ended.emit(event_id, {
		"outcome": "completed",
		"duration": event_data.ended_at - event_data.started_at
	})
	
	print("[AIEventSystem] Event ended: ", event_data.name)

# ============================================
# UTILITY FUNCTIONS
# ============================================

func enough_time_since_last_event() -> bool:
	"""Check if enough time has passed since last event"""
	if world_state.recent_events.is_empty():
		return true
	
	var last_event = world_state.recent_events.back()
	var time_since = Time.get_unix_time_from_system() - last_event.timestamp
	
	return time_since >= generation_params.min_event_interval

func get_last_event_time(event_name: String) -> float:
	"""Get timestamp of last occurrence of an event"""
	for event in event_history:
		if event.name == event_name:
			return event.ended_at
	
	return 999999.0  # Never occurred

func generate_event_id() -> String:
	"""Generate unique event ID"""
	return "evt_" + str(Time.get_unix_time_from_system()).replace(".", "") + "_" + str(randi() % 1000)

func get_current_season() -> String:
	"""Get current season"""
	if GameManager and GameManager.player_data:
		return GameManager.player_data.season
	return "spring"

func get_current_weather() -> String:
	"""Get current weather"""
	if WeatherSystem:
		return WeatherSystem.get_weather_name().to_lower()
	return "sunny"

func get_time_period() -> String:
	"""Get current time period"""
	if GameManager:
		var hour = int(GameManager.current_time)
		if hour < 6:
			return "early_morning"
		elif hour < 12:
			return "morning"
		elif hour < 17:
			return "afternoon"
		elif hour < 21:
			return "evening"
		else:
			return "night"
	return "day"

func get_day_type() -> String:
	"""Get day type (weekday/weekend/festival)"""
	# Simplified - could check festival calendar
	return "weekday"

func get_active_events() -> Array:
	"""Get all currently active events"""
	return active_events.values()

func get_event_history(count: int = 10) -> Array:
	"""Get recent event history"""
	return event_history.slice(-count)

func get_world_state_summary() -> Dictionary:
	"""Get summary of current world state"""
	return world_state.duplicate()
