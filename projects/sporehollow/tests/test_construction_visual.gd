extends "res://tests/test_housing_sleep.gd"
const Ghost=preload("res://game/building_ghost.gd")
const Art=preload("res://game/building_art.gd")
class Capture:
	extends RefCounted
	var world
	var TILE=Vector2(48,42)
	var calls=[]
	func center(q):return Vector2(q)*TILE+TILE/2
	func box(r):return [r.position.x,r.position.y,r.size.x,r.size.y]
	func xy(p):return [p.x,p.y]
	func wall_links(q):
		var result={}
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:result[d]=world.Buildings.enclosure(world.structures.get(q+d,{}))
		return result
	func draw_texture(t,p,c=Color.WHITE):calls.append({"path":t.resource_path,"at":xy(p),"tint":c.to_html()})
	func draw_texture_rect(t,r,_tile=false,c=Color.WHITE):calls.append({"path":t.resource_path,"at":xy(r.position),"size":xy(r.size),"tint":c.to_html()})
	func draw_texture_rect_region(t,r,src):calls.append({"path":t.resource_path,"at":xy(r.position),"src":box(src)})
	func draw_mesh(_m,t,tr,c):calls.append({"path":t.resource_path,"at":xy(tr.origin),"mesh":true,"tint":c.to_html()})
	func draw_rect(r,c,_filled=true,_width=1):calls.append({"rect":box(r),"color":c.to_html()})
	func draw_line(a,b,c,width=1):calls.append({"line":[xy(a),xy(b)],"color":c.to_html(),"width":width})
	func draw_polyline(points,c,width=1):
		var list=[]
		for point in points:list.append(xy(point))
		calls.append({"line":list,"color":c.to_html(),"width":width})
	func draw_arc(pos,radius,_a,_b,_n,c,width):calls.append({"arc":xy(pos),"radius":radius,"color":c.to_html(),"width":width})
func old_floor(pen,cell,extend):
	var mask=0
	for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
		if w.floors.get(cell+pair[0],{}).get("status")!="ready":mask+=pair[1]
	Art.floor_at(pen,cell,w.floors[cell].kind,mask)
	if not extend:return
	var kind=w.floors[cell].kind;var tex=Art.TEXTURES[Art.floor_path(kind)+("wood_00.png" if Art.material(kind)=="wood" else "base.png")]
	for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		if not w.Buildings.enclosure(w.structures.get(cell+d,{})):continue
		var offset=Vector2(0,-21) if d==Vector2i.UP else Vector2(0,42) if d==Vector2i.DOWN else Vector2(-24,0) if d==Vector2i.LEFT else Vector2(48,0)
		var size=Vector2(48,21) if d.x==0 else Vector2(24,42)
		pen.draw_texture_rect_region(tex,Rect2(Vector2(cell)*pen.TILE+offset,size),Rect2(Vector2.ZERO,size))
func run():
	w=fixture();w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(28,24));var s=preload("res://game/wall_stroke.gd").new()
	s.begin("wood_wall",Vector2i(35,25));s.add(Vector2i(37,25));w.Stock.add(w,"wood",7,Vector2i(25,23))
	var draft=s.plan(w);check(draft.accepted==3 and draft.rows.map(func(r):return r.waiting_material)==[false,true,true],"Three valid candidates share one7-unit budget")
	s.commit(w);var view=preload("res://game/construction_view.gd").new();view.update(w)
	check(view.rows.values().map(func(r):return r.waiting_material)==[false,true,true],"Committed ghosts share same funding state")
	var cached=view.rebuilds;view.update(w);check(view.rebuilds==cached,"Unchanged committed display reuses cached rows")
	var j=w.jobs[1];w.Stock.add(w,"wood",3,j.pos,"site",j.id);view.update(w)
	check(view.rows[j.id].delivered==3 and view.rows[j.id].missing==2 and not view.rows[j.id].waiting_material,"Onsite3 + available2 covers remaining quantity once")
	j.cancel_requested=true;w.Stock.sync(w);view.update(w);check(view.rows[j.id].delivered==3,"Deferred cancellation still displays real onsite quantity");j.erase("cancel_requested")
	w.Stock.add(w,"wood",5,Vector2i(26,23));view.update(w);check(view.rows.values().all(func(r):return not r.waiting_material),"Restock removes material-wait display")
	w.Stock.designate(w,"forbid",Vector2i(26,23),Vector2i(26,23));view.update(w);check(view.rows[w.jobs[2].id].waiting_material,"Forbidden supply updates waiting ghost immediately")
	s.begin("wood_wall",Vector2i(40,25));check(s.plan(w).rows[0].waiting_material,"New draft respects earlier commitments")
	w.trees[Vector2i(40,25)]="test";check(not s.plan(w).rows[0].valid,"Invalid placement remains distinct from reservable shortage")
	var pen=Capture.new();pen.world=w;var ghost=Ghost.new();var ghosts=[]
	for kind in ["wood_wall","door","wood_tile","cooking_bench"]:
		for state in ["before","normal","wait","invalid"]:
			pen.calls.clear();ghost.draw(pen,kind,Vector2i(1,1),state!="invalid",state=="wait");ghosts.append({"kind":kind,"state":state,"calls":pen.calls.duplicate(true)})
			check(pen.calls.any(func(c):return c.has("arc"))==(state=="invalid"),"Prohibition only for invalid "+kind+" / "+state)
	# Nine material combinations, same floor/wall anchors in three modes.
	var rooms=[]
	w=fixture();pen.world=w
	for wall_kind in ["wall","wood_wall","stone_wall"]:
		for floor_kind in ["soil_tile","wood_tile","stone_tile"]:
			w.structures.clear();w.floors.clear()
			for x in range(5):
				for y in range(5):ready(wall_kind if x in [0,4] or y in [0,4] else floor_kind,Vector2i(x+1,y+1))
			ready("door",Vector2i(3,1));ready("door",Vector2i(1,3));w.structures[Vector2i(1,3)].open=true
			for mode in ["half","none","contact"]:
				pen.calls.clear()
				for q in w.floors:
					if mode=="contact":Art.floor_tile(pen,q)
					else:old_floor(pen,q,mode=="half")
				if mode=="contact":check(pen.calls.filter(func(c):return c.has("src")).all(func(c):return int(c.src[2]) in [8,48]),"Only8px contacts or bounded48px doorway: "+wall_kind+floor_kind)
				for q in w.structures:
					var b=w.structures[q]
					if b.kind=="door":
						for layer in ["frame_rear","leaf","frame_front"]:Art.door_layer(pen,pen.center(q),b,layer)
					else:Art.wall(pen,pen.center(q),b,false)
				rooms.append({"wall":wall_kind,"floor":floor_kind,"mode":mode,"calls":pen.calls.duplicate(true)})
	var states=[]
	for status in ["ready","building","destroyed"]:
		w.structures[Vector2i(5,3)].status=status;pen.calls.clear()
		for q in w.floors:Art.floor_tile(pen,q)
		var overlay=pen.calls.filter(func(c):return c.has("src") and c.at[0]==240 and c.at[1]==126)
		check(not overlay.is_empty() if status=="ready" else overlay.is_empty(),"Side contact follows wall status "+status)
		for q in w.structures:
			var b=w.structures[q]
			if b.status=="destroyed":continue
			if b.status=="building":ghost.draw(pen,b.kind,q);continue
			if b.kind=="door":
				for layer in ["frame_rear","leaf","frame_front"]:Art.door_layer(pen,pen.center(q),b,layer)
			else:Art.wall(pen,pen.center(q),b,false)
		states.append({"state":status,"calls":pen.calls.duplicate(true)})
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/construction-visual.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"ghosts":ghosts,"rooms":rooms,"wall_states":states,"sx":Art.WALL_SOURCE_X,"sy":Art.WALL_SOURCE_Y,"dx":Art.WALL_DEST_X,"dy":Art.WALL_DEST_Y},"  "))
	print("Construction visual: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
