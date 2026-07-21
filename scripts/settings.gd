extends Node

signal settings_changed

const SAVE_PATH := "user://settings.save"

const DEFAULT_WINDOW_MODE := 0
const DEFAULT_RESOLUTION_INDEX := 0
const DEFAULT_VSYNC_ENABLED := true
const DEFAULT_SCREEN_SCALE := 1.0

const DEFAULT_FONT_SIZE := 12
const LARGE_FONT_SIZE_BONUS := 4
const NORMAL_FONT_COLOR := Color("#E9F7FF")
const HIGH_CONTRAST_FONT_COLOR := Color("#FFF26A")
const HIGH_CONTRAST_OUTLINE_COLOR := Color("#000000")

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

var window_mode: int = DEFAULT_WINDOW_MODE
var resolution_index: int = DEFAULT_RESOLUTION_INDEX
var vsync_enabled: bool = DEFAULT_VSYNC_ENABLED
var screen_scale: float = DEFAULT_SCREEN_SCALE

var large_text_enabled: bool = false
var reduce_motion_enabled: bool = false
var high_contrast_enabled: bool = false

func _ready() -> void:
	load_settings()
	apply_settings()
	
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
		
	call_deferred("apply_accessibility_settings")

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_window_mode(value: int) -> void:
	window_mode = value
	apply_display_settings()
	save_settings()
	settings_changed.emit()

func set_resolution_index(value: int) -> void:
	resolution_index = value
	apply_display_settings()
	save_settings()
	settings_changed.emit()

func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	apply_display_settings()
	save_settings()
	settings_changed.emit()

func set_screen_scale(value: float) -> void:
	screen_scale = value
	sanitize_display_settings()
	apply_screen_scale()
	save_settings()
	settings_changed.emit()

func set_large_text_enabled(enabled: bool) -> void:
	large_text_enabled = enabled
	apply_accessibility_settings()
	save_settings()
	settings_changed.emit()

func set_reduce_motion_enabled(enabled: bool) -> void:
	reduce_motion_enabled = enabled
	save_settings()
	settings_changed.emit()

func is_reduce_motion_enabled() -> bool:
	return reduce_motion_enabled

func set_high_contrast_enabled(enabled: bool) -> void:
	high_contrast_enabled = enabled
	apply_accessibility_settings()
	save_settings()
	settings_changed.emit()

func apply_settings() -> void:
	sanitize_display_settings()
	apply_audio_settings()
	apply_display_settings()
	apply_accessibility_settings()

func apply_audio_settings() -> void:
	apply_bus_volume(&"Master", master_volume)
	apply_bus_volume(&"Music", music_volume)
	apply_bus_volume(&"SFX", sfx_volume)

func apply_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	
	if bus_index < 0:
		push_warning("Audio bus is missing: %s" % bus_name)
		return
		
	var clamped_value := clampf(linear_value, 0.0, 1.0)
	
	if clamped_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		return
		
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_value))

func apply_display_settings() -> void:
	sanitize_display_settings()
	
	if is_web_build():
		return
	
	var window := get_window()
	var resolution := RESOLUTIONS[resolution_index]
	
	match window_mode:
		0:
			window.borderless = false
			window.mode = Window.MODE_WINDOWED
			window.size = resolution
			
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_size(resolution)
			center_window_on_screen(resolution)
			
		1:
			window.borderless = false
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			)
			
		2:
			window.mode = Window.MODE_WINDOWED
			window.borderless = true
			window.size = resolution
			
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				true
			)
			DisplayServer.window_set_size(resolution)
			center_window_on_screen(resolution)
			
		_:
			window_mode = DEFAULT_WINDOW_MODE
			resolution_index = DEFAULT_RESOLUTION_INDEX
			window.borderless = false
			window.mode = Window.MODE_WINDOWED
			window.size = RESOLUTIONS[DEFAULT_RESOLUTION_INDEX]
			
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_size(
				RESOLUTIONS[DEFAULT_RESOLUTION_INDEX]
			)
			center_window_on_screen(RESOLUTIONS[DEFAULT_RESOLUTION_INDEX])
			
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED,
		0
	)
	
	apply_screen_scale()

func center_window_on_screen(resolution: Vector2i) -> void:
	if is_web_build():
		return
		
	if window_mode == 1:
		return
		
	var window := get_window()
	var screen_index := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var centered_position := Vector2i(
		(screen_size.x - resolution.x) / 2,
		(screen_size.y - resolution.y) / 2
	)
	
	DisplayServer.window_set_position(centered_position)
	window.position = centered_position

func apply_screen_scale() -> void:
	if is_web_build():
		return
		
	var window := get_window()
	
	if object_has_property(window, &"content_scale_factor"):
		window.set("content_scale_factor", screen_scale)

func is_web_build() -> bool:
	return OS.get_name() == "Web"

func object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
			
	return false

func save_settings() -> void:
	var save_data := {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"window_mode": window_mode,
		"resolution_index": resolution_index,
		"screen_scale": screen_scale,
		"large_text_enabled": large_text_enabled,
		"reduce_motion_enabled": reduce_motion_enabled,
		"high_contrast_enabled": high_contrast_enabled,
		"vsync_enabled": vsync_enabled
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("Could not save settings.")
		return
		
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		push_error("Could not load settings.")
		return
		
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Settings save data is invalid.")
		return
		
	master_volume = clampf(float(parsed.get("master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(parsed.get("music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", 1.0)), 0.0, 1.0)
	window_mode = int(parsed.get("window_mode", DEFAULT_WINDOW_MODE))
	resolution_index = int(parsed.get("resolution_index", DEFAULT_RESOLUTION_INDEX))
	screen_scale = float(parsed.get("screen_scale", DEFAULT_SCREEN_SCALE))
	large_text_enabled = bool(parsed.get("large_text_enabled", false))
	reduce_motion_enabled = bool(parsed.get("reduce_motion_enabled", false))
	high_contrast_enabled = bool(parsed.get("high_contrast_enabled", false))
	vsync_enabled = bool(parsed.get("vsync_enabled", DEFAULT_VSYNC_ENABLED))
	
	sanitize_display_settings()

func sanitize_display_settings() -> void:
	window_mode = clampi(window_mode, 0, 2)
	
	if RESOLUTIONS.is_empty():
		resolution_index = 0
	else:
		resolution_index = clampi(
			resolution_index,
			0,
			RESOLUTIONS.size() - 1
		)
		
	if (
		screen_scale != 1.0
		and screen_scale != 1.25
		and screen_scale != 1.5
		and screen_scale != 2.0
	):
		screen_scale = DEFAULT_SCREEN_SCALE

func _on_node_added(node: Node) -> void:
	if large_text_enabled or high_contrast_enabled:
		call_deferred("apply_accessibility_to_node", node)

func apply_accessibility_settings() -> void:
	if not is_inside_tree():
		return
		
	apply_accessibility_to_node(get_tree().root)

func apply_accessibility_to_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
		
	if node is Control:
		apply_accessibility_to_control(node as Control)
		
	for child in node.get_children():
		apply_accessibility_to_node(child)

func apply_accessibility_to_control(control: Control) -> void:
	var should_style_font := (
		control is Label
		or control is Button
		or control is CheckBox
		or control is OptionButton
	)
	
	if not should_style_font:
		return
		
	if not control.has_meta("settings_original_font_size"):
		control.set_meta(
			"settings_original_font_size",
			control.get_theme_font_size("font_size")
		)
		
	var original_size := int(
		control.get_meta("settings_original_font_size", DEFAULT_FONT_SIZE)
	)
	
	if large_text_enabled:
		control.add_theme_font_size_override(
			"font_size",
			original_size + LARGE_FONT_SIZE_BONUS
		)
	else:
		control.add_theme_font_size_override("font_size", original_size)
		
	if not control.has_meta("settings_original_font_color"):
		control.set_meta(
			"settings_original_font_color",
			control.get_theme_color("font_color")
		)
		
	var original_color: Color = control.get_meta(
		"settings_original_font_color",
		NORMAL_FONT_COLOR
	)
	
	if high_contrast_enabled:
		control.add_theme_color_override(
			"font_color",
			HIGH_CONTRAST_FONT_COLOR
		)
		control.add_theme_color_override(
			"font_hover_color",
			HIGH_CONTRAST_FONT_COLOR
		)
		control.add_theme_color_override(
			"font_pressed_color",
			HIGH_CONTRAST_FONT_COLOR
		)
		control.add_theme_color_override(
			"font_focus_color",
			HIGH_CONTRAST_FONT_COLOR
		)
		control.add_theme_color_override(
			"font_outline_color",
			HIGH_CONTRAST_OUTLINE_COLOR
		)
		control.add_theme_constant_override("outline_size", 2)
	else:
		control.add_theme_color_override("font_color", original_color)
		control.remove_theme_color_override("font_hover_color")
		control.remove_theme_color_override("font_pressed_color")
		control.remove_theme_color_override("font_focus_color")
		control.remove_theme_color_override("font_outline_color")
		control.remove_theme_constant_override("outline_size")
