extends Camera3D
class_name SignaledCamera3D
"""
Emits signals when the camera becomes the viewport's main camera.

For use in Godot v4.x
"""

signal became_current
signal lost_current

func _notification(what):
	if what == 50:
		became_current.emit()
	elif what == 51:
		lost_current.emit()
