extends Resource
class_name DifficultyCurve

@export_category("Quota")
@export_range(1,100000,1) var baseQuota: int = 30
@export_range(1.0,5.0,0.05) var quotaGrowth: float = 1.5
@export_range(1,100000,1) var maximumQuota: int = 1000

@export_category("Mineral Rarity")
@export_range(0.0, 1.0, 0.05) var commonReductionPerLevel := 0.15
@export_range(0.0, 2.0, 0.05) var rareIncreasePerLevel := 0.25

@export_category("Prize Weight Caps")
@export_range(0.1, 100.0, 0.1) var minimumPrizeWeight := 0.5
@export_range(0.1, 100.0, 0.1) var maximumPrizeWeight := 5.0

@export_category("Optional Timing")
@export_range(0.25, 1.0, 0.05) var timerMultiplierPerLevel := 0.95
@export_range(0.25, 1.0, 0.05) var minimumTimerMultiplier := 0.6

# Called when the node enters the scene tree for the first time.
func resolve(levelIndex: int) -> Dictionary:
	var quota := mini(
		maximumQuota,
		roundi(
			baseQuota
			* pow(quotaGrowth, levelIndex)
		)
	)
	
	var commonMultiplier := maxf(
		0.25,
		1.0
		- commonReductionPerLevel * levelIndex
	)
	
	var rareMultiplier := (
		1.0
		+ rareIncreasePerLevel
		* levelIndex
	)
	
	var timerMultiplier := maxf(
		minimumTimerMultiplier,
		pow(
			timerMultiplierPerLevel,
			levelIndex
		)
	)
	
	return{
		"quota": quota,
		"common_multiplier": commonMultiplier,
		"rare_multiplier": rareMultiplier,
		"minimum_prize_weight": minimumPrizeWeight,
		"maximum_prize_weight": maximumPrizeWeight,
		"timer_multiplier": timerMultiplier
	}
