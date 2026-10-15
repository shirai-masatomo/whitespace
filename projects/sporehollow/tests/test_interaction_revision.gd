extends SceneTree
const Farm=preload("res://game/world.gd")
const Safety=preload("res://game/construction_safety.gd")
var checks=[]
var pictures=[]
var timings=[]
class MarkPainter:
	extends RefCounted
	var camera={"zoom":Vector2.ONE}
	var calls=[]
	func draw_line(a,b,color,width):calls.append({"type":"line","a":[a.x,a.y],"b":[b.x,b.y],"color":color.to_html(),"width":width})
	func draw_circle(p,r,color):calls.append({"type":"circle","p":[p.x,p.y],"radius":r,"color":color.to_html()})
func marker_proof():
	for zoom in [0.25,0.5,1.0,1.5]:
		for partial in [false,true]:
			var painter=MarkPainter.new();painter.camera.zoom=Vector2.ONE*zoom
			preload("res://game/selection_visual.gd").forbidden(painter,Vector2(60,60)/zoom,partial)
			check(painter.calls.size()==(8 if partial else 6),"Shared cross has dark/light/red layers and partial dot")
			check(is_equal_approx(painter.calls[0].width*zoom,7),"Cross remains seven pixels thick at zoom "+str(zoom))
			pictures.append({"zoom":zoom,"partial":partial,"calls":painter.calls})
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.animals.clear();w.refresh_indoor()
	w.keeper.pos=Vector2i(50,34);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason=""
	w.campaign.unlocked_blueprints.append_array(["wood_wall","stone_wall","locked_door"])
	w.Zones.create(w,"stockpile",Vector2i(40,30),Vector2i(42,30))
	for kind in ["soil","wood","stone"]:w.Stock.add(w,kind,40,Vector2i(40+["soil","wood","stone"].find(kind),30))
	return w
func ready(w,kind,p):
	var d=w.BUILD[kind];w.structures[p]={"id":w.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.resource,"open":false,"armor":0};w.next_structure_id+=1;w.invalidate_navigation()
func logic(w):
	var p=Vector2i(35,25)
	for kind in w.Buildings.BENCHES:
		check(w.Buildings.cells(kind,p).size()==4,"Four-cell footprint "+kind)
		check(w.Buildings.perimeter(kind,p).size()==8,"Eight external work goals "+kind)
		for cell in w.Buildings.cells(kind,p):
			w.trees[cell]=1;check(w.Buildings.reason(w,kind,p,false)!="","Every covered tree blocks "+kind);w.trees.erase(cell)
		check(w.act(kind,p),"Bench accepted once "+kind)
		var j=w.jobs.back()
		check(not w.act("wood_wall",p+Vector2i.ONE),"Planned footprint blocks child overlap")
		check(not w.act("soil_tile",p+Vector2i.ONE),"Planned bench also rejects overlapping floor plan")
		check(w.Stock.cancel_targets(w,p+Vector2i.ONE,p+Vector2i.ONE).has(j),"Cancel from covered child cell")
		w.Jobs.cancel(w,j.id)
		ready(w,kind,p)
		for cell in w.Buildings.cells(kind,p):check(w.Buildings.anchor(w,cell)==p and w.blocks(cell),"Completed footprint blocked and resolves anchor")
		for cell in w.Buildings.cells(kind,p):check(not w.RaidNavigation.passable(w,cell,false),"Raider collision resolves covered cell")
		check(w.act("remove",p+Vector2i.ONE),"Demolition resolves same bench")
		check(w.jobs.back().pos==p and w.jobs.back().target_id==w.structures[p].id,"Single target identity")
		w.Jobs.cancel(w,w.jobs.back().id);w.structures.erase(p);w.invalidate_navigation()
	# Last opening of a small enclosure: worker must construct from outside.
	var gate=Vector2i(20,19)
	for x in range(19,22):
		for y in range(19,22):
			var q=Vector2i(x,y)
			if q!=Vector2i(20,20) and q!=gate:ready(w,"wood_wall",q)
	var j={"kind":"wood_wall","pos":gate}
	w.keeper.pos=Vector2i(20,20)
	var safety_start=Time.get_ticks_usec()
	check(not Safety.can_finish(w,j,w.keeper),"Last wall cannot trap worker inside")
	var cold=(Time.get_ticks_usec()-safety_start)/1000.0;safety_start=Time.get_ticks_usec()
	for i in range(20):Safety.can_finish(w,j,w.keeper)
	timings.append({"case":"escape_check","cold_ms":cold,"cached_mean_ms":(Time.get_ticks_usec()-safety_start)/20000.0})
	check(Vector2i(20,20) not in Safety.work_goals(w,j,w.keeper,w.Buildings.perimeter(j.kind,j.pos)),"Inside construction goal excluded")
	w.keeper.pos=Vector2i(20,18)
	check(Safety.can_finish(w,j,w.keeper),"Outside worker can close empty room")
	var other=w.keeper.duplicate(true);other.pos=Vector2i(20,20);other.work_key="helper";w.workers.helper=other
	check(not Safety.can_finish(w,j,w.keeper),"Outside builder cannot seal a second worker inside")
	w.workers.erase("helper")
	w.MERCHANT_CELL=Vector2i(20,20);w.merchant_visit={"state":"waiting"}
	check(not Safety.can_finish(w,j,w.keeper),"Merchant inside prevents sealing")
	w.merchant_visit={"state":"gone"};ready(w,"door",Vector2i(19,20));w.keeper.pos=Vector2i(20,20)
	check(Safety.can_finish(w,j,w.keeper),"Usable door preserves escape")
func ui(w):
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Headless production UI initializes")
	if not boot.finished:boot.queue_free();return
	var g=boot.game;g.set_process(false);g.world=w;w.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false;g.neutral()
	for i in range(3):g.set_speed(i);check(g.speed==i+1 and w.paused,"Speed selectable while paused")
	g.toggle_speed();check(g.speed==1,"Speed cycles 3 to 1")
	var p=Vector2i(35,25);ready(w,"cooking_bench",p)
	g.select_building(p+Vector2i.ONE,"structure")
	check(g.group==-1 and g.selected.pos==p and g.buttons.has("craft_open"),"Equipment click opens individual context")
	g.Actions.primary(g);check(g.crafting_panel.opened and g.crafting_panel.bench==p,"E opens crafting for correct bench");g.crafting_panel.close(g)
	var item=w.Stock.add(w,"wood",8,Vector2i(45,31));g.select_resource(item.pos)
	g.Actions.forbid_resources(g,true)
	check(item.forbidden and g.Actions.resources_forbidden(g),"Resource menu forbids physical stock")
	check(g.buttons.resource_forbid.text=="許可","Forbidden selection offers Allow")
	g.Actions.forbid_resources(g,false);check(not item.forbidden,"Allow restores existing same physical item")
	w.trees[Vector2i(44,25)]=1;g.refresh()
	var rect=g.SelectionVisual.tree_rect(g,Vector2i(44,25))
	check(g.SelectionVisual.tree_at(g,rect.get_center())==Vector2i(44,25),"Crown click finds tree without image readback")
	g.neutral();g.drag_start=g.center(Vector2i(30,20))
	var rows=g.selection_candidates()
	check(rows.count({})==0 and rows.filter(func(r):return r["class"]=="building" and r.pos==p).size()==1,"Two-by-two object appears only once in range catalogue")
	await input_checks(g,w)
	boot.free();await process_frame;await process_frame;await process_frame


func logistics():
	var w=fixture();w.keeper.work_priorities={"build":1,"haul":1,"other":1,"gather":2,"collect":2,"animal":2}
	var p=Vector2i(45,33);var d=w.BUILD.carpentry_bench;var before=w.Stock.totals(w).wood
	check(w.act("carpentry_bench",p),"Physical two-by-two bench reservation")
	var j=w.jobs.back();var internal=false;var start=Time.get_ticks_usec()
	for i in range(300):
		w.tick+=1;w.Combat.recover(w.keeper,w.DT,false);w.Work.step(w)
		if j.started and w.keeper.pos in w.Buildings.cells(j.kind,p):internal=true
		if w.structures.get(p,{}).get("status")=="ready":break
	check(w.structures.get(p,{}).get("status")=="ready" and not internal,"Actual delivery and assembly finish outside two-by-two footprint")
	check(w.Stock.totals(w).wood==before-d.cost,"Bench cost unchanged and consumed once")
	timings.append({"case":"bench_delivery_and_build","ms":(Time.get_ticks_usec()-start)/1000.0,"ticks":w.tick})
	check(w.Craft.enqueue(w,p+Vector2i.ONE,"wood_crate","count",1),"Craft from covered child resolves facility")
	for i in range(240):
		w.tick+=1;w.Combat.recover(w.keeper,w.DT,false);w.Work.step(w)
		if w.Stock.totals(w).get("wood_crate",0)>0:break
	check(w.Stock.totals(w).get("wood_crate",0)==1,"Actual worker fetches ingredients and produces at expanded bench")
	check(w.Stock.totals(w).wood==before-d.cost-5,"Craft consumes exact physical ingredients")
	var item=w.field_items.filter(func(r):return r.kind=="wood_crate")
	check(not item.is_empty() and item[0].pos not in w.Buildings.cells("carpentry_bench",p),"Craft output appears outside equipment footprint")
func merchant():
	var w=fixture();w.campaign.day=2;w.calendar_ticks=2128;w.tick=0;w.MERCHANT_CELL=Vector2i(48,34)
	w.merchant_visit={"state":"waiting","day":2,"route":[],"credit":0.0,"steps":0,"pause_until":0,"retry":0,"leave_after":1000,"hard_end":1000,"goal":w.MERCHANT_CELL}
	check(w.act("wood_wall",Vector2i(48,33)),"Build plan next to waiting merchant accepted")
	var start=Time.get_ticks_usec();w.Merchant.step(w)
	check(w.merchant_visit.state=="approach" and w.merchant_visit.route.size()>1,"Merchant relocates when a neighboring plan is added")
	check(w.Merchant.clearance(w,w.merchant_visit.goal),"New waiting point avoids plans, buildings and zones")
	timings.append({"case":"merchant_relocation","ms":(Time.get_ticks_usec()-start)/1000.0})
	w.merchant_visit.state="return";w.merchant_visit.route=[];w.merchant_visit.hard_end=0;w.Merchant.step(w)
	check(w.merchant_visit.state=="gone","Bounded return prevents endless merchant stay")

func key(code):
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=true;return e
func input_checks(g,w):
	g.neutral();g.pointer=Vector2(700,300)
	for mode in [-1,0,1,2,4]:
		g.group=mode;g.tool="";g.refresh();g.camera.zoom=Vector2.ONE
		var e=InputEventMouseButton.new();e.position=g.pointer;e.pressed=true;e.button_index=MOUSE_BUTTON_WHEEL_DOWN
		g._route_input(e);check(g.camera.zoom.x<1,"Ordinary wheel zooms in mode "+str(mode))
		var zoom=g.camera.zoom.x;e.ctrl_pressed=true;g._route_input(e)
		check(g.camera.zoom.x==zoom,"Control wheel does not zoom in mode "+str(mode))
		if mode==4:check(g.tool!="" and w.jobs.is_empty(),"Command wheel arms tool without creating jobs")
	g.neutral();g.group=4;g.refresh();g.tool="haul";g.pointer=Vector2(700,300)
	var e=InputEventMouseButton.new();e.position=g.pointer;e.pressed=true;e.button_index=MOUSE_BUTTON_WHEEL_DOWN;e.ctrl_pressed=true
	g._route_input(e);check(g.tool=="forbid","Ctrl wheel advances command")
	for code in [KEY_1,KEY_2,KEY_3]:g._route_input(key(code));check(g.speed==code-KEY_1+1,"Number-key speed mapping")
	g.neutral();var p=Vector2i(35,25);g.select_building(p,"structure");g._route_input(key(KEY_E))
	check(g.crafting_panel.opened,"Actual E dispatch opens crafting")
	g.crafting_panel.close(g);g._route_input(key(KEY_X));check(w.jobs.any(func(j):return j.kind=="remove" and j.pos==p),"X queues demolition rather than deleting equipment")
	for j in w.jobs.duplicate():w.Jobs.cancel(w,j.id)
	g.neutral();w.act("wood_wall",Vector2i(38,25));var plan=w.jobs.back()
	g.drag_start=g.center(Vector2i(34,24));g.pointer=g.get_canvas_transform()*g.center(Vector2i(39,27));g.drag_class="building";g.drag_ranks.clear();g.drag_encounters.clear();g.finish_drag()
	check(g.selected.get("kind")=="building_set" and g.selected_buildings.size()==2,"Range selection mixes completed bench and planned wall")
	g._route_input(key(KEY_X));check(not w.jobs.has(plan) and w.jobs.any(func(j):return j.kind=="remove") and w.structures.has(p),"Mixed X cancels plan and queues one equipment demolition")
	for j in w.jobs.duplicate():w.Jobs.cancel(w,j.id)
	g.neutral();w.act("wood_wall",Vector2i(38,25));plan=w.jobs.back();plan.state="blocked";plan.block_reason="資材不足";g.selected={"kind":"job","id":plan.id,"pos":plan.pos}
	g.construction_view.update(w);check(g.selected_construction().lines.any(func(line):return "資材不足" in line) and g.selected_construction().lines.all(func(line):return "時間停止中" not in line),"Pause preserves actual blocked reason")
	g.refresh();var field=LineEdit.new();g.controls.add_child(field);field.grab_focus();await process_frame
	g._route_input(key(KEY_X));check(w.jobs.has(plan),"Text input suppresses X shortcut");field.release_focus();field.free();g.neutral()

func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	marker_proof();var w=fixture();logic(w);logistics();merchant();await ui(fixture())
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/interaction.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"timings":timings},"\t"))
	FileAccess.open(out+"/forbidden-commands.json",FileAccess.WRITE).store_string(JSON.stringify(pictures,"\t"))
	print("InteractionRevision: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
