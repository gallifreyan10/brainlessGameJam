extends Resource
class_name AlienData

@export var alien_id:StringName
@export var displayName: String = "Alien"
@export var icon: Texture2D
@export_multiline var description:String
@export var ability:AlienAbility
@export var rarity: Rarity = Rarity.COMMON
@export var collection_slot: int = 0
@export var spawn_weight: float = 1.0
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	THECHOSEN
}

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	
	if alien_id == &"":
		errors.append("AlienData is missing alien_id")
		
	if displayName.strip_edges().is_empty():
		errors.append("AlienData %s is missing displayName." % alien_id)
		
	if ability == null:
		errors.append("AlienAbility %s is missing ability." % alien_id)
		
	else:
		errors.append_array(ability.get_validation_errors())
		
	if collection_slot < 0:
		errors.append("AlienData %s has invalid collection_slot." % alien_id)
		
	if spawn_weight <= 0.0:
		errors.append("AlienData %s should have spawn_weight greater than 0." % alien_id)
	return errors
