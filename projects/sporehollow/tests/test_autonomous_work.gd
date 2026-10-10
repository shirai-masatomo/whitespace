extends SceneTree
const Farm=preload("res://game/world.gd")
var failures=0
var record={"method":"Production World.step on controlled terrain; synthetic second human only for contention; injected Godot UI input; no human play","groups":[]}
var group={}
var output=""
func _initialize():call_deferred("run")
func start_group(name: String):
	group={"name":name,"checks":[]};record.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day()
	w.trees.clear();w.natural.clear();w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0;w.keeper.pos=Vector2i(4,6);w.keeper_path=[[4,6]]
	w.animals[0].pos=Vector2i(20,13);w.animals[0].mode="stay";w.story.intro_seen=true
	return w
func run_steps(w,n: int):
	for i in range(n):w.step()
func drain(w,n: int=160):
	for i in range(n):
		if w.jobs.is_empty():return
		w.step()
func press(button):
	if button==null:check(false,"Required UI control exists");return
	var at=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await process_frame
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	start_group("1 Live selection, registration and resource shortage")
	var w=farm();w.natural[Vector2i(5,6)]="stump";w.field_items=[{"kind":"egg","pos":Vector2i(6,6),"born_day":1}]
	check(w.act("wood_wall",Vector2i(4,7)) and w.act("collect",Vector2i(5,6)) and w.act("collect",Vector2i(6,6)),"Three designations registered, including construction with no wood")
	check(w.wood==0 and w.jobs[0].reserved==0,"Registration does not debit a budget or assign a person")
	var build_id=w.jobs[0].id;var gather_id=w.jobs[1].id
	w.Work.set_priority(w,"keeper","build",1);w.Work.set_priority(w,"keeper","gather",2)
	w.step()
	check(w.job_log.any(func(e):return e.event=="assigned" and e.id==gather_id) and w.jobs[0].state=="blocked","Unavailable higher-priority construction yields to gathering")
	drain(w)
	check(w.jobs.is_empty() and w.structures[Vector2i(4,7)].status=="ready" and w.campaign.eggs==1,"Production World completes gathering, item recovery and construction autonomously")
	check(w.wood==w.Rules.NATURE.stump_wood-w.BUILD.wood_wall.cost and w.work_claims.is_empty(),"One building charge and no leaked target claims")
	group.log=w.job_log;group.resources=w.resource_snapshot()
	start_group("2 Ownership and two-human contention")
	w=farm();w.natural[Vector2i(8,6)]="stump"
	w.act("collect",Vector2i(8,6));var job=w.jobs[0]
	var helper=w.keeper.duplicate(true);helper.pos=Vector2i(8,8);helper.name="検証用の人";w.Work.register(w,"helper",helper)
	check(w.Work.claim(w,"keeper",job) and not w.Work.claim(w,"helper",job),"Second human cannot claim the same job")
	var competing=job.duplicate(true);competing.id=900;competing.assigned_to=""
	check(not w.Work.claim(w,"helper",competing),"Distinct job ID cannot claim an already reserved target")
	w.Work.interrupt(w,"keeper","検証の担当解除")
	w.Work.set_drafted(w,"keeper",true);w.step()
	check(job.assigned_to=="helper","Released target can be claimed by the other human through World.step")
	drain(w)
	check(w.wood==w.Rules.NATURE.stump_wood and w.jobs.is_empty() and w.work_claims.is_empty(),"Two-human contention collects exactly once")
	w.Work.set_drafted(w,"keeper",false);w.act("wall",Vector2i(4,7));w.act("wall",Vector2i(9,7));w.step()
	check(w.jobs.all(func(j):return j.get("assigned_to","")!="") and w.work_claims.size()==2,"Two actors execute distinct construction jobs in the production loop")
	drain(w);check(w.metrics.built==2 and w.materials==80 and w.work_claims.is_empty(),"Parallel construction consumes two budgets exactly once")
	group.log=w.job_log
	start_group("3 Interrupt, blocked route, vanished target and recovery")
	w=farm();w.act("wall",Vector2i(4,7));w.step();job=w.jobs[0]
	var remaining=job.remaining
	w.Work.set_drafted(w,"keeper",true);run_steps(w,3)
	check(job.remaining==remaining and w.work_claims.is_empty() and w.Jobs.status(w)=="徴兵中","Drafting releases claim and retains partial progress")
	w.Work.set_drafted(w,"keeper",false);w.keeper.hurt_until=w.tick+3;w.step()
	check(job.remaining==remaining and w.work_claims.is_empty(),"Injury postpones work without losing its phase")
	w.keeper.life_need="food";run_steps(w,3)
	check(w.Jobs.status(w)=="空腹・食事を優先" and job.remaining==remaining,"Future life-need hook interrupts work; this is not an implemented hunger simulation")
	w.keeper.erase("life_need");w.keeper.danger_near=true;w.Work.step(w)
	check(w.work_claims.is_empty(),"Combat alert retains progress without a permanent owner")
	w.keeper.danger_near=false;drain(w)
	check(w.metrics.built==1 and w.materials==90 and w.work_claims.is_empty(),"After danger clears, partial construction resumes without a second charge")
	w.act("collect",Vector2i(10,6)) # absent target must reject
	w.natural[Vector2i(10,6)]="stump";w.act("collect",Vector2i(10,6));job=w.jobs.back()
	for cell in w.neighbors(Vector2i(10,6)):w.structures[cell]={"id":700+cell.x+cell.y*25,"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false}
	w.act("wall",Vector2i(5,7));run_steps(w,24)
	check(job.state=="blocked" and job.assigned_to=="" and w.metrics.built==2,"Closed route yields to other work instead of holding the worker")
	var attempts=w.job_log.filter(func(e):return e.event=="assigned" and e.id==job.id).size()
	check(attempts<=4,"Blocked route retries are bounded, not every tick")
	w.structures.erase(Vector2i(9,6));drain(w)
	check(w.wood==w.Rules.NATURE.stump_wood and w.jobs.is_empty(),"Opening a route allows autonomous reselection")
	w.natural[Vector2i(14,6)]="stump";w.act("collect",Vector2i(14,6));w.step();w.natural.erase(Vector2i(14,6));w.step()
	check(w.jobs.is_empty() and w.work_claims.is_empty() and w.job_log.any(func(e):return e.event=="target_missing"),"Disappeared target releases ownership and removes stale work")
	w.act("wall",Vector2i(5,8));w.step();job=w.jobs.back();w.keeper.carrier=99;w.step()
	check(w.work_claims.is_empty() and job.assigned_to=="","Capture releases work ownership")
	w.keeper.carrier=-1;w.keeper.dead=true;w.step();check(w.work_claims.is_empty(),"Death state retains no target claim")
	w.keeper.erase("dead");w.Jobs.cancel(w,job.id);check(w.jobs.is_empty() and w.work_claims.is_empty(),"Cancellation releases reservations")
	group.log=w.job_log
	start_group("4 Save/load and paid legacy construction")
	w=farm();w.act("wall",Vector2i(4,7));w.step();job=w.jobs[0];remaining=job.remaining
	w.natural[Vector2i(9,6)]="stump";w.act("collect",Vector2i(9,6));w.Work.set_priority(w,"keeper","gather",3)
	w.persist_farm();var data=JSON.parse_string(JSON.stringify(w.campaign))
	var loaded=Farm.new(data,31);loaded.trees.clear();loaded.day_seconds=9999;loaded.nature_config.spawn_chance_per_second=0
	check(loaded.jobs[0].id==job.id and loaded.jobs[0].remaining==remaining and loaded.jobs[0].reserved==10 and loaded.work_claims.is_empty(),"Save reload retains ID, budget, progress; no stale actor lock")
	check(loaded.keeper.work_priorities.gather==3 and loaded.natural.get(Vector2i(9,6))=="stump","Personal priority and designated harvest target survive reload")
	drain(loaded)
	check(loaded.jobs.is_empty() and loaded.metrics.built==1 and loaded.materials==90 and loaded.wood==loaded.Rules.NATURE.stump_wood,"Reload finishes work without loss or duplicate resource charge")
	# Old saves have reserved costs but no required amount, assigned owner, or priority profile.
	data.work_profiles={};data.work_jobs=data.work_jobs.slice(0,1);data.work_jobs[0].erase("required");data.work_jobs[0].erase("assigned_to")
	var legacy=Farm.new(data,31);legacy.trees.clear();legacy.day_seconds=9999;drain(legacy)
	check(legacy.jobs.is_empty() and legacy.materials==90,"Pre-foundation paid construction migrates without charging again")
	if DisplayServer.get_name()!="headless":await ui_group()
	record.failed=failures;record.passed=failures==0
	FileAccess.open(output+"/autonomous-work.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("Autonomous work: ",record.groups.size()," groups; ",failures," failures")
	quit(0 if failures==0 else 1)
func ui_group():
	start_group("5 Real scene / priority and draft input / representative UI")
	root.size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=farm();g.world.paused=true
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral()
	var w=g.world;w.natural[Vector2i(9,6)]="stump";w.act("wall",Vector2i(6,8));w.act("collect",Vector2i(9,6));w.field_items=[{"kind":"egg","pos":Vector2i(8,8),"born_day":1}];w.act("collect",Vector2i(8,8))
	await press(g.buttons.roles)
	var previous=w.keeper.work_priorities.build
	await press(g.colony_panel.find_child("Priority_keeper_build",true,false))
	check(w.keeper.work_priorities.build==(previous+1)%4,"Injected mouse changes the actual worker priority")
	await press(g.colony_panel.find_child("Draft_keeper",true,false))
	check(w.keeper.drafted and w.Jobs.status(w)=="徴兵中","Injected mouse drafts the worker and updates stop reason")
	await press(g.colony_panel.find_child("Draft_keeper",true,false))
	w.paused=false;w.step();w.paused=true;g.refresh();g.refresh_jobs()
	check(not w.Work.active(w).is_empty() and w.Work.active(w).kind=="collect","Actual scene World.step chooses gathering, not registration order")
	var ids=w.jobs.map(func(j):return j.id);g.set_job_category(0)
	check(w.jobs.map(func(j):return j.id)==ids and g.queue_drag_id==-1,"Category display preserves designations and provides no global execution reorder")
	g.message_until=-1;g.queue_redraw();g.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/autonomous-work.png")
	group.jobs=w.jobs.duplicate(true);group.worker=w.keeper.duplicate(true)
