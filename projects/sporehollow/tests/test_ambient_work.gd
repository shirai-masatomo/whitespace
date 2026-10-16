extends "res://tests/test_housing_sleep.gd"
func setup(mode="free"):
	w=fixture();w.spawn_schedule=[];w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999;w.calendar_ticks=7*72;w.keeper.timetable.fill(mode);w.keeper.auto_collect=true
	w.Zones.create(w,"stockpile",Vector2i(27,23),Vector2i(29,23))
func advance(n):
	for i in range(n):w.step()
func done_until(condition,limit=260):
	for i in range(limit):
		w.step()
		if condition.call():return true
	return false
func run():
	for mode in ["work","free"]:
		setup(mode);house(Vector2i(33,23));check(w.act("bed",Vector2i(35,25)),mode+" indoor shortage reservation")
		var blocked=w.jobs[0].id;w.keeper.auto_collect=false
		var row=w.Stock.add(w,"stone",3,Vector2i(31,25));w.Stock.enqueue_haul(w,row)
		check(done_until(func():return w.Stock.available(w,"stone")==3),mode+" production ticks: shortage does not block explicit haul")
		w.Jobs.cancel(w,blocked);var next=w.Stock.add(w,"wood",4,Vector2i(32,26));w.Stock.enqueue_haul(w,next)
		check(done_until(func():return w.Stock.available(w,"wood")==4),mode+" cancellation allows next actual work")
		check(w.keeper.timetable.all(func(v):return v==mode),mode+" timetable data unchanged")
		setup(mode);var wood=w.Stock.add(w,"wood",23,Vector2i(32,25));w.Stock.add(w,"stone",4,Vector2i(32,26));var total=w.Stock.totals(w).duplicate()
		check(done_until(func():return w.Stock.available(w,"wood")==23 and w.Stock.available(w,"stone")==4),mode+" auto collects multiple stacks, including second 20-capacity trip")
		check(w.jobs.is_empty() and w.Stock.totals(w)==total,mode+" personal work uses no public slots and conserves items")
	setup();w.keeper.auto_collect=false;w.Stock.add(w,"wood",3,Vector2i(31,25));advance(40);check(w.Stock.available(w,"wood")==0,"OFF never collects without designation")
	w.Stock.enqueue_haul(w,w.field_items[0]);check(done_until(func():return w.Stock.available(w,"wood")==3),"OFF preserves explicit haul")
	setup();var r=w.Stock.add(w,"wood",5,Vector2i(31,25));r.forbidden=true;var site=w.Stock.add(w,"wood",3,Vector2i(32,25),"site",123);var held=w.Stock.add(w,"stone",3,Vector2i(32,26));held.claims["other"]=3;advance(40)
	check(w.Stock.available(w,"wood")==0 and site.location=="site" and held.amount==3,"Forbidden/site/claimed materials stay untouched")
	r.forbidden=false;check(done_until(func():return w.Stock.available(w,"wood")==5),"Allow change re-evaluates auto collection")
	setup();w.Stock.add(w,"wood",5,Vector2i(32,25));w.act("wood_wall",Vector2i(35,25));check(done_until(func():return w.structures.get(Vector2i(35,25),{}).get("status")=="ready",320),"Auto recovery supplies an unfunded build, then construction resumes")
	check(w.stock_used.get("wood",0)==5 and w.Stock.totals(w).get("wood",0)==0,"Auto recovery/build consumes exactly five")
	setup();w.Stock.add(w,"stone",40,Vector2i(38,25));advance(1);check(not w.keeper.get("personal_haul",{}).is_empty(),"Personal fetch begins")
	var r2=w.Stock.add(w,"wood",2,Vector2i(31,26));w.Stock.enqueue_haul(w,r2);advance(1);check(w.Work.active(w).get("stock_id")==r2.stock_id and w.keeper.get("personal_haul",{}).is_empty(),"New explicit feasible job preempts unladen auto fetch")
	setup();var helper=w.keeper.duplicate(true);helper.pos=Vector2i(30,26);w.Work.register(w,"helper",helper);w.Stock.add(w,"wood",40,Vector2i(32,25));w.Stock.add(w,"wood",40,Vector2i(33,26));
	check(done_until(func():return w.Stock.available(w,"wood")==80,320),"Two workers collect without claims colliding")
	check(w.storage_cells.all(func(p):return w.Stock.storage_used(w,p)<=40) and w.Stock.totals(w).wood==80,"Shared reservation capacity40 and total conserved")
	setup();var start=w.keeper.pos;advance(36);check(w.keeper.pos!=start or w.keeper.has("idle_move"),"Idle has bounded local movement")
	check(w.distance(start,w.keeper.pos)<=3,"Idle does not drift far")
	w.Jobs.hold(w,"explicit");var stopped=w.keeper.pos;advance(12);check(w.keeper.pos==stopped and w.job_hold_reason=="explicit","Explicit stop is never forcibly released")
	setup();w.keeper.timetable.fill("sleep");w.keeper.sleepiness=80;w.Stock.add(w,"wood",4,Vector2i(32,25));advance(8);check(w.keeper.resting and w.keeper.get("personal_haul",{}).is_empty(),"Sleep remains higher priority")
	setup();w.Work.set_drafted(w,"keeper",true);w.Stock.add(w,"wood",4,Vector2i(32,25));advance(8);check(w.Stock.available(w,"wood")==0 and not w.keeper.has("idle_move"),"Draft blocks auto collect and idle")
	var failed=checks.filter(func(c):return not c.passed).size();var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/ambient-work.json",FileAccess.WRITE);f.store_string(JSON.stringify({"count":checks.size(),"failed":failed,"checks":checks},"  "));f.close();print("Ambient work: %d checks / %d failed"%[checks.size(),failed]);quit(1 if failed else 0)
