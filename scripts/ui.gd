extends Control

@onready var player_stats_label: Label = $PlayerStatsLabel
@onready var score_label: Label = $ScoreLabel
@onready var reward_notification_label: Label = $RewardNotificationLabel
@onready var hp_icon_rect: TextureRect = $HPIcon # Added
@onready var total_score_icon_rect: TextureRect = $TotalScoreIcon # Added

@export var hp_icon_texture: Texture
@export var total_score_icon_texture: Texture

var notification_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	print("UI scene loaded")
	update_stats(100, 0)
	update_score_display(0)

	if hp_icon_texture and hp_icon_rect:
		hp_icon_rect.texture = hp_icon_texture
	if total_score_icon_texture and total_score_icon_rect:
		total_score_icon_rect.texture = total_score_icon_texture

	# Timer for hiding notification
	notification_timer = Timer.new()
	notification_timer.wait_time = 5.0 # Show notification for 5 seconds
	notification_timer.one_shot = true
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	add_child(notification_timer)


func update_stats(health, score): # This 'score' is player's individual score, not total game score
	player_stats_label.text = "Health: %s\nScore: %s" % [health, score]

func update_score_display(total_score: int):
	if score_label:
		score_label.text = "Total Score: %s" % total_score

func show_reward_notification(message: String):
	if reward_notification_label:
		reward_notification_label.text = message
		reward_notification_label.visible = true
		notification_timer.start()

func _on_notification_timer_timeout():
	if reward_notification_label:
		reward_notification_label.visible = false

# Example of how you might connect this to a player's signals:
# func _on_player_health_changed(new_health):
#   update_stats(new_health, current_score) # Assuming current_score is stored somewhere
#
# func _on_player_score_changed(new_score):
#   update_stats(current_health, new_score) # Assuming current_health is stored somewhere
