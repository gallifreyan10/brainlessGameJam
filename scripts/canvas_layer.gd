extends CanvasLayer

@onready var collection_button: Button = $CollectionButton
@onready var alien_collection_panel: PanelContainer = $"AlienCollectionPanel"
@onready var abilities_button: Button = $AbilitiesButton
@onready var active_abilities_panel: PanelContainer = $ActiveAbilitiesPanel

func _ready() -> void:
	collection_button.pressed.connect(_on_collection_button_pressed)
	abilities_button.pressed.connect(_on_abilities_button_pressed)

func _on_collection_button_pressed() -> void:
	alien_collection_panel.open()
	
func _on_abilities_button_pressed() -> void:
	active_abilities_panel.open()
