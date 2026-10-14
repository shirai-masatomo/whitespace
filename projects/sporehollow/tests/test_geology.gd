extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var samples=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func components(cells):
	var left=cells.duplicate();var sizes=[]
	while not left.is_empty():
		var q=[left.keys()[0]];left.erase(q[0]);var i=0
		while i<q.size():
			var p=q[i];i+=1
			for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				if left.has(p+d):left.erase(p+d);q.append(p+d)
		sizes.append(q.size())
	sizes.sort();sizes.reverse();return sizes
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	for seed in [31,97,2026]:
		var t=Time.get_ticks_msec();var w=Farm.new({},seed).begin_day();var elapsed=Time.get_ticks_msec()-t
		var fraction=float(w.terrain.regions.count("rocky"))/(w.W*w.H);var sizes=components(w.rocks)
		check(fraction>=0.25 and fraction<=0.3334,"Rock biome area 1/4 to 1/3: %d"%seed)
		check(w.rocks.size()>500 and sizes[0]>w.rocks.size()*0.8,"Large actual mineable connected mass: %d"%seed)
		check(w.rocks.values().all(func(r):return r.amount==8),"Stone yield unchanged; no new iron drops: %d"%seed)
		check(w.rocks.values().any(func(r):return r.get("geology")=="iron") and w.rocks.values().any(func(r):return r.get("geology")=="stone"),"Iron veins and normal stone coexist: %d"%seed)
		check(w.terrain.materials.has("clay") and w.terrain.materials.has("sand"),"Identifiable clay and sand surface: %d"%seed)
		var reached=w.Biome.reachable(w);var free=0;var blocked_route=0
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y)
				if w.walkable(p):free+=1
				if w.Biome.Geology.route(seed,p,w.W,w.H) and (w.rocks.has(p) or w.trees.has(p) or w.mountain_cells.has(p)):blocked_route+=1
		check(reached.size()==free,"All traversable land remains connected: %d"%seed)
		check(blocked_route==0,"Multiple central transit routes are free of natural obstacles: %d"%seed)
		var path_start=Time.get_ticks_usec();var paths=0
		for p in w.rocks:
			if paths>=20:break
			var goals=w.neighbors(p).filter(func(q):return w.walkable(q))
			if goals.is_empty():continue
			check(not w.find_path(w.keeper.pos,goals[0]).is_empty(),"Reachable mining perimeter: %d/%d"%[seed,paths]);paths+=1
		samples.append({"seed":seed,"new_world_ms":elapsed,"region_fraction":fraction,"rock_cells":w.rocks.size(),"component_sizes":sizes,"iron_cells":w.rocks.values().filter(func(r):return r.get("geology")=="iron").size(),"twenty_paths_ms":(Time.get_ticks_usec()-path_start)/1000.0})
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/geology.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"failures":failed},"\t"))
	print("GEOLOGY: ",checks.size()," checks, failures=",failed);quit(1 if failed else 0)
