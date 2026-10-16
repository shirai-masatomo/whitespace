extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var w
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func fixture():
	var result=Farm.new({},731).begin_day()
	result.trees.clear();result.rocks.clear();result.mountains.clear();result.mountain_cells.clear();result.natural.clear();result.field_items.clear();result.structures.clear();result.floors.clear();result.enemies.clear();result.jobs.clear();result.zones.clear();result.animals.clear();result.work_claims.clear();result.build_deliveries.clear()
	result.keeper.pos=Vector2i(30,25);result.keeper.satiety=100;result.keeper.resting=false;result.keeper.sleepiness=0;result.jobs_held=false;result.job_hold_reason=""
	result.campaign.unlocked_blueprints.append_array(["wood_wall","stone_wall","locked_door"])
	result.refresh_indoor();return result
func ready(kind:String,q:Vector2i):
	var d=w.BUILD[kind];var b={"id":w.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.resource,"armor":0,"open":false,"lock_hp":8 if kind=="locked_door" else 0}
	w.next_structure_id+=1;w.Buildings.layer(w,kind)[q]=b
func house(origin:Vector2i):
	for x in range(5):
		for y in range(5):
			var q=origin+Vector2i(x,y)
			ready("wood_wall" if x==0 or x==4 or y==0 or y==4 else "wood_tile",q)
	ready("door",origin+Vector2i(2,0));w.refresh_indoor()
func tick_work(count:int):
	for i in range(count):
		w.tick+=1
		for a in w.workers.values():a.stamina=100;a.sleepiness=0;a.timetable.fill("work")
		w.Work.step(w)
func construction():
	w=fixture();var pos=Vector2i(35,25)
	check(w.Jobs.build_reason(w,"wood_wall",pos)=="" and w.act("wood_wall",pos),"Zero stock permits ordinary ghost and designation")
	tick_work(10);check(w.jobs.size()==1 and not w.jobs[0].started,"Unfunded job remains pending, not cancelled")
	w.Zones.create(w,"stockpile",Vector2i(29,23),Vector2i(30,23));w.Stock.add(w,"wood",3,Vector2i(29,23))
	tick_work(90);check(w.jobs.size()==1 and w.Stock.delivered(w,w.jobs[0])==3 and not w.jobs[0].started,"Three of five units delivered without premature assembly")
	w.Stock.add(w,"wood",2,Vector2i(29,23));tick_work(90)
	check(w.structures.get(pos,{}).get("status")=="ready" and w.jobs.is_empty(),"Later two units restart delivery and finish without redesignation")
	check(w.stock_used.get("wood",0)==5 and w.Stock.totals(w).get("wood",0)==0,"Five physical units consumed exactly once")
	w=fixture()
	for x in range(101):
		var q=Vector2i(10+x%20,10+x/20)
		check(w.act("wood_wall",q)==(x<100),"Unfunded limit at designation "+str(x+1))
	check(w.jobs.size()==100,"Reservation cap stays100")
	w.Jobs.cancel(w,w.jobs[0].id);check(w.jobs.size()==99 and w.Stock.totals(w).get("wood",0)==0,"Unfunded cancellation creates no resources")
func housing():
	w=fixture();var origin=Vector2i(15,15);house(origin)
	check(w.homes.size()==1 and w.homes.values()[0].cells.size()==9,"Completed floor/wall/door creates nine-cell house")
	var id=w.homes.keys()[0];var floor=origin+Vector2i(1,1);var old=w.floors[floor]
	w.floors.erase(floor);w.refresh_indoor();check(w.homes.is_empty(),"Missing one completed floor invalidates house")
	w.floors[floor]=old;w.refresh_indoor();id=w.homes.keys()[0]
	var door=origin+Vector2i(2,0);w.structures[door].open=true;w.refresh_indoor();check(w.homes.has(id),"Open door preserves stable house ID")
	ready("wood_wall",Vector2i(40,40));w.refresh_indoor();check(w.homes.has(id),"Unrelated building preserves house ID")
	ready("bed",origin+Vector2i(2,2));w.refresh_indoor();w.Zones.create(w,"residential",origin+Vector2i.ONE,origin+Vector2i(3,3));w.Homes.assign_pending(w)
	check(w.keeper.get("home_id")==id and not w.Homes.bed(w,w.keeper).is_empty(),"Residential zone auto-assigns keeper to a bed")
	var helper=w.keeper.duplicate(true);helper.erase("home_id");helper.erase("bed_id");helper.pos=Vector2i(29,25);helper.name="田中";w.Work.register(w,"helper",helper);w.Homes.assign_pending(w)
	check(not helper.has("bed_id"),"One bed never assigns two residents")
	ready("bed",origin+Vector2i(3,2));w.refresh_indoor();w.Homes.assign_pending(w)
	check(helper.get("bed_id",-1)!=w.keeper.bed_id and helper.get("home_id")==id,"Second bed assigns second resident, preserving first")
	check("たちの家" in w.Homes.title(w,w.homes[id]),"House title describes multiple residents")
	var bed=w.Homes.bed(w,helper);w.structures.erase(bed.pos);w.refresh_indoor();w.Homes.assign_pending(w);check(not helper.has("home_id"),"Removed bed releases obsolete resident assignment")
	w.structures[door].status="destroyed";w.refresh_indoor();w.Homes.assign_pending(w);check(w.homes.is_empty() and not w.keeper.has("home_id"),"Broken enclosure invalidates house and home assignment")
func deep():
	w=fixture();house(Vector2i(15,15));var h=w.homes.values()[0];ready("bed",Vector2i(17,17));w.refresh_indoor();w.Zones.create(w,"residential",Vector2i(16,16),Vector2i(18,18));w.Homes.assign_pending(w)
	var a=w.keeper;clock_at(0);a.sleepiness=80
	for i in range(180):
		w.tick+=1;a.stamina=100;w.Sleep.step(w,a)
		if a.get("asleep",false):break
	check(a.get("asleep",false) and a.get("rest_target")==a.pos and "ベッド" in a.get("rest_reason",""),"Assigned resident walks into house and sleeps at own bed access cell")
	check(w.Sleep.recovery(w,a)>100.0/108.0,"Assigned bed increases recovery")
	var hp=a.hp;var fatigue=a.sleepiness;w.Life.step(w);check(a.sleepiness==fatigue and a.hp==hp,"Keeper Life does not apply a second sleep/HP recovery")
	# Rebuild must connect interior doors but does not identify a doorless enclosure as a house.
	w=fixture()
	for x in range(9):
		for y in range(5):ready("wood_wall" if x in [0,4,8] or y in [0,4] else "wood_tile",Vector2i(10+x,10+y))
	ready("door",Vector2i(12,10));ready("door",Vector2i(14,12));w.refresh_indoor()
	check(w.homes.size()==1 and w.homes.values()[0].cells.size()==18,"Interior door joins two floored rooms into one house")
	var id=w.homes.keys()[0];ready("wood_wall",Vector2i(14,12));ready("door",Vector2i(16,10));w.refresh_indoor();check(w.homes.size()==2 and w.homes.has(id),"Partition produces two houses and retains one stable ID")
	w.structures[Vector2i(12,10)].kind="wood_wall";w.structures[Vector2i(16,10)].kind="wood_wall";w.refresh_indoor();check(w.homes.is_empty(),"Doorless sealed rooms are not inhabitable houses")
	# An unseen resident does not leak its exact position to an invader.
	w=fixture();house(Vector2i(15,15));w.keeper.pos=Vector2i(17,17);w.spawn_enemy({"role":"kidnapper","entry":Vector2i(0,30),"lv":1,"wave":999});var e=w.enemies.back();e.pos=Vector2i(17,12);e.sight_range=12
	w.RaiderAI.perceive(e,w);check(not e.can_see_keeper,"Closed wall/door hides resident from direct sight")
	var goal=w.RaidNavigation.objective(w,e);check(goal!=w.keeper.pos and goal==Vector2i(17,16),"Visible entrance supplies an interior search waypoint, not hidden resident coordinate")
	var route=w.RaiderAI.route(e,w,goal,true,false)
	check(route.has(Vector2i(17,15)) and route.all(func(q):return not w.Buildings.enclosure(w.structures.get(q,{})) or w.structures[q].kind in w.Buildings.DOORS),"Invader uses ordinary door before breaking walls")
	w.move_enemy(e,Vector2i(17,15),goal);check(w.structures[Vector2i(17,15)].open,"Actual movement opens unlocked door")
	e.pos=goal;w.RaidNavigation.objective(w,e);check(not e.raid_zone_visits.is_empty(),"Visited house search gets a bounded revisit cooldown")
	# A helper remains a valid target even while the keeper is down.
	var helper=w.keeper.duplicate(true);helper.pos=Vector2i(17,18);helper.hp=30;helper.state="free";w.Work.register(w,"helper",helper);w.keeper.hp=0;w.keeper.state="unconscious";e.pos=Vector2i(17,19)
	check(w.Progression.target_candidates(w,e).any(func(t):return t.kind=="worker"),"Keeper down does not remove other visible humans from candidates")
	# A cancelled partially supplied job returns exactly the physical resources present.
	w=fixture();w.Zones.create(w,"stockpile",Vector2i(29,23),Vector2i(30,23));w.Stock.add(w,"wood",3,Vector2i(29,23));w.act("wood_wall",Vector2i(35,25));tick_work(90)
	var job=w.jobs[0];w.Jobs.cancel(w,job.id);check(w.Stock.totals(w).get("wood",0)==3 and w.field_items.all(func(r):return r.get("location")=="ground"),"Cancellation returns partial materials without loss")

func clock_at(h:int):w.calendar_ticks=posmod(h-5,24)*72
func sleeping():
	w=fixture();var a=w.keeper;clock_at(0);a.sleepiness=50
	w.Sleep.step(w,a);check(a.resting and a.rest_kind=="scheduled","Sleep timetable begins at sleepiness50")
	clock_at(6);w.Sleep.step(w,a);check(not a.resting,"Schedule end wakes before complete recovery")
	clock_at(12);a.sleepiness=100;w.Sleep.step(w,a);check(a.resting and a.forced_rest,"Exhaustion overrides work schedule")
	w.Sleep.wake(w,a,true);w.Sleep.step(w,a);check(not a.resting,"Manual wake grace prevents immediate sleep loop")
	w.tick=a.wake_until+1;w.Sleep.step(w,a);check(a.forced_rest,"Exhaustion re-evaluated after bounded wake grace")
	a.sleepiness=0;w.Sleep.step(w,a);check(not a.resting and not a.forced_rest,"Forced sleep ends at zero")
	clock_at(0);a.sleepiness=100;a.asleep=true;a.resting=true;a.rest_kind="forced";a.forced_rest=true;a.rest_elapsed=10
	var amount=w.Sleep.recovery(w,a);check(is_equal_approx(amount,100.0/108.0),"Ordinary preferred-time ground sleep recovers100 per108s")
	a.sleep_trait="short";check(w.Sleep.recovery(w,a)>amount,"Short sleeper recovers faster")
	a.sleep_trait="long";check(w.Sleep.recovery(w,a)<amount,"Long sleeper recovers slower")
	a.sleep_trait="normal";clock_at(12);check(w.Sleep.recovery(w,a)<amount,"Off-type sleeping is less efficient")
	w.Sleep.wake(w,a);a.sleepiness=0;a.timetable.fill("work")
	for i in range(1728):w.tick+=1;w.Sleep.step(w,a)
	check(absf(a.sleepiness-100)<0.1,"432 simulation seconds raise ordinary sleepiness0 to100")
	for kind in w.Sleep.TYPES:
		var defaults=w.Sleep.defaults(kind);check(defaults.count("sleep")==6,"Six default hours for "+kind)
	check(w.Sleep.defaults("early")[23]=="sleep" and w.Sleep.defaults("early")[0]=="sleep","Early schedule wraps midnight")
	w=fixture();a=w.keeper;clock_at(12);var before=w.Sleep.activity(w,a);w.Sleep.edit(w,a,12,"sleep");w.Sleep.edit(w,a,13,"sleep")
	check(w.Sleep.activity(w,a)==before,"Editing timetable does not change current hour")
	clock_at(13);check(w.Sleep.activity(w,a)=="sleep" and not a.has("pending_timetable"),"Pending edit activates at next hour")
	a.sleepiness=80;w.Sleep.step(w,a);check(a.resting,"Edited schedule governs sleep")
	a.drafted=true;w.Sleep.step(w,a);check(not a.resting,"Draft overrides scheduled sleep")
func raid():
	w=fixture();w.spawn_enemy({"role":"kidnapper","entry":Vector2i(0,30),"lv":1,"wave":999});var e=w.enemies.back();e.pos=Vector2i(30,30)
	var targets=[{"kind":"structure","id":1,"pos":Vector2i(31,30)},{"kind":"worker","id":"helper","pos":Vector2i(32,30)}]
	check(w.Progression.Targets.focus(w,e,targets)[0].kind=="worker","Visible resident outranks closer structure")
	check(w.Progression.Targets.focus(w,e,[targets[0]]).is_empty(),"Kidnapper has no independent building attack target")
	check(e.human_memory==Vector2i(32,30),"Human memory stores last observed position")
	e.archetype="destroyer";check(w.Progression.Targets.focus(w,e,[targets[0]]).size()==1,"Destroyer keeps structural target")
func ui():
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production loading builds UI headlessly")
	if not boot.finished:boot.queue_free();return
	var scene=boot.game;scene.set_process(false);scene.world=fixture();scene.world.paused=true;scene.story_modal="";scene.field_book=false;scene.field_shop=false;scene.neutral();scene.colony_page="schedule";scene.refresh()
	check(scene.colony_panel.name=="Timetable","Time tab builds a24-hour resident panel")
	check(scene.colony_panel.size.x<=1280 and scene.colony_panel.position.y>=49,"Time panel fits1280x800 logical canvas")
	var hours=scene.colony_panel.find_children("*","Control",true,false).filter(func(c):return c.get_script()==scene.HomeUI.Hours)
	if not hours.is_empty():
		var row=hours[0];check(row.get_parent().has_node("Wake"),"Every human timetable row provides manual wake control");scene.schedule_brush="sleep";row.paint(22*24);row.paint(23*24);row.last=-1;row.paint(0);row.paint(4*24)
		check(scene.world.keeper.pending_timetable[23]=="sleep" and scene.world.keeper.pending_timetable[4]=="sleep","Timetable brush supports midnight-crossing sleep")
	for size in [Vector2i(1280,800),Vector2i(1600,1000)]:
		root.size=size;scene.refresh();check(scene.colony_panel.position.y>=49 and scene.colony_panel.size.x<=1280,"Schedule logical layout remains within bounds "+str(size))
	w=scene.world;house(Vector2i(15,15));scene.neutral();scene.camera.zoom=Vector2.ONE
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=scene.get_canvas_transform()*scene.center(Vector2i(16,16))
	scene.board_click(e);check(scene.selected.get("kind")=="house","Single click selects house")
	scene.board_click(e);check(scene.home_individual>=0 and scene.selected.get("kind")=="floor","Second click enters individual floor selection")
	var esc=InputEventKey.new();esc.pressed=true;esc.physical_keycode=KEY_ESCAPE;scene._route_input(esc);check(scene.home_individual<0 and not scene.menu_open,"Escape exits individual mode without opening menu")
	scene.select_group(0);scene.architect_category="設置";scene.refresh();check(scene.buttons.has("bed"),"Bed available through architect furniture category");scene.tool="bed";scene.board_click(e);check(w.jobs.any(func(j):return j.kind=="bed"),"Construction inside house bypasses normal house selection")
	scene.neutral();scene.home_click_id=-1;scene.board_click(e);check(scene.colony_panel.name=="HouseStatus","House status uses dedicated compact panel")
	boot.queue_free();await process_frame
class Paint:
	extends RefCounted
	var world
	var TILE=Vector2(48,42)
	var calls=[]
	func center(q):return Vector2(q)*TILE+TILE/2
	func box(r):return [r.position.x,r.position.y,r.size.x,r.size.y]
	func wall_links(q):
		var result={}
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:result[d]=world.Buildings.enclosure(world.structures.get(q+d,{}))
		return result
	func draw_texture(t,p,_c=Color.WHITE):calls.append({"path":t.resource_path,"at":[p.x,p.y]})
	func draw_texture_rect_region(t,r,src):calls.append({"path":t.resource_path,"at":[r.position.x,r.position.y],"src":box(src)})
	func draw_mesh(_m,t,tr,_c):calls.append({"path":t.resource_path,"at":[tr.origin.x,tr.origin.y],"mesh":true})
	func draw_rect(r,c):calls.append({"rect":box(r),"color":c.to_html()})
func rendering():
	w=fixture();house(Vector2i(1,1));ready("bed",Vector2i(3,3));w.refresh_indoor()
	var art=preload("res://game/building_art.gd");var pen=Paint.new();pen.world=w;var pages=[]
	for updated in [false,true]:
		pen.calls.clear()
		for q in w.floors:
			if updated:art.floor_tile(pen,q)
			else:
				var mask=0
				for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
					if not w.floors.has(q+pair[0]):mask+=pair[1]
				art.floor_at(pen,q,w.floors[q].kind,mask)
		var regions=pen.calls.filter(func(c):return c.has("src"))
		if updated:
			check(regions.size()==12,"All twelve interior boundary sides receive cropped floor underlay")
			check(regions.all(func(c):return c.src[2]<=48 and c.src[3]<=42),"Floor underlay crops the original without image scaling")
		for q in w.structures:
			var b=w.structures[q]
			if b.kind=="bed":art.bed(pen,pen.center(q))
			elif b.kind in w.Buildings.DOORS:
				for layer in ["frame_rear","leaf","frame_front"]:art.door_layer(pen,pen.center(q),b,layer)
			else:art.wall(pen,pen.center(q),b,false)
		pages.append(pen.calls.duplicate(true))
	var output=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/housing-draw.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"pages":pages,"sx":art.WALL_SOURCE_X,"sy":art.WALL_SOURCE_Y,"dx":art.WALL_DEST_X,"dy":art.WALL_DEST_Y},"  "));output.close()
func run():
	construction();housing();sleeping();raid();deep();rendering();await ui()
	var failed=checks.filter(func(c):return not c.passed).size()
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/housing-sleep.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed},"  "));f.close()
	print("Housing/sleep: %d checks, %d failures"%[checks.size(),failed]);quit(1 if failed else 0)
