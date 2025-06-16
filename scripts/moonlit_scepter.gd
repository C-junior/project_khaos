extends "res://scripts/base_artifact.gd"
class_name MoonlitScepter

func _init():
	artifact_name = "Moonlit Scepter"
	description = "A scepter that hums with lunar energy, empowering magical abilities."
	base_effect_description = "Increases Attack Power by 10 and maximum HP by 20."
	resonant_accessory_description = "When paired with the 'Stardust Amulet', also grants +5% Crit Chance."

# Apply the primary effect of the Moonlit Scepter
func apply_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_effect for %s." % artifact_name)
		return

	print("Applying Moonlit Scepter effect to %s." % character.name)
	character.attack_power += 10
	character.max_hp += 20
	character.current_hp += 20 # Also increase current HP to match max_hp increase

	# It's good practice to have the character update its internal state if needed
	if character.has_method("update_hp_label"):
		character.update_hp_label()
	if character.has_signal("health_changed"):
		character.emit_signal("health_changed", character.current_hp, character.max_hp)

	print("%s new stats: ATK %s, MaxHP %s" % [character.name, character.attack_power, character.max_hp])

# Remove the primary effect of the Moonlit Scepter
func remove_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in remove_effect for %s." % artifact_name)
		return

	print("Removing Moonlit Scepter effect from %s." % character.name)
	character.attack_power -= 10
	character.max_hp -= 20
	# Ensure current_hp doesn't exceed new max_hp
	if character.current_hp > character.max_hp:
		character.current_hp = character.max_hp

	if character.has_method("update_hp_label"):
		character.update_hp_label()
	if character.has_signal("health_changed"):
		character.emit_signal("health_changed", character.current_hp, character.max_hp)

	print("%s reverted stats: ATK %s, MaxHP %s" % [character.name, character.attack_power, character.max_hp])

# Apply the resonant effect (placeholder for now)
func apply_resonant_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_resonant_effect for %s." % artifact_name)
		return

	super.apply_resonant_effect(character) # Calls the base print message
	# Actual implementation if Stardust Amulet is equipped:
	# if character.is_accessory_equipped("Stardust Amulet"): # Assumes a helper method on character
	print("Applying Moonlit Scepter resonant effect to %s: +5% Crit Chance." % character.name)
	character.crit_chance += 0.05
	print("%s new Crit Chance: %s" % [character.name, character.crit_chance])
	# else:
	#   print("Stardust Amulet not equipped, resonant effect not applied.")

# Remove the resonant effect
func remove_resonant_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in remove_resonant_effect for %s." % artifact_name)
		return

	print("Removing Moonlit Scepter resonant effect from %s." % character.name)
	character.crit_chance -= 0.05 # Ensure this only happens if it was applied
	print("%s reverted Crit Chance: %s" % [character.name, character.crit_chance])
