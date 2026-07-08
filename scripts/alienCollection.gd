extends Node

signal alien_collected(alien_data: AlienData)

var collected_alien_ids: Array[StringName] = []
var collected_aliens: Array[AlienData] = []
var collected_alien_data: Dictionary = {}

func collect_alien(alien_data: AlienData) -> void:
	if alien_data == null:
		return
	
	if alien_data.alien_id == &"":
		return
	
	if collected_alien_ids.has(alien_data.alien_id):
		return
	
	collected_alien_ids.append(alien_data.alien_id)	
	collected_aliens.append(alien_data)
	
	print("Collected alien: ", alien_data.displayName)
	alien_collected.emit(alien_data)
	
func has_alien(alien_id:StringName) -> bool:
	return collected_alien_ids.has(alien_id)
	
func get_active_abilities() -> Array[AlienAbility]:
	var abilities: Array[AlienAbility] = []
	
	for alien in collected_aliens:
		if alien == null:
			continue
		if alien.ability == null:
			continue
			
		abilities.append(alien.ability)
		
	return abilities	
	
func clear_collection_for_debug() -> void:
	collected_alien_ids.clear()
	collected_aliens.clear()

func get_sale_value_multiplier() -> float:
	var multiplier := 1.0
	
	for ability in get_active_abilities():
		if ability.ability_type == AlienAbility.AbilityType.SALE_VALUE_MULTIPLIER:
			multiplier *= ability.magnitude
			
	return multiplier
	
func get_suit_price_multiplier() -> float:
	var multiplier := 1.0
	
	for ability in get_active_abilities():
		if ability.ability_type == AlienAbility.AbilityType.SUIT_DISCOUNT:
			multiplier *= ability.magnitude
			
	return multiplier

func get_extra_attempts() -> int:
	var extra_attempts := 0
	
	for ability in get_active_abilities():	
		if ability.ability_type == AlienAbility.AbilityType.ATTEMPT_NUMBER_INCREASED:
			extra_attempts += int(ability.magnitude)
			
	return extra_attempts
