extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Layouts/cabinet.tscn"

@onready var startButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var quitButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	startButton.pressed.connect(_on_start_pressed)
	quitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)
	
func _on_quit_pressed() -> void:
	get_tree().quit()
