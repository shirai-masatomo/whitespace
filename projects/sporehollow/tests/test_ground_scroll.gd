extends SceneTree
const Farm=preload("res://game/world.gd")
const Board=preload("res://game/board_art.gd")
var checks=[]
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="":quit(2);return
	for seed_number in [31,73,109]:
		var w=Farm.new({},seed_number).begin_day()
		check(w.W==100 and w.H==68 and w.terrain.version==5,"New terrain dimensions/version")
		check(w.terrain.fields.all(func(f):return f[6]<0.001 if f[2]<=0.12 else true),"Clay does not form independent water-like regions away from rock")
		check(w.terrain.ground_weights.size()==101*69,"Shared vertices span all new map edges")
		var stored=[w.terrain.duplicate(true),w.rocks.duplicate(true),w.mountains.duplicate(true)]
		Board.cache_ground(w,Vector2(48,42))
		for y in range(9):
			for x in range(13):Board.prepare_region(w,Vector2(48,42),Rect2i(x*8,y*8,mini(8,100-x*8),mini(8,68-y*8)))
		var meshes=Board.region_meshes.duplicate()
		check(meshes.size()==117,"One prepared base mesh per chunk, no stacked full-map surface meshes")
		for box in meshes:Board.prepare_region(w,Vector2(48,42),box)
		check(meshes==Board.region_meshes,"Revisiting all chunks reuses the same mesh resources")
		check(stored==[w.terrain,w.rocks,w.mountains],"Drawing preparation cannot mutate terrain, resources or collision")
		var totals=w.nature_site_cache.totals.duplicate();var before=w.natural.size()
		for resource in ["weed","mushroom","stump"]:
			var valid=true
			for attempt in range(80):
				var p=w.Biome.sample_nature(w,resource)
				valid=valid and p!=null and w.Biome.nature_site_valid(w,p)
			check(valid,"Cached weighted samples respect current occupancy: "+resource)
		check(w.natural.size()==before and totals==w.nature_site_cache.totals,"Candidate sampling does not spawn or consume capacity")
		# Fill every otherwise-valid interior cell after caching. No floor spawn,
		# then unblock exactly one cell: the bounded fallback must still find it.
		var free=w.Biome.sample_nature(w,"weed")
		for p in w.nature_site_cache.sites:w.floors[p]={"status":"ready"}
		check(w.Biome.sample_nature(w,"weed")==null,"Fully tiled map has no forced nature spawn")
		w.floors.erase(free)
		check(w.Biome.sample_nature(w,"weed")==free,"Live floor removal is respected without rebuilding weights")
	FileAccess.open(out+"/ground-scroll-tests.json",FileAccess.WRITE).store_string(JSON.stringify(checks,"  "))
	quit(0 if checks.all(func(c):return c.passed) else 1)
