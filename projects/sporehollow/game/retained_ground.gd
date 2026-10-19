extends Node2D
const Metrics=preload("res://game/terrain_metrics.gd")
## Retain native CanvasItem commands. Camera movement never rebuilds ground.
const SIZE=8
const TILE=Vector2(48,42)
const Board=preload("res://game/board_art.gd")
const Rock=preload("res://game/rock_view.gd")
var world
var chunks={}
var stamps={}
var occupancy_signature=0
var rock_revision=-1
class Base extends Node2D:
	var world
	var box:Rect2i
	func _draw():
		var started=Metrics.start()
		Board.draw_base(self,world,TILE,box)
		Metrics.finish("chunk_draw",started)
class Chunk extends Node2D:
	var world
	var box:Rect2i
	const TILE=Vector2(48,42)
	func center(p):return (Vector2(p)+Vector2(0.5,0.5))*TILE
	func _draw():
		var started=Metrics.start()
		Board.draw_decor(self,world,TILE,box)
		Rock.ground(self,Rect2(Vector2(box.position)*TILE,Vector2(box.size)*TILE))
		Metrics.finish("chunk_draw",started)
# Perimeter ground reads immediate neighbours and their connection masks.
# A changed rock can therefore affect cells up to two steps away, across chunks.
static func rock_dependency_chunks(p: Vector2i) -> Array:
	var result=[]
	for dy in [-2,0,2]:
		for dx in [-2,0,2]:
			var key=Vector2i(floori(float(p.x+dx)/SIZE),floori(float(p.y+dy)/SIZE))
			if key not in result:result.append(key)
	return result

func _ready():
	show_behind_parent=true
	sync()
func _exit_tree():
	Board.release_ground(world)
	Rock.release_ground(world)
	preload("res://game/story_view.gd").release_stumps(world)
	world=null;chunks.clear();stamps.clear()
func _process(_delta):sync()
func sync():
	var started=Metrics.start()
	sync_measured()
	Metrics.finish("ground_sync",started)
func sync_measured():
	var w=get_parent().world
	if world!=w:
		world=w
		for child in get_children():child.queue_free()
		chunks.clear();stamps.clear();occupancy_signature=0
		# Release previous-map scenery references before gameplay rendering.
		preload("res://game/story_view.gd").cut_cells(w)
		Board.cache_ground(w,TILE)
		Rock.prepare_ground(w)
		for y in range(ceili(w.H/float(SIZE))):
			for x in range(ceili(w.W/float(SIZE))):
				var cell=Vector2i(x,y);var node=Chunk.new();node.world=w;node.box=Rect2i(cell*SIZE,Vector2i(mini(SIZE,w.W-x*SIZE),mini(SIZE,w.H-y*SIZE)));node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;Board.prepare_region(w,TILE,node.box);add_child(node);chunks[cell]=node
				var base=Base.new();base.world=w;base.box=node.box;base.show_behind_parent=true;base.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
				if Board.textured(w):base.material=Board.soil_material()
				node.add_child(base)
		queue_redraw()
	if rock_revision!=w.rock_visual_revision:
		rock_revision=w.rock_visual_revision
		if Vector2i(-1,-1) in w.rock_changed_cells:
			for node in chunks.values():node.queue_redraw()
		else:
			for p in w.rock_changed_cells:
				for key in rock_dependency_chunks(p):
					if chunks.has(key):chunks[key].queue_redraw()
		w.rock_changed_cells.clear()
	var occupancy=hash([w.floors,w.structures,w.natural])
	if occupancy!=occupancy_signature:
		occupancy_signature=occupancy
		var next={}
		for key in chunks:next[key]=[]
		var groups=[w.floors.keys(),w.structures.keys(),[],w.natural.keys(),[]]
		for index in range(groups.size()):
			for p in groups[index]:
				var key=Vector2i(floori(float(p.x)/SIZE),floori(float(p.y)/SIZE))
				var affected=rock_dependency_chunks(p) if index==2 else [key]
				for target in affected:
					if next.has(target):next[target].append([index,p,w.live_structure(p) if index==1 else true])
		for key in chunks:
			var signature=hash(next[key])
			if stamps.get(key)!=signature:chunks[key].queue_redraw();stamps[key]=signature
	var visible=get_canvas_transform().affine_inverse()*get_viewport_rect()
	for key in chunks:
		var node=chunks[key]
		node.visible=visible.grow(64).intersects(Rect2(Vector2(node.box.position)*TILE,Vector2(node.box.size)*TILE))
func _draw():
	if world!=null:draw_rect(Rect2(Vector2.ZERO,Vector2(world.W,world.H)*TILE),Color("d4c89d"),false,3)
