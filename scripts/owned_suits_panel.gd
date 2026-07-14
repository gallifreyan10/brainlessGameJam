extends PanelContainer

@export var runManager: RunManager

@onready var suit_list: VBoxContainer = $VBoxContainer/SuitList
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var contentBox: VBoxContainer = $VBoxContainer
const TITLE_COLOR := Color("#FFD36A")
const DETAIL_COLOR := Color("#7CFFD6")

func _ready() -> void:
	visible = false
	_set_panel_rect(Vector2(400, 260), Vector2(160, 50))
	_wrap_content_in_margin(34)
	
	contentBox.add_theme_constant_override("separation", 6)
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	title_label.add_theme_font_size_override("font_size", 14)
	
	var scroll := ScrollContainer.new()
	scroll.name = "SuitListScroll"
	scroll.custom_minimum_size = Vector2(300, 130)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var suit_list_index := suit_list.get_index()
	contentBox.remove_child(suit_list)
	contentBox.add_child(scroll)
	contentBox.move_child(scroll, suit_list_index)
	scroll.add_child(suit_list)
	
	close_button.custom_minimum_size = Vector2(160, 28)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	suit_list.add_theme_constant_override("separation", 6)
	
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
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(340, 0)
		suit_list.add_child(empty_label)
		return
		
	for suit in runManager.ownedSuits:
		var row := create_suit_row(suit)
		suit_list.add_child(row)
		
func create_suit_row(suit: SuitData) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(340, 40)
	row.add_theme_constant_override("separation", 8)
	
	var name_label := Label.new()
	var equip_button := Button.new()
	var iconRect := TextureRect.new()
	
	name_label.text = suit.displayName
	name_label.custom_minimum_size = Vector2(170,0)
	name_label.add_theme_color_override("font_color", DETAIL_COLOR)
	
	iconRect.texture = suit.icon
	iconRect.custom_minimum_size = Vector2(34,34)
	iconRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	equip_button.custom_minimum_size = Vector2(100, 28)
	
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

func _set_panel_rect(panel_size: Vector2, top_left: Vector2) -> void:
	custom_minimum_size = panel_size
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = top_left.x
	offset_top = top_left.y
	offset_right = top_left.x + panel_size.x
	offset_bottom = top_left.y + panel_size.y

func _wrap_content_in_margin(padding: int) -> void:
	if contentBox.get_parent() is MarginContainer:
		return
	
	var margin_container := MarginContainer.new()
	margin_container.name = "RuntimeMargin"
	margin_container.add_theme_constant_override("margin_left", padding)
	margin_container.add_theme_constant_override("margin_right", padding)
	margin_container.add_theme_constant_override("margin_top", padding)
	margin_container.add_theme_constant_override("margin_bottom", padding)
	
	remove_child(contentBox)
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_child(contentBox)
