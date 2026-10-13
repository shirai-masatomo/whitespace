extends RefCounted
## One resource/ID per object. Explicit footprints; never inferred from image alpha.
const CONFIG={"large":{"amount":64,"batch":16,"seconds":8.0,"stages":4},"small":{"amount":12,"batch":4,"seconds":2.0,"stages":3}}
const FOOTPRINTS=[Rect2i(0,0,4,4),Rect2i(0,1,4,3),Rect2i(0,2,3,2),Rect2i(1,3,2,1)]
const REMAINS_SECONDS=12.0
static func init(w):
	w.mountains={}
	for saved in w.campaign.get("mining_mountains",[]):
		var row=saved.duplicate(true);row.pos=Vector2i(row.pos[0],row.pos[1]);w.mountains[row.id]=row
	reindex(w)
static func reindex(w):
	w.mountain_cells.clear()
	for r in w.mountains.values():
		for p in footprint(r):w.mountain_cells[p]=r.id
static func save(w):
	w.campaign.mining_mountains=[]
	for r in w.mountains.values():
		var row=r.duplicate(true);row.pos=[r.pos.x,r.pos.y];w.campaign.mining_mountains.append(row)
static func footprint(r) -> Array:
	if r.remaining<=0:return []
	var box=FOOTPRINTS[mini(r.stage,3)] if r.kind=="large" else Rect2i(0,0,1,1)
	var cells=[]
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):cells.append(r.pos+Vector2i(x,y))
	return cells
static func at(w,p: Vector2i) -> Dictionary:
	return w.mountains.get(w.mountain_cells.get(p,""),{})
static func by_origin(w,p: Vector2i) -> Dictionary:
	for r in w.mountains.values():
		if r.pos==p:return r
	return {}
static func resource(w,p: Vector2i) -> Dictionary:
	var r=at(w,p);return by_origin(w,p) if r.is_empty() else r
static func canonical(w,p: Vector2i) -> Vector2i:
	var r=resource(w,p);return r.pos if not r.is_empty() else p
static func goals(w,r) -> Array:
	var result=[]
	for p in footprint(r):
		for q in w.neighbors(p):
			if q not in result and w.walkable(q):result.append(q)
	return result
static func job_goals(w,j) -> Array:
	var r=w.mountains.get(j.get("mountain_id",""),{})
	return goals(w,r) if not r.is_empty() else w.neighbors(j.pos)
static func overlapping(r,first: Vector2i,last: Vector2i) -> bool:
	return footprint(r).any(func(p):return p.x>=mini(first.x,last.x) and p.x<=maxi(first.x,last.x) and p.y>=mini(first.y,last.y) and p.y<=maxi(first.y,last.y))
static func add(w,kind: String,p: Vector2i) -> Dictionary:
	var id="mountain:%s:%d:%d"%[kind,p.x,p.y]
	if w.mountains.has(id):return {}
	var r={"id":id,"kind":kind,"pos":p,"stage":0,"remaining":CONFIG[kind].amount,"elapsed":0.0,"forbidden":false,"batches":0,"depleted_tick":-1}
	for c in footprint(r):
		if not w.inside(c) or not w.Biome.available(w,c):return {}
	w.mountains[id]=r;reindex(w);return r
static func populate(w):
	# Called exclusively inside new-map population. No retroactive insertion on load.
	var sites=[]
	for y in range(2,w.H-5):
		for x in range(2,w.W-5):
			var p=Vector2i(x,y)
			if w.Biome.kind(w,p)=="rocky":sites.append(p)
	sites.sort_custom(func(a,b):return w.Biome.unit(w.seed_value,a.x,a.y,421)<w.Biome.unit(w.seed_value,b.x,b.y,421))
	var kinds=[]
	for group in range(ceili(w.W*w.H/1700.0*w.Biome.SETTINGS.mountain_groups_per_1700)):kinds.append_array(["large","small","small","small"])
	for kind in kinds:
		for p in sites:
			var box=Rect2i(p,Vector2i(4,4) if kind=="large" else Vector2i.ONE);var valid=true
			for y in range(box.position.y-1,box.end.y+1):
				for x in range(box.position.x-1,box.end.x+1):
					var c=Vector2i(x,y)
					if w.Biome.protected(w,c) or not w.Biome.available(w,c):valid=false
			if not valid:continue
			var r=add(w,kind,p)
			if r.is_empty():continue
			var reached=w.Biome.reachable(w);var connected=true
			for y in range(w.H):
				for x in range(w.W):
					var c=Vector2i(x,y)
					if w.walkable(c) and not reached.has(c):connected=false
			if not connected:w.mountains.erase(r.id);reindex(w);continue
			break
	save(w)
static func execute(w,j,actor):
	var r=w.mountains.get(j.mountain_id,{})
	if r.is_empty() or r.remaining<=0:w.Jobs.complete(w,j,false);return
	if r.forbidden:j.state="blocked";j.block_reason="この岩山の採掘は禁止中です";return
	if not w.Jobs.walk(w,j,goals(w,r),actor):return
	var contact=footprint(r);contact.sort_custom(func(a,b):return w.distance(actor.pos,a)<w.distance(actor.pos,b))
	j.contact=contact[0]
	if not j.get("started",false):w.Harvest.emit(w,j,actor,"start")
	j.started=true;j.state="working";j.phase="work"
	var config=CONFIG[r.kind];var before=r.elapsed
	r.elapsed=minf(config.seconds,before+w.DT*w.Jobs.factor(actor));j.work_elapsed=r.elapsed
	actor.facing=-1 if j.contact.x<actor.pos.x else (1 if j.contact.x>actor.pos.x else actor.get("facing",1))
	if floori(r.elapsed/w.Harvest.STRIKE_SECONDS)>floori(before/w.Harvest.STRIKE_SECONDS):w.Harvest.emit(w,j,actor,"strike")
	if r.elapsed<config.seconds:return
	# Only reachable free ground at this work face receives a physical batch.
	var candidates=w.neighbors(actor.pos).filter(func(p):return w.walkable(p) and not w.occupied(p) and not w.live_structure(p) and not w.natural.has(p) and p not in w.storage_cells)
	if candidates.is_empty():j.state="blocked";j.block_reason="石材を置く場所がありません";return
	var amount=mini(config.batch,r.remaining)
	var item=w.Stock.add(w,"stone",amount,candidates[0]);item.stocked=false;item.mountain_id=r.id;item.harvest_job_id=j.id;item.mountain_batch=r.batches
	r.remaining-=amount;r.batches+=1;r.stage+=1;r.elapsed=0.0;j.work_elapsed=0.0;j.state="walking"
	reindex(w);w.Harvest.emit(w,j,actor,"complete");w.Stock.sync(w);w.refresh_indoor()
	if r.remaining<=0:
		r.depleted_tick=w.tick
		w.PlayerEvents.add(w,"岩山の採掘完了：石材は現地で回収できます","mountain_done:"+r.id)
		w.Jobs.complete(w,j,true)
	save(w)
