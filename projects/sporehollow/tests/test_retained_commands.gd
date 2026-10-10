extends SceneTree
const Farm=preload("res://game/world.gd")
var report={"method":"Controlled production World.step checks plus injected scene InputEvents and manually advanced main._process frames; no human play","groups":[]}
var group={}
var failed=0
var output=""
func _initialize():call_deferred("run")
func begin(name: String):group={"name":name,"checks":[]};report.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func fresh():
	var w=Farm.new({},17).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0;return w
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="":quit(2);return
	begin("Exact legacy guide reproduction")
	var w=fresh();w.natural.clear();w.keeper.pos=Vector2i(10,8);w.keeper.sleepiness=35
	var a=w.animals[0];a.pos=Vector2i(12,8);a.mode="stay";a.order_until=9999;a.order=a.pos;a.home=a.pos
	for y in range(7,11):
		for x in range(8,15):
			w.floors[Vector2i(x,y)]={"id":w.next_structure_id,"kind":"wood_tile","status":"ready","hp":16,"max_hp":16,"cost":2,"resource":"wood","open":false};w.next_structure_id+=1
	check(w.act("guide",Vector2i(13,9),1),"Legacy guide command accepted")
	var target=w.jobs[0].targets[0].dest
	group.initial={"keeper":w.keeper.pos,"animal":a.pos,"idol_cells":w.Story.idol_cells(w),"requested":Vector2i(13,9),"requested_walkable":w.animal_walkable(a,Vector2i(13,9)),"allocated":target}
	for i in range(32):w.step()
	group.final={"keeper":w.keeper.pos,"animal":a.pos,"jobs":w.jobs.duplicate(true),"log":w.job_log.duplicate(true)}
	check(w.jobs.is_empty() and w.job_log.any(func(e):return e.event=="guide_arrived" and e.destination==[target.x,target.y]),"Animal physically arrived at the allocated reachable destination")
	check(target!=Vector2i(13,9) and Vector2i(13,9) in w.Story.idol_cells(w),"Old exact-coordinate expectation targets the installed idol footprint")
	begin("Drafted movement, hunger and suspension")
	w=fresh();w.trees.clear();w.keeper.pos=Vector2i(4,6);w.keeper.satiety=20
	check(not w.act("keeper_move",Vector2i(6,6)),"Undrafted ground move is rejected; autonomous work remains in charge")
	w.Work.set_drafted(w,"keeper",true);w.paused=true
	check(w.act("keeper_move",Vector2i(6,6)) and w.tick==0 and w.keeper.pos==Vector2i(4,6) and w.jobs[0].get("direct_control",false),"Paused draft move records a destination without executing it")
	check(w.act("keeper_move",Vector2i(7,6)) and w.jobs.size()==1 and w.jobs[0].pos==Vector2i(7,6),"New destination replaces the previous direct command")
	w.paused=false
	for i in range(16):w.step()
	check(w.keeper.pos==Vector2i(7,6) and w.keeper.satiety<20 and w.stock_used.get("mushroom",0)==0,"Hungry drafted person moves; satiety falls but eating is suspended")
	w.act("keeper_move",Vector2i(11,6))
	var helper=w.keeper.duplicate(true);helper.pos=Vector2i(15,6);w.Work.register(w,"helper",helper);w.Work.set_drafted(w,"helper",false)
	check(w.jobs.any(func(j):return j.get("direct_control",false)),"Undrafting another worker preserves the keeper direct order")
	w.Work.set_drafted(w,"keeper",false)
	check(not w.jobs.any(func(j):return j.get("direct_control",false)),"Undrafting clears stale direct movement instead of executing it as autonomous work")
	w.Work.set_drafted(w,"keeper",true);w.keeper.resting=true;w.keeper.forced_rest=true;w.keeper.sleepiness=100
	w.act("keeper_move",Vector2i(10,6));var origin=w.keeper.pos;w.step()
	check(w.keeper.pos==origin and w.Jobs.status(w)=="休息中","Draft command cannot move a forced sleeper")
	begin("Retained legal guidance, equipment and prayer")
	w=fresh();w.trees.clear();w.keeper.pos=Vector2i(4,6);a=w.animals[0];a.pos=Vector2i(6,6);a.mode="stay";a.order_until=9999;a.order=a.pos;a.home=a.pos
	check(w.act("guide",Vector2i(8,6),1),"Valid animal guidance is still accepted")
	var guide_id=w.jobs.back().id
	for i in range(80):
		w.step()
		if not w.jobs.any(func(j):return j.id==guide_id):break
	check(a.pos==Vector2i(8,6) and w.job_log.any(func(e):return e.event=="guide_arrived" and e.id==guide_id),"Valid guidance physically reaches the requested cell")
	w.Stock.add(w,"collar",1,Vector2i(5,6));check(w.Progression.equip_job(w,1,"collar"),"Existing equipment order accepted")
	var saw_cargo=false
	for i in range(100):
		w.step();saw_cargo=saw_cargo or not w.Stock.cargo(w,"keeper").is_empty()
		if not a.equipment.is_empty():break
	check(saw_cargo and a.equipment.get("item_id")=="collar" and w.Stock.totals(w).get("collar",0)==1,"Equipment is fetched, carried and equipped exactly once")
	w=fresh();w.campaign.day=2;w.phase="defend";w.spawn_schedule=[];w.schedule_index=0;w.story.investigated=true;w.keeper.pos=w.Story.goals(w)[0]
	var karma=w.story.hidden.karma
	check(w.act("pray_gold"),"Existing eligible prayer accepted")
	for i in range(14):w.step()
	check(w.story.prayers.size()==1 and w.story.hidden.karma==karma+w.Story.PRAYER_KARMA and w.story.prayed_day==2,"Prayer completes once with its existing karma and aftermath records")
	w=fresh();w.campaign.day=2;w.phase="defend";w.spawn_schedule=[];w.schedule_index=0;w.story.investigated=true;w.keeper.pos=w.Story.goals(w)[0]
	w.act("pray_gold");w.step();w.Life.hurt(w,{"id":999,"attack_power":1})
	check(w.jobs.is_empty() and w.story.prayers.is_empty() and w.work_claims.is_empty(),"Damage still interrupts a started prayer without a reward or stale ownership")
	if DisplayServer.get_name()!="headless":await ui_checks()
	report.passed=failed==0;report.failures=failed
	FileAccess.open(output+"/retained-commands.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("Retained commands: ",report.groups.size()," groups, ",failed," failures");quit(0 if failed==0 else 1)
func click_at(at: Vector2,button: int=MOUSE_BUTTON_LEFT):
	var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await process_frame
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=at;e.button_index=button;e.pressed=down;Input.parse_input_event(e);await process_frame
func ui_checks():
	begin("Actual scene input and merchant route")
	root.size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=fresh();g.world.trees.clear();g.world.keeper.pos=Vector2i(4,6);g.world.paused=true
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.choose_walk()
	await click_at(g.screen_cell(Vector2i(6,6)))
	check(g.world.jobs.is_empty(),"Undrafted actor's ground click does not create an old manual movement queue")
	g.world.Work.set_drafted(g.world,"keeper",true);g.choose_walk()
	await click_at(g.screen_cell(Vector2i(6,6)))
	check(g.world.jobs.size()==1 and g.world.jobs[0].get("direct_control",false) and g.world.tick==0,"Drafted ground click records movement through the actual scene input path")
	await click_at(g.screen_cell(Vector2i(5,8)),MOUSE_BUTTON_RIGHT)
	check(g.selected.is_empty() and g.world.jobs.size()==1,"Deselecting preserves the drafted destination")
	g.world.paused=false;g.automated=false # Enable the production frame-loop stepping branch after safe fixture initialization.
	for i in range(90):g._process(1.0/30.0)
	group.movement={"tick":g.world.tick,"position":g.world.keeper.pos,"jobs":g.world.jobs.duplicate(true)}
	check(g.world.keeper.pos==Vector2i(6,6) and g.world.jobs.is_empty(),"Actual scene frame loop executes the drafted destination")
	g.world.Work.set_drafted(g.world,"keeper",false);g.world.tick=20;g.world.keeper.pos=Vector2i(3,8);g.world.keeper.satiety=100;g.request_merchant()
	check(g.merchant_requested and g.world.jobs.any(func(j):return j.get("purpose","")=="merchant" and not j.get("direct_control",false)),"Merchant approach remains available without drafting")
	for i in range(180):
		g._process(1.0/30.0)
		if g.world.market_open:break
	group.merchant={"tick":g.world.tick,"position":g.world.keeper.pos,"destination":g.merchant_talk_target,"market_open":g.world.market_open}
	check(g.world.market_open,"Existing merchant approach reaches and opens the shop")
	g.close_morning_screen();g.world.paused=true;g.neutral();g.colony_page="roles";g.group=2;g.refresh();g.queue_redraw();g.hud.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/retained-controls.png")
