extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var template
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func fresh():
	var w=Farm.new(template.duplicate(true),31).begin_day();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.jobs.clear();w.animals.clear();w.mountains.clear();w.Mountains.reindex(w);w.trees.clear();w.rocks.clear();w.natural.clear();w.structures.clear();w.nature_config.spawn_chance_per_second=0;w.paused=false;w.keeper.pos=Vector2i(12,12)
	for key in w.keeper.work_priorities:w.keeper.work_priorities[key]=1 if key=="haul" else 0
	return w
func ticks(w,n=120):
	for i in range(n):w.step()
func setup(w,amount=39):
	w.Zones.create(w,"stockpile",Vector2i(14,12),Vector2i(14,12));w.Stock.add(w,"wood",amount,Vector2i(14,12));w.Stock.add(w,"wood",8,Vector2i(10,12));w.Stock.designate(w,"haul",Vector2i(10,12),Vector2i(10,12))
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="":quit(2);return
	var initial=Farm.new({},31);initial.persist_farm();template=initial.campaign
	var w=fresh();setup(w);ticks(w)
	check(w.Stock.summary(w,"wood").stored==40 and w.Stock.summary(w,"wood").outside==7 and w.Stock.summary(w,"wood").carried==0,"39 occupied: deliver only one, seven stay at source")
	check(w.jobs.size()==1 and w.jobs[0].get("block_reason","")=="備蓄が満杯です","Full storage retains blocked designation with clear reason")
	var pos=w.keeper.pos;ticks(w,48);check(w.keeper.pos==pos and w.Stock.summary(w,"wood").owned==47,"Full storage does not repeatedly pickup/drop or travel")
	w.Zones.create(w,"stockpile",Vector2i(15,12),Vector2i(15,12));ticks(w)
	check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored==47,"Adding another zone automatically resumes remaining seven")
	w=fresh();setup(w,1);ticks(w);check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored==9,"39 free: normal carry-eight completes")
	w=fresh();setup(w,40);ticks(w,24);check(w.Stock.summary(w,"wood").outside==8 and w.Stock.summary(w,"wood").carried==0,"Completely full: no pickup")
	w.Stock.consume(w,"wood",8);ticks(w);check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored==40,"Consumption frees reserved capacity and resumes automatically")
	w=fresh();setup(w,39);var helper=w.keeper.duplicate(true);helper.pos=Vector2i(10,14);w.Work.register(w,"helper",helper);w.Stock.add(w,"stone",8,Vector2i(10,15));w.Stock.designate(w,"haul",Vector2i(10,15),Vector2i(10,15));var maximum=0;var reserved_max=0
	for i in range(100):
		w.step();maximum=maxi(maximum,w.Stock.storage_used(w,Vector2i(14,12)))
		var reserved=0
		for j in w.jobs:reserved+=j.get("storage_amount",0)
		reserved_max=maxi(reserved_max,w.Stock.storage_used(w,Vector2i(14,12))+reserved)
	check(maximum==40 and reserved_max<=40 and w.Stock.totals(w)=={"wood":47,"stone":8},"Two workers cannot double-book the last free slot or lose goods")
	w.Zones.create(w,"stockpile",Vector2i(15,12),Vector2i(16,12));ticks(w,160)
	check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored+w.Stock.summary(w,"stone").stored==55,"Two workers finish after expansion across multiple cells")
	w=fresh();setup(w,30);w.Zones.create(w,"stockpile",Vector2i(12,13),Vector2i(12,13));check(w.Stock.storage_plan(w,w.keeper,8,"wood").pos==Vector2i(14,12),"Same-kind consolidation outranks nearer empty cell")
	for i in range(40):
		w.step()
		if w.Stock.summary(w,"wood").carried>0:break
	check(w.Stock.summary(w,"wood").carried==8,"Real worker picked up eight for save fixture")
	w.Snapshot.save(w,out+"/carry.snapshot");var saved=w.Snapshot.restore(out+"/carry.snapshot");check(saved.jobs[0].get("storage_amount",0)==8,"Destination capacity reservation survives snapshot")
	ticks(saved);check(saved.jobs.is_empty() and saved.Stock.summary(saved,"wood").stored==38,"Restored carrier delivers once with exact totals")
	w=fresh();setup(w,0);w.Zones.set_allowed(w,w.zones[0].id,["stone"]);ticks(w,24);check(w.jobs[0].get("block_reason","")=="この物資を受け入れる備蓄がありません" and w.Stock.summary(w,"wood").carried==0,"Filter mismatch has distinct waiting reason")
	w.Zones.set_allowed(w,w.zones[0].id,["wood"]);ticks(w);check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored==8,"Allowing material resumes waiting haul")
	FileAccess.open(out+"/map-storage.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks},"  "));quit(0 if checks.all(func(c):return c.passed) else 1)
