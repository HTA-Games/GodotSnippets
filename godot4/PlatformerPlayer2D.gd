extends CharacterBody2D
class_name PlatformerPlayer2D
"""
A 2D platformer controller with:
- Separated ground and air motion
- Momentum and acceleration/deceleration
- Coyote time
- Hold-to-extend-jumps
- Air Jumping,
- Wall Clinging
- Wall Jumping
- Cloud Platform Diving

This script assumes gravity points DOWN.


coyote_time - The time after the player falls off a platformer
	in which a jump input is still considered as "from the ground"
	
jump_buffer - If the JUMP action is pressed just before touching
	the ground, it will be treated as if the player pressed the button
	on the same frame as they touched the ground.

cloud_layers - physics layers can be set as "clouds" (aka 'diveable platforms')
	When the player is holding the DIVE action, their collision mask for any
	cloud layers will be disabled, allowing them to pass through.
	
	As an example setup:
		Set the player's collision layer to only 3
		Set the player's collision mask to only layer 1
		Set the player's cloud layers to only layer 2
		
		Set solid walls to be on collision layer 1
		Disable the mask for solid walls
		
		Set cloud platforms to be on collision layer 2
		Disable the mask for cloud platforms.
		Use segment shapes for the collision shape and set
			them as having "One Way Collision"

speed/acceleration/deceleration/turn_rate -
	In general, the player's speed will accelerate up to the target speed
		using the acceleration
	If they are throttling in the opposite direction, they will accelerate
		using the turn_accel instead.
	If they are not throttling at all, the will decelerate using 
		the deceleration value.
	Momentum will be conserved.
	If any of these accelerations is set to < 0.0, it will be treated as
		instant acceleration


air jumps - Each element of the air jump array determines how much vertical
	velocity to set to. If infinite_jump is enabled, the last available
	jump speed is used.


For use with Godot v4.x
"""

# Script config
const LEFT_ACTION := "ui_left"
const RIGHT_ACTION := "ui_right"
const JUMP_ACTION := "ui_up"
const DIVE_ACTION := "ui_down"


# Configurations
@export_group("Ground Behaviour", "ground_")
@export var ground_speed := 400.0
@export var ground_acceleration := 8000.0
@export var ground_turn_accel := 8000.0
@export var ground_deceleration := 8000.0

@export_group("Air Behaviour", "air_")
@export var air_speed := 300.0
@export var air_acceleration := 1500.0
@export var air_turn_accel := 8000.0
@export var air_deceleration := 0.0


@export_group("Jump Behaviour", "jump_")
@export var jump_ground_speed := 500
@export var jump_air_speed :Array[int] = [400]
@export var jump_infinite_jumps := false

@export var jump_max_time := 0.1
@export var jump_short_stop_scalar := 0.65

@export_range(0.0, 1.0, 0.05) var jump_max_coyote_time := 0.1
@export_range(0.0, 1.0, 0.05) var jump_input_buffer_time := 0.2

@export_group("Wall Behaviour", "wall_")
@export var wall_slide_friction := 0.85
@export var wall_jump_speed := Vector2(300, 400)
@export var wall_max_coyote_time := 0.2

@export_group("Physics")
@export var gravity_scale := 1.0
@export_flags_2d_physics var cloud_layers := 2


# Script Behaviours
var coyote_time := 0.0
var jump_buffer := 0.0
var air_jumps := 0

var jump_timer := 0.0
var jump_speed :float

var wall_coyote_time := 0.0
var wall_normal := Vector2()
var wall_normal_direction := 0


# Script constants
@onready var GRAVITY :float = ProjectSettings["physics/2d/default_gravity"]

func _physics_process(delta :float):
	# Common Inputs
	var throttle := Input.get_axis(LEFT_ACTION, RIGHT_ACTION)
	var tap_dir := int(Input.is_action_just_pressed(RIGHT_ACTION)) - int(Input.is_action_just_pressed(LEFT_ACTION))
	
	# Update internal state
	if is_on_floor():
		coyote_time = jump_max_coyote_time
		wall_coyote_time = 0.0
		air_jumps = jump_air_speed.size()
	else:
		coyote_time -= delta
		velocity.y += gravity_scale * GRAVITY * delta
	
	
	# Cloud Diving
	if Input.is_action_pressed(DIVE_ACTION):
		collision_mask = collision_mask & ~cloud_layers
	else:
		collision_mask = collision_mask | cloud_layers
	
	
	var speed :float
	var accel :float
	var decel :float
	var turn_acc :float
	
	# -- Determine which motion to use
	if is_on_floor():
		speed = ground_speed
		accel = ground_acceleration
		decel = ground_deceleration
		turn_acc = ground_turn_accel
	else:
		speed = air_speed
		accel = air_acceleration
		decel = air_deceleration
		turn_acc = air_turn_accel
	
	var thdir := int(sign(throttle))
	var hdir := int(sign(velocity.x))
	
	# -- Determine which accel to use
	var acc :float
	if thdir == 0 or thdir == hdir and abs(velocity.x) > speed:
		acc = decel
	elif thdir == -hdir:
		acc = turn_acc
	else:
		acc = accel
	
	# -- Apply throttle
	if acc >= 0.0:
		velocity.x = move_toward(velocity.x, speed * thdir, acc * delta)
	else:
		velocity.x = speed * thdir
	
	
	# Handle Jump
	if Input.is_action_just_pressed(JUMP_ACTION):
		jump_buffer = jump_input_buffer_time
	
	if jump_buffer > 0.0:
		jump_buffer -= delta
		
		# -- Ground Jump
		if coyote_time > 0.0:
			jump(jump_ground_speed)
			coyote_time = 0.0
		
		# -- Air Jump
		elif air_jumps > 0:
			jump(jump_air_speed[-air_jumps])
			air_jumps -= 1
		
		# -- Infinite Jump
		elif jump_infinite_jumps:
			jump(jump_air_speed[-1] if jump_air_speed else jump_ground_speed)
	
	
	# Wall sliding
	if is_on_wall() and not is_on_floor():
		for idx in get_slide_collision_count():
			var col := get_slide_collision(idx)
			var mx := 0.0
			var n := col.get_normal()
			if absf(n.x) > mx:
				mx = absf(n.x)
				wall_normal = n
				wall_normal_direction = int(sign(n.x))
		
		# -- Throttling towards wall
		if thdir == -wall_normal_direction:
			wall_coyote_time = wall_max_coyote_time
			if velocity.y > 0.0:
				velocity.y *= wall_slide_friction
	
	
	# Wall Jumping
	if wall_coyote_time > 0.0:
		wall_coyote_time -= delta
		
		# -- Tapping away from wall
		if tap_dir == wall_normal_direction:
			jump_timer = 0.0
			velocity = wall_normal * wall_jump_speed.x + Vector2.UP * wall_jump_speed.y
			wall_coyote_time = 0.0
	
	
	# Process jump
	if jump_timer > 0.0:
		if Input.is_action_just_released(JUMP_ACTION):
			velocity.y *= jump_short_stop_scalar
			jump_timer = 0.0
		else:
			velocity.y = -jump_speed
			jump_timer -= delta
	
	
	# Apply Physics
	move_and_slide()



func jump(speed :float):
	jump_buffer = 0.0
	jump_timer = jump_max_time
	jump_speed = speed
