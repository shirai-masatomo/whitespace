extends Node
const Art = preload("res://game/adopted_art.gd")
const UI = preload("res://game/ui_style.gd")
const OPEN = preload("res://art_delivery/ranch_assets_v1/book/open_00.png")
const ROOT = "res://art_delivery/ranch_assets_v1/book/"
var sequences: Dictionary = {}
var quads: Dictionary = {}
var pages: Array = []
var inks: Array = []
var game
var state = "closed"

func setup(owner_game):
	game=owner_game
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://art_delivery/ranch_assets_v1/manifest.json"))
	quads=manifest.book.page_content_quads
	for key in ["opening","closing","turning_next","turning_previous"]:
		var prefix={"opening":"opening","closing":"closing","turning_next":"page_next","turning_previous":"page_previous"}[key]
		sequences[key]=[]
		for i in range(6): sequences[key].append(load(ROOT+prefix+"_%02d.png"%i))
	for i in range(2):
		var viewport=SubViewport.new()
		viewport.size=Vector2i(1024,640)
		viewport.transparent_bg=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var ink=Node2D.new()
		viewport.add_child(ink)
		ink.draw.connect(draw_content.bind(ink,i))
		pages.append(viewport)
		inks.append(ink)

func draw_content(canvas, index):
	game.draw_book_content(canvas,game.training_id if index==0 else game.book_next_id)

func _process(_delta):
	state=game.book_motion if game.book_motion!="" else ("open" if game.morning_screen=="book" else "closed")
	for ink in inks:
		if state!="closed": ink.queue_redraw()
	for page in pages: page.render_target_update_mode=SubViewport.UPDATE_DISABLED if state=="closed" else SubViewport.UPDATE_ALWAYS

func duration() -> float:
	return 0.42 if state.begins_with("turning") else 0.54

func region(canvas, texture, area: Rect2):
	if area.size.x>0: canvas.draw_texture_rect_region(texture,area,area)

func moving_content(canvas, texture, quad: Array, source: Rect2):
	var points=PackedVector2Array()
	for point in quad: points.append(Vector2(point[0],point[1]))
	var uv=PackedVector2Array([source.position,source.position+Vector2(source.size.x,0),source.end,source.position+Vector2(0,source.size.y)])
	for i in range(4): uv[i]/=Vector2(1024,640)
	canvas.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture)

func draw(canvas):
	var motion=game.book_motion
	var elapsed=game.clock-game.book_started
	var t=clampf(elapsed/(0.42 if motion.begins_with("turning") else 0.54),0,0.999)
	var index=mini(5,int(t*6))
	var origin=Vector2(128,100)
	var scale=1.0
	if motion in ["opening","closing"]:
		var opening=t if motion=="opening" else 1-t
		var travel=smoothstep(0,0.23,opening)
		scale=lerpf(0.387,1.0,travel)
		origin=(Vector2(748,235)-Vector2(504,36)*0.387).lerp(origin,travel)
		index=mini(5,int(clampf((opening-0.18)/0.82,0,0.999)*6))
		if motion=="closing": index=5-index
	canvas.draw_set_transform(origin,0,Vector2.ONE*scale)
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture(OPEN if motion=="" else sequences[motion][index],Vector2.ZERO)
	var current=pages[0].get_texture()
	var next=pages[1].get_texture()
	if motion=="": canvas.draw_texture(current,Vector2.ZERO)
	elif motion.begins_with("turning"):
		if index==0: canvas.draw_texture(current,Vector2.ZERO)
		elif index==5: canvas.draw_texture(next,Vector2.ZERO)
		else:
			var forward=motion=="turning_next"
			var quad=quads["next" if forward else "previous"][index]
			var left=float(quad[0][0]);var right=float(quad[1][0])
			if forward:
				region(canvas,current,Rect2(0,0,minf(left,512),640))
				region(canvas,next,Rect2(maxf(right,512),0,1024-maxf(right,512),640))
			else:
				region(canvas,next,Rect2(0,0,minf(left,512),640))
				region(canvas,current,Rect2(maxf(right,512),0,1024-maxf(right,512),640))
			var source_right=(forward and index<3) or (not forward and index>=3)
			moving_content(canvas,current if index<3 else next,quad,Rect2(512 if source_right else 92,52,420,484))
	elif (motion=="opening" and index==5) or (motion=="closing" and index==0):
		canvas.draw_texture(current,Vector2.ZERO)
	canvas.draw_set_transform(Vector2.ZERO)

