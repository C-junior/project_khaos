extends Node2D

# Preload character scenes
const ElaraScene = preload("res://scenes/elara.tscn")
const SylvaraScene = preload("res://scenes/sylvara.tscn")
# BaseCharacterScene is used by EnemySpawner if specific enemy scenes aren't defined there
# const BaseCharacterScene = preload("res://scenes/base_character.tscn")

var combat_manager: CombatManager
var stage_manager: StageManager
var enemy_spawner: EnemySpawner
var score_manager: ScoreManager
var reward_manager: RewardManager
var audio_manager: AudioManager # Added AudioManager

# Reference to the UI script/node
var ui_node # Assuming UI scene is a child of Game node and has script ui.gd
# Example: @onready var ui_node = $UI (if UI is a child node named UI)

var player_party: Array[BaseCharacter] = []
var player_crimson_veil_relic: CrimsonVeilRelic = null # Holds the instance if player has it
# enemy_party is now managed by StageManager/CombatManager via EnemySpawner

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Game scene loaded. Initializing managers and player party...")
	setup_player_party()
	setup_managers()

	# StageManager now controls combat initiation
	stage_manager.start_first_stage()

func setup_player_party():
	# Player Party
	var elara = ElaraScene.instantiate() as BaseCharacter
	elara.position = Vector2(200, 300) # Example position
	add_child(elara) # Add to scene tree so it's visible and processes
	player_party.append(elara)

	var sylvara = SylvaraScene.instantiate() as BaseCharacter
	sylvara.position = Vector2(250, 400) # Example position
	add_child(sylvara) # Add to scene tree
	player_party.append(sylvara)

	print("Player party created with %s members." % player_party.size())

func setup_managers():
	# Instantiate managers
	combat_manager = CombatManager.new()
	add_child(combat_manager) # So it can process signals, etc.

	stage_manager = StageManager.new()
	add_child(stage_manager)

	enemy_spawner = EnemySpawner.new()
	# EnemySpawner needs its spawn_parent_path set if not default, or parent set by add_child
	# Its default spawn_parent_path is "..", so if Game is parent of EnemySpawner, it's correct.
	add_child(enemy_spawner)

	score_manager = ScoreManager.new()
	add_child(score_manager)

	reward_manager = RewardManager.new()
	add_child(reward_manager)

	audio_manager = AudioManager.new() # Instantiate AudioManager
	audio_manager.name = "AudioManager" # Good practice to name nodes
	add_child(audio_manager)

	# Set dependencies
	# StageManager needs CombatManager (to start combat), EnemySpawner (to get enemies), and Game node (to get player party)
	stage_manager.set_dependencies(combat_manager, enemy_spawner, self, audio_manager) # Added audio_manager
	reward_manager.set_dependencies(score_manager)
	combat_manager.set_dependencies(audio_manager) # Added audio_manager

	# We need a reference to the UI script.
	# Assuming the UI scene is instanced in the Game scene with node name "UI"
	ui_node = find_child("UI") # Or get_node("UI") if it's a direct child
	if not ui_node:
		printerr("GAME.GD: UI Node not found! Score and reward UI will not update.")
	elif not ui_node.has_method("update_score_display"):
		printerr("GAME.GD: UI Node does not have expected methods (e.g. update_score_display).")
		ui_node = null # Prevent errors if methods are missing

	# Connect signals from managers to game logic or UI updates
	# CombatManager signals for ScoreManager
	combat_manager.enemy_defeated_for_score.connect(score_manager.on_enemy_defeated)
	combat_manager.player_damage_dealt_for_score.connect(score_manager.on_damage_dealt)
	# BaseCharacter critical hit signals (must connect for each player character)
	for player_char in player_party:
		if not player_char.is_connected("critical_hit_landed_by_character", Callable(score_manager, "on_critical_hit_landed")):
			player_char.critical_hit_landed_by_character.connect(score_manager.on_critical_hit_landed)

	# StageManager signals for ScoreManager
	stage_manager.stage_completed.connect(score_manager.on_stage_cleared)
	stage_manager.wave_completed.connect(score_manager.on_wave_cleared)
	# Add connections for NO_DAMAGE_WAVE and FLAWLESS_STAGE if StageManager implements them

	# ScoreManager and RewardManager signals for UI updates (via Game.gd handlers)
	score_manager.score_changed.connect(_on_score_updated)
	reward_manager.reward_unlocked.connect(_on_reward_unlocked)
	reward_manager.covenant_rank_up.connect(_on_covenant_rank_up)

	# Existing combat and stage manager signals
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.combat_ended.connect(_on_combat_ended) # StageManager also connects to this
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.turn_ended.connect(_on_turn_ended)
	combat_manager.combat_log_message.connect(_on_combat_log_message)

	stage_manager.stage_started.connect(_on_stage_started)
	stage_manager.stage_completed.connect(_on_stage_completed)
	stage_manager.all_stages_completed.connect(_on_all_stages_completed)
	stage_manager.wave_started.connect(_on_wave_started)
	stage_manager.wave_completed.connect(_on_wave_completed)
	stage_manager.artifact_dropped.connect(_on_artifact_dropped) # This might also give score or be a reward itself

	print("All managers instantiated and dependencies set. Signals connected.")

func get_player_party() -> Array[BaseCharacter]:
	return player_party

func get_player_crimson_veil() -> CrimsonVeilRelic: # Added getter for StageManager
	return player_crimson_veil_relic

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Example input handling for player turn (very basic)
	if Input.is_action_just_pressed("ui_accept"): # Usually 'Space' or 'Enter'
		if combat_manager and combat_manager.get_current_combatant() and player_party.has(combat_manager.get_current_combatant()):
			var attacker = combat_manager.get_current_combatant()
			var current_enemies = combat_manager.get_enemy_party() # Get current enemies from CM
			var target_enemy = null
			for enemy in current_enemies:
				if is_instance_valid(enemy) and enemy.current_hp > 0:
					target_enemy = enemy
					break

			if target_enemy:
				print_rich("[b]Player Action:[/b] %s attacks %s (via Enter/Space)" % [attacker.name, target_enemy.name])
				combat_manager.player_attack(attacker, target_enemy)
			else:
				print("No valid enemy target for player attack. (Perhaps all enemies defeated this turn?)")

	if Input.is_action_just_pressed("ui_select"): # Usually 'Enter' or 'Space' - mapped to skill for now
		if combat_manager and combat_manager.get_current_combatant() and player_party.has(combat_manager.get_current_combatant()):
			var attacker = combat_manager.get_current_combatant()
			var current_enemies = combat_manager.get_enemy_party() # Get current enemies from CM
			var target_enemy_array = []
			for enemy in current_enemies:
				if is_instance_valid(enemy) and enemy.current_hp > 0:
					target_enemy_array.append(enemy)
					break # For this basic example, skill targets first living enemy

			if not target_enemy_array.is_empty():
				print_rich("[b]Player Action:[/b] %s uses Signature Skill 1 on %s (via ui_select)" % [attacker.name, target_enemy_array[0].name])
				combat_manager.player_use_skill(attacker, target_enemy_array, 1) # Use skill 1
			else:
				print("No valid enemy target for player skill. (Perhaps all enemies defeated this turn?)")

	if Input.is_action_just_pressed("ui_end"): # 'End' key for testing artifact drop manually
		if stage_manager:
			print_rich("[b]Game Action:[/b] Manually triggering artifact drop for testing.")
			# This drop_artifact is on StageManager, it needs to know current stage for pool
			# For this test, ensure a stage is "active" or modify drop_artifact for test mode
			if stage_manager.current_stage_index == -1: # If no stage active, use a default pool for test
				var temp_artifact = stage_manager.available_artifact_scripts.keys().pick_random()
				var artifact_script_path = stage_manager.available_artifact_scripts[temp_artifact]
				var ArtifactClass = load(artifact_script_path)
				if ArtifactClass:
					var new_artifact = ArtifactClass.new()
					if new_artifact is BaseArtifact:
						_on_artifact_dropped(new_artifact) # Use the existing handler
					else: printerr("Test artifact is not BaseArtifact")
				else: printerr("Failed to load test artifact script")
			else:
				stage_manager.drop_artifact()


# --- Combat Manager Signal Handlers ---
func _on_combat_started():
	print_rich("[b]Game:[/b] Combat has officially started!")
	# UI could be updated here

func _on_combat_ended(result: String):
	print_rich("[b]Game:[/b] Combat ended. Result: [color=yellow]%s[/color]" % result.to_upper())
	# StageManager handles progression based on this.
	# If player lost, Game.gd might show a game over screen here.
	if result == "enemy_victory":
		print_rich("[b]Game:[/b] [color=red]PLAYER DEFEATED. Game Over.[/color]")
		# get_tree().quit() # Example: End game
		# Or: get_tree().reload_current_scene() to restart the game scene

func _on_turn_started(combatant: BaseCharacter):
	print_rich("[b]Game:[/b] Turn started for: [color=green]%s[/color] (HP: %s/%s)" % [combatant.name, combatant.current_hp, combatant.max_hp])
	if player_party.has(combatant):
		print_rich("   It's a player's turn. Waiting for input (Space/Enter to attack, 'ui_select' for skill 1).")

func _on_turn_ended(combatant: BaseCharacter):
	if is_instance_valid(combatant): # Combatant might have died and been freed
		print_rich("[b]Game:[/b] Turn ended for: [color=red]%s[/color]" % combatant.name)

func _on_combat_log_message(message: String):
	print_rich("[Combat Log] %s" % message)

# --- Stage Manager Signal Handlers ---
func _on_stage_started(stage_number: int):
	print_rich("[b]Game:[/b] [color=cyan]Stage %s started.[/color]" % stage_number)
	# Update UI with stage name/number

func _on_stage_completed(stage_number: int):
	print_rich("[b]Game:[/b] [color=green]Stage %s completed![/color]" % stage_number)
	# Offer rewards, save progress, etc.
	# StageManager calls drop_artifact internally.
	# StageManager will attempt to auto-proceed to next stage after artifact drop.
	print_rich("Stage completed. Artifact drop (if any) handled by StageManager.")
	print_rich("If there are more stages, the next one will start shortly.")
	# Potentially award score for flawless stage completion here, needs StageManager to track player deaths per stage.
	# Example: if stage_manager.was_stage_flawless(): score_manager.on_flawless_stage_bonus(stage_number)


func _on_all_stages_completed():
	print_rich("[b]Game:[/b] [color=gold]CONGRATULATIONS! All stages completed! YOU WIN![/color]")
	# Show victory screen, credits, etc.
	# get_tree().quit()

func _on_wave_started(wave_number: int):
	print_rich("[b]Game:[/b] Wave %s of Stage %s starting." % [wave_number, stage_manager.get_current_stage_number()])

func _on_wave_completed(wave_number: int):
	print_rich("[b]Game:[/b] Wave %s of Stage %s cleared." % [wave_number, stage_manager.get_current_stage_number()])

func _on_artifact_dropped(artifact_resource: BaseArtifact):
	if artifact_resource:
		print_rich("[b]Game:[/b] [color=orange]Artifact Acquired: %s![/color]\nTooltip: %s" % [artifact_resource.artifact_name, artifact_resource.get_tooltip_text()])
		# TODO: Add artifact to player's inventory / present choice to player.
		# For now, let's try to apply it to the first player character (Elara)
		if not player_party.is_empty():
			var character_to_apply = player_party[0] # Default to first character
			# In a real game, player would choose who gets it, or it goes to inventory.
			print_rich("Attempting to apply %s to %s." % [artifact_resource.artifact_name, character_to_apply.name])

			# Check if character already has this artifact (by name) to prevent re-applying stat boosts.
			# This requires characters to store their artifacts. For now, we assume it can be reapplied for testing.
			# A proper inventory system would manage this.
			artifact_resource.apply_effect(character_to_apply)

			# Add artifact to a list in the character?
			# if not hasattr(character_to_apply, "artifacts"):
			#   character_to_apply.artifacts = []
			# character_to_apply.artifacts.append(artifact_resource)
		else:
			print_rich("No characters in player party to apply artifact to.")
	else:
		print_rich("[b]Game:[/b] No artifact dropped this time or error in dropping.")

# --- Score and Reward UI Handlers ---
func _on_score_updated(new_score: int):
	print_rich("[b]Game UI:[/b] Score updated to: [color=yellow]%s[/color]" % new_score)
	if ui_node and ui_node.has_method("update_score_display"):
		ui_node.update_score_display(new_score)

func _on_reward_unlocked(reward_id: String, reward_description: String):
	print_rich("[b]Game UI:[/b] Reward unlocked: [color=orange]%s[/color] (%s)" % [reward_id, reward_description])
	if ui_node and ui_node.has_method("show_reward_notification"):
		ui_node.show_reward_notification("Unlocked: %s" % reward_description)

	if reward_id == "unlock_crimson_veil_fully_formed":
		var veil_script_path = stage_manager.available_artifact_scripts.get("crimson_veil")
		if veil_script_path:
			var VeilClass = load(veil_script_path)
			if VeilClass:
				var veil_instance = VeilClass.new() as CrimsonVeilRelic
				if veil_instance:
					veil_instance.is_fully_formed = true # Mark it as fully formed
					print_rich("[b]Game System:[/b] Crimson Veil relic instance created and marked as fully formed.")
					player_crimson_veil_relic = veil_instance # Store the activated veil
					# Simulate player acquiring it / its effects being applied
					_on_artifact_dropped(veil_instance)
					# Add to a global player inventory/relic list if one existed
					# Example: player_data.add_relic(veil_instance)
				else:
					printerr("Failed to cast loaded Crimson Veil script to CrimsonVeilRelic.")
			else:
				printerr("Failed to load Crimson Veil script from path: %s" % veil_script_path)
		else:
			printerr("Crimson Veil script path not found in StageManager.")


func _on_covenant_rank_up(new_rank_name: String):
	print_rich("[b]Game UI:[/b] Covenant Rank Up: [color=lightblue]%s[/color]" % new_rank_name)
	if ui_node and ui_node.has_method("show_reward_notification"):
		ui_node.show_reward_notification("Covenant Rank Up: %s!" % new_rank_name)
	# Potentially update other UI elements if Covenant Rank is displayed permanently


# Remove or adapt the old restart_combat_test, as it's not compatible with StageManager flow.
# func restart_combat_test():
# This would need to be rethought in terms of restarting the current stage or wave.
#	print_rich("[b]Game:[/b] Attempting to restart combat...")
#	# ... existing cleanup ...
#	stage_manager.start_first_stage() # Or restart current stage
