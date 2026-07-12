extends PanelContainer

@export var helpButton: Button
@export var runManager: RunManager

@onready var closeButton: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	
	if helpButton == null:
		push_warning("HelpPanel needs HelpButton Assigned.")
	else:
		helpButton.pressed.connect(_on_help_pressed)

	closeButton.pressed.connect(_on_close_pressed)
	
func _on_help_pressed() -> void:
	if visible:
		return

	if runManager != null:
		runManager.request_ui_timer_pause()

	visible = true
	
func _on_close_pressed() -> void:
	close()

func close() -> void:
	if not visible:
		return
	
	visible = false
	
	if runManager != null:
		runManager.release_ui_timer_pause()
