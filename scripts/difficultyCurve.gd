extends Resource
class_name DifficultyCurve

@export var quota_by_level: Array[int] = [30,45,65,90,120]

@export_category("Spawn Odds")
@export var common_mulitplier_by_level: Array [float] = [1.0, 0.9, 0.8, 0.7, 0.6]
@export var rare_multiplier_by_level: Array[float] = [1.0, 1.15, 1.35, 1.6, 1.9]

@export_category("Mineral Rarity")
@export_range(0.0, 1.0, 0.05) var commonReductionPerLevel := 0.15
@export_range(0.0, 2.0, 0.05) var rareIncreasePerLevel := 0.25

@export_category("Prize Weight")
@export var minimum_prize_weight_by_level: Array[float] = [0.5, 0.5, 0.75, 0.9, 1.0]
@export var maximum_prize_weight_by_level: Array[float] = [5.0, 5.5, 6.0, 7.0, 8.0]

@export_category("Timer")
@export var timer_multiplier_by_level: Array[float] = [1.0, 0.95, 0.9, 0.85, 0.8]

# Called when the node enters the scene tree for the first time.
func resolve(levelIndex: int) -> Dictionary:
	
	return{
		"quota": _get_int(quota_by_level, levelIndex, 30),
		"common_multiplier": _get_float(common_mulitplier_by_level, levelIndex, 1.0),
		"rare_multiplier": _get_float(rare_multiplier_by_level, levelIndex, 1.0),
		"minimum_prize_weight": _get_float(minimum_prize_weight_by_level, levelIndex, 0.5),
		"maximum_prize_weight": _get_float(maximum_prize_weight_by_level, levelIndex, 5.0),
		"timer_multiplier": _get_float(timer_multiplier_by_level, levelIndex, 1.0)
	}

func _get_int(values: Array[int], index:int, fallback:int) -> int:
	if values.is_empty():
		return fallback
	
	return values[clampi(index, 0, values.size() -1)]
	
func _get_float(values: Array[float], index:int, fallback:float) -> float:
	if values.is_empty():
		return fallback
		
	return values[clampi(index,0,values.size()-1)]
