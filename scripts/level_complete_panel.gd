extends PanelContainer

@export var runManager: RunManager
const TITLE_COLOR := Color("#FFD36A")
const DETAIL_COLOR := Color("#7CFFD6")

@onready var titleLabel: Label = (
	$VBoxContainer/TitleLabel
)
@onready var earningsLabel: Label = (
	$VBoxContainer/EarningsLabel
)
@onready var continueButton: Button = (
	$VBoxContainer/ContinueButton
)
@onready var shopButton: Button = (
	$VBoxContainer/ShopButton
)
@onready var contentBox: VBoxContainer = $VBoxContainer
func _ready() -> void:
	visible = false
	_set_panel_rect(Vector2(330, 210), Vector2(185, 75))
	_wrap_content_in_margin(34)
	
	contentBox.add_theme_constant_override("separation", 8)
	titleLabel.add_theme_color_override("font_color", TITLE_COLOR)
	titleLabel.add_theme_font_size_override("font_size", 14)
	earningsLabel.add_theme_color_override("font_color", DETAIL_COLOR)
	earningsLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	earningsLabel.custom_minimum_size = Vector2(250, 0)
	
	continueButton.custom_minimum_size = Vector2(140, 28)
	shopButton.custom_minimum_size = Vector2(140, 28)
	continueButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shopButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if runManager == null:
		push_error("LevelCompletePanel has no RunManager.")
		return
		
	runManager.levelCompleted.connect(_on_level_completed)
	runManager.levelStarted.connect(_on_level_started)
	runManager.shopRequested.connect(_on_shop_requested)
	
	continueButton.pressed.connect(
		_on_continue_pressed
	)
	shopButton.pressed.connect(
		_on_shop_pressed
	)

func _on_level_completed(
	levelIndex: int,
	grossEarnings: int
) -> void:
	earningsLabel.text = (
		"Level %d earned: %d"
		% [
			levelIndex + 1,
			grossEarnings
		]
	)
	
	visible = true

func _on_level_started(
	_levelIndex: int,
	_data: LevelData
) -> void:
	visible = false
	
func _on_continue_pressed() -> void:
	runManager.continue_to_next_level()
	
func _on_shop_pressed() -> void:
	visible = false
	runManager.open_shop()
	
func _on_shop_requested() -> void:
	visible = false

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
