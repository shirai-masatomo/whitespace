extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="":quit(2);return
	var w=Farm.new({},31).begin_day();w.paused=true;w.jobs.clear();w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear()
	w.keeper.pos=Vector2i(19,20);w.keeper.work_priorities={"build":0,"gather":1,"collect":0,"animal":0,"other":0,"haul":0}
	var points=[]
	for y in range(20,30):
		for x in range(20,30):points.append(Vector2i(x,y))
	points.append(Vector2i(30,30))
	for p in points:w.rocks[p]={"amount":8,"forbidden":false}
	var time=Time.get_ticks_usec();var registered=0
	for p in points:
		if w.Tasks.designate(w,"mine",p):registered+=1
	var register_ms=(Time.get_ticks_usec()-time)/1000.0
	check(w.Jobs.LIMIT==100 and registered==100 and w.jobs.size()==100,"Exactly100 accepted;101st denied")
	var ids=w.jobs.map(func(j):return j.id)
	check(w.Snapshot.save(w,out+"/hundred.snapshot"),"100 jobs save")
	var restored=Farm.Snapshot.restore(out+"/hundred.snapshot")
	check(restored.jobs==w.jobs and restored.keeper.work_priorities==w.keeper.work_priorities,"100 jobs IDs/progress/priorities restored")
	w.Jobs.cancel(w,w.jobs.back().id);check(w.jobs.size()==99 and w.Tasks.designate(w,"mine",points[-1]) and w.jobs.size()==100,"Cancel frees exactly one slot")
	var samples=[];w.paused=false
	for i in range(28):
		var t=Time.get_ticks_usec();w.step();samples.append((Time.get_ticks_usec()-t)/1000.0)
	check(w.field_items.any(func(r):return r.kind=="stone") and w.jobs.size()<100,"Scheduler selects gathering and physically completes mining with100 jobs")
	check(w.jobs.all(func(j):return j.id in ids or j.pos==points[-1]),"Existing job identities preserved")
	var sorted=samples.duplicate();sorted.sort();var total=0.0
	for s in samples:total+=s
	FileAccess.open(out+"/hundred-jobs.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"registration_ms":register_ms,"step_ms":samples,"mean_ms":total/samples.size(),"max_ms":sorted[-1]},"  "))
	quit(0 if checks.all(func(c):return c.passed) else 1)
