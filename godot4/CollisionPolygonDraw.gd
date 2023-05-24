@tool
extends CollisionPolygon2D
"""
Simple drawing for CollisionPolygon2D to make debugging
look a little nicer.
"""


@export var line_colour :Color = Color.BLACK :
	set(new):
		line_colour = new
		queue_redraw()

@export var fill_colour :Color = Color.LIGHT_SLATE_GRAY :
	set(new):
		fill_colour = new
		queue_redraw()

@export_range(0.1, 10.0, 0.1) var line_width := 2.0 :
	set(new):
		line_width = new
		queue_redraw()

@export var antialiased := false :
	set(new):
		antialiased = new
		queue_redraw()


func _draw():
	var poly := polygon as PackedVector2Array
	draw_polygon(poly, [fill_colour])
	var line := poly
	line.append(poly[0])
	draw_polyline(line, line_colour, line_width, antialiased)


