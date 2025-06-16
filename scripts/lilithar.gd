extends "res://scripts/base_character.gd"
class_name Lilithar

# Lilithar - Final Boss

# --- Stats ---
# Lilithar will have multiple phases, stats might change per phase.
# These are base Phase 1 stats.
var phase: int = 1
var initial_attack_power: int
var initial_defense: int

# For Crimson Veil interaction
var is_weakened_by_veil: bool = false
const VEIL_ATTACK_REDUCTION: int = 20
const VEIL_DEFENSE_REDUCTION: int = 10

func _init():
	name = "Lilithar, Empress of Torment"

	# Phase 1 Stats (can be adjusted)
	max_hp = 1000
	current_hp = 1000
	attack_power = 40
	defense = 20
	crit_chance = 0.15
	crit_damage_multiplier = 1.7
	speed = 20 # Boss is fast

	initial_attack_power = attack_power # Store for veil interaction
	initial_defense = defense

	# Lilithar's specific skills (names for now)
	# signature_skill_1_name = "Soul Rend"
	# signature_skill_2_name = "Chains of Damnation"
	# ultimate_skill_name = "Abyssal Eruption"
	# phase_transition_skill_name = "Despair Nova"

func _ready():
	super._ready() # Calls BaseCharacter's _ready
	# set_sprite_texture("res://assets/art/bosses/lilithar_phase1.png") # Example path
	print("Lilithar, Empress of Torment, has awakened!")
	update_hp_label()


func check_for_crimson_veil(player_has_veil: bool): # This would be called by CombatManager/StageManager
	if player_has_veil and not is_weakened_by_veil:
		is_weakened_by_veil = true
		print_rich("[b]Lilithar shudders as the Crimson Veil's power takes hold! She is weakened![/b]")
		attack_power = max(5, initial_attack_power - VEIL_ATTACK_REDUCTION)
		defense = max(0, initial_defense - VEIL_DEFENSE_REDUCTION)
		# Could also affect other stats like speed or resistances if implemented
		# Or disable/weaken certain abilities
	elif not player_has_veil and is_weakened_by_veil: # Should not happen if veil is permanent
		is_weakened_by_veil = false
		attack_power = initial_attack_power
		defense = initial_defense
		print_rich("[b]The Crimson Veil's influence fades! Lilithar's power returns![/b]")


# --- Overridden BaseCharacter Methods ---
func take_damage(damage_amount: int):
	var actual_damage = super.take_damage(damage_amount) # Call parent and get actual damage

	# Phase transition logic (example)
	if phase == 1 and current_hp <= max_hp * 0.66 and is_instance_valid(self): # Check if still valid (not already dead)
		transition_to_phase(2)
	elif phase == 2 and current_hp <= max_hp * 0.33 and is_instance_valid(self):
		transition_to_phase(3)

	return actual_damage


func transition_to_phase(new_phase: int):
	if new_phase == phase: return

	phase = new_phase
	print_rich("[b]Lilithar roars in fury, transitioning to Phase %s! Her power intensifies![/b]" % phase)
	if audio_manager: audio_manager.play_sfx("boss_phase_change_sfx") # Placeholder SFX
	# Emit a signal or call a function that CombatManager/Game can react to (e.g., change music, visual effects)
	# get_tree().call_group("combat_listeners", "on_boss_phase_change", self, phase)

	match phase:
		2:
			# Modify stats for Phase 2 (example: more attack, less defense, new skills)
			attack_power = initial_attack_power + 10 - (VEIL_ATTACK_REDUCTION if is_weakened_by_veil else 0)
			defense = initial_defense - 5 - (VEIL_DEFENSE_REDUCTION if is_weakened_by_veil else 0)
			if defense < 0: defense = 0
			speed += 5
			# set_sprite_texture("res://assets/art/bosses/lilithar_phase2.png")
			print("Lilithar Phase 2 stats: ATK %s, DEF %s, SPD %s" % [attack_power, defense, speed])
			# Potentially heal a small amount or clear some status effects
			# heal(max_hp * 0.1)
			# Use a powerful AoE attack upon phase transition
			# despair_nova()
		3:
			# Modify stats for Phase 3 (example: massive attack, speed boost, special abilities)
			attack_power = initial_attack_power + 20 - (VEIL_ATTACK_REDUCTION if is_weakened_by_veil else 0)
			defense = initial_defense - 10 - (VEIL_DEFENSE_REDUCTION if is_weakened_by_veil else 0)
			if defense < 0: defense = 0
			speed += 10
			crit_chance += 0.1
			# set_sprite_texture("res://assets/art/bosses/lilithar_phase3.png")
			print("Lilithar Phase 3 stats: ATK %s, DEF %s, SPD %s, Crit %s" % [attack_power, defense, speed, crit_chance])
			# abyssal_eruption() # Unleash ultimate

	# Ensure HP label is updated if max_hp changes or healing occurs during transition
	update_hp_label()


# --- Lilithar's Specific Skills (Placeholders) ---

# Signature Skill 1: Soul Rend (High single-target damage, maybe lifesteal)
func signature_skill_1(targets: Array[BaseCharacter]):
	if targets.is_empty(): return
	var target = targets[0] # Assume single target for this skill
	print_rich("[b]%s[/b] uses [color=purple]Soul Rend[/color] on %s!" % [name, target.name])
	if audio_manager: audio_manager.play_sfx("lilithar_soul_rend_cast") # Placeholder

	var damage = int(attack_power * 1.5)
	if randf() < crit_chance: # Recalculate crit for skill
		damage = int(damage * crit_damage_multiplier)
		print("Critical Hit with Soul Rend!")
		emit_signal("critical_hit_landed_by_character", self.name) # For scoring system

	var actual_damage = target.take_damage(damage)
	if actual_damage > 0:
		var lifesteal = int(actual_damage * 0.33) # Heals for 33% of damage dealt
		heal(lifesteal)
		print("%s drains %s HP from %s." % [name, lifesteal, target.name])

# Signature Skill 2: Chains of Damnation (AoE, chance to apply a 'Stun' or 'Speed Down' status effect)
func signature_skill_2(targets: Array[BaseCharacter]):
	print_rich("[b]%s[/b] unleashes [color=red]Chains of Damnation[/color] on all foes!" % name)
	if audio_manager: audio_manager.play_sfx("lilithar_chains_cast") # Placeholder
	for target in targets:
		if is_instance_valid(target) and target.current_hp > 0:
			var damage = int(attack_power * 0.8) # Lower damage for AoE
			target.take_damage(damage)
			# Add status effect logic here if system exists
			# if randf() < 0.3: target.apply_status("speed_down", 2) # 30% chance, 2 turns
			print("%s is hit by Chains of Damnation." % target.name)

# Ultimate Skill: Abyssal Eruption (Massive AoE damage, used in later phases or on a cooldown)
func ultimate_skill(targets: Array[BaseCharacter]):
	print_rich("[b]%s[/b] invokes [color=darkred]ABYSSAL ERUPTION[/color]!" % name)
	if audio_manager: audio_manager.play_sfx("lilithar_abyssal_eruption_cast") # Placeholder
	for target in targets:
		if is_instance_valid(target) and target.current_hp > 0:
			var damage = int(attack_power * 2.0) # Very high damage
			target.take_damage(damage)
			print("%s is engulfed in abyssal energy." % target.name)

# Phase Transition Skill: Despair Nova (Used automatically on phase change)
func despair_nova(targets: Array[BaseCharacter]): # Targets would be all player characters
	print_rich("[b]%s[/b] emits a [color=violet]Despair Nova[/color] as her form shifts!" % name)
	if audio_manager: audio_manager.play_sfx("lilithar_despair_nova_cast") # Placeholder
	for target in targets:
		if is_instance_valid(target) and target.current_hp > 0:
			var damage = int(attack_power * 1.2) # Moderate AoE damage
			target.take_damage(damage)
			# Potentially apply a debuff like defense down
			print("%s is struck by the Despair Nova." % target.name)

# --- AI Logic (Called by CombatManager during Lilithar's turn) ---
# This is a simplified version. A real boss AI would be more complex.
func choose_action(player_party_for_targeting: Array[BaseCharacter]) -> Dictionary:
	# Returns a dictionary like {"action_type": "skill", "skill_function": "signature_skill_1", "targets": [player_char]}
	# Or {"action_type": "attack", "targets": [player_char]}

	var living_players = []
	for p in player_party_for_targeting:
		if is_instance_valid(p) and p.current_hp > 0:
			living_players.append(p)
	if living_players.is_empty(): return {"action_type": "none"}

	# Basic AI:
	# Phase 1: Cycle Soul Rend and Chains of Damnation. Basic attack if low on "mana" (not implemented).
	# Phase 2: Higher chance of Chains, uses Despair Nova if recently transitioned (conceptual cooldown).
	# Phase 3: High chance of Abyssal Eruption if available, otherwise Soul Rend or powerful basic attacks.

	var rand_choice = randf()

	if phase == 1:
		if rand_choice < 0.4:
			return {"action_type": "skill", "skill_name": "signature_skill_1", "targets": [living_players.pick_random()]}
		elif rand_choice < 0.8:
			# Chains of Damnation targets all living players
			return {"action_type": "skill", "skill_name": "signature_skill_2", "targets": living_players}
		else:
			return {"action_type": "attack", "targets": [living_players.pick_random()]}
	elif phase == 2:
		# Example: Use Despair Nova once shortly after phase transition, then other skills.
		# This would need a flag like `just_transitioned_to_phase_2 = true`
		# if just_transitioned_to_phase_2_and_nova_available:
		#   just_transitioned_to_phase_2 = false
		#   return {"action_type": "skill", "skill_name": "despair_nova", "targets": living_players}

		if rand_choice < 0.3:
			return {"action_type": "skill", "skill_name": "signature_skill_1", "targets": [living_players.pick_random()]}
		elif rand_choice < 0.7:
			return {"action_type": "skill", "skill_name": "signature_skill_2", "targets": living_players}
		else:
			return {"action_type": "attack", "targets": [living_players.pick_random()]} # More powerful basic attacks in P2
	elif phase == 3:
		if rand_choice < 0.4: # Higher chance for ultimate
			return {"action_type": "skill", "skill_name": "ultimate_skill", "targets": living_players}
		elif rand_choice < 0.7:
			return {"action_type": "skill", "skill_name": "signature_skill_1", "targets": [living_players.pick_random()]}
		else:
			return {"action_type": "attack", "targets": [living_players.pick_random()]}

	# Fallback: Basic Attack
	return {"action_type": "attack", "targets": [living_players.pick_random()]}
