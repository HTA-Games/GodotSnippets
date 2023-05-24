tool
extends CollisionPolygon2D
"""
Simple drawing for CollisionPolygon2D to make debugging
look a little nicer.
"""


export var line_colour :Color = Color.black setget _set_line_colour
export var fill_colour :Color = Color.slategray setget _set_fill_colour
export(float, 0.1, 10.0, 0.1) var line_width := 2.0 setget _set_line_width
export var antialiased := false setget _set_antialiased

func _draw():
	var poly := polygon as PoolVector2Array
	draw_polygon(poly, [fill_colour])
	var line := poly
	line.append(poly[0])
	draw_polyline(line, line_colour, line_width, antialiased)


func _set_line_colour(new):
	line_colour = new
	update()

func _set_fill_colour(new):
	fill_colour = new
	update()

func _set_line_width(new):
	line_width = new
	update()

func _set_antialiased(new):
	antialiased = new
	update()
