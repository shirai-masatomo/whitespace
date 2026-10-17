extends Control
## Independent static background; no UI reference image is loaded.
const VisualAssets = preload("res://ui/visual_assets.gd")
var scenery: TextureRect
var floor_number := 1

func set_depth(value: int) -> void:
	floor_number = value
	if scenery != null:
		scenery.texture = VisualAssets.texture(VisualAssets.background_key(value))
		scenery.modulate = VisualAssets.depth_tint(value)
	queue_redraw()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scenery = TextureRect.new()
	scenery.mouse_filter = MOUSE_FILTER_IGNORE
	scenery.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scenery)
	set_depth(floor_number)
	resized.connect(queue_redraw)

func tile(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(color))

func lantern(x: float, y: float) -> void:
	tile(x+2,y-12,1,12,"6b5938")
	tile(x-4,y-3,13,16,"1d2524")
	tile(x-2,y-2,9,13,"a86f33")
	tile(x,y,5,9,"f0b55b")
	tile(x+1,y+1,2,6,"ffe5a0")
	tile(x-3,y+11,11,2,"604b2c")

func _draw() -> void:
	if scenery != null and scenery.texture != null: return
	draw_set_transform(Vector2.ZERO,0,size / Vector2(320,180))
	tile(0,0,320,180,"07131d")
	var rng := RandomNumberGenerator.new()
	rng.seed = 170126
	for layer in range(3):
		for i in range(38):
			var x := rng.randi_range(0,310)
			var y := rng.randi_range(0,160)
			var color: String = ["102833","16333d","1c4149"][layer]
			tile(x,y,rng.randi_range(4,14),rng.randi_range(10,45),color)
	for x in range(118,201,4):
		var top := rng.randi_range(0,10)
		tile(x,top,3,160-top,["1b4550","246171","2a7480","3694a0"][rng.randi_range(0,3)])
		for i in range(5):
			tile(x,rng.randi_range(20,160),1,rng.randi_range(2,9),"64adb0")
	for i in range(28):
		var x := i * 12
		var depth := rng.randi_range(8,40)
		tile(x,0,12,depth,"0b1d27")
		tile(x+3,depth,6,8,"0b1d27")
		tile(x+5,depth+8,2,5,"0b1d27")
	for y in [61,113]:
		for x in range(20,301,8):
			tile(x,y,7,3,"594b37")
			tile(x,y,7,1,"8e7850")
			if x % 24 == 20:
				tile(x,y-10,2,16,"302e27")
			tile(x,y-7,8,1,"5b5c43")
	for x in range(0,320,12):
		var height := rng.randi_range(12,25)
		tile(x,180-height,12,height,"101e25")
		tile(x,180-height,12,2,"445349")
		tile(x+2,184-height,8,3,"233b3f")
	for point in [Vector2(29,51),Vector2(284,51),Vector2(62,103),Vector2(256,103)]:
		lantern(point.x,point.y)
