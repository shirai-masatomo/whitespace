extends SceneTree
const Farm=preload("res://game/world.gd")
var failed=0
var checks=[]
var out=""
func _initialize():call_deferred("run")
func check(ok: bool,note: String):
	checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.rocks.clear();w.zones.clear();w.Zones.sync_storage(w);w.storage_cells.clear();w.stock_used.clear();w.campaign.last_supply_day=9999;w.nature_config.spawn_chance_per_second=0
	w.story.intro_seen=true;w.keeper.pos=Vector2i(8,10);w.keeper.satiety=100;w.animals[0].pos=Vector2i(3,3);w.animals[0].mode="stay";w.Stock.sync(w);return w
func stock(w,kind: String,n: int,pos: Vector2i) -> Dictionary:
	w.Zones.create(w,"stockpile",pos,pos);return w.Stock.add(w,kind,n,pos)
func ticks(w,n: int):
	for i in range(n):w.step()
func done(w,count: int,n: int=400):
	for i in range(n):
		w.step()
		if w.metrics.built>=count:break
func helper(w,key: String,pos: Vector2i):
	var a=w.keeper.duplicate(true);a.pos=pos;a.name=key;a.satiety=100;w.Work.register(w,key,a);return a
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();var cells={}
	for row in w.field_items:cells[row.pos]=true
	check(cells.size()==w.field_items.size(),"New initial goods occupy distinct physical cells")
	check(w.field_items.all(func(r):return w.Stock.stored(w,r) and r.amount<=w.Work.Policy.STORAGE_CAPACITY),"Initial goods are valid stockpile stacks")
	check(w.Stock.available(w,"soil")==100,"Initial stock is immediately usable")
	var before=w.field_items.duplicate(true);w.Snapshot.save(w,out+"/initial.snapshot");w=w.Snapshot.restore(out+"/initial.snapshot")
	check(w.field_items==before,"Restore does not rearrange initial goods or IDs")
	w=farm();var stack_pos=Vector2i(6,10);w.Stock.add(w,"wood",3,stack_pos);w.Stock.add(w,"wood",5,stack_pos)
	var raw=w.field_items.duplicate(true);var display=preload("res://game/stock_view.gd").rows(w)
	check(display.size()==1 and display[0].amount==8 and display[0].ids.size()==2 and w.field_items==raw,"Rendering combines same-kind stack labels without changing any physical ID or quantity")
	w=farm();var row=w.Stock.add(w,"wood",8,Vector2i(5,10));w.Stock.add(w,"mushroom",2,Vector2i(6,10));w.keeper.satiety=20
	check(w.act("wood_tile",Vector2i(10,10)),"A plan can be placed before materials arrive")
	ticks(w,20);check(w.metrics.built==0 and w.Stock.available(w,"wood")==0 and w.stock_used.get("mushroom",0)==0,"Uncollected off-stock materials and food are not used")
	w.Zones.create(w,"stockpile",Vector2i(5,12),Vector2i(6,12));var positions=w.field_items.map(func(r):return r.pos)
	check(w.field_items.map(func(r):return r.pos)==positions and w.jobs.size()==1,"Zone creation does not move goods or create hidden hauling")
	check(w.Stock.designate(w,"haul",Vector2i(5,10),Vector2i(6,10)).accepted==2,"Explicit collection creates the two transport designations")
	done(w,1,500);ticks(w,100);check(w.metrics.built==1 and w.stock_used.get("mushroom",0)>=1,"Collected materials build and stored food feeds the sole worker")
	w=farm();stock(w,"wood",8,Vector2i(6,10));w.act("wood_tile",Vector2i(11,10));w.act("wood_tile",Vector2i(12,10));var count=w.jobs.size()
	w.step();var task=w.build_deliveries.get("keeper",{})
	check(not task.is_empty() and task.allocations.size()==2 and w.jobs.size()==count,"Nearby sites share one internal delivery with no added designation")
	var reserved=0
	for item in w.field_items:
		for n in item.claims.values():reserved+=n
	check(reserved<=8,"Batched delivery respects total carrying capacity")
	done(w,2);check(w.metrics.built==2 and w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==8,"One person completes batched supply and assembly without duplication")
	w=farm();var hauler=helper(w,"hauler",Vector2i(9,12));w.keeper.work_priorities={"build":1,"gather":0,"collect":0,"animal":0,"other":0,"haul":0};hauler.work_priorities={"build":0,"gather":0,"collect":0,"animal":0,"other":0,"haul":1}
	stock(w,"wood",8,Vector2i(5,10));w.act("wood_tile",Vector2i(12,10));w.act("wood_tile",Vector2i(13,10));done(w,2)
	check(w.metrics.built==2,"Separate hauling-only and building-only people cooperate")
	check(w.job_log.any(func(r):return r.event=="materials_delivered" and r.worker=="hauler") and w.job_log.filter(func(r):return r.event=="assigned").all(func(r):return r.worker=="keeper"),"Hauler delivers; builder assembles")
	w=farm();stock(w,"wood",8,Vector2i(6,10));w.act("wood_tile",Vector2i(12,10));w.act("wood_tile",Vector2i(13,10))
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	before=w.Stock.totals(w);check(w.Snapshot.save(w,out+"/delivery.snapshot"),"Active multi-site transport saves")
	w=w.Snapshot.restore(out+"/delivery.snapshot");check(w.build_deliveries.has("keeper") and not w.Stock.cargo(w,"keeper").is_empty(),"Transport assignments, cargo and reservation IDs restore")
	w.Work.set_drafted(w,"keeper",true);check(w.Stock.totals(w)==before and not w.build_deliveries.has("keeper"),"Drafting releases the internal task without losing withdrawn goods")
	w.Work.set_drafted(w,"keeper",false);done(w,2);check(w.metrics.built==2 and w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==8,"Interrupted transfer resumes from its actual dropped location")
	w=farm();stock(w,"wood",8,Vector2i(6,10));w.act("wood_tile",Vector2i(12,10));w.act("wood_tile",Vector2i(13,10));w.step();var cancelled=w.jobs[0].id
	w.Jobs.cancel(w,cancelled);done(w,1);check(w.metrics.built==1 and w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==8,"Cancelling one allocation keeps the other and conserves all goods")
	w=farm();var near=Vector2i(9,10);var far=Vector2i(17,10);w.Stock.add(w,"mushroom",1,near);w.Stock.add(w,"wood",1,far)
	w.Stock.designate(w,"haul",near,near);w.jobs.append({"id":w.next_job_id,"kind":"collect","pos":far,"state":"pending","animal_id":-1,"assigned_to":"","queued_tick":w.tick});w.next_job_id+=1;w.Zones.create(w,"stockpile",Vector2i(6,12),Vector2i(7,12));w.keeper.work_priorities.haul=1;w.keeper.work_priorities.collect=1
	var chosen=w.Work.choose(w,"keeper");check(chosen.kind=="haul","Equal priorities choose a nearer later UI column over the earlier column")
	w.Work.release(w,chosen);w.jobs[1].queued_tick=w.tick-10000;chosen=w.Work.choose(w,"keeper");check(chosen.kind=="collect","A long-waiting feasible job gains priority within equal categories")
	w=farm();row=w.Stock.add(w,"wood",4,Vector2i(6,10));w.Zones.create(w,"stockpile",row.pos,row.pos)
	check(w.Stock.available(w,"wood")==0 and not row.get("stocked",false),"A zone over an uncollected pile is not a material receipt")
	w.Stock.designate(w,"haul",row.pos,row.pos);ticks(w,50);check(w.Stock.available(w,"wood")==4,"Explicit pickup/delivery inside the new zone records a real receipt")
	w=farm();row=stock(w,"wood",4,Vector2i(6,10));row.forbidden=true;w.Stock.sync(w);w.act("wood_tile",Vector2i(12,10));ticks(w,10);check(w.metrics.built==0 and w.build_deliveries.is_empty(),"Forbidden stock is not reserved or delivered")
	w=farm();stock(w,"wood",8,Vector2i(6,10));w.act("wood_tile",Vector2i(12,10));w.act("wood_tile",Vector2i(13,10))
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Jobs.preview(w).is_empty(),"Current construction hauling uses the existing real red-route planner")
	check(w.Snapshot.save(w,out+"/restart.snapshot"),"Separate-process restart fixture saves live batch delivery")
	done(w,2)
	var reference={"tick":w.tick,"built":w.metrics.built,"totals":w.Stock.totals(w),"used":w.stock_used,"pos":w.keeper.pos}
	FileAccess.open(out+"/restart-expected.bin",FileAccess.WRITE).store_var(reference,false)
	w=farm();stock(w,"wood",8,Vector2i(6,10));w.act("wood_tile",Vector2i(12,10));w.act("wood_tile",Vector2i(13,10))
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	before=w.Stock.totals(w);w.Jobs.cancel(w,w.jobs[0].id);done(w,1)
	check(w.metrics.built==1 and w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==before.wood,"Cancellation during pickup leaves the remaining site and exact physical goods")
	w=farm();row=stock(w,"wood",4,Vector2i(6,10));w.act("wood_tile",Vector2i(12,10));w.step();before=w.Stock.totals(w)
	w.Zones.remove(w,w.zones[0].id);ticks(w,12)
	check(w.Stock.totals(w)==before and w.Stock.available(w,"wood")==0 and w.metrics.built==0,"Deleting a stockpile preserves its goods but prevents a not-yet-picked transport")
	w.Zones.create(w,"stockpile",row.pos,row.pos);done(w,1);check(w.metrics.built==1,"Restoring an allowed stockpile resumes the valid plan")
	FileAccess.open(out+"/integrated-work.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Production World.step, controlled workers, real material IDs and snapshot restore","checks":checks,"failures":failed},"\t"))
	print("IntegratedWork: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
