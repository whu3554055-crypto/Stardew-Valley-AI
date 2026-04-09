extends Node

# ============================================
# Daily Narrative Event System
# Generates themed daily narrative scripts with NPC casting
# Integrates with AIEventSystem for world events, focuses on story-driven experiences
# ============================================

signal narrative_generated(narrative_id, narrative_data)
signal narrative_started(narrative_id, cast_list)
signal narrative_ended(narrative_id, outcome)
signal scene_transition_started(transition_type, theme)
signal scene_transition_ended(transition_type)
signal backend_generation_fallback(reason)

# Narrative themes and genres
const NARRATIVE_THEMES = {
	"magical": {
		"name": "Magical Fantasy",
		"description": "Enchanting tales of magic and wonder",
		"visual_filter": "dream_purple",
		"audio_theme": "mystical_harp",
		"mood_modifier": {"wonder": 0.8, "excitement": 0.6}
	},
	"fairy_tale": {
		"name": "Fairy Tale",
		"description": "Classic folklore and fairy tale adaptations",
		"visual_filter": "soft_glow",
		"audio_theme": "orchestral_whimsy",
		"mood_modifier": {"joy": 0.7, "nostalgia": 0.5}
	},
	"horror": {
		"name": "Horror/Mystery",
		"description": "Spine-chilling tales of mystery and suspense",
		"visual_filter": "dark_vignette",
		"audio_theme": "eerie_ambient",
		"mood_modifier": {"fear": 0.7, "tension": 0.8}
	},
	"romantic": {
		"name": "Romance",
		"description": "Heartwarming love stories and relationships",
		"visual_filter": "warm_soft",
		"audio_theme": "gentle_strings",
		"mood_modifier": {"love": 0.9, "tenderness": 0.7}
	},
	"joyful": {
		"name": "Joyful Celebration",
		"description": "Uplifting stories of friendship and happiness",
		"visual_filter": "bright_vibrant",
		"audio_theme": "upbeat_folk",
		"mood_modifier": {"happiness": 0.9, "energy": 0.6}
	},
	"sci_fi": {
		"name": "Science Fiction",
		"description": "Futuristic tales of technology and space",
		"visual_filter": "neon_grid",
		"audio_theme": "synth_wave",
		"mood_modifier": {"curiosity": 0.7, "awe": 0.6}
	},
	"adventure": {
		"name": "Adventure/Quest",
		"description": "Epic journeys and heroic deeds",
		"visual_filter": "cinematic_wide",
		"audio_theme": "epic_orchestral",
		"mood_modifier": {"courage": 0.8, "excitement": 0.7}
	},
	"comedy": {
		"name": "Comedy",
		"description": "Lighthearted humorous situations",
		"visual_filter": "bright_saturated",
		"audio_theme": "playful_winds",
		"mood_modifier": {"amusement": 0.9, "lighthearted": 0.8}
	}
}

# Scenario library - classic tropes and templates
var scenario_library = {}

# Active daily narrative
var current_narrative = {}
var narrative_history = []
var last_generated_day_key = ""
var backend_api_timeout_seconds = 8.0

# Configuration
var config = {
	"enabled": true,
	"auto_generate_daily": true,
	"generation_time": 6.0,  # 6 AM in-game
	"max_duration_hours": 24,
	"allow_player_participation": true,
	"immersive_transitions": true,
	"theme_rotation": true,  # Rotate themes to avoid repetition
	"last_theme_used": "",
	"preferred_themes": [],  # User preferences
	"blocked_themes": []     # Themes to exclude
}

# Casting data
var current_cast = {}
var npc_role_assignments = {}

func _ready():
	initialize_narrative_system()

func initialize_narrative_system():
	"""Initialize the daily narrative system"""
	print("[DailyNarrativeSystem] Initializing...")
	
	load_scenario_library()
	initialize_scene_templates()
	load_config()
	
	if config.auto_generate_daily:
		schedule_daily_generation()
	
	print("[DailyNarrativeSystem] Ready with ", scenario_library.size(), " scenarios")
	print("[DailyNarrativeSystem] Scene templates initialized: ", scene_templates.size())

# ============================================
# SCENARIO LIBRARY
# ============================================

func load_scenario_library():
	"""Load built-in scenario templates"""
	
	# MAGICAL THEMES
	scenario_library["hogwarts_arrival"] = {
		"id": "hogwarts_arrival",
		"theme": "magical",
		"title_template": "The Mysterious Invitation",
		"description": "A magical letter arrives, inviting someone to a secret academy",
		"trope": "chosen_one",
		"roles": {
			"protagonist": {"traits": ["curious", "special"], "count": 1},
			"mentor": {"traits": ["wise", "mysterious"], "count": 1},
			"sidekick": {"traits": ["loyal", "brave"], "count": 1},
			"rival": {"traits": ["proud", "competitive"], "count": 1}
		},
		"scenes": [
			{"location": "home", "action": "receive_mysterious_letter"},
			{"location": "town_square", "action": "magical_display"},
			{"location": "forest", "action": "first_spell_attempt"},
			{"location": "mountains", "action": "final_test"}
		],
		"ai_prompt_additions": "Include magical elements like spells, enchanted objects, and a sense of wonder. Think Harry Potter-esque atmosphere."
	}
	
	scenario_library["butterfly_lovers"] = {
		"id": "butterfly_lovers",
		"theme": "romantic",
		"title_template": "Star-Crossed Lovers",
		"description": "Two souls destined to be together face impossible odds",
		"trope": "forbidden_love",
		"roles": {
			"lover_1": {"traits": ["passionate", "devoted"], "count": 1},
			"lover_2": {"traits": ["gentle", "determined"], "count": 1},
			"obstacle": {"traits": ["strict", "traditional"], "count": 1},
			"confidant": {"traits": ["supportive", "wise"], "count": 1}
		},
		"scenes": [
			{"location": "garden", "action": "first_meeting"},
			{"location": "river", "action": "secret_trysts"},
			{"location": "village", "action": "confrontation"},
			{"location": "hilltop", "action": "transformation"}
		],
		"ai_prompt_additions": "Draw from classical romance traditions. Include poetic dialogue and bittersweet emotions. Think Romeo and Juliet or Butterfly Livers folklore."
	}
	
	# HORROR THEMES
	scenario_library["alien_visit"] = {
		"id": "alien_visit",
		"theme": "horror",
		"title_template": "Visitors from Beyond",
		"description": "Strange occurrences signal an otherworldly presence",
		"trope": "first_contact_gone_wrong",
		"roles": {
			"witness": {"traits": ["observant", "anxious"], "count": 1},
			"skeptic": {"traits": ["logical", "dismissive"], "count": 1},
			"victim": {"traits": ["vulnerable", "isolated"], "count": 1},
			"hero": {"traits": ["brave", "resourceful"], "count": 1}
		},
		"scenes": [
			{"location": "farm", "action": "strange_lights"},
			{"location": "town", "action": "disappearance"},
			{"location": "mine", "action": "discovery"},
			{"location": "beach", "action": "confrontation"}
		],
		"ai_prompt_additions": "Build tension gradually. Use atmospheric horror rather than gore. Think Arrival meets The Thing - uncertainty and paranoia."
	}
	
	scenario_library["haunted_manor"] = {
		"id": "haunted_manor",
		"theme": "horror",
		"title_template": "Whispers in the Dark",
		"description": "A cursed location holds dark secrets from the past",
		"trope": "haunted_location",
		"roles": {
			"investigator": {"traits": ["curious", "skeptical"], "count": 1},
			"spirit": {"traits": ["tragic", "mysterious"], "count": 1},
			"historian": {"traits": ["knowledgeable", "cautious"], "count": 1},
			"skeptic": {"traits": ["pragmatic", "disbelieving"], "count": 1}
		},
		"scenes": [
			{"location": "manor", "action": "arrival_at_dusk"},
			{"location": "library", "action": "discover_diary"},
			{"location": "basement", "action": "supernatural_encounter"},
			{"location": "attic", "action": "lay_spirit_rest"}
		],
		"ai_prompt_additions": "Focus on psychological horror and tragic backstory. The ghost should be sympathetic, not purely evil. Think The Others or Crimson Peak."
	}
	
	# FAIRY TALE THEMES
	scenario_library["cinderella_ball"] = {
		"id": "cinderella_ball",
		"theme": "fairy_tale",
		"title_template": "The Enchanted Evening",
		"description": "An ordinary person gets a chance at transformation",
		"trope": "rags_to_riches",
		"roles": {
			"protagonist": {"traits": ["kind", "dreamer"], "count": 1},
			"benefactor": {"traits": ["magical", "generous"], "count": 1},
			"antagonist": {"traits": ["cruel", "jealous"], "count": 1},
			"love_interest": {"traits": ["charming", "noble"], "count": 1}
		},
		"scenes": [
			{"location": "home", "action": "mundane_life"},
			{"location": "workshop", "action": "magical_transformation"},
			{"location": "town_hall", "action": "grand_event"},
			{"location": "street", "action": "midnight_escape"}
		],
		"ai_prompt_additions": "Classic fairy tale structure with moral lessons. Include magical helpers and a transformative moment. Keep it wholesome and uplifting."
	}
	
	scenario_library["hero_journey"] = {
		"id": "hero_journey",
		"theme": "adventure",
		"title_template": "Call to Adventure",
		"description": "An unlikely hero must rise to face a great challenge",
		"trope": "heroes_journey",
		"roles": {
			"hero": {"traits": ["reluctant", "good_hearted"], "count": 1},
			"mentor": {"traits": ["experienced", "enigmatic"], "count": 1},
			"companion": {"traits": ["faithful", "optimistic"], "count": 1},
			"villain": {"traits": ["powerful", "complex_motivation"], "count": 1}
		},
		"scenes": [
			{"location": "village", "action": "ordinary_world"},
			{"location": "crossroads", "action": "call_to_action"},
			{"location": "wilderness", "action": "trial_by_fire"},
			{"location": "summit", "action": "final_confrontation"}
		],
		"ai_prompt_additions": "Follow Joseph Campbell's monomyth structure. Include refusal of call, supernatural aid, crossing threshold, and return with elixir."
	}
	
	# JOYFUL THEMES
	scenario_library["harvest_festival"] = {
		"id": "harvest_festival",
		"theme": "joyful",
		"title_template": "Community Celebration",
		"description": "The town comes together for a joyous occasion",
		"trope": "community_bonding",
		"roles": {
			"organizer": {"traits": ["enthusiastic", "organized"], "count": 1},
			"performer": {"traits": ["talented", "shy"], "count": 1},
			"newcomer": {"traits": ["outsider", "curious"], "count": 1},
			"elder": {"traits": ["nostalgic", "welcoming"], "count": 1}
		},
		"scenes": [
			{"location": "town_square", "action": "decorations_setup"},
			{"location": "market", "action": "food_preparation"},
			{"location": "stage", "action": "performances"},
			{"location": "square", "action": "group_celebration"}
		],
		"ai_prompt_additions": "Emphasize community spirit, gratitude, and shared joy. Include traditional activities and heartwarming moments."
	}
	
	# SCI-FI THEMES
	scenario_library["time_paradox"] = {
		"id": "time_paradox",
		"theme": "sci_fi",
		"title_template": "Echoes of Tomorrow",
		"description": "Time anomalies create puzzling situations",
		"trope": "time_travel_paradox",
		"roles": {
			"time_traveler": {"traits": ["confused", "determined"], "count": 1},
			"scientist": {"traits": ["analytical", "fascinated"], "count": 1},
			"affected_person": {"traits": ["deja_vu_prone", "intuitive"], "count": 1},
			"guardian": {"traits": ["protective", "knowing"], "count": 1}
		},
		"scenes": [
			{"location": "lab", "action": "experiment_goes_wrong"},
			{"location": "town", "action": "temporal_anomalies"},
			{"location": "past_version", "action": "meeting_self"},
			{"location": "present", "action": "restore_timeline"}
		],
		"ai_prompt_additions": "Explore causality paradoxes gently. Focus on character emotions rather than complex physics. Think Doctor Who - accessible sci-fi."
	}
	
	# COMEDY THEMES
	scenario_library["case_mistaken_identity"] = {
		"id": "case_mistaken_identity",
		"theme": "comedy",
		"title_template": "Double Trouble",
		"description": "Confusion arises from mistaken identities",
		"trope": "mistaken_identity",
		"roles": {
			"lookalike_1": {"traits": ["serious", "professional"], "count": 1},
			"lookalike_2": {"traits": ["carefree", "mischievous"], "count": 1},
			"confused_person": {"traits": ["absent_minded", "well_meaning"], "count": 1},
			"revealer": {"traits": ["observant", "amused"], "count": 1}
		},
		"scenes": [
			{"location": "town", "action": "first_confusion"},
			{"location": "shop", "action": "escalating_mixups"},
			{"location": "event", "action": "chaos_peaks"},
			{"location": "square", "action": "truth_revealed"}
		],
		"ai_prompt_additions": "Classic farce structure with escalating confusion. Keep it light and fun. Think Shakespearean comedy or sitcom misunderstandings."
	}

# ============================================
# DAILY GENERATION SYSTEM
# ============================================

func schedule_daily_generation():
	"""Schedule automatic daily narrative generation"""
	if GameManager:
		GameManager.connect("day_changed", Callable(self, "_on_new_day"))

func _on_new_day(_new_day: int):
	"""Handle new day - generate narrative if enabled"""
	if not config.enabled:
		return
	
	if config.auto_generate_daily:
		await generate_daily_narrative()

func generate_daily_narrative(force_theme: String = "") -> Dictionary:
	"""Generate a complete daily narrative script"""
	var day_key = get_current_day_key()
	if force_theme == "" and day_key == last_generated_day_key and not current_narrative.is_empty():
		return current_narrative
	
	print("[DailyNarrativeSystem] Generating daily narrative...")
	
	# Step 1: Select theme
	var theme = select_theme(force_theme)
	if theme.is_empty():
		push_error("[DailyNarrativeSystem] Failed to select theme")
		return {}
	
	# Step 2: Select scenario from library
	var scenario = select_scenario(theme)
	if scenario.is_empty():
		push_error("[DailyNarrativeSystem] No scenario found for theme: " + theme)
		return {}
	
	# Step 3: Cast NPCs to roles (with temporary character support)
	var cast = get_cast_with_temps(scenario, theme)
	if cast.is_empty():
		push_error("[DailyNarrativeSystem] Failed to cast NPCs")
		return {}
	
	# Step 4: Generate script using AI
	var script = await generate_narrative_script(scenario, cast, theme)
	if script.is_empty():
		push_error("[DailyNarrativeSystem] Failed to generate script")
		return {}
	
	# Step 5: Assemble complete narrative
	var narrative = assemble_narrative(theme, scenario, cast, script)
	
	# Store as current
	current_narrative = narrative
	current_cast = cast
	last_generated_day_key = day_key
	
	# Emit signals
	narrative_generated.emit(narrative.id, narrative)
	
	print("[DailyNarrativeSystem] Generated: ", narrative.title)
	print("[DailyNarrativeSystem] Theme: ", theme)
	print("[DailyNarrativeSystem] Cast size: ", cast.size())
	
	return narrative

func generate_daily_narrative_playable(force_theme: String = "") -> Dictionary:
	"""
	Playable-first entry:
	1) Try backend LLM daily narrative (if available)
	2) Fallback to local generator
	"""
	var ai_narrative = await _generate_daily_narrative_from_backend()
	if not ai_narrative.is_empty():
		current_narrative = ai_narrative
		last_generated_day_key = get_current_day_key()
		narrative_generated.emit(ai_narrative.id, ai_narrative)
		return ai_narrative
	backend_generation_fallback.emit("backend_unavailable_or_invalid")
	return await generate_daily_narrative(force_theme)

func _generate_daily_narrative_from_backend() -> Dictionary:
	if not AIAgentManager or not AIAgentManager._backend_available or not AIAgentManager.has_method("request_text_generation"):
		backend_generation_fallback.emit("backend_offline")
		return {}
	
	var season = GameManager.player_data.season if GameManager else "spring"
	var day = GameManager.player_data.day if GameManager else 1
	var year = GameManager.player_data.year if GameManager else 1

	var body = {
		"season": season,
		"day": day,
		"year": year,
		"context": {
			"weather": WeatherSystem.get_weather_name().to_lower() if WeatherSystem else "sunny",
			"active_npcs": NPCBehaviorController.get_all_npc_ids() if NPCBehaviorController else []
		}
	}
	var gen: Dictionary = await AIAgentManager.request_text_generation({
		"prompt": "daily_narrative_request",
		"source": "daily_narrative",
		"use_backend": true,
		"backend_path": "/api/v1/narrative/daily",
		"backend_body": body,
		"backend_text_key": "summary",
		"timeout_sec": backend_api_timeout_seconds
	})
	if not bool(gen.get("ok", false)):
		backend_generation_fallback.emit(str(gen.get("error", "backend_request_failed")))
		return {}

	var parsed: Dictionary = gen.get("raw", {})
	if parsed.is_empty():
		backend_generation_fallback.emit("empty_backend_payload")
		return {}
	
	var events = parsed.get("events", [])
	return {
		"id": "backend_narrative_" + get_current_day_key(),
		"date": get_current_date_string(),
		"theme": "dynamic",
		"title": "Today's Storyline",
		"description": parsed.get("summary", "A new story unfolds today."),
		"status": "generated",
		"script": {"scenes": []},
		"events": events,
		"source": parsed.get("source", "backend"),
		"created_at": Time.get_unix_time_from_system()
	}

func select_theme(force_theme: String = "") -> String:
	"""Select theme for today's narrative"""
	if force_theme != "" and NARRATIVE_THEMES.has(force_theme):
		return force_theme
	
	# Check user preferences
	var available_themes = NARRATIVE_THEMES.keys()
	
	# Remove blocked themes
	for blocked in config.blocked_themes:
		available_themes.erase(blocked)
	
	if available_themes.is_empty():
		push_error("[DailyNarrativeSystem] No available themes after filtering")
		return ""
	
	# Prefer unused themes
	if config.theme_rotation and config.last_theme_used != "":
		available_themes.erase(config.last_theme_used)
		
		if available_themes.is_empty():
			# Reset rotation if all themes used
			available_themes = NARRATIVE_THEMES.keys()
			for blocked in config.blocked_themes:
				available_themes.erase(blocked)
	
	# Random selection from available
	return available_themes[randi() % available_themes.size()]

func select_scenario(theme: String) -> Dictionary:
	"""Select a scenario matching the theme"""
	var candidates = []
	
	for scenario_id in scenario_library.keys():
		var scenario = scenario_library[scenario_id]
		if scenario.theme == theme:
			candidates.append(scenario)
	
	if candidates.is_empty():
		# Fallback: find any scenario
		candidates = scenario_library.values()
	
	return candidates[randi() % candidates.size()]

# ============================================
# CASTING SYSTEM
# ============================================

func cast_npcs_for_scenario(scenario: Dictionary) -> Dictionary:
	"""Intelligently cast NPCs to roles based on personality matching"""
	var cast = {}
	var roles = scenario.roles
	
	if not NPCBehaviorController or not EnhancedPersonalitySystem:
		push_error("[DailyNarrativeSystem] Required systems not available for casting")
		return {}
	
	# Get all available NPCs
	var all_npcs = NPCBehaviorController.get_all_npc_ids()
	var available_npcs = all_npcs.duplicate()
	var used_npcs = []
	
	# Cast each role
	for role_name in roles.keys():
		var role_requirements = roles[role_name]
		var required_traits = role_requirements.get("traits", [])
		var count = role_requirements.get("count", 1)
		
		var best_matches = find_best_npc_matches(required_traits, available_npcs, used_npcs)
		
		for i in range(min(count, best_matches.size())):
			if not best_matches[i].is_empty():
				cast[role_name] = {
					"npc_id": best_matches[i].npc_id,
					"npc_name": get_npc_name(best_matches[i].npc_id),
					"match_score": best_matches[i].score,
					"matched_traits": best_matches[i].matched_traits
				}
				used_npcs.append(best_matches[i].npc_id)
	
	# If we couldn't fill all roles, try harder with relaxed requirements
	if cast.size() < roles.size():
		fill_remaining_roles(cast, roles, available_npcs, used_npcs)
	
	return cast

func find_best_npc_matches(required_traits: Array, all_npcs: Array, excluded: Array) -> Array:
	"""Find NPCs that best match the required traits"""
	var scored_candidates = []
	
	for npc_id in all_npcs:
		if npc_id in excluded:
			continue
		
		var score = calculate_npc_role_fit(npc_id, required_traits)
		
		scored_candidates.append({
			"npc_id": npc_id,
			"score": score.score,
			"matched_traits": score.matched_traits
		})
	
	# Sort by score descending
	scored_candidates.sort_custom(func(a, b): return a.score > b.score)
	
	return scored_candidates

func calculate_npc_role_fit(npc_id: String, required_traits: Array) -> Dictionary:
	"""Calculate how well an NPC fits a role based on personality"""
	var profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
	var result = {
		"score": 0.0,
		"matched_traits": []
	}
	
	if profile.is_empty():
		return result
	
	# Check personality traits
	var personality = profile.get("personality_core", {})
	var npc_traits = personality.get("traits", [])
	
	var matches = 0
	for required in required_traits:
		for npc_trait in npc_traits:
			if traits_compatible(required, npc_trait):
				matches += 1
				result.matched_traits.append(required)
				break
	
	# Calculate base score
	result.score = float(matches) / max(1, required_traits.size())
	
	# Bonus for speech style matching role tone
	var speech_style = profile.get("speech_patterns", {}).get("style", "neutral")
	if role_tone_matches_speech(required_traits, speech_style):
		result.score += 0.2
	
	# Small random factor for variety
	result.score += randf_range(-0.1, 0.1)
	result.score = clamp(result.score, 0.0, 1.0)
	
	return result

func traits_compatible(required: String, actual: String) -> bool:
	"""Check if two trait descriptions are compatible"""
	required = required.to_lower()
	actual = actual.to_lower()
	
	# Direct match
	if required == actual:
		return true
	
	# Synonym matching
	var synonyms = {
		"brave": ["courageous", "fearless", "bold"],
		"kind": ["gentle", "compassionate", "caring"],
		"wise": ["intelligent", "knowledgeable", "smart"],
		"mysterious": ["enigmatic", "secretive", "cryptic"],
		"cheerful": ["happy", "optimistic", "positive"]
	}
	
	if synonyms.has(required) and actual in synonyms[required]:
		return true
	
	if synonyms.has(actual) and required in synonyms[actual]:
		return true
	
	return false

func role_tone_matches_speech(required_traits: Array, speech_style: String) -> bool:
	"""Check if speech style matches role requirements"""
	if required_traits.has("mysterious") and speech_style == "formal":
		return true
	if required_traits.has("cheerful") and speech_style == "casual":
		return true
	if required_traits.has("wise") and speech_style == "thoughtful":
		return true
	
	return false

func fill_remaining_roles(cast: Dictionary, roles: Dictionary, all_npcs: Array, used: Array):
	"""Fill any unfilled roles with available NPCs"""
	for role_name in roles.keys():
		if not cast.has(role_name):
			# Find any unused NPC
			for npc_id in all_npcs:
				if not npc_id in used:
					cast[role_name] = {
						"npc_id": npc_id,
						"npc_name": get_npc_name(npc_id),
						"match_score": 0.3,
						"matched_traits": []
					}
					used.append(npc_id)
					break

# ============================================
# TEMPORARY CHARACTER SYSTEM
# ============================================

var temporary_characters = {}
var npc_archive = {}  # For storing temporarily created NPCs

func create_temporary_character(role_name: String, role_requirements: Dictionary, theme: String) -> Dictionary:
	"""Create a temporary NPC character for narrative purposes"""
	var temp_id = "temp_" + role_name + "_" + str(randi() % 10000)
	
	# Generate character based on role and theme
	var temp_char = {
		"id": temp_id,
		"name": generate_character_name(role_name, theme),
		"role": role_name,
		"is_temporary": true,
		"personality": generate_temp_personality(role_requirements, theme),
		"appearance": generate_appearance(role_name, theme),
		"backstory": generate_backstory(role_name, theme),
		"duration": "native_only",  # Exists only during this narrative
		"traits": role_requirements.get("traits", [])
	}
	
	temporary_characters[temp_id] = temp_char
	
	print("[DailyNarrativeSystem] Created temporary character: ", temp_char.name)
	
	return temp_char

func generate_character_name(role: String, theme: String) -> String:
	"""Generate appropriate name for temporary character"""
	var name_templates = {
		"magical": {
			"protagonist": ["Young Apprentice", "The Chosen One", "Mysterious Stranger"],
			"mentor": ["Elder Wizard", "Ancient Sage", "Wandering Enchanter"],
			"villain": ["Dark Sorcerer", "Shadow Master", "Corrupted Mage"]
		},
		"horror": {
			"witness": ["Night Watchman", "Lonely Traveler", "Curious Student"],
			"victim": ["Missing Person", "Unlucky Camper", "Late Night Worker"],
			"spirit": ["Restless Ghost", "Trapped Soul", "Forgotten Entity"]
		},
		"romantic": {
			"lover_1": ["Handsome Stranger", "Childhood Friend", "Mysterious Artist"],
			"lover_2": ["Gentle Soul", "Free Spirit", "Noble Heart"],
			"obstacle": ["Strict Parent", "Traditional Elder", "Jealous Rival"]
		},
		"sci_fi": {
			"time_traveler": ["Chrononaut", "Future Refugee", "Timeline Guardian"],
			"scientist": ["Lead Researcher", "Brilliant Mind", "Mad Scientist"],
			"alien": ["Visitor from Beyond", "Star Being", "Cosmic Entity"]
		}
	}
	
	var theme_names = name_templates.get(theme, {})
	var role_names = theme_names.get(role, ["Unknown Character"])
	
	return role_names[randi() % role_names.size()]

func generate_temp_personality(role_req: Dictionary, theme: String) -> Dictionary:
	"""Generate personality for temporary character"""
	return {
		"traits": role_req.get("traits", ["generic"]),
		"temperament": ["calm", "energetic", "melancholic", "cheerful"][randi() % 4],
		"intelligence": randf_range(0.3, 1.0),
		"charisma": randf_range(0.3, 1.0),
		"theme_alignment": theme
	}

func generate_appearance(role: String, theme: String) -> String:
	"""Generate appearance description"""
	var appearances = {
		"magical": "Robes shimmering with arcane energy, eyes glowing with mystical power",
		"horror": "Pale complexion, dark circles under eyes, wearing tattered clothing",
		"romantic": "Warm smile, gentle eyes, dressed in soft flowing garments",
		"sci_fi": "Futuristic attire with strange technology, metallic accessories",
		"fairy_tale": "Enchanting beauty, ethereal grace, dressed in natural materials",
		"adventure": "Rugged appearance, weathered gear, determined expression",
		"joyful": "Bright colors, cheerful demeanor, infectious smile",
		"comedy": "Quirky outfit, exaggerated features, comical posture"
	}
	
	return appearances.get(theme, "Distinctive appearance fitting the role")

func generate_backstory(role: String, theme: String) -> String:
	"""Generate brief backstory for temporary character"""
	var backstories = {
		"magical": "Trained in the ancient arts, seeking to restore balance to the magical realm",
		"horror": "Haunted by past traumas, drawn to the supernatural occurrences in town",
		"romantic": "Searching for true love, carrying secrets from a mysterious past",
		"sci_fi": "Arrived from another time/dimension, mission to prevent catastrophe",
		"fairy_tale": "Cursed/blessed by magical forces, quest to break/find true purpose",
		"adventure": "Seasoned explorer, chasing legends and hidden treasures",
		"joyful": "Spreading happiness wherever they go, organizer of community events",
		"comedy": "Well-meaning but clumsy, always finding themselves in absurd situations"
	}
	
	return backstories.get(theme, "A character with depth and purpose in this story")

func cleanup_temporary_characters():
	"""Remove all temporary characters after narrative ends"""
	var count = temporary_characters.size()
	temporary_characters.clear()
	print("[DailyNarrativeSystem] Cleaned up ", count, " temporary characters")

func get_cast_with_temps(scenario: Dictionary, theme: String) -> Dictionary:
	"""Get cast including temporary characters if needed"""
	var cast = cast_npcs_for_scenario(scenario)
	
	# Check if we need temporary characters for unfilled roles
	for role_name in scenario.roles.keys():
		if not cast.has(role_name):
			# Create temporary character for this role
			var temp_char = create_temporary_character(role_name, scenario.roles[role_name], theme)
			cast[role_name] = {
				"npc_id": temp_char.id,
				"npc_name": temp_char.name,
				"is_temporary": true,
				"character_data": temp_char,
				"match_score": 1.0,  # Perfect fit since custom-made
				"matched_traits": temp_char.traits
			}
	
	return cast

# ============================================
# DYNAMIC SCENE GENERATION
# ============================================

var dynamic_scenes = {}
var scene_templates = {}

func initialize_scene_templates():
	"""Initialize reusable scene templates for narratives"""
	scene_templates = {
		"town_square_day": {
			"name": "Town Square - Daytime",
			"description": "Bustling center of town with townsfolk going about their day",
			"atmosphere": "lively",
			"lighting": "bright_sunlight",
			"ambient_sounds": ["chatter", "footsteps", "birds_chirping"],
			"props": ["market_stalls", "fountain", "benches", "flower_beds"]
		},
		"town_square_night": {
			"name": "Town Square - Night",
			"description": "Peaceful square under moonlight, street lamps casting warm glow",
			"atmosphere": "peaceful",
			"lighting": "moonlight_lamps",
			"ambient_sounds": ["crickets", "distant_music", "gentle_breeze"],
			"props": ["lit_lamps", "empty_benches", "closed_stalls"]
		},
		"forest_clearing": {
			"name": "Mystic Forest Clearing",
			"description": "Secluded glade surrounded by ancient trees",
			"atmosphere": "mysterious",
			"lighting": "dappled_sunlight",
			"ambient_sounds": ["rustling_leaves", "birdsong", "stream_babbling"],
			"props": ["ancient_tree", "mushroom_circle", "hidden_path"]
		},
		"haunted_manor_interior": {
			"name": "Haunted Manor Library",
			"description": "Dusty library filled with ancient tomes and dark secrets",
			"atmosphere": "eerie",
			"lighting": "dim_candlelight",
			"ambient_sounds": ["creaking_floors", "wind_howling", "distant_thunder"],
			"props": ["bookshelves", "fireplace", "secret_passage", "portraits"]
		},
		"laboratory": {
			"name": "Scientific Laboratory",
			"description": "Cluttered lab filled with experiments and inventions",
			"atmosphere": "chaotic_brilliant",
			"lighting": "fluorescent_sparks",
			"ambient_sounds": ["bubbling_liquids", "electrical_hum", "machinery"],
			"props": ["test_tubes", "telescope", "chalkboard_formulas", "inventions"]
		},
		"cafe_cozy": {
			"name": "Cozy Cafe Corner",
			"description": "Warm cafe with aroma of coffee and fresh pastries",
			"atmosphere": "welcoming",
			"lighting": "warm_indoor",
			"ambient_sounds": ["coffee_machine", "soft_jazz", "quiet_conversations"],
			"props": ["tables", "counter", "pastry_case", "plants"]
		},
		"beach_sunset": {
			"name": "Beach at Sunset",
			"description": "Golden hour at the beach, waves gently lapping shore",
			"atmosphere": "romantic",
			"lighting": "golden_hour",
			"ambient_sounds": ["waves", "seagulls", "gentle_wind"],
			"props": ["driftwood", "shells", "sunset_view", "pier"]
		},
		"mountain_peak": {
			"name": "Mountain Summit",
			"description": "Breathtaking view from the mountain peak",
			"atmosphere": "awe_inspiring",
			"lighting": "clear_skies",
			"ambient_sounds": ["wind", "eagle_cry", "silence"],
			"props": ["peak_marker", "prayer_flags", "panoramic_view"]
		}
	}

func generate_dynamic_scene(scene_template: Dictionary, narrative_theme: String) -> Dictionary:
	"""Generate a customized scene based on template and theme"""
	var scene = scene_template.duplicate(true)
	
	# Modify atmosphere based on theme
	scene.atmosphere = adjust_atmosphere_for_theme(scene.atmosphere, narrative_theme)
	scene.lighting = adjust_lighting_for_theme(scene.lighting, narrative_theme)
	
	# Add theme-specific props
	var theme_props = get_theme_specific_props(narrative_theme)
	scene.props.append_array(theme_props)
	
	# Generate unique scene ID
	scene.id = "scene_" + str(randi() % 100000)
	scene.theme = narrative_theme
	
	dynamic_scenes[scene.id] = scene
	
	return scene

func adjust_atmosphere_for_theme(base_atmosphere: String, theme: String) -> String:
	"""Adjust scene atmosphere to match narrative theme"""
	var adjustments = {
		"horror": {"lively": "unsettling", "peaceful": "ominous", "mysterious": "terrifying"},
		"romantic": {"lively": "festive", "peaceful": "intimate", "mysterious": "alluring"},
		"magical": {"lively": "enchanted", "peaceful": "serene", "mysterious": "arcane"},
		"sci_fi": {"lively": "futuristic", "peaceful": "sterile", "mysterious": "otherworldly"}
	}
	
	if adjustments.has(theme) and adjustments[theme].has(base_atmosphere):
		return adjustments[theme][base_atmosphere]
	
	return base_atmosphere

func adjust_lighting_for_theme(base_lighting: String, theme: String) -> String:
	"""Adjust lighting to match theme"""
	var thematic_lighting = {
		"horror": "shadowy_with_flickering",
		"romantic": "soft_warm_glow",
		"magical": "ethereal_shimmer",
		"sci_fi": "neon_and_holographic",
		"fairy_tale": "dreamy_golden",
		"adventure": "dramatic_contrast"
	}
	
	return thematic_lighting.get(theme, base_lighting)

func get_theme_specific_props(theme: String) -> Array:
	"""Get props specific to narrative theme"""
	var theme_props = {
		"horror": ["broken_mirror", "cobwebs", "old_diary", "candles"],
		"magical": ["glowing_crystals", "spell_books", "mystical_symbols", "potions"],
		"romantic": ["rose_petals", "love_letters", "string_lights", "picnic_blanket"],
		"sci_fi": ["holographic_displays", "strange_devices", "alien_artifacts", "screens"],
		"fairy_tale": ["magic_mirror", "pumpkin_carriage", "glass_slipper", "enchanted_items"],
		"adventure": ["treasure_map", "compass", "rope", "torch"],
		"joyful": ["balloons", "confetti", "banner", "gift_boxes"],
		"comedy": ["rubber_chicken", "banana_peel", "whoopee_cushion", "pie"]
	}
	
	return theme_props.get(theme, [])

func get_or_create_scene(location: String, theme: String) -> Dictionary:
	"""Get existing scene or create new dynamic one"""
	# Try to find matching template
	for template_id in scene_templates.keys():
		if location in template_id or template_id in location:
			return generate_dynamic_scene(scene_templates[template_id], theme)
	
	# Create generic scene if no template matches
	return create_generic_scene(location, theme)

func create_generic_scene(location: String, theme: String) -> Dictionary:
	"""Create a generic scene for unknown locations"""
	return {
		"id": "scene_generic_" + str(randi() % 10000),
		"name": location.capitalize().replace("_", " "),
		"description": "A " + location.replace("_", " ") + " setting for the narrative",
		"atmosphere": adjust_atmosphere_for_theme("neutral", theme),
		"lighting": adjust_lighting_for_theme("standard", theme),
		"ambient_sounds": ["ambient_noise"],
		"props": get_theme_specific_props(theme),
		"theme": theme,
		"location": location
	}


# ============================================
# AI SCRIPT GENERATION
# ============================================

func generate_narrative_script(scenario: Dictionary, cast: Dictionary, theme: String) -> Dictionary:
	"""Generate complete narrative script using AI agent"""
	if not AdvancedAIAgentManager:
		push_error("[DailyNarrativeSystem] AdvancedAIAgentManager not available")
		return {}
	
	# Build comprehensive prompt
	var prompt = build_script_generation_prompt(scenario, cast, theme)
	
	# Create context for AI
	var context = {
		"type": "narrative_script",
		"theme": theme,
		"scenario": scenario.id,
		"cast_size": cast.size(),
		"prompt": prompt
	}
	
	# Generate script (synchronous for daily generation)
	var callback_result = []
	var callback = func(agent_id, response):
		callback_result.append(response)
	
	AdvancedAIAgentManager.generate_dialogue_async("narrative_generator", context, callback, 100)
	
	# Wait for response (with timeout)
	var wait_time = 0.0
	while callback_result.is_empty() and wait_time < 30.0:
		await get_tree().create_timer(0.5).timeout
		wait_time += 0.5
	
	if callback_result.is_empty():
		push_error("[DailyNarrativeSystem] AI script generation timed out")
		return generate_fallback_script(scenario, cast, theme)
	
	var ai_response = callback_result[0]
	
	# Parse AI response into structured script
	var parsed_script = parse_ai_script_response(ai_response, scenario, cast)
	
	return parsed_script

func build_script_generation_prompt(scenario: Dictionary, cast: Dictionary, theme: String) -> String:
	"""Build detailed prompt for AI script generation"""
	var prompt = """
You are a talented screenwriter creating a short narrative script for a farming simulation game.

THEME: {theme_name}
{theme_description}

SCENARIO: {scenario_title}
{scenario_description}
Trope: {trope}

CHARACTERS (Cast):
{cast_list}

SCENE STRUCTURE:
{scene_list}

INSTRUCTIONS:
1. Write a engaging short narrative with 4 scenes
2. Each scene should have dialogue and action descriptions
3. Stay true to each character's personality traits
4. Include emotional arcs and character development
5. Keep the tone consistent with the theme
6. Make it immersive but appropriate for all ages
7. Total length: 800-1200 words

{ai_prompt_additions}

FORMAT YOUR RESPONSE AS JSON:
{{
	"title": "Script Title",
	"scenes": [
		{{
			"scene_number": 1,
			"location": "location_name",
			"action": "description of what happens",
			"dialogue": [
				{{"character": "role_name", "line": "dialogue text", "emotion": "emotion"}}
			],
			"mood": "overall mood of scene"
		}}
	],
	"narrator_notes": "Additional context for presentation"
}}
""".format({
		"theme_name": NARRATIVE_THEMES[theme].name,
		"theme_description": NARRATIVE_THEMES[theme].description,
		"scenario_title": scenario.title_template,
		"scenario_description": scenario.description,
		"trope": scenario.trope,
		"cast_list": format_cast_for_prompt(cast),
		"scene_list": format_scenes_for_prompt(scenario.scenes),
		"ai_prompt_additions": scenario.get("ai_prompt_additions", "")
	})
	
	return prompt

func format_cast_for_prompt(cast: Dictionary) -> String:
	"""Format cast list for AI prompt"""
	var text = ""
	for role_name in cast.keys():
		var actor = cast[role_name]
		text += "- {role}: {name} (Traits: {traits})\n".format({
			"role": role_name.capitalize(),
			"name": actor.npc_name,
			"traits": ", ".join(actor.matched_traits) if actor.matched_traits else "general"
		})
	return text

func format_scenes_for_prompt(scenes: Array) -> String:
	"""Format scene structure for AI prompt"""
	var text = ""
	for i in range(scenes.size()):
		var scene = scenes[i]
		text += "{num}. {location}: {action}\n".format({
			"num": i + 1,
			"location": scene.location.capitalize(),
			"action": scene.action.replace("_", " ")
		})
	return text

func parse_ai_script_response(ai_response, scenario: Dictionary, cast: Dictionary) -> Dictionary:
	"""Parse AI response into structured script"""
	# If response is already a dictionary (parsed JSON)
	if ai_response is Dictionary:
		return ai_response
	
	# If string, try to parse JSON
	if ai_response is String:
		var json_result = JSON.parse_string(ai_response)
		if json_result is Dictionary:
			return json_result
	
	# If parsing failed, return fallback
	push_warning("[DailyNarrativeSystem] Could not parse AI response, using fallback")
	return generate_fallback_script(scenario, cast, "magical")

func generate_fallback_script(scenario: Dictionary, cast: Dictionary, theme: String) -> Dictionary:
	"""Generate a basic fallback script if AI fails"""
	var script = {
		"title": scenario.title_template,
		"scenes": [],
		"narrator_notes": "Generated using fallback template"
	}
	
	var locations = ["town_square", "garden", "forest", "beach"]
	var actions = ["discussion", "discovery", "celebration", "reflection"]
	
	for i in range(4):
		var scene = {
			"scene_number": i + 1,
			"location": locations[i] if i < locations.size() else "town",
			"action": actions[i] if i < actions.size() else "interaction",
			"dialogue": [],
			"mood": theme
		}
		
		# Add simple dialogue for each cast member
		for role in cast.keys():
			scene.dialogue.append({
				"character": role,
				"line": "This is part of our {theme} story.".format({"theme": theme}),
				"emotion": "neutral"
			})
		
		script.scenes.append(scene)
	
	return script

# ============================================
# NARRATIVE ASSEMBLY
# ============================================

func assemble_narrative(theme: String, scenario: Dictionary, cast: Dictionary, script: Dictionary) -> Dictionary:
	"""Assemble complete narrative package with scenes and characters"""
	# Generate dynamic scenes for each script scene
	var generated_scenes = []
	if script.has("scenes"):
		for script_scene in script.scenes:
			var location = script_scene.get("location", "town_square")
			var dynamic_scene = get_or_create_scene(location, theme)
			dynamic_scene.scene_number = script_scene.get("scene_number", 1)
			dynamic_scene.action = script_scene.get("action", "")
			generated_scenes.append(dynamic_scene)
	
	var narrative = {
		"id": "narrative_" + str(Time.get_unix_time_from_system()).replace(".", ""),
		"date": get_current_date_string(),
		"theme": theme,
		"theme_info": NARRATIVE_THEMES[theme],
		"scenario_id": scenario.id,
		"title": script.get("title", scenario.title_template),
		"description": scenario.description,
		"cast": cast,
		"script": script,
		"scenes": generated_scenes,
		"has_temporary_characters": check_for_temp_characters(cast),
		"status": "generated",
		"created_at": Time.get_unix_time_from_system(),
		"presentation": {
			"visual_filter": NARRATIVE_THEMES[theme].visual_filter,
			"audio_theme": NARRATIVE_THEMES[theme].audio_theme,
			"mood_modifiers": NARRATIVE_THEMES[theme].mood_modifier
		}
	}
	
	return narrative

func check_for_temp_characters(cast: Dictionary) -> bool:
	"""Check if cast includes temporary characters"""
	for role in cast.keys():
		if cast[role].get("is_temporary", false):
			return true
	return false

# ============================================
# IMMERSIVE PRESENTATION
# ============================================

func start_narrative_presentation():
	"""Begin immersive narrative presentation with transitions"""
	if current_narrative.is_empty():
		push_error("[DailyNarrativeSystem] No narrative to present")
		return
	
	if not config.immersive_transitions:
		# Skip transitions, just emit started
		narrative_started.emit(current_narrative.id, current_narrative.cast)
		return
	
	var theme = current_narrative.theme
	var presentation = current_narrative.presentation
	
	# Start visual transition
	apply_visual_filter(presentation.visual_filter, theme)
	
	# Start audio transition
	play_theme_audio(presentation.audio_theme, theme)
	
	# Apply mood modifiers to NPCs
	apply_mood_modifiers(presentation.mood_modifiers)
	
	# Update status
	current_narrative.status = "active"
	
	# Emit started signal
	narrative_started.emit(current_narrative.id, current_narrative.cast)
	
	print("[DailyNarrativeSystem] Narrative presentation started: ", current_narrative.title)

func apply_visual_filter(filter_type: String, theme: String):
	"""Apply visual filter for narrative immersion"""
	scene_transition_started.emit(filter_type, theme)
	
	# In a real implementation, this would:
	# - Apply shader effects
	# - Change color grading
	# - Add particle effects
	# - Modify UI appearance
	
	print("[DailyNarrativeSystem] Visual filter applied: ", filter_type)
	
	# Example: Transition effect
	await get_tree().create_timer(1.0).timeout
	scene_transition_ended.emit(filter_type)

func play_theme_audio(audio_theme: String, theme: String):
	"""Play thematic audio for narrative"""
	if NPCAudioManager:
		# Keep API compatible with current audio manager MVP.
		# Theme-specific track routing can be added later.
		NPCAudioManager.play_ambient_sound("town")
	
	print("[DailyNarrativeSystem] Audio theme playing: ", audio_theme)

func apply_mood_modifiers(modifiers: Dictionary):
	"""Apply mood modifications to cast members"""
	if not NPCTraitSystem:
		return
	
	for role in current_narrative.cast.keys():
		var npc_id = current_narrative.cast[role].npc_id
		
		# Apply primary mood modifier
		for mood_name in modifiers.keys():
			var intensity = modifiers[mood_name]
			NPCTraitSystem.set_mood(npc_id, mood_name, intensity, 3600.0)

func end_narrative_presentation():
	"""End narrative presentation and restore normal state"""
	if current_narrative.is_empty():
		return
	
	# Clear visual filters
	remove_visual_filters()
	
	# Restore default town ambience after narrative theme
	if NPCAudioManager:
		NPCAudioManager.play_ambient_sound("town")
	
	# Update status
	current_narrative.status = "completed"
	current_narrative.ended_at = Time.get_unix_time_from_system()
	
	# Cleanup temporary characters
	if current_narrative.has_temporary_characters:
		cleanup_temporary_characters()
	
	# Add to history
	narrative_history.append(current_narrative.duplicate(true))
	
	# Emit ended signal
	narrative_ended.emit(current_narrative.id, "completed")
	
	# Save to config
	config.last_theme_used = current_narrative.theme
	save_config()
	
	print("[DailyNarrativeSystem] Narrative presentation ended")

func remove_visual_filters():
	"""Remove all visual filters and restore normal view"""
	scene_transition_started.emit("clear", "normal")
	await get_tree().create_timer(0.5).timeout
	scene_transition_ended.emit("clear")

# ============================================
# ADMIN INTERFACE SUPPORT
# ============================================

func get_available_themes() -> Array:
	"""Get list of all available themes"""
	var themes = []
	for theme_id in NARRATIVE_THEMES.keys():
		themes.append({
			"id": theme_id,
			"name": NARRATIVE_THEMES[theme_id].name,
			"description": NARRATIVE_THEMES[theme_id].description,
			"blocked": theme_id in config.blocked_themes
		})
	return themes

func get_scenario_library_summary() -> Array:
	"""Get summary of all scenarios"""
	var summaries = []
	for scenario_id in scenario_library.keys():
		var scenario = scenario_library[scenario_id]
		summaries.append({
			"id": scenario_id,
			"title": scenario.title_template,
			"theme": scenario.theme,
			"trope": scenario.trope,
			"roles_count": scenario.roles.size()
		})
	return summaries

func add_custom_scenario(scenario_data: Dictionary) -> bool:
	"""Add a custom scenario to the library"""
	if not scenario_data.has("id") or not scenario_data.has("theme"):
		push_error("[DailyNarrativeSystem] Custom scenario missing required fields")
		return false
	
	scenario_library[scenario_data.id] = scenario_data
	save_scenario_library()
	return true

func remove_scenario(scenario_id: String) -> bool:
	"""Remove a scenario from the library"""
	if scenario_library.has(scenario_id):
		scenario_library.erase(scenario_id)
		save_scenario_library()
		return true
	return false

func toggle_theme_availability(theme_id: String, blocked: bool):
	"""Block or unblock a theme"""
	if blocked:
		if not theme_id in config.blocked_themes:
			config.blocked_themes.append(theme_id)
	else:
		config.blocked_themes.erase(theme_id)
	
	save_config()

func set_theme_preference(theme_id: String, preferred: bool):
	"""Add or remove theme from preferences"""
	if preferred:
		if not theme_id in config.preferred_themes:
			config.preferred_themes.append(theme_id)
	else:
		config.preferred_themes.erase(theme_id)
	
	save_config()

# ============================================
# CONFIGURATION MANAGEMENT
# ============================================

func load_config():
	"""Load configuration from file"""
	var config_path = "user://daily_narrative_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			file.close()
			config.merge(data, true)

func save_config():
	"""Save configuration to file"""
	var config_path = "user://daily_narrative_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config))
		file.close()

func save_scenario_library():
	"""Save custom scenarios to file"""
	var library_path = "user://custom_scenarios.json"
	var file = FileAccess.open(library_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(scenario_library))
		file.close()

# ============================================
# UTILITY FUNCTIONS
# ============================================

func get_npc_name(npc_id: String) -> String:
	"""Get NPC display name"""
	if EnhancedPersonalitySystem:
		var profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
		if profile.has("basic_info"):
			return profile.basic_info.get("name", npc_id)
	return npc_id.capitalize()

func get_current_date_string() -> String:
	"""Get current in-game date as string"""
	if GameManager and GameManager.player_data:
		return "Year {year}, {season} {day}".format({
			"year": GameManager.player_data.year,
			"season": GameManager.player_data.season.capitalize(),
			"day": GameManager.player_data.day
		})
	return "Unknown Date"

func get_current_day_key() -> String:
	"""Compact key for per-day generation guard."""
	if GameManager and GameManager.player_data:
		return "{y}-{s}-{d}".format({
			"y": GameManager.player_data.year,
			"s": GameManager.player_data.season,
			"d": GameManager.player_data.day
		})
	return "unknown-day"

func get_current_narrative() -> Dictionary:
	"""Get current active narrative"""
	return current_narrative

func get_narrative_history(count: int = 10) -> Array:
	"""Get recent narrative history"""
	return narrative_history.slice(-count)

func is_narrative_active() -> bool:
	"""Check if a narrative is currently active"""
	return current_narrative.get("status") == "active"
