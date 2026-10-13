extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="":quit(2);return
	var stats=[]
	for seed_number in [31,73,109]:
		var start=Time.get_ticks_usec();var w=Farm.new({},seed_number).begin_day()
		var row={"seed":seed_number,"generation_ms":(Time.get_ticks_usec()-start)/1000.0,"large":w.mountains.values().filter(func(r):return r.kind=="large").size(),"materials":{}}
		for m in w.terrain.materials:row.materials[m]=row.materials.get(m,0)+1
		check(["soil","sand","clay","gravel","bedrock"].all(func(k):return row.materials.get(k,0)>0),"All surface types exist: "+str(seed_number))
		check(row.large<=2 and row.large>0,"Large mountain count reduced without removal of system: "+str(seed_number))
		var reached=w.Biome.reachable(w);var regional={};var free=0
		for p in reached:
			var kind=w.Biome.kind(w,p);regional[kind]=regional.get(kind,0)+1
			if w.distance(p,w.Story.at(w))<=8 and not w.occupied(p) and w.items_at(p).is_empty():free+=1
		check(free>=100 and regional.size()==5,"Central building space and access to five regions: "+str(seed_number))
		var near=w.neighbors(w.keeper.pos).filter(func(p):return w.walkable(p))
		check(near.size()>=3,"At least three approaches from starting keeper")
		var block=near[0];w.rocks[block]={"amount":8,"forbidden":false};var alternative=w.Biome.reachable(w);var kinds={}
		for p in alternative:kinds[w.Biome.kind(w,p)]=true
		check(kinds.size()==5,"A blocked start approach still reaches every biome")
		w.rocks.erase(block)
		var mountain=w.mountains.values()[0]
		for mirrored in [false,true]:
			mountain.visual_flip=mirrored
			for stage in range(4):
				mountain.stage=stage;var cells=w.Mountains.footprint(mountain)
				check(cells.size()==[16,12,6,2][stage] and cells.all(func(p):return Rect2i(mountain.pos,Vector2i(4,4)).has_point(p)),"Mirror retains staged occupancy count and bounds")
		mountain.stage=0;w.Mountains.reindex(w)
		w.Tasks.designate(w,"mine",mountain.pos)
		var snapshot=[w.terrain.duplicate(true),w.mountains.duplicate(true),w.jobs.duplicate(true),w.Stock.totals(w)]
		check(w.Snapshot.save(w,out+"/large.snapshot"),"New surfaces/mirrored mountain save")
		var restored=w.Snapshot.restore(out+"/large.snapshot")
		check([restored.terrain,restored.mountains,restored.jobs,restored.Stock.totals(restored)]==snapshot,"Snapshot restores surface types, mirrors, work and quantities exactly")
		stats.append(row)
	var legacy=Farm.Snapshot.restore(OS.get_environment("FARM_LEGACY_FIXTURE")+"/legacy.snapshot")
	var old=[legacy.terrain.duplicate(true),legacy.trees.duplicate(true),legacy.rocks.duplicate(true),legacy.jobs.duplicate(true)]
	legacy.Snapshot.save(legacy,out+"/old.snapshot");var restored=Farm.Snapshot.restore(out+"/old.snapshot")
	check(restored.W==50 and restored.H==34 and [restored.terrain,restored.trees,restored.rocks,restored.jobs]==old,"Legacy map round trip retains exact stored geography/jobs, no regeneration")
	FileAccess.open(out+"/terrain-quality.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"statistics":stats},"  "))
	quit(0 if checks.all(func(c):return c.passed) else 1)
