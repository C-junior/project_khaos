extends Resource # Artifacts are best represented as Resources
class_name BaseArtifact

@export var artifact_name: String = "Unnamed Artifact"
@export_multiline var description: String = "No description provided."

# Describes the primary effect of the artifact
@export_multiline var base_effect_description: String = "Grants a basic bonus."

# Describes the additional effect when paired with a specific accessory (conceptual for now)
@export_multiline var resonant_accessory_description: String = "Unlocks a hidden power when paired with its resonant accessory."

# --- Virtual methods to be overridden by specific artifacts ---

# Called when the artifact is equipped or its effect needs to be applied.
# 'character' is expected to be a BaseCharacter node.
func apply_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_effect for %s." % artifact_name)
		return
	print("Applying base effect of %s to %s (Not Implemented)" % [artifact_name, character.name])
	# Example: character.attack_power += 5
	pass

# Called if a resonant accessory is also equipped.
# 'character' is expected to be a BaseCharacter node.
func apply_resonant_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in apply_resonant_effect for %s." % artifact_name)
		return
	print("Applying resonant effect of %s to %s (Not Implemented)" % [artifact_name, character.name])
	# Example: character.crit_chance += 0.1
	pass

# Optional: Function to remove effects if the artifact is unequipped
func remove_effect(character: BaseCharacter):
	if not is_instance_valid(character):
		print("Invalid character reference in remove_effect for %s." % artifact_name)
		return
	print("Removing effects of %s from %s (Not Implemented - ensure to revert stat changes)" % [artifact_name, character.name])
	# Example: character.attack_power -= 5 (if it was added in apply_effect)
	pass

# Helper to get a summary of the artifact
func get_tooltip_text() -> String:
	var tooltip = "%s\n" % artifact_name
	tooltip += "Effect: %s\n" % base_effect_description
	if not resonant_accessory_description.is_empty():
		tooltip += "Resonance: %s" % resonant_accessory_description
	return tooltip.strip_edges()

func _init():
	# Ensure artifacts are properly initialized if created directly
	# This is more relevant if you are creating Resource files (.tres) for each artifact
	pass
