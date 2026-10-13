extends Node2D
## Retain native CanvasItem commands. Camera movement never rebuilds ground.
const SIZE=8
const TILE=Vector2(48,42)
const Board=preload("res://game/board_art.gd")
const Rock=preload("res://game/rock_view.gd")
var world
var chunks={}
var stamps={}
class Chunk extends Node2D:
	var world
	var box:Rect2i
	const TILE=Vector2(48,42)
	func center(p):return (Vector2(p)+Vector2(0.5,0.5))*TILE
	func _draw():
		Board.draw_region(self,world,TILE,box)
		Rock.ground(self,Rect2(Vector2(box.position)*TILE,Vector2(box.size)*TILE))
func _ready():
	show_behind_parent=true
	sync()
func _process(_delta):sync()
func sync():
	var w=get_parent().world
	if world!=w:
		world=w
		for child in get_children():child.queue_free()
		chunks.clear();stamps.clear()
		for y in range(ceili(w.H/float(SIZE))):
			for x in range(ceili(w.W/float(SIZE))):
				var cell=Vector2i(x,y);var node=Chunk.new();node.world=w;node.box=Rect2i(cell*SIZE,Vector2i(mini(SIZE,w.W-x*SIZE),mini(SIZE,w.H-y*SIZE)));node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;add_child(node);chunks[cell]=node
		queue_redraw()
	var next={}
	for key in chunks:next[key]=[]
	for index in range(5):
		var positions=[w.floors.keys(),w.structures.keys(),w.rocks.keys(),w.natural.keys(),w.mined_rock_cells][index]
		for p in positions:
			var key=Vector2i(floori(float(p.x)/SIZE),floori(float(p.y)/SIZE))
			if next.has(key):next[key].append([index,p,w.live_structure(p) if index==1 else true])
	var visible=get_canvas_transform().affine_inverse()*get_viewport_rect()
	for key in chunks:
		var node=chunks[key];var signature=hash(next[key])
		if stamps.get(key)!=signature:node.queue_redraw();stamps[key]=signature
		node.visible=visible.grow(64).intersects(Rect2(Vector2(node.box.position)*TILE,Vector2(node.box.size)*TILE))
func _draw():
	if world!=null:draw_rect(Rect2(Vector2.ZERO,Vector2(world.W,world.H)*TILE),Color("d4c89d"),false,3)
