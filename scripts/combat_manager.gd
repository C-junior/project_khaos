extends Node
class_name CombatManager

var player_party: Array[BaseCharacter] = []
var enemy_party: Array[BaseCharacter] = []
var all_combatants: Array[BaseCharacter] = [] # Combined and sorted by speed for turn order
var current_turn_index: int = 0
var current_combatant: BaseCharacter = null

var audio_manager # Will be set by Game.gd

signal combat_started
signal combat_ended(result) # "player_victory", "enemy_victory"
signal turn_started(combatant)
signal turn_ended(combatant)
signal combat_log_message(message) # For sending messages to a UI or console

# Signals for ScoreManager
signal enemy_defeated_for_score(enemy_node)
signal player_damage_dealt_for_score(damage_amount)


func _ready():
	print("Combat Manager ready.")

func set_dependencies(am): # AudioManager
	audio_manager = am
	if not audio_manager:
		printerr("CombatManager: AudioManager dependency not set!")


# --- Combat Setup ---
func setup_combat(p_party: Array[BaseCharacter], e_party: Array[BaseCharacter]):
	player_party = p_party
	enemy_party = e_party

	if player_party.is_empty() or enemy_party.is_empty():
		emit_signal("combat_log_message", "Cannot start combat: one or both parties are empty.")
		print("Cannot start combat: one or both parties are empty.")
		return false

	all_combatants.clear()
	all_combatants.append_array(player_party)
	all_combatants.append_array(enemy_party)

	# Connect signals and pass AudioManager for all combatants
	for combatant in all_combatants:
		if self.audio_manager and combatant.has_variable("audio_manager"): # Check if var exists
			combatant.audio_manager = self.audio_manager

		if not combatant.is_connected("health_changed", Callable(self, "_on_combatant_health_changed")):
			combatant.connect("health_changed", Callable(self, "_on_combatant_health_changed"))
		if not combatant.is_connected("died", Callable(self, "_on_combatant_died")):
			combatant.connect("died", Callable(self, "_on_combatant_died").bind(combatant)) # Bind combatant to know who died

	# Sort combatants by speed (descending)
	all_combatants.sort_custom(func(a, b): return a.speed > b.speed)

	current_turn_index = -1 # Will be incremented to 0 by next_turn
	emit_signal("combat_log_message", "Combat setup complete. Sorted turn order.")
	print("Combat setup. Turn order:")
	for c in all_combatants:
		print("- %s (Speed: %s)" % [c.name, c.speed])
	return true

func start_combat():
	if all_combatants.is_empty():
		emit_signal("combat_log_message", "Combat cannot start, no combatants.")
		return

	emit_signal("combat_started")
	emit_signal("combat_log_message", "Combat Started!")
	print("Combat Started!")
	next_turn()

# --- Turn Management ---
func next_turn():
	if check_combat_end_conditions():
		return

	current_turn_index = (current_turn_index + 1) % all_combatants.size()
	current_combatant = all_combatants[current_turn_index]

	# Skip dead combatants
	while not is_instance_valid(current_combatant) or current_combatant.current_hp == 0:
		current_turn_index = (current_turn_index + 1) % all_combatants.size()
		current_combatant = all_combatants[current_turn_index]
		if check_combat_end_conditions(): # Check again in case all remaining are dead
			return


	emit_signal("turn_started", current_combatant)
	emit_signal("combat_log_message", "--- %s's Turn ---" % current_combatant.name)
	print("--- %s's Turn (HP: %s/%s) ---" % [current_combatant.name, current_combatant.current_hp, current_combatant.max_hp])

	if enemy_party.has(current_combatant):
		enemy_turn(current_combatant)
	# Else, it's a player's turn, wait for player input (handled by game.gd or UI)

func end_current_turn():
	if current_combatant:
		emit_signal("turn_ended", current_combatant)
		# Check for status effects, cooldowns, etc. at end of turn if implemented
	next_turn()

# --- Action Handling ---
func player_attack(attacker: BaseCharacter, target: BaseCharacter):
	if attacker != current_combatant:
		emit_signal("combat_log_message", "Not %s's turn." % attacker.name)
		return false
	if not is_instance_valid(target) or target.current_hp == 0:
		emit_signal("combat_log_message", "%s cannot attack %s: target is invalid or already defeated." % [attacker.name, target.name])
		return false

	emit_signal("combat_log_message", "%s attacks %s." % [attacker.name, target.name])
	if audio_manager: audio_manager.play_sfx("attack_sword") # Placeholder SFX

	var actual_damage_dealt = attacker.attack(target) # attack() now returns actual_damage

	if player_party.has(attacker) and actual_damage_dealt != null and actual_damage_dealt > 0 :
		emit_signal("player_damage_dealt_for_score", actual_damage_dealt)

	end_current_turn()
	return true

func player_use_skill(attacker: BaseCharacter, targets: Array[BaseCharacter], skill_id: int): # skill_id = 1, 2, or 3 for ultimate
	# Similar to player_attack, if skills deal damage, we'd want to capture actual damage dealt
	# and emit player_damage_dealt_for_score for each target hit by a player's skill.
	# This requires skill methods in BaseCharacter and its children to return damage info or for take_damage to be robust.
	# For now, this example focuses on the signal infrastructure.
	if attacker != current_combatant:
		emit_signal("combat_log_message", "Not %s's turn." % attacker.name)
		return false

	var skill_name = "Unknown Skill"
	match skill_id:
		1:
			skill_name = "Signature Skill 1"
			if audio_manager: audio_manager.play_sfx("skill_generic_cast") # Placeholder
			attacker.signature_skill_1(targets)
		2:
			skill_name = "Signature Skill 2"
			if audio_manager: audio_manager.play_sfx("skill_special_cast") # Placeholder
			attacker.signature_skill_2(targets)
		3:
			skill_name = "Ultimate Skill"
			if audio_manager: audio_manager.play_sfx("skill_ultimate_cast") # Placeholder
			attacker.ultimate_skill(targets)
		_:
			emit_signal("combat_log_message", "Invalid skill ID: %s" % skill_id)
			return false

	emit_signal("combat_log_message", "%s uses %s." % [attacker.name, skill_name]) # Targets described in skill itself
	end_current_turn()
	return true

# --- Enemy AI ---
func enemy_turn(enemy: BaseCharacter):
	emit_signal("combat_log_message", "Enemy %s is thinking..." % enemy.name)
	# Basic AI: Attack a random living player character
	var living_players = []
	for p in player_party:
		if is_instance_valid(p) and p.current_hp > 0:
			living_players.append(p)

	if living_players.is_empty():
		emit_signal("combat_log_message", "No living players for %s to target." % enemy.name)
		end_current_turn() # Should trigger combat end
		return

	var target = living_players.pick_random() # Default target if not specified by skill

	if enemy.has_method("choose_action"):
		var action_info = enemy.choose_action(living_players)
		match action_info.action_type:
			"attack":
				var attack_target = action_info.targets[0] if not action_info.targets.is_empty() else target
				if is_instance_valid(attack_target) and attack_target.current_hp > 0:
					emit_signal("combat_log_message", "%s decides to attack %s." % [enemy.name, attack_target.name])
					if audio_manager: audio_manager.play_sfx("attack_monster") # Placeholder
					enemy.attack(attack_target)
				else:
					emit_signal("combat_log_message", "%s tries to attack, but target %s is invalid or defeated." % [enemy.name, attack_target.name])
			"skill":
				var skill_name_for_invoke = action_info.skill_name # e.g., "signature_skill_1"
				var skill_targets = action_info.targets
				if enemy.has_method(skill_name_for_invoke):
					emit_signal("combat_log_message", "%s uses %s!" % [enemy.name, skill_name_for_invoke.replace("_", " ").capitalize()])
					if audio_manager: audio_manager.play_sfx("skill_boss_generic") # Placeholder for boss skills
					enemy.call(skill_name_for_invoke, skill_targets) # Call the method by string name
				else:
					emit_signal("combat_log_message", "%s tries to use skill %s, but method not found. Defaulting to attack." % [enemy.name, skill_name_for_invoke])
					if is_instance_valid(target) and target.current_hp > 0:
						if audio_manager: audio_manager.play_sfx("attack_monster") # Placeholder
						enemy.attack(target)
			"none":
				emit_signal("combat_log_message", "%s chooses to do nothing." % enemy.name)
			_:
				emit_signal("combat_log_message", "%s AI returned unknown action. Defaulting to attack." % enemy.name)
				if is_instance_valid(target) and target.current_hp > 0:
					if audio_manager: audio_manager.play_sfx("attack_monster") # Placeholder
					enemy.attack(target)
	else:
		# Default AI for non-boss enemies
		if is_instance_valid(target) and target.current_hp > 0:
			emit_signal("combat_log_message", "%s decides to attack %s." % [enemy.name, target.name])
			if audio_manager: audio_manager.play_sfx("attack_grunt") # Placeholder
			enemy.attack(target)
		else:
			emit_signal("combat_log_message", "%s has no valid target to attack." % enemy.name)

	end_current_turn()

# --- Combat State & Signal Handling ---
func _on_combatant_health_changed(new_hp, max_hp):
	# This signal comes from BaseCharacter, parameters are new_hp, max_hp
	# We don't strictly need to find who it was, as the character's label updates itself.
	# However, we could log it here if desired.
	# Example: find which character sent this and log "Character X HP changed..."
	# For now, base_character.gd already prints damage/heal amounts.
	pass


func _on_combatant_died(combatant: BaseCharacter): # Bound combatant who died
	emit_signal("combat_log_message", "%s has been defeated!" % combatant.name)
	print("%s has been defeated!" % combatant.name)

	# If the currently active combatant died, their turn should end immediately.
	if combatant == current_combatant:
		# No need to call end_current_turn() here, as check_combat_end_conditions() in next_turn()
		# will handle it, or the loop for skipping dead combatants will.
		# If we call it here, it might cause a double turn skip.
		pass

	# No need to remove from all_combatants; sorting and turn skipping handles dead units.
	# check_combat_end_conditions() will determine if the fight is over.

	if enemy_party.has(combatant): # Check if the defeated combatant was an enemy
		emit_signal("enemy_defeated_for_score", combatant)
		if audio_manager: audio_manager.play_sfx("enemy_defeated_sfx")
	elif player_party.has(combatant): # Check if it was a player character
		if audio_manager: audio_manager.play_sfx("player_defeated_sfx")


func check_combat_end_conditions() -> bool:
	var all_players_dead = true
	for p in player_party:
		if is_instance_valid(p) and p.current_hp > 0:
			all_players_dead = false
			break

	if all_players_dead:
		emit_signal("combat_log_message", "All player characters defeated. Enemy victory!")
		print("All player characters defeated. Enemy victory!")
		emit_signal("combat_ended", "enemy_victory")
		# cleanup_combat()
		return true

	var all_enemies_dead = true
	for e in enemy_party:
		if is_instance_valid(e) and e.current_hp > 0:
			all_enemies_dead = false
			break

	if all_enemies_dead:
		emit_signal("combat_log_message", "All enemies defeated. Player victory!")
		print("All enemies defeated. Player victory!")
		emit_signal("combat_ended", "player_victory")
		# cleanup_combat()
		return true

	return false

func cleanup_combat():
	# Disconnect signals
	for combatant in all_combatants:
		if is_instance_valid(combatant):
			if combatant.is_connected("health_changed", Callable(self, "_on_combatant_health_changed")):
				combatant.disconnect("health_changed", Callable(self, "_on_combatant_health_changed"))
			if combatant.is_connected("died", Callable(self, "_on_combatant_died")):
				# This is tricky because of the bind. A more robust way is to store Callables.
				# For now, let's assume it's okay or manage connections more strictly.
				# Or, simply let them be, they won't fire if combat_manager is queue_freed.
				pass

	player_party.clear()
	enemy_party.clear()
	all_combatants.clear()
	current_combatant = null
	current_turn_index = 0
	emit_signal("combat_log_message", "Combat cleaned up.")
	print("Combat cleaned up.")

# Call this if you want to manually end combat (e.g. player flees)
func force_end_combat(reason: String = "manual_end"):
	emit_signal("combat_log_message", "Combat ended manually: %s" % reason)
	emit_signal("combat_ended", reason)
	cleanup_combat()

func get_all_combatants() -> Array[BaseCharacter]:
	return all_combatants

func get_player_party() -> Array[BaseCharacter]:
	return player_party

func get_enemy_party() -> Array[BaseCharacter]:
	return enemy_party

func get_current_combatant() -> BaseCharacter:
	return current_combatant
