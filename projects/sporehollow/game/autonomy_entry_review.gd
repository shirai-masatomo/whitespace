extends Node
## Opt-in evidence driver attached to the real main scene. Never advances World or main manually.
var g
var output=""
var phase=""
var failures=[]
var evidence={"method":"Exported normal main scene; engine-owned _process; injected UI input only after initial fixture; no World.step or manual main._process calls","checks":[],"states":[]}
var previous=""
var initial_ticks=0
var last_tick=-1
func check(ok: bool,note: String):
	evidence.checks.append({"passed":ok,"check":note})
	if not ok:failures.append(note);push_error(note)
func snapshot_summary():
	var w=g.world
	return {"tick":w.tick,"pos":w.keeper.pos,"satiety":w.keeper.satiety,"paused":w.paused,"jobs":w.jobs.duplicate(true),"claims":w.work_claims.duplicate(true),"stock":w.field_items.duplicate(true),"built":w.metrics.built}
func _process(_delta):
	if g==null or g.world.tick==last_tick:return
	last_tick=g.world.tick
	var state=g.world.Jobs.status(g.world)
	if state!=previous:
		evidence.states.append({"tick":last_tick,"state":state,"cargo":g.world.Stock.cargo(g.world,"keeper").map(func(r):return [r.kind,r.amount]),"satiety":g.world.keeper.satiety});previous=state
func click(at: Vector2):
	var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await get_tree().process_frame
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await get_tree().process_frame
func press(id: String):
	if not g.buttons.has(id):check(false,"Missing UI control: "+id);return
	await click(g.buttons[id].get_global_rect().get_center())
func wait_until(test: Callable,seconds: float) -> bool:
	var deadline=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	return test.call()
func capture(name: String):
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")
func run():
	g=get_parent();output=OS.get_environment("FARM_REVIEW_OUTPUT");phase="resume" if "--resume-entry" in OS.get_cmdline_user_args() else "save"
	evidence.phase=phase;evidence.pid=OS.get_process_id();evidence.user_data=OS.get_user_data_dir();evidence.automated=g.automated;evidence.persistence_enabled=g.persistence_enabled
	g.world.paused=true
	if g.story_modal!="":g.StoryView.close(g) # Initial tutorial dismissal only, before wall designation/load.
	await get_tree().process_frame
	if phase=="save":
		var w=g.Farm.new({},31).begin_day();w.paused=true;w.trees.clear();w.natural.clear();w.field_items.clear();w.nature_config.spawn_chance_per_second=0;w.storage_cells=[];w.stock_used={};w.story.intro_seen=true
		w.keeper.pos=Vector2i(4,6);w.keeper_path=[[4,6]];w.keeper.satiety=31.6
		w.animals[0].pos=Vector2i(20,13);w.animals[0].mode="stay";w.animals[0].order_until=9999
		w.Stock.add(w,"wood",18,Vector2i(8,6));w.Stock.add(w,"mushroom",2,Vector2i(6,5));g.world=w;g.reset_view();g.neutral();g.arrival_started=g.clock-3;g.refresh()
		evidence.fixture="Before designation only: seed31 daytime, cleared trees/natural/loose stock, no natural spawns, keeper(4,6) satiety31.6, wood18@(8,6), mushroom2@(6,5), dog(20,13) staying. Existing day length/speed kept. No API work actions after this point."
		await press("group0");await press("wood_wall");await click(g.screen_cell(Vector2i(4,8)))
		check(w.jobs.any(func(j):return j.kind=="wood_wall" and j.pos==Vector2i(4,8)),"UI wall designation created the real construction job")
		await press("roles");await press("storage_zone");await click(g.screen_cell(Vector2i(10,7)))
		check(Vector2i(10,7) in w.storage_cells,"UI designated storage")
		await press("pause")
		check(await wait_until(func():return not w.Stock.cargo(w,"keeper").is_empty(),12),"Normal engine frames reached material carrying")
		await press("pause");await press("research_save")
		var saved=snapshot_summary();FileAccess.open(output+"/expected-carry.bin",FileAccess.WRITE).store_var(saved,false)
		evidence.saved=saved;evidence.snapshot_path=ProjectSettings.globalize_path("user://autonomy.snapshot")
		check(FileAccess.file_exists("user://autonomy.snapshot") and w.paused and not w.Work.active(w).is_empty() and not w.Stock.cargo(w,"keeper").is_empty(),"UI saved paused carrying state with assigned job")
	else:
		var expected=FileAccess.open(output+"/expected-carry.bin",FileAccess.READ).get_var(false)
		evidence.before_load=snapshot_summary()
		check(g.world.tick!=expected.tick or g.world.Stock.cargo(g.world,"keeper").is_empty(),"Fresh process entered ordinary startup before explicit research load")
		await press("roles");await press("research_load")
		check(snapshot_summary()==expected,"UI research load restored carrying, assignment, progress, quantities and tick exactly")
		evidence.loaded=snapshot_summary()
		await press("pause")
		check(await wait_until(func():return g.world.keeper.has("meal_remaining"),20),"Normal engine frames reached eating after delivery")
		await capture("meal-live")
		check(await wait_until(func():return g.world.metrics.built==1,20),"Normal engine frames resumed work and completed the wall")
		await press("pause")
		check(g.world.stock_used.get("wood",0)==10 and g.world.Stock.totals(g.world).get("wood",0)==8 and g.world.stock_used.get("mushroom",0)==1 and g.world.Stock.totals(g.world).get("mushroom",0)==1,"Completed chain conserved wood18 and food2 with one meal")
		check(g.world.work_claims.is_empty(),"No target reservation remains after construction")
		evidence.completed=snapshot_summary();evidence.used=g.world.stock_used.duplicate(true)
		var status=g.queue_controls.get_node_or_null("JobStatus")
		check(status!=null and not status.clip_text and status.size.x>=248,"Status uses its own wrapping line")
		check(g.colony_panel.size.y<=230,"Single-person roles panel fits its content")
		await capture("wall-live")
	check(not g.automated and g.is_processing(),"Normal scene process stayed enabled without manual stepping")
	evidence.passed=failures.is_empty();evidence.failures=failures
	FileAccess.open(output+"/"+phase+".json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t"))
	get_tree().quit(0 if failures.is_empty() else 1)
