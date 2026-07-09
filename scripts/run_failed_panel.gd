extends PanelContainer


@export var runManager: RunManager

@onready var messageLabel: Label = $VBoxContainer/MessageLabel
@onready var newRunButton: Button = $VBoxContainer/NewRunButton
@onready var mainMenuButton: Button = $VBoxContainer/MainMenuButton

func _ready() -> void:
	visible = false
	
	if runManager == null:
		push_error("RunFailedPanel needs RunManager assigned.")
		return
	
	runManager.runFailed.connect(_on_run_failed)
	runManager.levelStarted.connect(_on_level_started)
	
	newRunButton.pressed.connect(_on_newRun_pressed)
	mainMenuButton.pressed.connect(_on_mainmenu_pressed)

func _on_run_failed(_levelIndex: int, earned: int, quota: int) -> void:
	visible = true
	messageLabel.text = "Earned %d / %d" % [earned, quota]

func _on_level_started(_levelIndex: int, _data: LevelData) -> void:
	visible = false
	
func _on_newRun_pressed() -> void:
	visible = false
	runManager.start_new_run()

func _on_mainmenu_pressed() -> void:
	pass	
