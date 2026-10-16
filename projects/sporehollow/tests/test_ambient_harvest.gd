extends "res://tests/test_ambient_work.gd"
func run():
	setup();var p=Vector2i(32,25);w.rocks[p]={"amount":8,"forbidden":false};var t=Vector2i(34,25);w.trees[t]="fixture-log";w.story.trees.append({"id":"fixture-log","position":[t.x,t.y]})
	check(w.Tasks.designate(w,"mine",p) and w.Tasks.designate(w,"clear_tree",t),"Free schedule accepts real mining/felling")
	var before_idle=w.keeper.pos;var explicit_first=true;var cap=true
	for i in range(180):
		w.step()
		if not w.jobs.is_empty() and not w.keeper.get("personal_haul",{}).is_empty():explicit_first=false
		var count=0
		for row in w.Stock.cargo(w,"keeper"):count+=row.amount
		cap=cap and count<=20
		if w.Stock.available(w,"wood")==8 and w.Stock.available(w,"stone")==8:break
	check(not w.rocks.has(p) and not w.trees.has(t) and w.Stock.available(w,"wood")==8 and w.Stock.available(w,"stone")==8,"World.step harvests and auto collects actual wood and stone outputs")
	check(explicit_first and cap,"Harvest designations precede collection, carry<=20")
	ready("carpentry_bench",Vector2i(35,28));w.refresh_indoor();check(w.Craft.enqueue(w,Vector2i(35,28),"wood_crate","count",1),"Craft bill accepts during free time")
	check(done_until(func():return w.Stock.totals(w).get("wood_crate",0)==1),"Production ticks complete crafting during free time")
	setup();w.zones.clear();w.storage_cells.clear();w.Zones.create(w,"stockpile",Vector2i(29,23),Vector2i(29,23));w.Stock.add(w,"wood",39,Vector2i(29,23));w.Stock.add(w,"wood",4,Vector2i(32,25))
	check(done_until(func():return w.Stock.available(w,"wood")==40),"Auto haul uses final one unit of free capacity")
	advance(12);check(w.Stock.totals(w).wood==43 and w.Stock.cargo(w,"keeper").is_empty(),"Full stock never picks excess or loses it")
	w.Zones.create(w,"stockpile",Vector2i(28,23),Vector2i(28,23));check(done_until(func():return w.Stock.available(w,"wood")==43),"Expansion resumes collection")
	setup();w.Stock.add(w,"wood",3,Vector2i(29,23));w.act("wood_wall",Vector2i(35,25));check(done_until(func():return w.Stock.delivered(w,w.jobs[0])==3),"Partial site really receives three")
	w.Jobs.cancel(w,w.jobs[0].id);check(done_until(func():return w.Stock.available(w,"wood")==3),"Cancelled site materials auto-return to stock without minting")
	setup();w.keeper.auto_collect=false;var start=w.keeper.pos;advance(12);w.Stock.add(w,"wood",5,Vector2i(29,23));w.act("wood_wall",Vector2i(35,25));advance(1);check(not w.keeper.has("idle_move") and w.build_deliveries.has("keeper"),"Explicit work replaces idle immediately")
	w.keeper.timetable.fill("work");check(done_until(func():return w.structures.get(Vector2i(35,25),{}).get("status")=="ready"),"Work/free switch does not cancel construction")
	setup();w.keeper.auto_collect=false
	var source=w.Stock.add(w,"wood",5,Vector2i(31,25));w.keeper.auto_collect=true
	check(done_until(func():return w.Work.Ambient.carrying(w,w.keeper),40),"Auto actually picks physical cargo")
	w.Stock.add(w,"stone",2,Vector2i(32,26));w.Stock.enqueue_haul(w,w.field_items.filter(func(row):return row.kind=="stone")[0]);advance(1)
	check(w.Work.active(w).is_empty() and w.Stock.totals(w).wood==5,"New designation does not discard an in-flight batch")
	check(done_until(func():return w.Stock.available(w,"wood")==5 and w.Stock.available(w,"stone")==2),"Batch delivery safely yields to explicit collection")
	setup();var cell=Vector2i(31,25);w.Zones.create(w,"stockpile",cell,cell);var zone=w.zones.back();var denied=w.Stock.add(w,"wood",4,cell);denied.stocked=false;w.Access.set_permission(w,zone,"keeper",false);advance(16)
	check(denied.pos==cell and denied.amount==4 and w.keeper.get("personal_haul",{}).is_empty(),"Automatic pickup honors withdrawal permissions")
	setup();w.Stock.add(w,"wood",4,Vector2i(31,25));w.spawn_enemy({"role":"kidnapper","entry":Vector2i(0,30),"lv":1,"wave":999});advance(4)
	check(w.keeper.get("personal_haul",{}).is_empty() and not w.keeper.has("idle_move"),"Live raid blocks fallback collection and wandering even at a distance")
	var failed=checks.filter(func(c):return not c.passed).size();var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/ambient-harvest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"count":checks.size(),"failed":failed,"checks":checks},"  "));f.close();print("Ambient harvest: %d checks / %d failed"%[checks.size(),failed]);quit(1 if failed else 0)
