extends "res://scripts/base_character.gd"
class_name Mira

# Mira - Rogue-like character, high speed and crit, status effects

func _init():
	name = "Mira"

	# Base Stats - Mira
	max_hp = 85
	current_hp = 85
	attack_power = 10
	defense = 4
	crit_chance = 0.20 # Very high crit chance
	crit_damage_multiplier = 1.8 # Also high crit damage
	speed = 15 # Fastest character

func _ready():
	super._ready()
	# set_sprite_texture("res://assets/art/mira_sprite.png") # Example path
	print("Mira character initialized with custom stats.")
	update_hp_label()

# Signature Skill 1: Shadow Strike (Example: High crit chance, may apply bleed)
func shadow_strike(targets: Array[BaseCharacter]): # Renamed for clarity
	print("%s performs Shadow Strike!" % name)
	if targets.is_empty():
		print("No target for Shadow Strike.")
		return

	var target = targets[0]
	if is_instance_valid(target):
		var damage = attack_power # Base damage before crit
		# Enhanced crit chance for this skill specifically
		var skill_crit_chance = crit_chance + 0.25 # e.g. 20% base + 25% skill = 45%

		var is_critical = randf() < skill_crit_chance
		if is_critical:
			damage = int(damage * crit_damage_multiplier)
			print("Critical Hit with Shadow Strike!")

		print("%s hits %s for %s damage with Shadow Strike." % [name, target.name, damage])
		target.take_damage(damage)

		# Add a chance to apply a status effect like 'bleed' or 'poison'
		# if randf() < 0.5: # 50% chance to apply bleed
		#   print("%s is now bleeding!" % target.name)
		#   # target.apply_status("bleed", 3) # Example: apply bleed for 3 turns
	else:
		print("Target for Shadow Strike is invalid.")

# Override the base signature_skill_1
func signature_skill_1(targets: Array[BaseCharacter]):
	shadow_strike(targets)

# Placeholder for other skills
# func signature_skill_2(targets: Array[BaseCharacter]):
#   print("%s uses Vanish!" % name) # Example: Become invisible or increase evasion

# func ultimate_skill(targets: Array[BaseCharacter]):
#   print("%s executes Heartseeker!" % name) # Example: Massive single target damage, executes if HP low
