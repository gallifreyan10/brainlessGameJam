extends VBoxContainer

@onready var alienIcon: TextureRect = $HeaderRow/AlienIcon
@onready var alienNameLabel: Label = $HeaderRow/AlienNameLabel
@onready var breakdownLabel: Label = $BreakdownLabel
@onready var totalLabel: Label = $TotalLabel
@onready var hideTimer: Timer = $HideTimer
@export var alien_collected_sfx: AudioStream
const DETAIL_COLOR := Color("#7CFFD6")
var original_position : Vector2
var feedback_tween: Tween = null

func _ready() -> void:
	AlienCollection.alien_collected.connect(
		_on_alien_collected
	)
	
	hideTimer.timeout.connect(_on_hide_timer_timeout)
	
	visible = false
	alienNameLabel.add_theme_color_override("font_color", DETAIL_COLOR)
	original_position = position
	
func _on_alien_collected(alien_data: AlienData) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
		
	hideTimer.stop()
	
	SFXManager.play_sfx(alien_collected_sfx)
	
	alienNameLabel.text = alien_data.displayName
	alienIcon.texture = alien_data.icon
	
	breakdownLabel.text = "Alien Collected!"
	breakdownLabel.visible = true
	totalLabel.text = "Stacks: %d" % AlienCollection.get_alien_stack_count(alien_data.alien_id)
	
	visible = true
	modulate.a = 1.0
	scale = Vector2(1.1,1.1)
	
	position = original_position + Vector2(0,8)
	var target_position := original_position
	
	feedback_tween = create_tween()
	var tween := feedback_tween
	tween.set_parallel(true)
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.2
	)
	tween.tween_property(
		self,
		"modulate:a",
		1.0, 
		0.2
	)
	
	tween.tween_property(
		self,
		"position",
		target_position, 
		0.25
	)
	hideTimer.start()
	
func _on_hide_timer_timeout() -> void:
	
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
		
	feedback_tween = create_tween()
	var tween := feedback_tween
	
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.25
	)
	
	tween.tween_callback(
		func() -> void: 
			visible=false
)
