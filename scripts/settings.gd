extends Node

signal settings_changed

const SAVE_PATH := "user://settings.save"

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

var window_mode: int = 0
var resolution_index: int = 0
var vsync_enabled: bool = true
var screen_scale: float = 1.0

var large_text_enabled: bool = false
var reduce_motion_enabled: bool = false
var high_contrast_enabled: bool = false

const DEFAULT_WINDOW_MODE := 0
const DEFAULT_RESOLUTION_INDEX := 0
const DEFAULT_VSYNC_ENABLED := true
const DEFAULT_SCREEN_SCALE := 1.0

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1290, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

func _ready() -> void:
	load_settings()
	apply_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_settings()
	settings_changed.emit()

func set_large_text_enabled(enabled: bool) -> void:
	large_text_enabled = enabled
	save_settings()
	settings_changed.emit()
	
func set_reduce_motion_enabled(enabled: bool) -> void:
	reduce_motion_enabled = enabled
	save_settings()
	settings_changed.emit()
	
func set_high_contrast_enabled(enabled: bool) -> void:
	high_contrast_enabled = enabled
	save_settings()
	settings_changed.emit()

func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	apply_display_settings()
	save_settings()
	settings_changed.emit()
	
func apply_settings() -> void:
	
	apply_display_settings()
	var bus_index := AudioServer.get_bus_index("Master")
	
	if bus_index >= 0:
		if master_volume <= 0.0:
			AudioServer.set_bus_mute(bus_index,true)
		else:
			AudioServer.set_bus_mute(bus_index,false)
			AudioServer.set_bus_volume_db(bus_index,linear_to_db(master_volume))

func apply_display_settings() -> void:
	sanitize_display_settings()

	var resolution := RESOLUTIONS[resolution_index]

	match window_mode:
		0:
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_size(resolution)

		1:
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN
			)

		2:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				true
			)
			DisplayServer.window_set_size(resolution)

		_:
			window_mode = DEFAULT_WINDOW_MODE
			resolution_index = DEFAULT_RESOLUTION_INDEX
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)
			DisplayServer.window_set_size(
				RESOLUTIONS[DEFAULT_RESOLUTION_INDEX]
			)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)		
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
		
	master_volume = float(parsed.get("master_volume", 1.0))
	music_volume = float(parsed.get("music_volume", 1.0))
	sfx_volume = float(parsed.get("sfx_volume", 1.0))
	window_mode = int(parsed.get("window_mode", DEFAULT_WINDOW_MODE))
	resolution_index = int(parsed.get("resolution_index", DEFAULT_RESOLUTION_INDEX))
	screen_scale = float(parsed.get("screen_scale", DEFAULT_SCREEN_SCALE))
	large_text_enabled = bool(parsed.get("large_text_enabled", false))
	reduce_motion_enabled = bool(parsed.get("reduce_motion_enabled", false))
	high_contrast_enabled = bool(parsed.get("high_constrast_enabled", false))
	vsync_enabled = bool(parsed.get("vsync_enabled", DEFAULT_VSYNC_ENABLED))
	
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
	
	if screen_scale != 1.0 and screen_scale != 1.25 and screen_scale != 1.5 and screen_scale != 2.0:
		screen_scale = DEFAULT_SCREEN_SCALE
		
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
	
func set_screen_scale(value: int) -> void:
	screen_scale = value
	sanitize_display_settings()
	save_settings()
	settings_changed.emit()
