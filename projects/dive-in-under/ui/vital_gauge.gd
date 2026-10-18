extends Control
## Lightweight native gauge: no prefilled picture, simulation or polling.
var value: float=0.0:
	set(v): value=v; queue_redraw()
var max_value: float=1.0:
	set(v): max_value=maxf(1.0,v); queue_redraw()
var tint:=Color("b9473b")
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("211d19"))
	var inner:=Rect2(Vector2(2,2),Vector2(maxf(0,size.x-4)*clampf(value/max_value,0,1),maxf(0,size.y-4)))
	if inner.size.x>0: draw_rect(inner,tint); draw_line(inner.position,Vector2(inner.end.x,inner.position.y),tint.lightened(0.35),1)
	draw_rect(Rect2(Vector2.ZERO,size),Color("806c42"),false,1)
