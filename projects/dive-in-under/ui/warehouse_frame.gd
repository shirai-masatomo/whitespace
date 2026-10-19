extends Control
const Art=preload("res://ui/interface_art.gd")
## Independent, integer-aligned UI ornament. Text and controls stay engine-rendered.
var ornament_only := false
var cloth := false
var heading_line:=true
var prominent := false
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var r:=Rect2(Vector2.ZERO,size)
	if not ornament_only: draw_rect(r,Color("17110d"))
	draw_rect(r.grow(-2),Color("8b662f"),false,2)
	if not ornament_only: draw_rect(r.grow(-5),Color("30283c") if cloth else Color("09191e"))
	draw_rect(r.grow(-7),Color("b08a47") if prominent else Color("625339"),false,1)
	Art.frame(self,r)
	if not ornament_only and heading_line: draw_line(Vector2(18,45),Vector2(size.x-18,45),Color("95723b"),1)
	if cloth:
		for x in range(22,int(size.x)-22,12):
			draw_line(Vector2(x,size.y-11),Vector2(x+4,size.y-15),Color("66517d"))
	else:
		for x in range(25,int(size.x)-25,48):
			draw_rect(Rect2(x,12,22,1),Color("163039"))
