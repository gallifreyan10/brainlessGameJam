extends PanelContainer

@export var settingsButton: Button
@export var runManager: RunManager

@onready var closeButton: Button = $VBoxContainer/CloseButton
@onready var masterVolumeSlider: HSlider = $VBoxContainer/ScrollContainer/SettingsContent/MasterVolumeSlider
@onready var musicVolumeSlider: HSlider = $VBoxContainer/ScrollContainer/SettingsContent/MusicVolumeSlider
@onready var sfxVolumeSlider: HSlider = $VBoxContainer/ScrollContainer/SettingsContent/SFXVolumeSlider

@onready var windowModeOption: OptionButton = $VBoxContainer/ScrollContainer/SettingsContent/WindowModeOption
@onready var resolutionOption: OptionButton = $VBoxContainer/ScrollContainer/SettingsContent/ResolutionOption
@onready var vSyncCheck: CheckBox = $VBoxContainer/ScrollContainer/SettingsContent/VSyncCheck
@onready var scaleOption: OptionButton = $VBoxContainer/ScrollContainer/SettingsContent/ScaleOption
@onready var largeTextCheck: CheckBox = $VBoxContainer/ScrollContainer/SettingsContent/LargeTextCheck
@onready var reduceMotionCheck: CheckBox = $VBoxContainer/ScrollContainer/SettingsContent/ReduceMotionCheck
@onready var highContrastCheck: CheckBox = $VBoxContainer/ScrollContainer/SettingsContent/HighContrastCheck
@onready var titleLabel: Label = $VBoxContainer/TitleLabel
const TITLE_COLOR := Color("#FFD36A")

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(360, 320)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -180.0
	offset_top = -160.0
	offset_right = 180.0
	offset_bottom = 160.0
	
	var vbox := $VBoxContainer
	vbox.add_theme_constant_override("separation", 6)
	titleLabel.add_theme_color_override("font_color", TITLE_COLOR)
	titleLabel.add_theme_font_size_override("font_size", 14)
	
	var scroll_container := $VBoxContainer/ScrollContainer
	scroll_container.custom_minimum_size = Vector2(300, 220)
	
	var settings_content := $VBoxContainer/ScrollContainer/SettingsContent
	settings_content.add_theme_constant_override("separation", 4)
	
	closeButton.custom_minimum_size = Vector2(140, 28)
	closeButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if settingsButton != null:
		settingsButton.pressed.connect(_on_settings_pressed)
	else:
		push_warning("SettingsPanel needs SettingsButton assigned.")
		
	closeButton.pressed.connect(_on_close_pressed)
	
	_setup_options()
	masterVolumeSlider.value_changed.connect(_on_master_volume_changed)
	musicVolumeSlider.value_changed.connect(_on_music_volume_changed)
	sfxVolumeSlider.value_changed.connect(_on_sfx_volume_changed)
	
	windowModeOption.item_selected.connect(_on_window_mode_selected)
	resolutionOption.item_selected.connect(_on_resolution_selected)
	vSyncCheck.toggled.connect(_on_vsync_toggled)
	scaleOption.item_selected.connect(_on_scale_selected)
	
	largeTextCheck.toggled.connect(_on_large_text_toggled)
	reduceMotionCheck.toggled.connect(_on_reduce_motion_toggled)
	highContrastCheck.toggled.connect(_on_high_contrast_toggled)
	
	_load_current_settings_into_ui()

func _setup_options() -> void:
	windowModeOption.clear()
	windowModeOption.add_item("Windowed", 0)
	windowModeOption.add_item("Fullscreen", 1)
	windowModeOption.add_item("Borderless", 2)
	
	resolutionOption.clear()
	
	for i in gameSettings.RESOLUTIONS.size():
		var resolution : Vector2i = gameSettings.RESOLUTIONS[i]
		resolutionOption.add_item(
			"%d x %d" %[resolution.x, resolution.y],
			i
		)
		
		scaleOption.clear()
		scaleOption.add_item("100%",0)
		scaleOption.add_item("125%",1)
		scaleOption.add_item("150%",2)
		scaleOption.add_item("200%",3)
		
func _load_current_settings_into_ui() -> void:
	masterVolumeSlider.value = gameSettings.master_volume
	musicVolumeSlider.value = gameSettings.music_volume
	sfxVolumeSlider.value = gameSettings.sfx_volume
	
	windowModeOption.select(gameSettings.window_mode)
	resolutionOption.select(gameSettings.resolution_index)
	vSyncCheck.button_pressed = gameSettings.vsync_enabled
	
	match gameSettings.screen_scale:
		1.0:
			scaleOption.select(0)
		1.25:
			scaleOption.select(1)
		1.5:
			scaleOption.select(2)
		2.0:
			scaleOption.select(3)
		_:
			scaleOption.select(0)
			
	largeTextCheck.button_pressed = gameSettings.large_text_enabled
	reduceMotionCheck.button_pressed = gameSettings.reduce_motion_enabled
	highContrastCheck.button_pressed = gameSettings.high_contrast_enabled

func _on_settings_pressed() -> void:
	open()
	
func _on_close_pressed() -> void:
	close()

func _on_master_volume_changed(value: float) -> void:
	gameSettings.set_master_volume(value)
	
func _on_music_volume_changed(value: float) -> void:
	gameSettings.set_master_volume(value)
	
func _on_sfx_volume_changed(value: float) -> void:
	gameSettings.set_master_volume(value)

func _on_window_mode_selected(index: int) -> void:
	gameSettings.set_window_mode(index)
	
func _on_resolution_selected(index: int) -> void:
	gameSettings.set_resolution_index(index)
	
func _on_vsync_toggled(enabled: bool) -> void:
	gameSettings.set_vsync_enabled(enabled)
	
func _on_scale_selected(index: int) -> void:
	match index:
		0:
			gameSettings.set_screen_scale(1.0)	
		1:
			gameSettings.set_screen_scale(1.25)	
		2:
			gameSettings.set_screen_scale(1.5)	
		3:
			gameSettings.set_screen_scale(2.0)	
			
func _on_large_text_toggled(enabled: bool) -> void:
	gameSettings.set_large_text_enabled(enabled)
	
func _on_reduce_motion_toggled(enabled: bool) -> void:
	gameSettings.set_reduce_motion_enabled(enabled)
		
func _on_high_contrast_toggled(enabled: bool) -> void:
	gameSettings.set_high_contrast_enabled(enabled)

func open() -> void:
	if visible:
		return

	if runManager != null:
		runManager.request_ui_timer_pause()
		
	_load_current_settings_into_ui()
	visible = true

func close() -> void:
	if not visible:
		return
	
	visible = false
	
	if runManager != null:
		runManager.release_ui_timer_pause()
