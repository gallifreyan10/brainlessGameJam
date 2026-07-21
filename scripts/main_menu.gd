extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Layouts/cabinet.tscn"
@export var menu_music: AudioStream
@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream
@export var credits_music: AudioStream

@onready var startButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var settingsButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var creditsButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CreditsButton
@onready var quitButton: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton
@onready var settingsPanel: PanelContainer = $SettingsPanel
@onready var creditsPanel: PanelContainer = $CreditsPanel
@onready var creditsScrollContainer: ScrollContainer = $CreditsPanel/MarginContainer/VBoxContainer/ScrollContainer
@onready var creditsCloseButton: Button = $CreditsPanel/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	creditsPanel.visible = false
	settingsPanel.visible = false
	
	startButton.pressed.connect(_on_start_pressed)
	settingsButton.pressed.connect(_on_settings_pressed)
	quitButton.pressed.connect(_on_quit_pressed)
	creditsButton.pressed.connect(_on_credits_pressed)
	creditsCloseButton.pressed.connect(_on_credits_close_pressed)
	startButton.mouse_entered.connect(_on_button_hovered)
	settingsButton.mouse_entered.connect(_on_button_hovered)
	creditsButton.mouse_entered.connect(_on_button_hovered)
	quitButton.mouse_entered.connect(_on_button_hovered)
	creditsCloseButton.pressed.connect(_on_button_hovered)
	
	if PlayerProgress.consume_credits_on_menu_load():
		_on_credits_pressed()
	else:
		MusicManager.play_music(menu_music)

func _on_start_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	PlayerProgress.clear_credits_on_menu_load()
	creditsPanel.visible = false
	get_tree().change_scene_to_file(game_scene_path)

func _on_settings_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	settingsPanel.open()
	
func _on_quit_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().quit()

func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx, -6.0)

func _on_credits_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	MusicManager.play_music(credits_music)
	creditsPanel.visible = true
	
	if creditsScrollContainer.has_method("restart_scroll"):
		creditsScrollContainer.call("restart_scroll")
	
func _on_credits_close_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	creditsPanel.visible = false
	MusicManager.play_music(menu_music)
