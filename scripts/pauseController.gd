extends CanvasLayer

@export_file("*.tscn") var title_scene_path: String = "res://scenes/main_menu.tscn"
@export var settingsPanel: PanelContainer
@export var runManager: RunManager

@onready var pauseMenu: Control = $PauseMenu
@onready var resumeButton: Button = $PauseMenu/MarginContainer/VBoxContainer/ResumeButton
@onready var settingsButton: Button = $PauseMenu/MarginContainer/VBoxContainer/SettingsButton
@onready var restartButton: Button = $PauseMenu/MarginContainer/VBoxContainer/RestartRunButton
@onready var titleButton: Button = $PauseMenu/MarginContainer/VBoxContainer/ReturnToTitleButton
@onready var quitConfirmPanel: Control = $QuitConfirmPanel

var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pauseMenu.visible = false
	quitConfirmPanel.visible = false
	
	resumeButton.pressed.connect(resume_game)
	settingsButton.pressed.connect(_on_settings_pressed)
	restartButton.pressed.connect(_on_restart_pressed)
	titleButton.pressed.connect(_on_return_to_title_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		print("PAUSE INPUT DETECTED")
		toggle_pause()
		get_viewport().set_input_as_handled()
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()
		
func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	pauseMenu.visible = true
	
func resume_game() -> void:
	is_paused = false
	pauseMenu.visible = false
	quitConfirmPanel.visible = false
	get_tree().paused = false
	
func _on_settings_pressed() -> void:
	if settingsPanel == null:
		push_warning("PauseController needs SettingsPanel assigned.")
		return
		
	settingsPanel.open()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	
	if runManager != null:
		runManager.start_new_run()
		
func _on_return_to_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)
