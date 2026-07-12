extends Node
class_name RunManager

enum RunState {
	RUNNING,
	LEVEL_COMPLETE,
	SHOP,
	RUN_COMPLETE,
	LEVEL_FAILED
}

signal stateChanged(newState: RunState)
signal levelStarted(levelIndex: int, data: LevelData)
signal levelCompleted(levelIndex: int, grossEarnings: int)
signal shopRequested
signal suitEquipped(suit: SuitData)
signal attemptsChanged(attemptsRemaining:int)
signal attemptsDepleted
signal countdownChanged(timeRemaining: float)
signal countdownStarted(timeRemaining: float)
signal countdownStopped
signal countdownExpired
signal runFailed(levelIndex: int, earned: int, quota: int)
signal newRunStarted

@export var levels: Array[LevelData] = []
@export var prizeContainer: Node
@export var clawController: Node
@export var attemptCountdownDuration: float = 15.0
@export var layoutManager: LayoutManager

var attemptsCountdownRemaining: float = 0.0
var countdownActive: bool = false
var currentState: RunState = RunState.RUNNING
var currentLevelIndex: int = 0
var completedLevelIndex: int = -1
var completedLevelEarnings: int = 0
var equippedSuit: SuitData = null
var ownedSuits: Array[SuitData] = []
var attemptsRemaining: int = 0
var currentAttemptCountdownDuration: float = 15.0
var ui_timer_pause_count: int = 0
var countdown_was_active_before_ui_pause:bool = false

signal suitsCleared

func _ready() -> void:
	RunEconomy.quotaReached.connect(
		_on_quota_reached
	)
	
	if clawController != null and clawController.has_signal("attempt_finished"):
		clawController.attempt_finished.connect(_on_attempt_finished)
	else:
		push_warning("RunManager needs ClawController assigned.")

	call_deferred("start_level", 0)
	
func start_level(levelIndex: int) -> void:
	if levelIndex < 0 or levelIndex >= levels.size():
		currentState = RunState.RUN_COMPLETE
		stateChanged.emit(currentState)
		PlayerProgress.record_run_completed()
		return
		
	if prizeContainer == null:
		push_error("RunManager has no prize container.")
		return
		
	currentLevelIndex = levelIndex
	PlayerProgress.record_level_reached(currentLevelIndex+1)
	currentState = RunState.RUNNING
	stateChanged.emit(currentState)
	
	var data := levels[currentLevelIndex]
	
	if layoutManager != null:
		var layout : Node = null
		if levelIndex == 0:
			layout = layoutManager.load_layout(0)
		else:
			layout = layoutManager.load_random_layout()
			
		apply_layout_references(layout)
	
	attemptsRemaining = data.plannedAttemptLimit + AlienCollection.get_extra_attempts()
	attemptsChanged.emit(attemptsRemaining)
	
	var resolvedDifficulty := (
		data.resolve_difficulty(
			currentLevelIndex
		)
	)
	
	print_debug(
		"Level %d difficulty: %s" %[
			currentLevelIndex + 1,
			resolvedDifficulty
		]
	)
	
	currentAttemptCountdownDuration = attemptCountdownDuration * float(resolvedDifficulty.get("timer_multiplier", 1.0))
	
	prizeContainer.load_level(
		data,
		resolvedDifficulty
	)
	levelStarted.emit(currentLevelIndex, data)
	start_attempt_countdown()
	
func _on_quota_reached(
	earned: int,
	_quota: int
) -> void:
	complete_level(earned)
	
func complete_level(grossEarnings: int) -> void:
	if currentState != RunState.RUNNING:
		return
	
	completedLevelIndex = currentLevelIndex
	completedLevelEarnings = grossEarnings
	
	currentState = RunState.LEVEL_COMPLETE
	stateChanged.emit(currentState)
	
	levelCompleted.emit(
		completedLevelIndex,
		completedLevelEarnings
	)
	
func continue_to_next_level() -> void:
	if currentState != RunState.LEVEL_COMPLETE:
		return
		
	call_deferred(
		"start_level",
		currentLevelIndex + 1
	)

func open_shop() -> void:
	if currentState != RunState.LEVEL_COMPLETE:
		return
	
	currentState = RunState.SHOP
	stateChanged.emit(currentState)
	shopRequested.emit()

func buy_and_equip_suit(suit: SuitData, price_override: int = -1) -> bool:
	if currentState != RunState.SHOP:
		return false
		
	if suit == null:
		return false
		
	if ownedSuits.has(suit):
		equippedSuit = suit
		suitEquipped.emit(equippedSuit)
		return true
		
	var finalPrice := suit.price
	
	if price_override >= 0:
		finalPrice = price_override
		
	if not RunEconomy.spend_money(finalPrice):
		return false
	
	ownedSuits.append(suit)	
	equippedSuit = suit
	suitEquipped.emit(equippedSuit)
	return true
	
func leave_shop_and_continue() -> void:
	if currentState != RunState.SHOP:
		return
		
	call_deferred("start_level", currentLevelIndex + 1)

func consume_attempt() -> void:
	if currentState != RunState.RUNNING:
		return
	if attemptsRemaining <= 0:
		return
		
	attemptsRemaining -= 1
	attemptsChanged.emit(attemptsRemaining)
	
	if attemptsRemaining <= 0:
		attemptsDepleted.emit()
		
		if RunEconomy.earnedQuotaProgress < RunEconomy.levelQuota:
			fail_level()
		
func _on_attempt_finished() -> void:
	consume_attempt()
	
	if currentState == RunState.RUNNING and attemptsRemaining > 0:
		start_attempt_countdown()

func _process(delta: float) -> void:
	if not countdownActive:
		return
	
	if currentState != RunState.RUNNING:
		return
		
	attemptsCountdownRemaining = maxf(
		attemptsCountdownRemaining - delta,
		0.0
	)
	
	countdownChanged.emit(attemptsCountdownRemaining)
	
	if attemptsCountdownRemaining <= 0.0:
		countdownActive = false
		countdownChanged.emit(0.0)
		countdownExpired.emit()
		countdownStopped.emit()
		
func start_attempt_countdown() -> void:
	if currentState != RunState.RUNNING:
		return
		
	if attemptsRemaining <= 0:
		return
		
	attemptsCountdownRemaining = currentAttemptCountdownDuration
	countdownActive = true
	countdownStarted.emit(attemptsCountdownRemaining)
	countdownChanged.emit(attemptsCountdownRemaining)
	
func stop_attempt_countdown() -> void:
	if not countdownActive:
		return
	
	countdownActive = false
	countdownStopped.emit()
	
func fail_level() -> void:
	if currentState != RunState.RUNNING:
		return
	
	currentState = RunState.LEVEL_FAILED
	stateChanged.emit(currentState)
	
	PlayerProgress.record_run_failed()
	runFailed.emit(currentLevelIndex,RunEconomy.earnedQuotaProgress,RunEconomy.levelQuota)
	
func start_new_run() -> void:
	PlayerProgress.record_run_started()
	clear_run_suits()
	RunEconomy.reset_run_money()
	currentLevelIndex = 0
	newRunStarted.emit()
	call_deferred("start_level", 0)

func clear_run_suits() -> void:
	ownedSuits.clear()
	equippedSuit = null
	suitsCleared.emit()
	suitEquipped.emit(null)

func equip_owned_suit(suit: SuitData) -> bool:
	if suit == null:
		return false
	
	if not ownedSuits.has(suit):
		return false
		
	equippedSuit = suit
	suitEquipped.emit(equippedSuit)
	return true

func apply_layout_references(layout: Node) -> void:
	if layout == null:
		return
		
	var prize_chute := layout.get_node_or_null("PrizeChute") as Area2D
	var chute_release_point := layout.get_node_or_null("ChuteReleasePoint") as Marker2D
	var spawn_top_left := layout.get_node_or_null("PrizeSpawnTopLeft") as Marker2D
	var spawn_bottom_right := layout.get_node_or_null("PrizeSpawnBottomRight") as Marker2D
	var resolution_timer: Timer = null
	var cable := layout.get_node_or_null("cable") as Line2D
	
	if chute_release_point != null:
		resolution_timer = chute_release_point.get_node_or_null("ResolutionTimer") as Timer
	
	if prizeContainer != null:
		prizeContainer.spawn_top_left = spawn_top_left
		prizeContainer.spawn_bottom_right = spawn_bottom_right
		
	if clawController != null:
		clawController.chuteArea = prize_chute
		clawController.chuteReleasePoint = chute_release_point
		clawController.resolutionTimer = resolution_timer
		clawController.cable = cable
		
		if prize_chute != null:
			var chute_callable := Callable(clawController, "_on_prize_chute_body_entered")
			
			if not prize_chute.body_entered.is_connected(chute_callable):
				prize_chute.body_entered.connect(chute_callable)
				
		if resolution_timer != null:
			var timer_callable := Callable(clawController, "_on_resolution_timer_timeout")
			
			if not resolution_timer.timeout.is_connected(timer_callable):
				resolution_timer.timeout.connect(timer_callable)
				
func request_ui_timer_pause() -> void:
	ui_timer_pause_count += 1
	
	if ui_timer_pause_count == 1:
		countdown_was_active_before_ui_pause = countdownActive
		stop_attempt_countdown()
		
func release_ui_timer_pause() -> void:
	ui_timer_pause_count = maxi(0, ui_timer_pause_count - 1)
	
	if ui_timer_pause_count > 0:
		return
		
	if (
		countdown_was_active_before_ui_pause
		and currentState == RunState.RUNNING
		and attemptsRemaining > 0
	):
		resume_attempt_countdown_from_current_time()
		
	countdown_was_active_before_ui_pause = false
	
func resume_attempt_countdown_from_current_time() -> void:
	if currentState != RunState.RUNNING:
		return
	
	if attemptsRemaining <= 0:
		return
		
	if attemptsCountdownRemaining <= 0.0:
		return
		
	countdownActive = true
	countdownStarted.emit(attemptsCountdownRemaining)
	countdownChanged.emit(attemptsCountdownRemaining)
