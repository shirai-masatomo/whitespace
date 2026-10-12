extends RefCounted
## Internal transport stages; never adds another player designation.
const RADIUS=6

static func job(w,id: int) -> Dictionary:
	for j in w.jobs:
		if j.id==id:return j
	return {}

static func needed(w,j) -> int:
	return maxi(0,j.get("required",w.BUILD[j.kind].cost)-w.Stock.delivered(w,j))

static func plans(w,a) -> Array:
	var rows=w.jobs.filter(func(j):return w.BUILD.has(j.kind) and not j.get("cancel_requested",false) and needed(w,j)>0 and j.get("delivery_owner","")=="" and w.tick>=j.get("delivery_retry",0))
	rows.sort_custom(func(x,y):
		var sx=w.Work.score(w,x,float(w.distance(a.pos,x.pos)));var sy=w.Work.score(w,y,float(w.distance(a.pos,y.pos)))
		return sx<sy if sx!=sy else x.id<y.id)
	return rows

static func sources(w,j,a) -> Array:
	var rows=w.field_items.filter(func(r):return r.kind==j.resource and r.get("location")=="ground" and not r.get("forbidden",false) and w.Stock.free_count(r)>0 and (w.Stock.eligible(w,r) or (r.get("construction_transfer",false) and r.get("job_id",-1)==j.id)))
	rows.sort_custom(func(x,y):return w.distance(a.pos,x.pos)<w.distance(a.pos,y.pos) if w.distance(a.pos,x.pos)!=w.distance(a.pos,y.pos) else x.stock_id<y.stock_id)
	return rows

static func proposal(w,key: String) -> Dictionary:
	var a=w.workers[key]
	if int(a.work_priorities.get("haul",0))<=0 or w.tick<a.get("delivery_retry",0):return {}
	for j in plans(w,a):
		var why=w.Buildings.reason(w,j.kind,j.pos,false) if not j.started else ""
		if why!="" and not (why=="ここに誰かいます" and a.pos==j.pos):j.block_reason=why;continue
		var destination=w.Jobs.path_to(w,a.pos,w.neighbors(j.pos))
		if destination.is_empty():j.block_reason="材料を搬入する通路がありません";continue
		for row in sources(w,j,a):
			var route=w.Jobs.path_to(w,a.pos,w.neighbors(row.pos))
			if route.is_empty():continue
			return {"kind":"build_delivery","id":j.id,"pos":row.pos,"seed_job":j.id,"priority":a.work_priorities.haul,"effort":float(route.size()+w.distance(row.pos,j.pos)),"queued_tick":j.get("queued_tick",w.tick)}
		j.material_wait=true;j.block_reason="備蓄に使える資材がありません"
	return {}

static func start(w,key: String,proposal: Dictionary) -> Dictionary:
	var a=w.workers[key];var first=job(w,proposal.seed_job)
	if first.is_empty():return {}
	var task={"kind":"build_delivery","id":first.id,"pos":first.pos,"phase":"fetch","state":"walking","allocations":[]}
	var capacity=w.Work.Policy.CARRY_CAPACITY
	var targets=plans(w,a);targets.erase(first);targets.push_front(first)
	for j in targets:
		if capacity<=0:break
		if w.distance(first.pos,j.pos)>RADIUS:continue
		if w.Jobs.path_to(w,a.pos,w.neighbors(j.pos)).is_empty():continue
		if not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false)
			if why!="" and not (why=="ここに誰かいます" and a.pos==j.pos):continue
		var left=mini(capacity,needed(w,j));var claims=[];var token="construction:%s:%d"%[key,j.id]
		for row in sources(w,j,a):
			if left<=0:break
			if w.Jobs.path_to(w,a.pos,w.neighbors(row.pos)).is_empty():continue
			var n=mini(left,w.Stock.free_count(row));row.claims[token]=n;claims.append({"stock_id":row.stock_id,"amount":n});left-=n;capacity-=n
		if claims.is_empty():continue
		task.allocations.append({"job_id":j.id,"token":token,"claims":claims});j.delivery_owner=key;j.material_wait=false;j.block_reason=""
	if task.allocations.is_empty():return {}
	w.build_deliveries[key]=task;a.work_job=-1
	w.Stock.sync(w);return task

static func release(w,key: String):
	var task=w.build_deliveries.get(key,{})
	if task.is_empty():return
	for entry in task.allocations:
		w.Stock.release_token(w,entry.token)
		var j=job(w,entry.job_id)
		if not j.is_empty() and j.get("delivery_owner","")==key:j.delivery_owner=""
	for row in w.Stock.cargo(w,key):
		if not row.get("construction_transfer",false):continue
		row.location="ground";row.owner="";row.pos=w.workers[key].pos if w.workers.has(key) else row.pos
	w.build_deliveries.erase(key);w.Stock.sync(w)

static func cancel_job(w,j):
	for key in w.build_deliveries.keys():
		var task=w.build_deliveries[key]
		for entry in task.allocations.duplicate():
			if entry.job_id!=j.id:continue
			w.Stock.release_token(w,entry.token);task.allocations.erase(entry)
		if task.allocations.is_empty():w.build_deliveries.erase(key)
	for row in w.field_items:
		if row.get("construction_transfer",false) and row.get("job_id",-1)==j.id:
			if row.location=="carry" and w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
			row.location="ground";row.owner="";row.job_id=-1;row.erase("construction_transfer")
	j.delivery_owner=""

static func step(w,key: String):
	var task=w.build_deliveries.get(key,{})
	if task.is_empty():return
	var a=w.workers[key]
	for entry in task.allocations.duplicate():
		var j=job(w,entry.job_id)
		if j.is_empty() or j.get("cancel_requested",false):
			w.Stock.release_token(w,entry.token);task.allocations.erase(entry)
	if task.allocations.is_empty():release(w,key);return
	for row in w.Stock.cargo(w,key):
		if row.get("construction_transfer",false) and row.get("forbidden",false):release(w,key);return
	for entry in task.allocations:
		if entry.claims.is_empty():continue
		var row=w.Stock.find(w,entry.claims[0].stock_id)
		if row.is_empty() or row.get("forbidden",false) or row.get("claims",{}).get(entry.token,0)<=0:
			a.work_status="搬入する資材を再確認";release(w,key);return
		if not row.get("construction_transfer",false) and not w.Stock.stored(w,row):release(w,key);return
		task.phase="fetch";task.pos=row.pos;a.work_status="建築材料を備蓄へ取りに移動"
		if w.Jobs.walk(w,task,w.neighbors(row.pos),a):
			var carried=w.Stock.pickup(w,row,entry.token,a,entry.job_id)
			if not carried.is_empty():carried.construction_transfer=true;entry.claims.pop_front()
		elif task.state=="blocked":a.delivery_retry=w.tick+ceili(w.Work.Policy.RETRY_SECONDS/w.DT);release(w,key)
		return
	var cargo=w.Stock.cargo(w,key).filter(func(r):return r.get("construction_transfer",false))
	if cargo.is_empty():release(w,key);return
	cargo.sort_custom(func(x,y):return w.distance(a.pos,job(w,x.job_id).get("pos",a.pos))<w.distance(a.pos,job(w,y.job_id).get("pos",a.pos)))
	var j=job(w,cargo[0].job_id)
	if j.is_empty():release(w,key);return
	task.phase="deliver";task.pos=j.pos;a.work_status="建築現場へ材料を搬入"
	if w.Jobs.walk(w,task,w.neighbors(j.pos),a):
		for row in cargo:
			if row.job_id!=j.id:continue
			row.location="site";row.owner="";row.pos=j.pos;row.erase("construction_transfer")
		j.delivery_owner="";j.material_wait=needed(w,j)>0;j.state="pending";j.block_reason=""
		w.job_log.append({"tick":w.tick,"event":"materials_delivered","id":j.id,"worker":key})
		w.Stock.sync(w)
		if w.Stock.cargo(w,key).is_empty():release(w,key)
	elif task.state=="blocked":
		j.block_reason=task.get("block_reason","材料搬入の通路待ち");j.delivery_retry=w.tick+ceili(w.Work.Policy.RETRY_SECONDS/w.DT);a.delivery_retry=j.delivery_retry;release(w,key)

static func reconcile(w):
	for key in w.build_deliveries.keys():
		if not w.workers.has(key):release(w,key)
