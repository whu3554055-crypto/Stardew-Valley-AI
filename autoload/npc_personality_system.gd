extends Node

# ============================================
# NPC 个性化系统
# 管理喜好、口头禅、习惯动作等细节
# ============================================

# NPC 个性数据库
var npc_personalities = {}

# 口头禅库
var catchphrase_library = {
	"greetings": {
		"casual": ["Hey there!", "Hi!", "Hello!", "What's up?", "Howdy!"],
		"formal": ["Good morning.", "Greetings.", "Pleasure to see you.", "Welcome."],
		"energetic": ["Hey!!!", "Woohoo!", "Yahaha!", "Oh boy!"],
		"shy": ["Um... hi...", "Oh... hello...", "H-hi there..."],
		"gruff": ["Yeah?", "What?", "Hmph.", "..."],
		"warm": ["Hello dear!", "Lovely to see you!", "Come in, come in!"]
	},
	
	"farewells": {
		"casual": ["See ya!", "Bye!", "Take care!", "Catch you later!"],
		"formal": ["Farewell.", "Until next time.", "Have a pleasant day."],
		"energetic": ["Byeee!", "See you soon!!!", "Can't wait!"],
		"shy": ["B-bye...", "See you...", "*waves quietly*"],
		"gruff": ["Hmph.", "*grunts*", "Later."],
		"warm": ["Take care now!", "Come back soon!", "Bless you!"]
	},
	
	"thanks": {
		"casual": ["Thanks!", "Much appreciated!", "You're the best!"],
		"formal": ["Thank you very much.", "I'm grateful.", "My sincere thanks."],
		"energetic": ["THANK YOU!!!", "You're AMAZING!"],
		"shy": ["Th-thank you...", "I... appreciate it..."],
		"gruff": ["Thanks.", "Hmph. Appreciate it."],
		"warm": ["Oh, thank you dear!", "How kind of you!"]
	},
	
	"surprised": {
		"casual": ["Whoa!", "No way!", "Seriously?"],
		"formal": ["My goodness!", "How unexpected!", "Remarkable!"],
		"energetic": ["WOW!!!", "NO WAY!!!", "OMG!!!"],
		"shy": ["Eep!", "Oh my...", "I-I didn't expect..."],
		"gruff": ["Tch.", "Huh.", "Whatever."],
		"warm": ["Oh my stars!", "How wonderful!", "Bless my soul!"]
	},
	
	"thinking": {
		"casual": ["Hmm...", "Let me think...", "Well..."],
		"formal": ["Indeed...", "A curious matter...", "One must consider..."],
		"energetic": ["Ooh ooh!", "I know! I know!"],
		"shy": ["Umm...", "Maybe...?", "I-I suppose..."],
		"gruff": ["*scratches head*", "Dunno.", "Beats me."],
		"warm": ["Now let me see...", "Let's think together, dear..."]
	}
}

# 喜好数据库
var preferences_db = {
	"gifts": {
		"loved": [],      # 最喜欢的礼物（+80 关系点）
		"liked": [],      # 喜欢的礼物（+45 关系点）
		"neutral": [],    # 无感（+20 关系点）
		"disliked": [],   # 不喜欢（-20 关系点）
		"hated": []       # 讨厌（-50 关系点）
	},
	
	"foods": {
		"favorite_meals": [],
		"favorite_drinks": [],
		"dislikes": []
	},
	
	"activities": {
		"enjoys": [],
		"avoids": []
	},
	
	"topics": {
		"loves_discussing": [],
		"hates_discussing": []
	},
	
	"environment": {
		"favorite_weather": "",
		"favorite_time": "",
		"favorite_location": ""
	}
}

# 习惯动作库
var habitual_actions = {
	"nervous": ["fidgeting with hands", "adjusting clothes", "looking around anxiously"],
	"happy": ["humming softly", "whistling", "bouncing slightly"],
	"thinking": ["stroking chin", "tapping foot", "looking upward"],
	"bored": ["yawning", "checking watch", "looking at nails"],
	"excited": ["jumping slightly", "clapping hands", "spinning around"],
	"shy": ["playing with hair", "looking down", "fidgeting with hem"]
}

# 对话模板
var dialogue_templates = {
	"introductions": [],
	"small_talk": [],
	"deep_conversations": [],
	"reactions": {}
}

signal preference_learned(npc_id, category, item)
signal favorite_discovered(npc_id, item_type, item)

func _ready():
	initialize_npc_personalities()

func initialize_npc_personalities():
	"""初始化所有 NPC 的个性化数据"""
	
	# Pierre 的个性
	npc_personalities["pierre"] = {
		"name": "Pierre",
		"speech_style": "warm",
		
		# 口头禅
		"catchphrases": {
			"greeting": ["Welcome to my store!", "Ah, a valued customer!"],
			"agreement": ["Absolutely!", "Indeed indeed!", "That's right!"],
			"concern": ["Oh dear...", "I do hope...", "Let's see what we can do..."],
			"excitement": ["Wonderful!", "Splendid!", "How marvelous!"],
			"filler": ["you see", "as it were", "if you will"]
		},
		
		# 喜好
		"preferences": {
			"gifts": {
				"loved": ["gold_bar", "diamond", "cooking_recipe"],
				"liked": ["parsnip", "green_bean", "cauliflower"],
				"neutral": ["wood", "stone"],
				"disliked": ["monster_loot", "slime"],
				"hated": ["trash", "broken_glasses"]
			},
			"foods": {
				"favorite_meals": ["pizza", "pasta", "bread"],
				"favorite_drinks": ["coffee", "juice"],
				"dislikes": ["wild_horseradish", "dandelion"]
			},
			"activities": {
				"enjoys": ["shopping", "farming", "family_time"],
				"avoids": ["combat", "mining", "late_nights"]
			},
			"topics": {
				"loves_discussing": ["business", "family", "community", "farming"],
				"hates_discussing": ["JojaMart", "danger", "scandal"]
			},
			"environment": {
				"favorite_weather": "sunny",
				"favorite_time": "morning",
				"favorite_location": "store"
			}
		},
		
		# 习惯动作
		"habits": {
			"when_happy": ["polishing counter", "arranging shelves", "humming tune"],
			"when_worried": ["wiping forehead", "checking ledger", "pacing"],
			"when_thinking": ["stroking mustache", "adjusting apron", "tapping chin"],
			"idle": ["organizing items", "sweeping floor", "checking inventory"]
		},
		
		# 特殊反应
		"special_reactions": {
			"sees_rain": "The crops will love this rain!",
			"sees_player_farming": "Keep up the good work! The valley needs farmers like you!",
			"daughter_mentioned": "Abigail? She's... quite the character. *sighs*",
			"business_mentioned": "Business is good! Well, most days anyway..."
		},
		
		# 对话风格特征
		"speech_patterns": {
			"uses_exclamations": true,
			"formal_level": 0.3,
			"warmth_level": 0.9,
			"common_words": ["dear", "valued", "wonderful", " splendid"],
			"avoid_words": ["bad", "terrible", "awful"]
		}
	}
	
	# Abigail 的个性
	npc_personalities["abigail"] = {
		"name": "Abigail",
		"speech_style": "energetic",
		
		# 口头禅
		"catchphrases": {
			"greeting": ["Hey!", "Yo!", "What's up adventurer?"],
			"agreement": ["Heck yeah!", "Totally!", "For sure!"],
			"excitement": ["AWESOME!!!", "SO COOL!", "Let's goooo!"],
			"frustration": ["Ugh!", "Not again!", "So annoying!"],
			"filler": ["like", "totally", "you know"]
		},
		
		# 喜好
		"preferences": {
			"gifts": {
				"loved": ["amethyst", "monster_loot", "sword", "ring_of_yoba"],
				"liked": ["quartz", "earth_crystal", "video_game"],
				"neutral": ["flowers", "fruits"],
				"disliked": ["farming_tools", "cookbook"],
				"hated": ["hay", "mayonnaise"]
			},
			"foods": {
				"favorite_meals": ["chocolate_cake", "pumpkin_soup", "eggplant_parmesan"],
				"favorite_drinks": ["coffee", "energy_drink"],
				"dislikes": ["salad", "healthy_food"]
			},
			"activities": {
				"enjoys": ["adventuring", "gaming", "exploring_caves", "magic"],
				"avoids": ["farming", "cleaning", "shopping"]
			},
			"topics": {
				"loves_discussing": ["adventure", "monsters", "magic", "games", "mysteries"],
				"hates_discussing": ["chores", "boring_stuff", "marriage"]
			},
			"environment": {
				"favorite_weather": "storm",
				"favorite_time": "night",
				"favorite_location": "mountains"
			}
		},
		
		# 习惯动作
		"habits": {
			"when_happy": ["doing a little dance", "spinning around", "air guitar"],
			"when_excited": ["jumping up and down", "punching air", "running in circles"],
			"when_thinking": ["tilting head", "twirling hair", "looking at nails"],
			"idle": ["practicing sword moves", "examining gems", "playing handheld game"]
		},
		
		# 特殊反应
		"special_reactions": {
			"sees_storm": "YES! Storm weather is perfect for adventure!",
			"sees_player_with_sword": "Whoa! Nice sword! Wanna spar sometime?",
			"dad_mentioned": "Dad worries too much. I can take care of myself!",
			"adventure_mentioned": "Adventure? I'm SO in! When do we start?"
		},
		
		# 对话风格特征
		"speech_patterns": {
			"uses_exclamations": true,
			"exclamation_frequency": 0.7,
			"uses_slang": true,
			"energy_level": 0.95,
			"common_words": ["awesome", "cool", "totally", "heck"],
			"avoid_words": ["boring", "maybe", "perhaps"]
		}
	}
	
	# Mayor Lewis 的个性
	npc_personalities["lewis"] = {
		"name": "Mayor Lewis",
		"speech_style": "formal",
		
		# 口头禅
		"catchphrases": {
			"greeting": ["Good day to you.", "Greetings, citizen.", "Welcome."],
			"agreement": ["Quite so.", "Indeed.", "A sound proposition."],
			"concern": ["This is troubling...", "We must address this...", "Hmm..."],
			"authority": ["As mayor...", "For the good of the town...", "I must insist..."],
			"filler": ["you understand", "if you will", "as it were"]
		},
		
		# 喜好
		"preferences": {
			"gifts": {
				"loved": ["ancient_artifact", "book", "wine"],
				"liked": ["vegetables", "flowers", "tea"],
				"neutral": ["ores", "gems"],
				"disliked": ["trash", "junk"],
				"hated": ["monster_parts", "slime"]
			},
			"foods": {
				"favorite_meals": ["vegetable_stew", "soup", "roasted_mushrooms"],
				"favorite_drinks": ["tea", "wine", "coffee"],
				"dislikes": ["fast_food", "candy"]
			},
			"activities": {
				"enjoys": ["town_management", "festivals", "inspections", "gardening"],
				"avoids": ["conflict", "scandals", "late_parties"]
			},
			"topics": {
				"loves_discussing": ["community", "festivals", "agriculture", "history"],
				"hates_discussing": ["scandals", "Marnie_secret", "complaints"]
			},
			"environment": {
				"favorite_weather": "sunny",
				"favorite_time": "afternoon",
				"favorite_location": "town_square"
			}
		},
		
		# 习惯动作
		"habits": {
			"when_happy": ["nodding approvingly", "clasping hands", "smiling warmly"],
			"when_worried": ["furrowing brow", "pacing slowly", "stroking chin"],
			"when_authoritative": ["standing tall", "clearing throat", "raising hand"],
			"idle": ["inspecting town", "tending garden", "reviewing documents"]
		},
		
		# 特殊反应
		"special_reactions": {
			"sees_festival_preparation": "The festival brings our community together!",
			"sees_player_working": "Hard work builds character. Keep it up!",
			"marnie_mentioned": "M-Marnie? Ah yes, a fine upstanding citizen!",
			"town_issue": "We must handle this discreetly, for the good of Pelican Town."
		},
		
		# 对话风格特征
		"speech_patterns": {
			"uses_formal_language": true,
			"formal_level": 0.85,
			"uses_titles": true,
			"diplomatic_level": 0.9,
			"common_words": ["indeed", "citizen", "community", "responsibility"],
			"avoid_words": ["yeah", "nope", "whatever"]
		}
	}

func get_npc_personality(npc_id: String) -> Dictionary:
	"""获取 NPC 的完整个性档案"""
	return npc_personalities.get(npc_id, {})

func get_catchphrase(npc_id: String, category: String) -> String:
	"""获取 NPC 的口头禅"""
	var personality = get_npc_personality(npc_id)
	if personality.is_empty():
		return "..."
	
	var catchphrases = personality.get("catchphrases", {})
	var phrases = catchphrases.get(category, [])
	
	if phrases.is_empty():
		#  fallback 到通用口头禅
		var style = personality.get("speech_style", "casual")
		var library_phrases = catchphrase_library.get(category, {}).get(style, [])
		if not library_phrases.is_empty():
			return library_phrases[randi() % library_phrases.size()]
		return "..."
	
	return phrases[randi() % phrases.size()]

func check_gift_preference(npc_id: String, gift_id: String) -> Dictionary:
	"""检查 NPC 对礼物的喜好"""
	var personality = get_npc_personality(npc_id)
	if personality.is_empty():
		return {"level": "neutral", "points": 20}
	
	var prefs = personality.get("preferences", {}).get("gifts", {})
	
	if gift_id in prefs.get("loved", []):
		return {"level": "loved", "points": 80, "reaction": "absolutely_loves"}
	elif gift_id in prefs.get("liked", []):
		return {"level": "liked", "points": 45, "reaction": "likes"}
	elif gift_id in prefs.get("disliked", []):
		return {"level": "disliked", "points": -20, "reaction": "dislikes"}
	elif gift_id in prefs.get("hated", []):
		return {"level": "hated", "points": -50, "reaction": "hates"}
	else:
		return {"level": "neutral", "points": 20, "reaction": "neutral"}

func get_habitual_action(npc_id: String, mood: String) -> String:
	"""获取 NPC 的习惯动作"""
	var personality = get_npc_personality(npc_id)
	if personality.is_empty():
		return "standing still"
	
	var habits = personality.get("habits", {})
	var actions = habits.get(mood, habits.get("idle", []))
	
	if actions.is_empty():
		return "standing still"
	
	return actions[randi() % actions.size()]

func get_special_reaction(npc_id: String, trigger: String) -> String:
	"""获取 NPC 的特殊反应"""
	var personality = get_npc_personality(npc_id)
	if personality.is_empty():
		return ""
	
	var reactions = personality.get("special_reactions", {})
	return reactions.get(trigger, "")

func loves_topic(npc_id: String, topic: String) -> bool:
	"""检查 NPC 是否喜欢某个话题"""
	var personality = get_npc_personality(npc_id)
	var topics = personality.get("preferences", {}).get("topics", {}).get("loves_discussing", [])
	var tl: String = topic.to_lower()
	for t in topics:
		if str(t).to_lower() == tl:
			return true
	return false

func hates_topic(npc_id: String, topic: String) -> bool:
	"""检查 NPC 是否讨厌某个话题"""
	var personality = get_npc_personality(npc_id)
	var topics = personality.get("preferences", {}).get("topics", {}).get("hates_discussing", [])
	var tl: String = topic.to_lower()
	for t in topics:
		if str(t).to_lower() == tl:
			return true
	return false

func get_favorite_environment(npc_id: String) -> Dictionary:
	"""获取 NPC 最喜欢的环境"""
	var personality = get_npc_personality(npc_id)
	return personality.get("preferences", {}).get("environment", {})

func get_speech_pattern(npc_id: String, pattern_name: String):
	"""获取 NPC 的说话模式特征"""
	var personality = get_npc_personality(npc_id)
	var patterns = personality.get("speech_patterns", {})
	return patterns.get(pattern_name, null)

func add_custom_catchphrase(npc_id: String, category: String, phrase: String):
	"""添加自定义口头禅"""
	if npc_personalities.has(npc_id):
		if not npc_personalities[npc_id].has("catchphrases"):
			npc_personalities[npc_id]["catchphrases"] = {}
		
		if not npc_personalities[npc_id].catchphrases.has(category):
			npc_personalities[npc_id].catchphrases[category] = []
		
		npc_personalities[npc_id].catchphrases[category].append(phrase)

func learn_preference(npc_id: String, category: String, item: String, level: String):
	"""学习 NPC 的新喜好"""
	if npc_personalities.has(npc_id):
		if not npc_personalities[npc_id].has("preferences"):
			npc_personalities[npc_id]["preferences"] = {"gifts": {}}
		
		if not npc_personalities[npc_id].preferences.gifts.has(level):
			npc_personalities[npc_id].preferences.gifts[level] = []
		
		if not item in npc_personalities[npc_id].preferences.gifts[level]:
			npc_personalities[npc_id].preferences.gifts[level].append(item)
			preference_learned.emit(npc_id, category, item)

# ============================================
# 辅助函数
# ============================================

func format_personality_summary(npc_id: String) -> String:
	"""生成个性摘要（用于提示词）"""
	var p = get_npc_personality(npc_id)
	if p.is_empty():
		return "A regular villager."
	
	var summary = ""
	
	# 说话风格
	summary += "Speaks in a %s manner. " % p.get("speech_style", "normal")
	
	# 喜好
	var loves = p.get("preferences", {}).get("topics", {}).get("loves_discussing", [])
	if not loves.is_empty():
		summary += "Loves talking about %s. " % ", ".join(loves.slice(0, 3))
	
	# 习惯
	var idle_habits = p.get("habits", {}).get("idle", [])
	if not idle_habits.is_empty():
		summary += "Often seen %s. " % idle_habits[0]
	
	# 口头禅示例
	var greeting = get_catchphrase(npc_id, "greeting")
	if greeting != "":
		summary += "Commonly says '%s'" % greeting
	
	return summary
