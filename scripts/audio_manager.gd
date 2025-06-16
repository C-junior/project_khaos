extends Node
class_name AudioManager

# --- Nodes ---
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer # For one-shot sound effects
var sfx_player_pool_size: int = 5 # Pool for multiple overlapping SFX
var sfx_player_pool: Array[AudioStreamPlayer] = []
var sfx_player_index: int = 0

# --- Volume Settings (examples, can be exposed via options menu) ---
@export var music_volume_db: float = -10.0 # Default music volume in dB
@export var sfx_volume_db: float = -5.0   # Default SFX volume in dB

# --- Resource Storage (conceptual - actual loading needs more) ---
# In a real game, you'd likely have these paths in a dictionary or preload them.
# For this example, we'll just use string names passed directly to play functions,
# and those functions will try to load "res://assets/sound/{name}.wav" or "res://assets/music/{name}.mp3"
# This part is highly dependent on actual asset paths and types.

func _ready():
	# Create Music Player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.name = "MusicPlayer"
	music_player.bus = "Master" # Or a specific "Music" bus if you set one up in Godot Audio tab
	music_player.volume_db = music_volume_db

	# Create SFX Player Pool
	for i in range(sfx_player_pool_size):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		add_child(player)
		player.bus = "Master" # Or a specific "SFX" bus
		player.volume_db = sfx_volume_db
		sfx_player_pool.append(player)

	# sfx_player will point to the next available player in the pool
	sfx_player = sfx_player_pool[0] if sfx_player_pool_size > 0 else null

	print("Audio Manager ready. Music Volume: %s dB, SFX Volume: %s dB" % [music_volume_db, sfx_volume_db])

# --- Music Playback ---
func play_music(music_name: String, loop: bool = true, fade_in_time: float = 0.5):
	if not music_player:
		printerr("AudioManager: MusicPlayer not found!")
		return

	if music_name.is_empty():
		music_player.stop()
		print("AudioManager: Stopping music.")
		return

	var music_path = "res://assets/music/%s.ogg" % music_name # Assuming .ogg for music
	# In a real game, you'd check if path exists or use a resource preloader.
	var stream = load(music_path) as AudioStream

	if stream:
		if music_player.stream == stream and music_player.playing:
			print("AudioManager: Music '%s' is already playing." % music_name)
			return

		music_player.stream = stream
		music_player.play() # Godot's AudioStreamPlayer doesn't have built-in fade in on play.
		                # A Tween node could be used for custom fade effects if needed.
		print("AudioManager: Playing music '%s'." % music_name)
		if not loop: # Godot AudioStreamOGGVorbis loops by default if 'loop' is true in import settings.
			# To ensure it doesn't loop if loop=false, you might need to handle 'finished' signal.
			# For simplicity, we assume import settings control looping for .ogg.
			pass
	else:
		printerr("AudioManager: Could not load music '%s' from path '%s'." % [music_name, music_path])

func stop_music(fade_out_time: float = 0.5):
	if music_player and music_player.playing:
		# Implement fade out with Tween if needed, for now, just stop.
		music_player.stop()
		print("AudioManager: Music stopped.")

func set_music_volume(volume_db_value: float):
	music_volume_db = volume_db_value
	if music_player:
		music_player.volume_db = music_volume_db
	print("AudioManager: Music volume set to %s dB." % volume_db_value)

# --- SFX Playback ---
func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0):
	if sfx_player_pool.is_empty():
		printerr("AudioManager: SFX Player pool is empty!")
		return

	var sfx_path = "res://assets/sound/%s.wav" % sfx_name # Assuming .wav for SFX
	var stream = load(sfx_path) as AudioStream

	if stream:
		# Get next player from pool
		sfx_player = sfx_player_pool[sfx_player_index]
		sfx_player_index = (sfx_player_index + 1) % sfx_player_pool_size

		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch_scale
		sfx_player.volume_db = sfx_volume_db + volume_offset_db # Apply temporary offset if needed
		sfx_player.play()
		# print("AudioManager: Playing SFX '%s'." % sfx_name) # Can be too verbose
	else:
		printerr("AudioManager: Could not load SFX '%s' from path '%s'." % [sfx_name, sfx_path])

func set_sfx_volume(volume_db_value: float):
	sfx_volume_db = volume_db_value
	for player in sfx_player_pool:
		player.volume_db = sfx_volume_db
	print("AudioManager: SFX volume set to %s dB." % volume_db_value)

# --- Global Access (Optional Singleton Pattern) ---
# static var instance: AudioManager = null
# func _enter_tree():
#   if instance == null:
#       instance = self
#   else:
#       printerr("AudioManager: Singleton instance already exists. Destroying new one.")
#       queue_free()

# Example: AudioManager.instance.play_sfx("hit")
# For this task, Game.gd will hold a reference, so singleton pattern isn't strictly needed yet.
