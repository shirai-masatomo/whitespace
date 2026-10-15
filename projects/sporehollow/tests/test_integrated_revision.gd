extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var measurements=[]
var map_proofs=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w);w.refresh_indoor()
	w.keeper.pos=Vector2i(50,34);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason="";w.animals.clear()
	return w
func zones(w):
	var a=w.Zones.create(w,"stockpile",Vector2i(10,10),Vector2i(12,10));var b=w.Zones.create(w,"stockpile",Vector2i(14,10),Vector2i(16,10))
	w.Zones.rename(w,a,"工房資材");w.Zones.set_priority(w,a,2);w.Zones.filter_change(w,a,"all","",false);w.Zones.filter_change(w,a,"items","wood",true)
	var row=w.Stock.add(w,"wood",20,Vector2i(11,10));var id=row.stock_id
	check(w.Zones.create(w,"stockpile",Vector2i(13,10),Vector2i(13,10))==a and w.zones.size()==1,"Adjacent zones merge under oldest ID")
	check(w.zones[0].name=="工房資材" and w.zones[0].priority==2 and w.Zones.accepts_item(w,w.zones[0],"wood") and not w.Zones.accepts_item(w,w.zones[0],"stone"),"Merge preserves deterministic name/filter/priority")
	check(w.Zones.subtract(w,[Vector2i(13,10)])==1 and w.zones.size()==2,"Removing bridge splits four-connected zone")
	check(w.zones.all(func(z):return z.priority==2 and z.filter==w.zones[0].filter),"Split inherits filters/priority")
	check(w.Zones.find(w,a).cells.has(Vector2i(10,10)) and w.zones[1].id!=a and w.zones[1].name!="工房資材","Stable largest/top-left fragment keeps ID; new fragment gets unique name")
	w.Zones.subtract(w,[Vector2i(11,10)])
	check(w.Stock.find(w,id).amount==20 and w.Stock.find(w,id).pos==Vector2i(11,10),"Zone removal never removes or relocates physical goods")
	w.zones.clear();w.Zones.sync_storage(w)
	for i in range(10):w.Zones.create(w,"residential",Vector2i(5+i*3,20),Vector2i(7+i*3,20)) # adjacent by design merges
	check(w.zones.size()==1,"Adjacent repeated strokes remain one zone")
	for i in range(9):w.Zones.create(w,"residential",Vector2i(5+i*3,24),Vector2i(5+i*3,24))
	check(w.zones.size()==10 and w.Zones.create(w,"residential",Vector2i(80,20),Vector2i(80,20))<0,"Ten-zone cap rejects eleventh independent zone")
	w.Zones.subtract(w,[Vector2i(8,20)])
	check(w.zones.size()==10 and not w.zones.any(func(z):return Vector2i(5,20) in z.cells),"Split overflow drops smallest deterministic new fragment only")
func forest():
	for seed_number in [731,991,2026]:
		var start=Time.get_ticks_usec();var data=Farm.Biome.generate(seed_number,100,68);var elapsed=(Time.get_ticks_usec()-start)/1000.0
		var fraction=data.regions.count("woodland")/6800.0;var rock=data.regions.count("rocky")/6800.0
		check(fraction>=0.25 and fraction<=0.33,"Forest area 25-33 percent seed %d"%seed_number)
		check(rock>=0.25 and rock<=0.34,"Rock region retained seed %d"%seed_number)
		measurements.append({"seed":seed_number,"generation_ms":elapsed,"forest_fraction":fraction,"rock_fraction":rock})
		var world=Farm.new({},seed_number).begin_day();var nav=world.RaidNavigation.field(world,false)
		var reachable={}
		for q in nav.distance:reachable[world.terrain.regions[q.y*100+q.x]]=true
		check(["woodland","rocky","dry","open"].all(func(kind):return reachable.has(kind)),"Central camp can reach all principal biomes seed %d"%seed_number)
		check(world.trees.keys().all(func(q):return world.distance(q,Vector2i(50,34))>=5),"Central camp tree clearance seed %d"%seed_number)
		var cells=[]
		for index in range(data.regions.size()):
			if data.regions[index]=="woodland":cells.append(Vector2i(index%100,index/100))
		check(world.Zones.components(cells).size()==1,"Forest is one four-connected region seed %d"%seed_number)
		map_proofs.append({"seed":seed_number,"regions":data.regions,"trees":world.trees.keys().map(func(q):return [q.x,q.y]),"rocks":world.rocks.keys().map(func(q):return [q.x,q.y]),"reachable":nav.distance.keys().map(func(q):return [q.x,q.y])})
func raids(w):
	w.zones.clear();w.Zones.sync_storage(w);w.keeper.placed=false
	# Broad rock barrier with an open northern/southern detour.
	for y in range(12,54):
		for x in range(25,30):w.rocks[Vector2i(x,y)]={"amount":8,"forbidden":false}
	w.refresh_indoor()
	for kind in ["salaryman","ninja","runner","kidnapper","destroyer","martial_artist"]:
		w.spawn_enemy({"role":kind,"archetype":kind,"entry":Vector2i(1,34),"lv":1,"debug_single":true})
		var e=w.enemies.back();e.pos=Vector2i(20,34);e.arrival_complete=true;e.sight_range=2
		var goal=w.RaiderAI.target(e,w);var route=w.RaiderAI.route(e,w,goal,true,false)
		check(route.size()>1 and route.all(func(p):return not w.Story.terrain_block(w,p)),kind+" routes around rock toward central rally")
		var calls=e.get("raid_route_queries",0)
		for i in range(8):w.RaiderAI.route(e,w,goal,true,false)
		check(e.get("raid_route_queries",0)==calls,kind+" reuses route without repeated path search")
		check(not e.can_see_keeper and e.last_known_keeper_position==null,kind+" rally does not reveal keeper position")
	w.enemies.clear();w.keeper.placed=true
func merchant(w):
	w.rocks.clear();w.refresh_indoor();w.campaign.day=2;w.calendar_ticks=1728;w.tick=0;w.Merchant.schedule(w)
	var first=w.merchant_arrive_tick;w.Merchant.schedule(w)
	check(w.merchant_arrive_tick==first and first>=360 and first<540,"Daily seeded visit starts between 10:00 and 12:30")
	w.tick=first;w.calendar_ticks=1728+first;w.Merchant.step(w)
	check(w.merchant_visit.state=="approach" and w.MERCHANT_CELL in w.Land.border_cells(w.W,w.H),"Merchant enters at reachable map border")
	var previous=w.MERCHANT_CELL;var reached=false
	for i in range(500):
		w.tick+=1;w.calendar_ticks+=1;w.Merchant.step(w)
		check(w.MERCHANT_CELL==previous or w.distance(previous,w.MERCHANT_CELL)==1,"Merchant moves through adjacent cells")
		previous=w.MERCHANT_CELL
		if w.merchant_visit.state=="waiting":reached=true;break
	check(reached and w.distance(w.MERCHANT_CELL,w.keeper.pos)>=3,"Merchant stops near resident without overlap")
	check(w.merchant_visit.leave_after-w.tick>=120,"At least thirty seconds of on-site stay")
	check(w.merchant_present() and w.merchant_visit.get("speech","")!="","On-site speech and negotiation available")
	w.calendar_ticks=1728+1008;w.tick+=1;w.Merchant.step(w)
	check(w.merchant_visit.state=="return" and not w.merchant_present(),"Night forces departure and stops new negotiation")
	for i in range(500):
		w.tick+=1;w.Merchant.step(w)
		if w.merchant_visit.state=="gone":break
	check(w.merchant_visit.state=="gone","Merchant exits without permanent night stay")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=fixture();zones(w);forest();raids(w);merchant(w)
	var failures=checks.filter(func(r):return not r.passed).size()
	var file=FileAccess.open(out+"/integrated-revision.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"measurements":measurements,"maps":map_proofs,"failures":failures},"  "));file.close()
	print("INTEGRATED_REVISION ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)
