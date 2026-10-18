extends Control
## Read-only topology of the CURRENT implemented linear route.
## No invented branches, keys, content types or scouting ability.
var floor_number:=1
var highest_floor:=0
var expanded:=false
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func nodes() -> Array:
	var result: Array=[]
	var range_to_show: Array=range(1,12) if expanded else [floor_number-1,floor_number,floor_number+1]
	for number in range_to_show:
		if number<0 or number>11: continue
		result.append({"id":"floor-%d"%number,"label":"地上" if number==0 else "%d F"%number,"current":number==floor_number,"visited":number<floor_number,"type_revealed":false})
	return result
func positions() -> Array:
	var output: Array=[]; var list:=nodes()
	for i in list.size():
		if expanded: output.append(Vector2(70+(i%6 if i<6 else 11-i)*125,85+(i/6)*140))
		else: output.append(Vector2(38+i*76,38))
	return output
func _draw() -> void:
	var list:=nodes(); var points:=positions()
	for i in range(1,points.size()):
		draw_line(points[i-1],points[i],Color("668487") if list[i-1].visited else Color("344e56"),2)
	var font:=get_theme_default_font()
	for i in list.size():
		var point: Vector2=points[i]; var node: Dictionary=list[i]
		var color:=Color("f1cb79") if node.current else (Color("6dafa7") if node.visited else Color("344e56"))
		draw_rect(Rect2(point-Vector2(9,9),Vector2(18,18)),Color("101f26"))
		draw_rect(Rect2(point-Vector2(9,9),Vector2(18,18)),color,false,2)
		if node.current: draw_rect(Rect2(point-Vector2(4,4),Vector2(8,8)),color)
		draw_string(font,point+Vector2(-15,34),node.label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e6ddc4"))
