extends CharacterBody3D


@export var speed: float
@export var accel_time: float
@export var jump_speed: float
@export var mouse_sensitivity: float
@export var coyote_time_ms: int
@export var fov: float
@export var sprint_fov: float

@onready var cam = $cam


var game_state: GameState

var state: int = 0
var last_state: int = 0

var last_time_on_floor_ms = 0
var wall_ride_cooldown = 0
var prev_wall_dir: Vector3
var wall_dir: Vector3


func _ready() -> void:
	cam.fov = fov


func _physics_process(delta: float) -> void:
	if game_state.in_menu: return
	
	var time_ms = Time.get_ticks_msec()
	
	update_walls()
	if time_ms < wall_ride_cooldown and wall_dir.distance_squared_to(prev_wall_dir) < .01:
		set_wall_riding(false)
	else:
		wall_ride_cooldown = 0
	
	if not was_wall_riding() and is_wall_riding():
		velocity.y = max(0, velocity.y)
	
	# Add the gravity.
	if is_on_floor() or is_wall_riding():
		set_jumping(false)
	
	if not is_on_floor():
		var gravity = get_gravity()
		if is_wall_riding():
			var g = .15*exp(-velocity.length()) if velocity.y < 0 else 1.
			velocity += gravity*g*delta
		else:
			velocity += gravity * delta
		if was_on_floor:
			last_time_on_floor_ms = time_ms

	var in_coyote_time = time_ms - last_time_on_floor_ms < coyote_time_ms
	# Handle jump.
	var can_jump = is_on_floor() or in_coyote_time or is_wall_riding()
	if not is_jumping() and Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = jump_speed
		set_jumping()
		if is_wall_riding() and not is_on_floor():
			velocity += -wall_dir*15
			wall_ride_cooldown = time_ms + 800

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_sprinting():
		cam.fov = move_toward(cam.fov, sprint_fov * (1. if is_wall_riding() else 1.), 4)
		if not direction:
			set_sprinting(false)
	else:
		cam.fov = move_toward(cam.fov, fov, 4)
		if Input.is_action_pressed("sprint") and direction:
			set_sprinting()
	
	var top_speed = speed * if_sprinting(2, 1) * if_wall_riding(1.5, 1.)
	var accel_multiplier = if_sprinting(2, 1) * if_on_floor(1., 0.3)
	var accel = speed*delta/accel_time * accel_multiplier
	var target_vel = top_speed * direction
	
	var vy = velocity.y
	velocity.y = 0
	var vdelta = target_vel - velocity
	vdelta = vdelta.normalized()*minf(accel, vdelta.length())
	velocity += vdelta
	velocity.y = vy
	
	if is_wall_riding() and not is_on_floor():
		velocity += wall_dir*.5
	
	last_state = state
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or game_state.in_menu: return
		
	if Input.is_action_just_pressed("toggle_debug"):
		$env_detector.toggle_debug_enabled()
	
	if event is InputEventMouseMotion:
		rotation.y = wrapf(rotation.y - event.relative.x*mouse_sensitivity, -PI, PI)
		cam.rotation.x = clamp(cam.rotation.x - event.relative.y*mouse_sensitivity, -PI/2, PI/2)


func _on_death_plane_entered(_body: Node3D) -> void:
	get_tree().call_deferred("reload_current_scene")


func update_walls() -> void:
	wall_dir = $env_detector.find_wall_dir()
	#print(wall_dir)
	set_wall_riding(wall_dir != Vector3.ZERO)


@warning_ignore_start("shadowed_variable")
func set_sprinting(state: bool = true) -> void:
	if state: set_state(CharState.SPRINTING)
	else: unset_state(CharState.SPRINTING)
func set_wall_riding(state: bool = true) -> void:
	if state: set_state(CharState.WALL_RIDING)
	else: unset_state(CharState.WALL_RIDING)
func set_jumping(state: bool = true) -> void:
	if state: set_state(CharState.JUMPING)
	else: unset_state(CharState.JUMPING)
func set_bjumping(state: bool = true) -> void:
	if state: set_state(CharState.BOUNCE_JUMPING)
	else: unset_state(CharState.BOUNCE_JUMPING)
func is_sprinting(): return is_state(CharState.SPRINTING)
func is_wall_riding(): return is_state(CharState.WALL_RIDING)
func is_jumping(): return is_state(CharState.JUMPING)
func is_bjumping(): return is_state(CharState.BOUNCE_JUMPING)
func was_on_floor(): return was_state(CharState.ON_FLOOR)
func was_sprinting(): return was_state(CharState.SPRINTING)
func was_wall_riding(): return was_state(CharState.WALL_RIDING)
func was_jumping(): return was_state(CharState.JUMPING)
func was_bjumping(): return was_state(CharState.BOUNCE_JUMPING)
func if_on_floor(if_true: Variant, if_false: Variant):
	return if_true if is_on_floor() else if_false
func if_sprinting(if_true: Variant, if_false: Variant):
	return if_true if is_sprinting() else if_false
func if_wall_riding(if_true: Variant, if_false: Variant):
	return if_true if is_wall_riding() else if_false
func if_jumping(if_true: Variant, if_false: Variant):
	return if_true if is_jumping() else if_false
func if_bjumping(if_true: Variant, if_false: Variant):
	return if_true if is_bjumping() else if_false
func if_was_on_floor(if_true: Variant, if_false: Variant):
	return if_true if was_on_floor() else if_false
func if_was_sprinting(if_true: Variant, if_false: Variant):
	return if_true if was_sprinting() else if_false
func if_was_wall_riding(if_true: Variant, if_false: Variant):
	return if_true if was_wall_riding() else if_false
func if_was_jumping(if_true: Variant, if_false: Variant):
	return if_true if was_jumping() else if_false
func if_was_bjumping(if_true: Variant, if_false: Variant):
	return if_true if was_bjumping() else if_false

func is_state(statemask: int) -> bool:
	return state & statemask != 0
func set_state(statemask: int) -> void:
	state = state | statemask
func unset_state(statemask: int) -> void:
	state = state & (~statemask)
func clear_state() -> void:
	state = 0
func was_state(statemask: int) -> bool:
	return last_state & statemask != 0
@warning_ignore_restore("shadowed_variable")


enum CharState {
	ON_FLOOR = 1<<0,
	SPRINTING = 1<<1,
	WALL_RIDING = 1<<2,
	JUMPING = 1<<3,
	BOUNCE_JUMPING = 1<<4,
}
