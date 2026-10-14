extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w)
	w.animals.clear();w.keeper.pos=Vector2i(30,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason="";w.refresh_indoor();w.nature_config.spawn_chance_per_second=0
	return w
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=fixture();var peer=w.keeper.duplicate(true);peer.id=-2;peer.name="職人";peer.pos=Vector2i(30,27);w.Work.register(w,"artisan",peer)
	var material={"wood":35,"fiber":12,"mushroom":12,"egg":6,"milk":4,"meat":8};var i=0
	for kind in material:
		var pos=Vector2i(29+i,22);w.Zones.create(w,"stockpile",pos,pos);w.Stock.add(w,kind,material[kind],pos).stocked=true;i+=1
	var benches={"cooking_bench":Vector2i(37,24),"carpentry_bench":Vector2i(37,26),"sewing_bench":Vector2i(37,28)}
	for kind in benches:
		check(w.act(kind,benches[kind]),"Bench build can be designated: "+kind)
	# Cost is 36 wood; rest is delivered explicitly, not minted from a virtual account.
	w.Zones.create(w,"stockpile",Vector2i(28,22),Vector2i(28,22));w.Stock.add(w,"wood",30,Vector2i(28,22)).stocked=true
	for n in range(1000):
		w.step()
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and benches.values().all(func(pos):return w.structures.get(pos,{}).get("status")=="ready"),"Three benches built by real delivery/construction AI")
	for recipe in w.Craft.Data.RECIPES:
		check(w.Craft.enqueue(w,benches[w.Craft.Data.RECIPES[recipe].bench],recipe,"count",1),"Recipe bill: "+recipe)
	var initial=w.Stock.totals(w);var start_used=w.stock_used.duplicate();var seen_owners={};var max_cargo=0;var conservation=true;var resumed=false
	for n in range(1500):
		w.step()
		for worker in w.workers.values():
			var count=0
			for r in w.Stock.cargo(w,worker.work_key):count+=r.amount
			max_cargo=maxi(count,max_cargo)
			var j=w.Work.active(w,worker.work_key)
			if j.get("kind")=="craft":seen_owners[worker.work_key]=true
		if n==30:
			var before=w.Stock.totals(w);check(w.Snapshot.save(w,out+"/craft-inflight.snapshot"),"Craft snapshot fixture written")
			var restored=w.Snapshot.restore(out+"/craft-inflight.snapshot")
			check(restored!=null and restored.Stock.totals(restored)==before,"In-flight claims/cargo restore without duplication")
			if restored!=null:w=restored;resumed=true
		var totals=w.Stock.totals(w)
		for kind in material:
			if totals.get(kind,0)+w.stock_used.get(kind,0)-start_used.get(kind,0)!=initial.get(kind,0):conservation=false
		if w.jobs.is_empty():break
	check(w.jobs.is_empty(),"All seven bills finish through production World.step")
	check(seen_owners.size()==2,"Two residents both participate without duplicate bench ownership")
	check(max_cargo<=20 and conservation and resumed,"Carry cap and material conservation through interruption/reload")
	for recipe in w.Craft.Data.RECIPES:check(w.Stock.totals(w).get(recipe,0)==1,"Physical finished output: "+recipe)
	# A low-stamina worker keeps the same accepted job while resting.
	w.Craft.enqueue(w,benches.sewing_bench,"fiber_clothes","count",1)
	var bill=w.jobs.back();w.Work.claim(w,"keeper",bill);w.keeper.needs_rest=true;w.keeper.stamina=10;w.Work.step(w)
	check(w.Work.active(w,"keeper").get("id")==bill.id,"Stamina rest retains current job identity")
	w.keeper.stamina=80;w.keeper.needs_rest=false;w.Jobs.cancel(w,bill.id)
	# Clothing uses its own slot and a physical pickup, with no armor effects.
	w.keeper.equipment={"item_id":"wood_staff","durability":-1}
	check(w.HumanCombat.equip(w,"fiber_clothes"),"Human clothing action accepted")
	for n in range(300):
		w.step()
		if not w.keeper.get("clothing",{}).is_empty():break
	check(w.keeper.get("clothing",{}).get("item_id")=="fiber_clothes" and w.keeper.equipment.item_id=="wood_staff","Clothing is physically equipped without replacing weapon")
	check(w.Stock.summary(w,"fiber_clothes").equipped==1,"Equipped clothing remains in ownership accounting")
	# Target-stock schedules are bounded to one player job each, cap includes bills.
	w.jobs.clear()
	for n in range(100):check(w.Craft.enqueue(w,benches.cooking_bench,"roast_mushroom","stock",1),"Bill slot "+str(n+1))
	check(not w.Craft.enqueue(w,benches.cooking_bench,"roast_mushroom","stock",1),"101st bill rejected")
	var fail=checks.filter(func(c):return not c.passed).size();FileAccess.open(out+"/craft-integration.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail,"maximum_cargo":max_cargo,"tick":w.tick},"\t"));print("CRAFT_INTEGRATION: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
