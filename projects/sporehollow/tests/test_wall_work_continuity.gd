extends SceneTree
const Farm=preload("res://game/world.gd")
const Art=preload("res://game/building_art.gd")
var checks=[]
var failed=0
class Recorder extends RefCounted:
	const TILE=Vector2(48,42)
	var mask=0
	var calls=[]
	func wall_links(_p):return {Vector2i.UP:bool(mask&1),Vector2i.RIGHT:bool(mask&2),Vector2i.DOWN:bool(mask&4),Vector2i.LEFT:bool(mask&8)}
	func draw_mesh(mesh,texture,transform,color):calls.append({"texture":texture,"mesh":mesh,"transform":transform,"color":color})
	func draw_rect(_rect,_color):pass
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w)
	w.keeper.pos=Vector2i(30,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason=""
	w.animals.clear();w.debug_enabled=true;w.debug_infinite=true;w.refresh_indoor()
	w.keeper.work_priorities={"build":1,"gather":2,"collect":3,"animal":4,"other":4,"haul":4}
	w.Zones.create(w,"stockpile",Vector2i(24,24),Vector2i(25,25))
	return w
func tick(w):
	w.tick+=1
	w.Combat.recover(w.keeper,w.DT,false)
	w.Work.step(w)
func add_job(w,kind,p):
	var ok=false
	if kind=="mine":w.rocks[p]={"amount":8,"forbidden":false};ok=w.Tasks.designate(w,kind,p)
	elif kind=="clear_tree":w.trees[p]="continuity_tree_%d_%d"%[p.x,p.y];ok=w.Tasks.designate(w,kind,p)
	elif kind=="haul":ok=w.Stock.enqueue_haul(w,w.Stock.add(w,"wood",8,p))
	else:ok=w.act(kind,p)
	check(ok,"Reserve "+kind+" "+str(p))
	return w.jobs[-1] if ok else {}
func continuity(kind,stage):
	var w=fixture();var j=add_job(w,kind,Vector2i(40,25))
	if j.is_empty():return
	var reached=false
	for i in range(100):
		tick(w)
		if (j.state=="walking" if stage=="walking" else (not w.Stock.cargo(w,"keeper").is_empty() if kind=="haul" else j.state=="working")):
			reached=true;break
	check(reached,"Reach "+kind+" / "+stage)
	if not reached:return
	var id=j.id
	add_job(w,"wood_tile",w.keeper.pos+Vector2i(0,2))
	add_job(w,"mine",Vector2i(32,20))
	add_job(w,"clear_tree",Vector2i(33,20))
	add_job(w,"haul",Vector2i(34,20))
	var held=true;var observed=0
	for i in range(150):
		if not w.jobs.has(j):break
		held=held and w.Work.active(w).get("id",-1)==id
		tick(w);observed+=1
	check(held and observed>0,"New mixed/nearer/higher-priority reservations never preempt "+kind+" / "+stage)
	check(w.job_log.any(func(row):return row.event=="completed" and row.id==id),"Original completes before reassignment "+kind+" / "+stage)
	check(w.job_log.filter(func(row):return row.event=="assigned" and row.id==id).size()==1,"No release/reclaim oscillation "+kind+" / "+stage)
	# Existing priorities still select the pending build after completing a gather/haul.
	if kind!="wood_tile":
		tick(w);check(w.Work.active(w).get("kind","")=="wood_tile","Pending build priority applies after completion: "+kind+" / "+stage)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var r=Recorder.new()
	for kind in ["wall","wood_wall","stone_wall"]:
		for mask in range(16):
			for hp in [100,25]:
				r.mask=mask;r.calls.clear();var b={"kind":kind,"hp":hp,"max_hp":100}
				var before=b.duplicate(true);Art.wall(r,Vector2(504,441),b,false)
				check(r.calls.size()==1 and b==before and r.calls[0].texture.get_size()==Vector2(48,68),"One draw of adopted texture; state unchanged %s/%d/%d"%[kind,mask,hp])
				check(r.calls[0].mesh==Art.surface_mesh(),"Shared geometry reused %s/%d/%d"%[kind,mask,hp])
	var mesh=Art.surface_mesh();var arrays=mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_VERTEX].size()==24 and arrays[Mesh.ARRAY_INDEX].size()==90,"Geometry bounded at 24 vertices, 30 triangles")
	check(Art.WALL_DEST_X[2]-Art.WALL_DEST_X[1]==32 and Art.WALL_DEST_Y[3]-Art.WALL_DEST_Y[2]==28,"Roof 32x28 has equal two-thirds cell thickness in both directions")
	check(Art.WALL_DEST_Y[1]==2 and Art.WALL_DEST_Y[4]==44 and Art.WALL_DEST_X[0]==0 and Art.WALL_DEST_X[3]==48,"All connection ports retain exact 48x42 pitch")
	check(Art.WALL_SOURCE_Y[4]==Art.WALL_DEST_Y[4] and Art.WALL_SOURCE_Y[5]==Art.WALL_DEST_Y[5],"Lower foot anchor remains unchanged")
	var area=0.0;var v=arrays[Mesh.ARRAY_VERTEX];var ix=arrays[Mesh.ARRAY_INDEX]
	for i in range(0,ix.size(),3):area+=absf((Vector2(v[ix[i+1]])-Vector2(v[ix[i]])).cross(Vector2(v[ix[i+2]])-Vector2(v[ix[i]])))*0.5
	check(is_equal_approx(area,48.0*68.0),"Triangle coverage contains no gaps or extra overlapping area")
	for mask in [5,10,3,15]:
		for opened in [false,true]:
			r.mask=mask;r.calls.clear()
			var b={"kind":"locked_door","hp":25,"max_hp":100,"open":opened,"lock_hp":0}
			for layer in ["frame_rear","leaf","frame_front"]:Art.door_layer(r,Vector2(504,441),b,layer)
			check(r.calls.size()==4 and r.calls.all(func(c):return c.mesh==mesh),"Door frame/leaf/lock share wall profile: %d/%s"%[mask,opened])
	r.calls.clear();Art.wall(r,Vector2.ZERO,{"kind":"wall","hp":100,"max_hp":100},true)
	check(r.calls.all(func(c):return is_equal_approx(c.color.a,0.45)),"Preview keeps transparency")
	for kind in ["wood_tile","mine","clear_tree","haul"]:
		for stage in ["walking","working"]:continuity(kind,stage)
	# Real construction material trip must also retain its initial allocation set.
	var w=fixture();w.debug_infinite=false
	w.Stock.add(w,"wood",16,Vector2i(24,24))
	var j=add_job(w,"wood_tile",Vector2i(40,25));tick(w)
	var allocation=w.build_deliveries.get("keeper",{}).duplicate(true)
	check(not allocation.is_empty(),"Real material-fetch trip starts")
	add_job(w,"wood_tile",Vector2i(31,26))
	var steady=true
	for i in range(80):
		if not w.build_deliveries.has("keeper"):break
		steady=steady and w.build_deliveries.keeper.id==allocation.get("id",-1) and w.build_deliveries.keeper.allocations.all(func(entry):return entry.job_id==j.id)
		tick(w)
	check(steady and w.Stock.delivered(w,j)==2,"New nearby plan does not redirect active material pickup/delivery")
	# Valid interruptions are retained and retry is bounded, not forced commitment.
	w=fixture();j=add_job(w,"mine",Vector2i(40,25));tick(w);w.keeper.danger_near=true;tick(w)
	check(w.Work.active(w).is_empty() and j.state=="suspended","Danger interrupts current job")
	w.keeper.danger_near=false;tick(w)
	check(w.Work.active(w).get("id",-1)==j.id,"Same pending job resumes when danger clears")
	w.Tasks.set_forbidden(w,"mine",j.pos,-1,true);tick(w)
	check(w.Work.active(w).is_empty() and j.state=="blocked" and j.retry_at>w.tick,"Forbidden target releases claim and delays retry")
	var assigned=w.job_log.filter(func(row):return row.event=="assigned").size()
	for i in range(4):tick(w)
	check(w.job_log.filter(func(row):return row.event=="assigned").size()==assigned,"Blocked work does not reclaim on every tick")
	w.Tasks.set_forbidden(w,"mine",j.pos,-1,false);tick(w)
	check(w.Work.active(w).get("id",-1)==j.id,"Allowed target resumes without discarding progress")
	w.keeper.resting=true;tick(w);check(w.Work.active(w).is_empty(),"Rest may interrupt work")
	w.keeper.resting=false;tick(w);w.Jobs.cancel(w,j.id)
	check(w.Work.active(w).is_empty() and not w.jobs.has(j),"Explicit cancellation releases the job")
	FileAccess.open(out+"/wall-work-continuity.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"method":"Production scheduler/executor, controlled fixed ticks; recorder-only draw calls; no scene/GPU"},"\t"))
	print("WallWorkContinuity: ",checks.size()," checks; ",failed," failures");quit(1 if failed else 0)
