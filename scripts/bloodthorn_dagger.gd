extends "res://scripts/base_artifact.gd"
class_name BloodthornDagger

func _init():
	artifact_name = "Bloodthorn Dagger"
	description = "A wicked dagger that thirsts for blood, growing stronger with each critical strike."
	base_effect_description = "Increases Crit Chance by 10% and Crit Damage Multiplier by 0.2."
	# Example resonant effect (conceptual)
	resonant_accessory_description = "When paired with the 'Shadowclasp Gauntlet', critical hits also have a 25% chance to apply 'Bleed' for 2 turns."

# Apply the primary effect of the Bloodthorn Dagger
func apply_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_effect for %s." % artifact_name)
		return

	print("Applying Bloodthorn Dagger effect to %s." % character.name)
	character.crit_chance += 0.10
	character.crit_damage_multiplier += 0.2

	print("%s new stats: CritChance %s, CritDMG Multiplier %s" % [character.name, character.crit_chance, character.crit_damage_multiplier])

# Remove the primary effect of the Bloodthorn Dagger
func remove_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in remove_effect for %s." % artifact_name)
		return

	print("Removing Bloodthorn Dagger effect from %s." % character.name)
	character.crit_chance -= 0.10
	# Clamp to avoid negative values if other effects also modify this
	if character.crit_chance < 0: character.crit_chance = 0.0
	character.crit_damage_multiplier -= 0.2
	# Clamp to avoid going below a baseline (e.g., 1.0 for 100% base crit damage)
	if character.crit_damage_multiplier < 1.0: character.crit_damage_multiplier = 1.0

	print("%s reverted stats: CritChance %s, CritDMG Multiplier %s" % [character.name, character.crit_chance, character.crit_damage_multiplier])

# Apply the resonant effect (placeholder for now, actual implementation would require status effect system)
func apply_resonant_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_resonant_effect for %s." % artifact_name)
		return

	super.apply_resonant_effect(character) # Calls the base print message
	# Actual implementation if Shadowclasp Gauntlet is equipped:
	# if character.is_accessory_equipped("Shadowclasp Gauntlet"):
	print("Applying Bloodthorn Dagger resonant effect to %s: Critical hits may apply 'Bleed'." % character.name)
	# This effect is passive, it would modify how critical hits are processed.
	# For example, the character's attack function might check:
	# if self.has_artifact_resonant_effect("Bloodthorn Dagger_Bleed_On_Crit"):
	#   if is_critical and randf() < 0.25:
	#     target.apply_status("Bleed", 2) # Apply bleed for 2 turns
	# else:
	#   print("Shadowclasp Gauntlet not equipped, resonant bleed effect not active.")
	pass # The actual application of bleed would be handled in the character's attack logic

# Remove the resonant effect (conceptual, as the effect is passive)
func remove_resonant_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in remove_resonant_effect for %s." % artifact_name)
		return
	print("Removing Bloodthorn Dagger resonant effect from %s (effect was passive)." % character.name)
	# No direct stat change to revert here, but internal flags on character might be reset.
	pass
