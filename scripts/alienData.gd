extends Resource
class_name AlienData

@export var alien_id:StringName
@export var displayName: String = "Alien"
@export var icon: Texture2D
@export_multiline var description:String
@export var ability:AlienAbility

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	
	if ability.ability_id == &"":
		errors.append("AlienAbility is missing ability_id")
		
	if displayName.strip_edges().is_empty():
		errors.append("AlienAbility %s is missing displayName." % ability.ability_id)
		
	if ability.ability_type == AlienAbility.AbilityType.NONE:
		errors.append("AlienAbility %s has AbilityType.NONE." % ability.ability_id)
		
	if ability == null:
		errors.append("AlienAbility %s is missing ability." % alien_id)
		
	else:
		errors.append_array(ability.get_validation_errors())
		
	return errors
