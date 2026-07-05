extends RigidBody2D
class_name MineralPrize

@export var mineral_data: MineralData

var _captured: bool = false

func try_mark_captured() -> bool:
	if _captured:
		return false
	
	_captured = true
	return true
	
