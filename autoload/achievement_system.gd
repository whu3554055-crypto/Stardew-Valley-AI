extends Node

class_name AchievementSystem

var achievements = {}
var unlocked_achievements = []

signal achievement_unlocked(achievement_id)

func _ready():
	initialize_achievements()

func initialize_achievements():
	# Farming achievements
	achievements["first_crop"] = {
		"id": "first_crop",
		"title": "Greenhorn",
		"description": "Plant your first crop",
		"category": "farming",
		"unlocked": false
	}

	achievements["master_farmer"] = {
		"id": "master_farmer",
		"title": "Master Farmer",
		"description": "Harvest 100 crops",
		"category": "farming",
		"requirement": 100,
		"unlocked": false
	}

	achievements["rich"] = {
		"id": "rich",
		"title": "Millionaire",
		"description": "Earn 10,000 gold",
		"category": "earning",
		"requirement": 10000,
		"unlocked": false
	}

	achievements["socialite"] = {
		"id": "socialite",
		"title": "Socialite",
		"description": "Talk to every villager",
		"category": "social",
		"unlocked": false
	}

	achievements["angler"] = {
		"id": "angler",
		"title": "Master Angler",
		"description": "Catch 10 different fish",
		"category": "fishing",
		"requirement": 10,
		"unlocked": false
	}

	achievements["explorer"] = {
		"id": "explorer",
		"title": "Explorer",
		"description": "Reach the bottom of the mines",
		"category": "exploration",
		"unlocked": false
	}

	achievements["chef"] = {
		"id": "chef",
		"title": "Gourmet Chef",
		"description": "Cook every recipe",
		"category": "cooking",
		"unlocked": false
	}

	achievements["collector"] = {
		"id": "collector",
		"title": "Collector",
		"description": "Complete the museum collection",
		"category": "collection",
		"unlocked": false
	}

func unlock_achievement(achievement_id: String):
	if not achievements.has(achievement_id):
		return

	var achievement = achievements[achievement_id]
	if not achievement.unlocked:
		achievement.unlocked = true
		unlocked_achievements.append(achievement_id)
		achievement_unlocked.emit(achievement_id)
		print("Achievement Unlocked: %s - %s" % [achievement.title, achievement.description])

func check_progress(stat_name: String, value: int):
	match stat_name:
		"crops_harvested":
			if value >= 100 and not achievements["master_farmer"].unlocked:
				unlock_achievement("master_farmer")
		"gold_earned":
			if GameManager.player_data.gold >= 10000 and not achievements["rich"].unlocked:
				unlock_achievement("rich")

func get_achievement(achievement_id: String) -> Dictionary:
	return achievements.get(achievement_id, {})

func get_all_achievements() -> Array:
	return achievements.values()

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return achievements.size()

func get_completion_percentage() -> float:
	if achievements.size() == 0:
		return 0.0
	return (float(get_unlocked_count()) / get_total_count()) * 100.0
