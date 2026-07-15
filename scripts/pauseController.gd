extends CanvasLayer

@export_file("*.tscn") var title_scene_path: String = "res://scenes/main_menu.tscn"
@export var settingsPanel: PanelContainer
@export var runManager: RunManager
@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream

@onready var pauseMenu: Control = $PauseMenu
@onready var resumeButton: Button = $PauseMenu/MarginContainer/VBoxContainer/ResumeButton
@onready var settingsButton: Button = $PauseMenu/MarginContainer/VBoxContainer/SettingsButton
@onready var restartButton: Button = $PauseMenu/MarginContainer/VBoxContainer/RestartRunButton
@onready var titleButton: Button = $PauseMenu/MarginContainer/VBoxContainer/ReturnToTitleButton
@onready var quitConfirmPanel: Control = $QuitConfirmPanel
@onready var titleLabel: Label = $PauseMenu/MarginContainer/VBoxContainer/TitleLabel

var is_paused: bool = false
const TITLE_COLOR := Color("#FFD36A")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pauseMenu.custom_minimum_size = Vector2(300, 220)
	pauseMenu.anchor_left = 0.5
	pauseMenu.anchor_top = 0.5
	pauseMenu.anchor_right = 0.5
	pauseMenu.anchor_bottom = 0.5
	pauseMenu.offset_left = -150.0
	pauseMenu.offset_top = -110.0
	pauseMenu.offset_right = 150.0
	pauseMenu.offset_bottom = 110.0
	
	var margin_container := $PauseMenu/MarginContainer
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.offset_left = 0.0
	margin_container.offset_top = 0.0
	margin_container.offset_right = 0.0
	margin_container.offset_bottom = 0.0
	margin_container.add_theme_constant_override("margin_left", 24)
	margin_container.add_theme_constant_override("margin_right", 24)
	margin_container.add_theme_constant_override("margin_top", 24)
	margin_container.add_theme_constant_override("margin_bottom", 24)
	
	var vbox := $PauseMenu/MarginContainer/VBoxContainer
	vbox.add_theme_constant_override("separation", 8)
	titleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titleLabel.add_theme_color_override("font_color", TITLE_COLOR)
	titleLabel.add_theme_font_size_override("font_size", 14)
	
	resumeButton.custom_minimum_size = Vector2(140, 28)
	settingsButton.custom_minimum_size = Vector2(140, 28)
	restartButton.custom_minimum_size = Vector2(140, 28)
	titleButton.custom_minimum_size = Vector2(140, 28)
	resumeButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settingsButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restartButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	titleButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	pauseMenu.visible = false
	quitConfirmPanel.visible = false
	
	resumeButton.pressed.connect(resume_game)
	settingsButton.pressed.connect(_on_settings_pressed)
	restartButton.pressed.connect(_on_restart_pressed)
	titleButton.pressed.connect(_on_return_to_title_pressed)
	resumeButton.mouse_entered.connect(_on_button_hovered)
	settingsButton.mouse_entered.connect(_on_button_hovered)
	restartButton.mouse_entered.connect(_on_button_hovered)
	titleButton.mouse_entered.connect(_on_button_hovered)

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
	SFXManager.play_sfx(button_click_sfx)
	if settingsPanel == null:
		push_warning("PauseController needs SettingsPanel assigned.")
		return
		
	settingsPanel.open()

func _on_restart_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().paused = false
	
	if runManager != null:
		runManager.start_new_run()
		
func _on_return_to_title_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)

func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx, -6.0)
