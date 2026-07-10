extends RigidBody2D
class_name MineralPrize

@export var mineral_data: MineralData

var _captured: bool = false

func _ready() -> void:
	if mineral_data == null:
		push_warning("MineralPrize has no MineralData:" + name)
		return
	setup(mineral_data)
	
func setup(data: MineralData) -> void:
	if data == null:
		push_error("Cannot setup a mineral with null data.")
		return
		
	mineral_data = data
	
	var validationErrors := data.get_validation_errors()
	
	for error in validationErrors:
		push_warning(error)
		
	var spriteNode := get_node_or_null("Sprite2D") as Sprite2D
	
	var collisionNode := get_node_or_null("CollisionShape2D") as CollisionShape2D
		
	if spriteNode != null:
		spriteNode.texture = data.sprite
		spriteNode.modulate = data.rarity_color
		
	if collisionNode != null:
		collisionNode.shape = data.collision_shape
		
	mass = data.weight
	
	set_meta("mineral_id", data.mineral_id)
	set_meta("rarity", data.rarity)
	
func try_mark_captured() -> bool:
	if _captured:
		return false
	
	_captured = true
	return true
	
