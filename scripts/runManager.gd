extends Node
class_name RunManager

@export var default_spawn_separation: float = 18.0
@export_file("*tscn") var title_scene_path: String = "res://scenes/main_menu.tscn"


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
signal runCompleted(grossEarnings: int)

@export var levels: Array[LevelData] = []
@export var prizeContainer: Node
@export var clawController: Node
@export var attemptCountdownDuration: float = 15.0
@export var layoutManager: LayoutManager
@export var decorativePrizePiles: Control
@export var leftChutePrizePileOffsetX: float = 80.0
@export var levelNameLabel: Label

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
var defaultDecorativePrizePilePosition: Vector2 = Vector2.ZERO
var hasDefaultDecorativePrizePilePosition: bool = false

signal suitsCleared

func _ready() -> void:
	if decorativePrizePiles != null:
		defaultDecorativePrizePilePosition = decorativePrizePiles.position
		hasDefaultDecorativePrizePilePosition = true
	
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
	update_level_name_label(currentLevelIndex, data)
	
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

func update_level_name_label(levelIndex: int, data: LevelData) -> void:
	if levelNameLabel == null:
		return
		
	var resolved_name := ""
	
	if data != null:
		resolved_name = data.displayName.strip_edges()
		
	if resolved_name.is_empty():
		resolved_name = "LEVEL %d" % (levelIndex + 1)
		
	levelNameLabel.text = resolved_name
	
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
	
	if is_final_level():
		currentState = RunState.RUN_COMPLETE
		stateChanged.emit(currentState)
		PlayerProgress.record_run_completed()
		PlayerProgress.request_credits_on_menu_load()
		call_deferred("_go_to_title")
		return
		
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
		
	if is_final_level():
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
	var kill_zone := layout.get_node_or_null("KillZone") as Area2D
	
	apply_decorative_prize_pile_layout(
		prize_chute,
		spawn_top_left,
		spawn_bottom_right
	)
	
	if chute_release_point != null:
		resolution_timer = chute_release_point.get_node_or_null("ResolutionTimer") as Timer
	
	if prizeContainer != null:
		prizeContainer.spawn_top_left = spawn_top_left
		prizeContainer.spawn_bottom_right = spawn_bottom_right
		prizeContainer.chuteArea = prize_chute
		prizeContainer.killZone = kill_zone
		prizeContainer.minimumSpawnSeparation = default_spawn_separation
		if kill_zone != null:
			var kill_callable := Callable(
				prizeContainer,
				"_on_kill_zone_body_entered"
			)
			
			if not kill_zone.body_entered.is_connected(kill_callable):
				kill_zone.body_entered.connect(kill_callable)
				
		var layout_settings := layout.get_node_or_null("LayoutSettings")
		
		if layout_settings != null:
			prizeContainer.minimumSpawnSeparation = float(
				layout_settings.get("spawn_separation")
			)
		
	if clawController != null:
		clawController.chuteArea = prize_chute
		clawController.chuteReleasePoint = chute_release_point
		clawController.resolutionTimer = resolution_timer
		
		if cable != null:
			clawController.cable = cable
		
		if prize_chute != null:
			var chute_callable := Callable(clawController, "_on_prize_chute_body_entered")
			
			if not prize_chute.body_entered.is_connected(chute_callable):
				prize_chute.body_entered.connect(chute_callable)
				
		if resolution_timer != null:
			var timer_callable := Callable(clawController, "_on_resolution_timer_timeout")
			
			if not resolution_timer.timeout.is_connected(timer_callable):
				resolution_timer.timeout.connect(timer_callable)

func apply_decorative_prize_pile_layout(
	prize_chute: Area2D,
	spawn_top_left: Marker2D,
	spawn_bottom_right: Marker2D
) -> void:
	if decorativePrizePiles == null:
		return
		
	if not hasDefaultDecorativePrizePilePosition:
		defaultDecorativePrizePilePosition = decorativePrizePiles.position
		hasDefaultDecorativePrizePilePosition = true
		
	var targetPosition := defaultDecorativePrizePilePosition
	
	if (
		prize_chute != null
		and spawn_top_left != null
		and spawn_bottom_right != null
	):
		var spawnCenterX := (
			spawn_top_left.global_position.x
			+ spawn_bottom_right.global_position.x
		) * 0.5
		
		if prize_chute.global_position.x < spawnCenterX:
			targetPosition.x += leftChutePrizePileOffsetX
			
	decorativePrizePiles.position = targetPosition
				
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

func is_final_level() -> bool:
	return currentLevelIndex >= levels.size() -1

func _go_to_title() -> void:
	get_tree().change_scene_to_file(title_scene_path)
