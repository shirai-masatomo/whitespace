extends RefCounted
## Presentation reads the fixed-tick work state. It never finishes jobs or removes terrain.
const EVENT_DRAW_LIMIT=24
const EFFECT_SECONDS=0.65
const GroundArt=preload("res://game/rock_art.gd")
var source=null
var seen=0
func setup(w):source=w;seen=w.next_harvest_event-1
func sync(g):
	if source!=g.world:setup(g.world);return
	var closest=[]
	for e in g.world.harvest_events:
		if e.id<=seen:continue
		seen=e.id
		if g.world.paused or e.event not in ["strike","complete"]:continue
		var screen=g.get_canvas_transform()*g.center(e.pos)
		if not Rect2(-80,-80,1440,960).has_point(screen):continue
		if e.event=="strike":g.puff(g.center(e.pos),"stone_powder" if e.kind=="mine" else "wood_chips")
		closest.append(e)
	closest.sort_custom(func(a,b):return g.center(a.pos).distance_to(g.camera.position)<g.center(b.pos).distance_to(g.camera.position))
	for e in closest.slice(0,2):
		var distance=g.center(e.pos).distance_to(g.camera.position)/g.TILE.x
		g.audio.harvest_cue(("mine_hit" if e.kind=="mine" else "chop_hit") if e.event=="strike" else ("rock_crumble" if e.kind=="mine" else "tree_fall"),distance)
static func active(g,key: String="keeper") -> Dictionary:
	var j=g.world.Work.active(g.world,key)
	return j if not j.is_empty() and j.kind in g.world.Harvest.KINDS and j.state=="working" and not j.get("cancel_requested",false) else {}
static func phase(g,j) -> float:
	var a=g.world.workers.get(j.get("assigned_to","keeper"),g.world.keeper)
	var elapsed=j.get("work_elapsed",0.0)+(0.0 if g.world.paused else minf(g.accumulated,g.world.DT)*g.world.Jobs.factor(a))
	return fposmod(elapsed,g.world.Harvest.STRIKE_SECONDS)/g.world.Harvest.STRIKE_SECONDS
static func tool(g,key: String="keeper"):
	var j=active(g,key)
	if j.is_empty():return
	var a=g.world.workers[key];var foot=g.actor_pixel(key,a.pos)+Vector2(0,14)
	var contact_cell=j.get("contact",j.pos)
	var direction=Vector2(contact_cell-a.pos).normalized();var sweep=sin(phase(g,j)*PI)
	var hand=foot+direction*8+Vector2(0,-21)
	var contact=g.center(contact_cell)-direction*16 if j.kind=="mine" else g.StoryView.tree_foot(g,j.pos)-direction*6+Vector2(0,-14)
	var tip=hand+(contact-hand).rotated(-1.05*sweep)
	g.draw_line(foot+Vector2(0,-24),hand,Color("d3ad82"),4)
	g.draw_line(hand-direction*6,tip,Color("8c6444"),3)
	if j.kind=="mine":
		g.draw_polyline(PackedVector2Array([tip+Vector2(-8,4),tip+Vector2(-3,-4),tip+Vector2(7,-3),tip+Vector2(11,3)]),Color("bbbfb4"),3)
	else:
		g.draw_colored_polygon(PackedVector2Array([tip+Vector2(-4,-7),tip+Vector2(5,-6),tip+Vector2(8,0),tip+Vector2(5,7),tip+Vector2(-4,5)]),Color("b9c2b5"))
		g.draw_line(tip+Vector2(6,-4),tip+Vector2(7,4),Color("ede6cd"),2)
static func tree(g,p: Vector2i,deep: bool=false):
	var kick=0.0
	for e in g.world.harvest_events.slice(-EVENT_DRAW_LIMIT):
		var age=(g.world.tick-e.tick)*g.world.DT+g.accumulated
		if e.kind=="clear_tree" and e.event=="strike" and e.pos==p and age<EFFECT_SECONDS:kick=sin(age*30)*0.035*(1-age/EFFECT_SECONDS)
	# Trunk, notch and canopy share exactly the same foot transform.
	g.StoryView.tree(g,p,deep,kick)
static func recent(g) -> Array:
	return g.world.harvest_events.slice(-EVENT_DRAW_LIMIT).filter(func(e):return (g.world.tick-e.tick)*g.world.DT+g.accumulated<EFFECT_SECONDS)
static func remnants(g) -> Array:return recent(g).filter(func(e):return e.event=="complete")
static func remnant(g,e):
	var age=(g.world.tick-e.tick)*g.world.DT+g.accumulated;var t=clampf(age/EFFECT_SECONDS,0,1);var q=g.center(e.pos)
	if e.kind=="clear_tree":
		var id="world.tree_"+g.StoryView.tree_variant(g.world,e.pos)
		var foot=g.StoryView.tree_foot(g,e.pos)
		# Rotate only pixels above the cut (native y=65). The persistent stump
		# stays on the ground; the standing root is never drawn a second time.
		var pivot=foot+Vector2(0,-7)*g.StoryView.TREE_SCALE
		g.draw_set_transform(pivot,1.3*smoothstep(0,0.8,t),Vector2.ONE*g.StoryView.TREE_SCALE)
		for part in ["_trunk","_canopy"]:
			var texture=g.Direction.ASSETS[id+part].texture
			g.draw_texture_rect_region(texture,Rect2(-32,-65,64,65),Rect2(0,0,64,65),Color(1,1,1,1-t))
		g.draw_set_transform(Vector2.ZERO)
		GroundArt.paint(g,"biome_environment_v2/tree_cut/branch_debris.png",q,0.7*(1-t))
	else:g.RockView.rubble(g,e.pos,1-t)
static func particles(g):
	for e in recent(g):
		if e.event not in ["strike","complete"]:continue
		var age=(g.world.tick-e.tick)*g.world.DT+g.accumulated;var origin=g.center(e.pos)+Vector2(0,-8)
		if e.kind=="mine":g.RockView.chips(g,e.pos,age);continue
		# Native three-frame leaves complement the existing wood_chips puff.
		var cursor=age
		for i in range(3):
			var duration=[0.1,0.12,0.16][i]
			if cursor<duration:
				GroundArt.paint(g,"biome_environment_v1/forest/leaves_%02d.png"%i,origin)
				break
			cursor-=duration
