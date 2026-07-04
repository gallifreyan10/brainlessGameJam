extends CharacterBody2D
@export_category("Movement")
@export var horizontal_speed:float = 100
@export var drop_speed: float = 120
@export var return_speed: float = 150
@export var maximum_drop_depth: float = 290


@export_category("Timing")
@export var grabbing_duration: float = 0.75

@export_category("References")
#Timer that gets triggered when player takes too long and drops claw
@export var attempt_timer: Timer

@export_category("Animations")
@export var animation_player: AnimationPlayer
signal claw_closed(claw: CharacterBody2D)

var close_request_locked: bool = false

#Downwards cast checking for bottom of cabinet
@export var bottom_detector: RayCast2D

#Visually connects cable
@export var cable:Line2D

@export var current_State: State = State.IDLE

@export var starting_y:float = 0




signal position_changed(new_position: Vector2)
signal state_changed(new_state: State)

enum State{IDLE,DROPPING,GRABBING,RETURNING}

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
	updateCable()
	
	

func process_idle() -> void:
	#Player Control is only available when claw is idle
	var direction := Input.get_axis("move_left","move_right")

	velocity = Vector2(direction * horizontal_speed,0.0)
	move_and_slide()
	
	var dropPressed = Input.is_action_just_pressed("drop_claw")
	
	if dropPressed == true:
		start_dropping()
		
func start_dropping() -> void:
	#Prevent repeated input or timer signals from restarting an already triggered drop
	if current_State != State.IDLE:
		return
		
	if attempt_timer != null:
		attempt_timer.stop()
		
	change_state(State.DROPPING)
	
func process_dropping() -> void:
	#Player controls are locked during drop
	velocity.x = 0
	velocity.y = drop_speed
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
		change_state(State.IDLE)
		animation_player.play(&"RESET")
		close_request_locked=false
		
		if(attempt_timer != null):
			attempt_timer.start()
			
	
	
func updateCable() -> void:
	if cable == null or cable.get_point_count() < 2:
		return
		#The first Line2D point remains attached to the cabinet
		#the second point follows the claw in the cable's local coordinates
		cable.set_point_position(1,cable.to_local(global_position))
		
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
	change_state(State.GRABBING)
	animation_player.play(&"close_claw")	
	
func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"close_claw":
		return
	if current_State != State.GRABBING:
		return
		
	claw_closed.emit(self)
	change_state(State.RETURNING)
func _ready() -> void:
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
