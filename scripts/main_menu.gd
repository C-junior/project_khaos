extends Control

@export var start_button_texture: Texture
@export var quit_button_texture: Texture

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton

func _ready():
	if start_button_texture:
		if start_button:
			start_button.icon = start_button_texture
		else:
			printerr("StartButton node not found in MainMenu for texture assignment.")

	if quit_button_texture:
		if quit_button:
			quit_button.icon = quit_button_texture
		else:
			printerr("QuitButton node not found in MainMenu for texture assignment.")

func _on_start_button_pressed():
	print("Start button pressed")
	# In a real game, you'd likely change scenes here:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_button_pressed():
	print("Quit button pressed")
	get_tree().quit()
