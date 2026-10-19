extends "res://tests/test_housing_sleep.gd"
var observations=[]
func setup(seed_value):
	w=Farm.new({},seed_value).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.zones.clear();w.animals.clear();w.work_claims.clear();w.build_deliveries.clear()
	w.Zones.sync_storage(w);w.keeper.pos=Vector2i(30,25);w.keeper.auto_collect=false;w.keeper.sleepiness=0;w.jobs_held=false;w.job_hold_reason="";w.calendar_ticks=7*72;w.campaign.last_supply_day=999;w.nature_config.spawn_chance_per_second=0;w.spawn_schedule=[]
	w.campaign.unlocked_blueprints.append_array(["wood_wall","stone_wall","locked_door"]);w.refresh_indoor();w.Zones.create(w,"stockpile",Vector2i(26,23),Vector2i(28,23))
func until(condition,limit=400):
	for i in range(limit):
		w.step()
		if condition.call():return true
	return false
func partial(seed_value):
	setup(seed_value);check(w.act("wood_wall",Vector2i(35,25)),"%d: zero-material plan accepted"%seed_value);var j=w.jobs[0]
	for i in range(12):w.step()
	check(not j.started,"No zero-material construction")
	w.Stock.add(w,"wood",3,Vector2i(26,23));check(until(func():return w.Stock.delivered(w,j)==3),"%d: World.step physically delivers3/5"%seed_value)
	for i in range(64):w.step()
	check(w.Stock.delivered(w,j)==3 and w.jobs.has(j),"Partial delivery remains owned during wait")
	return j
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var started=Time.get_ticks_msec()
	for seed_value in [31,731,20261019]:
		var j=partial(seed_value);var existing=w.field_items.filter(func(r):return r.location=="site").map(func(r):return r.stock_id)
		check(not w.act("collect",j.pos),"Site cannot be stolen by collection")
		var more=w.Stock.add(w,"wood",2,Vector2i(32,27));w.Stock.enqueue_haul(w,more)
		check(until(func():return w.structures.get(j.pos,{}).get("status")=="ready"),"%d: ordinary haul top-up completes existing job"%seed_value)
		check(w.stock_used.get("wood",0)==5 and w.Stock.totals(w).get("wood",0)==0,"Five consumed exactly once")
		j=partial(seed_value);check(w.Jobs.cancel(w,j.id),"Partial job cancels")
		check(w.field_items.all(func(r):return r.location=="ground" and r.job_id==-1 and r.claims.is_empty()) and w.Stock.totals(w).wood==3,"Cancel releases same physical quantity and claims")
		w.Stock.designate(w,"haul",j.pos,j.pos);check(until(func():return w.Stock.available(w,"wood")==3),"Cancelled cargo returns to stock")
		setup(seed_value);var zid=w.zones[0].id;w.Stock.add(w,"wood",5,Vector2i(26,23));w.Access.set_permission(w,w.Zones.find(w,zid),"keeper",false)
		w.act("wood_wall",Vector2i(35,25));for i in range(25):w.step()
		check(w.stock_used.get("wood",0)==0,"Access denied prevents withdrawal")
		w.Access.set_permission(w,w.Zones.find(w,zid),"keeper",true)
		check(until(func():return w.metrics.built==1),"Permission change resumes same construction")
		setup(seed_value);w.Stock.add(w,"wood",10,Vector2i(26,23));w.Stock.add(w,"mushroom",3,Vector2i(27,23));w.keeper.satiety=20;w.act("wood_wall",Vector2i(35,25))
		check(until(func():return w.metrics.built==1),"Meal interrupts then actual work resumes")
		check(w.stock_used.get("mushroom",0)>0,"Actual meal consumed physical food")
		w.act("wood_wall",Vector2i(36,25));check(w.Work.set_drafted(w,"keeper",true),"Draft accepted");for i in range(12):w.step()
		check(w.Work.reason(w,"keeper",w.keeper)=="徴兵中" and w.metrics.built==1,"Draft suspends ordinary work")
		w.Work.set_drafted(w,"keeper",false);check(until(func():return w.metrics.built==2),"Undraft resumes work")
		setup(seed_value);house(Vector2i(34,23));ready("bed",Vector2i(36,25));w.refresh_indoor();w.Homes.assign_pending(w);w.calendar_ticks=19*72;w.keeper.sleepiness=80;w.keeper.satiety=100
		check(until(func():return w.keeper.get("asleep",false),200),"Assigned bed reached through real steps")
		var epos=w.keeper.pos+Vector2i(-1,0);w.spawn_enemy({"role":"kidnapper","entry":epos,"lv":1,"wave":999});w.enemies[-1].pos=epos;w.enemies[-1].entry=epos
		w.step();check(not w.keeper.get("asleep",false) and not w.keeper.get("resting",false),"Visible threat wakes sleep instead of automatic sleep during attack")
		observations.append({"seed":seed_value,"checks_so_far":checks.size(),"tick":w.tick,"claims":w.work_claims.size()})
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-logic.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":fail,"rows":observations,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0},"  "))
	print("PHASE1_LOGIC checks=",checks.size()," failed=",fail);quit(1 if fail else 0)
