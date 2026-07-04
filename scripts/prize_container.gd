extends Node2D
@export var blue_Scene: PackedScene
var rng = RandomNumberGenerator.new()
var alienCount: int = rng.randi_range(1, 6)
@export var spawn_top_left: Marker2D
@export var spawn_bottom_right: Marker2D
var reset_count: int = 0

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


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if not body is RigidBody2D:
		return
	
	var prize := body as RigidBody2D
	
	if not prize.is_in_group("prizes"):
		return
	
	if not is_instance_valid(prize):
		return
		
	call_deferred("reset_prize", prize)

func reset_prize(prize: RigidBody2D) -> void:
	if not is_instance_valid(prize):
		return
	if prize.is_queued_for_deletion():
		return
	
	var minimum_x := minf(spawn_top_left.global_position.x,
	spawn_bottom_right.global_position.x)
	
	var maximum_x := maxf(spawn_top_left.global_position.x,
	spawn_bottom_right.global_position.x)
	
	var minimum_y := minf(spawn_top_left.global_position.y,
	spawn_bottom_right.global_position.y)
	
	var maximum_y := maxf(spawn_top_left.global_position.y,
	spawn_bottom_right.global_position.y)
	
	prize.freeze = true
	
	prize.global_position = Vector2(
		randf_range(minimum_x, maximum_x),
		randf_range(minimum_y, maximum_y)
	)
	
	prize.linear_velocity = Vector2.ZERO
	prize.angular_velocity = 0.0
	prize.rotation = 0.0
	
	#restore expected prize collision settings
	prize.collision_layer = 2
	prize.collision_mask = 3
	prize.freeze = false
	prize.sleeping = false
	
	reset_count += 1
	print("Escaped prizes reset: ", reset_count)
