extends Node
## AgenticThemeManager - Manages theme selection, rotation, and player preferences.
## Ensures diverse and engaging theme distribution.
##
## Responsibilities:
## - Intelligent theme selection
## - Theme rotation to avoid repetition
## - Player preference learning
## - Theme history tracking

# === 常量 ===

const THEME_HISTORY_SIZE := 20
const MIN_THEME_GAP := 3  # Minimum games before reusing theme
const PREFERENCE_DECAY := 0.95  # How quickly preferences decay

# Available themes
const AVAILABLE_THEMES: Array[String] = [
	"magical",
	"fairy_tale",
	"horror",
	"romantic",
	"joyful",
	"sci_fi",
	"adventure",
	"comedy"
]

# === 成员变量 ===

var _recent_theme_history: Array[String] = []
var _player_pref_scores: Dictionary = {}
var _continuity_hint: String = ""
var _last_used_theme: String = ""
var _theme_usage_counts: Dictionary = {}

# === 信号 ===

signal theme_selected(theme: String, reason: String)
signal theme_rotated(old_theme: String, new_theme: String)
signal preference_updated(theme: String, score: float)

# === 生命周期方法 ===

func _ready() -> void:
	_initialize_preferences()

func _initialize_preferences() -> void:
	"""Initialize player preferences with default values"""
	for theme in AVAILABLE_THEMES:
		if not _player_pref_scores.has(theme):
			_player_pref_scores[theme] = 0.5  # Neutral starting point
		
		if not _theme_usage_counts.has(theme):
			_theme_usage_counts[theme] = 0

# === 公共方法 ===

## Select next theme based on various factors
func select_theme(reason: Dictionary = {}) -> String:
	"""
	Select theme intelligently considering:
	- Recent history (avoid repetition)
	- Player preferences
	- Continuity hints
	- Rotation requirements
	
	Returns: Selected theme string
	"""
	var candidates = _get_candidate_themes()
	
	if candidates.is_empty():
		# Fallback to least used theme
		return _get_least_used_theme()
	
	# Score candidates
	var scored = _score_candidates(candidates, reason)
	
	# Select best candidate
	var selected = _select_from_scored(scored)
	
	# Record selection
	_record_theme_usage(selected)
	_last_used_theme = selected
	
	emit_signal("theme_selected", selected, reason.get("reason", "auto"))
	
	return selected

## Record that a theme was used
func record_theme_usage(theme: String, success: bool = true) -> void:
	"""Update preferences based on theme completion"""
	if success:
		# Increase preference for successful themes
		if _player_pref_scores.has(theme):
			_player_pref_scores[theme] = min(1.0, 
				_player_pref_scores[theme] + 0.1)
	else:
		# Decrease preference for failed themes
		if _player_pref_scores.has(theme):
			_player_pref_scores[theme] = max(0.0, 
				_player_pref_scores[theme] - 0.05)
	
	emit_signal("preference_updated", theme, _player_pref_scores.get(theme, 0.5))

## Get player's preferred themes
func get_preferred_themes(count: int = 3) -> Array[String]:
	"""Get top N preferred themes"""
	var sorted = _player_pref_scores.keys()
	sorted.sort_custom(func(a, b): 
		return _player_pref_scores[a] > _player_pref_scores[b]
	)
	
	return sorted.slice(0, count)

## Get themes to avoid (recently used)
func get_blocked_themes() -> Array[String]:
	"""Get themes that shouldn't be used yet"""
	var blocked: Array[String] = []
	
	for i in range(_recent_theme_history.size()):
		var theme = _recent_theme_history[i]
		var positions_ago = _recent_theme_history.size() - i
		
		if positions_ago < MIN_THEME_GAP:
			if not blocked.has(theme):
				blocked.append(theme)
	
	return blocked

## Set continuity hint for next theme
func set_continuity_hint(hint: String) -> void:
	"""Set hint for thematic continuity"""
	_continuity_hint = hint

## Get theme statistics
func get_theme_stats() -> Dictionary:
	"""Get usage statistics for all themes"""
	return {
		"preferences": _player_pref_scores.duplicate(),
		"usage_counts": _theme_usage_counts.duplicate(),
		"recent_history": _recent_theme_history.duplicate(),
		"last_used": _last_used_theme
	}

## Reset theme history (use sparingly)
func reset_history() -> void:
	_recent_theme_history.clear()
	_last_used_theme = ""

# === 私有方法 ===

func _get_candidate_themes() -> Array[String]:
	"""Get themes eligible for selection"""
	var blocked = get_blocked_themes()
	var candidates: Array[String] = []
	
	for theme in AVAILABLE_THEMES:
		if not blocked.has(theme):
			candidates.append(theme)
	
	return candidates

func _score_candidates(candidates: Array[String], reason: Dictionary) -> Dictionary:
	"""Score each candidate theme"""
	var scores: Dictionary = {}
	
	for theme in candidates:
		var score = 0.0
		
		# Base score from player preference
		score += _player_pref_scores.get(theme, 0.5) * 40
		
		# Bonus for continuity hint match
		if _continuity_hint and _matches_hint(theme, _continuity_hint):
			score += 30
		
		# Bonus for underused themes (promote diversity)
		var usage = _theme_usage_counts.get(theme, 0)
		score += max(0, 20 - usage * 2)
		
		# Random factor for variety
		score += randf() * 10
		
		scores[theme] = score
	
	return scores

func _select_from_scored(scored: Dictionary) -> String:
	"""Select theme using weighted random"""
	if scored.is_empty():
		return AVAILABLE_THEMES[randi() % AVAILABLE_THEMES.size()]
	
	# Find highest scored theme
	var best_theme = ""
	var best_score = -1.0
	
	for theme in scored.keys():
		if scored[theme] > best_score:
			best_score = scored[theme]
			best_theme = theme
	
	return best_theme

func _record_theme_usage(theme: String) -> void:
	"""Record theme usage in history"""
	_recent_theme_history.append(theme)
	
	# Keep history at manageable size
	if _recent_theme_history.size() > THEME_HISTORY_SIZE:
		_recent_theme_history.pop_front()
	
	# Update usage counts
	if not _theme_usage_counts.has(theme):
		_theme_usage_counts[theme] = 0
	
	_theme_usage_counts[theme] += 1
	
	# Apply preference decay to all themes
	for t in _player_pref_scores.keys():
		_player_pref_scores[t] *= PREFERENCE_DECAY

func _get_least_used_theme() -> String:
	"""Find the least used theme"""
	var min_usage = 999999
	var least_used = AVAILABLE_THEMES[0]
	
	for theme in AVAILABLE_THEMES:
		var usage = _theme_usage_counts.get(theme, 0)
		if usage < min_usage:
			min_usage = usage
			least_used = theme
	
	return least_used

func _matches_hint(theme: String, hint: String) -> bool:
	"""Check if theme matches continuity hint"""
	# Simple keyword matching (can be enhanced)
	var theme_keywords = {
		"magical": ["magic", "mystical", "enchanted"],
		"horror": ["scary", "spooky", "mystery"],
		"romantic": ["love", "relationship", "heart"],
		"adventure": ["quest", "journey", "explore"]
	}
	
	var keywords = theme_keywords.get(theme, [])
	for keyword in keywords:
		if keyword in hint.to_lower():
			return true
	
	return false
