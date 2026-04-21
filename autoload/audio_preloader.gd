extends Node
## AudioPreloader - Intelligent audio preloading and management system.
## Eliminates audio playback delays by preloading common sounds and managing audio pools.
##
## Features:
## - Automatic preloading of common sounds
## - Audio instance pooling
## - Distance-based volume attenuation
## - Priority-based loading
## - Memory usage monitoring

# === 类型定义 ===

class AudioPool:
	var stream: AudioStream
	var instances: Array[AudioStreamPlayer] = []
	var max_instances: int = 5
	var preload_count: int = 3
	
	func _init(p_stream: AudioStream, p_max_instances: int = 5, p_preload_count: int = 3):
		stream = p_stream
		max_instances = p_max_instances
		preload_count = p_preload_count

# === 常量 ===

const MAX_AUDIO_DISTANCE: float = 800.0  # pixels
const VOLUME_ROLLOFF: float = 2.0  # dB per 100 pixels
const DEFAULT_POOL_SIZE: int = 3
const MAX_POOL_SIZE: int = 8

# === 成员变量 ===

var audio_pools: Dictionary = {}  # {sound_id: AudioPool}
var preloaded_sounds: Array[String] = []
var total_plays: int = 0
var cache_hits: int = 0

# === 信号 ===

signal sound_preloaded(sound_id: String)
signal sound_played(sound_id: String, position: Vector2)
signal pool_exhausted(sound_id: String)

# === 生命周期方法 ===

func _ready() -> void:
	if OS.is_debug_build():
		print("[AudioPreloader] Initialized")

# === 公共方法 ===

## Preload a sound effect
func preload_sound(sound_id: String, sound_path: String, pool_size: int = DEFAULT_POOL_SIZE) -> void:
	if audio_pools.has(sound_id):
		return  # Already loaded
	
	var stream = load(sound_path) as AudioStream
	if not stream:
		push_error("[AudioPreloader] Failed to load: %s" % sound_path)
		return
	
	var pool = AudioPool.new(stream, MAX_POOL_SIZE, pool_size)
	
	# Create pooled instances
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = 0.0
		add_child(player)
		pool.instances.append(player)
	
	audio_pools[sound_id] = pool
	preloaded_sounds.append(sound_id)
	
	emit_signal("sound_preloaded", sound_id)
	
	if OS.is_debug_build():
		print("[AudioPreloader] Preloaded: %s (%d instances)" % [sound_id, pool_size])

## Preload multiple sounds at once
func preload_sounds_batch(sounds: Dictionary) -> void:
	# sounds format: {"sound_id": {"path": "res://...", "pool_size": 3}}
	for sound_id in sounds.keys():
		var config = sounds[sound_id]
		preload_sound(sound_id, config.path, config.get("pool_size", DEFAULT_POOL_SIZE))

## Play a preloaded sound (instant playback, no delay)
func play_sound(sound_id: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0) -> bool:
	if not audio_pools.has(sound_id):
		push_warning("[AudioPreloader] Sound not preloaded: %s" % sound_id)
		return false
	
	var pool: AudioPool = audio_pools[sound_id]
	total_plays += 1
	
	# Find available instance
	var player = _get_available_instance(pool)
	
	if not player:
		# Pool exhausted - create temporary instance or wait
		emit_signal("pool_exhausted", sound_id)
		
		# Fallback: create temporary player
		player = AudioStreamPlayer.new()
		player.stream = pool.stream
		add_child(player)
		
		if OS.is_debug_build():
			print("[AudioPreloader] Temporary instance for: %s" % sound_id)
	else:
		cache_hits += 1
	
	# Configure and play
	player.global_position = position
	player.volume_db = volume_db
	player.play()
	
	emit_signal("sound_played", sound_id, position)
	
	return true

## Play sound with distance-based attenuation
func play_sound_with_distance(sound_id: String, sound_position: Vector2, listener_position: Vector2, base_volume: float = 0.0) -> bool:
	var distance = sound_position.distance_to(listener_position)
	
	if distance > MAX_AUDIO_DISTANCE:
		return false  # Too far, don't play
	
	# Calculate volume based on distance
	var volume_drop = (distance / 100.0) * VOLUME_ROLLOFF
	var final_volume = base_volume - volume_drop
	final_volume = clamp(final_volume, -60.0, 0.0)  # Clamp to reasonable range
	
	return play_sound(sound_id, sound_position, final_volume)

## Stop all instances of a sound
func stop_sound(sound_id: String) -> void:
	if not audio_pools.has(sound_id):
		return
	
	var pool: AudioPool = audio_pools[sound_id]
	for player in pool.instances:
		if player.playing:
			player.stop()

## Stop all sounds
func stop_all_sounds() -> void:
	for pool in audio_pools.values():
		for player in pool.instances:
			if player.playing:
				player.stop()

## Unload a sound from memory
func unload_sound(sound_id: String) -> void:
	if not audio_pools.has(sound_id):
		return
	
	var pool: AudioPool = audio_pools[sound_id]
	
	# Free all instances
	for player in pool.instances:
		player.stop()
		player.queue_free()
	
	audio_pools.erase(sound_id)
	preloaded_sounds.erase(sound_id)
	
	if OS.is_debug_build():
		print("[AudioPreloader] Unloaded: %s" % sound_id)

## Get audio statistics
func get_stats() -> Dictionary:
	var total_instances = 0
	var active_instances = 0
	
	for pool in audio_pools.values():
		total_instances += pool.instances.size()
		for player in pool.instances:
			if player.playing:
				active_instances += 1
	
	var hit_rate = 0.0
	if total_plays > 0:
		hit_rate = float(cache_hits) / float(total_plays) * 100.0
	
	return {
		"preloaded_sounds": preloaded_sounds.size(),
		"total_instances": total_instances,
		"active_instances": active_instances,
		"total_plays": total_plays,
		"cache_hits": cache_hits,
		"hit_rate_percent": hit_rate,
		"memory_estimate_mb": _estimate_memory_usage()
	}

## Check if sound is preloaded
func is_preloaded(sound_id: String) -> bool:
	return audio_pools.has(sound_id)

# === 私有方法 ===

func _get_available_instance(pool: AudioPool) -> Variant:
	"""Find an available (not playing) audio instance from pool"""
	for player in pool.instances:
		if not player.playing:
			return player
	
	# All instances busy - check if we can expand pool
	if pool.instances.size() < pool.max_instances:
		var new_player = AudioStreamPlayer.new()
		new_player.stream = pool.stream
		add_child(new_player)
		pool.instances.append(new_player)
		
		if OS.is_debug_build():
			print("[AudioPreloader] Expanded pool for: %s (%d/%d)" % [
				pool.stream.resource_path.get_file(),
				pool.instances.size(),
				pool.max_instances
			])
		
		return new_player
	
	return null  # Pool exhausted

func _estimate_memory_usage() -> float:
	"""Estimate total audio memory usage in MB"""
	var total_bytes = 0
	
	for pool in audio_pools.values():
		if pool.stream:
			# Rough estimate: compressed audio ~100 KB/s
			var duration = pool.stream.get_length() if pool.stream.has_method("get_length") else 1.0
			total_bytes += int(duration * 100000) * pool.instances.size()
	
	return total_bytes / (1024.0 * 1024.0)

## Preload common game sounds (convenience method)
func preload_common_game_sounds() -> void:
	var common_sounds = {
		"ui_click": {"path": "res://assets/audio/ui/click.wav", "pool_size": 5},
		"ui_hover": {"path": "res://assets/audio/ui/hover.wav", "pool_size": 3},
		"step_grass": {"path": "res://assets/audio/footsteps/grass.wav", "pool_size": 4},
		"step_wood": {"path": "res://assets/audio/footsteps/wood.wav", "pool_size": 4},
		"harvest": {"path": "res://assets/audio/actions/harvest.wav", "pool_size": 3},
		"water_splash": {"path": "res://assets/audio/environment/water.wav", "pool_size": 2},
		"bird_chirp": {"path": "res://assets/audio/ambient/birds.wav", "pool_size": 3}
	}
	
	preload_sounds_batch(common_sounds)
	
	if OS.is_debug_build():
		print("[AudioPreloader] Preloaded %d common game sounds" % common_sounds.size())
