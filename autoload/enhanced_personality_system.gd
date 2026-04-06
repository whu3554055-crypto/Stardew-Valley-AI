extends Node

class_name EnhancedPersonalitySystem

# ============================================
# Enhanced NPC Personality System
# Includes secrets, occupational depth, and dynamic traits
# ============================================

# Complete NPC database with all enhanced features
var npc_database = {}

# Audio library for NPC sounds
var audio_library = {
	"greetings": {
		"happy": ["res://assets/audio/sfx/happy_greeting.wav"],
		"neutral": ["res://assets/audio/sfx/neutral_greeting.wav"],
		"sad": ["res://assets/audio/sfx/sad_greeting.wav"]
	},
	"emotions": {
		"laugh": ["res://assets/audio/sfx/laugh_light.wav", "res://assets/audio/sfx/laugh_hearty.wav"],
		"sigh": ["res://assets/audio/sfx/sigh_relief.wav", "res://assets/audio/sfx/sigh_disappointed.wav"],
		"surprised": ["res://assets/audio/sfx/gasp.wav", "res://assets/audio/sfx/oh.wav"],
		"thinking": ["res://assets/audio/sfx/hmm.wav", "res://assets/audio/sfx/thinking.wav"]
	},
	"activities": {
		"working": ["res://assets/audio/sfx/work_tools.wav"],
		"walking": ["res://assets/audio/sfx/footsteps_grass.wav", "res://assets/audio/sfx/footsteps_wood.wav"],
		"reading": ["res://assets/audio/sfx/page_turn.wav"],
		"farming": ["res://assets/audio/sfx/hoe_dig.wav", "res://assets/audio/sfx/watering.wav"]
	},
	"ambient": {
		"shop": ["res://assets/audio/ambience/shop_bell.wav", "res://assets/audio/ambience/shop_murmur.wav"],
		"farm": ["res://assets/audio/ambience/birds_chirp.wav"],
		"town": ["res://assets/audio/ambience/town_fountain.wav"]
	}
}

signal secret_revealed(npc_id, secret_info)
signal relationship_milestone(npc_id, level)
signal audio_played(npc_id, sound_type, sound_path)

func _ready():
	initialize_enhanced_database()

func initialize_enhanced_database():
	"""Initialize complete NPC database with all enhanced features"""
	
	# Pierre - Complete Profile
	npc_database["pierre"] = {
		"basic_info": {
			"name": "Pierre",
			"age": 42,
			"occupation": "General Store Owner",
			"work_location": "general_store",
			"home_location": "pierre_house",
			"family": ["caroline_wife", "abigail_daughter"],
			"birthday": {"season": "spring", "day": 26}
		},
		
		"personality_core": {
			"traits": {
				"friendliness": 0.9,
				"patience": 0.8,
				"generosity": 0.7,
				"energy": 0.7,
				"sensitivity": 0.4,
				"materialism": 0.6,
				"family_orientation": 0.95
			},
			"values": ["family", "hard_work", "community", "honesty", "profit"],
			"fears": ["losing_family", "business_failure", "change", "jojamart_competition"],
			"dreams": ["expand_store", "abigail_happiness", "town_prosperity"],
			"quirks": ["counts_inventory_daily", "hums_when_happy", "polishes_counter_nervously", "worries_excessively"]
		},
		
		"occupational_depth": {
			"job_description": "Runs the local general store, supplies farmers with seeds and tools",
			"work_schedule": {"open": 9.0, "close": 17.0, "closed_days": []},
			"work_topics": [
				"seed_quality", "crop_prices", "inventory_management", 
				"customer_service", "supplier_relationships", "profit_margins"
			],
			"work_behaviors": {
				"during_work": ["organizing_shelves", "checking_ledger", "greeting_customers", "arranging_displays"],
				"busy_reaction": "I'll be with you in just a moment, dear!",
				"slow_day_reaction": "Business has been quiet lately... I hope things pick up soon."
			},
			"professional_pride": "We have the finest selection of seeds in the entire valley!"
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["gold_bar", "diamond", "cooking_recipe", "rare_artifact"],
					"reaction": "Oh my! This is absolutely wonderful! Thank you so much!",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["parsnip", "green_bean", "cauliflower", "coffee"],
					"reaction": "Oh, how thoughtful! I do appreciate this.",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["wood", "stone", "fiber"],
					"reaction": "Thank you, dear.",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["monster_loot", "slime", "bug_meat"],
					"reaction": "Oh... um... thank you? I suppose...",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["trash", "broken_glasses", "driftwood"],
					"reaction": "Is this... trash? *sighs* Please don't joke around like that.",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "sunny",
				"reactions": {
					"sunny": "What a beautiful day! Perfect for business!",
					"rain": "The crops will love this rain, though foot traffic might slow down...",
					"storm": "I do hope the store roof holds up...",
					"snow": "Winter weather means fewer customers, but at least it's peaceful."
				}
			},
			
			"topics": {
				"loves": ["family", "business_success", "farming_tips", "community_events"],
				"likes": ["weather", "recipes", "town_news", "customer_stories"],
				"neutral": ["hobbies", "travel", "books"],
				"dislikes": ["competitors", "economic_downturn"],
				"hates": ["jojamart", "vandalism", "theft"]
			},
			
			"food": {
				"favorites": ["pizza", "pasta", "fresh_bread", "chocolate_cake"],
				"dislikes": ["wild_horseradish", "dandelion", "anything_spoiled"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"id": "financial_worries",
					"description": "Pierre secretly worries about money despite appearing successful",
					"reveal_condition": {"relationship_min": 6, "trigger": "evening_conversation"},
					"revealed_dialogue": "Between you and me... business hasn't been as good as I'd like. But don't tell anyone, alright?",
					"impact": "Unlocks discount opportunities and business advice"
				},
				{
					"id": "abigail_concerns",
					"description": "Deeply worried about Abigail's adventurous lifestyle",
					"reveal_condition": {"relationship_min": 8, "trigger": "mention_abigail"},
					"revealed_dialogue": "Abigail... she's so headstrong. I just worry she'll get hurt exploring those dangerous places. A father can't help but worry, you know?",
					"impact": "Unlocks family quest lines"
				}
			],
			
			"hidden_behaviors": {
				"when_alone": ["counting_money", "worrying_about_bills", "talking_to_self"],
				"stress_habits": ["excessive_cleaning", "reorganizing_same_items"],
				"comfort_activities": ["cooking_for_family", "reading_business_books"]
			}
		},
		
		"speech_patterns": {
			"style": "warm_professional",
			"characteristics": {
				"uses_dear": true,
				"exclamation_frequency": 0.4,
				"formal_level": 0.3,
				"warmth_level": 0.9,
				"business_mentions": 0.3
			},
			"catchphrases": {
				"greetings": [
					"Welcome to my store!",
					"Ah, a valued customer!",
					"Good day to you, dear!",
					"Come in, come in!"
				],
				"agreement": [
					"Absolutely!",
					"Indeed indeed!",
					"That's right!",
					"Precisely!"
				],
				"concern": [
					"Oh dear...",
					"I do hope...",
					"Let's see what we can do...",
					"My, my..."
				],
				"excitement": [
					"Wonderful!",
					"Splendid!",
					"How marvelous!",
					"Excellent!"
				],
				"farewell": [
					"Thank you for your business!",
					"Come again soon!",
					"Take care now!",
					"Have a lovely day!"
				],
				"filler_words": ["you see", "as it were", "if you will", "my dear"]
			},
			"common_phrases": [
				"Finest quality, guaranteed!",
				"We take pride in our selection.",
				"Can I interest you in...?",
				"Just arrived today!"
			]
		},
		
		"dynamic_schedule": {
			"weekday": {
				6.0: {"action": "wake_up", "location": "bedroom", "duration": 1.0, "animation": "stretching"},
				6.5: {"action": "morning_routine", "location": "bathroom", "duration": 1.0, "animation": "washing"},
				7.5: {"action": "breakfast_with_family", "location": "kitchen", "duration": 1.0, "animation": "eating", "social": ["caroline", "abigail"]},
				8.5: {"action": "prepare_store", "location": "general_store", "duration": 0.5, "animation": "unlocking_door"},
				9.0: {"action": "open_store", "location": "general_store", "duration": 8.0, "animation": "behind_counter", "state": "working"},
				12.0: {"action": "lunch_break", "location": "back_room", "duration": 1.0, "animation": "eating", "notes": "Quick lunch, checks inventory"},
				17.0: {"action": "close_store", "location": "general_store", "duration": 0.5, "animation": "locking_up"},
				17.5: {"action": "return_home", "location": "pierre_house", "duration": 0.5, "animation": "walking"},
				18.0: {"action": "family_time", "location": "living_room", "duration": 2.0, "animation": "relaxing", "social": ["caroline", "abigail"]},
				20.0: {"action": "evening_routine", "location": "kitchen", "duration": 1.5, "animation": "cleaning"},
				21.5: {"action": "review_business", "location": "office", "duration": 1.0, "animation": "reading_ledger", "mood": "contemplative"},
				22.5: {"action": "prepare_bed", "location": "bedroom", "duration": 0.5, "animation": "changing"},
				23.0: {"action": "sleep", "location": "bed", "duration": 7.0, "animation": "sleeping"}
			},
			"weekend": {
				7.0: {"action": "wake_up_late", "location": "bedroom", "duration": 1.0},
				8.0: {"action": "leisurely_breakfast", "location": "kitchen", "duration": 1.5, "social": ["caroline", "abigail"]},
				9.5: {"action": "open_store", "location": "general_store", "duration": 6.0, "animation": "behind_counter"},
				16.0: {"action": "close_early", "location": "general_store", "duration": 0.5},
				17.0: {"action": "community_time", "location": "town_square", "duration": 2.0, "animation": "socializing"},
				19.0: {"action": "family_dinner", "location": "kitchen", "duration": 1.5, "social": ["caroline", "abigail"]},
				21.0: {"action": "relax", "location": "living_room", "duration": 2.0},
				23.0: {"action": "sleep", "location": "bed", "duration": 7.0}
			},
			"rainy_day": {
				"modifications": {
					"store_hours": {"open": 10.0, "close": 16.0},
					"mood_modifier": -0.1,
					"special_behavior": "reads_business_books during slow periods"
				}
			},
			"festival_day": {
				"modifications": {
					"store_closed": true,
					"location": "festival_grounds",
					"behavior": "sets_up_booth",
					"mood_modifier": 0.3
				}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 1.0,
			"speaking_speed": 1.0,
			"volume": 1.0,
			"emotion_sounds": {
				"happy": "res://assets/audio/sfx/pierre/pierre_chuckle.wav",
				"surprised": "res://assets/audio/sfx/pierre/pierre_gasp.wav",
				"thinking": "res://assets/audio/sfx/pierre/pierre_hmm.wav",
				"sighing": "res://assets/audio/sfx/pierre/pierre_sigh.wav"
			},
			"activity_sounds": {
				"working": "res://assets/audio/sfx/pierre/register_ring.wav",
				"cleaning": "res://assets/audio/sfx/cleaning_swipe.wav",
				"walking": "res://assets/audio/sfx/footsteps_wood.wav"
			}
		}
	}
	
	# Abigail - Complete Profile
	npc_database["abigail"] = {
		"basic_info": {
			"name": "Abigail",
			"age": 19,
			"occupation": "Adventurer / Shopkeeper's Daughter",
			"work_location": "none",
			"home_location": "pierre_house",
			"family": ["pierre_father", "caroline_mother"],
			"birthday": {"season": "fall", "day": 13}
		},
		
		"personality_core": {
			"traits": {
				"adventurousness": 0.95,
				"independence": 0.9,
				"curiosity": 0.85,
				"impulsiveness": 0.7,
				"loyalty": 0.8,
				"mysteriousness": 0.75,
				"energy": 0.95,
				"patience": 0.4
			},
			"values": ["freedom", "adventure", "self_discovery", "authenticity", "excitement"],
			"fears": ["being_trapped", "boredom", "conformity", "disappointing_parents"],
			"dreams": ["become_great_adventurer", "discover_ancient_secrets", "master_swordplay", "find_true_purpose"],
			"quirks": ["eats_strange_things", "talks_to_sword", "collects_shiny_objects", "purple_hair_dye", "plays_flute"]
		},
		
		"occupational_depth": {
			"job_description": "Part-time helper at family store, full-time adventurer and explorer",
			"work_schedule": {"helps_store": "occasional_weekends", "adventure_time": "daily"},
			"adventure_topics": [
				"cave_exploration", "monster_hunting", "ancient_artifacts",
				"magic_practice", "sword_training", "mystical_experiences"
			],
			"adventure_behaviors": {
				"preparing": ["sharpening_sword", "checking_supplies", "studying_map"],
				"returning": ["examining_loot", "treating_wounds", "documenting_findings"],
				"excited_reaction": "YES! Adventure time! Let's goooo!",
				"bored_reaction": "Ugh, another boring day... I need to get out of here!"
			},
			"skills": ["swordsmanship", "magic_affinity", "monster_knowledge", "survival"]
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["amethyst", "monster_loot", "enchanted_blade", "ring_of_yoba", "void_egg"],
					"reaction": "WHOA!!! This is AMAZING!!! How did you know I wanted this?!",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["quartz", "earth_crystal", "video_game", "chocolate", "spicy_eel"],
					"reaction": "Oh cool! Thanks! This is pretty neat!",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["flowers", "fruits", "clothes"],
					"reaction": "Thanks, I guess.",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["farming_tools", "cookbook", "household_items"],
					"reaction": "Uh... what am I supposed to do with this?",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["hay", "mayonnaise", "pickles", "anything_domestic"],
					"reaction": "Eww! Gross! Why would you give me THIS?!",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "storm",
				"reactions": {
					"sunny": "Nice day, but kind of boring... nothing exciting happens on sunny days.",
					"rain": "Rain is okay. Good excuse to stay inside and play games.",
					"storm": "YES! Storm weather is PERFECT for adventure! The monsters are more active!",
					"snow": "Snow is pretty! Makes everything look magical."
				}
			},
			
			"topics": {
				"loves": ["adventure", "monsters", "magic", "video_games", "mysteries", "the_occult"],
				"likes": ["music", "exploring", "gems", "fantasy_stories"],
				"neutral": ["school", "movies", "animals"],
				"dislikes": ["chores", "farming_details", "small_talk"],
				"hates": ["being_treated_like_child", "marriage_pressure", "boring_routines"]
			},
			
			"food": {
				"favorites": ["chocolate_cake", "pumpkin_soup", "eggplant_parmesan", "spicy_food"],
				"dislikes": ["salad", "plain_vegetables", "bland_food"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"id": "eats_minerals",
					"description": "Secretly eats gems and minerals, believes they give her power",
					"reveal_condition": {"relationship_min": 4, "trigger": "give_gem_gift"},
					"revealed_dialogue": "Okay, don't laugh... but sometimes I eat rocks. Amethyst especially. I know it sounds weird, but they make me feel stronger! Don't tell my parents, okay?",
					"impact": "Unlocks unique dialogue about mystical experiences"
				},
				{
					"id": "magical_abilities",
					"description": "Has latent magical abilities she's trying to develop",
					"reveal_condition": {"relationship_min": 7, "trigger": "cave_conversation"},
					"revealed_dialogue": "Sometimes... when I'm in the caves... I can feel something. Like energy flowing through me. I think I might have magic in me. Crazy, right?",
					"impact": "Unlocks magic-related quests and abilities"
				},
				{
					"id": "parental_pressure",
					"description": "Feels trapped between adventure dreams and parental expectations",
					"reveal_condition": {"relationship_min": 9, "trigger": "deep_night_conversation"},
					"revealed_dialogue": "I love my parents, really. But dad wants me to work at the store, and mom wants me to be more... normal. I just want to explore and find my own path, you know?",
					"impact": "Unlocks family reconciliation quest line"
				}
			],
			
			"hidden_behaviors": {
				"when_alone": ["practicing_sword_moves", "talking_to_amethyst", "writing_adventure_journal"],
				"stress_habits": ["playing_flute_badly", "pacing_restlessly"],
				"comfort_activities": ["gaming", "polishing_sword", "stargazing"]
			}
		},
		
		"speech_patterns": {
			"style": "energetic_casual",
			"characteristics": {
				"uses_slang": true,
				"exclamation_frequency": 0.7,
				"energy_level": 0.95,
				"formal_level": 0.05,
				"sentence_length": "short_to_medium"
			},
			"catchphrases": {
				"greetings": [
					"Hey!",
					"Yo!",
					"What's up, adventurer?",
					"Hey there!"
				],
				"agreement": [
					"Heck yeah!",
					"Totally!",
					"For sure!",
					"Absolutely!"
				],
				"excitement": [
					"AWESOME!!!",
					"SO COOL!",
					"Let's goooo!",
					"This is AMAZING!!!"
				],
				"frustration": [
					"Ugh!",
					"Not again!",
					"So annoying!",
					"Whatever!"
				],
				"farewell": [
					"See ya!",
					"Later!",
					"Keep adventuring!",
					"Stay awesome!"
				],
				"filler_words": ["like", "totally", "you know", "I mean"]
			},
			"common_phrases": [
				"Wanna go explore?",
				"The caves are calling!",
				"I'm not like other girls.",
				"Adventure awaits!"
			]
		},
		
		"dynamic_schedule": {
			"weekday": {
				9.0: {"action": "wake_up", "location": "bedroom", "duration": 1.0, "animation": "stretching"},
				10.0: {"action": "morning_routine", "location": "bathroom", "duration": 1.0},
				11.0: {"action": "help_at_store", "location": "general_store", "duration": 3.0, "animation": "stocking_shelves", "mood": "bored", "notes": "Reluctantly helps father"},
				14.0: {"action": "adventure_prep", "location": "bedroom", "duration": 1.0, "animation": "equipping_gear"},
				15.0: {"action": "explore_mountains", "location": "mountain_area", "duration": 4.0, "animation": "exploring", "state": "adventuring"},
				19.0: {"action": "return_home", "location": "pierre_house", "duration": 0.5},
				19.5: {"action": "dinner_with_family", "location": "kitchen", "duration": 1.0, "social": ["pierre", "caroline"]},
				21.0: {"action": "gaming_or_reading", "location": "bedroom", "duration": 2.0, "animation": "gaming"},
				23.0: {"action": "sleep", "location": "bed", "duration": 10.0}
			},
			"adventure_day": {
				8.0: {"action": "early_wake", "location": "bedroom", "duration": 0.5},
				9.0: {"action": "head_to_caves", "location": "mines_entrance", "duration": 8.0, "animation": "fighting_monsters", "state": "adventuring"},
				17.0: {"action": "return_exhausted", "location": "home", "duration": 1.0},
				18.0: {"action": "rest_and_recovery", "location": "bedroom", "duration": 2.0},
				20.0: {"action": "document_adventure", "location": "desk", "duration": 1.0, "animation": "writing"},
				23.0: {"action": "sleep", "location": "bed", "duration": 9.0}
			},
			"rainy_day": {
				"modifications": {
					"stay_indoors": true,
					"activities": ["gaming", "reading", "practicing_flute"],
					"mood_modifier": -0.2,
					"special_behavior": "complains_about_boredom"
				}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 1.2,
			"speaking_speed": 1.3,
			"volume": 1.2,
			"emotion_sounds": {
				"excited": "res://assets/audio/sfx/abigail/abigail_cheer.wav",
				"laughing": "res://assets/audio/sfx/abigail/abigail_laugh.wav",
				"frustrated": "res://assets/audio/sfx/abigail/abigail_ugh.wav",
				"determined": "res://assets/audio/sfx/abigail/abigail_hmph.wav"
			},
			"activity_sounds": {
				"sword_practice": "res://assets/audio/sfx/sword_swing.wav",
				"gaming": "res://assets/audio/sfx/game_beeps.wav",
				"flute": "res://assets/audio/sfx/flute_notes.wav"
			}
		}
	}
	
	# Mayor Lewis - Complete Profile
	npc_database["lewis"] = {
		"basic_info": {
			"name": "Lewis",
			"age": 55,
			"occupation": "Town Mayor",
			"work_location": "mayor_manor",
			"home_location": "mayor_manor",
			"family": [],
			"secret_relationship": "marnie",
			"birthday": {"season": "spring", "day": 7}
		},
		
		"personality_core": {
			"traits": {
				"responsibility": 0.95,
				"diplomacy": 0.9,
				"patience": 0.85,
				"pride": 0.7,
				"cautiousness": 0.8,
				"community_focus": 0.95,
				"secretiveness": 0.6
			},
			"values": ["order", "tradition", "community_welfare", "reputation", "harmony"],
			"fears": ["scandal", "losing_respect", "town_decline", "marnie_secret_exposed"],
			"dreams": ["perfect_festival", "town_prosperity", "peaceful_retirement", "legacy"],
			"quirks": ["adjusts_hat_nervously", "clears_throat_before_speeches", "obsessive_about_schedules", "hides_personal_life"]
		},
		
		"occupational_depth": {
			"job_description": "Manages town affairs, organizes festivals, maintains community harmony",
			"work_schedule": {"hours": "flexible_but_always_on_call", "responsibilities": ["festivals", "disputes", "inspections", "paperwork"]},
			"mayoral_topics": [
				"town_development", "festival_planning", "community_relations",
				"local_agriculture", "infrastructure", "traditions"
			],
			"mayoral_behaviors": {
				"during_duty": ["inspecting_town", "reviewing_documents", "meeting_citizens", "planning_events"],
				"official_speech": "As mayor, I must ensure Pelican Town remains the wonderful community it is.",
				"private_moment": "*sighs* So much responsibility..."
			},
			"achievements": ["organized_festivals_for_20_years", "maintained_town_peace", "supported_local_farmers"]
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["ancient_artifact", "book", "wine", "autumn_bounty"],
					"reaction": "My, what a distinguished gift! You have excellent taste.",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["vegetables", "flowers", "tea", "goat_cheese"],
					"reaction": "How thoughtful. I do appreciate this.",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["ores", "gems", "crafting_materials"],
					"reaction": "Thank you.",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["trash", "junk", "monster_parts"],
					"reaction": "I... see. Well. Thank you, I suppose.",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["slime", "bug_meat", "anything_inappropriate"],
					"reaction": "*clears throat* I must say, this is quite inappropriate.",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "sunny",
				"reactions": {
					"sunny": "Perfect weather for town inspections.",
					"rain": "I do hope everyone is staying dry and safe.",
					"storm": "This weather is concerning. I should check on the townsfolk.",
					"snow": "Winter brings its own challenges to the town."
				}
			},
			
			"topics": {
				"loves": ["festivals", "community_events", "town_history", "agriculture", "traditions"],
				"likes": ["gardening", "local_news", "civic_improvement"],
				"neutral": ["weather", "sports", "hobbies"],
				"dislikes": ["gossip", "complaints", "radical_change"],
				"hates": ["scandals", "marnie_secret", "jojamart_expansion", "disorder"]
			},
			
			"food": {
				"favorites": ["vegetable_stew", "soup", "roasted_mushrooms", "fine_wine"],
				"dislikes": ["fast_food", "candy", "unrefined_meals"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"id": "marnie_relationship",
					"description": "Secret romantic relationship with Marnie, keeps it hidden to maintain dignity",
					"reveal_condition": {"relationship_min": 8, "trigger": "evening_at_marnies"},
					"revealed_dialogue": "Marnie and I... we've been close for many years. But please, keep this between us. As mayor, I must maintain a certain image, you understand.",
					"impact": "Unlocks special events with Marnie and Lewis together"
				},
				{
					"id": "mayoral_pressures",
					"description": "Struggles with the weight of responsibility and maintaining town's reputation",
					"reveal_condition": {"relationship_min": 7, "trigger": "late_night_conversation"},
					"revealed_dialogue": "Being mayor isn't easy. Every decision affects the whole town. Sometimes I wonder if I'm doing enough... but I must carry on, for everyone's sake.",
					"impact": "Unlocks mayor assistance quests"
				}
			],
			
			"hidden_behaviors": {
				"when_alone": ["reviewing_town_budget", "practicing_speeches", "tending_private_garden"],
				"stress_habits": ["adjusting_hat_repeatedly", "pacing_while_muttering"],
				"comfort_activities": ["visiting_marnie_secretly", "working_in_garden", "reading_history_books"]
			}
		},
		
		"speech_patterns": {
			"style": "formal_diplomatic",
			"characteristics": {
				"uses_formal_language": true,
				"formal_level": 0.85,
				"uses_titles": true,
				"diplomatic_level": 0.9,
				"sentence_complexity": "high"
			},
			"catchphrases": {
				"greetings": [
					"Good day to you.",
					"Greetings, citizen.",
					"Welcome to Pelican Town.",
					"A pleasure to see you."
				],
				"agreement": [
					"Quite so.",
					"Indeed.",
					"A sound proposition.",
					"I concur."
				],
				"concern": [
					"This is troubling...",
					"We must address this...",
					"Hmm, a matter of concern...",
					"I must give this thought..."
				],
				"authority": [
					"As mayor...",
					"For the good of the town...",
					"I must insist...",
					"It is my duty to..."
				],
				"farewell": [
					"Farewell, citizen.",
					"Until next time.",
					"Have a pleasant day.",
					"Take care."
				],
				"filler_words": ["you understand", "if you will", "as it were", "needless to say"]
			},
			"common_phrases": [
				"For the community's benefit.",
				"We must maintain order.",
				"Pelican Town has a proud tradition.",
				"As your mayor, I assure you..."
			]
		},
		
		"dynamic_schedule": {
			"weekday": {
				7.0: {"action": "wake_up", "location": "bedroom", "duration": 1.0},
				8.0: {"action": "morning_routine", "location": "bathroom", "duration": 1.0},
				9.0: {"action": "breakfast", "location": "kitchen", "duration": 1.0},
				10.0: {"action": "town_inspection", "location": "town_square", "duration": 2.0, "animation": "walking_inspecting"},
				12.0: {"action": "office_work", "location": "mayor_office", "duration": 2.0, "animation": "desk_work"},
				14.0: {"action": "meet_citizens", "location": "various", "duration": 2.0, "animation": "conversing"},
				16.0: {"action": "garden_work", "location": "backyard", "duration": 1.5, "animation": "gardening"},
				17.5: {"action": "return_inside", "location": "living_room", "duration": 0.5},
				18.0: {"action": "dinner", "location": "dining_room", "duration": 1.0},
				19.0: {"action": "paperwork", "location": "office", "duration": 2.0, "animation": "reading"},
				21.0: {"action": "relax", "location": "living_room", "duration": 1.5},
				22.5: {"action": "prepare_bed", "location": "bedroom", "duration": 0.5},
				23.0: {"action": "sleep", "location": "bed", "duration": 8.0}
			},
			"friday": {
				"modifications": {
					"evening_activity": "visit_marnie_secretly",
					"location": "marnie_ranch",
					"time": 20.0,
					"secret": true
				}
			},
			"festival_day": {
				"modifications": {
					"all_day": "manage_festival",
					"location": "festival_grounds",
					"mood_modifier": 0.2,
					"behavior": "directing_events"
				}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 0.9,
			"speaking_speed": 0.9,
			"volume": 1.0,
			"emotion_sounds": {
				"pleased": "res://assets/audio/sfx/lewis/lewis_chuckle.wav",
				"concerned": "res://assets/audio/sfx/lewis/lewis_hmm.wav",
				"authoritative": "res://assets/audio/sfx/lewis/lewis_clears_throat.wav",
				"sighing": "res://assets/audio/sfx/lewis/lewis_sigh.wav"
			},
			"activity_sounds": {
				"paperwork": "res://assets/audio/sfx/paper_rustle.wav",
				"gardening": "res://assets/audio/sfx/garden_tools.wav",
				"walking": "res://assets/audio/sfx/footsteps_formal.wav"
			}
		}
	}
	
	# ============================================
	# NEW DIVERSE NPC ARCHETYPES
	# ============================================
	
	# INTELLECTUALS/SCIENTISTS
	
	# Dr. Elias Thornwood - The Eccentric Scientist (Einstein-inspired)
	npc_database["elias"] = {
		"basic_info": {
			"name": "Dr. Elias Thornwood",
			"age": 67,
			"occupation": "Research Scientist & Inventor",
			"work_location": "research_lab",
			"home_location": "thornwood_cottage",
			"family": [],
			"birthday": {"season": "winter", "day": 14}
		},
		
		"personality_core": {
			"traits": {
				"friendliness": 0.5,
				"patience": 0.3,
				"generosity": 0.8,
				"energy": 0.9,
				"sensitivity": 0.2,
				"curiosity": 1.0,
				"eccentricity": 0.95
			},
			"values": ["knowledge", "discovery", "innovation", "truth", "intellectual_freedom"],
			"fears": ["ignorance", "stagnation", "losing_curiosity", "bureaucracy"],
			"dreams": ["unified_theory", "revolutionary_invention", "mentor_young_scientists"],
			"quirks": ["talks_to_self", "forgets_meals", "hair_always_messy", "wears_mismatched_socks", "carries_notebook_everywhere"]
		},
		
		"occupational_depth": {
			"job_description": "Conducts experiments and develops inventions in private laboratory",
			"work_schedule": {"open": 0.0, "close": 24.0, "closed_days": []},
			"work_topics": [
				"quantum_physics", "invention_prototypes", "scientific_method",
				"astronomy", "theoretical_mathematics", "experimental_results"
			],
			"work_behaviors": {
				"during_work": ["scribbling_formulas", "mixing_chemicals", "adjusting_telescopes", "muttering_calculations"],
				"busy_reaction": "Fascinating! The data is absolutely fascinating!",
				"slow_day_reaction": "Perhaps I should recalibrate the instruments... again."
			},
			"professional_pride": "My latest invention will revolutionize how we understand energy!"
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["rare_mineral", "ancient_book", "telescope_lens", "copper_wire"],
					"reaction": "Incredible! Do you realize the implications of this?!",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["coffee", "battery", "gear", "book_science"],
					"reaction": "Ah, useful materials! Thank you!",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["wood", "stone"],
					"reaction": "Hmm? Oh, thank you.",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["flowers", "perfume", "jewelry"],
					"reaction": "I... don't know what to do with this.",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["trash", "broken_cd"],
					"reaction": "This is scientifically worthless!",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "storm",
				"reactions": {
					"sunny": "Clear skies are good for stargazing later, I suppose.",
					"rain": "The humidity affects my equipment... but the sound is rather peaceful.",
					"storm": "Magnificent! The electrical activity is extraordinary!",
					"snow": "Snow dampens sound... excellent for concentration."
				}
			},
			
			"topics": {
				"loves": ["physics", "inventions", "space", "mathematics", "experiments"],
				"likes": ["technology", "books", "puzzles", "history_of_science"],
				"neutral": ["weather", "food", "town_news"],
				"dislikes": ["gossip", "sports", "fashion"],
				"hates": ["anti_science", "superstition", "small_talk"]
			},
			
			"food": {
				"favorites": ["black_coffee", "simple_sandwich", "anything_quick"],
				"dislikes": ["fancy_dishes", "spicy_food", "anything_requiring_utensils"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"text": "I once won a Nobel Prize but gave it back because they wouldn't let me explain my theory for 3 hours straight.",
					"reveal_condition": {"relationship_min": 7}
				},
				{
					"text": "I talk to my plants. They're my control group for studying the effects of conversation on growth rates.",
					"reveal_condition": {"relationship_min": 5}
				}
			],
			"special_reactions": {
				"loves_it": "Eureka! This is exactly what I needed!",
				"likes_it": "Interesting... very interesting...",
				"dislikes_it": "Hmm, not quite what I was looking for.",
				"hates_it": "Illogical! Completely illogical!"
			}
		},
		
		"speech_patterns": {
			"style": "academic_scattered",
			"catchphrases": {
				"greetings": [
					"Ah! Hello! I was just contemplating the nature of— oh, never mind.",
					"Fascinating day for discovery, isn't it?",
					"*looks up from notebook* Hmm? Oh, greetings!"
				],
				"agreement": [
					"Precisely! Your logic is sound!",
					"The data supports that conclusion!",
					"Q.E.D., as they say!"
				],
				"excitement": [
					"EUREKA! I've got it! Well, almost...",
					"The implications are staggering!",
					"This changes everything!"
				],
				"concern": [
					"The variables don't add up...",
					"There's an anomaly in the results...",
					"I need more data..."
				],
				"filler": [
					"Hmm, fascinating...",
					"Let me calculate...",
					"Theoretically speaking...",
					"*scribbles notes*"
				]
			},
			"verbal_tics": ["actually", "theoretically", "fascinating", "the data shows", "hypothesis"],
			"speech_tempo": "fast_with_pauses",
			"vocabulary_level": "advanced"
		},
		
		"dynamic_schedule": {
			"weekday": {
				"6:00": {"action": "waking_up", "location": "thornwood_cottage", "duration": 1.0},
				"7:00": {"action": "morning_coffee_and_notes", "location": "thornwood_cottage", "duration": 1.5},
				"9:00": {"action": "laboratory_research", "location": "research_lab", "duration": 4.0},
				"13:00": {"action": "quick_lunch_at_desk", "location": "research_lab", "duration": 0.5},
				"14:00": {"action": "experiments", "location": "research_lab", "duration": 4.0},
				"18:00": {"action": "evening_walk_clear_head", "location": "forest", "duration": 1.5},
				"20:00": {"action": "stargazing", "location": "mountains", "duration": 2.0},
				"22:00": {"action": "return_home_read", "location": "thornwood_cottage", "duration": 2.0},
				"0:00": {"action": "sleeping", "location": "thornwood_cottage", "duration": 6.0}
			},
			"weekend": {
				"8:00": {"action": "late_wake_reading", "location": "thornwood_cottage", "duration": 2.0},
				"10:00": {"action": "library_research", "location": "bookstore", "duration": 3.0},
				"14:00": {"action": "nature_observation", "location": "forest", "duration": 3.0},
				"18:00": {"action": "dinner_simple", "location": "thornwood_cottage", "duration": 1.0},
				"20:00": {"action": "writing_papers", "location": "thornwood_cottage", "duration": 3.0},
				"23:00": {"action": "sleeping", "location": "thornwood_cottage", "duration": 7.0}
			},
			"rainy": {
				"9:00": {"action": "indoor_experiments", "location": "research_lab", "duration": 8.0},
				"18:00": {"action": "reading_by_fire", "location": "thornwood_cottage", "duration": 4.0},
				"22:00": {"action": "sleeping", "location": "thornwood_cottage", "duration": 8.0}
			},
			"festival": {
				"10:00": {"action": "reluctant_attendance", "location": "town_square", "duration": 2.0},
				"12:00": {"action": "observing_crowd_behavior", "location": "town_square", "duration": 2.0},
				"15:00": {"action": "early_departure_to_lab", "location": "research_lab", "duration": 5.0}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 1.1,
			"speaking_speed": 1.3,
			"volume": 0.9,
			"emotion_sounds": {
				"excited": "res://assets/audio/sfx/elias/elias_eureka.wav",
				"thinking": "res://assets/audio/sfx/elias/elias_hmm.wav",
				"frustrated": "res://assets/audio/sfx/elias/elias_ugh.wav",
				"laughing": "res://assets/audio/sfx/elias/elias_chuckle.wav"
			},
			"activity_sounds": {
				"writing": "res://assets/audio/sfx/pencil_scratch.wav",
				"experiment": "res://assets/audio/sfx/bubbles_bubbling.wav",
				"walking": "res://assets/audio/sfx/footsteps_quick.wav"
			}
		}
	}
	
	# Isabella Nightingale - Horror Novelist (Stephen King-inspired)
	npc_database["isabella"] = {
		"basic_info": {
			"name": "Isabella Nightingale",
			"age": 45,
			"occupation": "Horror/Mystery Novelist",
			"work_location": "nightingale_manor_study",
			"home_location": "nightingale_manor",
			"family": ["ghost_cat_whiskers"],
			"birthday": {"season": "fall", "day": 31}
		},
		
		"personality_core": {
			"traits": {
				"friendliness": 0.6,
				"patience": 0.7,
				"generosity": 0.5,
				"energy": 0.4,
				"sensitivity": 0.8,
				"creativity": 1.0,
				"mysteriousness": 0.9
			},
			"values": ["storytelling", "darkness_in_human_nature", "solitude", "authenticity", "craft"],
			"fears": ["writers_block", "irrelevance", "bright_fluorescent_lights", "happy_endings"],
			"dreams": ["write_masterpiece", "haunt_readers_minds", "find_perfect_plot_twist"],
			"quirks": ["names_typewriter", "collects_obituaries", "talks_to_cat_like_person", "writes_only_at_night", "superstitious_about_number_13"]
		},
		
		"occupational_depth": {
			"job_description": "Writes bestselling horror and mystery novels from secluded manor",
			"work_schedule": {"open": 20.0, "close": 4.0, "closed_days": []},
			"work_topics": [
				"plot_structure", "character_development", "horror_tropes",
				"psychological_thriller", "supernatural_elements", "reader_psychology"
			],
			"work_behaviors": {
				"during_work": ["typing_furiously", "pacing_room", "staring_into_void", "whispering_dialogue"],
				"busy_reaction": "I'm in the middle of a scene... the shadows won't write themselves.",
				"slow_day_reaction": "The muse is silent today. Perhaps something dreadful is brewing..."
			},
			"professional_pride": "My readers sleep with the lights on. That's the highest compliment."
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["antique_pen", "leather_journal", "black_roses", "typewriter_ribbon"],
					"reaction": "How delightfully macabre... I love it.",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["coffee_dark_roast", "chocolate", "old_books", "candles"],
					"reaction": "These will fuel my writing. Thank you.",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["paper", "ink"],
					"reaction": "Practical. I appreciate practicality.",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["sunflowers", "bright_colors", "party_supplies"],
					"reaction": "Too... cheerful. It hurts my eyes.",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["self_help_books", "motivational_posters"],
					"reaction": "Positivity is the death of good horror.",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "storm",
				"reactions": {
					"sunny": "Bright days drain my creative energy... but tourists buy more books.",
					"rain": "Perfect writing weather. The rain whispers plot ideas.",
					"storm": "Magnificent! Thunder is nature's horror soundtrack!",
					"snow": "Silent snow... like a blank page waiting for terror."
				}
			},
			
			"topics": {
				"loves": ["horror_stories", "mystery_plots", "psychology", "supernatural", "dark_humor"],
				"likes": ["literature", "writing_craft", "strange_occurrences", "folklore"],
				"neutral": ["weather", "cats", "coffee"],
				"dislikes": ["romance_novels", "celebrity_gossip", "reality_tv"],
				"hates": ["censorship", "plot_holes", "deus_ex_machina"]
			},
			
			"food": {
				"favorites": ["black_coffee", "dark_chocolate", "red_wine", "anything_gothic_presented"],
				"dislikes": ["bright_colored_foods", "bubblegum", "anything_cute"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"text": "Sometimes I wonder if the stories write themselves... and I'm just the vessel.",
					"reveal_condition": {"relationship_min": 6}
				},
				{
					"text": "My cat Whiskers gives me better plot advice than my editor.",
					"reveal_condition": {"relationship_min": 4}
				},
				{
					"text": "I based my most terrifying villain on someone who lives in this town. They'll never know.",
					"reveal_condition": {"relationship_min": 8}
				}
			],
			"special_reactions": {
				"loves_it": "Deliciously dark... perfect for my collection.",
				"likes_it": "This will do nicely. Very well.",
				"dislikes_it": "Not my aesthetic, I'm afraid.",
				"hates_it": "Remove it from my sight before it infects my creativity."
			}
		},
		
		"speech_patterns": {
			"style": "gothic_dramatic",
			"catchphrases": {
				"greetings": [
					"Ah, a visitor... how delightfully unexpected.",
					"The shadows told me you might come.",
					"Welcome to my humble abode... mind the creaky floorboards."
				],
				"agreement": [
					"Indeed... the darkness agrees.",
					"A plot twist worthy of note.",
					"You have a storyteller's intuition."
				],
				"excitement": [
					"What a deliciously twisted idea!",
					"The narrative possibilities are endless!",
					"My typewriter hungers for this tale!"
				],
				"concern": [
					"The omens are troubling...",
					"I sense a disturbance in the narrative...",
					"Something lurks beneath the surface..."
				],
				"filler": [
					"In the words of my protagonist...",
					"Picture this, if you dare...",
					"The darkness whispers...",
					"*strokes cat thoughtfully*"
				]
			},
			"verbal_tics": ["darling", "macabre", "sinister", "the shadows", "narrative"],
			"speech_tempo": "slow_deliberate",
			"vocabulary_level": "literary"
		},
		
		"dynamic_schedule": {
			"weekday": {
				"10:00": {"action": "waking_up_late", "location": "nightingale_manor", "duration": 1.5},
				"12:00": {"action": "feeding_cat_breakfast", "location": "nightingale_manor", "duration": 0.5},
				"14:00": {"action": "afternoon_reading_research", "location": "bookstore", "duration": 3.0},
				"17:00": {"action": "cafe_visit_people_watch", "location": "cafe", "duration": 2.0},
				"19:00": {"action": "return_home_prepare_write", "location": "nightingale_manor", "duration": 1.0},
				"20:00": {"action": "writing_session", "location": "nightingale_manor_study", "duration": 6.0},
				"2:00": {"action": "midnight_snack", "location": "nightingale_manor", "duration": 0.5},
				"3:00": {"action": "sleeping", "location": "nightingale_manor", "duration": 7.0}
			},
			"weekend": {
				"12:00": {"action": "late_wake", "location": "nightingale_manor", "duration": 2.0},
				"14:00": {"action": "cemetery_inspiration_walk", "location": "forest", "duration": 2.0},
				"17:00": {"action": "tea_and_outlining", "location": "cafe", "duration": 2.0},
				"20:00": {"action": "intensive_writing", "location": "nightingale_manor_study", "duration": 7.0},
				"3:00": {"action": "sleeping", "location": "nightingale_manor", "duration": 9.0}
			},
			"rainy": {
				"12:00": {"action": "waking", "location": "nightingale_manor", "duration": 1.0},
				"14:00": {"action": "writing_marathon", "location": "nightingale_manor_study", "duration": 10.0},
				"0:00": {"action": "sleeping_exhausted", "location": "nightingale_manor", "duration": 10.0}
			},
			"festival": {
				"14:00": {"action": "observing_from_shadows", "location": "town_square", "duration": 2.0},
				"16:00": {"action": "taking_mental_notes_for_story", "location": "town_square", "duration": 2.0},
				"18:00": {"action": "retreat_to_manor", "location": "nightingale_manor", "duration": 6.0}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 0.85,
			"speaking_speed": 0.8,
			"volume": 0.8,
			"emotion_sounds": {
				"intrigued": "res://assets/audio/sfx/isabella/isabella_intrigued.wav",
				"creepy_laugh": "res://assets/audio/sfx/isabella/isabella_chuckle.wav",
				"dramatic_gasps": "res://assets/audio/sfx/isabella/isabella_gasp.wav",
				"contemplative": "res://assets/audio/sfx/isabella/isabella_hmm.wav"
			},
			"activity_sounds": {
				"typing": "res://assets/audio/sfx/typewriter_clack.wav",
				"page_turn": "res://assets/audio/sfx/book_pages.wav",
				"cat_purring": "res://assets/audio/sfx/cat_purr.wav"
			}
		}
	}
	
	# Marcus Chen - Street Musician/Wandering Bard
	npc_database["marcus"] = {
		"basic_info": {
			"name": "Marcus Chen",
			"age": 28,
			"occupation": "Street Performer & Wandering Musician",
			"work_location": "town_square_stage",
			"home_location": "travelers_hostel",
			"family": [],
			"birthday": {"season": "summer", "day": 21}
		},
		
		"personality_core": {
			"traits": {
				"friendliness": 0.95,
				"patience": 0.8,
				"generosity": 0.9,
				"energy": 0.9,
				"sensitivity": 0.7,
				"artistry": 1.0,
				"wanderlust": 0.95
			},
			"values": ["music", "freedom", "connection", "beauty", "spontaneity", "cultural_exchange"],
			"fears": ["silence", "being_forgotten", "losing_creativity", "settling_down"],
			"dreams": ["compose_masterpiece", "tour_world", "touch_souls_through_music"],
			"quirks": ["names_instruments", "humms_constant", "collects_song_stories", "sleeps_under_stars", "philosophical_about_rhythm"]
		},
		
		"occupational_depth": {
			"job_description": "Performs music in public spaces, travels between towns sharing songs",
			"work_schedule": {"open": 10.0, "close": 22.0, "closed_days": []},
			"work_topics": [
				"music_theory", "song_composition", "instrument_care",
				"travel_stories", "cultural_music", "audience_connection"
			],
			"work_behaviors": {
				"during_work": ["strumming_guitar", "tuning_violin", "improvising_melodies", "teaching_passersby"],
				"busy_reaction": "Just a moment! This melody won't wait!",
				"slow_day_reaction": "The music flows whether people listen or not... but tips help."
			},
			"professional_pride": "I've made strangers cry with a single chord progression. That's power."
		},
		
		"preferences": {
			"gifts": {
				"loved": {
					"items": ["guitar_strings", "sheet_music_rare", "handcrafted_pick", "vinyl_record"],
					"reaction": "Beautiful! This will sing wonderfully!",
					"relationship_gain": 80
				},
				"liked": {
					"items": ["coffee", "sandwich", "notebook", "headphones"],
					"reaction": "Thanks, friend! Much appreciated!",
					"relationship_gain": 45
				},
				"neutral": {
					"items": ["water", "snacks"],
					"reaction": "Cool, thanks!",
					"relationship_gain": 20
				},
				"disliked": {
					"items": ["earplugs", "noise_canceling_devices"],
					"reaction": "Ha ha... very funny. Not.",
					"relationship_gain": -20
				},
				"hated": {
					"items": ["broken_instrument", "tone_deaf_recording"],
					"reaction": "That's... actually painful to witness.",
					"relationship_gain": -50
				}
			},
			
			"weather": {
				"favorite": "sunny",
				"reactions": {
					"sunny": "Perfect day for outdoor concerts!",
					"rain": "Rain makes the best percussion, don't you think?",
					"storm": "Nature's symphony! Listen to that thunder!",
					"snow": "Snow muffles sound... intimate performances today."
				}
			},
			
			"topics": {
				"loves": ["music", "travel", "instruments", "concerts", "songwriting"],
				"likes": ["culture", "philosophy", "food_variety", "meeting_people"],
				"neutral": ["weather", "local_news"],
				"dislikes": ["politics", "routine", "corporate_music"],
				"hates": ["censorship", "musical_pretension", "pay_to_play"]
			},
			
			"food": {
				"favorites": ["street_food", "international_cuisine", "anything_portable", "spicy_tacos"],
				"dislikes": ["expensive_restaurants", "formal_dining", "bland_food"]
			}
		},
		
		"secrets_and_quirks": {
			"secrets": [
				{
					"text": "I was classically trained at a prestigious conservatory. I left because perfection killed the soul of music.",
					"reveal_condition": {"relationship_min": 6}
				},
				{
					"text": "Every town I visit, I leave a song behind. There are 47 'Marcus songs' being sung worldwide right now.",
					"reveal_condition": {"relationship_min": 7}
				}
			],
			"special_reactions": {
				"loves_it": "This sings to my soul, friend!",
				"likes_it": "Groovy! Thanks a ton!",
				"dislikes_it": "Not really my vibe, but hey...",
				"hates_it": "Some things just shouldn't exist, you know?"
			}
		},
		
		"speech_patterns": {
			"style": "casual_musical",
			"catchphrases": {
				"greetings": [
					"Hey there! Ready for some music?",
					"The rhythm brought you here, didn't it?",
					"*strums guitar* Welcome welcome!"
				],
				"agreement": [
					"Right on! That resonates!",
					"In perfect harmony!",
					"You feel the beat too!"
				],
				"excitement": [
					"That's FIRE! Absolutely fire!",
					"My strings are vibrating with excitement!",
					"Cue the crescendo!"
				],
				"concern": [
					"The rhythm feels off...",
					"Something's out of tune...",
					"I hear dissonance..."
				],
				"filler": [
					"*humming*",
					"You feel me?",
					"Like a song says...",
					"*taps rhythm on table*"
				]
			},
			"verbal_tics": ["man", "vibe", "rhythm", "groove", "feel"],
			"speech_tempo": "varied_musical",
			"vocabulary_level": "casual_poetic"
		},
		
		"dynamic_schedule": {
			"weekday": {
				"8:00": {"action": "waking_hostel", "location": "travelers_hostel", "duration": 1.0},
				"9:00": {"action": "morning_practice", "location": "park", "duration": 2.0},
				"11:00": {"action": "street_performance_setup", "location": "town_square_stage", "duration": 1.0},
				"12:00": {"action": "midday_performance", "location": "town_square_stage", "duration": 3.0},
				"15:00": {"action": "break_lunch", "location": "cafe", "duration": 1.5},
				"17:00": {"action": "afternoon_performance", "location": "town_square_stage", "duration": 3.0},
				"20:00": {"action": "jam_session_locals", "location": "arcade", "duration": 2.0},
				"22:00": {"action": "return_hostel", "location": "travelers_hostel", "duration": 1.0},
				"23:00": {"action": "sleeping", "location": "travelers_hostel", "duration": 9.0}
			},
			"weekend": {
				"10:00": {"action": "late_wake", "location": "travelers_hostel", "duration": 1.5},
				"12:00": {"action": "open_mic_hosting", "location": "cafe", "duration": 3.0},
				"16:00": {"action": "teaching_music_kids", "location": "park", "duration": 2.0},
				"19:00": {"action": "evening_concert", "location": "town_square_stage", "duration": 3.0},
				"22:00": {"action": "bonfire_songs", "location": "beach", "duration": 2.0},
				"0:00": {"action": "sleeping", "location": "travelers_hostel", "duration": 8.0}
			},
			"rainy": {
				"10:00": {"action": "indoor_practice", "location": "travelers_hostel", "duration": 3.0},
				"14:00": {"action": "writing_new_songs", "location": "cafe", "duration": 3.0},
				"18:00": {"action": "impromptu_rain_concert", "location": "town_square_stage", "duration": 2.0},
				"21:00": {"action": "sleeping", "location": "travelers_hostel", "duration": 9.0}
			},
			"festival": {
				"10:00": {"action": "festival_performance", "location": "town_square_stage", "duration": 8.0},
				"18:00": {"action": "collaborative_jam", "location": "town_square_stage", "duration": 3.0},
				"22:00": {"action": "closing_ceremony_music", "location": "town_square_stage", "duration": 1.0}
			}
		},
		
		"audio_profile": {
			"voice_pitch": 1.0,
			"speaking_speed": 1.1,
			"volume": 1.0,
			"emotion_sounds": {
				"excited": "res://assets/audio/sfx/marcus/marcus_yes.wav",
				"humming": "res://assets/audio/sfx/marcus/marcus_hum.wav",
				"laughing": "res://assets/audio/sfx/marcus/marcus_laugh.wav",
				"thinking": "res://assets/audio/sfx/marcus/marcus_hmm.wav"
			},
			"activity_sounds": {
				"guitar_strum": "res://assets/audio/sfx/guitar_strum.wav",
				"violin_play": "res://assets/audio/sfx/violin_melody.wav",
				"footsteps_casual": "res://assets/audio/sfx/footsteps_casual.wav"
			}
		}
	}

# ============================================
# API Functions
# ============================================

func get_npc_complete_profile(npc_id: String) -> Dictionary:
	"""Get complete NPC profile with all details"""
	return npc_database.get(npc_id, {})

func get_npc_preferences(npc_id: String, category: String) -> Dictionary:
	"""Get specific preference category"""
	var profile = get_npc_complete_profile(npc_id)
	return profile.get("preferences", {}).get(category, {})

func get_npc_secrets(npc_id: String, relationship_level: int = 0) -> Array:
	"""Get secrets based on relationship level"""
	var profile = get_npc_complete_profile(npc_id)
	var secrets = profile.get("secrets_and_quirks", {}).get("secrets", [])
	var revealed = []
	
	for secret in secrets:
		if relationship_level >= secret.reveal_condition.relationship_min:
			revealed.append(secret)
	
	return revealed

func get_current_schedule(npc_id: String, day_type: String = "weekday") -> Dictionary:
	"""Get NPC's schedule for current day type"""
	var profile = get_npc_complete_profile(npc_id)
	return profile.get("dynamic_schedule", {}).get(day_type, {})

func get_audio_file(npc_id: String, category: String, emotion: String = "") -> String:
	"""Get audio file path for NPC"""
	var profile = get_npc_complete_profile(npc_id)
	var audio = profile.get("audio_profile", {})
	
	if category == "emotion":
		return audio.get("emotion_sounds", {}).get(emotion, "")
	elif category == "activity":
		return audio.get("activity_sounds", {}).get(emotion, "")
	
	return ""

func get_catchphrase_by_context(npc_id: String, context: String) -> String:
	"""Get appropriate catchphrase for context"""
	var profile = get_npc_complete_profile(npc_id)
	var catchphrases = profile.get("speech_patterns", {}).get("catchphrases", {})
	var phrases = catchphrases.get(context, [])
	
	if phrases.is_empty():
		return ""
	
	return phrases[randi() % phrases.size()]

func check_gift_reaction(npc_id: String, gift_id: String) -> Dictionary:
	"""Check NPC's reaction to a gift"""
	var preferences = get_npc_preferences(npc_id, "gifts")
	
	for level in ["loved", "liked", "neutral", "disliked", "hated"]:
		if gift_id in preferences.get(level, {}).get("items", []):
			var data = preferences[level]
			return {
				"level": level,
				"reaction": data.reaction,
				"relationship_gain": data.relationship_gain
			}
	
	return {"level": "neutral", "reaction": "Thank you.", "relationship_gain": 20}

func get_weather_reaction(npc_id: String, weather: String) -> String:
	"""Get NPC's reaction to weather"""
	var preferences = get_npc_preferences(npc_id, "weather")
	return preferences.get("reactions", {}).get(weather, "")

func loves_topic(npc_id: String, topic: String) -> bool:
	"""Check if NPC loves discussing a topic"""
	var topics = get_npc_preferences(npc_id, "topics").get("loves", [])
	return topic.to_lower() in [t.to_lower() for t in topics]

func hates_topic(npc_id: String, topic: String) -> bool:
	"""Check if NPC hates discussing a topic"""
	var topics = get_npc_preferences(npc_id, "topics").get("hates", [])
	return topic.to_lower() in [t.to_lower() for t in topics]

func get_npc_audio_profile(npc_id: String) -> Dictionary:
	"""Get NPC's audio profile configuration"""
	if npc_database.has(npc_id):
		return npc_database[npc_id].get("audio_profile", {})
	return {}

func get_activity_sounds(npc_id: String, activity: String) -> Array:
	"""Get sound paths for a specific activity"""
	var profile = get_npc_audio_profile(npc_id)
	if profile.has("activity_sounds") and profile.activity_sounds.has(activity):
		return profile.activity_sounds[activity]
	
	# Fallback to general activity sounds from audio_library
	if audio_library.has("activities") and audio_library.activities.has(activity):
		return audio_library.activities[activity]
	
	return []

func get_greeting_sounds(npc_id: String, situation: String) -> Array:
	"""Get greeting sounds based on situation"""
	var profile = get_npc_audio_profile(npc_id)
	if profile.has("greeting_sounds") and profile.greeting_sounds.has(situation):
		return profile.greeting_sounds[situation]
	
	# Fallback to emotion-based greetings
	var emotion_map = {
		"morning": "happy",
		"greeting": "neutral",
		"raining": "sad",
		"tired": "sad"
	}
	var emotion = emotion_map.get(situation, "neutral")
	if audio_library.has("greetings") and audio_library.greetings.has(emotion):
		return audio_library.greetings[emotion]
	
	return []

func get_ambient_sounds(npc_id: String, location: String) -> Array:
	"""Get ambient sounds for current location"""
	var profile = get_npc_audio_profile(npc_id)
	if profile.has("ambient_sounds") and profile.ambient_sounds.has(location):
		return profile.ambient_sounds[location]
	
	# Fallback to location-based ambients
	if audio_library.has("ambient") and audio_library.ambient.has(location):
		return audio_library.ambient[location]
	
	return []

func get_catchphrase(npc_id: String, context: String) -> String:
	"""Get catchphrase for given context (wrapper for compatibility)"""
	return get_catchphrase_by_context(npc_id, context)

func check_gift_preference(npc_id: String, gift_id: String) -> Dictionary:
	"""Check NPC's reaction to a gift (wrapper for compatibility)"""
	return check_gift_reaction(npc_id, gift_id)

func get_special_reaction(npc_id: String, reaction_type: String) -> String:
	"""Get special reaction text for gift/interaction types"""
	var reactions = {
		"loves_it": ["Oh my! This is absolutely wonderful!", "I can't believe it! Thank you so much!", "This is my favorite thing!"],
		"likes_it": ["This is nice, thank you!", "I really like this!", "How thoughtful of you!"],
		"dislikes_it": ["Oh... um, thank you?", "This isn't really my taste...", "I appreciate the gesture..."],
		"hates_it": ["What is this supposed to be?", "I can't stand this!", "Why would you give me this?"]
	}
	
	if reactions.has(reaction_type):
		var options = reactions[reaction_type]
		return options[randi() % options.size()]
	
	return ""

func get_habitual_action(npc_id: String, mood: String) -> String:
	"""Get habitual action based on mood"""
	if not npc_database.has(npc_id):
		return ""
	
	var habits = npc_database[npc_id].get("habits", [])
	if habits.is_empty():
		return ""
	
	# Filter by mood if possible
	var mood_habits = []
	for habit in habits:
		if habit.has("mood") and habit.mood == mood:
			mood_habits.append(habit.get("action", ""))
	
	if not mood_habits.is_empty():
		return mood_habits[randi() % mood_habits.size()]
	
	# Return random habit if no mood match
	var random_habit = habits[randi() % habits.size()]
	return random_habit.get("action", "")
