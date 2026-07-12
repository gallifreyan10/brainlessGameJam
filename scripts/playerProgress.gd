extends Node

signal progress_changed
signal progress_loaded

const SAVE_PATH := "user://player_progress.save"

var best_level_reached: int = 1
var total_runs_started: int = 0
var total_runs_failed: int = 0
var total_runs_completed: int = 0

func _ready() -> void:
	load_progress()

func record_level_reached(level_number: int) -> void:
	if level_number <= best_level_reached:
		return
		
	best_level_reached = level_number
	save_progress()
	progress_changed.emit()

func record_run_started() -> void:
	total_runs_started += 1
	save_progress()
	progress_changed.emit()
	
func record_run_failed() -> void:
	total_runs_failed += 1
	save_progress()
	progress_changed.emit()
	
func record_run_completed() -> void:
	total_runs_completed += 1
	save_progress()
	progress_changed.emit()
	
func save_progress() -> void:
	var save_data := {
		"best_level_reached": best_level_reached,
		"total_runs_started": total_runs_started,
		"total_runs_failed": total_runs_failed,
		"total_runs_completed": total_runs_completed
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("Could not save player progression.")
		return
		
	file.store_string(JSON.stringify(save_data))
	file.close()
	
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		progress_loaded.emit()
		return
		
	var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
	
	if file == null:
		push_error("Could not load player progression.")
		return
		
	var text:= file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Player progression save data is invalid.")
		return
		
	best_level_reached = int(parsed.get("best_level_reached", 1))
	total_runs_started = int(parsed.get("total_runs_started", 0))
	total_runs_failed = int(parsed.get("total_runs_failed", 0))
	total_runs_completed = int(parsed.get("total_runs_completed", 0))
	
	progress_loaded.emit()
	
func clear_progress_for_debug() -> void:
	best_level_reached = 1
	total_runs_started = 0
	total_runs_failed = 0
	total_runs_completed = 0
	save_progress()
	progress_changed.emit()
