extends Control
## Reusable native UI ornament, independent of every background and character.
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	# PanelContainer already provides its fill and outer border. These small brass
	# corners remain decoration only: the controls above receive all real input.
	for point in [Vector2.ZERO,Vector2(size.x-8,0),Vector2(0,size.y-8),size-Vector2(8,8)]:
		draw_rect(Rect2(point,Vector2(8,8)),Color("231c17"))
		draw_rect(Rect2(point+Vector2(1,1),Vector2(6,6)),Color("8d6734"))
		draw_rect(Rect2(point+Vector2(2,2),Vector2(3,3)),Color("e5c57c"))
