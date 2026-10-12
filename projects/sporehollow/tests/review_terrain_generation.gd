extends SceneTree
## Actual renderer and ordinary jobs; no inserted rocks, trees, drops, or completion calls.
const Farm=preload("res://game/world.gd")
const SEEDS=[31,97,2026]
var game
var out=""
var screens=[]
var results=[]
var failures=[]
var timings={"generation_ms":[],"world_step_ms":[],"scene_process_ms":[],"viewport_cpu_ms":[],"viewport_gpu_ms":[]}
var clip_frames={}
var slow_steps=[]
func _initialize():call_deferred("run")
func mark(stage):
	FileAccess.open(out+"/terrain-stages.json",FileAccess.WRITE).store_string(JSON.stringify({"stage":stage,"milliseconds":Time.get_ticks_msec()}))
func check(value,message):
	if not value:failures.append(message);push_error(message)
	return value
func stats(values):
	if values.is_empty():return {"samples":0}
	var sorted=values.duplicate();sorted.sort();var total=0.0
	for value in sorted:total+=value
	return {"samples":sorted.size(),"mean":total/sorted.size(),"p50":sorted[int((sorted.size()-1)*0.50)],"p95":sorted[int((sorted.size()-1)*0.95)],"max":sorted.back()}
func fresh(seed_number):
	var start=Time.get_ticks_usec();var w=Farm.new({},seed_number).begin_day()
	timings.generation_ms.append((Time.get_ticks_usec()-start)/1000.0)
	w.story.intro_seen=true
	return w
func bind_world(w):
	game.world=w;game.reset_view();game.neutral();game.harvest_view.setup(w);game.refresh()
func camera_at(p,zoom=1.5):
	game.camera.zoom=Vector2.ONE*zoom;game.camera.position=game.center(p)+Vector2(80,-20)/zoom;game.clamp_camera()
func advance():
	var start=Time.get_ticks_usec();game.world.step();var elapsed=(Time.get_ticks_usec()-start)/1000.0;timings.world_step_ms.append(elapsed)
	if elapsed>16.67:slow_steps.append({"seed":game.world.seed_value,"tick":game.world.tick,"ms":elapsed,"jobs":game.world.jobs.map(func(j):return {"kind":j.kind,"state":j.state,"position":[j.pos.x,j.pos.y]})})
	start=Time.get_ticks_usec();game._process(Farm.DT);timings.scene_process_ms.append((Time.get_ticks_usec()-start)/1000.0)
	game.audio.seconds+=Farm.DT;game.accumulated=0
func render():
	game.queue_redraw();game.hud.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	if RenderingServer.has_method("viewport_get_measured_render_time_cpu"):
		timings.viewport_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		timings.viewport_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
func image(name,p=Vector2i(-1,-1),note="",overview=false):
	await render()
	check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Could not save "+name)
	var w=game.world
	screens.append({"file":name+".png","seed":w.seed_value,"tick":w.tick,"focus":[p.x,p.y],"zoom":game.camera.zoom.x,"overview_hud_hidden":overview,"note":note,"rocks":w.rocks.size(),"trees":w.trees.size(),"mined_cells":w.mined_rock_cells.size()})
func clip(name):
	var index=clip_frames.get(name,0);clip_frames[name]=index+1
	await render();check(root.get_texture().get_image().save_png(out+"/frame_%s_%03d.png"%[name,index])==OK,"Could not save clip")
func reachable(w,p):
	for q in w.neighbors(p):
		if w.walkable(q) and (q==w.keeper.pos or not w.find_path(w.keeper.pos,q).is_empty()):return true
	return false
func find_patch(w):
	var options=[]
	for y in range(w.H-2):
		for x in range(w.W-2):
			var base=Vector2i(x,y);var full=true
			for dy in range(3):
				for dx in range(3):
					if not w.rocks.has(base+Vector2i(dx,dy)):full=false
			if not full:continue
			for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(2,1),Vector2i(1,2)]:
				if reachable(w,base+offset):options.append({"base":base,"edge":base+offset});break
	options.sort_custom(func(a,b):return w.distance(w.keeper.pos,a.edge)<w.distance(w.keeper.pos,b.edge))
	return {} if options.is_empty() else options[0]
func region_focus(w,kind_name):
	var candidates=[]
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			if w.Biome.kind(w,p)==kind_name:candidates.append(p)
	if candidates.is_empty():return Vector2i(-1,-1)
	var average=Vector2.ZERO
	for p in candidates:average+=Vector2(p)
	average/=candidates.size();candidates.sort_custom(func(a,b):return Vector2(a).distance_squared_to(average)<Vector2(b).distance_squared_to(average))
	return candidates[0]
func boundary_focus(w):
	var candidates=[]
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var p=Vector2i(x,y)
			if w.Biome.kind(w,p)!="rocky":continue
			if w.neighbors(p).any(func(q):return w.Biome.kind(w,q)!="rocky"):candidates.append(p)
	candidates.sort_custom(func(a,b):return w.distance(a,w.keeper.pos)<w.distance(b,w.keeper.pos))
	return Vector2i(-1,-1) if candidates.is_empty() else candidates[0]
func views(w):
	var prefix="seed_%d_"%w.seed_value
	var layer=game.hud.get_parent();layer.hide();game.camera.zoom=Vector2.ONE*0.48;game.camera.position=Vector2(w.W*48,w.H*42)*0.5;game.camera.force_update_scroll()
	await image(prefix+"full_map",Vector2i(25,17),"Actual game draw, diagnostic overview zoom; HUD temporarily hidden",true);layer.show()
	var points={"idol_center":w.Story.at(w),"grass_rock_boundary":boundary_focus(w),"rocky_interior":region_focus(w,"rocky"),"woodland":region_focus(w,"woodland"),"dry":region_focus(w,"dry"),"lush":region_focus(w,"lush"),"corner_nw":Vector2i(0,0),"corner_ne":Vector2i(49,0),"corner_sw":Vector2i(0,33),"corner_se":Vector2i(49,33),"edge_n":Vector2i(25,0),"edge_s":Vector2i(25,33),"edge_w":Vector2i(0,17),"edge_e":Vector2i(49,17)}
	var isolated=w.rocks.keys().filter(func(p):return game.RockView.mask(w,p)==0)
	if not isolated.is_empty():points.isolated_rock=isolated[0]
	for key in points:
		var p=points[key]
		if not check(p.x>=0,"Missing region "+key+" seed "+str(w.seed_value)):continue
		camera_at(p);await image(prefix+key,p,"Actual game renderer at ordinary play zoom")
	camera_at(w.Story.at(w))
	for i in range(60):
		var start=Time.get_ticks_usec();game._process(1.0/30.0);timings.scene_process_ms.append((Time.get_ticks_usec()-start)/1000.0)
		await render()
func do_harvest(w,kind,p,name,record_clip=false):
	mark(name)
	var before_count=w.rocks.size() if kind=="mine" else w.trees.size()
	var before_total=w.Stock.totals(w).get("stone" if kind=="mine" else "wood",0)
	var expected=w.rocks[p].amount if kind=="mine" else w.Story.CLEAR_WOOD
	if not check(w.Tasks.designate(w,kind,p),"Could not designate "+name):return {}
	var job_id=w.jobs.back().id;var damaged=false;var start_tick=w.tick;var counter=0
	while w.Harvest.exists(w,kind,p) and counter<450:
		advance();counter+=1
		var progress=w.Harvest.progress(w,kind,p)
		if progress>=0.5 and not damaged:
			if record_clip:await image(name+"_damage",p,"Normal work progress, no manually assigned damage")
			damaged=true
		if record_clip and ((progress>0 and counter%2==0) or counter%8==0):await clip(name)
	if not check(not w.Harvest.exists(w,kind,p),"Timed out "+name+" jobs="+str(w.jobs)):return {}
	if record_clip:
		await clip(name)
		for i in range(4):advance();await clip(name)
		await image(name+"_after",p,"Normal work completion and real physical drop")
	var drops=w.field_items.filter(func(row):return row.get("harvest_job_id",-1)==job_id)
	var dropped=0
	for row in drops:dropped+=row.get("amount",0)
	var result={"name":name,"target":[p.x,p.y],"kind":kind,"ticks":w.tick-start_tick,"before_count":before_count,"after_count":w.rocks.size() if kind=="mine" else w.trees.size(),"expected_drop":expected,"physical_drop":dropped,"stock_delta":w.Stock.totals(w).get("stone" if kind=="mine" else "wood",0)-before_total,"walkable":w.walkable(p),"floor_build_reason":w.Buildings.reason(w,"wood_tile",p,false),"damaged_observed":damaged}
	check(dropped==expected,"Physical amount mismatch "+name);check(w.walkable(p),"Harvest did not open target "+name)
	return result
func aside(w,p):
	var options=w.neighbors(p).filter(func(q):return w.walkable(q) and q!=w.keeper.pos and not w.actor_occupied(q,w.keeper.pos))
	for q in options:
		if w.find_path(w.keeper.pos,q).is_empty():continue
		if not w.act("move",q):continue
		for i in range(100):
			advance()
			if w.keeper.pos==q:advance();return
func collect_and_build(w,p,prefix):
	camera_at(p,1.8)
	var blocked_reason=w.Buildings.reason(w,"wood_tile",p,false)
	check(blocked_reason=="物があるため建設できません","Mined drop should block construction until collected")
	var forbid=w.Stock.designate(w,"forbid",p,p)
	check(forbid.accepted>0,"Forbid mined stone")
	check(w.items_at(p).all(func(row):return row.get("forbidden",false)),"Stone forbidden flags")
	await image(prefix+"stone_forbidden",p,"Mined stone remains a real object; construction blocked until collected")
	var allow=w.Stock.designate(w,"allow",p,p)
	check(allow.accepted>0,"Allow mined stone")
	var haul=w.Stock.designate(w,"haul",p,p)
	check(haul.accepted>0,"Designate mined stone for normal haul")
	var before_available=w.Stock.available(w,"stone")
	for i in range(350):
		advance()
		if w.items_at(p).is_empty() and not w.jobs.any(func(j):return j.kind=="haul"):break
	check(w.items_at(p).is_empty(),"Mined cell emptied through hauling")
	check(w.Stock.available(w,"stone")>=before_available+8,"Eight mined stones stored in existing stockpile")
	await aside(w,p);camera_at(p,1.8)
	await image(prefix+"after_collection",p,"Normal hauling cleared the cell and delivered stone to original storage")
	var reason=w.Buildings.reason(w,"wood_tile",p,false)
	var requested=false
	if check(reason=="","Harvested, collected tile is buildable: "+reason):requested=w.act("wood_tile",p)
	check(requested,"Normal wood floor request after collection")
	for i in range(350):
		advance()
		if w.floors.get(p,{}).get("status","")=="ready":break
	var complete=w.floors.get(p,{}).get("status","")=="ready"
	check(complete,"Normal floor construction completed on former rock")
	await image(prefix+"built_on_mined_cell",p,"Existing construction delivery/work completed a wood floor on the mined cell")
	return {"before_collection_build_reason":blocked_reason,"after_collection_build_reason":reason,"normal_floor_requested":requested,"normal_floor_ready":complete,"storage_cells":w.storage_cells.map(func(q):return [q.x,q.y])}
func harvest_review(w):
	var seed_number=w.seed_value;var prefix="seed_%d_"%seed_number;var patch=find_patch(w)
	if not check(not patch.is_empty(),"No accessible natural filled 3x3 for seed "+str(seed_number)):return
	var base=patch.base;var center=base+Vector2i.ONE;camera_at(center,1.8)
	await image(prefix+"connected_before",center,"Naturally generated 3x3 patch; no obstacle fixture added")
	var initial_rocks=w.rocks.duplicate(true);var events=[]
	events.append(await do_harvest(w,"mine",patch.edge,prefix+"mine_edge",true))
	await image(prefix+"center_entrance",center,"A genuine edge mined first to reach the previously inaccessible centre")
	events.append(await do_harvest(w,"mine",center,prefix+"mine_center",true))
	var corners=[base,base+Vector2i(2,0),base+Vector2i(0,2),base+Vector2i(2,2)]
	corners.sort_custom(func(a,b):return w.distance(a,patch.edge)<w.distance(b,patch.edge))
	for p in corners:
		if reachable(w,p):events.append(await do_harvest(w,"mine",p,prefix+"mine_corner",true));break
	var remaining=[]
	for y in range(3):
		for x in range(3):
			var p=base+Vector2i(x,y)
			if w.rocks.has(p):remaining.append(p)
	while not remaining.is_empty():
		remaining.sort_custom(func(a,b):return w.distance(a,w.keeper.pos)<w.distance(b,w.keeper.pos))
		var next=null
		for p in remaining:
			if reachable(w,p):next=p;break
		if not check(next!=null,"No access to remaining patch"):break
		var event=await do_harvest(w,"mine",next,prefix+"patch_%d_%d"%[next.x,next.y])
		events.append(event)
		if event.is_empty():break
		remaining.erase(next)
	await aside(w,base+Vector2i(1,3));camera_at(center,1.8)
	await image(prefix+"patch_all_mined",center,"All 9 cells in marked 3x3 review patch mined; outside natural rocks retained")
	var outside_unchanged=true
	for p in initial_rocks:
		if p.x>=base.x and p.x<base.x+3 and p.y>=base.y and p.y<base.y+3:continue
		if not w.rocks.has(p) or w.rocks[p]!=initial_rocks[p]:outside_unchanged=false
	check(outside_unchanged,"Rock outside target patch changed")
	var trees=w.trees.keys().filter(func(p):return reachable(w,p));trees.sort_custom(func(a,b):return w.distance(w.keeper.pos,a)<w.distance(w.keeper.pos,b))
	if check(not trees.is_empty(),"No accessible natural tree"):
		var tree=trees[0];camera_at(tree,1.8);await image(prefix+"logging_before",tree,"Original generated tree")
		events.append(await do_harvest(w,"clear_tree",tree,prefix+"logging",true));await aside(w,tree);await image(prefix+"logging_drops_clear",tree,"Normal logging drop and opened footprint")
	var building={}
	if seed_number==31:building=await collect_and_build(w,center,prefix)
	var path=out+"/seed_%d.snapshot"%seed_number;check(w.Snapshot.save(w,path),"Snapshot save failed")
	var restored=w.Snapshot.restore(path)
	var equal=restored!=null and restored.rocks==w.rocks and restored.trees==w.trees and restored.mined_rock_cells==w.mined_rock_cells and restored.field_items==w.field_items and restored.terrain==w.terrain and restored.floors==w.floors and restored.structures==w.structures
	check(equal,"Harvest snapshot restore mismatch")
	results.append({"seed":seed_number,"patch_base":[base.x,base.y],"removed_patch_cells":9-remaining.size(),"outside_rocks_unchanged":outside_unchanged,"snapshot_identical":equal,"events":events,"collection_build":building})
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	mark("start");root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game);await process_frame;game.set_process(false);game.audio.set_process(false)
	if RenderingServer.has_method("viewport_set_measure_render_time"):RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for seed_number in SEEDS:
		mark("seed "+str(seed_number));var w=fresh(seed_number);bind_world(w);await views(w);await harvest_review(w)
	var summary={}
	for key in timings:summary[key]=stats(timings[key])
	FileAccess.open(out+"/terrain-observations.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"Three real new maps; no inserted obstacles, no erased blockers, no target completion calls. Actual main renderer and normal Tasks/World.step. Full-map only uses diagnostic zoom. Sequential 3x3 patch mining preserves all outside rocks.","screens":screens,"cases":results,"clip_frames":clip_frames,"failures":failures,"performance":summary,"simulation_steps_over_16_67_ms":slow_steps,"performance_limits":"30 fps cap is an isolation requirement, not a performance result. Timers measure new World+begin_day, fixed-step simulation, main scene CPU processing, and viewport CPU/GPU render passes. PNG encoding/waits excluded from CPU timers. No claim of whole-window uncapped FPS or peak combat load."},"  "))
	mark("complete");game.queue_free();await process_frame;quit(0 if failures.is_empty() else 4)


