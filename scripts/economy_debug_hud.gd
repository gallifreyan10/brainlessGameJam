extends VBoxContainer

@onready var moneyLabel: Label = $MoneyLabel
@onready var quotaLabel: Label = $QuotaLabel
@onready var attemptsContainer: HBoxContainer = $AttemptsContainer
@onready var countdownLabel: Label = $CountdownLabel
@export var runManager: RunManager
@export var attemptFrames: Array[Texture2D] = []
@export var emptyAttemptIcon: Texture2D
@export var attempt_animation_fps: float = 8.0
@export var max_attempt_icons: int = 8

var attempt_icons: Array[TextureRect] = []
var attempt_anim_time: float = 0.0
var attempt_frame_index: int = 0

const DETAIL_COLOR := Color("#7CFFD6")

func _ready() -> void:
	RunEconomy.moneyChanged.connect(_on_money_changed)
	RunEconomy.quotaProgressChanged.connect(_on_quota_progress_changed)

	_on_money_changed(RunEconomy.runMoney)
	_on_quota_progress_changed(
		RunEconomy.earnedQuotaProgress,
		RunEconomy.levelQuota
	)
	if runManager != null:
		runManager.attemptsChanged.connect(_on_attempts_changed)
		_on_attempts_changed(runManager.attemptsRemaining)
		runManager.countdownChanged.connect(_on_countdown_changed)
		runManager.countdownStopped.connect(_on_countdown_stopped)
		
func _on_money_changed(wallet: int) -> void:
	moneyLabel.text = "Wallet %d" % wallet
	pulse_label(moneyLabel)

func _on_quota_progress_changed(
	earned: int,
	quota: int
) -> void:
	quotaLabel.text = "Quota: %d / %d" % [earned, quota]
	
	if earned >= quota:
		quotaLabel.text += " REACHED!"
		
	pulse_label(quotaLabel)

func pulse_label(label:Label) -> void:
	label.scale = Vector2(1.15,1.15)
	
	var tween := create_tween()
	tween.tween_property(
		label,
		"scale",
		Vector2.ONE,
		0.2
	)
func _on_attempts_changed(attemptsRemaining: int) -> void:
	for child in attemptsContainer.get_children():
		child.queue_free()
		
	for i in max_attempt_icons:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(16,16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if i < attemptsRemaining:
			if not attemptFrames.is_empty():
				icon.texture = attemptFrames[attempt_frame_index]
			icon.modulate = Color.WHITE
			attempt_icons.append(icon)
		else:
			if emptyAttemptIcon != null:
				icon.texture = emptyAttemptIcon
			elif not attemptFrames.is_empty():
				icon.texture = attemptFrames[0]
			icon.modulate = Color(1, 1, 1, 0.25)
			
		attemptsContainer.add_child(icon)
		
func _on_countdown_changed(timeRemaining: float) -> void:
	countdownLabel.text = "Time: %.1f" % timeRemaining
	
func _on_countdown_stopped() -> void:
	countdownLabel.text = "Time: --" 

func _process(delta: float) -> void:
	if attemptFrames.is_empty():
		return
		
	attempt_anim_time += delta
	
	if attempt_anim_time < 1.0 / attempt_animation_fps:
		return
	
	attempt_anim_time = 0.0
	attempt_frame_index = (attempt_frame_index + 1) % attemptFrames.size()
	
	for icon in attempt_icons:
		if icon != null:
			icon.texture = attemptFrames[attempt_frame_index]
