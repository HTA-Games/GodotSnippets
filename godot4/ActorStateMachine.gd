extends Node
class_name ActorStateMachine

"""
State Machine controller. Use in tandem with ActorState.gd

In your _process or _physics_process method of your actor object,
call $StateMachine.step(delta)

For use with Godot v4.x
"""

@export var actor_path := ^".."
var active_state :ActorState


func _ready():
	for child in get_children():
		if child is ActorState:
			active_state = child
			break
	active_state.enter_state()


func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is ActorState:
			return [""]
	return ["ActorStateMachine must have at least one ActorState as a child"]


func step(delta :float) -> void:
	active_state.step(delta)


func transition_to(target :String, _depth := 0) -> void:
	var next_state :ActorState = get_node_or_null(target)
	active_state.exit_state()
	if next_state:
		active_state = next_state
	else:
		active_state = get_child(0)
	active_state.enter_state()


func get_actor():
	return get_node_or_null(actor_path)
