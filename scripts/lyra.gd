extends "res://scripts/base_character.gd"
class_name Lyra

# Lyra - A mage or ranged attacker, high damage, low defense

func _init():
	name = "Lyra"

	# Base Stats - Lyra
	max_hp = 80 # Lower HP
	current_hp = 80
	attack_power = 15 # Higher attack power
	defense = 3 # Lower defense
	crit_chance = 0.1
	crit_damage_multiplier = 1.7 # Higher crit damage
	speed = 9

func _ready():
	super._ready()
	# set_sprite_texture("res://assets/art/lyra_sprite.png") # Example path
	print("Lyra character initialized with custom stats.")
	update_hp_label()

# Signature Skill 1: Arcane Bolt (Example: Single target high damage)
func arcane_bolt(targets: Array[BaseCharacter]): # Renamed for clarity
	print("%s casts Arcane Bolt!" % name)
	if targets.is_empty():
		print("No target for Arcane Bolt.")
		return

	var target = targets[0]
	if is_instance_valid(target):
		var damage = int(attack_power * 1.5) # Higher damage multiplier for the skill
		var is_critical = randf() < crit_chance
		if is_critical:
			damage = int(damage * crit_damage_multiplier)
			print("Critical Hit with Arcane Bolt!")

		print("%s zaps %s for %s damage with Arcane Bolt." % [name, target.name, damage])
		target.take_damage(damage)
	else:
		print("Target for Arcane Bolt is invalid.")

# Override the base signature_skill_1
func signature_skill_1(targets: Array[BaseCharacter]):
	arcane_bolt(targets)

# Placeholder for other skills
# func signature_skill_2(targets: Array[BaseCharacter]):
#   print("%s uses Mana Shield!" % name) # Example: Temporary defensive buff

# func ultimate_skill(targets: Array[BaseCharacter]):
#   print("%s unleashes Starfall!" % name) # Example: AoE magic damage
