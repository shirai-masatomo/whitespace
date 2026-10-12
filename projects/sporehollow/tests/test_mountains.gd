extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failures=0
var out=""
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.rocks.clear();w.mountains.clear();w.Mountains.reindex(w);w.natural.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.Stock.sync(w);w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999;w.keeper.pos=Vector2i(9,13);w.keeper.sleepiness=0;w.keeper.satiety=100;w.animals[0].pos=Vector2i(7,13)
	return w
func ticks(w,n):
	for i in range(n):w.step()
func total(w):return w.Stock.totals(w).get("stone",0)
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=farm();var p=Vector2i(10,10);var r=w.Mountains.add(w,"large",p)
	check(not r.is_empty() and w.mountains.size()==1 and w.Mountains.footprint(r).size()==16,"4x4 mountain is one object, distinct from cell rocks")
	check(w.Mountains.footprint(r).all(func(c):return w.Mountains.at(w,c).id==r.id and not w.walkable(c)),"All sixteen footprint cells select the same ID and block paths")
	check(w.Buildings.reason(w,"wood_tile",p,false)=="先に岩を採掘してください","Construction rejects every occupied mountain cell")
	check(w.Tasks.designate(w,"mine",p+Vector2i(3,3)) and not w.Tasks.designate(w,"mine",p+Vector2i(1,1)),"Any occupied cell designates one job without duplicate")
	var id=r.id;var j=w.jobs.back();var job_id=j.id
	var worker=w.keeper.duplicate(true);worker.pos=Vector2i(14,13);w.Work.register(w,"helper",worker)
	ticks(w,5)
	check(w.work_claims.size()==1 and w.jobs.size()==1 and r.elapsed>0,"Multiple workers claim this mountain only once")
	var saved=r.elapsed;w.paused=true;ticks(w,8);check(r.elapsed==saved,"PAUSE does not mine");w.paused=false
	w.Work.set_drafted(w,j.assigned_to,true);w.keeper.work_priorities.gather=0;worker.work_priorities.gather=0;ticks(w,4)
	check(r.elapsed==saved,"Draft interruption retains resource progress")
	w.Work.set_drafted(w,"keeper",false);w.Work.set_drafted(w,"helper",false);w.keeper.work_priorities.gather=1
	w.Tasks.set_forbidden(w,"mine",p,-1,true);ticks(w,5);check(r.elapsed==saved,"Forbid retains progress")
	w.Tasks.set_forbidden(w,"mine",p,-1,false);w.Jobs.cancel(w,job_id);check(r.elapsed==saved and w.jobs.is_empty(),"Cancellation leaves damaged resource and drops intact")
	w.Tasks.designate(w,"mine",p);job_id=w.jobs.back().id
	w.Snapshot.save(w,out+"/partial.snapshot");w=w.Snapshot.restore(out+"/partial.snapshot");r=w.mountains[id]
	check(r.elapsed==saved and w.jobs.back().mountain_id==id,"Save/restart preserves partial progress and ID")
	var seen=[r.stage];var footprints=[16];var guard=0
	while r.remaining>0 and guard<300:
		w.step();guard+=1
		if r.stage not in seen:
			seen.append(r.stage);footprints.append(w.Mountains.footprint(r).size())
			check(total(w)==r.batches*16,"One physical batch per transition "+str(r.stage))
			check(w.field_items.all(func(item):return w.walkable(item.pos) and item.pos not in w.Mountains.footprint(r)),"Drops stay outside occupied mountain "+str(r.stage))
			w.Snapshot.save(w,out+"/stage.snapshot");var restored=w.Snapshot.restore(out+"/stage.snapshot")
			check(restored.mountains==w.mountains and restored.field_items==w.field_items and restored.mountain_cells==w.mountain_cells,"Transition snapshot identity "+str(r.stage))
	check(seen==[0,1,2,3,4] and footprints==[16,12,6,2,0],"Single designation reaches all stages and shrinking footprint")
	check(total(w)==64 and w.Stock.available(w,"stone")==0 and w.jobs.is_empty(),"Exactly 64 physical stones, no instant shared inventory")
	check(w.walkable(p) and w.Buildings.reason(w,"wood_tile",p,false)=="" and not w.find_path(Vector2i(9,10),p).is_empty(),"Released ground permits building and navigation")
	w.Snapshot.save(w,out+"/depleted.snapshot");var done=w.Snapshot.restore(out+"/depleted.snapshot");ticks(done,5)
	check(done.mountains[id].remaining==0 and total(done)==64,"Depleted object never respawns or duplicates resources on restart")
	w.persist_farm();var campaign=Farm.new(w.campaign,31)
	check(campaign.mountains[id].remaining==0,"Campaign persistence retains depleted mountain")
	w.Zones.create(w,"stockpile",Vector2i(6,10),Vector2i(7,11));w.Stock.designate(w,"haul",Vector2i(0,0),Vector2i(49,33));ticks(w,600)
	if w.Stock.available(w,"stone")!=64:
		for i in range(12):
			print("HAUL_TRACE ",w.keeper.pos," helper=",w.workers.helper.pos," dest=",w.Stock.destination(w,w.keeper,8,"stone")," jobs=",w.jobs);w.step()
	check(w.Stock.available(w,"stone")==64,"Explicit hauling supplies stockpile with all four batches")
	w=farm();r=w.Mountains.add(w,"small",p);w.Tasks.designate(w,"mine",p);ticks(w,80)
	check(r.stage==3 and r.remaining==0 and total(w)==12 and w.walkable(p),"Small object has three batches and releases its single cell")
	w=farm();r=w.Mountains.add(w,"large",p);w.Stock.designate(w,"mine",p+Vector2i(2,2),p+Vector2i(3,3))
	check(w.jobs.size()==1,"Rectangle designation intersects object without including its origin")
	w.Stock.designate(w,"clear",p+Vector2i(2,2),p+Vector2i(3,3));check(w.jobs.is_empty(),"Rectangle cancellation matches footprint, not only origin")
	w.Stock.designate(w,"forbid",p+Vector2i(3,3),p+Vector2i(3,3));check(r.forbidden,"Range forbid works from far corner")
	w.Stock.designate(w,"allow",p+Vector2i(3,3),p+Vector2i(3,3));check(not r.forbidden,"Range allow preserves same object")
	w=farm();r=w.Mountains.add(w,"large",p);w.Tasks.designate(w,"mine",p);ticks(w,8);saved=r.elapsed
	w.Life.set_rest(w,true);ticks(w,12);check(r.elapsed==saved,"Manual sleep suspends without losing progress")
	w.Life.set_rest(w,false);ticks(w,4);check(r.elapsed>saved,"Wake resumes the same mining designation")
	w.Zones.create(w,"stockpile",Vector2i(8,12),Vector2i(8,12));w.Stock.add(w,"mushroom",3,Vector2i(8,12));w.keeper.satiety=20;w.keeper.erase("food_retry_at");saved=r.elapsed;ticks(w,1)
	check(r.elapsed==saved and w.keeper.get("life_need","")=="food","Hunger interrupts mining to obtain real stored food")
	var food_wait=0
	while w.keeper.satiety<30 and food_wait<100:w.step();food_wait+=1
	ticks(w,8);check(w.keeper.satiety>30 and (r.elapsed>saved or r.stage>0),"After eating the existing designation resumes")
	w=farm();r=w.Mountains.add(w,"large",p);w.Tasks.designate(w,"mine",p)
	while r.elapsed<7.75:w.step()
	w.Snapshot.save(w,out+"/threshold.snapshot");var threshold=w.Snapshot.restore(out+"/threshold.snapshot");ticks(w,2);ticks(threshold,2)
	check(w.mountains==threshold.mountains and w.field_items==threshold.field_items and total(w)==16,"Saving immediately before stage transition does not duplicate a batch")
	for seed_number in [1,17,31,97,2026]:
		w=Farm.new({},seed_number).begin_day();var copy=Farm.new({},seed_number).begin_day()
		check(w.mountains==copy.mountains,"Deterministic generation seed "+str(seed_number))
		check(w.mountains.values().any(func(a):return a.kind=="large") and w.mountains.values().any(func(a):return a.kind=="small"),"Both object kinds generated seed "+str(seed_number))
		var valid=true;var reached=w.Biome.reachable(w)
		for a in w.mountains.values():
			for c in w.Mountains.footprint(a):
				if w.Biome.protected(w,c) or w.occupied(c) or w.rocks.has(c) or w.trees.has(c) or c in w.storage_cells or not w.items_at(c).is_empty():valid=false;print("OVERLAP ",seed_number," ",a," cell=",c," tree=",w.trees.has(c)," rock=",w.rocks.has(c)," occupied=",w.occupied(c)," protected=",w.Biome.protected(w,c))
			if w.Mountains.goals(w,a).filter(func(c):return reached.has(c)).is_empty():valid=false;print("UNREACHABLE ",seed_number," ",a)
		check(valid,"No protected/object overlap and reachable work face seed "+str(seed_number))
		w.persist_farm();var old=w.campaign.duplicate(true);old.erase("mining_mountains");var legacy=Farm.new(old,seed_number)
		check(legacy.mountains.is_empty(),"Old save does not gain new mountains seed "+str(seed_number))
	FileAccess.open(out+"/mountains.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("MOUNTAINS: ",checks.size()," checks, failures=",failures);quit(1 if failures else 0)
