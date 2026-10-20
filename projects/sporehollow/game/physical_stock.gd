extends RefCounted
const Policy=preload("res://game/work_policy.gd")
const MATERIALS=["soil","wood","stone"]

static func normalize(w):
	for row in w.field_items:
		if row.has("stock_id"):continue
		row.stock_id=w.next_stock_id;w.next_stock_id+=1
		row.amount=1;row.location="ground";row.owner="";row.job_id=-1;row.claims={}
		row.incubating=false

static func add(w,kind: String,amount: int,pos: Vector2i,location: String="ground",job_id: int=-1) -> Dictionary:
	if amount<=0:return {}
	var row={"stock_id":w.next_stock_id,"kind":kind,"amount":amount,"pos":pos,"location":location,"owner":"","job_id":job_id,"claims":{},"born_day":w.campaign.day,"incubating":false,"stocked":location=="ground" and w.Zones.accepts(w,pos,kind)}
	w.next_stock_id+=1;w.field_items.append(row);sync(w);return row

static func init(w):
	w.next_stock_id=int(w.campaign.get("next_stock_id",1))
	w.storage_cells=w.campaign.get("storage_cells",[]).map(func(p):return Vector2i(p[0],p[1]))
	normalize(w)
	if not w.campaign.get("physical_stock",false):
		var origin=w.logistics_entry
		var initial=[]
		for kind in MATERIALS:initial.append([kind,int(w.campaign.resources.get(kind,0))])
		for kind in w.campaign.items:initial.append([kind,int(w.campaign.items[kind])])
		initial.append(["egg",int(w.campaign.get("eggs",0))]);initial.append(["mushroom",int(w.campaign.get("mushrooms",0))])
		if w.campaign.get("initial_stockpile",false):
			# Put the existing first-day supply into the initial stockpile, not another pile at the entrance.
			if int(w.campaign.get("last_supply_day",0))<w.campaign.day:
				initial.append(["wood",8]);initial.append(["mushroom",3]);w.campaign.last_supply_day=w.campaign.day
			var sites=[];var center=Vector2i(w.W/2-2,w.H/2+2)
			for y in range(1,w.H-1):
				for x in range(1,w.W-1):
					var p=Vector2i(x,y)
					if not w.walkable(p) or w.occupied(p) or w.natural.has(p) or w.live_structure(p) or not w.items_at(p).is_empty():continue
					if x in [w.W/2-1,w.W/2] and y in [w.H/2-1,w.H/2]:continue
					sites.append(p)
			sites.sort_custom(func(a,b):return w.distance(a,center)<w.distance(b,center) if w.distance(a,center)!=w.distance(b,center) else (a.y*w.W+a.x)<(b.y*w.W+b.x))
			for entry in initial:
				var left=entry[1]
				while left>0 and not sites.is_empty():
					var p=sites.pop_front();var n=mini(left,Policy.STORAGE_CAPACITY)
					var row=add(w,entry[0],n,p);row.stocked=true;w.storage_cells.append(p);left-=n
				if left>0:add(w,entry[0],left,origin);w.say("初期備蓄の空きが足りません")
			w.campaign.storage_cells=w.storage_cells.map(func(p):return [p.x,p.y]);w.campaign.erase("initial_stockpile")
		else:
			for entry in initial:add(w,entry[0],entry[1],origin)
		for j in w.jobs:
			if not w.BUILD.has(j.kind):continue
			j.required=j.get("required",j.reserved)
			if j.reserved>0:add(w,j.resource,j.reserved,j.pos,"site",j.id)
			j.reserved=0;j.physical=true
	# Campaign saves release transient ownership; dedicated snapshots restore the full runtime.
	for row in w.field_items:
		row.claims={}
		if row.location=="carry":
			row.location="ground";row.owner=""
			if not (row.get("construction_transfer",false) or row.get("craft_transfer",false)) or not w.jobs.any(func(j):return j.id==row.job_id):row.job_id=-1;row.erase("construction_transfer");row.erase("craft_transfer")
	w.campaign.physical_stock=true;w.Zones.init(w);migrate_storage(w);sync(w)

static func free_count(row) -> int:
	if row.get("forbidden",false):return 0
	var reserved=0
	for n in row.get("claims",{}).values():reserved+=n
	return maxi(0,row.get("amount",1)-reserved)

static func migrate_storage(w):
	# Existing saves retain every position/quantity; only old rows already in storage acquire the receipt flag.
	for row in w.field_items:
		if not row.has("stocked"):row.stocked=row.get("location","ground")=="ground" and w.Zones.accepts(w,row.pos,row.kind)

static func stored(w,row) -> bool:
	return row.get("location","ground")=="ground" and row.get("stocked",false) and w.Zones.accepts(w,row.pos,row.kind)

static func eligible(w,row,storage_only: bool=true) -> bool:
	if row.get("location","ground")!="ground" or row.get("placed",false) or row.get("construction_transfer",false) or row.get("craft_transfer",false) or free_count(row)<=0:return false
	return not storage_only or preload("res://game/item_catalog.gd").item(row.kind).category not in ["resource","food"] or stored(w,row)

static func available(w,kind: String) -> int:
	var n=0
	for row in w.field_items:
		if row.kind==kind and eligible(w,row):n+=free_count(row)
	return n

static func sync(w):
	w.stock_revision+=1
	if not w.campaign.get("physical_stock",false):return
	var counts={}
	for row in w.field_items:
		if eligible(w,row):counts[row.kind]=counts.get(row.kind,0)+free_count(row)
	w.materials=counts.get("soil",0);w.wood=counts.get("wood",0);w.stone=counts.get("stone",0)
	w.campaign.resources={"soil":w.materials,"wood":w.wood,"stone":w.stone}
	w.campaign.eggs=counts.get("egg",0);w.campaign.mushrooms=counts.get("mushroom",0)
	for kind in MATERIALS+["egg","mushroom"]:counts.erase(kind)
	w.campaign.items=counts

static func consume(w,kind: String,amount: int,actor:Dictionary={}) -> bool:
	if actor.is_empty():actor=w.keeper
	normalize(w)
	if w.field_items.filter(func(r):return r.kind==kind and eligible(w,r) and w.Access.can_take(w,r,actor)).reduce(func(n,r):return n+free_count(r),0)<amount:return false
	var remaining=amount
	for row in w.field_items.duplicate():
		if row.kind!=kind or not eligible(w,row) or not w.Access.can_take(w,row,actor):continue
		var used=mini(remaining,free_count(row));row.amount-=used;remaining-=used
		if row.amount==0:w.field_items.erase(row)
		if remaining==0:break
	w.stock_used[kind]=w.stock_used.get(kind,0)+amount
	sync(w);return true

static func find(w,id: int) -> Dictionary:
	for row in w.field_items:
		if row.get("stock_id",-1)==id:return row
	return {}

static func release_token(w,token: String):
	for row in w.field_items:row.get("claims",{}).erase(token)
	sync(w)

static func reserve(w,kind: String,amount: int,token: String,actor: Dictionary,specific: int=-1,storage_only: bool=true) -> Array:
	normalize(w)
	var rows=w.field_items.filter(func(r):return r.kind==kind and eligible(w,r,storage_only) and w.Access.can_take(w,r,actor) and (specific<0 or r.stock_id==specific))
	rows.sort_custom(func(a,b):return w.distance(actor.pos,a.pos)<w.distance(actor.pos,b.pos) if w.distance(actor.pos,a.pos)!=w.distance(actor.pos,b.pos) else a.stock_id<b.stock_id)
	var result=[];var remaining=amount
	for row in rows:
		if w.Jobs.path_to(w,actor.pos,w.neighbors(row.pos).filter(func(p):return w.walkable(p))).is_empty():continue
		var n=mini(remaining,free_count(row));row.claims[token]=row.claims.get(token,0)+n
		result.append({"stock_id":row.stock_id,"amount":n});remaining-=n
		if remaining==0:break
	sync(w);return result

static func carry_free(w,key: String) -> int:
	var count=0
	for row in cargo(w,key):count+=row.amount
	return maxi(0,Policy.CARRY_CAPACITY-count)

static func pickup(w,row,token: String,actor: Dictionary,job_id: int) -> Dictionary:
	if not w.Access.can_take(w,row,actor):row.get("claims",{}).erase(token);sync(w);return {}
	var n=int(row.get("claims",{}).get(token,0))
	if n<=0 or n>row.amount or n>carry_free(w,w.Sleep.actor_key(actor)) or row.location!="ground" or row.get("forbidden",false):return {}
	row.claims.erase(token);row.amount-=n
	var carried=row.duplicate(true);carried.stock_id=w.next_stock_id;w.next_stock_id+=1;carried.amount=n;carried.claims={}
	carried.location="carry";carried.owner=w.Sleep.actor_key(actor);carried.job_id=job_id;carried.pos=actor.pos;carried.incubating=false
	if row.amount==0:w.field_items.erase(row)
	w.field_items.append(carried);sync(w);return carried

static func cargo(w,key: String,job_id: int=-999) -> Array:
	return w.field_items.filter(func(r):return r.get("location")=="carry" and r.owner==key and (job_id==-999 or r.job_id==job_id))

static func release_job(w,j):
	j.erase("storage_target");j.erase("storage_amount")
	release_token(w,"job:%d"%j.id)
	for row in w.field_items:
		if row.get("job_id",-1)!=j.id or row.get("location")!="carry":continue
		if w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
		row.location="ground";row.owner="";row.job_id=j.id if j.kind=="craft" else -1;row.erase("construction_transfer")
		if j.kind=="haul":
			j.haul_sources=j.get("haul_sources",[j.stock_id])
			if row.stock_id not in j.haul_sources:j.haul_sources.append(row.stock_id)
	j.erase("material_claims");sync(w)

static func delivered(w,j) -> int:
	var n=0
	for kind in w.Buildings.Cost.materials(w,j.kind,j):n+=mini(w.Buildings.Cost.materials(w,j.kind,j)[kind],w.Buildings.Cost.onsite(w,j,kind))
	return n

static func prepare_build(w,j,_a) -> bool:
	j.physical=true
	if not w.Delivery.can_build(j):
		j.state="pending";j.block_reason=w.Delivery.GROUP_WAIT;return false
	if delivered(w,j)>=j.get("required",w.BUILD[j.kind].cost):return true
	j.state="pending";j.block_reason="備蓄から材料の搬入を待っています";return false

static func finish_build(w,j,success: bool):
	w.Stock.release_token(w,preload("res://game/build_reservations.gd").token(j))
	var remaining=w.Buildings.Cost.materials(w,j.kind,j)
	for row in w.field_items.duplicate():
		if row.get("location")!="site" or row.job_id!=j.id:continue
		if row.get("forbidden",false):row.location="ground";row.owner="";row.job_id=-1;row.stocked=false;row.erase("forbidden_reconciled")
		elif success:
			var used=mini(int(remaining.get(row.kind,0)),row.amount)
			remaining[row.kind]=remaining.get(row.kind,0)-used;row.amount-=used;w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+used
			if row.amount==0:w.field_items.erase(row)
			else:row.location="ground";row.owner="";row.job_id=-1;row.stocked=false
		else:
			var refund=floori(row.amount*w.Rules.INTERRUPT_REFUND) if j.started else row.amount
			w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+row.amount-refund
			row.amount=refund;row.location="ground";row.job_id=-1;row.stocked=false;row.claims={}
			row.erase("construction_transfer")
			if refund==0:w.field_items.erase(row)
	sync(w)

static func storage_used(w,pos: Vector2i) -> int:
	var n=0
	for row in w.field_items:
		if row.get("location","ground")=="ground" and row.pos==pos:n+=row.get("amount",1)
	return n

static func storage_free(w,pos: Vector2i,except_job: int=-1) -> int:
	var reserved=0
	for j in w.jobs+w.Work.Ambient.jobs(w):
		if j.id!=except_job and j.get("storage_target")==pos:reserved+=int(j.get("storage_amount",0))
	return maxi(0,Policy.STORAGE_CAPACITY-storage_used(w,pos)-reserved)

static func storage_plan(w,a,amount: int,kind: String,job_id: int=-1) -> Dictionary:
	var priorities=w.Zones.priority_map(w,kind)
	var eligible=priorities.keys() if not w.zones.is_empty() else w.storage_cells
	if eligible.is_empty():return {"reason":"この物資を受け入れる備蓄がありません"}
	var cells=eligible.filter(func(p):return w.walkable(p) and storage_free(w,p,job_id)>0)
	if cells.is_empty():return {"reason":"備蓄が満杯です"}
	var same={}
	for row in w.field_items:
		if row.kind==kind and stored(w,row):same[row.pos]=true
	var old=null
	for j in w.jobs+w.Work.Ambient.jobs(w):
		if j.id==job_id:old=j.get("storage_target")
	cells.sort_custom(func(x,y):return priorities.get(x,1)>priorities.get(y,1) if priorities.get(x,1)!=priorities.get(y,1) else x==old if x==old or y==old else (same.has(x) if same.has(x)!=same.has(y) else (w.distance(a.pos,x)<w.distance(a.pos,y) if w.distance(a.pos,x)!=w.distance(a.pos,y) else x.y*w.W+x.x<y.y*w.W+y.x)))
	for p in cells:
		var goals=w.neighbors(p)+([p] if a.pos==p else [])
		if not w.Jobs.path_to(w,a.pos,goals,false,true).is_empty():return {"pos":p,"amount":mini(amount,storage_free(w,p,job_id)),"reason":""}
	return {"reason":"備蓄への通路がふさがっています"}

static func destination(w,a,amount: int,kind: String="") -> Variant:
	return storage_plan(w,a,amount,kind).get("pos")

static func haul_step(w,j,a):
	var carried=cargo(w,a.work_key,j.id)
	if not carried.is_empty():
		var n=0
		for row in carried:n+=row.amount
		var plan=storage_plan(w,a,n,carried[0].kind,j.id)
		if not plan.has("pos"):j.state="blocked";j.block_reason=plan.reason;return
		var dest=plan.pos;j.storage_target=dest;j.storage_amount=plan.amount;j.phase="deliver"
		if not w.Jobs.walk(w,j,w.neighbors(dest)+([dest] if a.pos==dest else []),a):return
		var left=mini(n,storage_free(w,dest,j.id))
		if left<=0:j.state="blocked";j.block_reason="備蓄が満杯です";return
		for row in carried:
			var count=mini(left,row.amount)
			if count<=0:break
			if count==row.amount:row.location="ground";row.pos=dest;row.owner="";row.job_id=-1;row.stocked=true
			else:row.amount-=count;add(w,row.kind,count,dest).stocked=true
			left-=count
		j.erase("storage_target");j.erase("storage_amount");sync(w)
		if not cargo(w,a.work_key,j.id).is_empty():return
		if j.get("personal",false):w.Jobs.complete(w,j,true);return
		if j.get("haul_sources",[j.stock_id]).any(func(id):return not find(w,id).is_empty() and not stored(w,find(w,id))):j.state="walking";j.phase="fetch"
		else:w.Jobs.complete(w,j,true)
		return
	var sources=j.get("haul_sources",[j.stock_id]).map(func(id):return find(w,id)).filter(func(row):return not row.is_empty() and not stored(w,row))
	var eligible=sources.filter(func(row):return not row.get("forbidden",false) and row.get("location")=="ground" and free_count(row)>0)
	var row=eligible[0] if not eligible.is_empty() else (sources[0] if not sources.is_empty() else {})
	if row.is_empty() or row.kind=="chick":w.Jobs.complete(w,j,false);return
	j.stock_id=row.stock_id;j.pos=row.pos
	if row.get("forbidden",false):j.state="blocked";j.block_reason="対象の物資は禁止中です";return
	var token="job:%d"%j.id
	var requested=mini(carry_free(w,a.work_key),free_count(row)+int(row.claims.get(token,0)))
	var plan=storage_plan(w,a,requested,row.kind,j.id)
	if not plan.has("pos") or plan.amount<=0:j.state="blocked";j.block_reason=plan.get("reason","物資は別の人が使用中です");return
	j.storage_target=plan.pos;j.storage_amount=plan.amount
	if row.claims.get(token,0)!=plan.amount:
		release_token(w,token)
		if reserve(w,row.kind,plan.amount,token,a,row.stock_id,false).is_empty():j.erase("storage_target");j.erase("storage_amount");j.state="blocked";j.block_reason="物資は別の人が使用中です";return
	j.phase="fetch"
	if not w.Jobs.walk(w,j,w.neighbors(row.pos)+([row.pos] if a.pos==row.pos else []),a):return
	pickup(w,row,token,a,j.id);j.state="working"

static func step(w):
	normalize(w)
	reconcile_forbidden(w)
	for row in w.field_items:
		if row.location=="carry":
			if w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
			else:row.location="ground";row.owner="";row.job_id=-1
		for token in row.claims.keys():
			if token.begins_with("food:") and not w.workers.has(token.trim_prefix("food:")):row.claims.erase(token)
	# Storage zones choose destinations; only an explicit collection designation starts hauling.
	sync(w)

static func save(w):
	w.Zones.save(w)
	w.campaign.physical_stock=true;w.campaign.next_stock_id=w.next_stock_id
	w.campaign.storage_cells=w.storage_cells.map(func(p):return [p.x,p.y])
	w.campaign.stock_used=w.stock_used.duplicate()

static func totals(w) -> Dictionary:
	var result={}
	for a in w.workers.values():
		if not a.get("equipment",{}).is_empty():result[a.equipment.item_id]=result.get(a.equipment.item_id,0)+1
	for a in w.workers.values():
		if not a.get("clothing",{}).is_empty():result[a.clothing.item_id]=result.get(a.clothing.item_id,0)+1
	for row in w.field_items:result[row.kind]=result.get(row.kind,0)+row.get("amount",1)
	for a in w.animals.filter(func(a):return not w.workers.has("a%d"%a.id)):
		if not a.get("equipment",{}).is_empty():result[a.equipment.item_id]=result.get(a.equipment.item_id,0)+1
	for e in w.enemies:
		if not e.get("stolen",{}).is_empty():result[e.stolen.kind]=result.get(e.stolen.kind,0)+e.stolen.get("amount",1)
	return result

static func command_pos(w,row) -> Vector2i:
	return w.workers[row.owner].pos if row.get("location")=="carry" and w.workers.has(row.get("owner","")) else row.pos

static func command_targets(w,first: Vector2i,last: Vector2i,kind: String) -> Array:
	normalize(w)
	var result=[]
	for row in w.field_items:
		var p=command_pos(w,row)
		if not w.inside(p) or row.kind=="chick" or row.get("placed",false):continue
		if p.x<mini(first.x,last.x) or p.x>maxi(first.x,last.x) or p.y<mini(first.y,last.y) or p.y>maxi(first.y,last.y):continue
		if kind=="haul" and (row.location!="ground" or row.get("forbidden",false) or row.get("construction_transfer",false) or row.get("craft_transfer",false) or stored(w,row)):continue
		if kind=="forbid" and row.get("forbidden",false):continue
		if kind=="allow" and not row.get("forbidden",false):continue
		result.append(row)
	return result

static func enqueue_haul(w,row) -> bool:
	if not w.working() or row.get("forbidden",false) or row.location!="ground" or row.get("placed",false) or row.get("construction_transfer",false) or row.get("craft_transfer",false) or stored(w,row) or row.kind=="chick" or w.jobs.size()>=w.Jobs.LIMIT:return false
	if w.jobs.any(func(j):return j.get("stock_id",-1)==row.stock_id or row.stock_id in j.get("haul_sources",[])):return false
	w.jobs.append({"id":w.next_job_id,"kind":"haul","pos":row.pos,"stock_id":row.stock_id,"animal_id":-1,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"haul","explicit_designation":true});w.next_job_id+=1;w.Life.wake_auto(w);return true

static func cancel_targets(w,first: Vector2i,last: Vector2i) -> Array:
	var rows=[]
	for j in w.jobs:
		if j.get("cancel_requested",false):continue
		var p=j.pos
		if w.BUILD.has(j.kind):
			var bounds=Rect2i(Vector2i(mini(first.x,last.x),mini(first.y,last.y)),Vector2i(absi(last.x-first.x)+1,absi(last.y-first.y)+1))
			if w.Buildings.cells(j.kind,j.pos).any(func(q):return bounds.has_point(q)):rows.append(j)
			continue
		if j.has("mountain_id"):
			if w.Mountains.overlapping(w.mountains[j.mountain_id],first,last):rows.append(j)
			continue
		if j.kind in ["train","slaughter"]:
			var a=w.Orders.animal(w,j.animal_id)
			if not a.is_empty():p=a.pos
		if p.x>=mini(first.x,last.x) and p.x<=maxi(first.x,last.x) and p.y>=mini(first.y,last.y) and p.y<=maxi(first.y,last.y):rows.append(j)
	return rows

static func designate(w,kind: String,first: Vector2i,last: Vector2i) -> Dictionary:
	if kind in w.Harvest.KINDS:return w.Harvest.designate(w,kind,first,last) if w.working() else {"accepted":0,"skipped":0}
	if kind=="clear":
		if not w.working():return {"accepted":0,"skipped":0}
		var accepted=0;var targets=cancel_targets(w,first,last)
		for j in targets.duplicate():
			if w.Jobs.cancel(w,j.id):accepted+=1
		return {"accepted":accepted,"skipped":targets.size()-accepted}
	if kind not in ["haul","forbid","allow"] or not w.working():return {"accepted":0,"skipped":0}
	if kind=="haul":
		var locked=w.field_items.any(func(r):return construction_locked(r) and Rect2i(Vector2i(mini(first.x,last.x),mini(first.y,last.y)),Vector2i(absi(last.x-first.x)+1,absi(last.y-first.y)+1)).has_point(r.pos))
		if locked:
			var message="現場用に確保した資材は回収できません。先に作業予約をキャンセルしてください"
			w.say(message);w.PlayerEvents.add(w,message)
	var rows=command_targets(w,first,last,kind);var accepted=w.Harvest.forbid(w,first,last,kind=="forbid") if kind in ["forbid","allow"] else 0
	if kind in ["forbid","allow"]:
		var area=Rect2i(Vector2i(mini(first.x,last.x),mini(first.y,last.y)),Vector2i(absi(last.x-first.x)+1,absi(last.y-first.y)+1))
		for p in w.natural:
			if not area.has_point(p) or w.natural_forbidden.get(p,false)==(kind=="forbid"):continue
			if kind=="forbid":w.natural_forbidden[p]=true
			else:w.natural_forbidden.erase(p)
			accepted+=1
			for j in w.jobs:
				if j.kind=="collect" and j.pos==p:
					if kind=="forbid":w.Work.block(w,j,"採集対象は禁止中です")
					else:j.retry_at=w.tick
		for a in w.animals:
			if area.has_point(a.pos) and a.get("forbidden",false)!=(kind=="forbid") and w.Livestock.set_forbidden(w,a.id,kind=="forbid"):accepted+=1
	var object_accepted=accepted
	for row in rows:
		if kind=="haul":
			if enqueue_haul(w,row):accepted+=1
		else:
			row.forbidden=kind=="forbid";row.erase("forbidden_reconciled");accepted+=1
	reconcile_forbidden(w);sync(w)
	return {"accepted":accepted,"skipped":rows.size()-(accepted-object_accepted)}

static func reconcile_forbidden(w):
	var affected=[];var food_owners=[]
	for row in w.field_items:
		if not row.get("forbidden",false):continue
		for token in row.get("claims",{}):
			if token.begins_with("job:"):affected.append(int(token.trim_prefix("job:")))
			elif token.begins_with("food:"):food_owners.append(token.trim_prefix("food:"))
		row.claims={}
		if row.get("job_id",-1)>=0 and (row.get("location")!="site" or not row.get("forbidden_reconciled",false)):affected.append(row.job_id)
		if row.get("job_id",-1)==-2:food_owners.append(row.owner)
		if row.get("location")=="site":row.forbidden_reconciled=true
	for j in w.jobs.duplicate():
		if j.id in affected:w.Work.block(w,j,"予約した物資は禁止中です。代替を探します")
	for owner in food_owners:
		if w.workers.has(owner):w.Food.interrupt(w,w.workers[owner]);w.workers[owner].work_status="食料は禁止中です。別の食料を探します"

# Physical ownership is independent of availability, stockpile location and reservations.
static func summary(w,kind: String) -> Dictionary:
	var q={"owned":0,"stored":0,"available":available(w,kind),"carried":0,"site":0,"reserved":0,"outside":0,"equipped":0,"stolen":0,"forbidden":0}
	for row in w.field_items:
		if row.kind!=kind:continue
		var n=int(row.get("amount",1));q.owned+=n
		if row.get("forbidden",false):q.forbidden+=n
		match row.get("location","ground"):
			"carry":q.carried+=n
			"site":q.site+=n
			_:
				if stored(w,row):q.stored+=n
				else:q.outside+=n
		var claimed=0
		for amount in row.get("claims",{}).values():claimed+=int(amount)
		q.reserved+=mini(n,claimed)
	for a in w.workers.values()+w.animals.filter(func(a):return not w.workers.has("a%d"%a.id)):
		if a.get("equipment",{}).get("item_id","")==kind:q.equipped+=1;q.owned+=1
	for a in w.workers.values():
		if a.get("clothing",{}).get("item_id","")==kind:q.equipped+=1;q.owned+=1
	for e in w.enemies:
		if e.get("stolen",{}).get("kind","")==kind:q.stolen+=int(e.stolen.get("amount",1))
	return q

# Explicit one-click physical refill; extensible only with catalogued item IDs.
static func debug_replenish(w,kinds: Array=MATERIALS) -> Dictionary:
	if not w.debug_enabled:return {}
	var result={};var added=[];var missing=[]
	for kind in kinds:
		if result.has(kind) or not preload("res://game/item_catalog.gd").ROWS.has(kind) or preload("res://game/item_catalog.gd").item(kind).category!="resource":continue
		var left=40;var reason=""
		while left>0:
			var plan=storage_plan(w,w.keeper,left,kind)
			if not plan.has("pos"):reason=plan.reason;break
			var n=mini(left,plan.amount)
			if n<=0:reason="備蓄が満杯です";break
			var stack={}
			for row in w.field_items:
				if row.kind==kind and row.pos==plan.pos and stored(w,row) and not row.get("forbidden",false) and not row.get("placed",false) and not row.get("construction_transfer",false) and not row.get("craft_transfer",false):stack=row;break
			if stack.is_empty():add(w,kind,n,plan.pos).stocked=true
			else:stack.amount+=n;sync(w)
			left-=n
		var name={"soil":"土","wood":"木材","stone":"石材"}.get(kind,kind)
		result[kind]={"added":40-left,"missing":left,"reason":reason}
		if left<40:added.append("%s%d"%[name,40-left])
		if left>0:missing.append("%s%d：%s"%[name,left,reason])
	var message="デバッグ補充："+("・".join(added)+"を追加" if not added.is_empty() else "追加なし")
	if not missing.is_empty():message+="。"+"／".join(missing)
	w.PlayerEvents.add(w,message);w.say(message);return result

static func construction_locked(row) -> bool:
	return row.get("location")=="site" or row.get("construction_transfer",false)

static func collection_reason(w,p:Vector2i) -> String:
	if w.natural.has(p) and not w.natural_forbidden.get(p,false):return ""
	var locked=false
	for row in w.field_items:
		if row.pos!=p:continue
		if construction_locked(row):locked=true
		elif row.get("location")=="ground" and not row.get("forbidden",false) and not row.get("craft_transfer",false) and not row.get("placed",false) and not stored(w,row):return ""
	return "現場用に確保した資材です。回収するには作業予約をキャンセルしてください" if locked else ""
