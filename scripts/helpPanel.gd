extends PanelContainer

@export var helpButton: Button
@export var runManager: RunManager

@onready var closeButton: Button = $VBoxContainer/CloseButton
@onready var contentBox: VBoxContainer = $VBoxContainer
@onready var titleLabel: Label = $VBoxContainer/TitleLabel
const TITLE_COLOR := Color("#FFD36A")

func _ready() -> void:
	visible = false
	_set_panel_rect(Vector2(460, 300), Vector2(150, 30))
	_wrap_content_in_margin(34)
	
	contentBox.add_theme_constant_override("separation", 6)
	titleLabel.add_theme_color_override("font_color", TITLE_COLOR)
	titleLabel.add_theme_font_size_override("font_size", 14)
	
	var body_label := contentBox.get_node_or_null("BodyLabel") as Label
	if body_label != null:
		body_label.custom_minimum_size = Vector2(360, 0)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var scroll := ScrollContainer.new()
		scroll.name = "HelpBodyScroll"
		scroll.custom_minimum_size = Vector2(360, 150)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var body_index := body_label.get_index()
		contentBox.remove_child(body_label)
		contentBox.add_child(scroll)
		contentBox.move_child(scroll, body_index)
		scroll.add_child(body_label)
	
	closeButton.custom_minimum_size = Vector2(160, 28)
	closeButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
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
