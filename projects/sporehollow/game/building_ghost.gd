extends RefCounted
const Art=preload("res://game/building_art.gd")
const Stroke=preload("res://game/wall_stroke.gd")
var cursor=Stroke.new()
var key=[]
var structures={}
var floors={}
var masks={}
var rebuilds=0
func update(w,kind:String="",rows:Array=[]):
	var signature=[w.get_instance_id(),hash(w.jobs),hash(w.structures),hash(w.floors),kind,hash(rows)]
	if signature==key:return
	key=signature;structures.clear();floors.clear();masks.clear();rebuilds+=1
	for j in w.jobs:
		if w.BUILD.has(j.kind):
			if w.BUILD[j.kind].layer=="floor":floors[j.pos]=j.kind
			else:structures[j.pos]=j.kind
	for row in rows:
		# Geometrically invalid cells do not become bridges between accepted ghosts.
		if not row.valid and not row.reason.begins_with("資材不足"):continue
		if w.BUILD.get(kind,{}).get("layer")=="floor":floors[row.pos]=kind
		else:structures[row.pos]=kind
func mask(w,kind:String,cell:Vector2i) -> int:
	var layer=w.BUILD.get(kind,{}).get("layer","")
	var cache=str(cell)+layer
	if masks.has(cache):return masks[cache]
	var result=0
	for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
		var p=cell+pair[0]
		if layer=="floor":
			if not floors.has(p) and w.floors.get(p,{}).get("status")!="ready":result+=pair[1]
		elif structures.get(p,"") in w.Buildings.WALLS+w.Buildings.DOORS or w.Buildings.enclosure(w.structures.get(p,{})):result+=pair[1]
	masks[cache]=result;return result
func preview(w,kind:String,cell:Vector2i) -> Dictionary:
	if cursor.kind!=kind or cursor.cells!=[cell]:cursor.begin(kind,cell)
	return cursor.plan(w)
func draw(g,kind:String,cell:Vector2i,valid:bool=true):
	var tint=Color(1,1,1,0.45) if valid else Color(1,0.34,0.28,0.48)
	var p=g.center(cell)
	if kind.begins_with("place_"):Art.placeable(g,p,kind.trim_prefix("place_"),tint)
	elif g.world.BUILD[kind].layer=="floor":Art.floor_at(g,cell,kind,mask(g.world,kind,cell),tint)
	else:
		var b={"kind":kind,"hp":g.world.BUILD[kind].hp,"max_hp":g.world.BUILD[kind].hp,"status":"ready","open":false,"lock_hp":8,"tint":tint,"preview_mask":mask(g.world,kind,cell)}
		if kind in g.world.Buildings.WALLS:Art.wall(g,p,b,true)
		elif kind in g.world.Buildings.DOORS:
			for part in ["frame_rear","leaf","frame_front"]:Art.door_layer(g,p,b,part)
		elif g.world.Craft.Data.BENCHES.has(kind):Art.bench(g,p,kind,tint)
	if not valid:
		g.draw_arc(p,11,0,TAU,24,Color("ed6259"),2.5)
		g.draw_line(p+Vector2(-8,8),p+Vector2(8,-8),Color("ed6259"),2.5)
