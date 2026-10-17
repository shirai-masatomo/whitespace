extends Control
## Reusable native UI ornament, independent of every background and character.
var parchment := false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	# Fixed, low-contrast fibers: no RNG, processing, texture assets or input.
	if parchment:
		for y in range(5,int(size.y)-4,7):
			for x in range(7,int(size.x)-7,19):
				var offset := (x*3+y*7)%9
				draw_rect(Rect2(x+offset,y,3+(x+y)%5,1),Color(0.34,0.22,0.10,0.045))
		for inset in [1,3]:
			draw_rect(Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2),Color(0.30,0.19,0.08,0.14),false,1)
	# Recessed brass rim; content remains independent and draws above this node.
	# Keep the rim in the panel's 14px padding, outside all labels and buttons.
	var origin := Vector2(-8,-8)
	var extent := size+Vector2(16,16)
	draw_line(origin+Vector2(8,0),origin+Vector2(extent.x-8,0),Color("e0bc75"),1)
	draw_line(origin+Vector2(0,8),origin+Vector2(0,extent.y-8),Color("cfaa63"),1)
	draw_line(origin+Vector2(8,extent.y-1),origin+Vector2(extent.x-8,extent.y-1),Color("654b2b"),2)
	draw_line(origin+Vector2(extent.x-1,8),origin+Vector2(extent.x-1,extent.y-8),Color("654b2b"),2)
	for offset in [Vector2.ZERO,Vector2(extent.x-8,0),Vector2(0,extent.y-8),extent-Vector2(8,8)]:
		var point: Vector2 = origin+offset
		draw_rect(Rect2(point,Vector2(8,8)),Color("231c17"))
		draw_rect(Rect2(point+Vector2(1,1),Vector2(6,6)),Color("8d6734"))
		draw_rect(Rect2(point+Vector2(2,2),Vector2(3,3)),Color("e5c57c"))
