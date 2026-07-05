extends Resource
class_name MineralData

@export var mineral_id: StringName
@export var displayName: String
@export_range(0, 100000, 1) var base_value: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
