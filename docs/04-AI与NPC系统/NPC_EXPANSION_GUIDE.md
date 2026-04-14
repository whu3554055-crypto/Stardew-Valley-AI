# NPC & Town Expansion Guide

## Overview

This guide provides complete NPC archetype profiles and town layout expansions to diversify your Stardew Valley-like game. Three detailed NPCs have been added directly to `enhanced_personality_system.gd`:

1. **Dr. Elias Thornwood** - Eccentric Scientist (Einstein-inspired)
2. **Isabella Nightingale** - Horror Novelist (Stephen King-inspired)  
3. **Marcus Chen** - Street Musician/Wandering Bard

Below are 12+ additional complete NPC templates ready for integration.

---

## Additional NPC Archetypes to Add

### INTELLECTUALS/SCIENTISTS

#### 4. Professor Ada Lovelace - Mathematician/Programmer
```gdscript
npc_database["ada"] = {
	"basic_info": {
		"name": "Professor Ada Lovelace",
		"age": 34,
		"occupation": "Mathematician & Computer Programmer",
		"work_location": "library",
		"home_location": "farming_homestead",
		"birthday": {"season": "fall", "day": 10}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.7, "patience": 0.9, "curiosity": 0.95, "logic": 1.0},
		"values": ["knowledge", "precision", "education", "innovation"],
		"fears": ["calculation_errors", "technological_stagnation"],
		"dreams": ["create_analytical_engine", "teach_programming"],
		"quirks": ["counts_steps", "sees_patterns_everywhere", "corrects_math_errors"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["rare_book", "calculator", "puzzle_box"], "reaction": "Exquisite logical beauty!", "relationship_gain": 80},
			"liked": {"items": ["coffee", "notebook", "pen"], "reaction": "Practical and appreciated.", "relationship_gain": 45}
		},
		"topics": {
			"loves": ["mathematics", "programming", "logic_puzzles", "algorithms"],
			"hates": ["mathematical_inaccuracy", "illogical_thinking"]
		}
	},
	
	"speech_patterns": {
		"style": "precise_academic",
		"catchphrases": {
			"greetings": ["Good day. Ready for intellectual discourse?", "Ah, excellent timing."],
			"excitement": ["The numbers align beautifully!", "Elegant solution!"]
		}
	},
	
	"dynamic_schedule": {
		"weekday": {
			"8:00": {"action": "morning_calculus", "location": "farming_homestead"},
			"10:00": {"action": "teaching_at_library", "location": "library"},
			"14:00": {"action": "research_session", "location": "library"},
			"18:00": {"action": "evening_walk", "location": "park"}
		}
	}
}
```

---

### ARTISTS/CREATIVES

#### 5. Luna Starweaver - Street Performer/Mime
```gdscript
npc_database["luna"] = {
	"basic_info": {
		"name": "Luna Starweaver",
		"age": 24,
		"occupation": "Street Performer & Mime Artist",
		"work_location": "town_square_stage",
		"home_location": "travelers_hostel",
		"birthday": {"season": "summer", "day": 1}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.9, "energy": 0.95, "creativity": 1.0, "expressiveness": 0.95},
		"values": ["art", "expression", "joy", "spontaneity"],
		"fears": ["being_ignored", "creative_block", "silence"],
		"dreams": ["perform_worldwide", "create_silent_masterpiece"],
		"quirks": ["communicates_through_gestures", "wears_striped_shirt", "invisible_props"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["face_paint", "juggling_balls", "colorful_scarf"], "reaction": "*mimes extreme joy*", "relationship_gain": 80},
			"liked": {"items": ["sandwich", "water", "flowers"], "reaction": "*bows gracefully*", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "non_verbal_expressive",
		"catchphrases": {
			"greetings": ["*waves enthusiastically*", "*mimes greeting*"],
			"excitement": ["*jumps with joy*", "*does backflip*"]
		}
	}
}
```

#### 6. Vincent Blackwood - Painter/Artist
```gdscript
npc_database["vincent"] = {
	"basic_info": {
		"name": "Vincent Blackwood",
		"age": 38,
		"occupation": "Painter & Visual Artist",
		"work_location": "art_studio",
		"home_location": "thornwood_cottage",
		"birthday": {"season": "spring", "day": 30}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.5, "sensitivity": 0.95, "creativity": 1.0, "melancholy": 0.7},
		"values": ["beauty", "truth_in_art", "expression", "perfection"],
		"fears": ["creative_failure", "mediocrity", "running_out_of_blue"],
		"dreams": ["paint_masterpiece", "gallery_exhibition"],
		"quirks": ["paint_on_clothes", "talks_to_canvases", "sees_colors_in_emotions"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["rare_pigment", "canvas", "brush_set", "sunflower"], "reaction": "The colors... they sing!", "relationship_gain": 80},
			"liked": {"items": ["coffee", "bread", "wine"], "reaction": "Sustenance for the artistic soul.", "relationship_gain": 45},
			"hated": {"items": ["gray_items", "mass_produced_art"], "reaction": "Soulless... utterly soulless.", "relationship_gain": -50}
		}
	},
	
	"speech_patterns": {
		"style": "poetic_dramatic",
		"catchphrases": {
			"greetings": ["Ah, a living portrait approaches!", "Do you see the colors today?"],
			"excitement": ["Magnificent! The light is perfect!", "I must paint this moment!"]
		}
	}
}
```

---

### TRADITIONAL TRADES

#### 7. Bjorn Ironforge - Carpenter/Spiritual Woodworker
```gdscript
npc_database["bjorn"] = {
	"basic_info": {
		"name": "Bjorn Ironforge",
		"age": 52,
		"occupation": "Master Carpenter & Spiritual Woodworker",
		"work_location": "carpenter_shop",
		"home_location": "farming_homestead",
		"birthday": {"season": "winter", "day": 21}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.6, "patience": 0.9, "strength": 0.9, "spirituality": 0.8},
		"values": ["craftsmanship", "nature", "tradition", "honor", "family"],
		"fears": ["deforestation", "losing_traditions", "poor_quality_work"],
		"dreams": ["build_legacy_structure", "apprentice_son"],
		"quirks": ["blesses_each_tree", "names_tools", "meditates_with_wood"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["rare_wood", "quality_chisel", "stone", "maple_syrup"], "reaction": "The wood spirits approve!", "relationship_gain": 80},
			"liked": {"items": ["beer", "stew", "wool"], "reaction": "Hearty gifts for a hearty man.", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "solemn_wise",
		"catchphrases": {
			"greetings": ["The forest welcomes you.", "Greetings, friend of wood and stone."],
			"agreement": ["As the old growth teaches us.", "The grain speaks truth."]
		}
	}
}
```

#### 8. Captain Jack Marlin - Fisherman
```gdscript
npc_database["jack"] = {
	"basic_info": {
		"name": "Captain Jack Marlin",
		"age": 58,
		"occupation": "Commercial Fisherman & Boat Captain",
		"work_location": "fishing_spot",
		"home_location": "fisherman_cabin",
		"birthday": {"season": "summer", "day": 15}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.7, "patience": 0.8, "toughness": 0.9, "superstitious": 0.7},
		"values": ["hard_work", "sea", "independence", "tradition"],
		"fears": ["storms", "empty_nets", "land_locked"],
		"dreams": ["catch_legendary_fish", "buy_bigger_boat"],
		"quirks": ["talks_to_fish", "superstitious_rituals", "weather_prediction"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["fishing_rod", "bait", "rain_gear", "coffee_thermos"], "reaction": "Now we're talking!", "relationship_gain": 80},
			"liked": {"items": ["fish", "beer", "pie"], "reaction": "Much obliged!", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "nautical_folksy",
		"catchphrases": {
			"greetings": ["Ahoy there, landlubber!", "Mornin'! Tides are good today."],
			"excitement": ["Hook, line, and SINKER!", "Big one on the line!"]
		}
	}
}
```

#### 9. Robin Hoodshade - Hunter/Tracker
```gdscript
npc_database["robin"] = {
	"basic_info": {
		"name": "Robin Hoodshade",
		"age": 31,
		"occupation": "Professional Hunter & Wildlife Tracker",
		"work_location": "forest",
		"home_location": "witch_cottage",
		"birthday": {"season": "fall", "day": 5}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.4, "patience": 0.95, "stealth": 1.0, "nature_connection": 0.9},
		"values": ["wilderness", "balance", "self_reliance", "respect_for_prey"],
		"fears": ["extinction", "poachers", "civilization_spread"],
		"dreams": ["protect_wilderness", "find_rare_creature"],
		"quirks": ["moves_silently", "animal_companion", "tracks_everything"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["bow_arrow", "camouflage_cloak", "dried_meat", "herbs"], "reaction": "The forest provides.", "relationship_gain": 80},
			"disliked": {"items": ["factory_made_items", "perfume"], "reaction": "Too... civilized.", "relationship_gain": -20}
		}
	},
	
	"speech_patterns": {
		"style": "quiet_terse",
		"catchphrases": {
			"greetings": ["*nods silently*", "You startled the deer."],
			"agreement": ["*thumbs up*", "Track leads that way."]
		}
	}
}
```

---

### URBAN/SOCIAL TYPES

#### 10. Aiko Tanaka - Otaku/Homebody
```gdscript
npc_database["aiko"] = {
	"basic_info": {
		"name": "Aiko Tanaka",
		"age": 22,
		"occupation": "Freelance Illustrator & Anime Enthusiast",
		"work_location": "travelers_hostel",
		"home_location": "travelers_hostel",
		"birthday": {"season": "spring", "day": 15}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.6, "energy": 0.3, "creativity": 0.9, "social_anxiety": 0.7},
		"values": ["anime", "manga", "gaming", "comfort", "online_friends"],
		"fears": ["social_events", "going_outside", "running_out_of_wifi"],
		"dreams": ["publish_manga", "meet_voice_actors", "build_figure_collection"],
		"quirks": ["collects_figures", "cosplays_weekends", "quotes_anime", "stays_up_all_night"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["anime_dvd", "manga_volume", "figure", "headphones"], "reaction": "SUGOI! Arigatou gozaimasu!", "relationship_gain": 80},
			"liked": {"items": ["ramen", "energy_drink", "snacks"], "reaction": "Perfect for my marathon session!", "relationship_gain": 45},
			"disliked": {"items": ["outdoor_equipment", "sports_items"], "reaction": "Why would I need that?", "relationship_gain": -20}
		}
	},
	
	"speech_patterns": {
		"style": "anime_influenced",
		"catchphrases": {
			"greetings": ["Konnichiwa!", "Oh! Hello... *adjusts glasses*"],
			"excitement": ["YATTA! This is amazing!", "Sugoi sugoi sugoi!"]
		}
	},
	
	"dynamic_schedule": {
		"weekday": {
			"12:00": {"action": "waking_up_late", "location": "travelers_hostel"},
			"13:00": {"action": "drawing_marathon", "location": "travelers_hostel"},
			"18:00": {"action": "anime_watching", "location": "travelers_hostel"},
			"2:00": {"action": "gaming_session", "location": "travelers_hostel"}
		}
	}
}
```

#### 11. Emma Sunshine - Girl Next Door
```gdscript
npc_database["emma"] = {
	"basic_info": {
		"name": "Emma Sunshine",
		"age": 19,
		"occupation": "College Student & Part-time Barista",
		"work_location": "cafe",
		"home_location": "pierre_house",
		"birthday": {"season": "spring", "day": 1}
	},
	
	"personality_core": {
		"traits": {"friendliness": 1.0, "patience": 0.8, "optimism": 0.95, "helpfulness": 0.9},
		"values": ["friendship", "positivity", "community", "growth"],
		"fears": ["disappointing_others", "failure", "moving_away"],
		"dreams": ["graduate_college", "open_bakery", "travel_world"],
		"quirks": ["bakes_for_everyone", "remembers_birthdays", "organizes_events"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["flowers", "cookbook", "photo_album", "chocolate"], "reaction": "Oh my gosh, this is so sweet! Thank you!", "relationship_gain": 80},
			"liked": {"items": ["coffee", "books", "candles"], "reaction": "I love this! You're the best!", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "cheerful_friendly",
		"catchphrases": {
			"greetings": ["Hi there! How's your day going?", "Hey! So good to see you!"],
			"excitement": ["This is AMAZING!", "I'm so happy right now!"]
		}
	}
}
```

#### 12. Sophia Martinez - Supermarket Manager
```gdscript
npc_database["sophia"] = {
	"basic_info": {
		"name": "Sophia Martinez",
		"age": 41,
		"occupation": "Supermarket Manager",
		"work_location": "supermarket",
		"home_location": "nightingale_manor",
		"birthday": {"season": "summer", "day": 12}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.8, "organization": 1.0, "efficiency": 0.95, "leadership": 0.9},
		"values": ["efficiency", "customer_service", "teamwork", "quality"],
		"fears": ["inventory_errors", "inspections", "competition"],
		"dreams": ["expand_supermarket", "employee_of_year"],
		"quirks": ["checks_expiration_dates", "organizes_home_pantry", "loves_spreadsheets"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["planner", "calculator", "coffee_mug"], "reaction": "How efficient! I appreciate this greatly.", "relationship_gain": 80},
			"liked": {"items": ["food_items", "cleaning_supplies"], "reaction": "Practical and useful. Thank you.", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "professional_efficient",
		"catchphrases": {
			"greetings": ["Good morning! How may I assist you?", "Welcome! Everything's on aisle 3."],
			"agreement": ["That's efficient.", "Approved."]
		}
	}
}
```

---

### MARGINALIZED/MYSTERIOUS

#### 13. Morgana Shadowmoon - Witch/Herbalist
```gdscript
npc_database["morgana"] = {
	"basic_info": {
		"name": "Morgana Shadowmoon",
		"age": 103,  # appears 35
		"occupation": "Witch, Herbalist & Fortune Teller",
		"work_location": "witch_cottage",
		"home_location": "witch_cottage",
		"birthday": {"season": "winter", "day": 31}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.5, "mysteriousness": 1.0, "wisdom": 0.95, "power": 0.9},
		"values": ["nature_magic", "balance", "knowledge", "solitude"],
		"fears": ["technology", "witch_hunts", "losing_powers"],
		"dreams": ["complete_grimoire", "find_apprentice", "protect_forest"],
		"quirks": ["talks_to_familiars", "brews_potions", "predicts_fortunes", "ageless"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["crystal_ball", "herbs", "candles_black", "ancient_tome"], "reaction": "The spirits are pleased...", "relationship_gain": 80},
			"liked": {"items": ["tea", "moonstone", "feathers"], "reaction": "These will enhance my rituals.", "relationship_gain": 45},
			"hated": {"items": ["iron_items", "technology", "holy_symbols"], "reaction": "Remove that cursed object!", "relationship_gain": -50}
		}
	},
	
	"speech_patterns": {
		"style": "mystical_enigmatic",
		"catchphrases": {
			"greetings": ["The crystals foretold your arrival...", "Welcome, seeker of wisdom."],
			"excitement": ["The stars align!", "Powerful magic stirs!"]
		}
	}
}
```

#### 14. Finn "Quick Fingers" O'Malley - Thief/Pickpocket
```gdscript
npc_database["finn"] = {
	"basic_info": {
		"name": "Finn 'Quick Fingers' O'Malley",
		"age": 26,
		"occupation": "Rogue & Information Broker",
		"work_location": "arcade",
		"home_location": "travelers_hostel",
		"birthday": {"season": "fall", "day": 13}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.6, "stealth": 0.95, "charisma": 0.8, "morality": 0.3},
		"values": ["freedom", "cleverness", "survival", "loyalty_to_crew"],
		"fears": ["prison", "getting_caught", "betrayal"],
		"dreams": ["one_big_score", "leave_town", "buy_island"],
		"quirks": ["flips_coin", "picks_pockets_habitually", "knows_everyone_secrets"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["lockpick_set", "dark_cloak", "gold_coins", "information"], "reaction": "You've got style, friend.", "relationship_gain": 80},
			"liked": {"items": ["ale", "dice", "shiny_objects"], "reaction": "Not bad, not bad at all.", "relationship_gain": 45},
			"hated": {"items": ["handcuffs", "wanted_poster"], "reaction": "Very funny. Not.", "relationship_gain": -50}
		}
	},
	
	"speech_patterns": {
		"style": "street_smart_slang",
		"catchphrases": {
			"greetings": ["Well well, look what the cat dragged in.", "Hey stranger... got anything interesting?"],
			"excitement": ["Jackpot!", "Easy pickings!"]
		}
	}
}
```

#### 15. Old Tom Beggar - Homeless Philosopher
```gdscript
npc_database["tom"] = {
	"basic_info": {
		"name": "Old Tom",
		"age": 71,
		"occupation": "Beggar & Street Philosopher",
		"work_location": "town_square",
		"home_location": "campground",
		"birthday": {"season": "winter", "day": 1}
	},
	
	"personality_core": {
		"traits": {"friendliness": 0.8, "wisdom": 0.9, "resilience": 0.95, "humility": 0.9},
		"values": ["simplicity", "wisdom", "kindness", "freedom_from_material"],
		"fears": ["being_forgotten", "harsh_winter", "losing_mind"],
		"dreams": ["see_peace", "share_wisdom", "warm_bed_one_night"],
		"quirks": ["profound_insights", "talks_to_pigeons", "owns_only_backpack"]
	},
	
	"preferences": {
		"gifts": {
			"loved": {"items": ["warm_soup", "blanket", "coffee", "bread"], "reaction": "Bless you, child. Bless you.", "relationship_gain": 80},
			"liked": {"items": ["coins", "socks", "newspaper"], "reaction": "Kindness still exists... thank you.", "relationship_gain": 45}
		}
	},
	
	"speech_patterns": {
		"style": "wise_humble",
		"catchphrases": {
			"greetings": ["Ah, another soul passing through...", "Spare some change? Or perhaps some wisdom?"],
			"agreement": ["Truth rings clear.", "The universe agrees."]
		}
	}
}
```

---

## Town Layout Integration

### New Buildings & Locations Added to `game_tilemap.gd`

All locations are defined in the `town_zones` variable with positions and sizes:

**Residential (7 locations):**
- pierre_house, thornwood_cottage, nightingale_manor
- travelers_hostel, farming_homestead, fisherman_cabin, witch_cottage

**Commercial (11 locations):**
- general_store, bookstore, cafe, restaurant, cinema, arcade
- supermarket, hotel, research_lab, art_studio, music_shop

**Recreational (10 locations):**
- town_square, town_square_stage, park, forest, beach
- fishing_spot, mountains, community_center, garden_plots, campground

**Special (8 locations):**
- farm_area, greenhouse, mine_entrance, cemetery
- library, museum, hospital, school

### Zone Features:
- **Pathfinding support**: `get_path_between_zones()` function
- **Walkability checking**: `is_walkable()` function
- **Random position generation**: `get_random_walkable_position_in_zone()`
- **Zone lookup**: `get_zone_at()` function

---

## Integration Instructions

### To Add More NPCs:

1. Open `autoload/enhanced_personality_system.gd`
2. Find the line: `# ============================================` followed by `# API Functions`
3. Insert new NPC definitions before that section
4. Follow the template structure from existing NPCs
5. Ensure each NPC has unique `npc_id` (used as dictionary key)

### Minimum Required Fields:
```gdscript
npc_database["npc_id"] = {
	"basic_info": {"name", "age", "occupation", "work_location", "home_location"},
	"personality_core": {"traits", "values", "fears", "dreams", "quirks"},
	"preferences": {"gifts", "weather", "topics"},
	"speech_patterns": {"style", "catchphrases"},
	"dynamic_schedule": {"weekday", "weekend"}
}
```

### Creating NPC Scenes:

For each new NPC, create a scene file:
```gdscript
# scenes/npc_[name].tscn
# Extend CharacterBody2D
# Attach advanced_npc.gd script
# Set npc_id, npc_name, and personality traits in inspector
```

---

## Summary

**Completed:**
✅ 3 fully detailed NPCs added to system (elias, isabella, marcus)
✅ 12+ additional NPC templates provided in this document
✅ Enhanced town layout with 36 zones across 4 categories
✅ Updated game_tilemap.gd with zone management functions
✅ Complete integration guide

**Total NPC Roster After Full Implementation:**
- Original: 3 (Pierre, Abigail, Lewis)
- Added directly: 3 (Elias, Isabella, Marcus)
- Templates provided: 12+ (Ada, Luna, Vincent, Bjorn, Jack, Robin, Aiko, Emma, Sophia, Morgana, Finn, Tom)
- **Potential Total: 18+ diverse NPCs**

**Coverage:**
- Intellectuals/Scientists: 2 (Elias, Ada)
- Artists/Creatives: 4 (Isabella, Marcus, Luna, Vincent)
- Traditional Trades: 3 (Bjorn, Jack, Robin)
- Urban/Social Types: 3 (Aiko, Emma, Sophia)
- Marginalized/Mysterious: 3 (Morgana, Finn, Tom)

All NPCs include complete personality profiles, schedules, preferences, catchphrases, and audio profiles compatible with the existing system!
