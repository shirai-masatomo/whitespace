extends "res://tests/test_construction_recovery.gd"
func run():
	var j=partial();supply(2)
	for i in range(80):
		tick_work(1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.Work.interrupt(w,"keeper","休息中")
	var cargo=w.field_items.filter(func(r):return r.get("construction_transfer",false))[0]
	check(not w.act("collect",cargo.pos),"Direct collect cannot enqueue haul for interrupted construction cargo")
	check(w.Stock.collection_reason(w,cargo.pos)!="","Locked collection has a user-facing reason")
	finished("Interrupted cargo still delivers after rejected collect")
	j=partial();supply(2)
	for i in range(80):
		tick_work(1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.build_deliveries.erase("keeper");finished("Orphan cargo and owner recover together")
	j=partial();j.delivery_owner="missing-owner";j.delivery_retry=w.tick+9999;supply(2);finished("Orphan delivery owner is repaired without losing site materials")
	setup();var pos=Vector2i(35,25);w.act("cooking_bench",pos);supply(3);tick_work(100);j=w.jobs[0]
	check(w.Stock.delivered(w,j)==3 and j.required==12,"2x2 bench partially supplied with existing cost12")
	supply(9);tick_work(180);check(w.structures.get(pos,{}).get("status")=="ready" and w.stock_used.wood==12,"2x2 bench completes exactly12")
	setup();supply(3);w.act("wood_wall",pos)
	# Real World.step: production needs, timetable, stock, delivery and scheduler.
	for i in range(90):w.step()
	j=w.jobs[0];check(w.Stock.delivered(w,j)==3,"World.step (not Work-only fixture) reaches3/5")
	supply(2)
	for i in range(140):w.step()
	check(w.structures.get(pos,{}).get("status")=="ready","Production loop resumes and completes")
	# Two workers + phased restock + interrupted transfer must conserve quantities.
	setup();var helper=w.keeper.duplicate(true);helper.pos=Vector2i(30,27);w.Work.register(w,"helper",helper)
	var s=preload("res://game/wall_stroke.gd").new();s.begin("wood_wall",pos);s.add(pos+Vector2i(3,0));s.commit(w)
	for n in [3,7,4,6]:
		supply(n);tick_work(100)
	tick_work(120);check(w.metrics.built==4 and w.stock_used.wood==20 and w.Stock.totals(w).get("wood",0)==0,"Two workers and4 staged supplies conserve20 across4 walls")
	check(w.field_items.all(func(r):return r.amount>0 and r.claims.values().reduce(func(n,v):return n+v,0)<=r.amount),"No overclaimed physical stack")
	# A genuine unreachable stockpile is distinct from zero-stock waiting.
	j=partial();var row=supply(2)
	for q in w.neighbors(row.pos):ready("stone_wall",q)
	w.refresh_indoor();tick_work(20);check(w.Stock.available(w,"wood")==2 and w.Stock.delivered(w,j)==3,"Available stock can be unreachable")
	check("通路" in j.block_reason,"Unreachable stock reports a route reason, not zero supplies")
	w.structures.clear();w.refresh_indoor();finished("Reopened route resumes without new designation")
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/construction-edges.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"traces":traces},"  "))
	print("Construction edges: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
