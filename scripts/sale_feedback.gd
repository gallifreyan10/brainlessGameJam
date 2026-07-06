extends VBoxContainer

@onready var mineralNameLabel: Label = $MineralNameLabel
@onready var breakdownLabel: Label = $BreakdownLabel
@onready var totalLabel: Label = $TotalLabel
@onready var alienIcon: TextureRect = $AlienIcon
@onready var hideTimer: Timer = $HideTimer

func _ready() -> void:
	RunEconomy.mineral_banked.connect(
		_on_mineral_banked
	)
	
	hideTimer.timeout.connect(_on_hide_timer_timeout)
	
	visible = false
	
func _on_mineral_banked(
	data: MineralData,
	finalValue: int,
	context: Dictionary
) -> void:
	var alienMultiplier: float = float(context.get("alien_multiplier", 1.0))
	var suitMultiplier: float = float(context.get("suit_multiplier", 1.0))
	
	mineralNameLabel.text = data.displayName
	
	breakdownLabel.text = ("Base %d x Alien %.2f x Suit %.2f" %[
		data.sale_value,
		alienMultiplier,
		suitMultiplier
		]
	)
	
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
	scale = Vector2(1.1,1.1)
	
	var tween := create_tween()
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
	
	hideTimer.start()
	
func _on_hide_timer_timeout() -> void:
	
	var tween := create_tween()
	
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
