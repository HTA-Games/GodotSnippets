extends CharacterBody2D
class_name TopDownBody2D

"""
Top-down Player Controller.

If acceleration or deceleration are set to <= 0.0,
	it will be treated as instant

For use with Godot v4.x
"""

const LEFT_ACTION := "ui_left"
const RIGHT_ACTION := "ui_right"
const UP_ACTION := "ui_up"
const DOWN_ACTION := "ui_down"


@export var move_speed := 320.0
@export var acceleration := 3200.0
@export var deceleration := 3200.0


func _physics_process(delta: float) -> void:
	var throttle := Input.get_vector(LEFT_ACTION, RIGHT_ACTION, UP_ACTION, DOWN_ACTION)
	var motion := throttle * move_speed
	
	var accel := acceleration if motion else deceleration
	
	if accel > 0.0:
		var diff := motion - velocity
		velocity += diff.normalized() * min(accel * delta, diff.length())
	else:
		velocity = motion
	
	move_and_slide()
