extends Resource
class_name MineralData

enum Rarity{
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	THECHOSEN
}

@export_category("Identity")
@export var mineral_id: StringName
@export var displayName: String

@export_category("Visuals")
@export var sprite: Texture2D
@export var collision_shape: Shape2D
@export var rarity: Rarity = Rarity.COMMON
@export var rarity_color: Color = Color.WHITE

@export_category("Economy")
@export_range(0, 100000, 1) var sale_value: int = 1
@export_range(0, 100, 1) var weight: float = 1.1
@export_range(0, 1000.0, 1) var spawn_weight: float = 1

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	
	if mineral_id.is_empty():
		errors.append("Mineral ID is missing.")
		
	if displayName.is_empty():
		errors.append("Display name is missing for %s." % mineral_id)
		
	if sprite == null:
		errors.append("Sprite is missing for %s." % mineral_id)	
		
	if collision_shape == null:
		errors.append("Collision shape is missing for %s." % mineral_id)
		
	if sale_value < 0:
		errors.append("Sale value cannot be negative for %s." % mineral_id)
		
	if weight <= 0.0:
		errors.append("Weight must be greater than zero for %s." % mineral_id)
		
	if spawn_weight <= 0.0:
		errors.append("Spawn weight must be greater than zero for %s." % mineral_id)
		
	return errors
