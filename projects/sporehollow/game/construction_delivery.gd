extends RefCounted
## Internal transport stages; never adds another player designation.
const Reservations=preload("res://game/build_reservations.gd")
const RADIUS=6
const GROUP_WAIT="同じ施工グループへの資材搬入を待っています"

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
	var rows=w.field_items.filter(func(r):return Reservations.usable(w,r,j)>0 and w.Access.can_take(w,r,a))
	rows.sort_custom(func(x,y):return Reservations.held(x,j)>Reservations.held(y,j) if (Reservations.held(x,j)>0)!=(Reservations.held(y,j)>0) else w.distance(a.pos,x.pos)<w.distance(a.pos,y.pos) if w.distance(a.pos,x.pos)!=w.distance(a.pos,y.pos) else x.stock_id<y.stock_id)
	return rows

static func proposal(w,key: String) -> Dictionary:
	var a=w.workers[key]
	if int(a.work_priorities.get("haul",0))<=0 or w.tick<a.get("delivery_retry",0):return {}
	for j in plans(w,a):
		var why=w.Buildings.reason(w,j.kind,j.pos,false,j.id) if not j.started else ""
		if why!="" and not (why=="ここに誰かいます" and a.pos==j.pos):j.block_reason=why;continue
		# No path can produce missing material. Check usable physical sources
		# first: otherwise J unfunded plans cause H*J pointless route searches.
		var candidates=sources(w,j,a)
		if candidates.is_empty():
			j.material_wait=true
			j.block_reason="資材待ち：備蓄を利用できる担当者が必要です" if w.field_items.any(func(r):return Reservations.usable(w,r,j)>0) else "資材待ち：備蓄に使える資材がありません"
			continue
		var destination=w.Jobs.path_to(w,a.pos,w.Buildings.job_goals(w,j))
		if destination.is_empty():j.block_reason="材料を搬入する通路がありません";continue
		for row in candidates:
			var route=w.Jobs.path_to(w,a.pos,w.neighbors(row.pos))
			if route.is_empty():continue
			return {"kind":"build_delivery","id":j.id,"pos":row.pos,"seed_job":j.id,"priority":a.work_priorities.haul,"effort":float(route.size()+w.distance(row.pos,j.pos)),"queued_tick":j.get("queued_tick",w.tick)}
		j.material_wait=true
		j.block_reason="材料の備蓄へ通じる通路がありません"
	return {}

static func start(w,key: String,proposal: Dictionary) -> Dictionary:
	var a=w.workers[key];var first=job(w,proposal.seed_job)
	if first.is_empty():return {}
	var task={"kind":"build_delivery","id":first.id,"pos":first.pos,"phase":"fetch","state":"walking","allocations":[]}
	var capacity=w.Stock.carry_free(w,key)
	var targets=plans(w,a)
	var same=targets.filter(func(j):return j.get("construction_group",j.id)==first.get("construction_group",first.id))
	targets=same+targets.filter(func(j):return j.get("construction_group",j.id)!=first.get("construction_group",first.id))
	targets.erase(first);targets.push_front(first)
	for j in targets:
		if capacity<=0:break
		if w.distance(first.pos,j.pos)>RADIUS:continue
		if w.Jobs.path_to(w,a.pos,w.Buildings.job_goals(w,j)).is_empty():continue
		if not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false,j.id)
			if why!="" and not (why=="ここに誰かいます" and a.pos==j.pos):continue
		var left=mini(capacity,needed(w,j));var claims=[];var token="construction:%s:%d"%[key,j.id]
		for row in sources(w,j,a):
			if left<=0:break
			if w.Jobs.path_to(w,a.pos,w.neighbors(row.pos)).is_empty():continue
			var n=mini(left,Reservations.usable(w,row,j));Reservations.transfer(w,row,j,token,n);claims.append({"stock_id":row.stock_id,"amount":n});left-=n;capacity-=n
		if claims.is_empty():continue
		task.allocations.append({"job_id":j.id,"token":token,"claims":claims});j.delivery_owner=key;j.material_wait=false;j.block_reason=""
	if task.allocations.is_empty():return {}
	w.build_deliveries[key]=task;a.work_job=-1
	w.Stock.sync(w);return task

static func release(w,key: String):
	var task=w.build_deliveries.get(key,{})
	if task.is_empty():return
	for entry in task.allocations:
		Reservations.return_claim(w,entry.token,job(w,entry.job_id))
		var j=job(w,entry.job_id)
		if not j.is_empty() and j.get("delivery_owner","")==key:j.delivery_owner=""
	for row in w.Stock.cargo(w,key):
		if not row.get("construction_transfer",false):continue
		row.location="ground";row.owner="";row.pos=w.workers[key].pos if w.workers.has(key) else row.pos
	w.build_deliveries.erase(key);w.Stock.sync(w)

static func cancel_job(w,j):
	w.Stock.release_token(w,Reservations.token(j))
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
		if row.is_empty() or row.get("forbidden",false) or not w.Access.can_take(w,row,a) or row.get("claims",{}).get(entry.token,0)<=0:
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
	if w.Jobs.walk(w,task,w.Buildings.job_goals(w,j),a):
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
	var owners={}
	for key in w.build_deliveries:
		for allocation in w.build_deliveries[key].allocations:owners[allocation.job_id]=key
	for j in w.jobs:
		if not w.BUILD.has(j.kind):continue
		var owner=j.get("delivery_owner","")
		if owner!="" and owners.get(j.id,"")!=owner:
			Reservations.return_claim(w,"construction:%s:%d"%[owner,j.id],j)
			j.delivery_owner="";j.delivery_retry=w.tick;j.block_reason="";j.material_wait=needed(w,j)>0
	for row in w.field_items:
		if row.get("construction_transfer",false) and row.get("location")=="carry" and owners.get(row.job_id,"")!=row.owner:
			if w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
			row.location="ground";row.owner="";w.Stock.sync(w)

# Only unlatched groups enter the barrier scan. Site totals and source lists are
# indexed once per scheduler step, not re-scanned for each build candidate.
static func can_build(j) -> bool:
	return j.get("started",false) or j.get("construction_ready",true)

static func refresh_groups(w):
	preload("res://game/terrain_metrics.gd").count("construction_group_job_rows",w.jobs.size())
	var groups={}
	for j in w.jobs:
		if not w.BUILD.has(j.kind) or j.get("cancel_requested",false):continue
		var id=j.get("construction_group",j.id)
		if not groups.has(id):groups[id]=[]
		groups[id].append(j)
	var pending={}
	for id in groups:
		if groups[id].any(func(j):return not can_build(j)):pending[id]=groups[id]
	if pending.is_empty():return
	var totals={};var stock={}
	preload("res://game/terrain_metrics.gd").count("construction_group_stock_rows",w.field_items.size())
	for row in w.field_items:
		if row.get("forbidden",false):continue
		if row.get("location")=="site":
			var token=str(row.job_id)+":"+row.kind
			totals[token]=totals.get(token,0)+row.amount
		elif row.get("location")=="ground" and (w.Stock.stored(w,row) or row.get("construction_transfer",false)):
			if not stock.has(row.kind):stock[row.kind]=[]
			stock[row.kind].append(row)
	var evaluators={}
	for id in pending:
		var members=pending[id];var missing=[];var missing_ids={};var filled=0
		for j in members:
			if j.get("required",w.BUILD[j.kind].cost)>totals.get(str(j.id)+":"+j.resource,0):missing.append(j);missing_ids[j.id]=true
			else:filled+=1
		var ready=missing.is_empty() or members.any(func(j):return can_build(j))
		if not ready and filled>0:
			# Actual in-flight reservations keep the barrier closed, including a
			# temporary worker interruption until its normal release callback.
			var possible=missing.any(func(j):return j.get("delivery_owner","")!="" and w.build_deliveries.has(j.delivery_owner))
			if not possible:
				for j in missing:
					if feasible(w,j,stock.get(j.resource,[]),evaluators):possible=true;break
			ready=not possible
		if ready:
			for j in members:
				j.construction_ready=true
				if j.get("block_reason","")==GROUP_WAIT:j.block_reason=""
			w.job_log.append({"tick":w.tick,"event":"construction_group_ready","group":id,"partial":not missing.is_empty()})
		else:
			for j in members:
				if not missing_ids.has(j.id) and not j.get("started",false):j.block_reason=GROUP_WAIT

static func feasible(w,j,rows: Array,evaluators: Dictionary) -> bool:
	var candidates=rows.filter(func(r):return Reservations.usable(w,r,j)>0)
	if candidates.is_empty():
		j.material_wait=true;j.block_reason="資材待ち：備蓄に使える資材がありません";return false
	var why=w.Buildings.reason(w,j.kind,j.pos,false,j.id) if not j.started else ""
	if why!="" and why!="ここに誰かいます":j.block_reason=why;return false
	var has_hauler=false
	for key in w.workers:
		var a=w.workers[key]
		# Rest, danger and an existing task do not make a potential hauler vanish.
		if a.work_priorities.get("haul",0)<=0 or not a.get("placed",false) or a.get("dead",false) or a.get("hp",0)<=0:continue
		if j.get("explicit_actor",key)!=key:continue
		has_hauler=true
		if why!="" and a.pos!=j.pos:continue
		if not evaluators.has(key):evaluators[key]=preload("res://game/job_evaluation.gd").new(w,a.pos)
		var evaluation=evaluators[key]
		if is_inf(evaluation.distance_to(w,w.Buildings.job_goals(w,j))):continue
		for row in candidates:
			if w.Access.can_take(w,row,a) and not is_inf(evaluation.distance_to(w,w.neighbors(row.pos))):return true
	j.block_reason="材料を搬入する通路がありません" if has_hauler else "資材搬入を担当する住人がいません"
	return false

# Only at legacy data restore boundaries, never in the per-tick scheduler.
static func migrate_wall_costs(w):
	for j in w.jobs:
		if j.kind not in w.Buildings.WALLS or int(j.get("required",j.get("reserved",0)))!=10:continue
		# Release in-flight claims and retain physical cargo at its current position.
		cancel_job(w,j)
		j.required=w.BUILD[j.kind].cost;j.reserved=0;j.physical=true
		var remaining=j.required
		for row in w.field_items.duplicate():
			if row.get("location")!="site" or row.get("job_id",-1)!=j.id or row.kind!=j.resource:continue
			var keep=mini(remaining,row.amount);var excess=row.amount-keep;remaining-=keep
			if excess>0:
				if keep==0:row.location="ground";row.job_id=-1;row.owner="";row.stocked=false;row.pos=surplus_cell(w,j.pos)
				else:
					row.amount=keep
					var returned=w.Stock.add(w,row.kind,excess,surplus_cell(w,j.pos))
					returned.stocked=false;returned.forbidden=row.get("forbidden",false)
		var site=w.Buildings.layer(w,j.kind).get(j.pos,{})
		if site.get("status")=="building":site.cost=j.required
		j.material_wait=w.Stock.delivered(w,j)<j.required
		j.block_reason="" # scheduler will re-evaluate; started work and group latch survive
	w.Stock.sync(w)

static func surplus_cell(w,origin: Vector2i) -> Vector2i:
	# Do not drop a cost-migration surplus on another active construction footprint.
	var reserved={}
	for pending in w.jobs:
		if w.BUILD.has(pending.kind):reserved[pending.pos]=true
	var seen={origin:true};var queue=[origin];var index=0
	while index<queue.size():
		var cell=queue[index];index+=1
		if cell!=origin and not reserved.has(cell):return cell
		for next in w.neighbors(cell):
			if not seen.has(next) and w.inside(next) and w.walkable(next):seen[next]=true;queue.append(next)
	return origin # fully sealed: preserve physical stock rather than deleting it
