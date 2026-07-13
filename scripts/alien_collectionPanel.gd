extends PanelContainer

@onready var slots_grid: GridContainer = $MarginContainer/VBoxContainer/SlotsGrid
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel
@onready var stack_label: Label = $MarginContainer/VBoxContainer/StackLabel
@export var runManager: RunManager

const ALIEN_RESOURCE_FOLDER := "res://resources/aliens/"

func _ready() -> void:
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
	if runManager != null:
		runManager.release_ui_timer_pause()
		
	visible = false
	
func refresh() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
		
	var aliens := get_all_alien_data()
	aliens.sort_custom(_sort_by_collection_slot)
	
	var unique_count := get_unique_collected_count(aliens)
	var total_slots := aliens.size()
	var total_stacks := get_total_stack_count(aliens)
	
	progress_label.text = "Aliens Collected: %d / %d" %[unique_count,total_slots]
	stack_label.text = "Total Alien Stacks: %d" % total_stacks
	
	for alien_data in aliens:
		var slot := create_slot(alien_data)
		slots_grid.add_child(slot)

func get_unique_collected_count(aliens: Array[AlienData]) -> int:
	var count := 0
	
	for alien_data in aliens:
		if AlienCollection.has_alien(alien_data.alien_id):
			count += 1
			
	return count

func get_total_stack_count(aliens: Array[AlienData]) -> int:
	var count := 0
	
	for alien_data in aliens:
		count += AlienCollection.get_alien_stack_count(alien_data.alien_id)
		
	return count
	
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
	
func _sort_by_collection_slot(a: AlienData,b: AlienData) -> bool:
	return a.collection_slot < b.collection_slot
	
func create_slot(alien_data: AlienData) -> Control:
	var slot := VBoxContainer.new()
	slot.custom_minimum_size = Vector2(120,90)
	
	var icon_rect := TextureRect.new()
	var name_label := Label.new()
	var status_label := Label.new()
	var stack_label := Label.new()
	
	icon_rect.custom_minimum_size = Vector2(64,64)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var collected : bool = AlienCollection.has_alien(alien_data.alien_id)
	var stack_count : int = AlienCollection.get_alien_stack_count(alien_data.alien_id)
	
	if alien_data.icon != null:
		icon_rect.texture = alien_data.icon
	else:
		icon_rect.texture = null
	
	if collected:
		icon_rect.modulate = Color.WHITE
		name_label.text = alien_data.displayName
		status_label.text = "Collected"
		stack_label.text = "Stacks %d" % stack_count
	else:
		icon_rect.modulate = Color(0.05, 0.05,0.05,0.85)
		name_label.text = "???"
		status_label.text = "Locked"
		stack_label.text = ""
	
	slot.add_child(icon_rect)	
	slot.add_child(name_label)
	slot.add_child(status_label)
	slot.add_child(stack_label)
	
	return slot
	
func _on_alien_collected(_alien_data: AlienData) -> void:
	refresh()
		
func _on_close_pressed() -> void:
	close()
