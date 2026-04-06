extends Node

class_name NPCAudioManager

# ============================================
# NPC Audio Management System
# Handles all NPC-related sound effects and audio feedback
# ============================================

# Audio players pool for concurrent sounds
var audio_players = []
const MAX_CONCURRENT_SOUNDS = 10

# Audio configuration
var audio_config = {
	"master_volume": 1.0,
	"sfx_volume": 0.8,
	"ambient_volume": 0.5,
	"voice_volume": 0.9,
	"enable_emotion_sounds": true,
	"enable_activity_sounds": true,
	"enable_ambient_sounds": true
}

# Currently playing sounds tracking
var active_sounds = {}

# Sound cooldowns to prevent spam
var sound_cooldowns = {}
const DEFAULT_COOLDOWN = 2.0

signal sound_played(npc_id, sound_type, sound_path)
signal sound_finished(npc_id, sound_type)

func _ready():
	initialize_audio_pool()
	load_audio_config()

func initialize_audio_pool():
	"""Create pool of reusable audio players"""
	for i in range(MAX_CONCURRENT_SOUNDS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		audio_players.append(player)

func load_audio_config():
	"""Load audio preferences from config file"""
	var config_path = "user://npc_audio_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			audio_config.merge(data)
		file.close()

func save_audio_config():
	"""Save audio preferences"""
	var file = FileAccess.open("user://npc_audio_config.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(audio_config))
	file.close()

# ============================================
# Core Audio Functions
# ============================================

func play_npc_sound(
	npc_id: String,
	sound_type: String,
	sound_path: String,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	priority: int = 0
) -> bool:
	"""
	Play a sound effect for an NPC
	
	Args:
		npc_id: The NPC identifier
		sound_type: Type of sound (emotion, activity, greeting, etc.)
		sound_path: Path to the audio file
		volume_db: Volume adjustment in decibels
		pitch_scale: Pitch modification (1.0 = normal)
		priority: Priority level (higher = more important)
	
	Returns:
		true if sound played successfully, false otherwise
	"""
	
	# Check if sounds are enabled
	if not should_play_sound(sound_type):
		return false
	
	# Check cooldown
	if is_on_cooldown(npc_id, sound_type):
		return false
	
	# Check if path exists
	if not ResourceLoader.exists(sound_path):
		print("[NPCAudio] Warning: Sound file not found: ", sound_path)
		return false
	
	# Load the audio resource
	var audio_stream = ResourceLoader.load(sound_path) as AudioStream
	if not audio_stream:
		print("[NPCAudio] Error: Could not load sound: ", sound_path)
		return false
	
	# Find available audio player
	var player = find_available_player(priority)
	if not player:
		# If no player available and priority is high, stop lowest priority sound
		if priority > 0:
			player = stop_lowest_priority_sound()
		else:
			return false
	
	# Configure and play
	player.stream = audio_stream
	player.volume_db = volume_db + calculate_volume_adjustment(sound_type)
	player.pitch_scale = pitch_scale
	player.play()
	
	# Track the sound
	var sound_id = "%s_%s_%d" % [npc_id, sound_type, Time.get_ticks_usec()]
	active_sounds[sound_id] = {
		"player": player,
		"npc_id": npc_id,
		"sound_type": sound_type,
		"priority": priority,
		"start_time": Time.get_unix_time_from_system()
	}
	
	# Set cooldown
	set_cooldown(npc_id, sound_type)
	
	# Connect finished signal
	if not player.finished.is_connected(_on_sound_finished):
		player.finished.connect(_on_sound_finished.bind(sound_id, npc_id, sound_type))
	
	# Emit signal
	sound_played.emit(npc_id, sound_type, sound_path)
	
	return true

func play_emotion_sound(npc_id: String, emotion: String) -> bool:
	"""Play emotion-based vocalization"""
	if not audio_config.enable_emotion_sounds:
		return false
	
	var sound_path = get_emotion_sound_path(npc_id, emotion)
	if sound_path == "":
		return false
	
	var pitch = get_npc_voice_pitch(npc_id)
	return play_npc_sound(npc_id, "emotion_%s" % emotion, sound_path, 0.0, pitch, 5)

func play_activity_sound(npc_id: String, activity: String) -> bool:
	"""Play activity-related sound"""
	if not audio_config.enable_activity_sounds:
		return false
	
	var sound_path = get_activity_sound_path(npc_id, activity)
	if sound_path == "":
		return false
	
	return play_npc_sound(npc_id, "activity_%s" % activity, sound_path, -3.0, 1.0, 2)

func play_greeting_sound(npc_id: String, mood: String = "neutral") -> bool:
	"""Play greeting sound"""
	var sound_path = get_greeting_sound_path(npc_id, mood)
	if sound_path == "":
		return false
	
	var pitch = get_npc_voice_pitch(npc_id)
	return play_npc_sound(npc_id, "greeting", sound_path, 0.0, pitch, 7)

func play_ambient_sound(location: String) -> bool:
	"""Play ambient sound for location"""
	if not audio_config.enable_ambient_sounds:
		return false
	
	var sound_path = get_ambient_sound_path(location)
	if sound_path == "":
		return false
	
	return play_npc_sound("ambient", "location_%s" % location, sound_path, -10.0, 1.0, 1)

# ============================================
# Audio Context Functions
# ============================================

func should_play_sound(sound_type: String) -> bool:
	"""Check if sound type is enabled"""
	match sound_type:
		"emotion_*":
			return audio_config.enable_emotion_sounds
		"activity_*":
			return audio_config.enable_activity_sounds
		"ambient_*":
			return audio_config.enable_ambient_sounds
		_:
			return true

func is_on_cooldown(npc_id: String, sound_type: String) -> bool:
	"""Check if sound is on cooldown"""
	var key = "%s_%s" % [npc_id, sound_type]
	if sound_cooldowns.has(key):
		var cooldown_info = sound_cooldowns[key]
		var elapsed = Time.get_unix_time_from_system() - cooldown_info.time
		if elapsed < cooldown_info.duration:
			return true
		else:
			sound_cooldowns.erase(key)
	return false

func set_cooldown(npc_id: String, sound_type: String, duration: float = DEFAULT_COOLDOWN):
	"""Set cooldown for sound"""
	var key = "%s_%s" % [npc_id, sound_type]
	sound_cooldowns[key] = {
		"time": Time.get_unix_time_from_system(),
		"duration": duration
	}

func find_available_player(priority: int) -> AudioStreamPlayer:
	"""Find an available audio player"""
	# First, look for stopped players
	for player in audio_players:
		if not player.playing:
			return player
	
	# If all playing, check if we can interrupt low priority
	return null

func stop_lowest_priority_sound() -> AudioStreamPlayer:
	"""Stop the lowest priority sound to make room"""
	var lowest_priority = 999
	var lowest_sound_id = ""
	
	for sound_id in active_sounds:
		var info = active_sounds[sound_id]
		if info.priority < lowest_priority:
			lowest_priority = info.priority
			lowest_sound_id = sound_id
	
	if lowest_sound_id != "":
		var info = active_sounds[lowest_sound_id]
		info.player.stop()
		active_sounds.erase(lowest_sound_id)
		return info.player
	
	return null

func calculate_volume_adjustment(sound_type: String) -> float:
	"""Calculate volume adjustment based on sound type and config"""
	var base_volume = audio_config.sfx_volume * audio_config.master_volume
	
	match sound_type:
		"greeting":
			return linear_to_db(base_volume * audio_config.voice_volume)
		"emotion_*":
			return linear_to_db(base_volume * audio_config.voice_volume * 0.8)
		"activity_*":
			return linear_to_db(base_volume * 0.6)
		"ambient_*":
			return linear_to_db(base_volume * audio_config.ambient_volume)
		_:
			return linear_to_db(base_volume)

func get_npc_voice_pitch(npc_id: String) -> float:
	"""Get NPC's characteristic voice pitch"""
	if EnhancedPersonalitySystem:
		var profile = EnhancedPersonalitySystem.get_npc_complete_profile(npc_id)
		return profile.get("audio_profile", {}).get("voice_pitch", 1.0)
	return 1.0

# ============================================
# Sound Path Resolution
# ============================================

func get_emotion_sound_path(npc_id: String, emotion: String) -> String:
	"""Get path to emotion sound file"""
	if EnhancedPersonalitySystem:
		return EnhancedPersonalitySystem.get_audio_file(npc_id, "emotion", emotion)
	
	# Fallback to generic sounds
	var emotion_sounds = {
		"happy": "res://assets/audio/sfx/laugh_light.wav",
		"excited": "res://assets/audio/sfx/excited_vocal.wav",
		"sad": "res://assets/audio/sfx/sigh_disappointed.wav",
		"angry": "res://assets/audio/sfx/frustrated.wav",
		"surprised": "res://assets/audio/sfx/gasp.wav",
		"thinking": "res://assets/audio/sfx/hmm.wav"
	}
	return emotion_sounds.get(emotion, "")

func get_activity_sound_path(npc_id: String, activity: String) -> String:
	"""Get path to activity sound file"""
	if EnhancedPersonalitySystem:
		return EnhancedPersonalitySystem.get_audio_file(npc_id, "activity", activity)
	
	# Fallback
	var activity_sounds = {
		"working": "res://assets/audio/sfx/work_tools.wav",
		"farming": "res://assets/audio/sfx/hoe_dig.wav",
		"cleaning": "res://assets/audio/sfx/cleaning_swipe.wav",
		"walking": "res://assets/audio/sfx/footsteps_grass.wav",
		"reading": "res://assets/audio/sfx/page_turn.wav"
	}
	return activity_sounds.get(activity, "")

func get_greeting_sound_path(npc_id: String, mood: String) -> String:
	"""Get path to greeting sound"""
	var greeting_sounds = {
		"happy": "res://assets/audio/sfx/happy_greeting.wav",
		"neutral": "res://assets/audio/sfx/neutral_greeting.wav",
		"sad": "res://assets/audio/sfx/sad_greeting.wav"
	}
	return greeting_sounds.get(mood, greeting_sounds.neutral)

func get_ambient_sound_path(location: String) -> String:
	"""Get path to ambient location sound"""
	var ambient_sounds = {
		"shop": "res://assets/audio/ambience/shop_murmur.wav",
		"farm": "res://assets/audio/ambience/birds_chirp.wav",
		"town": "res://assets/audio/ambience/town_fountain.wav",
		"forest": "res://assets/audio/ambience/forest_wind.wav",
		"mountain": "res://assets/audio/ambience/mountain_echo.wav"
	}
	return ambient_sounds.get(location, "")

# ============================================
# Signal Handlers
# ============================================

func _on_sound_finished(sound_id: String, npc_id: String, sound_type: String):
	"""Handle sound completion"""
	if active_sounds.has(sound_id):
		active_sounds.erase(sound_id)
		sound_finished.emit(npc_id, sound_type)

# ============================================
# Utility Functions
# ============================================

func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels"""
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10)

func stop_all_sounds_for_npc(npc_id: String):
	"""Stop all sounds for a specific NPC"""
	var to_remove = []
	for sound_id in active_sounds:
		if active_sounds[sound_id].npc_id == npc_id:
			active_sounds[sound_id].player.stop()
			to_remove.append(sound_id)
	
	for sound_id in to_remove:
		active_sounds.erase(sound_id)

func stop_all_sounds():
	"""Stop all currently playing sounds"""
	for player in audio_players:
		player.stop()
	active_sounds.clear()

func set_volume_for_category(category: String, volume: float):
	"""Set volume for a specific category"""
	match category:
		"master":
			audio_config.master_volume = clamp(volume, 0.0, 1.0)
		"sfx":
			audio_config.sfx_volume = clamp(volume, 0.0, 1.0)
		"ambient":
			audio_config.ambient_volume = clamp(volume, 0.0, 1.0)
		"voice":
			audio_config.voice_volume = clamp(volume, 0.0, 1.0)
	
	save_audio_config()

func toggle_sound_category(category: String, enabled: bool):
	"""Enable or disable a sound category"""
	match category:
		"emotion":
			audio_config.enable_emotion_sounds = enabled
		"activity":
			audio_config.enable_activity_sounds = enabled
		"ambient":
			audio_config.enable_ambient_sounds = enabled
	
	save_audio_config()

func get_active_sound_count() -> int:
	"""Get number of currently playing sounds"""
	return active_sounds.size()

func get_audio_status() -> Dictionary:
	"""Get current audio system status"""
	return {
		"active_sounds": get_active_sound_count(),
		"config": audio_config.duplicate(),
		"cooldowns": sound_cooldowns.size()
	}
