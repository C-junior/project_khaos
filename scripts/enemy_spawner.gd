extends Node
class_name EnemySpawner

# Preload enemy scenes or define enemy data
# Using BaseCharacterScene for all for now, but ideally you'd have specific scenes
const BaseCharacterScene = preload("res://scenes/base_character.tscn")
const ElaraScene = preload("res://scenes/elara.tscn") # For the "elara_clone"

# Could also be a Dictionary mapping type strings to PackedScenes
var enemy_templates: Dictionary = {}

var current_wave_enemies: Array[BaseCharacter] = []

# Parent node for spawned enemies, usually the Game node or a specific layer
@export var spawn_parent_path: NodePath = NodePath("..") # Defaults to parent of EnemySpawner (i.e. Game node)
var spawn_parent: Node

# Define base stats or configurations for different enemy types
# This could be much more extensive, possibly loading from files or resources
var enemy_type_data: Dictionary = {
	"goblin_grunt": {
		"name": "Goblin Grunt",
		"scene": BaseCharacterScene,
		"stats": {"max_hp": 40, "current_hp": 40, "attack_power": 7, "defense": 3, "speed": 8, "crit_chance": 0.05, "crit_damage_multiplier": 1.5},
		"sprite": null # Example: "res://assets/art/enemies/goblin_grunt_sprite.png"
	},
	"orc_brute": {
		"name": "Orc Brute",
		"scene": BaseCharacterScene,
		"stats": {"max_hp": 75, "current_hp": 75, "attack_power": 12, "defense": 5, "speed": 6, "crit_chance": 0.05, "crit_damage_multiplier": 1.5},
		"sprite": null # Example: "res://assets/art/enemies/orc_brute_sprite.png"
	},
	"elara_clone": {
		"name": "Elara's Shadow",
		"scene": ElaraScene,
		"stats": {"max_hp": 90, "current_hp": 90, "attack_power": 12, "defense": 4, "speed": 12, "crit_chance": 0.15, "crit_damage_multiplier": 1.6},
		"sprite": null # Example: "res://assets/art/enemies/elara_shadow_sprite.png"
	},
	"wraith": {
		"name": "Wraith", "scene": BaseCharacterScene,
		"stats": {"max_hp": 60, "current_hp": 60, "attack_power": 10, "defense": 5, "speed": 11, "crit_chance": 0.1, "crit_damage_multiplier": 1.5},
		"sprite": null
	},
	"skeleton_warrior": {
		"name": "Skeleton Warrior", "scene": BaseCharacterScene,
		"stats": {"max_hp": 70, "current_hp": 70, "attack_power": 12, "defense": 8, "speed": 7, "crit_chance": 0.05, "crit_damage_multiplier": 1.5},
		"sprite": null
	},
	"cultist_acolyte": {
		"name": "Cultist Acolyte", "scene": BaseCharacterScene,
		"stats": {"max_hp": 50, "current_hp": 50, "attack_power": 9, "defense": 4, "speed": 9, "crit_chance": 0.1, "crit_damage_multiplier": 1.6},
		"sprite": null
	},
	"demon_imp": {
		"name": "Demon Imp", "scene": BaseCharacterScene,
		"stats": {"max_hp": 40, "current_hp": 40, "attack_power": 8, "defense": 3, "speed": 12, "crit_chance": 0.05, "crit_damage_multiplier": 1.5},
		"sprite": null
	},
	"lava_elemental": {
		"name": "Lava Elemental", "scene": BaseCharacterScene,
		"stats": {"max_hp": 90, "current_hp": 90, "attack_power": 14, "defense": 6, "speed": 5, "crit_chance": 0.05, "crit_damage_multiplier": 1.7},
		"sprite": null
	},
	"lilithar_boss": {
		"name": "Lilithar, Empress of Torment",
		"scene": preload("res://scenes/lilithar.tscn"),
		"stats": {},
		"sprite": null # Sprite is handled by Lilithar.tscn's own exported character_sprite_texture or its script.
	}
}

# Predefined spawn positions for enemies (example)
# These could be more dynamic or based on formation templates.
var enemy_spawn_positions: Array[Vector2] = [
	Vector2(700, 250),
	Vector2(750, 350),
	Vector2(800, 200),
	Vector2(850, 400)
]
var next_spawn_pos_idx = 0


func _ready():
	print("Enemy Spawner ready.")
	spawn_parent = get_node_or_null(spawn_parent_path)
	if not spawn_parent:
		printerr("EnemySpawner: Spawn parent node not found at path: %s. Defaulting to self's parent." % spawn_parent_path)
		spawn_parent = get_parent()

	# Populate enemy_templates if not using direct scene access in enemy_type_data
	# For example, if "scene" was a string path:
	# for type in enemy_type_data:
	#   enemy_templates[type] = load(enemy_type_data[type]["scene_path"])


func spawn_enemy(enemy_type_id: String, position: Vector2) -> BaseCharacter:
	if not enemy_type_data.has(enemy_type_id):
		printerr("Unknown enemy type: %s" % enemy_type_id)
		return null

	var data = enemy_type_data[enemy_type_id]
	var enemy_scene: PackedScene = data.scene # This now directly references the loaded scene

	if not enemy_scene:
		printerr("Scene not found for enemy type: %s" % enemy_type_id)
		return null

	var enemy_instance = enemy_scene.instantiate() as BaseCharacter
	if not enemy_instance:
		printerr("Failed to instance enemy: %s" % enemy_type_id)
		return null

	# Apply base stats and name
	enemy_instance.name = data.name # Node name

	for stat_name in data.stats:
		if enemy_instance.has_meta(stat_name):
			enemy_instance.set(stat_name, data.stats[stat_name])
		elif stat_name in enemy_instance:
			enemy_instance.set(stat_name, data.stats[stat_name])
		# else: printerr("Warning: Stat '%s' not found on enemy instance %s" % [stat_name, enemy_instance.name]) # Can be noisy

	if data.stats.has("max_hp") and not data.stats.has("current_hp"):
		enemy_instance.current_hp = data.stats.max_hp
	elif not data.stats.has("max_hp") and not data.stats.has("current_hp"):
		enemy_instance.current_hp = enemy_instance.max_hp

	# Set sprite texture if path is provided in enemy_type_data
	var sprite_path_string = data.get("sprite", null) # Get sprite path, default to null
	if sprite_path_string and not sprite_path_string.is_empty():
		var enemy_texture: Texture = load(sprite_path_string)
		if enemy_texture:
			if enemy_instance.has_method("set_sprite_texture"):
				enemy_instance.set_sprite_texture(enemy_texture)
			else:
				printerr("Enemy instance %s does not have set_sprite_texture method." % enemy_instance.name)
		else:
			printerr("Failed to load enemy texture: %s for %s" % [sprite_path_string, enemy_instance.name])

	enemy_instance.position = position

	# Update HP Label after stats are set
	if enemy_instance.has_method("update_hp_label"):
		enemy_instance.update_hp_label()

	spawn_parent.add_child(enemy_instance)
	current_wave_enemies.append(enemy_instance)
	print("Spawned %s at %s" % [enemy_instance.name, position])
	return enemy_instance

func spawn_wave(enemies_to_spawn_data: Array) -> Array[BaseCharacter]: # Data like [{"type": "goblin", "count": 2}, ...]
	cleanup_current_wave_enemies() # Clear any previous wave's enemies
	next_spawn_pos_idx = 0 # Reset spawn position index for the new wave

	var spawned_enemies_in_wave: Array[BaseCharacter] = []
	var current_spawn_index = 0

	for enemy_group in enemies_to_spawn_data:
		var type = enemy_group.type
		var count = enemy_group.count
		var pos: Vector2 # Declare pos here
		for i in range(count):
			if current_spawn_index >= enemy_spawn_positions.size():
				printerr("Not enough unique spawn positions defined for all enemies in wave.")
				# Fallback: reuse positions or spawn at a default offset
				pos = enemy_spawn_positions[current_spawn_index % enemy_spawn_positions.size()] + Vector2(randf_range(-20,20), randf_range(-20,20))
			else:
				pos = enemy_spawn_positions[current_spawn_index]

			var enemy = spawn_enemy(type, pos)
			if enemy:
				spawned_enemies_in_wave.append(enemy)
			current_spawn_index += 1

	return spawned_enemies_in_wave

func cleanup_current_wave_enemies():
	for enemy in current_wave_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_wave_enemies.clear()
	print("Cleaned up previous wave enemies.")

func get_current_wave_enemy_nodes() -> Array[BaseCharacter]:
	return current_wave_enemies
