# Godot Snippets

This repository is a loose collection of scripts, templates,
and behaviours from various random projects. It is meant to
act as a library of scripts that I'm rewriting constantly.
Code may be tweaked to simplify them from my projects to make
them more applicable in general.

It will not be updated regularly.

# Script List

### ActorStateMachine and ActorState
	- Provides an implementation of a state machine for actor behaviours.
	- States also act as sub-state machines, allowing nesting.
	- Intended for use with an Actor such as a player or NPC. The actor
	object it is attached to can be retrieved from any state or substate.


### CollisionPolygonDraw
	- Traces the CollisionPolygon using a line and a fill colour for easy debugging


### PlatformerPlayer2D
	- An implementation of a Platformer Player controller
	- Includes air momentum, acceleration, coyote time, hold-to-extend jumps,
	multiple air jumps, wall sliding with friction, wall jumping, platform diving


### SignaledCamera
	- Adds signals for "became_current" and "lost_current" to 3D Cameras


### TopDownPlayer2D
	- A simple implmention of a Top-Down Player controller
	- Includes linear acceleration and correctly handles diagonals
