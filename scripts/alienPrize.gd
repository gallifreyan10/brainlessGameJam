extends RigidBody2D
class_name AlienPrize

@export var alien_data: AlienData

@onready var sprite: Sprite2D = $LittleBlueAlien

var _captured: bool = false

func _ready() -> void:
	apply_alien_data()
	validate_alien_data()

func apply_alien_data() -> void:
	if alien_data == null:
		return
	
	if sprite != null and alien_data.icon != null:
		sprite.texture = alien_data.icon

func validate_alien_data() -> void:
	if alien_data == null:
		push_warning("AlienPrize has no AlienData.")
		return
	
	for error in alien_data.get_validation_errors():
		push_warning(error)
		
func try_mark_captured() -> bool:
	if _captured:
		return false
		
	_captured = true
	return true
