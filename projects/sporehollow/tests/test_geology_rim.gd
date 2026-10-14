extends SceneTree
const Farm=preload("res://game/world.gd")
const Groups=preload("res://tests/test_geology.gd")
const Visual=preload("res://tests/review_geology_cpu.gd")
const Rock=preload("res://game/rock_view.gd")
var checks=[]
var samples=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func straight(w):
	var longest=0;var long_edges=0
	for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var along=Vector2i.RIGHT if d.x==0 else Vector2i.DOWN
		for p in w.rocks:
			if w.rocks.has(p+d) or (w.rocks.has(p-along) and not w.rocks.has(p-along+d)):continue
			var n=0;var q=p
			while w.rocks.has(q) and not w.rocks.has(q+d):n+=1;q+=along
			longest=maxi(longest,n)
			if n>=10:long_edges+=n
	return {"longest":longest,"long_edge_cells":long_edges}
func slots(w):
	var count=0
	for p in w.rocks:
		for d in [Vector2i.RIGHT,Vector2i.DOWN]:
			var q=p+d
			if not w.rocks.has(q) and w.rocks.has(q+d):
				count+=1
	return count
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var groups=Groups.new();var visual=Visual.new()
	for seed in [31,97,2026]:
		var pair=[]
		for version in [6,7]:
			var campaign=Farm.new_campaign();campaign.biome_map=Farm.Biome.generate(seed,100,68,version)
			var start=Time.get_ticks_msec();var w=Farm.new(campaign,seed).begin_day();var elapsed=Time.get_ticks_msec()-start
			var sizes=groups.components(w.rocks);var free=0
			for y in range(w.H):
				for x in range(w.W):
					if w.walkable(Vector2i(x,y)):free+=1
			var row=straight(w);row.seed=seed;row.version=version;row.rocks=w.rocks.size();row.largest=sizes[0];row.region=float(w.terrain.regions.count("rocky"))/(w.W*w.H);row.slots=slots(w);row.world_ms=elapsed;pair.append(row);samples.append(row)
			if version==7:
				check(sizes[0]>=w.rocks.size()*0.9,"Mainland continuity "+str(seed))
				check(w.Biome.reachable(w).size()==free,"All open land reachable "+str(seed))
				check(row.region>=0.25 and row.region<=0.3334,"Biome area retained "+str(seed))
				check(row.slots<=pair[0].slots,"No extra one-cell passages between rock faces "+str(seed))
				check(not w.rocks.has(w.keeper.pos) and not w.rocks.has(w.Story.at(w)),"Initial centre clear "+str(seed))
			Rock.prepare_ground(w);visual.draw(w,Rect2i(0,0,w.W,w.H),out+"/rim-%d-v%d.png"%[seed,version])
		check(pair[1].longest<pair[0].longest,"Longest straight edge shortened "+str(seed))
		check(pair[1].long_edge_cells<pair[0].long_edge_cells,"Long-edge exposure reduced "+str(seed))
		check(absf(float(pair[1].rocks-pair[0].rocks))/pair[0].rocks<0.10,"Mineable area within ten percent "+str(seed))
	groups.free();visual.free()
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/rim.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"failures":failures,"images":"CPU production RockView; simplified ground; not game screenshots"},"\t"))
	print("RIM: ",checks.size()," checks, failures=",failures);quit(1 if failures else 0)
