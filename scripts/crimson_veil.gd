extends "res://scripts/base_artifact.gd"
class_name CrimsonVeilRelic

# The Crimson Veil - A powerful relic that weakens Lilithar.
# In this implementation, we'll assume collecting 3 fragments automatically forms the veil.
# A more complex system might involve combining them or having them as separate items.

var fragments_collected: int = 0 # Not used in this simplified version where reward system gives full veil.
const FRAGMENTS_NEEDED: int = 3

func _init():
	artifact_name = "Crimson Veil"
	description = "A mystical veil woven from threads of captured sunsets and righteous fury. It resonates with an ancient power, specifically attuned to disrupt abyssal entities."
	base_effect_description = "Grants the wearer +10 to all stats (HP, ATK, DEF, SPD). Its true power is unleashed against specific greater demons."
	resonant_accessory_description = "No specific resonant accessory; its power is inherent." # Or could have one for general buff

# This flag indicates the Veil is fully formed and its special properties are active.
# RewardManager will set this to true when the "artifact" is granted.
var is_fully_formed: bool = false

func apply_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_effect for %s." % artifact_name)
		return

	print("Applying Crimson Veil general effect to %s." % character.name)
	character.max_hp += 10
	character.current_hp += 10
	character.attack_power += 10
	character.defense += 10
	character.speed += 10

	if character.has_method("update_hp_label"):
		character.update_hp_label()
	if character.has_signal("health_changed"):
		character.emit_signal("health_changed", character.current_hp, character.max_hp)

	print("%s new stats after Veil: ATK %s, DEF %s, SPD %s, MaxHP %s" % [character.name, character.attack_power, character.defense, character.speed, character.max_hp])

func remove_effect(character: BaseCharacter): # If artifact can be unequipped
	if not is_instance_valid(character):
		print("Invalid character reference for %s." % artifact_name)
		return

	print("Removing Crimson Veil general effect from %s." % character.name)
	character.max_hp -= 10
	# current_hp will adjust if > new max_hp
	character.attack_power -= 10
	character.defense -= 10
	character.speed -= 10

	if character.current_hp > character.max_hp:
		character.current_hp = character.max_hp

	if character.has_method("update_hp_label"):
		character.update_hp_label()
	if character.has_signal("health_changed"):
		character.emit_signal("health_changed", character.current_hp, character.max_hp)


# Special function to check if the Veil should weaken Lilithar.
# This is what Lilithar's script will query.
func grants_power_against_abyss() -> bool:
	return is_fully_formed # In this simplified model, if player has it, it's formed.

# --- Fragment Logic (Conceptual - Not fully implemented via rewards this way) ---
# If we were collecting fragments:
# func add_fragment():
#   if is_fully_formed: return true
#   fragments_collected += 1
#   print("Crimson Veil fragment collected. Total: %s/%s" % [fragments_collected, FRAGMENTS_NEEDED])
#   if fragments_collected >= FRAGMENTS_NEEDED:
#       form_the_veil()
#       return true
#   return false

# func form_the_veil():
#   if is_fully_formed: return
#   print_rich("[color=red]The fragments of the Crimson Veil unite! Its power is now fully awakened![/color]")
#   is_fully_formed = true
#   # Potentially enhance its base_effect_description or apply a stronger version of apply_effect
#   base_effect_description = "The fully formed Crimson Veil greatly empowers the wearer (+20 to all stats) and weakens powerful abyssal foes."
#   # If applied to a character already, might need to re-apply or boost stats.
#   # This part is tricky if artifact effects are one-time applications.
#   # For simplicity, the current `apply_effect` is what it grants when "formed".

func get_tooltip_text() -> String:
	var tooltip = super.get_tooltip_text() # Gets name, base_effect_description
	if is_fully_formed:
		tooltip += "\n[color=green]The Veil is fully formed. Its power against the abyss is awakened.[/color]"
	# else if fragments_collected > 0:
	#   tooltip += "\n[color=orange]Fragments collected: %s/%s[/color]" % [fragments_collected, FRAGMENTS_NEEDED]
	return tooltip
