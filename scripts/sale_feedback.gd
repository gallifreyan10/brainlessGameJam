extends VBoxContainer

@onready var mineralIcon: TextureRect = $HeaderRow/MineralIcon
@onready var mineralNameLabel: Label = $HeaderRow/MineralNameLabel
@onready var breakdownLabel: Label = $BreakdownLabel
@onready var totalLabel: Label = $TotalLabel
@onready var alienIcon: TextureRect = $AlienIcon
@onready var hideTimer: Timer = $HideTimer
@export var mineral_sold_sfx: AudioStream
const DETAIL_COLOR := Color("#7CFFD6")
var original_position : Vector2
var feedback_tween: Tween = null

func _ready() -> void:
	RunEconomy.mineral_banked.connect(
		_on_mineral_banked
	)
	
	hideTimer.timeout.connect(_on_hide_timer_timeout)
	
	visible = false
	mineralNameLabel.add_theme_color_override("font_color", DETAIL_COLOR)
	original_position = position
	
func _on_mineral_banked(
	data: MineralData,
	finalValue: int,
	context: Dictionary
) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
		
	hideTimer.stop()
	var alienMultiplier: float = float(context.get("alien_multiplier", 1.0))
	var suitMultiplier: float = float(context.get("suit_multiplier", 1.0))
	
	SFXManager.play_sfx(mineral_sold_sfx)
	
	mineralNameLabel.text = data.displayName
	mineralIcon.texture = data.sprite
	
	var bonus_lines: Array[String] = []
	
	if not is_equal_approx(alienMultiplier, 1.0):
		bonus_lines.append("Alien Bonus x%.2f" % alienMultiplier)
		
	if not is_equal_approx(suitMultiplier, 1.0):
		bonus_lines.append("Suit Bonus x%.2f" % suitMultiplier)
	
	breakdownLabel.text = "\n".join(bonus_lines)
	breakdownLabel.visible = not bonus_lines.is_empty()
	
	totalLabel.text = "+%d money" % finalValue
	
	var equippedIcon := context.get("alien_icon", null) as Texture2D
	
	var alienChangedResult := (
		not is_equal_approx(
			alienMultiplier,
			1.0
		)
	)
	
	alienIcon.texture = equippedIcon
	alienIcon.visible = (
		equippedIcon != null
		and alienChangedResult
	)
	
	visible = true
	modulate.a = 1.0
	position = original_position
	
	if gameSettings.is_reduce_motion_enabled():
		scale = Vector2.ONE
		hideTimer.start()
		return
		
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
	
	if gameSettings.is_reduce_motion_enabled():
		visible = false
		modulate.a = 1.0
		scale = Vector2.ONE
		position = original_position
		return
		
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
