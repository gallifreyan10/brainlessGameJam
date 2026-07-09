extends PanelContainer

@export var helpButton: Button

@onready var closeButton: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	
	if helpButton == null:
		push_warning("HelpPanel needs HelpButton Assigned.")
	else:
		helpButton.pressed.connect(_on_help_pressed)

	closeButton.pressed.connect(_on_close_pressed)
	
func _on_help_pressed() -> void:
	visible = true
	
func _on_close_pressed() -> void:
	visible = false
