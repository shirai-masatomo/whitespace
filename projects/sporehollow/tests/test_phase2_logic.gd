extends "res://tests/test_phase1_logic.gd"
var details=[]
func stored(kind,n,q):
	w.Zones.create(w,"stockpile",q,q)
	var row=w.Stock.add(w,kind,n,q);row.stocked=true;w.Stock.sync(w);return row
func bed(q):
	ready("mushroom_bed",q)
	w.structures[q].materials={"wood":8,"soil":4}
func bill(q,mode="count",n=3):
	check(w.Craft.enqueue(w,q,"grow_mushroom",mode,n),"Cultivation bill registered")
	return w.jobs.back()
func used(kind):return int(w.stock_used.get(kind,0))
func logic_ticks(n):
	# Real executor, isolated crop-clock boundary tests: no hunger/time healing implied.
	for i in range(n):w.tick+=1;w.Work.step(w)
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	for seed_value in [31,731,20261019]:
		setup(seed_value);stored("wood",8,Vector2i(26,23));var soil=stored("soil",3,Vector2i(27,23));var q=Vector2i(35,25)
		check(w.act("mushroom_bed",q),"Mixed ingredient bed designation")
		var j=w.jobs[0];check(j.required==12 and j.materials=={"wood":8,"soil":4},"Exact 8 wood/4 soil costs in one reservation")
		check(until(func():return w.Stock.delivered(w,j)==11),"Partial mixed delivery 11/12")
		check(not j.started and used("wood")==0 and used("soil")==0,"No construction with missing soil; no early consumption")
		stored("soil",1,Vector2i(28,23))
		check(until(func():return w.structures.get(q,{}).get("status")=="ready"),"Mixed delivery resumes to finished bed")
		check(used("wood")==8 and used("soil")==4,"Both ingredients consumed exactly once")
		check(w.Buildings.cells("mushroom_bed",q)==[q],"Cultivation bed is 1x1")
		setup(seed_value);bed(q);var seedrow=stored("mushroom",2,Vector2i(27,23));j=bill(q)
		check(not w.Craft.enqueue(w,q,"grow_mushroom","count",3),"Duplicate bed bill rejected")
		check(until(func():return w.structures[q].has("culture")),"Actual AI fetches seed and inoculates")
		var crop=w.structures[q].culture;var seeded=w.tick;var remaining=int(crop.ready_tick)-w.tick
		check(used("mushroom")==1 and remaining==3456,"One seed consumed, full 48h clock")
		check(w.Work.active(w).is_empty(),"Growing releases worker and bench claim")
		w.act("wall",Vector2i(36,25));stored("soil",5,Vector2i(26,23))
		check(until(func():return w.structures.get(Vector2i(36,25),{}).get("status")=="ready"),"Worker performs other work during growth")
		w.tick=int(crop.ready_tick)-1;w.Work.step(w)
		check(j.made==0 and w.structures[q].has("culture"),"No harvest one tick before 48h")
		w.tick=int(crop.ready_tick);w.keeper.resting=true;w.Work.step(w)
		check(j.made==0,"Mature crop requires a present worker; rest cannot auto-produce")
		w.keeper.resting=false;w.keeper.pos=q+Vector2i.LEFT;logic_ticks(3)
		var progress=crop.harvest_progress
		w.Work.interrupt(w,"keeper","検証：中断");w.keeper.resting=true;logic_ticks(8)
		check(crop.harvest_progress==progress,"Harvest progress retained on interruption")
		w.keeper.resting=false;logic_ticks(50)
		check(not w.structures[q].has("culture") and not w.jobs.has(j) and j.made==3,"Exactly three physical mushrooms harvested after resumption")
		check(w.Stock.totals(w).mushroom+used("mushroom")==5,"Seed/output conservation (2 initial +3 output)")
		var count=w.Stock.totals(w).mushroom;logic_ticks(40)
		check(w.Stock.totals(w).mushroom==count,"No repeated harvest after completion")
		var output=w.field_items.filter(func(r):return r.kind=="mushroom" and not w.Stock.stored(w,r))
		check(output.size()==1 and output[0].amount==3 and output[0].location=="ground","Harvest is onsite physical output, not shared stock")
		# Storage full retains ground output until expanded; autocollect resumes normally.
		for cell in w.storage_cells:
			var free=w.Stock.storage_free(w,cell)
			if free>0:w.Stock.add(w,"stone",free,cell).stocked=true
		w.keeper.auto_collect=true;logic_ticks(24)
		check(w.field_items.has(output[0]) and output[0].amount==3,"Full storage never deletes or teleports harvest")
		w.Zones.create(w,"stockpile",Vector2i(33,24),Vector2i(34,24));logic_ticks(140)
		check(w.Stock.summary(w,"mushroom").stored>=3,"Expanded storage receives auto-collected harvest")
		# Cancellation before inoculation returns material; after inoculation leaves crop on bed.
		setup(seed_value);bed(q);stored("mushroom",1,Vector2i(27,23));j=bill(q)
		check(until(func():return w.field_items.any(func(r):return r.get("craft_transfer",false))),"Seed physically in transfer")
		w.Jobs.cancel(w,j.id)
		check(used("mushroom")==0 and w.Stock.totals(w).mushroom==1 and not w.structures[q].has("culture"),"Cancel before seed use returns same physical seed")
		setup(seed_value);bed(q);stored("mushroom",1,Vector2i(27,23));j=bill(q)
		check(until(func():return w.structures[q].has("culture")),"Seeded cancellation fixture")
		var ready_tick=w.structures[q].culture.ready_tick;w.Jobs.cancel(w,j.id);j=bill(q)
		w.tick=ready_tick;w.keeper.pos=q+Vector2i.LEFT;logic_ticks(45)
		check(j.made==3 and used("mushroom")==1,"New bill harvests retained crop without another seed")
		# Forbid/permission changes are reasons, not seed loss or permanent stalls.
		setup(seed_value);bed(q);seedrow=stored("mushroom",1,Vector2i(27,23));seedrow.forbidden=true;j=bill(q);logic_ticks(20)
		check(not w.structures[q].has("culture") and j.get("block_reason","").contains("禁止"),"Forbidden seed reports reason")
		seedrow.forbidden=false;var zone=w.zones.filter(func(z):return Vector2i(27,23) in z.cells)[0];w.Access.set_permission(w,zone,"keeper",false);logic_ticks(20)
		check(not w.structures[q].has("culture") and j.get("block_reason","").contains("権限"),"Seed withdrawal permission reports reason")
		w.Access.set_permission(w,zone,"keeper",true)
		check(until(func():return w.structures[q].has("culture")),"Permission restored resumes same bill")
		# Mixed plan cancellation restores both materials, including interrupted cargo.
		setup(seed_value);stored("wood",8,Vector2i(26,23));stored("soil",4,Vector2i(27,23));w.act("mushroom_bed",q);j=w.jobs[0]
		check(until(func():return w.field_items.any(func(r):return r.get("construction_transfer",false))),"Mixed construction in-flight")
		w.Jobs.cancel(w,j.id)
		check(w.Stock.totals(w)=={"wood":8,"soil":4} and w.field_items.all(func(r):return r.job_id==-1 and r.claims.is_empty()),"Cancellation releases both material types without claims")
		details.append({"seed":seed_value,"checks":checks.size()})
	setup(31);var q=Vector2i(35,25);bed(q);bed(q+Vector2i(3,0));stored("mushroom",2,Vector2i(27,23))
	var peer=w.keeper.duplicate(true);peer.id=-12;peer.name="検証住民";peer.pos=Vector2i(30,27);w.Work.register(w,"helper",peer)
	var one=bill(q);var two=bill(q+Vector2i(3,0))
	check(until(func():return w.structures[q].has("culture") and w.structures[q+Vector2i(3,0)].has("culture"),600),"Two residents inoculate two beds without claim competition")
	check(used("mushroom")==2 and w.Stock.totals(w).get("mushroom",0)==0,"Two beds consume two seeds, never the same physical unit")
	w.tick=maxi(w.structures[q].culture.ready_tick,w.structures[q+Vector2i(3,0)].culture.ready_tick);logic_ticks(160)
	check(one.made==3 and two.made==3 and w.Stock.totals(w).get("mushroom",0)==6,"Two-worker harvest produces exactly six")
	setup(731);bed(q);stored("mushroom",1,Vector2i(27,23));w.keeper.satiety=20;var j=bill(q)
	check(until(func():return used("mushroom")==1),"Hungry worker consumes physical food before planting")
	logic_ticks(30);check(not w.structures[q].has("culture"),"Eaten mushroom cannot also become a seed")
	stored("mushroom",1,Vector2i(27,23));check(until(func():return w.structures[q].has("culture")),"Normal stock replenishment resumes inoculation after meal")
	setup(20261019);bed(q);stored("mushroom",3,Vector2i(27,23));j=bill(q,"stock",3);logic_ticks(80)
	check(not w.structures[q].has("culture") and used("mushroom")==0,"Stock target satisfied: no needless seed/work")
	# One continuous physical chain: seed -> growth -> harvest -> storage -> cooking -> meal.
	setup(31);q=Vector2i(35,25);bed(q);stored("mushroom",1,Vector2i(27,23));j=bill(q)
	check(until(func():return w.structures[q].has("culture")),"Food chain inoculated through actual AI")
	w.tick=w.structures[q].culture.ready_tick;w.keeper.pos=q+Vector2i.LEFT;logic_ticks(60)
	w.Work.Ambient.set_enabled(w,w.keeper,true)
	check(until(func():return w.Stock.summary(w,"mushroom").stored==3),"Harvest auto-collected into real food stockpile")
	ready("cooking_bench",Vector2i(35,28));w.Craft.enqueue(w,Vector2i(35,28),"roast_mushroom","count",5);var cooking=w.jobs.back()
	check(until(func():return not w.jobs.has(cooking)),"Harvested food becomes five cooked portions through ingredient transport/work")
	check(used("mushroom")==3,"Seed1 plus cooking2: no double raw consumption")
	check(until(func():return w.Stock.summary(w,"roast_mushroom").stored==5),"Cooked output automatically physically stored")
	w.keeper.satiety=20
	check(until(func():return used("roast_mushroom")==1),"Meal preference consumes a cooked portion from storage")
	check(w.keeper.satiety>30 and w.Stock.totals(w).get("roast_mushroom",0)==4,"Established satiety20 applied once, four portions retained")
	# Existing hen/cow are fixture-owned; production quantities and day guards unchanged.
	setup(731)
	for species in ["hen","cow"]:
		var id=w.campaign.next_animal_id;w.campaign.next_animal_id+=1
		var owned={"id":id,"species":species,"category":w.SPECIES[species].category,"lv":1,"loyalty":75,"name":"","unavailable_through_day":0}
		w.campaign.animals.append(owned);w.add_resident(owned);w.animals[-1].pos=Vector2i(32,25 if species=="cow" else 28);w.animals[-1].mode="stay"
	w.Cycle.daily(w,2);w.Cycle.daily(w,2)
	check(w.Stock.totals(w).get("egg",0)==1,"Hen dawn guard creates exactly one physical egg/day")
	var cow=w.animals.filter(func(a):return a.species=="cow")[0]
	check(w.act("milk",cow.pos,cow.id),"Cow milk work designated")
	check(until(func():return w.Stock.totals(w).get("milk",0)==1),"Existing worker performs daily milking")
	var milk=w.field_items.filter(func(r):return r.kind=="milk")[0]
	check(not w.Stock.stored(w,milk) and w.distance(milk.pos,cow.pos)<=2 and milk.pos!=w.logistics_entry,"Milk is local physical produce, not teleported to entrance/shared stock")
	check(not w.act("milk",cow.pos,cow.id),"Same cow/day cannot be milked twice")
	w.Work.Ambient.set_enabled(w,w.keeper,true)
	check(until(func():return w.Stock.summary(w,"milk").stored==1 and w.Stock.summary(w,"egg").stored==1),"Egg and milk auto-collected into food storage")
	# A work position inside a full stockpile cannot overfill the physical 40/cell cap.
	setup(731);q=Vector2i(35,25);bed(q);j=bill(q)
	w.structures[q].culture={"seeded_tick":w.tick-3456,"ready_tick":w.tick,"harvest_progress":4.0};j.batch_active=true
	w.Zones.create(w,"stockpile",q-Vector2i.ONE,q+Vector2i.ONE)
	for x in range(q.x-1,q.x+2):
		for y in range(q.y-1,q.y+2):stored("stone",40,Vector2i(x,y))
	w.keeper.pos=q+Vector2i.LEFT;logic_ticks(12)
	check(j.made==0 and w.structures[q].has("culture") and j.get("block_reason","").contains("置き場"),"Full adjacent cells retain mature crop without overcapacity")
	var row=w.field_items.filter(func(r):return r.pos==q+Vector2i.LEFT)[0];row.amount-=3;w.stock_used.stone=w.stock_used.get("stone",0)+3;w.Stock.sync(w);logic_ticks(40)
	check(j.made==3 and w.Stock.storage_used(w,q+Vector2i.LEFT)==40,"Freed capacity resumes harvest and stays at40")
	w.Zones.create(w,"stockpile",Vector2i(38,25),Vector2i(38,25));w.keeper.auto_collect=true;logic_ticks(120)
	check(w.Stock.summary(w,"mushroom").stored==3,"After expanding storage, all harvest is collected without loss")
	# Mixed-material group barrier releases supplied sites when the rest cannot be supplied.
	setup(31);stored("wood",16,Vector2i(26,23));stored("soil",8,Vector2i(27,23))
	var stroke=preload("res://game/wall_stroke.gd").new();stroke.begin("mushroom_bed",Vector2i(35,25));stroke.add(Vector2i(37,25));var preview=stroke.plan(w)
	check(preview.accepted==3 and preview.rows.map(func(r):return r.waiting_material)==[false,false,true],"Mixed preview shares wood and soil budget across three cells")
	stroke.commit(w);var view=preload("res://game/construction_view.gd").new();view.update(w)
	check(view.rows.values().map(func(r):return r.waiting_material)==[false,false,true],"Committed mixed plans match draft material budget")
	check(until(func():return w.metrics.built==2,650),"Supplied two beds build when third has no remaining materials")
	check(used("wood")==16 and used("soil")==8 and w.jobs.size()==1,"One remaining public job; exact two-bed material consumption")
	stored("wood",8,Vector2i(26,23));stored("soil",4,Vector2i(27,23))
	check(until(func():return w.metrics.built==3),"Group resumes last bed after new supply without relocking completed sites")
	check(used("wood")==24 and used("soil")==12 and w.work_claims.is_empty(),"Three-bed mixed group balances all materials and ownership")
	setup(731);q=Vector2i(35,25);bed(q);stored("mushroom",1,Vector2i(27,23));j=bill(q)
	for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:w.trees[Vector2i(27,23)+delta]="fixture"
	w.invalidate_navigation();logic_ticks(20)
	check(j.get("block_reason","").contains("通路") and not j.block_reason.contains("不足"),"Sufficient seed behind closed access reports path, not shortage")
	w.trees.clear();w.invalidate_navigation();check(until(func():return w.structures[q].has("culture")),"Opening route resumes same inoculation job")
	setup(31);ready("cooking_bench",Vector2i(35,25));stored("mushroom",1,Vector2i(27,23));w.Craft.enqueue(w,Vector2i(35,25),"roast_mushroom","count",5);j=w.jobs.back();logic_ticks(20)
	check(j.get("block_reason","").contains("不足") and not j.block_reason.contains("通路"),"One of two ingredients reports real shortage, not path failure")
	# Recipe calories: same established gains/buffs, more portions per batch.
	for recipe in ["roast_mushroom","egg_meal","roast_meat","stew"]:
		var r=w.Craft.Data.RECIPES[recipe];var raw=0
		for kind in r.ingredients:raw+=r.ingredients[kind]*w.Needs.Data.FOOD[kind].satiety
		check(r.count*w.Needs.Data.FOOD[r.output].satiety>raw,"Cooking adds finite nutritional value: "+recipe)
	# All public jobs, including cultivation, share the existing cap.
	setup(731);bed(Vector2i(35,25));ready("cooking_bench",Vector2i(37,25));bill(Vector2i(35,25),"stock",6)
	for i in range(99):w.Craft.enqueue(w,Vector2i(37,25),"roast_mushroom","count",1)
	check(w.jobs.size()==100 and not w.Craft.enqueue(w,Vector2i(37,25),"roast_mushroom","count",1),"100 bills allowed, 101 rejected")
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase2-logic.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail,"rows":details},"  "))
	print("PHASE2_LOGIC ",checks.size()," failures=",fail);quit(1 if fail else 0)
