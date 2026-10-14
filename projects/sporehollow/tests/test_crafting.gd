extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=Farm.new(Farm.new_campaign(),31).begin_day();w.jobs.clear();w.field_items.clear()
	var a=w.keeper;var pos=a.pos+Vector2i(6,0);var source=a.pos+Vector2i(0,2)
	for cell in [pos,source]+w.neighbors(pos)+w.neighbors(source):w.natural.erase(cell);w.rocks.erase(cell);w.trees.erase(cell);w.structures.erase(cell)
	w.structures[pos]={"id":1001,"kind":"carpentry_bench","status":"ready","open":false,"hp":16,"max_hp":16}
	w.Zones.create(w,"stockpile",source,source);w.Stock.add(w,"wood",12,source).stocked=true
	check(w.Craft.enqueue(w,pos,"wood_crate","count",2),"Fixed bill accepted as one job")
	var j=w.jobs.back();check(w.jobs.size()==1,"Internal delivery does not create extra player jobs")
	w.Craft.prepare(w,j,a);check(w.Stock.available(w,"wood")==7,"Materials reserved once")
	w.Craft.prepare(w,j,a);check(w.Stock.available(w,"wood")==7,"Repeated preparation does not double reserve")
	# Drive normal executor at stock/bench to isolate logistics and completion from path length.
	a.pos=source+Vector2i.LEFT;w.Craft.step(w,j,a)
	check(w.Stock.cargo(w,"keeper",j.id).size()==1,"Physical ingredient pickup")
	w.Work.release(w,j);check(w.field_items.any(func(r):return r.get("craft_transfer",false) and r.location=="ground"),"Interruption keeps cargo at actual location")
	for i in range(500):
		if j not in w.jobs:break
		var carrying=not w.Stock.cargo(w,"keeper",j.id).is_empty()
		a.pos=pos+Vector2i.LEFT if carrying or w.Craft.holding(w,j,"wood")>=5 and w.field_items.any(func(r):return r.location=="site" and r.job_id==j.id) else source+Vector2i.LEFT
		w.Craft.step(w,j,a)
	check(j not in w.jobs and w.Stock.totals(w).get("wood_crate",0)==2 and w.Stock.totals(w).get("wood",0)==2,"Two outputs physical, exactly ten wood consumed")
	check(w.Craft.enqueue(w,pos,"wood_shelf","count",1),"New bill accepted")
	j=w.jobs.back();w.Craft.step(w,j,a)
	check(j.state=="blocked" and not j.block_reason.is_empty(),"Insufficient ingredients wait with reason")
	w.Jobs.cancel(w,j.id)
	w.Stock.add(w,"wood",10,source).stocked=true;w.Craft.enqueue(w,pos,"wood_shelf","count",1);j=w.jobs.back();w.Craft.prepare(w,j,a);a.pos=source+Vector2i.LEFT;w.Craft.step(w,j,a)
	var before=w.Stock.totals(w).get("wood",0);w.structures.erase(pos);w.Jobs.cancel(w,j.id,"target_missing")
	check(w.Stock.totals(w).get("wood",0)==before and not w.field_items.any(func(r):return r.get("job_id",-1)==j.id),"Removed bench refunds unused cargo without loss")
	w.structures[pos]={"id":1002,"kind":"carpentry_bench","status":"ready","open":false};w.Craft.enqueue(w,pos,"wood_crate","stock",2);j=w.jobs.back()
	check(not w.Craft.ready(w,j),"Target-stock bill sleeps when two outputs already exist")
	for r in w.field_items.duplicate():
		if r.kind=="wood_crate":w.field_items.erase(r)
	w.Stock.sync(w)
	check(w.Craft.ready(w,j),"Target-stock bill resumes after stock decreases")
	j.bill_amount=1;w.Craft.prepare(w,j,a)
	var pos2=pos+Vector2i(3,0);w.structures[pos2]={"id":1003,"kind":"carpentry_bench","status":"ready","open":false}
	w.Craft.enqueue(w,pos2,"wood_crate","stock",1);var second=w.jobs.back()
	check(not w.Craft.ready(w,second),"Concurrent target-stock bills include promised output")
	var fail=checks.filter(func(c):return not c.passed).size();FileAccess.open(out+"/crafting.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"));print("CRAFTING: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
