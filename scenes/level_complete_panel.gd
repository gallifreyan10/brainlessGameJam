extends PanelContainer

@export var runManager: RunManager

@onready var earningsLabel: Label = (
	$VBoxContainer/EarningsLabel
)
@onready var continueButton: Button = (
	$VBoxContainer/ContinueButton
)
@onready var shopButton: Button = (
	$VBoxContainer/ShopButton
)
func _ready() -> void:
	visible = false
	
	if runManager == null:
		push_error("LevelCompletePanel has no RunManager.")
		return
		
	runManager.levelCompleted.connect(_on_level_completed)
	runManager.levelCompleted.connect(_on_level_started)
	runManager.shopRequested.connect(_on_shop_requested)
	
	continueButton.pressed.connect(
		_on_continue_pressed
	)
	shopButton.pressed.connect(
		_on_shop_pressed
	)

func _on_level_completed(
	levelIndex: int,
	grossEarnings: int
) -> void:
	earningsLabel.text = (
		"Level %d earned: %d"
		% [
			levelIndex + 1,
			grossEarnings
		]
	)
	
	visible = true

func _on_level_started(
	_levelIndex: int,
	_data: LevelData
) -> void:
	visible = false
	
func _on_continue_pressed() -> void:
	runManager.continue_to_next_level()
	
func _on_shop_pressed() -> void:
	runManager.open_shop()
	
func _on_shop_requested() -> void:
	earningsLabel.text = "Shop coming later."
