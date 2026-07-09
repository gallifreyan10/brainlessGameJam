extends CharacterBody2D
@export_category("Movement")
@export var horizontal_speed:float = 100
@export var drop_speed: float = 120
@export var return_speed: float = 150
@export var maximum_drop_depth: float = 290
var base_horizontal_speed: float
var base_maximum_drop_depth: float
var base_grab_area_scale: Vector2
var max_second_chance_regrabs: int = 0
var second_chance_regrabs_remaining: int = 0
var blocks_cabinet_shake: bool = false

@export_category("Tilt")

@export var base_max_tilt_angle_degrees: float = 8.0
@export var tilt_speed_degrees: float = 90.0
@export var tilt_return_speed_degrees: float = 60.0
@export var mouse_tilt_full_distance: float = 180.0
@export var tilted_drop_horizontal_multiplier: float = 1.0

var max_tilt_angle_degrees: float
var current_tilt_degrees: float = 0.0
var locked_drop_tilt_degrees: float = 0.0

@export_category("Timing")
@export var grabbing_duration: float = 0.75

@export_category("References")
#Timer that gets triggered when player takes too long and drops claw
@export var attempt_timer: Timer
#Array of possible prizes to be picked from
var grab_candidates: Array[RigidBody2D] = []
@export var grab_Area: Area2D
@export var hold_point: Marker2D
@export var release_point: Marker2D
@export var chuteReleasePoint: Marker2D
@export var chuteArea: Area2D
@export var resolutionTimer: Timer
@export var release_impulse: float = 30.0
@export var chuteMoveSpeed: float = 120.0
@export var chuteArrivalTolerance: float = 2.0

#Selected prize that is picked up by the claw
var held_prize: RigidBody2D = null
var held_prize_original_parent: Node = null
var resolvingPrize: RigidBody2D = null

signal prize_released(prize: RigidBody2D)
signal attempt_finished
var held_prize_original_layer: int
var held_prize_original_mask: int
@export_category("Animations")
@export var animation_player: AnimationPlayer
signal claw_closed(claw: CharacterBody2D)

var close_request_locked: bool = false
var attemptsLocked: bool = false

#Downwards cast checking for bottom of cabinet
@export var bottom_detector: RayCast2D

#Visually connects cable
@export var cable:Line2D
@export var cableAttachPoint: Marker2D

@export var current_State: State = State.IDLE

@export var starting_y:float = 0

@export_range(0.0, 1.0) var slipChance: float = 0.15
@export var minimum_slip_delay: float = 0.5
@export var maximum_slip_delay: float = 1.5

@export var slipTimer: Timer
@export var runManager: RunManager

signal prize_Slipped(prize: RigidBody2D)

signal position_changed(new_position: Vector2)
signal state_changed(new_state: State)

enum State{
	IDLE,
	DROPPING,
	GRABBING,
	RETURNING,
	RELEASING,
	MOVING_TO_CHUTE,
	RESOLVING
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#Only trigger the behaviour belonging to the currently activated state
	match current_State:
		State.IDLE:
			process_idle()
		State.DROPPING:
			process_dropping()
		State.GRABBING:
			process_grabbing()
		State.RETURNING:
			process_returning()
		State.RELEASING:
			process_releasing()
		State.MOVING_TO_CHUTE:
			process_moving_to_chute()
		State.RESOLVING:
			process_resolving()
	updateCable()
	
	

func process_idle() -> void:
	if attemptsLocked:
		velocity = Vector2.ZERO
		return
	
	#Player Control is only available when claw is idle
	var direction := Input.get_axis("move_left","move_right")

	velocity = Vector2(direction * horizontal_speed,0.0)
	move_and_slide()
	
	process_tilt_input(get_physics_process_delta_time())

func process_tilt_input(delta: float) -> void:
	var viewport_rect := get_viewport_rect()
	var mouse_viewport_position := get_viewport().get_mouse_position()
	var mouse_is_inside_window := viewport_rect.has_point(mouse_viewport_position)
	
	var controller_tilt_strength := Input.get_axis(
		"tilt_left",
		"tilt_right"
	)
	
	var final_tilt_strength := 0.0
	
	if absf(controller_tilt_strength) > 0.1:
		final_tilt_strength = controller_tilt_strength
	elif mouse_is_inside_window:
		var mouse_position := get_global_mouse_position()
		var mouse_offset_x := mouse_position.x - global_position.x
		
		final_tilt_strength = -clampf(
			mouse_offset_x / mouse_tilt_full_distance,
			-1.0,
			1.0
		)
	else:
		final_tilt_strength = 0.0
			
	var target_tilt := final_tilt_strength * max_tilt_angle_degrees
	
	current_tilt_degrees = move_toward(
		current_tilt_degrees,
		target_tilt,
		tilt_speed_degrees * delta
	)
	
	rotation_degrees = current_tilt_degrees
	
func reset_tilt() -> void:
	current_tilt_degrees = 0.0
	rotation_degrees = 0.0
	
func start_dropping() -> void:
	if attemptsLocked:
		return
		
	if runManager != null:
		runManager.stop_attempt_countdown()
	#Prevent repeated input or timer signals from restarting an already triggered drop
	if current_State != State.IDLE:
		return
	if slipTimer != null:
		slipTimer.stop()	
		
	grab_candidates.clear()
		
	if attempt_timer != null:
		attempt_timer.stop()
	
	locked_drop_tilt_degrees = current_tilt_degrees
	second_chance_regrabs_remaining = max_second_chance_regrabs
	change_state(State.DROPPING)
	
func process_dropping() -> void:
	#Player controls are locked during drop
	var tilt_radians := deg_to_rad(locked_drop_tilt_degrees)
	 
	velocity.x = -sin(tilt_radians) * drop_speed * tilted_drop_horizontal_multiplier
	velocity.y = cos(tilt_radians) * drop_speed
	
	rotation_degrees = locked_drop_tilt_degrees
	
	move_and_slide()
	
	position_changed.emit(global_position)
	 
	var detector_hit := (
		bottom_detector != null 
		and bottom_detector.is_colliding()
	)
	
	var reached_maximum_depth := (
		global_position.y >= starting_y + maximum_drop_depth
	)
	 #if max depth is reached or claw collides with bottom these conditions are triggered
	if detector_hit or reached_maximum_depth:
		velocity = Vector2.ZERO
		request_close_claw()
		change_state(State.GRABBING)
		
func process_grabbing() -> void:
	#The claw remains still while the grab animation occurs
	velocity = Vector2.ZERO
	
		
func process_returning() -> void:
	#Player Movement is disabled while returning
	velocity.x = 0
	velocity.y = -return_speed
	
	move_and_slide()
	
	position_changed.emit(global_position)
	
	#Stop at the exact starting position
	if global_position.y <= starting_y:
		global_position.y = starting_y
		velocity = Vector2.ZERO
		reset_tilt()
		
		if grab_Area != null:
			grab_Area.set_deferred("monitoring", false)
			
		grab_candidates.clear()
		
		if is_instance_valid(held_prize):
			change_state(State.MOVING_TO_CHUTE)
		else:
		#Lock the claw in place while it opens
			change_state(State.RELEASING)
		
			if animation_player != null:
				animation_player.play(&"open_claw")
	
func process_releasing() -> void:
	velocity = Vector2.ZERO
	
func process_moving_to_chute() -> void:
	if chuteReleasePoint == null:
		push_error("Chute Release Point is not assigned.")
		velocity = Vector2.ZERO
		return
	if not is_instance_valid(held_prize):
		velocity = Vector2.ZERO
		change_state(State.RELEASING)
		animation_player.play(&"open_claw")
		return
	var difference := (chuteReleasePoint.global_position.x-global_position.x)
	
	velocity.y = 0.0
	
	if absf(difference) <=chuteArrivalTolerance:
		global_position.x = chuteReleasePoint.global_position.x
		velocity = Vector2.ZERO
		change_state(State.RELEASING)
		animation_player.play(&"open_claw")
		return
	
	velocity.x = signf(difference) * chuteMoveSpeed
	move_and_slide()
	
func process_resolving() -> void:
	velocity = Vector2.ZERO	
	
func finish_resolution() -> void:
	if resolutionTimer != null:
		resolutionTimer.stop()
		
	if slipTimer != null:
		slipTimer.stop()
		
	resolvingPrize = null
	close_request_locked = false
	change_state(State.IDLE)
	attempt_finished.emit()
	
	if attempt_timer != null and not attemptsLocked:
		attempt_timer.start()
			
func updateCable() -> void:
	if cable == null or cableAttachPoint == null:
		return
		
	if cable.get_point_count() < 2:
		return
	#The first Line2D point remains attached to the cabinet
	#the second point follows the claw in the cable's local coordinates
	cable.set_point_position(1,cable.to_local(cableAttachPoint.global_position))
		
func change_state(new_State: State) -> void:
	if current_State == new_State:
		return
		
	current_State = new_State
	state_changed.emit(current_State)
	
func _on_attempt_timer_timeout() -> void:
	#The timer may begin a drop only while horizontal control is active
	if current_State == State.IDLE:
		start_dropping()
	
func request_close_claw() -> void:
	if current_State != State.DROPPING:
		return
		
	if close_request_locked:
		return
		
	close_request_locked = true
	velocity = Vector2.ZERO
	grab_candidates.clear()
	
	grab_Area.set_deferred("monitoring", true)
	
	change_state(State.GRABBING)
	animation_player.play(&"close_claw")	
	
func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"close_claw":
		if current_State != State.GRABBING:
			return
			
		remove_invalid_candidates()
		
		#Select one prize before clearing the temporary candidates.
		held_prize = choose_nearest_candidate()
		grab_Area.set_deferred("monitoring", false)
		grab_candidates.clear()
			
		if is_instance_valid(held_prize):
			hold_selected_prize()
			
		claw_closed.emit(self)
		change_state(State.RETURNING)
		return
		
	if animation_name == &"open_claw":
		release_held_prize(true)
		
		if is_instance_valid(resolvingPrize):
			change_state(State.RESOLVING)
			
			if resolutionTimer != null:
				resolutionTimer.start()
			else:
				finish_resolution()
		else:
			finish_resolution()
				
		return
	
func hold_selected_prize() -> void:
	if not is_instance_valid(held_prize):
		held_prize = null
		return
		
	#Save everything needed to give back to prize if it is dropped
	held_prize_original_parent = held_prize.get_parent()
	held_prize_original_layer = held_prize.collision_layer
	held_prize_original_mask = held_prize.collision_mask
	
	#preserve its world transform during reparting
	var previous_transform := held_prize.global_transform
	
	#Disable normal physics while held
	held_prize.freeze = true
	held_prize.collision_layer = 0
	held_prize.collision_mask = 0
	
	held_prize.reparent(hold_point)
	held_prize.global_transform = previous_transform
	
	if slipTimer != null:
		slipTimer.stop()
		
		if randf() < slipChance:
			var grip_multiplier := AlienCollection.get_grip_strength_multiplier()
			slipTimer.wait_time = randf_range(minimum_slip_delay,maximum_slip_delay) * grip_multiplier
			start_slip_timer()
			
func release_held_prize(expect_chute_resolution: bool = true) -> void:
	if slipTimer != null:
		slipTimer.stop()
	
	grab_Area.set_deferred("monitoring", false)
	grab_candidates.clear()
	
	#a second call is stoppped here
	if not is_instance_valid(held_prize):
		held_prize = null
		held_prize_original_parent = null
		return
		
	if release_point == null:
		push_error("Relase Point has not been assigned")
		return
		
	var released_prize: RigidBody2D = held_prize
	held_prize = null
	
	if is_instance_valid(held_prize_original_parent):
		released_prize.reparent(held_prize_original_parent)
	else:
		released_prize.reparent(get_tree().current_scene)
		
	released_prize.global_position = release_point.global_position
	
	released_prize.collision_layer = held_prize_original_layer
	released_prize.collision_mask = held_prize_original_mask
	released_prize.freeze = false
	released_prize.linear_velocity = Vector2.ZERO
	released_prize.angular_velocity = 0.0
	released_prize.sleeping = false
	
	released_prize.apply_central_impulse(Vector2.DOWN * release_impulse)
	
	if expect_chute_resolution:
		resolvingPrize = released_prize
	else:
		resolvingPrize = null
		
	held_prize_original_parent = null
	prize_released.emit(released_prize)
	
func _ready() -> void:
	base_horizontal_speed = horizontal_speed
	base_maximum_drop_depth = maximum_drop_depth
	
	if grab_Area != null:
		base_grab_area_scale = grab_Area.scale
	
	max_tilt_angle_degrees = base_max_tilt_angle_degrees
	
	starting_y = global_position.y
	
	 #Connect the timeout through code if it's not already connected
	if attempt_timer != null:
		if not attempt_timer.timeout.is_connected(_on_attempt_timer_timeout):
			attempt_timer.timeout.connect(_on_attempt_timer_timeout)
			
	if bottom_detector != null:
		bottom_detector.enabled=true
		
	if animation_player != null:
		if not animation_player.animation_finished.is_connected(
			_on_animation_finished
		): 
			animation_player.animation_finished.connect(_on_animation_finished)
	#Connect the quota signal here
	if not RunEconomy.quotaReached.is_connected(
		_on_quota_reached
	):
		RunEconomy.quotaReached.connect(
			_on_quota_reached
		)
		
	if not RunEconomy.levelStarted.is_connected(_on_level_started):
		RunEconomy.levelStarted.connect(_on_level_started)
		
	if runManager != null:
		runManager.attemptsDepleted.connect(_on_attempts_depleted)
		runManager.countdownExpired.connect(_on_countdown_expired)
		runManager.suitEquipped.connect(_on_suit_equipped)
		apply_suit_modifiers(runManager.equippedSuit)
func choose_nearest_candidate() -> RigidBody2D:
	remove_invalid_candidates()
	
	var nearest_prize: RigidBody2D = null
	var nearest_distance_squared: float = INF
	
	for prize in grab_candidates:
		if not is_instance_valid(prize):
			continue
		if prize.is_queued_for_deletion():
			continue
		if not prize.is_inside_tree():
			continue
			
		#optional eligability check if all prizes use this group
		if not prize.is_in_group("prizes"):
			continue
		
		var distance_squared := (
			hold_point.global_position.distance_squared_to(prize.global_position)
		)
		
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_prize = prize
			
	return nearest_prize

func _on_grab_area_body_entered(body: Node2D) -> void:
	# Ignore cabinet walls and other non-prize body types
	if not body is RigidBody2D:
		return
	
	var prize := body as RigidBody2D
	
	#Ignore bodies that are already being deleted
	if not is_instance_valid(prize):
		return
	
	if prize.is_queued_for_deletion():
		return
		
	#prevent the same prize from appearing twice
	if not grab_candidates.has(prize):
		grab_candidates.append(prize)

func _on_grab_area_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		grab_candidates.erase(body)
		
	remove_invalid_candidates()
	
func remove_invalid_candidates() -> void:
	for index in range(grab_candidates.size() -1, -1, -1):
		var prize := grab_candidates[index]
	
		if not is_instance_valid(prize):
			grab_candidates.remove_at(index)
			continue
	
		if prize.is_queued_for_deletion():
			grab_candidates.remove_at(index)
			continue
	
		if not prize.is_inside_tree():
			grab_candidates.remove_at(index)
			
func _exit_tree() -> void:
	if slipTimer != null:
		slipTimer.stop()
	grab_candidates.clear()


func _on_slip_timer_timeout() -> void:
	if not is_instance_valid(held_prize):
		return
		
	if second_chance_regrabs_remaining > 0:
		second_chance_regrabs_remaining -= 1
		
		print("Second Chance Suit saved: ", held_prize.name)
		
		start_slip_timer()
		return	
	#For now slipping happens while the claw rises
	if current_State != State.RETURNING and current_State != State.MOVING_TO_CHUTE:
		return
		
	var slipped_prize: RigidBody2D = held_prize
	
	release_held_prize(false)
	prize_Slipped.emit(slipped_prize)

func start_slip_timer() -> void:
	if slipTimer == null:
		return
		
	if held_prize == null:
		return
		
	slipTimer.wait_time = randf_range(
		minimum_slip_delay,
		maximum_slip_delay
	)
	
	slipTimer.start()
	
func _on_prize_chute_body_entered(body: Node2D) -> void:
	if not is_instance_valid(resolvingPrize):
		return
		
	if body != resolvingPrize:
		return
		
	finish_resolution()
	
func _on_quota_reached(
	_earned: int, _quota: int
) -> void:
	attemptsLocked = true
	
	if attempt_timer != null:
		attempt_timer.stop()
		
func _on_resolution_timer_timeout() -> void:
	finish_resolution()

func _on_level_started(_quota: int) -> void:
	attemptsLocked = false
	
	if(
		attempt_timer != null
	and current_State == State.IDLE
	):
		attempt_timer.start()
		
func _on_attempts_depleted() -> void:
	attemptsLocked = true
	
	if attempt_timer != null:
		attempt_timer.stop()
		
func _on_countdown_expired() -> void:
	start_dropping()
	
func _on_suit_equipped(suit: SuitData) -> void:
	apply_suit_modifiers(suit)
	
func apply_suit_modifiers(suit: SuitData) -> void:
	horizontal_speed = base_horizontal_speed
	maximum_drop_depth = base_maximum_drop_depth
	max_tilt_angle_degrees = base_max_tilt_angle_degrees
	max_second_chance_regrabs = 0
	blocks_cabinet_shake = false
	
	if grab_Area != null:
		grab_Area.scale = base_grab_area_scale
		
	if suit == null:
		return
		
	maximum_drop_depth += suit.drop_depth_bonus
	horizontal_speed *= suit.horizontal_speed_multiplier
	max_tilt_angle_degrees += suit.max_tilt_angle_bonus
	max_second_chance_regrabs = suit.second_chance_regrabs
	blocks_cabinet_shake = suit.blocks_cabinet_shake
	
	if grab_Area != null:
		grab_Area.scale = base_grab_area_scale * suit.grab_area_scale_multiplier
		
	print(
		"Applied suit: ",
		suit.displayName,
		" max drop: ",
		maximum_drop_depth,
		" horizontal speed: ",
		horizontal_speed
	)	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_claw"):
		start_dropping()

func is_protecte_from_cabinet_shake() -> bool:
	return blocks_cabinet_shake
	
func apply_cabinet_shake_offset(offset: Vector2) -> void:
	if blocks_cabinet_shake:
		return
		
	global_position += offset
