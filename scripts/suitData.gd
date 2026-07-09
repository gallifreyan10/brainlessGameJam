extends Resource
class_name  SuitData

@export var suit_id: StringName
@export var displayName: String = "Suit"
@export var price: int = 10
@export var icon: Texture2D
@export var blocks_cabinet_shake: bool = false

@export_category("Claw_Modifiers")
@export var drop_depth_bonus: float = 0.0
@export var horizontal_speed_multiplier: float = 1.0
@export var grab_area_scale_multiplier: float = 1.0
@export var max_tilt_angle_bonus: float = 0.0
@export var second_chance_regrabs: int = 0
