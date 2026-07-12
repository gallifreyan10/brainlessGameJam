extends PanelContainer

@export var runManager: RunManager

@onready var suit_list: VBoxContainer = $VBoxContainer/SuitList
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	
	if runManager == null:
		push_error("Owned Suits Pane needs RunManager assigned.")
		return
		
	runManager.suitEquipped.connect(_on_suit_equipped)
	runManager.suitsCleared.connect(_on_suits_cleared)
	
	close_button.pressed.connect(_on_close_pressed)
	refresh()
	
func open() -> void:
	if visible:
		return

	if runManager != null:
		runManager.request_ui_timer_pause()

	visible = true
	
func close() -> void:
	if not visible:
		return
	
	visible = false
	
	if runManager != null:
		runManager.release_ui_timer_pause()
	
func refresh() -> void:
	for child in suit_list.get_children():
		child.queue_free()
		
	if runManager.ownedSuits.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No suits owned this run."
		suit_list.add_child(empty_label)
		return
		
	for suit in runManager.ownedSuits:
		var row := create_suit_row(suit)
		suit_list.add_child(row)
		
func create_suit_row(suit: SuitData) -> Control:
	var row := HBoxContainer.new()
	
	var name_label := Label.new()
	var equip_button := Button.new()
	var iconRect := TextureRect.new()
	
	name_label.text = suit.displayName
	name_label.custom_minimum_size = Vector2(160,0)
	
	iconRect.texture = suit.icon
	iconRect.custom_minimum_size = Vector2(48,48)
	iconRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if runManager.equippedSuit == suit:
		equip_button.text = "Equipped"
		equip_button.disabled = true
	else:
		equip_button.text = "Equip"
		equip_button.disabled = false
		
	equip_button.pressed.connect(func() -> void:
		runManager.equip_owned_suit(suit)
		refresh()
	)
	
	row.add_child(iconRect)
	row.add_child(name_label)
	row.add_child(equip_button)
	
	return row
	
func _on_suit_equipped(_suit: SuitData) -> void:
	refresh()
	
func _on_suits_cleared() -> void:
	refresh()
	
func _on_close_pressed() -> void:
	close()
