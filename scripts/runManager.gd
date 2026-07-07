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

@export var levels: Array[LevelData] = []
@export var prizeContainer: Node
@export var clawController: Node
@export var attemptCountdownDuration: float = 5.0

var attemptsCountdownRemaining: float = 0.0
var countdownActive: bool = false
var currentState: RunState = RunState.RUNNING
var currentLevelIndex: int = 0
var completedLevelIndex: int = -1
var completedLevelEarnings: int = 0
var equippedSuit: SuitData = null
var ownedSuits: Array[SuitData] = []
var attemptsRemaining: int = 0

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
		return
		
	if prizeContainer == null:
		push_error("RunManager has no prize container.")
		return
		
	currentLevelIndex = levelIndex
	currentState = RunState.RUNNING
	stateChanged.emit(currentState)
	
	var data := levels[currentLevelIndex]
	
	attemptsRemaining = data.plannedAttemptLimit
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

func buy_and_equip_suit(suit: SuitData) -> bool:
	if currentState != RunState.SHOP:
		return false
		
	if suit == null:
		return false
		
	if not RunEconomy.spend_money(suit.price):
		return false
	
	if not ownedSuits.has(suit):
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
		
	attemptsCountdownRemaining = attemptCountdownDuration
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
	runFailed.emit(currentLevelIndex,RunEconomy.earnedQuotaProgress,RunEconomy.levelQuota)
	
func start_new_run() -> void:
	clear_run_suits()
	currentLevelIndex = 0
	call_deferred("start_level", 0)

func clear_run_suits() -> void:
	ownedSuits.clear()
	equippedSuit = null
	suitsCleared.emit()
	suitEquipped.emit(null)
	
