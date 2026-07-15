extends PanelContainer


@export var runManager: RunManager

@onready var messageLabel: Label = $VBoxContainer/MessageLabel
@onready var newRunButton: Button = $VBoxContainer/NewRunButton
@onready var mainMenuButton: Button = $VBoxContainer/MainMenuButton
@onready var contentBox: VBoxContainer = $VBoxContainer
@onready var titleLabel: Label = $VBoxContainer/TitleLabel
@export_file("*.tscn") var title_scene_path: String = "res://scenes/main_menu.tscn"

@export var run_failed_sfx: AudioStream
@export var button_click_sfx: AudioStream
@export var button_hover_sfx: AudioStream

const TITLE_COLOR := Color("#FFD36A")
const DETAIL_COLOR := Color("#7CFFD6")

func _ready() -> void:
	visible = false
	_set_panel_rect(Vector2(360, 220), Vector2(170, 70))
	_wrap_content_in_margin(34)
	
	contentBox.add_theme_constant_override("separation", 8)
	titleLabel.add_theme_color_override("font_color", TITLE_COLOR)
	titleLabel.add_theme_font_size_override("font_size", 14)
	
	messageLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messageLabel.add_theme_color_override("font_color", DETAIL_COLOR)
	messageLabel.custom_minimum_size = Vector2(280, 0)
	newRunButton.custom_minimum_size = Vector2(170, 28)
	mainMenuButton.custom_minimum_size = Vector2(170, 28)
	newRunButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mainMenuButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	newRunButton.mouse_entered.connect(_on_button_hovered)
	mainMenuButton.mouse_entered.connect(_on_button_hovered)
	
	if runManager == null:
		push_error("RunFailedPanel needs RunManager assigned.")
		return
	
	runManager.runFailed.connect(_on_run_failed)
	runManager.levelStarted.connect(_on_level_started)
	
	newRunButton.pressed.connect(_on_newRun_pressed)
	mainMenuButton.pressed.connect(_on_mainmenu_pressed)

func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx, -6.0)
	
func _on_run_failed(_levelIndex: int, earned: int, quota: int) -> void:
	SFXManager.play_sfx(run_failed_sfx)
	visible = true
	messageLabel.text = "Earned %d / %d" % [earned, quota]

func _on_level_started(_levelIndex: int, _data: LevelData) -> void:
	visible = false
	
func _on_newRun_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	visible = false
	runManager.start_new_run()

func _on_mainmenu_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)

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
