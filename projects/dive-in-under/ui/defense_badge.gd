extends Control
## Presentation only: no combat RNG, movement, damage or save mutation.
var flash := false
var intensity := 0.35
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	z_index=900
	custom_minimum_size=Vector2(44,52)
	if flash:
		intensity=1.0
		create_tween().tween_method(func(value: float): intensity=value; queue_redraw(),1.0,0.35,0.4)
func _draw() -> void:
	var shield:=PackedVector2Array([Vector2(4,4),Vector2(40,4),Vector2(37,32),Vector2(22,48),Vector2(7,32)])
	draw_colored_polygon(shield,Color(0.06,0.38,0.72,0.45+intensity*0.4))
	var outline:=shield.duplicate(); outline.append(shield[0])
	draw_polyline(outline,Color(0.55,0.88,1.0),2.0)
	draw_line(Vector2(22,10),Vector2(22,35),Color(0.8,0.96,1.0),3)
	draw_line(Vector2(13,20),Vector2(31,20),Color(0.8,0.96,1.0),3)
func visual_audit() -> Dictionary:
	return {"effect":"S105-defense","static_character":true,"duration_seconds":0.4,"flash":flash,"intensity":intensity,"global_rect":str(get_global_rect()),"combat_rng_used":false}
