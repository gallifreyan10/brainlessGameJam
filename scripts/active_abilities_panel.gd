extends PanelContainer

@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var ability_list: VBoxContainer = $MarginContainer/VBoxContainer/AbilityList
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton
@export var runManager: RunManager

const ALIEN_RESOURCE_FOLDER := "res://resources/aliens/"

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	AlienCollection.alien_collected.connect(_on_alien_collected)
	refresh()

func open() -> void:
	if visible:
		return

	if runManager != null:
		runManager.request_ui_timer_pause()

	visible = true
	
func close() -> void:
	if not visible:
		return
	
	visible = false
	
	if runManager != null:
		runManager.release_ui_timer_pause()
	
func refresh() -> void:
	for child in ability_list.get_children():
		child.queue_free()
		
	var aliens := get_all_alien_data()
	aliens.sort_custom(_sort_by_collection_slot)
	
	var active_count := 0
	
	for alien_data in aliens:
		if not AlienCollection.has_alien(alien_data.alien_id):
			continue
			
		if alien_data.ability == null:
			continue
			
		var stack_count :int = AlienCollection.get_alien_stack_count(alien_data.alien_id)
		
		if stack_count <= 0:
			continue
			
		var row := create_ability_row(alien_data, stack_count)
		ability_list.add_child(row)
		active_count += 1
		
	if active_count == 0:
		summary_label.text = "No active alien abilities yet."
	else:
		summary_label.text = "Active Abilities: %d" % active_count
		
func get_all_alien_data() -> Array[AlienData]:
	var aliens: Array[AlienData] = []
	var files := DirAccess.get_files_at(ALIEN_RESOURCE_FOLDER)
	
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		
		var path := ALIEN_RESOURCE_FOLDER + file_name
		var resource := load(path)
		
		if resource is AlienData:
			aliens.append(resource as AlienData)
			
	return aliens

func _sort_by_collection_slot(a: AlienData, b: AlienData) -> bool:
	return a.collection_slot < b.collection_slot
	
func create_ability_row(alien_data: AlienData, stack_count: int) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	
	var name_label := Label.new()
	var stack_label := Label.new()
	var effect_label := Label.new()
	
	var ability := alien_data.ability
	
	name_label.text = "%s - %s" %[alien_data.displayName, ability.displayName]
	stack_label.text = "Stacks: %d" % stack_count
	effect_label.text = get_effect_text(ability, stack_count)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.custom_minimum_size = Vector2(260,0)
	
	box.add_child(name_label)
	box.add_child(stack_label)
	box.add_child(effect_label)
	
	panel.add_child(box)
	return panel
	
func get_effect_text(ability: AlienAbility, stack_count: int) -> String:
	match ability.ability_type:
		AlienAbility.AbilityType.SALE_VALUE_MULTIPLIER:
			var total_multiplier := pow(ability.magnitude, stack_count)
			return "Mineral sale value x%.2f" % total_multiplier
			
		AlienAbility.AbilityType.GRIP_STRENGTH:
			var total_multiplier := pow(ability.magnitude, stack_count)
			return "Claw Grip Strength x%.2f" % total_multiplier
		
		AlienAbility.AbilityType.SUIT_DISCOUNT:
			var total_multiplier := pow(ability.magnitude, stack_count)
			return "Suit prices x%.2f" % total_multiplier
		
		AlienAbility.AbilityType.BOOST_RARE_MINERAL_SPAWNS:
			var total_multiplier := pow(ability.magnitude, stack_count)
			return "Rare Mineral spawn chance increased by x%.2f" % total_multiplier
		
		AlienAbility.AbilityType.ATTEMPT_NUMBER_INCREASED:
			var total_bonus := int(ability.magnitude) * stack_count
			return "+%d claw attempts" % total_bonus
		
		AlienAbility.AbilityType.BOOST_RARER_ALIEN_SPAWNS:
			var total_multiplier := pow(ability.magnitude, stack_count)
			return "Rare Alien spawn chance increased by x%.2f" % total_multiplier
			
		_:
			return "Unknown ability effect."
			
func _on_alien_collected(_alien_data: AlienData) -> void:
	refresh()
	
func _on_close_pressed() -> void:
	close()
