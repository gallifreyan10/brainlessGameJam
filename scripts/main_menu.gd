extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Layouts/cabinet.tscn"
@export var menu_music: AudioStream
@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream

@onready var startButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var quitButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	startButton.pressed.connect(_on_start_pressed)
	quitButton.pressed.connect(_on_quit_pressed)
	startButton.mouse_entered.connect(_on_button_hovered)
	quitButton.mouse_entered.connect(_on_button_hovered)
	MusicManager.play_music(menu_music)

func _on_start_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().change_scene_to_file(game_scene_path)
	
func _on_quit_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().quit()

func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx, -6.0)
