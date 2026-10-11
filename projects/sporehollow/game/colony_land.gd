extends RefCounted
# Approved live geometry. Old saved object positions are retained.
const WIDTH=50
const HEIGHT=34
const BOUNDS=Rect2i(0,0,WIDTH,HEIGHT)
const IDOL_SIZE=Vector2i(2,2)
const IDOL_ANCHOR=Vector2i(24,16)

static func idol_cells() -> Array:
	return [IDOL_ANCHOR,IDOL_ANCHOR+Vector2i.RIGHT,IDOL_ANCHOR+Vector2i.DOWN,IDOL_ANCHOR+Vector2i.ONE]

static func border_cells() -> Array:
	var result=[]
	for x in range(WIDTH):result.append(Vector2i(x,0));result.append(Vector2i(x,HEIGHT-1))
	for y in range(1,HEIGHT-1):result.append(Vector2i(0,y));result.append(Vector2i(WIDTH-1,y))
	return result

static func safe_cell(w,old: Vector2i) -> Vector2i:
	var near=old.clamp(Vector2i.ZERO,Vector2i(WIDTH-1,HEIGHT-1))
	var queue=[near];var seen={near:true}
	while not queue.is_empty():
		var p=queue.pop_front()
		if w.walkable(p) and not w.actor_occupied(p,old):return p
		for n in w.neighbors(p):
			if BOUNDS.has_point(n) and not seen.has(n):seen[n]=true;queue.append(n)
	return near

static func migrate(w):
	if w.boundary_version>=1:return
	# Old off-map actors return to the nearest free visible cell, never become an instant loss.
	# Interior coordinates, HP, cargo, jobs and simulation time remain unchanged.
	var moved=[];var positions={}
	for e in w.enemies:
		if e.done or BOUNDS.has_point(e.pos):continue
		var old=e.pos;e.pos=safe_cell(w,old);positions[old]=e.pos
		moved.append({"kind":"enemy","id":e.id,"from":old,"to":e.pos})
		e.path=[e.pos];e.arrival_complete=false
		for key in ["arrival_route","arrival_goal","arrival_gate","arrival_closed","arrival_barriers","search_goal"]:e.erase(key)
		e.search_goal=null
		if e.carry=="keeper":w.keeper.pos=e.pos
	for a in w.workers.values()+w.animals:
		if not a.get("placed",false) or BOUNDS.has_point(a.pos):continue
		var old=a.pos;a.pos=safe_cell(w,old);positions[old]=a.pos
		moved.append({"kind":"ally","id":a.get("id",-1),"from":old,"to":a.pos})
	for item in w.field_items:
		if item.get("location","ground")!="ground" or BOUNDS.has_point(item.pos):continue
		var old=item.pos;item.pos=safe_cell(w,old);positions[old]=item.pos
		moved.append({"kind":"item","id":item.get("stock_id",-1),"from":old,"to":item.pos})
	# Old rescue-lane orders can point outside even when their actor is already inside.
	for a in w.workers.values()+w.animals:
		for key in ["home","order"]:
			if a.get(key) is Vector2i and not BOUNDS.has_point(a[key]):
				moved.append({"kind":"order","field":key,"id":a.get("id",-1),"from":a[key],"to":a.pos});a[key]=a.pos
		if a.get("pending",{}).get("pos") is Vector2i and not BOUNDS.has_point(a.pending.pos):
			moved.append({"kind":"order","field":"pending.pos","id":a.get("id",-1),"from":a.pending.pos,"to":a.pos});a.pending.pos=a.pos
	for job in w.jobs:
		for key in ["pos","command_pos","leader_goal"]:
			if job.get(key) is Vector2i and not BOUNDS.has_point(job[key]):job[key]=positions.get(job[key],safe_cell(w,job[key]))
		for target in job.get("targets",[]):
			if target.get("dest") is Vector2i and not BOUNDS.has_point(target.dest):target.dest=positions.get(target.dest,safe_cell(w,target.dest))
	if w.manual_goal is Vector2i and not BOUNDS.has_point(w.manual_goal):w.manual_goal=safe_cell(w,w.manual_goal)
	w.boundary_version=1;w.campaign.boundary_version=1
	if not moved.is_empty():
		w.campaign.boundary_migration=moved
		w.say("旧セーブの地図外の人物・物資を、近くの地図内へ移しました")

static func is_exit(p: Vector2i) -> bool:
	return ((p.x==-1 or p.x==WIDTH) and p.y>=0 and p.y<HEIGHT) or ((p.y==-1 or p.y==HEIGHT) and p.x>=0 and p.x<WIDTH)
