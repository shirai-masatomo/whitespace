extends RefCounted
## Personal fallback work: never enters the player's designation queue.
const SEARCH_SECONDS=2.0
static func jobs(w) -> Array:
	var result=[]
	for a in w.workers.values():
		if not a.get("personal_haul",{}).is_empty():result.append(a.personal_haul)
	return result
static func safe(w,a) -> bool:
	return w.Work.reason(w,a.work_key,a)=="" and not a.get("needs_rest",false) and not a.has("meal_remaining") and not w.enemies.any(func(e):return not e.get("done",false) and e.get("hp",0)>0 and not e.get("flee",false))
static func stop(w,a):
	var j=a.get("personal_haul",{})
	if not j.is_empty():w.Work.release(w,j)
	a.erase("personal_haul");a.erase("idle_move")
static func set_enabled(w,a,value:bool):
	a.auto_collect=value
	if not value:stop(w,a)
	a.auto_search_at=0
static func carrying(w,a) -> bool:
	var j=a.get("personal_haul",{})
	return not j.is_empty() and not w.Stock.cargo(w,a.work_key,j.id).is_empty()
static func collect(w,a) -> bool:
	if not a.get("auto_collect",true) or not safe(w,a):stop(w,a);return false
	var j=a.get("personal_haul",{})
	if j.is_empty():
		if w.tick<a.get("auto_search_at",0):return false
		a.auto_search_at=w.tick+ceili(SEARCH_SECONDS/w.DT)
		var rows=w.field_items.filter(func(r):return w.Stock.eligible(w,r,false) and r.kind!="chick" and not w.Stock.stored(w,r) and r.get("claims",{}).is_empty() and w.Access.can_take(w,r,a) and not w.jobs.any(func(job):return job.get("stock_id",-1)==r.stock_id or r.stock_id in job.get("haul_sources",[])))
		rows.sort_custom(func(x,y):return w.distance(a.pos,x.pos)<w.distance(a.pos,y.pos) if w.distance(a.pos,x.pos)!=w.distance(a.pos,y.pos) else x.stock_id<y.stock_id)
		# Bound failed route probes per scan; rotate so an unreachable cluster cannot starve later items.
		var offset=int(a.get("auto_search_cursor",0))
		for index in range(mini(8,rows.size())):
			var row=rows[posmod(offset+index,rows.size())]
			a.auto_search_cursor=posmod(offset+index+1,rows.size())
			if w.Jobs.path_to(w,a.pos,w.neighbors(row.pos)+[row.pos],false,true).is_empty():continue
			var plan=w.Stock.storage_plan(w,a,mini(w.Stock.carry_free(w,a.work_key),w.Stock.free_count(row)),row.kind)
			if not plan.has("pos") or plan.amount<=0:continue
			j={"id":w.next_job_id,"kind":"haul","personal":true,"pos":row.pos,"stock_id":row.stock_id,"animal_id":-1,"resource":"","reserved":0,"started":false,"state":"walking","assigned_to":a.work_key,"storage_target":plan.pos,"storage_amount":plan.amount}
			w.next_job_id+=1;a.personal_haul=j;a.auto_search_cursor=0;break
	if j.is_empty():return false
	a.erase("idle_move");a.erase("idle_anchor");a.work_job=j.id
	w.Stock.haul_step(w,j,a)
	a.work_status="自動収集 · "+("備蓄へ運搬中" if carrying(w,a) else "物資を取りに移動")
	if j.get("personal_finished",false) or j.state=="blocked":
		stop(w,a);a.auto_search_at=w.tick+ceili(SEARCH_SECONDS/w.DT)
	return true
static func idle(w,a):
	if not safe(w,a):a.erase("idle_move");return
	if not a.has("idle_anchor"):a.idle_anchor=a.pos
	var move=a.get("idle_move",{})
	if not move.is_empty():
		if obstructs(w,move.pos,a) or w.Jobs.walk(w,move,[move.pos],a) or move.get("state")=="blocked":a.erase("idle_move")
		else:a.work_status="近くを散歩中"
		return
	if w.tick<a.get("idle_at",0):return
	a.idle_at=w.tick+ceili((5.0+float(posmod(a.work_key.hash()+w.tick,6)))/w.DT)
	a.facing=-int(a.get("facing",1));a.work_status="周囲を見回しています"
	var candidates=w.neighbors(a.pos).filter(func(p):return w.distance(p,a.idle_anchor)<=3 and not obstructs(w,p,a))
	if not candidates.is_empty():a.idle_move={"kind":"idle","pos":candidates[posmod(w.tick+a.work_key.hash(),candidates.size())],"state":"walking"}
static func obstructs(w,p,a) -> bool:
	if not w.walkable(p) or w.actor_occupied(p,a.pos) or w.structures.has(p):return true
	for j in w.jobs:
		var cells=w.Buildings.cells(j.kind,j.pos) if w.BUILD.has(j.kind) else [j.pos]
		for q in cells:
			if w.distance(p,q)<=1:return true
	for other in w.workers.values():
		if other!=a and (other.get("work_job",-1)>=0 or w.build_deliveries.has(other.work_key)) and w.distance(p,other.pos)<=1:return true
	return false
