extends Node

signal alien_collected(alien_data: AlienData)

var collected_alien_ids: Array[StringName] = []
var collected_aliens: Array[AlienData] = []
var alien_stack_counts: Dictionary = {}
var collected_alien_data: Dictionary = {}
@export var alien_collected_sfx: AudioStream

const SAVE_PATH := "user://alien_collection.save"
const ALIEN_RESOURCE_FOLDER := "res://resources/aliens/"

func collect_alien(alien_data: AlienData) -> void:
	if alien_data == null:
		return
	
	if alien_data.alien_id == &"":
		return
	
	var alien_id := alien_data.alien_id
	
	if not collected_alien_ids.has(alien_data.alien_id):
		collected_alien_ids.append(alien_data.alien_id)	
		collected_aliens.append(alien_data)
		alien_stack_counts[alien_id] = 1
	else:
		alien_stack_counts[alien_id] = int(alien_stack_counts.get(alien_id, 0)) + 1
	
	print(
		"Collected alien: ", 
		alien_data.displayName,
		"stack count: ",
		alien_stack_counts[alien_id]
	)
	SFXManager.play_sfx(alien_collected_sfx)
	alien_collected.emit(alien_data)
	
	save_collection()
	
func has_alien(alien_id:StringName) -> bool:
	return collected_alien_ids.has(alien_id)
	
func get_alien_stack_count(alien_id: StringName) -> int:
	return int(alien_stack_counts.get(alien_id, 0))
		
func get_active_abilities() -> Array[AlienAbility]:
	var abilities: Array[AlienAbility] = []
	
	for alien in collected_aliens:
		if alien == null:
			continue
		if alien.ability == null:
			continue
		var stack_count := get_alien_stack_count(alien.alien_id)
		
		for i in stack_count:	
			abilities.append(alien.ability)
		
	return abilities	
	
func clear_collection_for_debug() -> void:
	collected_alien_ids.clear()
	collected_aliens.clear()
	alien_stack_counts.clear()

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

func get_rare_alien_spawn_multiplier() -> float:
	var multiplier := 1.0
	
	for ability in get_active_abilities():
		if ability.ability_type == AlienAbility.AbilityType.BOOST_RARER_ALIEN_SPAWNS:
			multiplier *= ability.magnitude
			
	return multiplier
	
func get_rare_mineral_spawn_multiplier() -> float:
	var multiplier := 1.0
	
	for ability in get_active_abilities():
		if ability.ability_type == AlienAbility.AbilityType.BOOST_RARE_MINERAL_SPAWNS:
			multiplier *= ability.magnitude
			
	return multiplier
	
func get_grip_strength_multiplier() -> float:
	var multiplier := 1.0
	
	for ability in get_active_abilities():
		if ability.ability_type == AlienAbility.AbilityType.GRIP_STRENGTH:
			multiplier *= ability.magnitude
			
	return multiplier
	
func find_alien_data_by_id(alien_id: StringName) -> AlienData:
	var files := DirAccess.get_files_at(ALIEN_RESOURCE_FOLDER)
	
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
	
		var path := ALIEN_RESOURCE_FOLDER + file_name
		var resource := load(path)
	
		if resource is AlienData:
			var alien_data := resource as AlienData
		
			if alien_data.alien_id == alien_id:
				return alien_data
	return null

func save_collection() -> void:
	var save_data := {
		"collected_alien_ids": [],
		"alien_stack_counts": {}
	}
	
	for alien_id in collected_alien_ids:
		save_data["collected_alien_ids"].append(String(alien_id))
		save_data["alien_stack_counts"][String(alien_id)] = get_alien_stack_count(alien_id)
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("Could not save alien collection.")
		return
		
	file.store_string(JSON.stringify(save_data))
	file.close()
	
	print("Saved alien collection.")
	
func load_collection() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		push_error("Could not load alien collection.")
		return
		
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Alien collection save data is invalid.")
		return
		
	collected_alien_ids.clear()
	collected_aliens.clear()
	alien_stack_counts.clear()
	
	var saved_ids: Array = parsed.get("collected_alien_ids", [])
	
	for saved_id in saved_ids:
		var alien_id := StringName(str(saved_id))
		var alien_data := find_alien_data_by_id(alien_id)
		
		if alien_data == null:
			push_warning("Could not find AlienData for saved alien id: %s" % alien_id)
			continue
			
		collected_alien_ids.append(alien_id)
		collected_aliens.append(alien_data)
		
		var saved_counts: Dictionary = parsed.get("alien_stack_counts", {})
		alien_stack_counts[alien_id] = int(saved_counts.get(String(alien_id), 1))
		
	print("Loaded alien collection: ", collected_alien_ids)
	
func _ready() -> void:
	load_collection()
