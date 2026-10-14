extends SceneTree
const Farm=preload("res://game/world.gd")
const View=preload("res://game/construction_view.gd")
var checks=[]
class Recorder extends RefCounted:
	var textures=[]
	var lines=0
	var rects=[]
	func draw_rect(area,color,filled=true,width=-1):rects.append([area,color,filled,width])
	func draw_line(_a,_b,_color,_width):lines+=1
	func draw_texture_rect(texture,area,_tile):textures.append([texture,area])
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w)
	w.keeper.pos=Vector2i(30,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.animals.clear();w.refresh_indoor()
	w.keeper.work_priorities={"build":1,"gather":2,"collect":3,"animal":4,"other":4,"haul":4}
	w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(28,24));return w
func plan(w,kind="wood_wall",p=Vector2i(35,26)):
	check(w.act(kind,p),"Plan accepted: "+kind);return w.jobs[-1]
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=fixture();var j=plan(w);j.construction_ready=false
	var view=View.new();view.update(w)
	check(view.rows[j.id].stage=="empty" and view.rows[j.id].missing==5,"No delivery: ghost, requirement5 and missing5")
	var empty=Recorder.new();View.draw(empty,Vector2.ZERO,view.rows[j.id]);check(empty.textures.is_empty(),"Undelivered ghost contains no material pile")
	w.Stock.add(w,"wood",3,j.pos,"site",j.id);view.update(w)
	check(view.rows[j.id].stage=="partial" and view.rows[j.id].delivered==3 and view.rows[j.id].missing==2,"Partial delivery: actual3 / required5 / missing2")
	var calls_before=view.rebuilds
	for i in range(60):view.update(w)
	check(view.rebuilds==calls_before,"Unchanged partial quantities reuse presentation cache")
	var partial=Recorder.new();View.draw(partial,Vector2.ZERO,view.rows[j.id])
	check(partial.textures.size()==1 and partial.textures[0][0]==View.Art.RESOURCES.wood[24],"Partial pile uses adopted wood icon")
	j.block_reason="材料を搬入する通路がありません";w.tick+=1;view.update(w)
	check("通路" in "".join(view.rows[j.id].lines),"Blocked site displays its actual reason")
	w.paused=true;view.update(w);check("時間停止中" in "".join(view.rows[j.id].lines),"Paused site states why work does not advance")
	w.paused=false;j.block_reason=""
	var extra=w.Stock.add(w,"wood",2,j.pos,"site",j.id);view.update(w)
	var complete=Recorder.new();View.draw(complete,Vector2.ZERO,view.rows[j.id])
	check(view.rows[j.id].stage=="ready" and complete.textures.size()==2 and "施工グループ" in "".join(view.rows[j.id].lines),"Delivered is checked waiting site, with group wait explanation; not completed wall")
	extra.forbidden=true;w.Stock.sync(w);view.update(w)
	check(view.rows[j.id].delivered==5 and view.rows[j.id].usable==3 and view.rows[j.id].missing==2,"Forbidden delivered stock stays physically visible but not usable")
	extra.forbidden=false;w.Stock.sync(w);j.construction_ready=true;w.Buildings.begin(w,j);j.remaining=4;view.update(w)
	check(view.rows[j.id].stage=="working" and view.rows[j.id].progress==0.5,"Construction begins and progress uses actual remaining ticks")
	var working=Recorder.new();View.draw(working,Vector2.ZERO,view.rows[j.id]);check(working.lines>=3 and working.rects.size()==2,"Construction scaffold and progress bar separate from ready marker")
	j.remaining=1;w.Buildings.advance(w,j);view.update(w)
	check(not view.rows.has(j.id) and w.structures[j.pos].status=="ready" and w.stock_used.wood==5,"Completion removes plan, consumes exactly5, retains finished building")
	w=fixture();j=plan(w);w.Stock.add(w,"wood",5,j.pos,"site",j.id);w.keeper.work_priorities.build=0;view=View.new();view.update(w)
	check("建築の担当設定" in "".join(view.rows[j.id].lines),"No build-role assignment is explained without changing the scheduler")
	# Each wall type charges five while retaining HP and duration; other costs unchanged.
	for kind in ["wall","wood_wall","stone_wall"]:
		w=fixture();j=plan(w,kind);w.Stock.add(w,j.resource,5,j.pos,"site",j.id);w.Buildings.begin(w,j)
		var expected={"wall":[8,4],"wood_wall":[16,8],"stone_wall":[28,12]}[kind]
		check(j.required==5 and w.structures[j.pos].max_hp==expected[0] and j.remaining==expected[1],"Cost5 with unchanged HP/time: "+kind)
		j.remaining=1;w.Buildings.advance(w,j)
		check(w.stock_used[j.resource]==5 and w.structures[j.pos].cost==5,"Actual consumption and completed cost5: "+kind)
	check(Farm.BUILD.door.cost==10 and Farm.BUILD.locked_door.cost==20 and Farm.BUILD.wood_tile.cost==2 and Farm.BUILD.soil_tile.cost==2 and Farm.BUILD.stone_tile.cost==2,"Doors and floors unchanged")
	for started in [false,true]:
		w=fixture();j=plan(w);w.Stock.add(w,"wood",5,j.pos,"site",j.id)
		if started:w.Buildings.begin(w,j)
		w.Jobs.cancel(w,j.id)
		check(w.Stock.totals(w).get("wood",0)==(2 if started else 5) and w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==5,"Cancel retains existing full/prestart or half/started refund: "+str(started))
	# Legacy reserved, partial, excess and carried states are conserved and idempotent.
	for quantity in [0,3,10]:
		w=fixture();j=plan(w);j.required=10
		if quantity>0:w.Stock.add(w,"wood",quantity,j.pos,"site",j.id)
		w.Delivery.migrate_wall_costs(w);w.Delivery.migrate_wall_costs(w)
		check(j.required==5 and w.Stock.delivered(w,j)==mini(quantity,5) and w.Stock.totals(w).get("wood",0)==quantity,"Legacy quantity safely migrates without loss: "+str(quantity))
	w=fixture();j=plan(w);j.required=10;var source=w.Stock.add(w,"wood",10,Vector2i(25,23));var task=w.Delivery.start(w,"keeper",{"seed_job":j.id})
	var entry=task.allocations[0];var carried=w.Stock.pickup(w,source,entry.token,w.keeper,j.id);carried.construction_transfer=true;entry.claims.clear()
	w.Delivery.migrate_wall_costs(w)
	check(j.required==5 and w.build_deliveries.is_empty() and w.Stock.totals(w).wood==10 and carried.location=="ground" and carried.job_id==-1,"Legacy carried materials release physically; no obsolete allocation or duplicated goods")
	w=fixture();j=plan(w);j.required=10;w.Stock.add(w,"wood",10,j.pos,"site",j.id);w.Buildings.begin(w,j);j.remaining=4
	var snapshot=out+"/site-fixture.snapshot";check(w.Snapshot.save(w,snapshot),"Legacy fixture saved only in scratch")
	var restored=w.Snapshot.restore(snapshot)
	check(restored.jobs[0].required==5 and restored.jobs[0].remaining==4 and restored.Stock.totals(restored).wood==10 and restored.structures[j.pos].cost==5,"Restore migrates legacy started cost without resetting progress or losing excess")
	DirAccess.remove_absolute(snapshot)
	j=restored.jobs[0];j.remaining=1;restored.Buildings.advance(restored,j)
	check(restored.stock_used.get("wood",0)==5 and restored.Stock.totals(restored).wood==5,"Legacy completion consumes5 and leaves excess5 at site")
	# 100 markers cached: no repeated field-item/job aggregation within a render interval.
	w=fixture();w.debug_enabled=true;w.debug_infinite=true
	var stroke=preload("res://game/wall_stroke.gd").new();stroke.kind="soil_tile"
	for i in range(101):stroke.cells.append(Vector2i(10+i%20,10+i/20))
	check(stroke.commit(w).accepted==100,"100 reservations accepted; 101 refused")
	view=View.new();view.update(w)
	for i in range(120):view.update(w)
	check(view.rows.size()==100 and view.rebuilds==1,"100 plans,120 repeated frame reads: exactly one aggregation")
	check(Farm.Work.Policy.CARRY_CAPACITY==20 and Farm.Work.Policy.STORAGE_CAPACITY==40,"Carry20 / storage40 unchanged")
	# Production click path and existing UI bounds in a headless scene, without native GPU.
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+20000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished and boot.failure=="","Production scene loads headlessly")
	if boot.finished:
		var g=boot.game;g.set_process(false);g.world=fixture();w=g.world;w.story.intro_seen=true;g.selected.clear();g.group=-1;g.tool=""
		j=plan(w);var other=plan(w,"stone_wall",Vector2i(36,26));w.Stock.add(w,"wood",3,j.pos,"site",j.id)
		for target in [j,other]:
			var event=InputEventMouseButton.new();event.position=g.get_canvas_transform()*g.center(target.pos);event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
			g.board_click(event)
			var card=g.selected_construction()
			check(g.selected.get("id")==target.id and card.name==w.Buildings.NAMES[target.kind] and card.delivered==(3 if target.id==j.id else 0),"Actual click selects the correct independent site and counts: "+target.kind)
			g.pointer=View.panel_rect(card.lines).position+Vector2(5,5)
			check(g.pointer_over_ui(),"Expanded existing card consumes pointer input")
		check(g.TOOLS.wall.ends_with("5") and g.TOOLS.wood_wall.ends_with("5") and g.TOOLS.stone_wall.ends_with("5"),"Architect labels also show five")
		g.selected={"kind":"job","id":j.id,"pos":j.pos};g.cancel_work(j.id)
		check(not w.jobs.has(j) and w.jobs.has(other),"Existing cancel button cancels only selected site")
	boot.queue_free();await process_frame
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/construction-sites.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"method":"headless logic, recording canvas and production click path; no visual/GPU approval"},"	"))
	print("ConstructionSites: ",checks.size()," checks; ",failed," failures");quit(1 if failed else 0)
