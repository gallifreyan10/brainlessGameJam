extends Node
class_name RunManager

enum RunState {
	RUNNING,
	LEVEL_COMPLETE,
	SHOP,
	RUN_COMPLETE
}

signal stateChanged(newState: RunState)
signal levelStarted(levelIndex: int, data: LevelData)
signal levelCompleted(levelIndex: int, grossEarnings: int)
signal shopRequested

@export var levels: Array[LevelData] = []
@export var prizeContainer: Node

var currentState: RunState = RunState.RUNNING
var currentLevelIndex: int = 0
var completedLevelIndex: int = -1
var completedLevelEarnings: int = 0

func _ready() -> void:
	RunEconomy.quotaReached.connect(
		_on_quota_reached
	)

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
	
	prizeContainer.load_level(data)
	levelStarted.emit(currentLevelIndex, data)

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
