extends Camera
class_name SignaledCamera
"""
Emits signals when the camera becomes the viewport's main camera.

For use in Godot v3.x
"""

signal became_current
signal lost_current

func _notification(what: int) -> void:
	if what == 50:
		emit_signal("became_current")
	elif what == 51:
		emit_signal("lost_current")
