extends "res://scripts/base_character.gd"
class_name Sylvara

# Sylvara - Nature-focused character, perhaps a healer or debuffer

func _init():
	name = "Sylvara"

	# Base Stats - Sylvara
	max_hp = 110 # More HP, tankier or healer
	current_hp = 110
	attack_power = 8
	defense = 6 # Higher defense
	crit_chance = 0.05
	crit_damage_multiplier = 1.5
	speed = 8 # Slower

func _ready():
	super._ready()
	# set_sprite_texture("res://assets/art/sylvara_sprite.png") # Example path
	print("Sylvara character initialized with custom stats.")
	update_hp_label()

# Signature Skill 1: Nature's Touch (Example: Heal)
func natures_touch(targets: Array[BaseCharacter]): # Changed from signature_skill_1 for clarity
	print("%s uses Nature's Touch!" % name)
	if targets.is_empty():
		print("No targets for Nature's Touch.")
		return

	var target = targets[0] # Example: heal the first target in the array
	if is_instance_valid(target):
		var heal_amount = int(attack_power * 1.5) # Healing based on her attack power, or a fixed value
		print("%s heals %s for %s HP." % [name, target.name, heal_amount])
		target.heal(heal_amount)
	else:
		print("Target for Nature's Touch is invalid.")

# Override the base signature_skill_1 to call the specific one if preferred
func signature_skill_1(targets: Array[BaseCharacter]):
	natures_touch(targets)

# Placeholder for other skills
# func signature_skill_2(targets: Array[BaseCharacter]):
#   print("%s uses Sylvan Ward!" % name) # Example: Defensive buff

# func ultimate_skill(targets: Array[BaseCharacter]):
#   print("%s uses Forest's Wrath!" % name) # Example: AoE damage or debuff
