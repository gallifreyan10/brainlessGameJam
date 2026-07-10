extends RigidBody2D
class_name blueLittleGuy

@export var alien_data: AlienData


var _captured: bool = false

func try_mark_captured() -> bool:
	if _captured:
		return false
		
	_captured = true
	return true
	
func _ready() -> void:
	if alien_data == null:
		push_warning("Alien has no AlienData.")
		return
		
	for error in alien_data.get_validation_errors():
		push_warning(error)
