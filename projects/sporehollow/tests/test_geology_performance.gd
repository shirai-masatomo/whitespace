extends SceneTree
const Farm=preload("res://game/world.gd")
const Old=preload("res://tests/legacy_path_reference.gd")
const Rock=preload("res://game/rock_view.gd")
var checks=[]
var samples=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	for seed in [31,97,2026]:
		var w=Farm.new({},seed).begin_day();var goals=[]
		for p in w.rocks:
			if goals.size()>=20:break
			var near=w.neighbors(p).filter(func(q):return w.walkable(q))
			if not near.is_empty():goals.append(near[0])
		var old_paths=[];var start=Time.get_ticks_usec()
		for p in goals:old_paths.append(Old.find_path(w,w.keeper.pos,p))
		var before=(Time.get_ticks_usec()-start)/1000.0;start=Time.get_ticks_usec()
		for i in range(goals.size()):check(w.find_path(w.keeper.pos,goals[i])==old_paths[i],"Exact old path and tie order preserved: %d/%d"%[seed,i])
		var after=(Time.get_ticks_usec()-start)/1000.0
		for flags in [[true,false,false],[false,true,false],[false,false,true],[true,true,true]]:
			var target=goals.back();var costs={target+Vector2i.LEFT:9.0,target+Vector2i.UP:3.0}
			check(w.find_path(w.keeper.pos,target,flags[0],flags[1],flags[2],costs)==Old.find_path(w,w.keeper.pos,target,flags[0],flags[1],flags[2],costs),"Role/occupancy/outdoor/route-cost rules unchanged: %d/%s"%[seed,flags])
		var built=w.rock_connection_builds
		for repeat in range(5):
			for p in w.rocks:Rock.mask(w,p);Rock.inner(w,p)
		check(w.rock_connection_builds==built,"Repeated drawing reads cached connections only: %d"%seed)
		var cell=w.rocks.keys()[0];w.rocks.erase(cell);Rock.changed(w,cell)
		check(w.rock_connection_builds-built<=8 and w.rock_connection_count==w.rocks.size(),"Mining updates no more than eight surviving neighbours: %d"%seed)
		check(w.rocks.keys().all(func(p):return Rock.mask(w,p)==Rock.raw_mask(w,p) and Rock.inner(w,p)==Rock.raw_inner(w,p)),"Local cache matches uncached truth after removal: %d"%seed)
		samples.append({"seed":seed,"queries":20,"old_frontier_scan_ms":before,"stable_heap_ms":after,"connection_reads_without_rebuild":w.rocks.size()*5})
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/geology-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"failures":failed},"\t"))
	print("GEOLOGY_PERFORMANCE: ",checks.size()," checks failures=",failed);quit(1 if failed else 0)
