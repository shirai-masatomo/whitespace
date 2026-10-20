extends RefCounted
## A draft gesture, separate from the paid job queue. Re-evaluated on release.
var kind=""
var cells: Array=[]
var seen={}
var last=null
var cache_key: Array=[]
var cached_rows: Array=[]
var cached_accepted=0
var cached_cost=0
var cached_reason=""
var cached_budget={}

func clear():
	kind="";cells.clear();seen.clear();last=null
	cache_key=[];cached_rows=[];cached_accepted=0;cached_cost=0;cached_reason=""

func begin(tool: String,p: Vector2i):
	clear();kind=tool;add(p)

func add(p: Vector2i):
	for cell in ([p] if last==null else segment(last,p)):
		if not seen.has(cell):cells.append(cell);seen[cell]=true
	last=p

static func segment(a: Vector2i,b: Vector2i) -> Array:
	# Cardinal supercover keeps walls joined even when mouse events skip cells.
	var result=[a];var p=a;var nx=absi(b.x-a.x);var ny=absi(b.y-a.y)
	var sx=signi(b.x-a.x);var sy=signi(b.y-a.y);var ix=0;var iy=0
	while ix<nx or iy<ny:
		if ix<nx and (iy>=ny or (1+2*ix)*ny<=(1+2*iy)*nx):p.x+=sx;ix+=1
		else:p.y+=sy;iy+=1
		result.append(p)
	return result

func state_key(w) -> Array:
	# Hash existing state once per preview (not once per cell). Release always revalidates.
	return [w.get_instance_id(),kind,w.phase,w.tick,w.W,w.H,w.logistics_entry,w.debug_enabled,
		hash(w.structures),hash(w.floors),hash(w.trees),hash(w.rocks),hash(w.mountain_cells),hash(w.story.idol),
		hash(w.animals),hash(w.workers),hash(w.keeper),hash(w.enemies),hash(w.foods),hash(w.natural),hash(w.field_items),hash(w.jobs),hash(w.campaign.unlocked_blueprints)]

func plan(w,force: bool=false) -> Dictionary:
	var key=state_key(w)
	if force or key!=cache_key or cached_rows.size()>cells.size():
		cache_key=key;cached_rows=[];cached_accepted=0;cached_cost=0;cached_reason=""
		cached_budget=w.Jobs.Reservations.presentation(w).remaining
	var lookup=w.Jobs.index(w) if cached_rows.size()<cells.size() else {}
	for i in range(cached_rows.size(),cells.size()):
		var p=cells[i];var why=w.Jobs.build_reason(w,kind,p,cached_accepted,cached_cost,lookup)
		var resource=w.BUILD[kind].get("resource","soil");var cost=int(w.BUILD[kind].cost)
		var unfunded=0
		for material in w.Buildings.Cost.materials(w,kind):
			var amount=w.Buildings.Cost.materials(w,kind)[material];var free=int(cached_budget.get(material,0))
			unfunded+=maxi(0,amount-free)
			if why=="":cached_budget[material]=maxi(0,free-amount)
		cached_rows.append({"pos":p,"valid":why=="","reason":why,"waiting_material":why=="" and unfunded>0,"unfunded":unfunded})
		if why=="":
			cached_accepted+=1
			cached_cost+=int(w.BUILD[kind].cost)
		elif cached_reason=="":cached_reason=why
	return {"rows":cached_rows,"accepted":cached_accepted,"skipped":cached_rows.size()-cached_accepted,"cost":cached_cost,"reason":cached_reason}

func commit(w) -> Dictionary:
	var preview=plan(w,true);var accepted=0;var lookup=w.Jobs.index(w);var reasons={}
	lookup.construction_group=w.next_job_id;lookup.quiet=true
	for row in preview.rows:
		var why=row.reason
		if row.valid:
			why=w.Jobs.build_reason(w,kind,row.pos,0,0,lookup)
			if why=="" and w.act(kind,row.pos,-1,lookup):accepted+=1;continue
			if why=="":why="資材の確保に失敗しました"
		reasons[why]=int(reasons.get(why,0))+1
	for why in reasons:w.Jobs.Reservations.reject(w,kind,why+"（%d件）"%reasons[why])
	var result={"accepted":accepted,"skipped":cells.size()-accepted,"reason":preview.reason,"reasons":reasons}
	if cells.size()>1:w.PlayerEvents.add(w,"建築指定：%d件予約／%d件未登録"%[accepted,result.skipped])
	clear()
	return result
