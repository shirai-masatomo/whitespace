extends RefCounted
## A draft gesture, separate from the paid job queue. Re-evaluated on release.
var kind=""
var cells: Array=[]
var seen={}
var last=null

func clear():
	kind="";cells.clear();seen.clear();last=null

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

func plan(w) -> Dictionary:
	var rows=[];var accepted=0;var total=0;var first_reason=""
	for p in cells:
		var why=w.Jobs.build_reason(w,kind,p,accepted,total)
		rows.append({"pos":p,"valid":why=="","reason":why})
		if why=="":
			accepted+=1
			total+=0 if w.debug_enabled and w.debug_infinite else int(w.BUILD[kind].cost)
		elif first_reason=="":first_reason=why
	return {"rows":rows,"accepted":accepted,"skipped":rows.size()-accepted,"cost":total,"reason":first_reason}

func commit(w) -> Dictionary:
	var preview=plan(w);var accepted=0
	for row in preview.rows:
		if row.valid and w.act(kind,row.pos):accepted+=1
	var result={"accepted":accepted,"skipped":cells.size()-accepted,"reason":preview.reason}
	clear()
	return result
