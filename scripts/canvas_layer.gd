extends CanvasLayer

@onready var collection_button: Button = $CollectionButton
@onready var alien_collection_panel: PanelContainer = $"AlienCollectionPanel"
@onready var abilities_button: Button = $AbilitiesButton
@onready var active_abilities_panel: PanelContainer = $ActiveAbilitiesPanel
@onready var ownedSuits_button: Button = $OwnedSuitsButton
@onready var ownedSuits_panel: PanelContainer = $OwnedSuitsPanel

@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream

func _ready() -> void:
	collection_button.pressed.connect(_on_collection_button_pressed)
	abilities_button.pressed.connect(_on_abilities_button_pressed)
	ownedSuits_button.pressed.connect(_on_suitInventory_button_pressed)
	collection_button.mouse_entered.connect(_on_button_hovered)
	abilities_button.mouse_entered.connect(_on_button_hovered)
	ownedSuits_button.mouse_entered.connect(_on_button_hovered)

func _on_collection_button_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	alien_collection_panel.open()
	
func _on_abilities_button_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	active_abilities_panel.open()

func _on_suitInventory_button_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	ownedSuits_panel.open()

func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx,-6.0)
