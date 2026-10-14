extends SceneTree
const Farm=preload("res://game/world.gd")
const View=preload("res://game/rock_view.gd")
const Art=preload("res://game/geology_art.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=Farm.new({},31).begin_day();var started=Time.get_ticks_usec();View.prepare_ground(w);var warm_ms=(Time.get_ticks_usec()-started)/1000.0
	var count=Art.preparations
	for p in w.rocks:
		check(Art.rock(p,View.mask(w,p),w.rocks[p].get("geology")=="iron").get_size()==Vector2(48,54),"Rock asset loaded "+str(p))
	check(Art.preparations==count,"Normal drawing reuses warmed rock cache")
	for mask in range(16):
		for iron in [false,true]:
			var tex=Art.rock(Vector2i(3,5),mask,iron).get_image();var base=Art.source("normal/mask_%02d.png"%mask);var escapes=false
			for y in range(54):
				for x in range(48):
					if base.get_pixel(x,y).a==0 and tex.get_pixel(x,y).a>0:escapes=true
			check(not escapes,"Stone/iron preserve footprint alpha %d/%s"%[mask,iron])
	for kind in ["clay","sand"]:
		var p=Vector2i(w.terrain.materials.find(kind)%w.W,w.terrain.materials.find(kind)/w.W)
		check(Art.surface(w,p,kind).get_size()==Vector2(48,42),"Formal ground patch loaded "+kind)
	# Exercise the existing production mining job on an accessible iron visual cell.
	w.trees.clear();w.natural.clear();w.rocks.clear();w.mountain_cells.clear();w.mountains.clear();w.jobs.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.Stock.sync(w)
	var p=Vector2i(15,11);w.rocks[p]={"amount":8,"forbidden":false,"geology":"iron"};View.prepare_connections(w)
	w.keeper.pos=p+Vector2i.DOWN;w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true;w.campaign.last_supply_day=99999;w.nature_config.spawn_chance_per_second=0
	w.Tasks.designate(w,"mine",p)
	for i in range(160):
		w.step()
		if not w.rocks.has(p):break
	check(not w.rocks.has(p) and w.walkable(p),"Mining iron visual opens the actual cell")
	check(w.Stock.totals(w).get("stone",0)==8 and w.Stock.totals(w).get("iron",0)==0,"Iron visual keeps existing 8-stone yield; no invented iron resource")
	check(not w.rock_connections.has(p),"Mined connection removed")
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/geology-art.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cpu_ground_and_texture_prepare_ms":warm_ms,"cpu_only":true},"\t"))
	print("GEOLOGY_ART: ",checks.size()," checks, failures=",failures," warm_ms=",warm_ms);quit(1 if failures else 0)
