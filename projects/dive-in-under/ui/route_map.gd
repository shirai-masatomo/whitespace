extends Control
## Vertical, read-only topology. Node CONTENTS remain undisclosed.
signal opened
var floor_number:=1
var highest_floor:=0
var expanded:=false
var max_floor:=10
var descent_y: float=-1.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_PASS
	custom_minimum_size=Vector2(200,44*max_floor+28)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		accept_event(); opened.emit()
func nodes() -> Array:
	var result: Array=[]
	for number in range(1,max_floor+1):
		result.append({"id":"floor-%d"%number,"label":"%d F"%number,"current":number==floor_number,"visited":number<=highest_floor and number!=floor_number,"type_revealed":false})
	return result
func positions() -> Array:
	var output: Array=[]
	for i in nodes().size(): output.append(Vector2(50,25+i*44))
	return output
func _draw() -> void:
	var list:=nodes(); var points:=positions(); var font:=get_theme_default_font()
	for i in range(1,points.size()): draw_line(points[i-1],points[i],Color("668487") if list[i-1].visited or list[i-1].current else Color("344e56"),2)
	for i in list.size():
		var p: Vector2=points[i]; var n: Dictionary=list[i]
		var color: Color=(Color("714d1b") if n.current else (Color("22655f") if n.visited else Color("5c6461"))) if expanded else (Color("f1cb79") if n.current else (Color("6dafa7") if n.visited else Color("344e56")))
		draw_rect(Rect2(p-Vector2.ONE*8,Vector2.ONE*16),Color("e8d5a4") if expanded else Color("101f26")); draw_rect(Rect2(p-Vector2.ONE*8,Vector2.ONE*16),color,false,2)
		if n.current: draw_rect(Rect2(Vector2(p.x,descent_y if descent_y>=0 else p.y)-Vector2.ONE*3,Vector2.ONE*6),color)
		draw_string(font,p+Vector2(24,6),n.label+("  現在地" if n.current else ("  到達済" if n.visited else "  未到達")),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("30291e") if expanded else Color("e6ddc4"))
func visual_audit() -> Dictionary:
	return {"orientation":"vertical","nodes":nodes(),"positions":positions().map(func(p):return [p.x,p.y])}

func animate_descent(previous: int) -> void:
	descent_y=25+maxi(0,previous-1)*44
	var motion:=create_tween();motion.tween_method(func(v):descent_y=v;queue_redraw(),descent_y,float(25+(floor_number-1)*44),.18);motion.tween_callback(func():descent_y=-1;queue_redraw())
