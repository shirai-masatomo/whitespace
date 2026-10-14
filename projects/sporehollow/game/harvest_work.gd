extends RefCounted
## Fixed-tick progress and bounded presentation events. No draw/audio calls.
const KINDS=["mine","clear_tree"]
const SECONDS=4.0
const STRIKE_SECONDS=0.75
const EVENT_LIMIT=64

static func init(w):
	w.tree_work={}
	for row in w.campaign.get("tree_work",[]):
		var p=Vector2i(row.pos[0],row.pos[1])
		if w.trees.get(p,"")==row.id:w.tree_work[p]={"id":row.id,"elapsed":row.get("elapsed",0.0),"forbidden":row.get("forbidden",false)}
	for j in w.jobs:
		if j.kind in KINDS and not j.has("mountain_id") and exists(w,j.kind,j.pos):
			var row=target(w,j.kind,j.pos);row.elapsed=maxf(row.get("elapsed",0.0),j.get("work_elapsed",j.get("elapsed",0.0)))

static func save(w):
	w.campaign.tree_work=[]
	for p in w.tree_work:
		if w.trees.get(p,"")!=w.tree_work[p].id:continue
		var row=w.tree_work[p].duplicate(true);row.pos=[p.x,p.y];w.campaign.tree_work.append(row)

static func exists(w,kind: String,p: Vector2i) -> bool:return w.rocks.has(p) if kind=="mine" else w.trees.has(p)
static func target(w,kind: String,p: Vector2i) -> Dictionary:
	if not exists(w,kind,p):return {}
	if kind=="mine":return w.rocks[p]
	if not w.tree_work.has(p) or w.tree_work[p].id!=w.trees[p]:w.tree_work[p]={"id":w.trees[p],"elapsed":0.0,"forbidden":false}
	return w.tree_work[p]
static func tree_reason(w,p: Vector2i,own: int=-1) -> String:
	if not w.trees.has(p):return "伐採する木がありません"
	if target(w,"clear_tree",p).forbidden:return "この木の伐採は禁止中です"
	if w.jobs.any(func(j):return j.id!=own and j.kind=="clear_tree" and j.pos==p):return "伐採は予約済みです"
	return ""
static func progress(w,kind: String,p: Vector2i) -> float:
	return clampf((w.rocks.get(p,{}) if kind=="mine" else w.tree_work.get(p,{})).get("elapsed",0.0)/SECONDS,0,1)
static func emit(w,j,actor,event: String):
	w.harvest_events.append({"id":w.next_harvest_event,"tick":w.tick,"kind":j.kind,"event":event,"pos":j.get("contact",j.pos),"worker":actor.get("work_key","keeper"),"progress":progress(w,j.kind,j.pos)})
	w.next_harvest_event+=1
	while w.harvest_events.size()>EVENT_LIMIT:w.harvest_events.pop_front()
static func execute(w,j,actor):
	if j.has("mountain_id"):w.Mountains.execute(w,j,actor);return
	if not exists(w,j.kind,j.pos):w.Jobs.complete(w,j,false);return
	if j.kind=="clear_tree" and j.get("world_target",w.trees[j.pos])!=w.trees[j.pos]:w.Jobs.complete(w,j,false);return
	var why=w.Tasks.reason(w,j.kind,j.pos,-1,j.id)
	if why!="":j.state="blocked";j.block_reason=why;return
	if not w.Jobs.walk(w,j,w.neighbors(j.pos),actor):return
	var row=target(w,j.kind,j.pos)
	if not j.get("started",false):emit(w,j,actor,"start")
	j.started=true;j.state="working";j.phase="work"
	var before=maxf(row.get("elapsed",0.0),j.get("work_elapsed",j.get("elapsed",0.0)))
	row.elapsed=minf(SECONDS,before+w.DT*w.Jobs.factor(actor));j.work_elapsed=row.elapsed
	actor.facing=-1 if j.pos.x<actor.pos.x else (1 if j.pos.x>actor.pos.x else actor.get("facing",1))
	if floori(row.elapsed/STRIKE_SECONDS)>floori(before/STRIKE_SECONDS):emit(w,j,actor,"strike")
	if row.elapsed<SECONDS:return
	if w.actor_occupied(j.pos,actor.pos):j.state="blocked";j.block_reason="誰かがいます";return
	emit(w,j,actor,"complete")
	var amount=w.rocks[j.pos].amount if j.kind=="mine" else w.Story.CLEAR_WOOD
	if j.kind=="mine":
		w.rocks.erase(j.pos)
		preload("res://game/rock_view.gd").changed(w,j.pos)
		if j.pos not in w.mined_rock_cells:w.mined_rock_cells.append(j.pos)
		w.Tasks.save(w)
	else:
		if w.trees[j.pos] not in w.story.cleared:w.story.cleared.append(w.trees[j.pos])
		w.trees.erase(j.pos);w.tree_work.erase(j.pos);save(w);w.Story.persist(w)
	w.refresh_indoor()
	var item=w.Stock.add(w,"stone" if j.kind=="mine" else "wood",amount,j.pos)
	item.stocked=false;item.harvest_job_id=j.id
	if j.kind=="mine":item.mining_job_id=j.id
	w.Stock.sync(w)
	w.PlayerEvents.add(w,("採掘" if j.kind=="mine" else "伐採")+"完了：現地に"+("石" if j.kind=="mine" else "木材")+str(amount)+"個","harvest_done:%d"%j.id)
	w.Jobs.complete(w,j,true)

static func cells(w,first: Vector2i,last: Vector2i,kind: String="") -> Array:
	var result=[]
	for p in (w.rocks.keys() if kind=="mine" else w.trees.keys() if kind=="clear_tree" else w.rocks.keys()+w.trees.keys()):
		if p.x>=mini(first.x,last.x) and p.x<=maxi(first.x,last.x) and p.y>=mini(first.y,last.y) and p.y<=maxi(first.y,last.y):result.append(p)
	if kind in ["","mine"]:
		for r in w.mountains.values():
			if w.Mountains.overlapping(r,first,last) and r.pos not in result:result.append(r.pos)
	result.sort_custom(func(a,b):return a.y*w.W+a.x<b.y*w.W+b.x);return result
static func designate(w,kind: String,first: Vector2i,last: Vector2i) -> Dictionary:
	var accepted=0;var positions=cells(w,first,last,kind)
	for p in positions:
		if w.Tasks.designate(w,kind,p):accepted+=1
	return {"accepted":accepted,"skipped":positions.size()-accepted}
static func forbid(w,first: Vector2i,last: Vector2i,value: bool) -> int:
	var count=0
	for p in cells(w,first,last):
		var kind="mine" if w.rocks.has(p) or not w.Mountains.resource(w,p).is_empty() else "clear_tree"
		var r=w.Mountains.resource(w,p)
		if (target(w,kind,p) if r.is_empty() else r).get("forbidden",false)==value:continue
		if w.Tasks.set_forbidden(w,kind,p,-1,value):count+=1
	return count
