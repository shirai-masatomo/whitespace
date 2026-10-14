extends "res://tests/test_scale_logic.gd"
const Evaluation=preload("res://game/job_evaluation.gd")
var failures=0
var checks=[]
func check(ok: bool,note: String):
	checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func building(kind: String,id: int=1):return {"id":id,"kind":kind,"status":"ready","hp":100,"max_hp":100,"open":false}
func equivalent(w,kind,p):
	var predicted=w.Buildings.rooms(w,{"kind":kind,"pos":p})
	var expected=w.animals.any(func(a):return a.placed and not w.SPECIES[a.species].can_enter_indoor and predicted.has(a.pos))
	check(w.Buildings.encloses_outdoor_animal(w,kind,p)==expected,"Local enclosure matches whole-map reference: %s %s"%[kind,p])
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=fixture(1);w.animals[0].pos=Vector2i(12,12)
	for y in range(10,15):
		for x in range(10,15):
			var p=Vector2i(x,y)
			if x in [10,14] or y in [10,14]:w.structures[p]=building("wall")
			else:w.floors[p]=building("soil_tile")
	var gap=Vector2i(12,10);w.structures.erase(gap)
	check(w.Buildings.reason(w,"wall",gap,false)=="先に犬を外へ誘導","Last wall rejects enclosing a dog")
	equivalent(w,"wall",gap);equivalent(w,"door",gap)
	w.structures[gap]=building("door");w.structures[gap].open=true
	var tile=Vector2i(11,12);w.floors.erase(tile)
	check(w.Buildings.reason(w,"soil_tile",tile,false)=="先に犬を外へ誘導","Last floor rejects enclosure even with an open door")
	equivalent(w,"soil_tile",tile)
	w.animals[0].pos=Vector2i(20,20)
	check(w.Buildings.reason(w,"soil_tile",tile,false)=="","Construction allowed after dog leaves")
	var rng=RandomNumberGenerator.new();rng.seed=731
	for sample in range(80):
		w.structures.clear();w.floors.clear()
		var origin=Vector2i.ZERO if sample%4==0 else Vector2i(10,10)
		for y in range(7):
			for x in range(7):
				var p=origin+Vector2i(x,y)
				if rng.randf()<0.35:w.structures[p]=building("wall" if rng.randf()<0.7 else "door")
				if rng.randf()<0.85:w.floors[p]=building("soil_tile")
		w.animals[0].pos=origin+Vector2i(rng.randi_range(0,6),rng.randi_range(0,6));w.structures.erase(w.animals[0].pos)
		var proposed=origin+Vector2i(rng.randi_range(0,6),rng.randi_range(0,6))
		if proposed==w.animals[0].pos:proposed+=Vector2i.RIGHT
		equivalent(w,"wall" if sample%2==0 else "soil_tile",proposed)
	w=fixture(1);var stroke=Stroke.new();stroke.begin("wall",Vector2i(10,20));stroke.add(Vector2i(19,20))
	Metrics.enabled=true;Metrics.take();stroke.plan(w);var first=Metrics.take();stroke.plan(w);var second=Metrics.take();stroke.add(Vector2i(20,20));stroke.plan(w);var third=Metrics.take();Metrics.enabled=false
	check(first.get("keeper_jobs.build_reason",0)==10 and second.get("keeper_jobs.build_reason",0)==0 and third.get("keeper_jobs.build_reason",0)==1,"Unchanged preview does no cell validation; extension validates one new cell")
	w.animals[0].pos=Vector2i(15,20)
	check(stroke.plan(w).accepted==10,"Paused same-tick occupancy invalidates preview")
	w.trees[Vector2i(16,20)]={}
	check(stroke.commit(w).accepted==9,"Release revalidates tree and animal occupancy")
	var cancelled=w.jobs[0].pos;w.Jobs.cancel(w,w.jobs[0].id)
	check(w.act("wall",cancelled) and not w.act("wood_wall",cancelled),"Fresh transaction sees cancellation and layer conflict")
	w=fixture(1);stroke=Stroke.new();stroke.kind="wall"
	for i in range(101):var p=Vector2i(10+i%20,30+i/20);stroke.cells.append(p);stroke.seen[p]=true
	check(stroke.commit(w).accepted==100 and w.jobs.size()==100 and not w.act("wall",Vector2i(8,20)),"100 reservations accepted and 101st rejected")
	var target=w.jobs[0];w.Jobs.complete(w,target,false)
	check(w.act("wall",target.pos),"Completion releases reservation index for next transaction")
	for mode in ["open","blocked","door","door_open"]:
		w=fixture(1)
		for i in range(50):w.act("wall",Vector2i(30+i%10,30+i/10))
		if mode!="open":
			for y in range(0,50):w.structures[Vector2i(35,y)]=building("wall")
			if mode in ["door","door_open"]:w.structures[Vector2i(35,28)]=building("door");w.structures[Vector2i(35,28)].open=mode=="door_open"
		var evaluation=Evaluation.new(w,w.keeper.pos)
		for j in w.jobs:
			var goals=w.neighbors(j.pos);var route=w.Jobs.path_to(w,w.keeper.pos,goals)
			var expected=INF if route.is_empty() else float(route.size()-1)
			check(evaluation.distance_to(w,goals)==expected,"Evaluation distance preserves legacy goal order/cost: "+mode)
		var expected_job={};var best=INF
		for j in w.jobs:
			if w.Buildings.reason(w,j.kind,j.pos,false)!="":continue
			var score=w.Work.score(w,j,w.Work.effort(w,w.keeper,j))
			if score<best:best=score;expected_job=j
		var actual=w.Work.choose(w,"keeper")
		check(actual.get("id",-1)==expected_job.get("id",-1),"Selected job unchanged: "+mode)
	w=fixture(1);var g=Main.new();g.world=w;g.group=-1;g.drag_start=Vector2.ZERO
	for i in range(1000):w.trees[Vector2i(i%100,i/100)]={}
	var area=Rect2(0,0,4800,420)
	var old=g.selection_candidates(area,true);g.drag_class="tree"
	for c in old:
		if c["class"]=="tree":g.drag_ranks[[c["class"],c.id]]=g.drag_ranks.size()
	check(g.selection_candidates(area,true,true).is_empty(),"Previously encountered static candidates need no repeat sort")
	w.trees.erase(Vector2i(0,0));w.trees[Vector2i(2,12)]={}
	var updated=g.selection_candidates()
	check(not updated.any(func(c):return c["class"]=="tree" and c.id==Vector2i.ZERO) and updated.any(func(c):return c["class"]=="tree" and c.id==Vector2i(2,12)),"Tree addition/removal invalidates selection catalog")
	g.group=1;var before=g.selection_candidates()[0].point;w.animals[0].pos+=Vector2i.RIGHT
	check(g.selection_candidates()[0].point!=before,"Moving animal points remain live, outside static cache")
	g.free()
	FileAccess.open(out+"/scale-correctness.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Scale correctness: ",checks.size()," checks, ",failures," failures");quit(1 if failures else 0)
