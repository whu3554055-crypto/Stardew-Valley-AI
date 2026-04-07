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
	"enable_ambient_sounds": true,
	"backend_tts_enabled": true,
	"backend_base_url": "http://localhost:8080/api/v1",
	"tts_timeout_seconds": 4.0
}

# Currently playing sounds tracking
var active_sounds = {}

# Sound cooldowns to prevent spam
var sound_cooldowns = {}
const DEFAULT_COOLDOWN = 2.0

signal sound_played(npc_id, sound_type, sound_path)
signal sound_finished(npc_id, sound_type)
signal tts_requested(npc_id, text, emotion)
signal tts_fallback_used(npc_id, text)
signal tts_result_received(npc_id, mode, payload)
signal tts_metrics_updated(npc_id, metrics)

var tts_queue_by_npc: Dictionary = {}
var tts_request_by_npc: Dictionary = {}
var pending_tts_context_by_npc: Dictionary = {}
var tts_in_flight_by_npc: Dictionary = {}
var last_tts_by_npc: Dictionary = {}
var tts_lane_last_active: Dictionary = {}
var tts_lane_request_started_at: Dictionary = {}
var tts_metrics_total: Dictionary = {
	"requested": 0,
	"success": 0,
	"fallback": 0,
	"timeouts_or_stalls": 0,
	"lane_rebuilds": 0
}
var tts_metrics_by_npc: Dictionary = {}
const TTS_MIN_INTERVAL_SECONDS = 0.35
const TTS_INTERRUPT_PRIORITY = 8
var tts_max_parallel_npc: int = 3
const TTS_LANE_IDLE_TIMEOUT_SECONDS = 45.0
const TTS_REQUEST_STALL_SECONDS = 12.0
var tts_cleanup_timer: Timer = null
var tts_metrics_flush_timer: Timer = null
const TTS_METRICS_SAVE_PATH = "user://tts_metrics_snapshot.json"
var tts_adaptive_timer: Timer = null

func _ready():
	initialize_audio_pool()
	initialize_tts_client()
	load_audio_config()
	_initialize_tts_cleanup_timer()
	_initialize_tts_metrics_flush_timer()
	_load_tts_metrics_snapshot()
	_initialize_tts_adaptive_timer()

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

func initialize_tts_client():
	"""Initialize TTS lane maps (one HTTPRequest per NPC lane)."""
	tts_queue_by_npc.clear()
	tts_request_by_npc.clear()
	pending_tts_context_by_npc.clear()
	tts_in_flight_by_npc.clear()
	tts_lane_last_active.clear()
	tts_lane_request_started_at.clear()
	tts_metrics_by_npc.clear()

func _ensure_npc_metrics(npc_id: String):
	if tts_metrics_by_npc.has(npc_id):
		return
	tts_metrics_by_npc[npc_id] = {
		"requested": 0,
		"success": 0,
		"fallback": 0,
		"timeouts_or_stalls": 0,
		"lane_rebuilds": 0
	}

func _bump_tts_metric(npc_id: String, key: String):
	_ensure_npc_metrics(npc_id)
	tts_metrics_total[key] = int(tts_metrics_total.get(key, 0)) + 1
	var npc_metrics = tts_metrics_by_npc[npc_id]
	npc_metrics[key] = int(npc_metrics.get(key, 0)) + 1
	tts_metrics_by_npc[npc_id] = npc_metrics
	tts_metrics_updated.emit(npc_id, npc_metrics)

func _initialize_tts_cleanup_timer():
	"""Periodically cleanup idle per-NPC TTS lanes."""
	tts_cleanup_timer = Timer.new()
	tts_cleanup_timer.wait_time = 10.0
	tts_cleanup_timer.one_shot = false
	tts_cleanup_timer.timeout.connect(_cleanup_idle_tts_lanes)
	add_child(tts_cleanup_timer)
	tts_cleanup_timer.start()

func _initialize_tts_metrics_flush_timer():
	"""Persist TTS metrics periodically for post-restart analysis."""
	tts_metrics_flush_timer = Timer.new()
	tts_metrics_flush_timer.wait_time = 30.0
	tts_metrics_flush_timer.one_shot = false
	tts_metrics_flush_timer.timeout.connect(_save_tts_metrics_snapshot)
	add_child(tts_metrics_flush_timer)
	tts_metrics_flush_timer.start()

func _initialize_tts_adaptive_timer():
	"""Adapt TTS lane concurrency based on runtime FPS."""
	tts_adaptive_timer = Timer.new()
	tts_adaptive_timer.wait_time = 5.0
	tts_adaptive_timer.one_shot = false
	tts_adaptive_timer.timeout.connect(_update_tts_parallel_limit)
	add_child(tts_adaptive_timer)
	tts_adaptive_timer.start()

func _update_tts_parallel_limit():
	# Lightweight rule-of-thumb tuning. Keeps gameplay responsive first.
	var fps = Engine.get_frames_per_second()
	if fps <= 35.0:
		tts_max_parallel_npc = 1
	elif fps <= 50.0:
		tts_max_parallel_npc = 2
	else:
		tts_max_parallel_npc = 3

func _save_tts_metrics_snapshot():
	"""Save aggregated/per-NPC TTS metrics to disk."""
	var payload = {
		"saved_at": Time.get_unix_time_from_system(),
		"total": tts_metrics_total,
		"by_npc": tts_metrics_by_npc
	}
	var file = FileAccess.open(TTS_METRICS_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))
		file.close()

func _load_tts_metrics_snapshot():
	"""Load metrics snapshot from previous sessions if available."""
	if not FileAccess.file_exists(TTS_METRICS_SAVE_PATH):
		return
	var file = FileAccess.open(TTS_METRICS_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var total_loaded = parsed.get("total", {})
	var by_npc_loaded = parsed.get("by_npc", {})
	if typeof(total_loaded) == TYPE_DICTIONARY:
		for key in tts_metrics_total.keys():
			tts_metrics_total[key] = int(total_loaded.get(key, 0))
	if typeof(by_npc_loaded) == TYPE_DICTIONARY:
		tts_metrics_by_npc = by_npc_loaded.duplicate(true)

func _can_enqueue_tts(npc_id: String) -> bool:
	var now_ts = Time.get_unix_time_from_system()
	var last_ts = float(last_tts_by_npc.get(npc_id, 0.0))
	return now_ts - last_ts >= TTS_MIN_INTERVAL_SECONDS

func _enqueue_tts_request(npc_id: String, text: String, emotion: String, priority: int = 0):
	if priority >= TTS_INTERRUPT_PRIORITY:
		_prune_lower_priority_for_npc(npc_id, priority)
	if not tts_queue_by_npc.has(npc_id):
		tts_queue_by_npc[npc_id] = []
	var lane_queue: Array = tts_queue_by_npc[npc_id]
	lane_queue.append({
		"npc_id": npc_id,
		"text": text,
		"emotion": emotion,
		"priority": priority,
		"created_at": Time.get_unix_time_from_system()
	})
	# Highest priority first, then oldest request first (per NPC lane)
	lane_queue.sort_custom(func(a, b):
		if a.priority == b.priority:
			return a.created_at < b.created_at
		return a.priority > b.priority
	)
	tts_queue_by_npc[npc_id] = lane_queue
	tts_lane_last_active[npc_id] = Time.get_unix_time_from_system()

func _prune_lower_priority_for_npc(npc_id: String, min_priority: int):
	"""When a high-priority line arrives, drop weaker queued lines for the same NPC."""
	if not tts_queue_by_npc.has(npc_id):
		return
	var filtered: Array = []
	for item in tts_queue_by_npc[npc_id]:
		var low_priority = int(item.get("priority", 0)) < min_priority
		if low_priority:
			continue
		filtered.append(item)
	tts_queue_by_npc[npc_id] = filtered

func _get_or_create_npc_tts_request(npc_id: String) -> HTTPRequest:
	if tts_request_by_npc.has(npc_id):
		return tts_request_by_npc[npc_id]
	if tts_request_by_npc.size() >= tts_max_parallel_npc:
		return null
	var req = HTTPRequest.new()
	add_child(req)
	req.timeout = audio_config.get("tts_timeout_seconds", 4.0)
	req.request_completed.connect(_on_tts_request_completed.bind(npc_id))
	tts_request_by_npc[npc_id] = req
	tts_lane_last_active[npc_id] = Time.get_unix_time_from_system()
	return req

func _process_tts_queue():
	for npc_id in tts_queue_by_npc.keys():
		var lane_queue: Array = tts_queue_by_npc.get(npc_id, [])
		if lane_queue.is_empty():
			continue
		if bool(tts_in_flight_by_npc.get(npc_id, false)):
			continue
		var lane_req = _get_or_create_npc_tts_request(npc_id)
		if lane_req == null:
			continue
		if lane_req.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
			continue
		
		var next_req = lane_queue.pop_front()
		tts_queue_by_npc[npc_id] = lane_queue
		if _should_preempt_current(next_req):
			_force_end_current_tts("preempted_by_higher_priority")
		pending_tts_context_by_npc[npc_id] = next_req
		tts_in_flight_by_npc[npc_id] = true
		last_tts_by_npc[npc_id] = Time.get_unix_time_from_system()
		tts_lane_last_active[npc_id] = Time.get_unix_time_from_system()
		tts_lane_request_started_at[npc_id] = Time.get_unix_time_from_system()
		
		var request_body = {
			"npc_id": next_req.npc_id,
			"text": next_req.text,
			"emotion": next_req.emotion
		}
		var err = lane_req.request(
			audio_config.get("backend_base_url", "http://localhost:8080/api/v1") + "/tts/generate",
			["Content-Type: application/json"],
			HTTPClient.METHOD_POST,
			JSON.stringify(request_body)
		)
		if err != OK:
			tts_in_flight_by_npc[npc_id] = false
			var fallback_ok = play_greeting_sound(next_req.npc_id, next_req.emotion if next_req.emotion in ["happy", "neutral", "sad"] else "neutral")
			if not fallback_ok:
				tts_fallback_used.emit(next_req.npc_id, next_req.text)
			tts_result_received.emit(next_req.npc_id, "fallback_request_error", {"code": err})
			call_deferred("_process_tts_queue")

func _should_preempt_current(next_req: Dictionary) -> bool:
	"""Decide whether next request should preempt current in-flight context."""
	var cur_npc = next_req.get("npc_id", "")
	if not bool(tts_in_flight_by_npc.get(cur_npc, false)):
		return false
	var cur_ctx = pending_tts_context_by_npc.get(cur_npc, {})
	var cur_pri = int(cur_ctx.get("priority", 0))
	var next_pri = int(next_req.get("priority", 0))
	
	# Only preempt within same NPC voice lane.
	return next_pri >= TTS_INTERRUPT_PRIORITY and next_pri > cur_pri

func _force_end_current_tts(reason: String):
	"""Best-effort cancellation marker for the current request context."""
	for npc_id in pending_tts_context_by_npc.keys():
		if not bool(tts_in_flight_by_npc.get(npc_id, false)):
			continue
		tts_result_received.emit(npc_id, "preempted", {"reason": reason})
		# HTTPRequest has no hard cancel; clear state and continue queue.
		tts_in_flight_by_npc[npc_id] = false
		pending_tts_context_by_npc[npc_id] = {}

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

func clear_tts_queue_for_npc(npc_id: String):
	"""Drop queued (not yet sent) TTS lines for one NPC."""
	tts_queue_by_npc[npc_id] = []
	tts_lane_last_active[npc_id] = Time.get_unix_time_from_system()

func _cleanup_idle_tts_lanes():
	"""Free idle per-NPC HTTPRequest lanes to avoid node growth."""
	var now_ts = Time.get_unix_time_from_system()
	var to_release: Array = []
	var to_heal: Array = []
	
	for npc_id in tts_request_by_npc.keys():
		var in_flight = bool(tts_in_flight_by_npc.get(npc_id, false))
		var queue_size = (tts_queue_by_npc.get(npc_id, []) as Array).size()
		var last_active = float(tts_lane_last_active.get(npc_id, 0.0))
		var idle_for = now_ts - last_active
		var req_started = float(tts_lane_request_started_at.get(npc_id, 0.0))
		var stalled_for = now_ts - req_started
		var lane_req = tts_request_by_npc.get(npc_id, null)
		
		# Self-heal stalled lanes (request seems hung too long).
		if in_flight and req_started > 0.0 and stalled_for > TTS_REQUEST_STALL_SECONDS:
			_bump_tts_metric(npc_id, "timeouts_or_stalls")
			to_heal.append(npc_id)
			continue
		
		# Heal abnormal state: lane object missing/invalid.
		if (lane_req == null or not is_instance_valid(lane_req)) and (in_flight or queue_size > 0):
			to_heal.append(npc_id)
			continue
		
		if in_flight or queue_size > 0:
			continue
		if idle_for < TTS_LANE_IDLE_TIMEOUT_SECONDS:
			continue
		
		to_release.append(npc_id)
	
	for npc_id in to_heal:
		_rebuild_tts_lane(npc_id, "lane_unhealthy_or_stalled")
	
	for npc_id in to_release:
		var req = tts_request_by_npc.get(npc_id, null)
		if req and is_instance_valid(req):
			req.queue_free()
		tts_request_by_npc.erase(npc_id)
		pending_tts_context_by_npc.erase(npc_id)
		tts_in_flight_by_npc.erase(npc_id)
		tts_lane_last_active.erase(npc_id)
		tts_lane_request_started_at.erase(npc_id)
		# Keep last_tts_by_npc for rate-limit continuity.

func _rebuild_tts_lane(npc_id: String, reason: String):
	"""Recreate one NPC lane when it gets stuck/corrupted."""
	var req = tts_request_by_npc.get(npc_id, null)
	if req and is_instance_valid(req):
		req.queue_free()
	
	tts_request_by_npc.erase(npc_id)
	tts_in_flight_by_npc[npc_id] = false
	tts_lane_request_started_at.erase(npc_id)
	
	# Requeue in-flight context to avoid losing dialogue line.
	var pending = pending_tts_context_by_npc.get(npc_id, {})
	if not pending.is_empty():
		var lane_queue: Array = tts_queue_by_npc.get(npc_id, [])
		lane_queue.push_front(pending)
		tts_queue_by_npc[npc_id] = lane_queue
		pending_tts_context_by_npc[npc_id] = {}
	
	tts_result_received.emit(npc_id, "lane_rebuilt", {"reason": reason})
	_bump_tts_metric(npc_id, "lane_rebuilds")
	_get_or_create_npc_tts_request(npc_id)
	call_deferred("_process_tts_queue")

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
		"cooldowns": sound_cooldowns.size(),
		"tts_queue_size": _get_total_tts_queue_size(),
		"tts_in_flight_total": _get_in_flight_lane_count(),
		"tts_lane_count": tts_request_by_npc.size(),
		"tts_stall_threshold_seconds": TTS_REQUEST_STALL_SECONDS,
		"tts_metrics_total": tts_metrics_total.duplicate(true),
		"tts_max_parallel_npc": tts_max_parallel_npc
	}

func get_tts_metrics_for_npc(npc_id: String) -> Dictionary:
	"""Get request-level TTS metrics for one NPC."""
	_ensure_npc_metrics(npc_id)
	return tts_metrics_by_npc[npc_id].duplicate(true)

func get_tts_metrics_summary() -> Dictionary:
	"""Get global and per-NPC TTS metrics summary."""
	return {
		"total": tts_metrics_total.duplicate(true),
		"by_npc": tts_metrics_by_npc.duplicate(true)
	}

func force_flush_tts_metrics():
	"""Manual flush hook for debug/admin tools."""
	_save_tts_metrics_snapshot()

func reset_tts_metrics(npc_id: String = ""):
	"""Reset metrics globally or for a specific NPC lane."""
	if npc_id == "":
		tts_metrics_total = {
			"requested": 0,
			"success": 0,
			"fallback": 0,
			"timeouts_or_stalls": 0,
			"lane_rebuilds": 0
		}
		tts_metrics_by_npc.clear()
		return
	tts_metrics_by_npc.erase(npc_id)

func rebuild_tts_lane_for_npc(npc_id: String):
	"""Manual lane rebuild hook for operator/debug tools."""
	_rebuild_tts_lane(npc_id, "manual_rebuild")

func rebuild_all_tts_lanes():
	"""Manual bulk lane rebuild for recovery scenarios."""
	for npc_id in tts_request_by_npc.keys():
		_rebuild_tts_lane(npc_id, "manual_rebuild_all")

func _get_total_tts_queue_size() -> int:
	var total = 0
	for lane in tts_queue_by_npc.values():
		total += lane.size()
	return total

func _get_in_flight_lane_count() -> int:
	var total = 0
	for is_busy in tts_in_flight_by_npc.values():
		if bool(is_busy):
			total += 1
	return total

func speak_npc_line(npc_id: String, text: String, emotion: String = "neutral", priority: int = 0) -> Dictionary:
	"""
	Lightweight TTS entrypoint for MVP.
	Current behavior: emit request + fallback to local greeting SFX.
	"""
	tts_requested.emit(npc_id, text, emotion)
	_bump_tts_metric(npc_id, "requested")
	
	var backend_tts_enabled = audio_config.get("backend_tts_enabled", true)
	if backend_tts_enabled:
		var is_interrupting = priority >= TTS_INTERRUPT_PRIORITY
		if not is_interrupting and not _can_enqueue_tts(npc_id):
			return {
				"success": true,
				"npc_id": npc_id,
				"emotion": emotion,
				"audio_mode": "tts_rate_limited"
			}
		_enqueue_tts_request(npc_id, text, emotion, priority)
		if is_interrupting:
			# Also stop current local SFX for the speaker to reduce overlap.
			stop_all_sounds_for_npc(npc_id)
		_process_tts_queue()
		return {
			"success": true,
			"npc_id": npc_id,
			"emotion": emotion,
			"audio_mode": "backend_tts_queued",
			"queue_size": _get_total_tts_queue_size()
		}
	
	var greeting_ok = play_greeting_sound(npc_id, emotion if emotion in ["happy", "neutral", "sad"] else "neutral")
	if not greeting_ok:
		tts_fallback_used.emit(npc_id, text)
	_bump_tts_metric(npc_id, "fallback")
	
	return {
		"success": true,
		"npc_id": npc_id,
		"emotion": emotion,
		"audio_mode": "sfx_fallback"
	}

func _on_tts_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, npc_id: String):
	"""Handle backend TTS response and fallback gracefully."""
	var ctx = pending_tts_context_by_npc.get(npc_id, {})
	var text = ctx.get("text", "")
	var emotion = ctx.get("emotion", "neutral")
	
	if result != OK or response_code != 200:
		var fallback_ok = play_greeting_sound(npc_id, emotion if emotion in ["happy", "neutral", "sad"] else "neutral")
		if not fallback_ok:
			tts_fallback_used.emit(npc_id, text)
		tts_result_received.emit(npc_id, "fallback_http_error", {"code": response_code})
		_bump_tts_metric(npc_id, "fallback")
		tts_in_flight_by_npc[npc_id] = false
		tts_lane_request_started_at.erase(npc_id)
		call_deferred("_process_tts_queue")
		return
	
	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		var fallback_ok2 = play_greeting_sound(npc_id, emotion if emotion in ["happy", "neutral", "sad"] else "neutral")
		if not fallback_ok2:
			tts_fallback_used.emit(npc_id, text)
		tts_result_received.emit(npc_id, "fallback_invalid_json", {})
		_bump_tts_metric(npc_id, "fallback")
		tts_in_flight_by_npc[npc_id] = false
		tts_lane_request_started_at.erase(npc_id)
		call_deferred("_process_tts_queue")
		return
	
	var payload = json.data
	var mode = payload.get("fallback_mode", "text_only")
	if mode == "text_only":
		var fallback_ok3 = play_greeting_sound(npc_id, emotion if emotion in ["happy", "neutral", "sad"] else "neutral")
		if not fallback_ok3:
			tts_fallback_used.emit(npc_id, text)
		tts_result_received.emit(npc_id, "fallback_text_only", payload)
		_bump_tts_metric(npc_id, "fallback")
		tts_in_flight_by_npc[npc_id] = false
		tts_lane_request_started_at.erase(npc_id)
		call_deferred("_process_tts_queue")
		return
	
	# Future-ready: if backend returns playable URL, this branch can stream/queue playback.
	tts_result_received.emit(npc_id, "backend_audio_ready", payload)
	_bump_tts_metric(npc_id, "success")
	tts_in_flight_by_npc[npc_id] = false
	tts_lane_last_active[npc_id] = Time.get_unix_time_from_system()
	tts_lane_request_started_at.erase(npc_id)
	call_deferred("_process_tts_queue")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_tts_metrics_snapshot()
