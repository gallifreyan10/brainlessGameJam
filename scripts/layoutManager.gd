extends Node2D
class_name LayoutManager

@export var layouts: Array[PackedScene] = []
@export var avoid_repeating_layout: bool = true

var current_layout: Node = null
var last_layout_index: int = -1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func load_random_layout() -> Node:
	if layouts.is_empty():
		push_warning("LayoutManager has no layouts assigned.")
		return null
		
	var index := choose_layout_index()
	return load_layout(index)
	
func load_layout(index: int) -> Node:
	if index < 0 or index >= layouts.size():
		push_error("Invalid layout index: %d" % index)
		return null
		
	if current_layout != null:
		current_layout.queue_free()
		current_layout = null
		
	current_layout = layouts[index].instantiate()
	add_child(current_layout)
	last_layout_index = index
	
	return current_layout
	
func choose_layout_index() -> int:
	if layouts.size() == 1:
		return 0
		
	var index := rng.randi_range(0,layouts.size()-1)
	
	if avoid_repeating_layout:
		while index == last_layout_index:
			index = rng.randi_range(0,layouts.size()-1)
			
	return index
	
func get_current_layout() -> Node:
	return current_layout
