extends Control

@export var runManager: RunManager

@onready var flashOverlay: ColorRect = $FlashOverlay
@onready var successBanner: Label = $CenterContainer/SuccessBanner

var has_played_for_level: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	flashOverlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	successBanner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	flashOverlay.color.a = 0.0
	successBanner.modulate.a = 0.0
	
	if runManager == null:
		push_warning("QuotaCompleteFeedback needs RunManager assigned.")
		return
		
	runManager.levelCompleted.connect(_on_level_completed)
	runManager.levelStarted.connect(_on_level_started)
	
func _on_level_started(_levelIndex: int, data: LevelData) -> void:
	has_played_for_level = false
	visible = false
	flashOverlay.color.a = 0.0
	successBanner.modulate.a = 0.0
	
func _on_level_completed(_levelIndex: int, _grossEarnings: int) -> void:
	if has_played_for_level:
		return
		
	has_played_for_level = true
	play_feedback()
	
func play_feedback() -> void:
	visible = true
	
	if gameSettings.reduce_motion_enabled:
		play_reduced_feedback()
	else:
		play_full_feedback()
		
func play_full_feedback() -> void:
	flashOverlay.color = Color(1.0, 0.95, 0.45, 0.0)
	successBanner.modulate.a = 0.0
	successBanner.scale = Vector2(0.85, 0.85)
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		flashOverlay,
		"color:a",
		0.45,
		0.08
	)
	
	tween.tween_property(
		successBanner,
		"modulate:a",
		1.0,
		1.15
	)
	
	tween.tween_property(
		successBanner,
		"scale",
		Vector2.ONE,
		0.2
	)
	
	tween.chain().tween_interval(0.65)
	
	tween.chain().tween_property(
		flashOverlay,
		"color:a",
		0.0,
		0.25
	)
	
	tween.chain().tween_property(
		successBanner,
		"modulate:a",
		0.0,
		0.25
	)
	
	tween.finished.connect(_on_feedback_finished)

func play_reduced_feedback() -> void:
	flashOverlay.color = Color(0.2, 0.8, 1.0, 0.0)
	successBanner.modulate.a = 0.0
	successBanner.scale = Vector2.ONE
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		flashOverlay,
		"color:a",
		0.18,
		0.2
	)
	
	tween.tween_property(
		successBanner,
		"modulate:a",
		1.0,
		0.2
	)
	
	tween.chain().tween_interval(0.8)
	
	tween.chain().tween_property(
		flashOverlay,
		"color:a",
		0.0, 
		0.35
	)

	tween.chain().tween_property(
		successBanner,
		"modulate:a",
		0.0,
		0.35
	)
	
	tween.finished.connect(_on_feedback_finished)
	
func _on_feedback_finished() -> void:
	visible = false
