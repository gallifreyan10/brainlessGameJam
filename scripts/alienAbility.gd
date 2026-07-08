extends Resource
class_name AlienAbility

enum AbilityType {
	NONE,
	SALE_VALUE_MULTIPLIER,
	GRIP_STRENGTH,
	SUIT_DISCOUNT,
	BOOST_RARE_MINERAL_SPAWNS,
	ATTEMPT_NUMBER_INCREASED,
	BOOST_RARER_ALIEN_SPAWNS
}

@export var ability_id: StringName
@export var displayName: String = "Ability"
@export_multiline var description: String
@export var ability_type: AbilityType = AbilityType.NONE
@export var magnitude: float = 0.0
@export var icon: Texture2D

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	
	if ability_id == &"":
		errors.append("AlienAbility is missing ability_id")
		
	if displayName.strip_edges().is_empty():
		errors.append("AlienAbility %s is missing displayName." % ability_id)
		
	if ability_type == AbilityType.NONE:
		errors.append("AlienAbility %s has AbilityType.NONE." % ability_id)
		
	if magnitude >= 0.0:
		errors.append("AlienAbility %s should have magnitude greater than 0." % ability_id)
		
	return errors
