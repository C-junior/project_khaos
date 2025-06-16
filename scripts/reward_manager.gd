extends Node
class_name RewardManager

# Dependencies
var score_manager: ScoreManager

signal reward_unlocked(reward_id, reward_description)
signal covenant_rank_up(new_rank_name)

# --- Reward Definitions ---
# Rewards can be more complex (e.g., custom Resource types)
# For now, using dictionaries.
# "type" could be "artifact", "skin", "covenant_rank", "currency", etc.
# "value" would be the specific item or rank.
var score_threshold_rewards: Array = [
	{"score_needed": 1000, "id": "unlock_artifact_healing_orb", "type": "artifact", "value": "HealingOrb", "description": "New Artifact Unlocked: Healing Orb - Occasionally heals the wielder.", "unlocked": false},
	{"score_needed": 2500, "id": "covenant_rank_1", "type": "covenant_rank", "value": "Iron Covenant", "description": "Covenant Rank Up: Iron! (+2% base HP for all characters)", "unlocked": false},
	{"score_needed": 5000, "id": "unlock_skin_elara_guardian", "type": "skin", "value": {"character": "Elara", "skin_name": "Guardian"}, "description": "New Skin Unlocked: Guardian Elara.", "unlocked": false},
	{"score_needed": 7500, "id": "unlock_artifact_warhorn", "type": "artifact", "value": "Warhorn", "description": "New Artifact Unlocked: Warhorn - Boosts party attack at battle start.", "unlocked": false},
	{"score_needed": 10000, "id": "covenant_rank_2", "type": "covenant_rank", "value": "Bronze Covenant", "description": "Covenant Rank Up: Bronze! (+5% base HP & ATK for all characters)", "unlocked": false},
	# New reward for the fully formed Crimson Veil
	{"score_needed": 12000, "id": "unlock_crimson_veil_fully_formed", "type": "special_artifact", "value": "CrimsonVeil", "description": "The Crimson Veil is now fully formed! Its power against the abyss is awakened.", "unlocked": false}
]

# Other event-based rewards (not solely score-based) could be handled differently
# e.g., completing a specific difficult stage, defeating a secret boss.

var current_covenant_rank: String = "Unranked"

func _ready():
	print("Reward Manager ready.")

func set_dependencies(sm: ScoreManager):
	score_manager = sm
	if score_manager:
		# Connect to score_changed to check for rewards when score updates
		if not score_manager.is_connected("score_changed", Callable(self, "_on_score_changed")):
			score_manager.score_changed.connect(_on_score_changed)
	else:
		printerr("RewardManager: ScoreManager dependency not set!")

func _on_score_changed(new_score: int):
	# print("RewardManager: Score changed to %s. Checking for rewards." % new_score)
	check_for_score_rewards(new_score)

func check_for_score_rewards(current_score_value: int):
	for reward_data in score_threshold_rewards:
		if not reward_data.unlocked and current_score_value >= reward_data.score_needed:
			unlock_reward(reward_data)
			# Keep checking, player might unlock multiple rewards at once if score jump is large

func unlock_reward(reward_data: Dictionary):
	reward_data.unlocked = true # Mark as unlocked to prevent multiple grants
	emit_signal("reward_unlocked", reward_data.id, reward_data.description)
	print_rich("[color=gold]Reward Unlocked![/color] %s" % reward_data.description)

	match reward_data.type:
		"artifact":
			# Here, you'd typically add the artifact to a global list of available artifacts
			# that can then be dropped by StageManager or found in shops.
			# For now, just log it.
			# Example: GlobalUnlockSystem.add_available_artifact(reward_data.value)
			print("Artifact '%s' is now available in the world." % reward_data.value)
			# Potentially, StageManager's available_artifact_scripts could be updated if it's a shared resource.
			# Or, if artifacts are .tres files, this might involve adding to a list of loadable paths.
			# Example: if not GlobalArtifactList.has(reward_data.value): GlobalArtifactList.append(reward_data.value)
		"special_artifact": # For Crimson Veil specifically
			if reward_data.value == "CrimsonVeil":
				# This is where we'd signal Game.gd or a PlayerInventory to add the Veil
				# and mark it as fully_formed.
				# For now, we assume Game.gd will listen for this reward_unlocked signal
				# and then instantiate/configure the CrimsonVeilRelic.
				print("Crimson Veil is marked as fully formed and available to the player.")
				# To actually make it usable:
				# 1. Game.gd listens for this reward_id.
				# 2. Game.gd creates/gets the CrimsonVeilRelic instance.
				# 3. Game.gd calls a method like `found_crimson_veil()` on that instance.
				# 4. Player gets the artifact (e.g. Game._on_artifact_dropped(veil_instance) )
				# This is complex because the artifact instance needs to be shared/managed.
				# The simplest for now: emit the signal, Game.gd handles it.
				pass # The reward_unlocked signal already carries the description.
		"skin":
			var skin_info = reward_data.value
			print("Skin '%s' for character '%s' unlocked." % [skin_info.skin_name, skin_info.character])
			# Example: PlayerProfile.unlock_skin(skin_info.character, skin_info.skin_name)
		"covenant_rank":
			current_covenant_rank = reward_data.value
			emit_signal("covenant_rank_up", current_covenant_rank)
			print("Player achieved Covenant Rank: %s" % current_covenant_rank)
			# Apply global effects of covenant rank if any
			# apply_covenant_rank_bonuses(current_covenant_rank)
		_:
			print("Unhandled reward type: %s" % reward_data.type)

func get_covenant_rank() -> String:
	return current_covenant_rank

func get_unlocked_rewards_summary() -> Array[String]:
	var summary: Array[String] = []
	for reward_data in score_threshold_rewards:
		if reward_data.unlocked:
			summary.append(reward_data.description)
	return summary

# Example: function to apply permanent bonuses from Covenant Ranks
# func apply_covenant_rank_bonuses(rank_name: String):
#   match rank_name:
#       "Iron Covenant":
#           # Modify global player stats or character base stats upon creation
#           # GlobalStats.base_hp_modifier += 0.02
#           print("Applying Iron Covenant bonus: +2% base HP to all characters.")
#       "Bronze Covenant":
#           # GlobalStats.base_hp_modifier += 0.03 # Additional 3% for a total of 5%
#           # GlobalStats.base_atk_modifier += 0.05
#           print("Applying Bronze Covenant bonus: +5% base HP & ATK to all characters.")
#   # This would require characters to fetch these global modifiers when initializing
#   # or a system to retroactively apply them.

func reset_rewards_progress():
	for reward_data in score_threshold_rewards:
		reward_data.unlocked = false
	current_covenant_rank = "Unranked"
	print("Rewards progress has been reset.")

# Future: Implement checks for other types of rewards (not just score-based)
# func check_for_achievement_rewards(achievement_id: String):
#   ...
#   unlock_reward(achievement_reward_data)
