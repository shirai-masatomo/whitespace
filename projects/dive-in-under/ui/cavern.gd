extends Control
## Original geometric placeholder scenery, not a cropped design mock.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color("071216"))
	for i in range(16):
		var x := s.x * (0.48 + 0.023 * i)
		draw_polygon(PackedVector2Array([Vector2(x,0),Vector2(x+28,0),Vector2(x-120,s.y),Vector2(x-190,s.y)]),
			PackedColorArray([Color(0.05,0.16,0.18,0.10)]))
	for i in range(9):
		var y := 65.0 + i * 79.0
		var left := 24.0 + (i % 3) * 27.0
		var right := s.x - 30.0 - (i % 4) * 37.0
		draw_line(Vector2(left,y), Vector2(s.x*0.28,y+40), Color("183035"), 5)
		draw_line(Vector2(right,y), Vector2(s.x*0.77,y+30), Color("173036"), 5)
		for x in [left+40.0, right-40.0]:
			draw_line(Vector2(x, y),Vector2(x-12,y+90),Color("1c2c2c"),8)
			draw_circle(Vector2(x,y-8),14,Color(0.8,0.45,0.18,0.035))
			draw_circle(Vector2(x,y-8),4,Color("b38449"))
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(s.x*0.28,0),Vector2(s.x*0.14,s.y*0.7),Vector2(s.x*0.25,s.y),Vector2(0,s.y)]),PackedColorArray([Color("081014")]))
	draw_polygon(PackedVector2Array([Vector2(s.x,0),Vector2(s.x*0.84,0),Vector2(s.x*0.91,s.y*0.6),Vector2(s.x*0.82,s.y),Vector2(s.x,s.y)]),PackedColorArray([Color("081014")]))
	for i in range(14):
		var y := s.y * 0.65 + i * i * 1.8
		draw_line(Vector2(s.x*0.46-i*7,y),Vector2(s.x*0.60+i*6,y),Color("294043"),2)
