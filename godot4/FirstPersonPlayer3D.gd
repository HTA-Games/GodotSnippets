extends CharacterBody3D
class_name FirstPersonPlayer3D

"""
First-person 3D Player Controller, including Camera controls.

Camera controls scales mouse motion to handle multiple resolutions.

If acceleration or deceleration are set to <= 0.0,
	it will be treated as instant

For use with Godot v4.x
"""

# Script Config

const FORWARD_ACTION := "ui_up"
const BACKWARD_ACTION := "ui_down"
const LEFT_ACTION := "ui_left"
const RIGHT_ACTION := "ui_right"
const JUMP_ACTION := "ui_accept"

const MIN_CAMERA_ANGLE := deg_to_rad(-85.0)
const MAX_CAMERA_ANGLE := deg_to_rad(85.0)


# Exports

@export var camera_path := ^"Camera3D"
@export var mouse_sensitivity := Vector2(1.0, 1.0)
@export var jump_speed := 5.0
@export var gravity_scale := 1.0

@export_group("Ground Physics", "ground_")
@export var ground_speed := 5.5
@export var ground_acceleration := -1.0
@export var ground_deceleration := 55.0

@export_group("Air Physics", "air_")
@export var air_acceleration := 22.0
@export var air_deceleration := 0.0


# Internals

var gravity :float = ProjectSettings["physics/3d/default_gravity"]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Convert FOV to pixels
		var res := get_viewport().size as Vector2
		var mscale :float = deg_to_rad(get_node(camera_path).fov) / -res.y
		
		# Apply camera motion
		var amt :Vector2 = mscale * mouse_sensitivity
		
		rotate_y(amt.x * event.relative.x / res.aspect())
		get_node(camera_path).rotation.x = clamp(get_node(camera_path).rotation.x + amt.y * event.relative.y, MIN_CAMERA_ANGLE, MAX_CAMERA_ANGLE)
	
	# DEBUGGING - Capture mouse if clicked in the window
	elif event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



func _physics_process(delta :float) -> void:
	var throttle := Input.get_vector(LEFT_ACTION, RIGHT_ACTION, FORWARD_ACTION, BACKWARD_ACTION)
	var motion := transform.basis * Vector3(throttle.x, 0.0, throttle.y) * ground_speed
	var accel :float
	
	
	# Gravity
	velocity.y -= gravity_scale * gravity * delta
	
	
	# Throttle
	if is_on_floor():
		accel = ground_acceleration if motion else ground_deceleration
	else:
		accel = air_acceleration if motion else air_deceleration
	
	
	if accel < 0.0:
		velocity.x = motion.x
		velocity.z = motion.z
	else:
		var diff := motion - velocity
		diff.y = 0.0
		velocity += diff.normalized() * min(accel * delta, diff.length())
	
	
	# Handle jump
	if Input.is_action_just_pressed(JUMP_ACTION) and is_on_floor():
		velocity.y = jump_speed
	
	
	move_and_slide()
