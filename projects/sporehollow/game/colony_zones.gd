extends RefCounted
# Areas guide hauling and rest; they never own or remove physical goods.
const Catalog=preload("res://game/item_catalog.gd")
const TYPES={"soil":"土","wood":"木材","stone":"石","food":"食料","equipment":"装備","other":"その他"}
const FOOD=["egg","mushroom","meat","milk"]

static func init(w):
	w.zones=[];w.next_zone_id=int(w.campaign.get("next_zone_id",1))
	for saved in w.campaign.get("zones",[]):
		var z=saved.duplicate(true);z.cells=z.cells.map(func(p):return Vector2i(p[0],p[1]));w.zones.append(z)
	if not w.campaign.has("zones") and not w.storage_cells.is_empty():
		w.zones.append({"id":w.next_zone_id,"kind":"stockpile","cells":w.storage_cells.duplicate(),"allowed":TYPES.keys()});w.next_zone_id+=1
	for z in w.zones:
		if not z.has("name"):z.name=default_name(w,z.kind)
	sync_storage(w)

static func sync_storage(w):
	w.storage_cells=[];var seen={}
	for z in w.zones:
		w.next_zone_id=maxi(w.next_zone_id,z.id+1)
		if z.kind!="stockpile":continue
		for p in z.cells:
			if w.inside(p) and not seen.has(p):seen[p]=true;w.storage_cells.append(p)

static func save(w):
	w.campaign.zones=[];w.campaign.next_zone_id=w.next_zone_id
	for z in w.zones:
		var row=z.duplicate(true);row.cells=z.cells.map(func(p):return [p.x,p.y]);w.campaign.zones.append(row)

static func find(w,id: int) -> Dictionary:
	for z in w.zones:
		if z.id==id:return z
	return {}

static func cells_in(w,first: Vector2i,last: Vector2i) -> Array:
	var cells=[]
	for y in range(maxi(0,mini(first.y,last.y)),mini(w.H-1,maxi(first.y,last.y))+1):
		for x in range(maxi(0,mini(first.x,last.x)),mini(w.W-1,maxi(first.x,last.x))+1):cells.append(Vector2i(x,y))
	return cells

const LIMIT=10
const DIRS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
static func ordered(cells:Array)->Array:
	cells.sort_custom(func(a,b):return a.y<b.y if a.y!=b.y else a.x<b.x)
	return cells
static func components(cells:Array)->Array:
	var remaining={};var result=[]
	for p in ordered(cells.duplicate()):remaining[p]=true
	while not remaining.is_empty():
		var queue=[remaining.keys()[0]];remaining.erase(queue[0]);var i=0
		while i<queue.size():
			var p=queue[i];i+=1
			for d in DIRS:
				if remaining.has(p+d):remaining.erase(p+d);queue.append(p+d)
		result.append(ordered(queue))
	result.sort_custom(func(a,b):return a.size()>b.size() if a.size()!=b.size() else (a[0].y<b[0].y if a[0].y!=b[0].y else a[0].x<b[0].x))
	return result
static func create(w,kind:String,first:Vector2i,last:Vector2i)->int:
	return add_cells(w,kind,cells_in(w,first,last))
static func add_cells(w,kind:String,cells:Array)->int:
	if kind not in ["stockpile","residential"] or cells.is_empty():return -1
	var merged={}
	for p in cells:
		if w.inside(p):merged[p]=true
	if merged.is_empty():return -1
	var touching=[];var changed_set=true
	while changed_set:
		changed_set=false
		for z in w.zones:
			if z.kind!=kind or z in touching:continue
			if z.cells.any(func(p):return merged.has(p) or DIRS.any(func(d):return merged.has(p+d))):
				touching.append(z);changed_set=true
				for p in z.cells:merged[p]=true
	touching.sort_custom(func(a,b):return a.id<b.id)
	var z={}
	if touching.is_empty():
		if w.zones.filter(func(row):return row.kind==kind).size()>=LIMIT:
			w.say("同じ種類のゾーンは10個までです");return -1
		z={"id":w.next_zone_id,"kind":kind,"name":default_name(w,kind),"cells":[],"allowed":TYPES.keys() if kind=="stockpile" else []}
		w.next_zone_id+=1;w.zones.append(z)
	else:
		z=touching[0] # Oldest ID wins name, priority and filters, deterministically.
		for other in touching.slice(1):w.zones.erase(other)
	z.cells=ordered(merged.keys());changed(w);return z.id
static func subtract(w,cells:Array,id:int=-1)->int:
	var cut={};var count=0;var fragments=[]
	for p in cells:cut[p]=true
	var rows=w.zones.duplicate();rows.sort_custom(func(a,b):return a.id<b.id)
	for z in rows:
		if id>=0 and z.id!=id:continue
		var remaining=z.cells.filter(func(p):return not cut.has(p));count+=z.cells.size()-remaining.size()
		if remaining.size()==z.cells.size():continue
		var parts=components(remaining)
		if parts.is_empty():w.zones.erase(z);continue
		z.cells=parts[0]
		for part in parts.slice(1):fragments.append({"source":z,"cells":part})
	var dropped=0
	for fragment in fragments:
		var source=fragment.source
		if w.zones.filter(func(z):return z.kind==source.kind).size()>=LIMIT:dropped+=fragment.cells.size();continue
		var z=source.duplicate(true);z.id=w.next_zone_id;w.next_zone_id+=1;z.name=default_name(w,z.kind);z.cells=fragment.cells;w.zones.append(z)
	if count>0:changed(w)
	if dropped>0:w.say("ゾーン上限：分断片%dマスの指定を解除。物資はその場に残ります"%dropped)
	return count

static func default_name(w,kind:String) -> String:
	var prefix="備蓄" if kind=="stockpile" else "居住"
	var names=w.zones.map(func(z):return z.get("name",""))
	var number=1
	while prefix+str(number) in names:number+=1
	return prefix+str(number)

static func title(z:Dictionary) -> String:
	return z.get("name",("備蓄" if z.kind=="stockpile" else "居住")+str(z.id))

static func rename(w,id:int,text:String) -> bool:
	var z=find(w,id);var clean=text.replace("\n","").replace("\r","").strip_edges().left(32)
	if z.is_empty() or clean.is_empty():return false
	z.name=clean;save(w) # Metadata only; never invalidate logistics, rest targets or goods.
	return true

static func resize(w,id:int,first:Vector2i,last:Vector2i)->bool:
	var z=find(w,id)
	return false if z.is_empty() else add_cells(w,z.kind,cells_in(w,first,last))>=0

static func remove(w,id: int) -> bool:
	var z=find(w,id)
	if z.is_empty():return false
	w.zones.erase(z);changed(w);return true

static func set_allowed(w,id: int,types: Array):
	var z=find(w,id)
	if z.is_empty() or z.kind!="stockpile":return
	z.allowed=types.filter(func(t):return TYPES.has(t));z.erase("filter");changed(w)

static func stock_type(w,kind: String) -> String:
	if kind in ["soil","wood","stone"]:return kind
	if kind in FOOD:return "food"
	if w.ProgressData.ITEMS.has(kind):return "equipment"
	return "other"

static func accepts(w,p: Vector2i,kind: String) -> bool:
	for z in w.zones:
		if z.kind=="stockpile" and p in z.cells and accepts_item(w,z,kind):return true
	return false

static func accepts_item(w,z,kind:String)->bool:
	return Catalog.accepted(z,kind) if z.has("filter") else stock_type(w,kind) in z.allowed
static func priority_map(w,kind:String)->Dictionary:
	var result={}
	for z in w.zones:
		if z.kind!="stockpile" or not accepts_item(w,z,kind):continue
		for p in z.cells:result[p]=maxi(result.get(p,-1),z.get("priority",1))
	return result
static func storage_for(w,kind: String) -> Array:return priority_map(w,kind).keys()
static func filter_change(w,id:int,scope:String,key:String,value:bool):
	var z=find(w,id)
	if z.is_empty() or z.kind!="stockpile":return
	if not z.has("filter"):
		Catalog.configure(z,"all","",false)
		for item in Catalog.ROWS:z.filter.items[item]=stock_type(w,item) in z.allowed
	Catalog.configure(z,scope,key,value);changed(w)
static func set_priority(w,id:int,value:int):
	var z=find(w,id)
	if z.is_empty():return
	z.priority=clampi(value,0,2);changed(w)

static func changed(w):
	w.housing_dirty=true
	sync_storage(w)
	w.Stock.sync(w)
	# Existing ownership/cargo is retained. Each haul step reselects its destination;
	# if none remains, normal blocking releases the unused goods at the actor.
	for j in w.jobs:
		if j.kind=="haul":j.retry_at=w.tick;j.erase("notified_block")
	for a in w.workers.values():
		if a.get("resting",false):begin_rest(w,a)
	save(w)

static func begin_rest(w,a):
	a.erase("rest_target");a.erase("rest_travel")
	var candidates=[];var has_residential=false
	for z in w.zones:
		if z.kind!="residential":continue
		has_residential=true
		for p in z.cells:
			if w.walkable(p) and not w.actor_occupied(p,a.pos) and p not in candidates:candidates.append(p)
	candidates.sort_custom(func(x,y):return w.distance(a.pos,x)<w.distance(a.pos,y))
	for p in candidates:
		if p==a.pos or not w.Jobs.path_to(w,a.pos,[p]).is_empty():
			a.rest_target=p;a.rest_reason="居住ゾーンで休息" if p==a.pos else "居住ゾーンへ移動中";return
	a.rest_reason="居住ゾーンに到達できないため現在地で休息" if has_residential else "居住ゾーン未指定：現在地で休息"

static func rest_step(w,a) -> bool:
	if not a.has("rest_reason"):begin_rest(w,a)
	if not a.has("rest_target"):return true
	var target=a.rest_target
	if a.pos==target:a.rest_reason="居住ゾーンで休息";return true
	if not w.walkable(target) or w.actor_occupied(target,a.pos) or w.Jobs.path_to(w,a.pos,[target]).is_empty():
		begin_rest(w,a)
		if not a.has("rest_target"):return true
		target=a.rest_target
	if not a.has("rest_travel"):a.rest_travel={"kind":"rest_travel","state":"walking"}
	w.Jobs.walk(w,a.rest_travel,[target],a)
	if a.rest_travel.state=="blocked" and a.rest_travel.get("block_reason","") in ["通路がふさがっています","通行待ち"]:
		a.erase("rest_target");a.rest_reason="居住ゾーンの通路がふさがったため現在地で休息";return true
	a.rest_reason="居住ゾーンへ移動中";a.rest_elapsed=0.0;a.asleep=false
	return false
