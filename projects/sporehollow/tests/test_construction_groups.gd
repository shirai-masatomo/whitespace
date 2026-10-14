extends SceneTree
const Farm=preload("res://game/world.gd")
const Stroke=preload("res://game/wall_stroke.gd")
const Metrics=preload("res://game/terrain_metrics.gd")
var checks=[]
var failed=0
var max_cargo=0
var invariant_ok=true
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w)
	w.keeper.pos=Vector2i(30,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason="";w.animals.clear();w.refresh_indoor()
	w.keeper.work_priorities={"build":1,"gather":2,"collect":3,"animal":4,"other":4,"haul":4}
	w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(28,24))
	return w
func group(w,n,kind="wood_wall",origin=Vector2i(35,26)):
	var stroke=Stroke.new();stroke.begin(kind,origin);stroke.add(origin+Vector2i(n-1,0))
	var first=w.next_job_id;var result=stroke.commit(w)
	check(result.accepted==n,"Drag accepts %d %s as %d player jobs"%[n,kind,n])
	var rows=w.jobs.filter(func(j):return j.id>=first)
	check(rows.all(func(j):return j.construction_group==first and not j.construction_ready),"One immutable group per gesture")
	return rows
func stock(w,kind,n,p=Vector2i(25,23)):return w.Stock.add(w,kind,n,p)
func tick(w):
	w.tick+=1
	for a in w.workers.values():w.Combat.recover(a,w.DT,false)
	w.Work.step(w)
	for key in w.workers:
		var count=0
		for r in w.Stock.cargo(w,key):count+=r.amount
		max_cargo=maxi(max_cargo,count);invariant_ok=invariant_ok and count<=20
	for r in w.field_items:
		var reserved=0
		for amount in r.claims.values():reserved+=amount
		invariant_ok=invariant_ok and r.amount>0 and reserved<=r.amount
func finish(w,count,limit=240):
	for i in range(limit):
		if w.metrics.built>=count:break
		tick(w)
func normal_cases():
	var w=fixture();stock(w,"wood",40)
	var rows=group(w,3);var fully_delivered=false;var order_ok=true
	for i in range(200):
		if rows.all(func(j):return w.Stock.delivered(w,j)>=j.required):fully_delivered=true
		tick(w)
		if rows.any(func(j):return j.started):order_ok=order_ok and fully_delivered
		if w.metrics.built==3:break
	check(fully_delivered and order_ok and w.metrics.built==3,"All three sites receive 30 wood before any assembly; builder priority cannot bypass group")
	check(w.Stock.totals(w).wood+w.stock_used.wood==40 and w.stock_used.wood==30,"Single-worker resources conserved")
	check(max_cargo==20,"A real trip carries exactly 20")
	# Finished/open groups never re-close when later gestures add unavailable work.
	w=fixture();stock(w,"wood",20);rows=group(w,2)
	for i in range(100):
		tick(w)
		if rows.any(func(j):return j.started):break
	var active=w.Work.active(w).get("id",-1);var added=group(w,2,"stone_wall",Vector2i(35,29))
	check(rows.all(func(j):return j.construction_ready) and added[0].construction_group!=rows[0].construction_group,"Later group cannot roll back already-started assembly")
	tick(w);check(w.Work.active(w).get("id",active)==active or not w.jobs.any(func(j):return j.id==active),"New work retains active assignment or its completion")
	finish(w,2);check(w.metrics.built==2,"Original group completes despite missing material in later group")
	w=fixture();stock(w,"wood",40);stock(w,"wood",20,Vector2i(26,23));rows=group(w,5)
	var helper=w.keeper.duplicate(true);helper.pos=Vector2i(30,29);w.Work.register(w,"helper",helper)
	fully_delivered=false;order_ok=true
	for i in range(240):
		if rows.all(func(j):return w.Stock.delivered(w,j)>=j.required):fully_delivered=true
		tick(w)
		if rows.any(func(j):return j.started):order_ok=order_ok and fully_delivered
		if w.metrics.built==5:break
	check(w.metrics.built==5 and order_ok,"Two workers deliver all sites then share assembly")
	check(w.Stock.totals(w).wood+w.stock_used.wood==60 and w.stock_used.wood==50,"Two-worker claims conserve every unit")
	var completed=w.job_log.filter(func(r):return r.event=="completed");var ids={}
	for row in completed:ids[row.id]=true
	check(completed.size()==5 and ids.size()==5,"No duplicate construction completions")
	w=fixture();stock(w,"wood",40);rows=group(w,1);rows[0].required=25
	finish(w,1)
	check(w.metrics.built==1 and w.stock_used.wood==25 and w.Stock.totals(w).wood==15,"Requirement over 20 uses multiple trips without loss (25-unit fixture)")
	w=fixture();stock(w,"wood",10);stock(w,"soil",10,Vector2i(26,23));stock(w,"stone",10,Vector2i(27,23))
	group(w,1);group(w,1,"wall",Vector2i(36,26));group(w,1,"stone_wall",Vector2i(37,26))
	var mixed=false
	for i in range(180):
		tick(w);var kinds={};var n=0
		for row in w.Stock.cargo(w,"keeper"):kinds[row.kind]=true;n+=row.amount
		mixed=mixed or (kinds.size()>1 and n==20)
		if w.metrics.built==3:break
	check(mixed and w.metrics.built==3,"Mixed material cargo totals 20, not 20 per kind")
func exception_cases():
	var w=fixture();stock(w,"wood",10);var rows=group(w,2)
	finish(w,1)
	check(w.metrics.built==1 and w.jobs.size()==1 and w.jobs[0].get("material_wait",false),"Resource shortage releases stocked site and leaves reason on missing site")
	stock(w,"wood",10);finish(w,2)
	check(w.metrics.built==2,"Adding supplies later finishes remainder without resetting group")
	w=fixture();stock(w,"wood",10);rows=group(w,2);var ready=rows[0];var blocked=rows[1]
	w.Stock.add(w,"wood",10,ready.pos,"site",ready.id)
	for p in w.neighbors(blocked.pos):w.structures[p]={"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false,"id":500+p.x*100+p.y}
	w.refresh_indoor();w.Delivery.refresh_groups(w)
	check(ready.construction_ready and "通路" in blocked.get("block_reason",""),"Unreachable site cannot permanently block supplied group member")
	# Cancellation, resting in transit and reservation contention.
	w=fixture();stock(w,"wood",40);rows=group(w,3)
	for i in range(80):
		tick(w)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.keeper.resting=true;tick(w)
	check(w.build_deliveries.is_empty() and w.Stock.totals(w).wood==40,"Rest releases transport safely; cargo remains physical")
	w.keeper.resting=false;w.Jobs.cancel(w,rows[1].id)
	finish(w,2)
	check(w.metrics.built==2 and w.Stock.totals(w).wood+w.stock_used.wood==40,"Cancel one grouped site after interrupted pickup; survivors finish without loss")
	w=fixture();var row=stock(w,"wood",10);rows=group(w,2)
	w.Stock.add(w,"wood",10,rows[0].pos,"site",rows[0].id);row.claims["other-reservation"]=10
	w.Delivery.refresh_groups(w)
	check(rows[0].construction_ready and w.Stock.free_count(row)==0,"Other reservation is not double-spent; supplied site is released")
	w=fixture();row=w.Stock.add(w,"wood",30,Vector2i(32,25));w.Stock.enqueue_haul(w,row)
	for i in range(100):
		tick(w)
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and w.Stock.available(w,"wood")==30,"Ordinary hauling retains physical stock and capacity-40 storage")
	check(w.storage_cells.all(func(p):return w.Stock.storage_used(w,p)<=40),"Storage cells never exceed 40")
func bounds_cases():
	var w=fixture();w.debug_enabled=true;w.debug_infinite=true
	var s=Stroke.new();s.kind="soil_tile"
	for i in range(101):s.cells.append(Vector2i(10+i%20,10+i/20))
	check(s.commit(w).accepted==100 and w.jobs.size()==100,"100 jobs allowed, 101st refused without creating stage jobs")
	Metrics.enabled=true;Metrics.take();w.Delivery.refresh_groups(w);var counts=Metrics.take();Metrics.enabled=false
	check(counts.get("construction_group_job_rows",0)==100 and counts.get("construction_group_stock_rows",0)==w.field_items.size(),"Barrier indexes jobs and physical stock once per scheduler step")
	check(w.jobs.all(func(j):return j.construction_ready),"Zero-cost debug group becomes construction-ready")
	# Regression through actual harvest executors.
	w=fixture();var p=Vector2i(32,25);w.rocks[p]={"amount":8,"forbidden":false};w.Tasks.designate(w,"mine",p)
	var q=Vector2i(33,26);w.trees[q]="group_test_tree";w.Tasks.designate(w,"clear_tree",q)
	for i in range(90):
		tick(w)
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and not w.rocks.has(p) and not w.trees.has(q),"Mining and chopping still finish with physical resource output")
	check(w.Stock.totals(w).get("stone",0)==8 and w.Stock.totals(w).get("wood",0)==8,"Harvest quantities unchanged")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var section="normal"
	if "--exceptions" in OS.get_cmdline_user_args():section="exceptions"
	if "--bounds" in OS.get_cmdline_user_args():section="bounds"
	if section=="normal":normal_cases()
	elif section=="exceptions":exception_cases()
	else:bounds_cases()
	check(invariant_ok,"All observed ticks: each worker cargo <=20 and claims <= physical amount")
	check(Farm.Work.Policy.STORAGE_CAPACITY==40 and Farm.Work.Policy.DESIGNATION_LIMIT==100,"Storage40 and designation100 unchanged")
	FileAccess.open(out+"/construction-groups-"+section+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"max_observed_cargo":max_cargo},"\t"))
	print("ConstructionGroups ",section,": ",checks.size()," checks; ",failed," failures");quit(1 if failed else 0)
