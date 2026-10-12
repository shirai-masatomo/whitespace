extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failures=0
var observations=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func solid_core(w) -> Vector2i:
	for p in w.rocks:
		var solid=true
		for dy in range(3):
			for dx in range(3):
				if not w.rocks.has(p+Vector2i(dx,dy)):solid=false
		if solid:return p
	return Vector2i(-1,-1)
func component_sizes(w,label: String) -> Array:
	var visited={};var sizes=[]
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			if visited.has(p) or w.Biome.kind(w,p)!=label:continue
			var queue=[p];visited[p]=true;var index=0
			while index<queue.size():
				var q=queue[index];index+=1
				for n in w.neighbors(q):
					if w.inside(n) and not visited.has(n) and w.Biome.kind(w,n)==label:visited[n]=true;queue.append(n)
			sizes.append(queue.size())
	return sizes
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var previous={}
	for seed_number in [1,17,31,97,2026]:
		var start=Time.get_ticks_usec();var w=Farm.new({},seed_number).begin_day()
		var creation_ms=(Time.get_ticks_usec()-start)/1000.0
		var twin=Farm.new({},seed_number).begin_day()
		check(w.terrain.version==2 and w.terrain.generation_version==2,"Only new campaigns use generator v2: "+str(seed_number))
		check(w.terrain==twin.terrain and w.rocks==twin.rocks and w.trees==twin.trees and w.natural==twin.natural,"Same seed reproduces all layers and objects: "+str(seed_number))
		if not previous.is_empty():check(previous.fields!=w.terrain.fields,"Different seeds alter region fields: "+str(seed_number))
		previous=w.terrain.duplicate(true)
		check(w.terrain.regions.size()==1700 and w.terrain.materials.size()==1700 and w.terrain.vertices.size()==1785,"Separate saved region/material/vertex grids: "+str(seed_number))
		check(w.terrain.materials.all(func(m):return m in ["grass","soil","gravel","bedrock"]),"Only nonblocking ground material labels: "+str(seed_number))
		var reached=w.Biome.reachable(w);var free_count=0;var clear_count=0;var rocky_free=0;var materials={};var regions={}
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var region=w.Biome.kind(w,p);regions[region]=regions.get(region,0)+1
				var ground=w.Biome.material(w,p);materials[ground]=materials.get(ground,0)+1
				if w.walkable(p):
					free_count+=1
					if region=="rocky":rocky_free+=1
					if w.Biome.clearing(Vector2(p),seed_number)<0.8:clear_count+=1
		check(regions.size()==5 and materials.size()>=3,"Five cohesive regions with mixed ground materials: "+str(seed_number))
		check(solid_core(w)!=Vector2i(-1,-1),"At least one generated solid 3x3 rock shelf: "+str(seed_number))
		check(rocky_free>10 and w.rocks.size()<regions.rocky,"Rock biome also has walkable gravel/bedrock: "+str(seed_number))
		check(reached.size()==free_count,"Every initially open cell connects to the keeper: "+str(seed_number))
		check(w.Land.border_cells().all(func(p):return reached.has(p)),"All edges and corners remain open and reachable: "+str(seed_number))
		check(clear_count>140 and w.rocks.keys().all(func(p):return not w.Biome.protected(w,p)) and w.trees.keys().all(func(p):return not w.Biome.protected(w,p)),"Central building room, actors, merchant and ingress protected: "+str(seed_number))
		check(w.entries.all(func(p):return reached.has(p)) and reached.has(w.logistics_entry),"Merchant and enemy approaches stay reachable: "+str(seed_number))
		check(w.trees.keys().all(func(p):return w.neighbors(p).all(func(q):return not w.trees.has(q))),"Sparse woodland never makes adjacent trunk walls: "+str(seed_number))
		check(w.rocks.values().all(func(r):return r.amount==w.Tasks.STONE_PER_ROCK),"Unchanged per-cell stone yield: "+str(seed_number))
		for resource in ["weed","mushroom","stump"]:
			check(w.natural.values().count(resource)<=w.nature_config.caps[resource],"Existing harvest cap retained: "+resource+" seed "+str(seed_number))
		var fragmentation={}
		for label in ["rocky","woodland","dry","lush"]:
			var sizes=component_sizes(w,label);fragmentation[label]=sizes
			var fragments=0
			for size in sizes:
				if size<9:fragments+=size
			check(fragments<=regions[label]*0.05 and sizes.max()>=25,"Regional area is made of broad patches, not tiny fragments: "+label+" seed "+str(seed_number))
			if label!="lush":check(sizes.max()>=regions[label]*0.50,"Dominant connected regional patch: "+label+" seed "+str(seed_number))
		observations.append({"seed":seed_number,"world_creation_ms":creation_ms,"regions":regions,"materials":materials,"region_components":fragmentation,"rocks":w.rocks.size(),"trees":w.trees.size(),"core":[solid_core(w).x,solid_core(w).y],"reachable_cells":reached.size(),"repairs":w.terrain.placement.repair_removed_cells})
	# Deliberately enclose one otherwise free cell to exercise the safety-repair
	# branch, which the naturally open review seeds need not happen to trigger.
	var fixture=Farm.new({},31).begin_day();var pocket=Vector2i(32,17)
	fixture.rocks.erase(pocket);fixture.trees.erase(pocket)
	for d in fixture.Biome.DIRECTIONS:fixture.rocks[pocket+d]={"amount":fixture.Tasks.STONE_PER_ROCK,"forbidden":false}
	check(not fixture.Biome.reachable(fixture).has(pocket),"Safety fixture starts with an enclosed free pocket")
	var idol_before=fixture.story.idol.duplicate(true);var structures_before=fixture.structures.duplicate(true)
	var removed=fixture.Biome.repair_connections(fixture)
	check(removed.size()==1 and fixture.Biome.reachable(fixture).has(pocket),"Safety repair removes one local rock barrier, without imposing a road")
	check(fixture.story.idol==idol_before and fixture.structures==structures_before,"Safety repair leaves idol and structures unchanged")
	# A real saved v1 layer gains only derived surface metadata. Never rerun
	# placement or replace its fields, vertices, remaining objects or actors.
	var w=Farm.new({},31).begin_day()
	var removed_rock=w.rocks.keys()[0];w.rocks.erase(removed_rock);w.mined_rock_cells.append(removed_rock)
	var removed_tree=w.trees.keys()[0];w.story.cleared.append(w.trees[removed_tree]);w.trees.erase(removed_tree)
	w.persist_farm();var saved=w.campaign.duplicate(true)
	saved.biome_map.version=1;saved.biome_map.erase("generation_version");saved.biome_map.erase("regions");saved.biome_map.erase("materials")
	var old=Farm.new(saved,31)
	check(old.terrain.version==1 and old.terrain.generation_version==1,"Saved v1 generation version is retained")
	check(old.terrain.fields==w.terrain.fields and old.terrain.vertices==w.terrain.vertices,"Saved v1 geometry and blended colors are not regenerated")
	check(old.rocks==w.rocks and old.trees==w.trees and old.structures==w.structures and old.keeper.pos==w.keeper.pos and old.field_items==w.field_items,"Saved world objects and actors survive visual metadata migration")
	check(not old.rocks.has(removed_rock) and not old.trees.has(removed_tree) and not old.campaign.has("biome_new_map"),"Depleted cells remain depleted on legacy load")
	old.terrain.erase("regions");old.terrain.erase("materials");old.terrain.erase("generation_version")
	check(old.Snapshot.save(old,out+"/terrain-v1.snapshot"),"Legacy-shaped full snapshot writes")
	var restored=old.Snapshot.restore(out+"/terrain-v1.snapshot")
	check(restored!=null and restored.terrain.version==1 and restored.terrain.generation_version==1 and restored.terrain.regions.size()==1700 and restored.terrain.materials.size()==1700,"Full v1 snapshot derives classification without upgrading generation")
	check(restored!=null and restored.rocks==old.rocks and restored.trees==old.trees and restored.natural==old.natural and restored.field_items==old.field_items,"Full v1 snapshot preserves removed objects and runtime items")
	var rng_state=w.nature_rng.state;var terrain=w.terrain.duplicate(true)
	for i in range(500):
		var p=Vector2i(i%w.W,(i/w.W)%w.H)
		w.Biome.kind(w,p);w.Biome.material(w,p);w.Biome.unit(w.seed_value,p.x,p.y,913)
	check(w.nature_rng.state==rng_state and w.terrain==terrain,"Render-facing classification and decoration never consume simulation RNG or regenerate layers")
	var f=FileAccess.open(out+"/terrain-generation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"timing_scope":"Full CPU world creation, not GPU frame performance"},"\t"));f.close()
	print("Terrain generation: ",checks.size()," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
