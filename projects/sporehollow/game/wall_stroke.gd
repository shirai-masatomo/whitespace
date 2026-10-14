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
	return [w.get_instance_id(),kind,w.phase,w.tick,w.W,w.H,w.logistics_entry,w.debug_enabled,w.debug_infinite,
		hash(w.structures),hash(w.floors),hash(w.trees),hash(w.rocks),hash(w.mountain_cells),hash(w.story.idol),
		hash(w.animals),hash(w.workers),hash(w.keeper),hash(w.enemies),hash(w.foods),hash(w.natural),hash(w.field_items),hash(w.jobs),hash(w.campaign.unlocked_blueprints)]

func plan(w,force: bool=false) -> Dictionary:
	var key=state_key(w)
	if force or key!=cache_key or cached_rows.size()>cells.size():
		cache_key=key;cached_rows=[];cached_accepted=0;cached_cost=0;cached_reason=""
	var lookup=w.Jobs.index(w) if cached_rows.size()<cells.size() else {}
	for i in range(cached_rows.size(),cells.size()):
		var p=cells[i];var why=w.Jobs.build_reason(w,kind,p,cached_accepted,cached_cost,lookup)
		cached_rows.append({"pos":p,"valid":why=="","reason":why})
		if why=="":
			cached_accepted+=1
			cached_cost+=0 if w.debug_enabled and w.debug_infinite else int(w.BUILD[kind].cost)
		elif cached_reason=="":cached_reason=why
	return {"rows":cached_rows,"accepted":cached_accepted,"skipped":cached_rows.size()-cached_accepted,"cost":cached_cost,"reason":cached_reason}

func commit(w) -> Dictionary:
	var preview=plan(w,true);var accepted=0;var lookup=w.Jobs.index(w)
	lookup.construction_group=w.next_job_id
	for row in preview.rows:
		if row.valid and w.act(kind,row.pos,-1,lookup):accepted+=1
	var result={"accepted":accepted,"skipped":cells.size()-accepted,"reason":preview.reason}
	clear()
	return result
