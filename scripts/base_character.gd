extends Node2D
class_name BaseCharacter

# Export variables for character stats
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var attack_power: int = 10
@export var defense: int = 5
@export var crit_chance: float = 0.1 # 0.0 to 1.0
@export var crit_damage_multiplier: float = 1.5 # e.g., 1.5 for 150% damage
@export var speed: int = 10 # Determines turn order or action frequency

var audio_manager # Set by CombatManager or Game for direct sfx calls from character if needed.

@onready var hp_label: Label = $HPLabel
@onready var sprite: Sprite2D = $Sprite2D
# @onready var animation_player: AnimationPlayer = $AnimationPlayer # If animations are added

signal health_changed(new_hp, max_hp)
signal died
signal critical_hit_landed_by_character(attacker_name) # For score system

func _ready():
	update_hp_label()
	# You might want to emit health_changed here if current_hp can start differently from max_hp
	# emit_signal("health_changed", current_hp, max_hp)

func update_hp_label():
	if hp_label:
		hp_label.text = "HP: %s/%s" % [current_hp, max_hp]

func take_damage(damage_amount: int):
	var actual_damage = damage_amount - defense
	if actual_damage < 0:
		actual_damage = 0

	current_hp -= actual_damage
	if current_hp < 0:
		current_hp = 0

	print("%s takes %s damage. Current HP: %s" % [name, actual_damage, current_hp])
	if audio_manager and actual_damage > 0: audio_manager.play_sfx("generic_hit_sfx") # Placeholder

	update_hp_label()
	emit_signal("health_changed", current_hp, max_hp)

	if current_hp == 0:
		die()

	return actual_damage # Return the actual damage taken

func heal(heal_amount: int):
	current_hp += heal_amount
	if current_hp > max_hp:
		current_hp = max_hp

	print("%s heals for %s. Current HP: %s" % [name, heal_amount, current_hp])
	update_hp_label()
	emit_signal("health_changed", current_hp, max_hp)

func die():
	print("%s has died." % name)
	emit_signal("died")
	# Add logic for death, like playing an animation, disabling the node, etc.
	# For now, we can just hide the character
	# visible = false
	# Or queue_free() if the character should be removed from the scene
	# queue_free()


# Placeholder for attack function
func attack(target: BaseCharacter):
	if not is_instance_valid(target):
		print("%s attack failed: target is invalid." % name)
		return

	print("%s attacks %s." % [name, target.name])
	var damage = attack_power
	var is_critical = randf() < crit_chance
	if is_critical:
		damage = int(damage * crit_damage_multiplier)
		print("Critical Hit!")
		emit_signal("critical_hit_landed_by_character", self.name)

	return target.take_damage(damage) # Return the actual_damage value

# --- Virtual methods for character-specific skills ---
# These are intended to be overridden by derived character scripts.

func signature_skill_1(targets: Array[BaseCharacter]):
	print("%s uses Signature Skill 1 (Not Implemented)" % name)
	# Base implementation or pass

func signature_skill_2(targets: Array[BaseCharacter]):
	print("%s uses Signature Skill 2 (Not Implemented)" % name)
	# Base implementation or pass

func ultimate_skill(targets: Array[BaseCharacter]):
	print("%s uses Ultimate Skill (Not Implemented)" % name)
	# Base implementation or pass

# Utility to set sprite texture - useful for derived classes
func set_sprite_texture(texture_path: String):
	var loaded_texture = load(texture_path)
	if loaded_texture:
		sprite.texture = loaded_texture
	else:
		print("Failed to load texture: %s" % texture_path)
