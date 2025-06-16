extends Control

func _on_start_button_pressed():
	# Placeholder for starting the game
	# For now, just print a message
	print("Start button pressed")
	# In a real game, you'd likely change scenes here:
	# get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_button_pressed():
	# Quit the game
	print("Quit button pressed")
	get_tree().quit()
