extends Node2D
@export var blue_Scene: PackedScene
var rng = RandomNumberGenerator.new()
var alienCount = rng.randf_range(0, 6)
@export var spawn_top_left: Marker2D
@export var spawn_bottom_right: Marker2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawnLittleGuys()


func spawnLittleGuys() -> void:
	for index in alienCount:
		spawnLittleGuy()
		

func spawnLittleGuy() -> void:
	if blue_Scene == null:
		push_error("No prizes have been spawned")
		return
		
	var blue := blue_Scene.instantiate() as RigidBody2D
	add_child(blue)
	
	var minimum_x := minf(
		spawn_top_left.position.x,
		spawn_bottom_right.position.x
		)
	var maximum_x := maxf(
		spawn_top_left.position.x,
		spawn_bottom_right.position.x
		)
	var minimum_y := minf(
		spawn_top_left.position.y,spawn_bottom_right.position.y
		)
	var maximum_y := maxf(spawn_top_left.position.y,
	spawn_bottom_right.position.y
	)
	
	blue.position = Vector2(randf_range(minimum_x,maximum_x),randf_range(minimum_y,maximum_y))
	
	blue.rotation = rng.randf_range(-1.0,1.0)
