extends Node
class_name ScoreManager

var current_score: int = 0

signal score_changed(new_score)

# Score event types (can be expanded)
enum ScoreEvent {
	ENEMY_DEFEATED_NORMAL,
	ENEMY_DEFEATED_ELITE,
	ENEMY_DEFEATED_BOSS,
	DAMAGE_DEALT, # Per point of damage, or per hit? Let's say per point.
	STAGE_CLEARED,
	WAVE_CLEARED,
	CRITICAL_HIT_LANDED,
	NO_DAMAGE_WAVE, # Bonus for not taking damage in a wave
	FLAWLESS_STAGE # Bonus for clearing a stage without any character dying
}

# Points for each event (configurable)
const SCORE_VALUES = {
	ScoreEvent.ENEMY_DEFEATED_NORMAL: 100,
	ScoreEvent.ENEMY_DEFEATED_ELITE: 300, # Assuming some way to classify enemies
	ScoreEvent.ENEMY_DEFEATED_BOSS: 1000,
	ScoreEvent.DAMAGE_DEALT: 1, # 1 point per point of damage
	ScoreEvent.STAGE_CLEARED: 500,
	ScoreEvent.WAVE_CLEARED: 50,
	ScoreEvent.CRITICAL_HIT_LANDED: 25,
	ScoreEvent.NO_DAMAGE_WAVE: 150,
	ScoreEvent.FLAWLESS_STAGE: 750
}

func _ready():
	print("Score Manager ready. Initial score: %s" % current_score)
	emit_signal("score_changed", current_score)

func add_score(points: int, event_type: ScoreEvent = -1, event_description: String = ""):
	if points <= 0:
		return

	current_score += points
	print("Score added: %s. New total: %s." % [points, current_score])
	if event_type != -1 and event_description != "":
		print("Reason: %s (%s)" % [event_description, ScoreEvent.keys()[event_type]])
	elif event_description != "":
		print("Reason: %s" % event_description)

	emit_signal("score_changed", current_score)

func get_score() -> int:
	return current_score

func reset_score():
	current_score = 0
	print("Score reset to 0.")
	emit_signal("score_changed", current_score)

# --- Public methods to be called by other systems ---

func on_enemy_defeated(enemy_node: BaseCharacter): # Pass the enemy node to determine its type/value
	# Basic classification for now, could be more sophisticated (e.g. enemy.enemy_class property)
	var points = SCORE_VALUES[ScoreEvent.ENEMY_DEFEATED_NORMAL]
	var description = "Defeated %s" % enemy_node.name

	# Example: Check if enemy name suggests it's tougher, or if it has a specific property
	if enemy_node.name.contains("Brute") or enemy_node.name.contains("Shadow"): # Simple check
		points = SCORE_VALUES[ScoreEvent.ENEMY_DEFEATED_ELITE]
		description = "Defeated Elite: %s" % enemy_node.name
	# elif enemy_node.is_boss: # if you add an 'is_boss' property
	#   points = SCORE_VALUES[ScoreEvent.ENEMY_DEFEATED_BOSS]
	#   description = "Defeated Boss: %s" % enemy_node.name

	add_score(points, ScoreEvent.ENEMY_DEFEATED_NORMAL, description) # Event type is generic here for simplicity of calling add_score

func on_damage_dealt(damage_amount: int):
	if damage_amount > 0:
		add_score(damage_amount * SCORE_VALUES[ScoreEvent.DAMAGE_DEALT], ScoreEvent.DAMAGE_DEALT, "%s damage dealt" % damage_amount)

func on_stage_cleared(stage_number: int):
	add_score(SCORE_VALUES[ScoreEvent.STAGE_CLEARED], ScoreEvent.STAGE_CLEARED, "Stage %s cleared" % stage_number)

func on_wave_cleared(wave_number: int):
	add_score(SCORE_VALUES[ScoreEvent.WAVE_CLEARED], ScoreEvent.WAVE_CLEARED, "Wave %s cleared" % wave_number)

func on_critical_hit_landed(character_name: String):
	add_score(SCORE_VALUES[ScoreEvent.CRITICAL_HIT_LANDED], ScoreEvent.CRITICAL_HIT_LANDED, "%s landed a critical hit" % character_name)

func on_no_damage_wave_bonus():
	add_score(SCORE_VALUES[ScoreEvent.NO_DAMAGE_WAVE], ScoreEvent.NO_DAMAGE_WAVE, "Flawless wave bonus")

func on_flawless_stage_bonus(stage_number: int):
	add_score(SCORE_VALUES[ScoreEvent.FLAWLESS_STAGE], ScoreEvent.FLAWLESS_STAGE, "Flawless Stage %s bonus (no deaths)" % stage_number)

# Example of how other systems might connect:
# In CombatManager, when an enemy dies:
# score_manager.on_enemy_defeated(enemy_node)
# In BaseCharacter, when dealing damage (after calculating actual damage):
# score_manager.on_damage_dealt(actual_damage)
# When landing a critical hit in BaseCharacter's attack:
# score_manager.on_critical_hit_landed(self.name)
# In StageManager, when a stage is completed:
# score_manager.on_stage_cleared(stage_number)
# In StageManager, when a wave is completed:
# score_manager.on_wave_cleared(wave_number)
# Potentially, StageManager could track damage taken per wave/stage to award bonuses.
