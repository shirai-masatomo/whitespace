extends RefCounted
const Policy=preload("res://game/work_policy.gd")
const MATERIALS=["soil","wood","stone"]

static func normalize(w):
	for row in w.field_items:
		if row.has("stock_id"):continue
		row.stock_id=w.next_stock_id;w.next_stock_id+=1
		row.amount=1;row.location="ground";row.owner="";row.job_id=-1;row.claims={}
		row.incubating=row.kind in ["egg","chick"]

static func add(w,kind: String,amount: int,pos: Vector2i,location: String="ground",job_id: int=-1) -> Dictionary:
	if amount<=0:return {}
	var row={"stock_id":w.next_stock_id,"kind":kind,"amount":amount,"pos":pos,"location":location,"owner":"","job_id":job_id,"claims":{},"born_day":w.campaign.day,"incubating":false}
	w.next_stock_id+=1;w.field_items.append(row);sync(w);return row

static func init(w):
	w.next_stock_id=int(w.campaign.get("next_stock_id",1))
	w.storage_cells=w.campaign.get("storage_cells",[]).map(func(p):return Vector2i(p[0],p[1]))
	normalize(w)
	if not w.campaign.get("physical_stock",false):
		for kind in MATERIALS:add(w,kind,w.campaign.resources.get(kind,0),w.logistics_entry)
		for kind in w.campaign.items:add(w,kind,w.campaign.items[kind],w.logistics_entry)
		add(w,"egg",w.campaign.get("eggs",0),w.logistics_entry)
		add(w,"mushroom",w.campaign.get("mushrooms",0),w.logistics_entry)
		for j in w.jobs:
			if not w.BUILD.has(j.kind):continue
			j.required=j.get("required",j.reserved)
			if j.reserved>0:add(w,j.resource,j.reserved,j.pos,"site",j.id)
			j.reserved=0;j.physical=true
	# Campaign saves release transient ownership; dedicated snapshots restore the full runtime.
	for row in w.field_items:
		row.claims={}
		if row.location=="carry":row.location="ground";row.owner="";row.job_id=-1
	w.campaign.physical_stock=true;sync(w)

static func free_count(row) -> int:
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
	if n<=0 or n>row.amount or row.location!="ground":return {}
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
		if row.get("location")=="site" and row.job_id==j.id and row.kind==j.resource:n+=row.amount
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
	if row.is_empty() or row.claims.get(token,0)<=0:j.erase("material_claims");j.state="blocked";j.block_reason="予約した資材がなくなりました";return false
	j.phase="fetch"
	if not w.Jobs.walk(w,j,w.neighbors(row.pos),a):return false
	pickup(w,row,token,a,j.id);j.material_claims.pop_front();j.state="working";return false

static func finish_build(w,j,success: bool):
	for row in w.field_items.duplicate():
		if row.get("location")!="site" or row.job_id!=j.id:continue
		if success:w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+row.amount;w.field_items.erase(row)
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

static func destination(w,a,amount: int) -> Variant:
	var cells=w.storage_cells.filter(func(p):return w.walkable(p) and storage_used(w,p)+amount<=Policy.STORAGE_CAPACITY)
	cells.sort_custom(func(x,y):return w.distance(a.pos,x)<w.distance(a.pos,y))
	for p in cells:
		if not w.Jobs.path_to(w,a.pos,w.neighbors(p).filter(func(c):return w.walkable(c))).is_empty():return p
	return null

static func haul_step(w,j,a):
	var carried=cargo(w,a.work_key,j.id)
	if not carried.is_empty():
		var n=0
		for row in carried:n+=row.amount
		var dest=destination(w,a,n)
		if dest==null:j.state="blocked";j.block_reason="保管域が満杯か届きません";return
		j.phase="deliver"
		if not w.Jobs.walk(w,j,w.neighbors(dest),a):return
		# Sequential execution rechecks capacity here; a second worker never overfills it.
		if storage_used(w,dest)+n>Policy.STORAGE_CAPACITY:j.state="blocked";j.block_reason="保管域が満杯です";return
		for row in carried:row.location="ground";row.pos=dest;row.owner="";row.job_id=-1
		sync(w);w.Jobs.complete(w,j,true);return
	var row=find(w,j.get("stock_id",-1))
	if row.is_empty() or row.kind=="chick":w.Jobs.complete(w,j,false);return
	var token="job:%d"%j.id
	if row.claims.get(token,0)<=0:
		if destination(w,a,mini(Policy.CARRY_CAPACITY,free_count(row)))==null:j.state="blocked";j.block_reason="使える保管域を指定してください";return
		if reserve(w,row.kind,Policy.CARRY_CAPACITY,token,a,row.stock_id).is_empty():j.state="blocked";j.block_reason="物資は別の人が使用中です";return
	j.phase="fetch"
	if not w.Jobs.walk(w,j,w.neighbors(row.pos),a):return
	pickup(w,row,token,a,j.id);j.state="working"

static func step(w):
	normalize(w)
	for row in w.field_items:
		if row.location=="carry":
			if w.workers.has(row.owner):row.pos=w.workers[row.owner].pos
			else:row.location="ground";row.owner="";row.job_id=-1
		for token in row.claims.keys():
			if token.begins_with("food:") and not w.workers.has(token.trim_prefix("food:")):row.claims.erase(token)
	if not w.storage_cells.is_empty():
		for row in w.field_items.duplicate():
			if w.jobs.size()>=w.Jobs.LIMIT:break
			if row.location!="ground" or row.pos in w.storage_cells or row.get("placed",false) or row.kind in ["chick","skill_scroll"] or row.kind.ends_with("_plan") or free_count(row)==0:continue
			if w.jobs.any(func(j):return j.get("stock_id",-1)==row.stock_id):continue
			w.jobs.append({"id":w.next_job_id,"kind":"haul","pos":row.pos,"stock_id":row.stock_id,"animal_id":-1,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"haul"});w.next_job_id+=1
			w.Life.wake_auto(w)
	sync(w)

static func save(w):
	w.campaign.physical_stock=true;w.campaign.next_stock_id=w.next_stock_id
	w.campaign.storage_cells=w.storage_cells.map(func(p):return [p.x,p.y])
	w.campaign.stock_used=w.stock_used.duplicate()

static func totals(w) -> Dictionary:
	var result={}
	for row in w.field_items:result[row.kind]=result.get(row.kind,0)+row.get("amount",1)
	for a in w.animals:
		if not a.get("equipment",{}).is_empty():result[a.equipment.item_id]=result.get(a.equipment.item_id,0)+1
	for e in w.enemies:
		if not e.get("stolen",{}).is_empty():result[e.stolen.kind]=result.get(e.stolen.kind,0)+e.stolen.get("amount",1)
	return result
