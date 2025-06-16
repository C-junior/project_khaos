extends Node
class_name StageManager

# Signals for game flow
signal stage_started(stage_number)
signal stage_completed(stage_number)
signal all_stages_completed
signal wave_started(wave_number)
signal wave_completed(wave_number)
signal artifact_dropped(artifact_resource) # Emitted when an artifact is chosen/dropped

# Dependencies (will be set by Game.gd or an initializer)
var combat_manager: CombatManager
var enemy_spawner: EnemySpawner
var game_node # To access game-level things like player party
var audio_manager # Added AudioManager reference

# Stage configuration
# Example: [{ "waves": [ {"enemies": ["goblin", "orc"]}, {"enemies": ["orc_brute"]} ], "environment_effect": null, "artifact_reward_pool": ["moonlit_scepter", "bloodthorn_dagger"] }, ... ]
var stage_definitions: Array = []
var current_stage_index: int = -1
var current_wave_index: int = -1

# Available artifacts (paths to their .gd or .tres files if they are resources)
# For now, using script paths as identifiers. Ideally, these would be resource paths.
var available_artifact_scripts: Dictionary = {
	"moonlit_scepter": "res://scripts/moonlit_scepter.gd",
	"bloodthorn_dagger": "res://scripts/bloodthorn_dagger.gd",
	"crimson_veil": "res://scripts/crimson_veil.gd" # Added Crimson Veil
}

# Placeholders for fragment rewards - these would resolve to the same "crimson_veil" script path
# but the RewardManager or a global tracker would handle the fragment count.
# For this simplified version, we'll grant the full veil later.
# "crimson_veil_fragment_1": "res://scripts/crimson_veil.gd",
# "crimson_veil_fragment_2": "res://scripts/crimson_veil.gd",
# "crimson_veil_fragment_3": "res://scripts/crimson_veil.gd",


func _ready():
	print("Stage Manager ready.")
	# Define stages programmatically for now.
	# In a real game, this might be loaded from a JSON file or custom Resource.
	# Enemy types used: "goblin_grunt", "orc_brute", "elara_clone" (from EnemySpawner)
	# New enemy types for future stages (need to be added to EnemySpawner.enemy_type_data):
	# "wraith", "skeleton_warrior", "cultist_acolyte", "demon_imp", "lava_elemental", "lilithar_boss"

	stage_definitions = [
		{
			"name": "Training Grounds", # Renamed first stage
			"scene_file": null, # No specific scene file, uses default background
			"waves": [
				{"enemies": [{"type": "goblin_grunt", "count": 1}], "description": "A lone Goblin Grunt"},
				{"enemies": [{"type": "goblin_grunt", "count": 2}], "description": "A couple of Goblin Grunts"}
			],
			"environment_effect": null,
			"artifact_reward_pool": ["moonlit_scepter"] # Initial easy artifact
		},
		{
			"name": "Forgotten Path", # Renamed second stage
			"scene_file": null,
			"waves": [
				{"enemies": [{"type": "goblin_grunt", "count": 1}, {"type": "orc_brute", "count": 1}], "description": "A Goblin and an Orc"},
				{"enemies": [{"type": "orc_brute", "count": 2}], "description": "Two Orc Brutes"}
			],
			"environment_effect": null,
			"artifact_reward_pool": ["bloodthorn_dagger"]
		},
		{
			"name": "Haunted Woods",
			"scene_file": "res://scenes/haunted_woods.tscn", # Path to visual scene
			"waves": [
				{"enemies": [{"type": "wraith", "count": 2}], "description": "Wispy Wraiths"}, # New enemy type
				{"enemies": [{"type": "skeleton_warrior", "count": 1}, {"type": "wraith", "count": 1}], "description": "A Skeleton and a Wraith"}, # New enemy types
				{"enemies": [{"type": "elara_clone", "count": 1, "name_override": "Forest Spirit"}], "description": "A vengeful Forest Spirit"}
			],
			"environment_effect": {"type": "supernatural_dread", "description": "Supernatural Dread: All characters have -1 Speed.", "stat_modifiers": {"all": {"speed": -1}}},
			"artifact_reward_pool": ["crimson_veil_fragment_1"] # Placeholder for fragment
		},
		{
			"name": "Cursed Cathedral",
			"scene_file": "res://scenes/cursed_cathedral.tscn",
			"waves": [
				{"enemies": [{"type": "cultist_acolyte", "count": 3}], "description": "Acolytes of the Damned"}, # New enemy type
				{"enemies": [{"type": "skeleton_warrior", "count": 2}, {"type": "cultist_acolyte", "count": 1}], "description": "Skeletal Guardians and an Acolyte"},
				{"enemies": [{"type": "wraith", "count": 1, "name_override": "Cathedral Guardian"}, {"type": "cultist_acolyte", "count": 2}], "description": "A powerful Cathedral Guardian and Acolytes"}
			],
			"environment_effect": {"type": "desacrated_ground", "description": "Desacrated Ground: Healing effects are 50% less effective.", "gameplay_modifiers": {"healing_effectiveness_multiplier": 0.5}},
			"artifact_reward_pool": ["crimson_veil_fragment_2"] # Placeholder for fragment
		},
		{
			"name": "Infernal Wastes",
			"scene_file": "res://scenes/infernal_wastes.tscn",
			"waves": [
				{"enemies": [{"type": "demon_imp", "count": 3}], "description": "Swarm of Demon Imps"}, # New enemy type
				{"enemies": [{"type": "lava_elemental", "count": 2}], "description": "Burning Lava Elementals"}, # New enemy type
				{"enemies": [{"type": "orc_brute", "count": 1, "name_override": "Infernal Champion"}, {"type": "demon_imp", "count": 2}], "description": "An Infernal Champion leading Imps"}
			],
			"environment_effect": {"type": "scorching_heat", "description": "Scorching Heat: All characters take 5 damage at the start of their turn.", "turn_start_damage": {"all": 5}},
			"artifact_reward_pool": ["crimson_veil_fragment_3"] # Placeholder for fragment
		},
		{
			"name": "Abyssal Citadel",
			"scene_file": "res://scenes/abyssal_citadel.tscn",
			"waves": [
				{"enemies": [{"type": "demon_imp", "count": 2}, {"type": "lava_elemental", "count": 1}], "description": "Guardians of the Approach"},
				{"enemies": [{"type": "cultist_acolyte", "count": 2, "name_override": "Lilithar's Chosen"}, {"type": "wraith", "count": 2, "name_override": "Tormented Soul"}], "description": "Lilithar's Chosen and their escorts"},
				{"enemies": [{"type": "lilithar_boss", "count": 1}], "description": "Lilithar, Empress of Torment"}
			],
			"environment_effect": {"type": "abyssal_presence", "description": "Abyssal Presence: All player characters feel an oppressive dread. -5% to all stats.", "stat_multipliers": {"player_party": {"max_hp": 0.95, "attack_power": 0.95, "defense": 0.95}}},
			"artifact_reward_pool": [] # No artifact reward, game ends or goes to epilogue
		}
	]

# Setter for dependencies, including a reference to the main game node
func set_dependencies(cm: CombatManager, es: EnemySpawner, gn: Node, am = null): # AudioManager added
	combat_manager = cm
	enemy_spawner = es
	game_node = gn # Store the reference to the Game.gd node
	audio_manager = am
	if not audio_manager:
		printerr("StageManager: AudioManager dependency not set!")
	if combat_manager:
		# Connect to combat_ended signal to know when to proceed
		if not combat_manager.is_connected("combat_ended", Callable(self, "_on_combat_ended")) :
			combat_manager.combat_ended.connect(_on_combat_ended)
	else:
		printerr("StageManager: CombatManager dependency not set!")

	if not enemy_spawner:
		printerr("StageManager: EnemySpawner dependency not set!")


func start_first_stage():
	current_stage_index = -1
	start_next_stage()

func start_next_stage():
	current_stage_index += 1
	if current_stage_index >= stage_definitions.size():
		emit_signal("all_stages_completed")
		print("All stages completed!")
		# Handle game completion or loop back, etc.
		return

	current_wave_index = -1
	var stage_data = stage_definitions[current_stage_index]
	emit_signal("stage_started", current_stage_index + 1) # User-friendly stage number
	print("Starting Stage %s: %s" % [current_stage_index + 1, stage_data.name])

	if audio_manager:
		var music_name = stage_data.get("music", "default_battle_music") # Get stage specific music or default
		if stage_data.name.contains("Woods"): music_name = "haunted_woods_music" # Example specific
		elif stage_data.name.contains("Cathedral"): music_name = "cursed_cathedral_music"
		elif stage_data.name.contains("Wastes"): music_name = "infernal_wastes_music"
		elif stage_data.name.contains("Citadel"): music_name = "abyssal_citadel_music"
		audio_manager.play_music(music_name)

	# Apply environment effects if any (conceptual for now)
	# apply_environment_effect(stage_data.environment_effect)

	spawn_next_wave()

func spawn_next_wave():
	if not enemy_spawner:
		printerr("Enemy Spawner not set in StageManager!")
		return

	current_wave_index += 1
	var stage_data = stage_definitions[current_stage_index]
	if current_wave_index >= stage_data.waves.size():
		# All waves for this stage cleared
		emit_signal("stage_completed", current_stage_index + 1)
		print("Stage %s completed." % (current_stage_index + 1))
		drop_artifact() # Offer artifact reward
		# Then proceed to next stage or wait for player input
		# For now, automatically start next stage after a delay or input
		# call_deferred("start_next_stage") # Example: auto-proceed
		return

	emit_signal("wave_started", current_wave_index + 1)
	var wave_data = stage_data.waves[current_wave_index]
	print("Starting Wave %s for Stage %s: %s" % [current_wave_index + 1, current_stage_index + 1, wave_data.description])

	var enemy_party_for_wave = enemy_spawner.spawn_wave(wave_data.enemies)

	if enemy_party_for_wave.is_empty():
		printerr("Failed to spawn enemies for the wave!")
		# Potentially skip wave or error out
		call_deferred("spawn_next_wave") # Try next wave if this one is empty
		return

	# Assume player party is already known by CombatManager or passed in by Game.gd
	# For now, Game.gd will set the player party once.
	# CombatManager.setup_combat should be called by Game.gd or here.
	# This part needs careful orchestration with Game.gd and CombatManager

	# This is a key integration point: Game.gd should probably drive the setup
	# and then call combat_manager.start_combat()
	# For now, StageManager tells CombatManager to get ready with the new enemies
	if not game_node or not game_node.has_method("get_player_party"):
		printerr("StageManager: Game node is not set or doesn't have get_player_party(). Cannot start combat.")
		return

	var current_player_party = game_node.get_player_party()
	if current_player_party.is_empty():
		printerr("StageManager: Player party is empty. Cannot start combat.")
		return

	# Check for Lilithar and apply Crimson Veil effect if necessary
	for enemy in enemy_party_for_wave:
		if enemy is Lilithar: # Check if the enemy node is specifically Lilithar
			var lilithar_node = enemy as Lilithar
			var veil_relic = null
			if game_node.has_method("get_player_crimson_veil"): # Check if method exists
				veil_relic = game_node.get_player_crimson_veil()

			if is_instance_valid(veil_relic) and veil_relic.is_fully_formed:
				print_rich("[StageManager] Player possesses the fully formed Crimson Veil. Applying effect to Lilithar.")
				lilithar_node.check_for_crimson_veil(true)
			else:
				lilithar_node.check_for_crimson_veil(false) # Ensure she's not weakened if veil not present/formed
			break # Assuming only one Lilithar

	if combat_manager.setup_combat(current_player_party, enemy_party_for_wave):
		combat_manager.start_combat()
	else:
		printerr("StageManager: Failed to setup combat for the new wave.")
		# Handle error, maybe retry or end game


func _on_combat_ended(result: String):
	print("StageManager received combat_ended signal with result: %s" % result)
	if result == "player_victory":
		emit_signal("wave_completed", current_wave_index + 1)
		print("Wave %s completed." % (current_wave_index + 1))
		enemy_spawner.cleanup_current_wave_enemies()
		call_deferred("spawn_next_wave")
	elif result == "enemy_victory":
		print("Player defeated in Stage %s, Wave %s." % [current_stage_index + 1, current_wave_index + 1])
		if audio_manager: audio_manager.play_music("defeat_jingle", false) # Play defeat music, don't loop
	else:
		print("Combat ended with non-standard result: %s. No progression." % result)

func _on_stage_completed_actions(): # Helper to avoid direct call_deferred in multiple places if logic grows
    # This is called after artifact drop, before starting next stage
	if audio_manager: audio_manager.play_sfx("stage_clear_fanfare") # Play once after stage is fully done
	# Any other logic before starting next stage (e.g. saving, specific UI)
	start_next_stage()


func drop_artifact():
	var stage_data = stage_definitions[current_stage_index]
	var reward_pool: Array = stage_data.get("artifact_reward_pool", [])

	if reward_pool.is_empty():
		print("No artifact rewards for this stage.")
		return

	var chosen_artifact_id = reward_pool.pick_random()
	var artifact_script_path = available_artifact_scripts.get(chosen_artifact_id)

	if not artifact_script_path:
		printerr("Artifact ID '%s' not found in available_artifact_scripts." % chosen_artifact_id)
		return

	# Artifacts are resources. We can create an instance of the script.
	# This assumes the artifact scripts extend Resource and have a class_name.
	var ArtifactClass = load(artifact_script_path)
	if ArtifactClass:
		var new_artifact = ArtifactClass.new()
		if new_artifact is BaseArtifact:
			print("Dropped artifact: %s" % new_artifact.artifact_name)
			if audio_manager: audio_manager.play_sfx("artifact_get_sfx")
			emit_signal("artifact_dropped", new_artifact)
		else:
			printerr("Failed to instantiate artifact: %s. Loaded script is not a BaseArtifact." % chosen_artifact_id)
	else:
		printerr("Failed to load artifact script: %s" % artifact_script_path)

	# After artifact logic (or if no artifact), proceed to next stage actions
	call_deferred("_on_stage_completed_actions")


# Placeholder for environment effects
# func apply_environment_effect(effect_data):
# 	if effect_data:
# 		print("Applying environment effect: %s" % effect_data.type)
# 		# This would modify global parameters or apply effects to all current/future combatants
# 		# For example, if effect_data.stat_modifier = {"defense": -2},
# 		# you might iterate through player_party and apply this.
# 		# This is complex and needs careful design for application and removal.
# 		pass

func get_current_stage_number() -> int:
	return current_stage_index + 1

func get_current_wave_number() -> int:
	return current_wave_index + 1
