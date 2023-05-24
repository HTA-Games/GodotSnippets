extends Node
class_name ActorState

"""
State Machine State. Use in tandem with ActorStateMachine.gd

Extend this script and override any/all of the following methods:
	_enter_state
	_exit_state
	_step(delta)


Methods:
	_step(delta)
		Called every step that the state is active
		
	_enter_state()
		Called when the state becomes active.
		If the state has substates, the first substate
		will also be entered after the parent
		
	_exit_state()
		Called when the state becomes inactive.
		If the state has substates, the active substate
		will be exited before the parent
	
	cancel()
		When called from _step, disables processing of substates
		for the current step iteration.
	
	transition_to(state_name, depth = 1)
		Causes the state machine to transition to another state.
		If depth < 0, the base state machine will transition states.
		If depth == 0, the current state's substate will be changed
		If depth > 0, a more parent state will transition substates.
	
	get_actor()
		Returns the actor object from the state machine, no matter
		how many layers of substates there are.

For use with Godot v3.x
"""


onready var _actor = get_actor()
var active_substate = null
var _canceled := false


# * Overrideables * #

func _enter_state() -> void:
	pass


func _exit_state() -> void:
	pass


func _step(_delta :float) -> void:
	pass



# * Internals * #

func step(delta :float) -> void:
	_canceled = false
	_step(delta)
	if active_substate and !_canceled:
		active_substate.step(delta)


func cancel() -> void:
	_canceled = true


func transition_to(target :String, depth=1) -> void:
	if depth == 0:
		set_substate(target)
	else:
		get_parent().transition_to(target, depth-1)


func set_substate(substate :String) -> void:
	if active_substate:
		active_substate.exit_substate()
	active_substate = get_node(substate)
	if active_substate:
		active_substate.enter_substate()


func get_actor():
	if _actor == null:
		_actor = get_parent().get_actor()
	return _actor


func enter_state() -> void:
	if get_child_count() > 0:
		active_substate = get_child(0)
	_enter_state()
	if active_substate:
		active_substate.enter_state()


func exit_state() -> void:
	if active_substate:
		active_substate.exit_state()
		active_substate = null
	_exit_state()
