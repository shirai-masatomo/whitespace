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
	var row={"stock_id":w.next_stock_id,"kind":kind,"amount":amount,"pos":pos,"location":location,"owner":"","job_id":job_id,"claims":{},"born_day":w.campaign.day,"incubating":false}
	w.next_stock_id+=1;w.field_items.append(row);sync(w);return row

static func init(w):
	w.next_stock_id=int(w.campaign.get("next_stock_id",1))
	w.storage_cells=w.campaign.get("storage_cells",[]).map(func(p):return Vector2i(p[0],p[1]))
	normalize(w)
	if not w.campaign.get("physical_stock",false):
		var origin=w.logistics_entry
		if w.campaign.get("start_near_idol",false):
			for p in [w.keeper.pos+Vector2i.DOWN]+w.neighbors(w.keeper.pos):
				if w.walkable(p) and not w.occupied(p) and not w.natural.has(p):origin=p;break
		for kind in MATERIALS:add(w,kind,w.campaign.resources.get(kind,0),origin)
		for kind in w.campaign.items:add(w,kind,w.campaign.items[kind],origin)
		add(w,"egg",w.campaign.get("eggs",0),origin)
		add(w,"mushroom",w.campaign.get("mushrooms",0),origin)
		for j in w.jobs:
			if not w.BUILD.has(j.kind):continue
			j.required=j.get("required",j.reserved)
			if j.reserved>0:add(w,j.resource,j.reserved,j.pos,"site",j.id)
			j.reserved=0;j.physical=true
	# Campaign saves release transient ownership; dedicated snapshots restore the full runtime.
	for row in w.field_items:
		row.claims={}
		if row.location=="carry":row.location="ground";row.owner="";row.job_id=-1
	w.campaign.physical_stock=true;w.Zones.init(w);sync(w)

static func free_count(row) -> int:
	if row.get("forbidden",false):return 0
	var reserved=0
	for n in row.get("claims",{}).values():reserved+=n
	return maxi(0,row.get("amount",1)-reserved)

static func available(w,kind: String) -> int:
	var n=0
	for row in w.field_items:
		if row.kind==kind and row.get("location","ground")=="ground" and not row.get("placed",false):n+=free_count(row)
	return n

static func sync(w):
	if not w.campaign.get("physical_stock",false):return
	w.materials=available(w,"soil");w.wood=available(w,"wood");w.stone=available(w,"stone")
	w.campaign.resources={"soil":w.materials,"wood":w.wood,"stone":w.stone}
	w.campaign.eggs=available(w,"egg");w.campaign.mushrooms=available(w,"mushroom")
	var counts={}
	for row in w.field_items:
		if row.kind not in MATERIALS+["egg","mushroom"]:counts[row.kind]=available(w,row.kind)
	w.campaign.items=counts

static func consume(w,kind: String,amount: int) -> bool:
	normalize(w)
	if available(w,kind)<amount:return false
	var remaining=amount
	for row in w.field_items.duplicate():
		if row.kind!=kind or row.location!="ground" or row.get("placed",false):continue
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

static func reserve(w,kind: String,amount: int,token: String,actor: Dictionary,specific: int=-1) -> Array:
	normalize(w)
	var rows=w.field_items.filter(func(r):return r.kind==kind and r.location=="ground" and not r.get("placed",false) and free_count(r)>0 and (specific<0 or r.stock_id==specific))
	rows.sort_custom(func(a,b):return w.distance(actor.pos,a.pos)<w.distance(actor.pos,b.pos) if w.distance(actor.pos,a.pos)!=w.distance(actor.pos,b.pos) else a.stock_id<b.stock_id)
	var result=[];var remaining=amount
	for row in rows:
		if w.Jobs.path_to(w,actor.pos,w.neighbors(row.pos).filter(func(p):return w.walkable(p))).is_empty():continue
		var n=mini(remaining,free_count(row));row.claims[token]=row.claims.get(token,0)+n
		result.append({"stock_id":row.stock_id,"amount":n});remaining-=n
		if remaining==0:break
	sync(w);return result

static func pickup(w,row,token: String,actor: Dictionary,job_id: int) -> Dictionary:
	var n=int(row.get("claims",{}).get(token,0))
	if n<=0 or n>row.amount or row.location!="ground" or row.get("forbidden",false):return {}
	row.claims.erase(token);row.amount-=n
	var carried=row.duplicate(true);carried.stock_id=w.next_stock_id;w.next_stock_id+=1;carried.amount=n;carried.claims={}
	carried.location="carry";carried.owner=actor.work_key;carried.job_id=job_id;carried.pos=actor.pos;carried.incubating=false
	if row.amount==0:w.field_items.erase(row)
	w.field_items.append(carried);sync(w);return carried

static func cargo(w,key: String,job_id: int=-999) -> Array:
	return w.field_items.filter(func(r):return r.get("location")=="carry" and r.owner==key and (job_id==-999 or r.job_id==job_id))

static func release_job(w,j):
	release_token(w,"job:%d"%j.id)
	for row in w.field_items:
		if row.get("job_id",-1)!=j.id or row.get("location")!="carry":continue
		if w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
		row.location="ground";row.owner="";row.job_id=-1
	j.erase("material_claims");sync(w)

static func delivered(w,j) -> int:
	var n=0
	for row in w.field_items:
		if row.get("location")=="site" and row.job_id==j.id and row.kind==j.resource and not row.get("forbidden",false):n+=row.amount
	return n

static func prepare_build(w,j,a) -> bool:
	j.physical=true
	var required=j.get("required",w.BUILD[j.kind].cost)
	if delivered(w,j)>=required:return true
	var carried=cargo(w,a.work_key,j.id)
	if not carried.is_empty():
		j.phase="deliver"
		if not w.Jobs.walk(w,j,w.neighbors(j.pos),a):return false
		for row in carried:row.location="site";row.owner="";row.pos=j.pos
		j.state="working";sync(w);return false
	var token="job:%d"%j.id
	if j.get("material_claims",[]).is_empty():j.material_claims=reserve(w,j.resource,mini(Policy.CARRY_CAPACITY,required-delivered(w,j)),token,a)
	if j.material_claims.is_empty():j.state="blocked";j.block_reason="資材不足・届く場所の資材を待つ";return false
	var row=find(w,j.material_claims[0].stock_id)
	if row.is_empty() or row.get("forbidden",false) or row.claims.get(token,0)<=0:j.erase("material_claims");j.state="blocked";j.block_reason="予約した資材がなくなりました";return false
	j.phase="fetch"
	if not w.Jobs.walk(w,j,w.neighbors(row.pos),a):return false
	pickup(w,row,token,a,j.id);j.material_claims.pop_front();j.state="working";return false

static func finish_build(w,j,success: bool):
	for row in w.field_items.duplicate():
		if row.get("location")!="site" or row.job_id!=j.id:continue
		if row.get("forbidden",false):row.location="ground";row.owner="";row.job_id=-1;row.erase("forbidden_reconciled")
		elif success:w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+row.amount;w.field_items.erase(row)
		else:
			var refund=floori(row.amount*w.Rules.INTERRUPT_REFUND) if j.started else row.amount
			w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+row.amount-refund
			row.amount=refund;row.location="ground";row.job_id=-1
			if refund==0:w.field_items.erase(row)
	sync(w)

static func storage_used(w,pos: Vector2i) -> int:
	var n=0
	for row in w.field_items:
		if row.get("location","ground")=="ground" and row.pos==pos:n+=row.get("amount",1)
	return n

static func destination(w,a,amount: int,kind: String="") -> Variant:
	var eligible=w.Zones.storage_for(w,kind) if kind!="" and not w.zones.is_empty() else w.storage_cells
	var cells=eligible.filter(func(p):return w.walkable(p) and storage_used(w,p)+amount<=Policy.STORAGE_CAPACITY)
	cells.sort_custom(func(x,y):return w.distance(a.pos,x)<w.distance(a.pos,y))
	for p in cells:
		if not w.Jobs.path_to(w,a.pos,w.neighbors(p).filter(func(c):return w.walkable(c))).is_empty():return p
	return null

static func haul_step(w,j,a):
	var carried=cargo(w,a.work_key,j.id)
	if not carried.is_empty():
		var n=0
		for row in carried:n+=row.amount
		var dest=destination(w,a,n,carried[0].kind)
		if dest==null:j.state="blocked";j.block_reason="許可された備蓄が満杯か到達できません";return
		j.phase="deliver"
		if not w.Jobs.walk(w,j,w.neighbors(dest),a):return
		# Sequential execution rechecks capacity here; a second worker never overfills it.
		if storage_used(w,dest)+n>Policy.STORAGE_CAPACITY:j.state="blocked";j.block_reason="保管域が満杯です";return
		for row in carried:row.location="ground";row.pos=dest;row.owner="";row.job_id=-1
		sync(w);w.Jobs.complete(w,j,true);return
	var row=find(w,j.get("stock_id",-1))
	if row.is_empty() or row.kind=="chick":w.Jobs.complete(w,j,false);return
	if row.get("forbidden",false):j.state="blocked";j.block_reason="対象の物資は禁止中です";return
	var token="job:%d"%j.id
	if row.claims.get(token,0)<=0:
		if destination(w,a,mini(Policy.CARRY_CAPACITY,free_count(row)),row.kind)==null:j.state="blocked";j.block_reason="この種類を許可する備蓄を指定してください";return
		if reserve(w,row.kind,Policy.CARRY_CAPACITY,token,a,row.stock_id).is_empty():j.state="blocked";j.block_reason="物資は別の人が使用中です";return
	j.phase="fetch"
	if not w.Jobs.walk(w,j,w.neighbors(row.pos),a):return
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
	if not w.keeper.get("equipment",{}).is_empty():result[w.keeper.equipment.item_id]=1
	for row in w.field_items:result[row.kind]=result.get(row.kind,0)+row.get("amount",1)
	for a in w.animals:
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
		if kind=="haul" and (row.location!="ground" or row.get("forbidden",false)):continue
		if kind=="forbid" and row.get("forbidden",false):continue
		if kind=="allow" and not row.get("forbidden",false):continue
		result.append(row)
	return result

static func enqueue_haul(w,row) -> bool:
	if not w.working() or row.get("forbidden",false) or row.location!="ground" or row.get("placed",false) or row.kind=="chick" or w.jobs.size()>=w.Jobs.LIMIT:return false
	if w.jobs.any(func(j):return j.get("stock_id",-1)==row.stock_id):return false
	w.jobs.append({"id":w.next_job_id,"kind":"haul","pos":row.pos,"stock_id":row.stock_id,"animal_id":-1,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"haul","explicit_designation":true});w.next_job_id+=1;w.Life.wake_auto(w);return true

static func designate(w,kind: String,first: Vector2i,last: Vector2i) -> Dictionary:
	if kind not in ["haul","forbid","allow"] or not w.working():return {"accepted":0,"skipped":0}
	var rows=command_targets(w,first,last,kind);var accepted=0
	for row in rows:
		if kind=="haul":
			if enqueue_haul(w,row):accepted+=1
		else:
			row.forbidden=kind=="forbid";row.erase("forbidden_reconciled");accepted+=1
	reconcile_forbidden(w);sync(w)
	return {"accepted":accepted,"skipped":rows.size()-accepted}

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
