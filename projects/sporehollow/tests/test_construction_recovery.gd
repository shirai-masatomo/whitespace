extends "res://tests/test_housing_sleep.gd"
var traces=[]
func setup():
	w=fixture();w.keeper.auto_collect=false # These cases exercise explicit collection after cancellation.
	w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(28,24));w.keeper.timetable.fill("work")
	w.keeper.work_priorities.haul=1;w.keeper.work_priorities.build=1
func supply(n:int,p=Vector2i(25,23)):return w.Stock.add(w,"wood",n,p)
func trace(label):
	traces.append({"label":label,"tick":w.tick,"jobs":w.jobs.duplicate(true),"items":w.field_items.duplicate(true),"deliveries":w.build_deliveries.duplicate(true),"available":w.Stock.available(w,"wood"),"worker_reason":w.Work.reason(w,"keeper",w.keeper),"status":w.keeper.get("work_status","")})
func partial():
	setup();check(w.act("wood_wall",Vector2i(35,25)),"Accept unfunded wall");tick_work(8);supply(3);tick_work(90)
	check(w.jobs.size()==1 and w.Stock.delivered(w,w.jobs[0])==3,"Actual transport delivers3/5");trace("partial");return w.jobs[0]
func finished(note):
	tick_work(160);trace(note);check(w.structures.get(Vector2i(35,25),{}).get("status")=="ready",note)
func cases():
	var j=partial();supply(2);finished("A: direct stocked top-up resumes")
	j=partial();tick_work(600);var loose=supply(2,Vector2i(29,26));check(w.Stock.available(w,"wood")==0,"Loose visible goods not yet available")
	check(w.act("collect",loose.pos),"A: ordinary collection accepted");finished("A: long wait then ordinary haul resumes")
	j=partial();w.debug_enabled=true;w.Stock.debug_replenish(w,["wood"]);finished("A: debug restock resumes")
	j=partial();var id=j.id;check(w.Stock.designate(w,"clear",j.pos,j.pos).accepted==1,"B: cancel designation accepted")
	check(w.Stock.totals(w).get("wood",0)==3 and w.field_items.all(func(r):return r.location=="ground" and r.job_id==-1),"B: three released, IDs detached")
	supply(2);tick_work(50);check(not w.structures.has(j.pos) and w.jobs.is_empty(),"B: cancelled job never revives")
	check(w.Stock.designate(w,"haul",j.pos,j.pos).accepted==1,"D: released site accepted for haul");tick_work(100)
	check(w.Stock.available(w,"wood")==5,"D: all returned goods stocked")
	check(w.act("wood_wall",j.pos),"B: same position accepts fresh designation");finished("B: fresh reservation consumes released materials")
	j=partial();var ids=w.field_items.map(func(r):return r.stock_id)
	check(w.Stock.designate(w,"haul",j.pos,j.pos).accepted==0 and not w.act("collect",j.pos),"C: both collection entry points reject active site")
	check(ids==w.field_items.map(func(r):return r.stock_id) and w.Stock.delivered(w,j)==3,"C: collection attempt retains site IDs and3 units")
	supply(2);finished("C: recovery after collection attempt")
	j=partial();supply(2)
	for i in range(80):
		tick_work(1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.Work.interrupt(w,"keeper","休息中");tick_work(1);finished("Interruption of second delivery recovers")
	j=partial();var row=supply(2);w.Stock.designate(w,"forbid",row.pos,row.pos);tick_work(40)
	check(w.Stock.delivered(w,j)==3,"Forbidden stock is not stolen");w.Stock.designate(w,"allow",row.pos,row.pos);finished("Allow stock resumes")
	j=partial();w.Stock.designate(w,"forbid",j.pos,j.pos);tick_work(30);w.Stock.designate(w,"allow",j.pos,j.pos);supply(2);finished("Allow site resumes")
	# Reach a real delivery, then cancel the neighbouring plan while a batch is in flight.
	setup();supply(8);var s=preload("res://game/wall_stroke.gd").new();s.begin("wood_wall",Vector2i(35,25));s.add(Vector2i(36,25));s.commit(w)
	tick_work(100);trace("batch-partial");supply(2);tick_work(150)
	check(w.metrics.built==2 and w.stock_used.get("wood",0)==10,"Batch5+3 then2 completes exactly10")
	# Interrupted cargo at its own destination must not obstruct its own plan.
	j=partial();supply(2)
	for i in range(80):
		tick_work(1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.keeper.pos=j.pos;w.Work.interrupt(w,"keeper","休息中");w.keeper.pos=Vector2i(32,25);trace("cargo-dropped-on-own-plan");finished("Own interrupted cargo does not permanently block site")
func run():
	cases()
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/construction-recovery.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"traces":traces},"  "))
	print("Construction recovery: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
