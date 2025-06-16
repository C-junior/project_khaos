extends "res://scripts/base_character.gd"
class_name Elara

# Elara - Agile warrior with wind-based attacks

func _init():
	# Character Name for debugging or UI
	name = "Elara"

	# Base Stats - Elara
	max_hp = 90
	current_hp = 90
	attack_power = 12
	defense = 4
	crit_chance = 0.15 # Higher crit chance
	crit_damage_multiplier = 1.6
	speed = 12 # Faster speed

	# Skill names (optional, for UI or reference)
	# signature_skill_1_name = "Whirlwind Strike"
	# signature_skill_2_name = "Gale Force"
	# ultimate_skill_name = "Tempest Fury"

func _ready():
	super._ready() # Call the parent's _ready function
	# Specific texture for Elara
	# set_sprite_texture("res://assets/art/elara_sprite.png") # Example path
	print("Elara character initialized with custom stats.")
	update_hp_label() # Ensure HP label is correct with Elara's stats

# Signature Skill 1: Whirlwind Strike
# Hits multiple enemies or one enemy multiple times.
func whirlwind_strike(targets: Array[BaseCharacter]):
	print("%s uses Whirlwind Strike!" % name)
	if targets.is_empty():
		print("No targets for Whirlwind Strike.")
		return

	# Example: Hit the first target, or could iterate all targets
	var target = targets[0]
	if is_instance_valid(target):
		var damage_per_hit = int(attack_power * 0.75) # Reduced damage per hit
		var number_of_hits = 2 # Hits twice

		print("%s strikes %s %s times." % [name, target.name, number_of_hits])
		for i in range(number_of_hits):
			var is_critical = randf() < crit_chance
			var current_hit_damage = damage_per_hit
			if is_critical:
				current_hit_damage = int(current_hit_damage * crit_damage_multiplier)
				print("Critical Hit on strike %s!" % (i+1))
			target.take_damage(current_hit_damage)
			# Add small delay or animation call here if needed between hits
	else:
		print("Target for Whirlwind Strike is invalid.")

# Override other skills as needed
# func signature_skill_2(targets: Array[BaseCharacter]):
#   super.signature_skill_2(targets) # or implement Elara's specific skill 2
#   print("%s uses Gale Force!" % name)

# func ultimate_skill(targets: Array[BaseCharacter]):
#   super.ultimate_skill(targets) # or implement Elara's specific ultimate
#   print("%s uses Tempest Fury!" % name)
