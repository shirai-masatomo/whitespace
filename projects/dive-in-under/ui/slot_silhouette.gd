extends Control
var slot: String="head"
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var paths: Dictionary={
	"head":[[Vector2(7,22),Vector2(8,11),Vector2(16,5),Vector2(24,11),Vector2(25,22),Vector2(7,22)],[Vector2(8,23),Vector2(24,23)]],
	"body":[[Vector2(5,10),Vector2(11,6),Vector2(16,10),Vector2(21,6),Vector2(27,10),Vector2(24,17),Vector2(21,15),Vector2(21,27),Vector2(11,27),Vector2(11,15),Vector2(8,17),Vector2(5,10)]],
	"legs":[[Vector2(9,5),Vector2(23,5),Vector2(24,27),Vector2(18,27),Vector2(16,14),Vector2(14,27),Vector2(8,27),Vector2(9,5)]],
	"feet":[[Vector2(8,6),Vector2(17,6),Vector2(17,20),Vector2(25,23),Vector2(25,27),Vector2(6,27),Vector2(8,6)]],
	"right_hand":[[Vector2(7,26),Vector2(24,6),Vector2(27,4),Vector2(27,10),Vector2(10,29)],[Vector2(5,19),Vector2(15,27)]],
	"left_hand":[[Vector2(6,7),Vector2(16,4),Vector2(26,7),Vector2(24,20),Vector2(16,28),Vector2(8,20),Vector2(6,7)]],
	"neck":[[Vector2(6,6),Vector2(9,17),Vector2(16,23),Vector2(23,17),Vector2(26,6)],[Vector2(16,21),Vector2(20,26),Vector2(16,30),Vector2(12,26),Vector2(16,21)]],
	"ears":[[Vector2(8,6),Vector2(5,11),Vector2(8,16),Vector2(11,11),Vector2(8,6)],[Vector2(23,6),Vector2(20,11),Vector2(23,16),Vector2(26,11),Vector2(23,6)],[Vector2(8,16),Vector2(8,25)],[Vector2(23,16),Vector2(23,25)]],
	"eyes":[[Vector2(3,16),Vector2(9,11),Vector2(23,11),Vector2(29,16),Vector2(23,21),Vector2(9,21),Vector2(3,16)]],
	"finger":[[Vector2(10,6),Vector2(22,6),Vector2(27,16),Vector2(22,26),Vector2(10,26),Vector2(5,16),Vector2(10,6)]],
	"wrist":[[Vector2(5,10),Vector2(23,5),Vector2(27,22),Vector2(9,27),Vector2(5,10)],[Vector2(10,10),Vector2(14,26)]]}
	for path in paths.get(slot,[]):
		var points:=PackedVector2Array()
		for point in path: points.append(point*size/32.0)
		draw_polyline(points,Color(0.46,0.57,0.60,0.48),2.0,false)
	if slot=="eyes": draw_circle(size*0.5,size.x*0.08,Color(0.46,0.57,0.60,0.48))
