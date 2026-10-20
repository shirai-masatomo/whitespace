extends SceneTree
var records=[]
var failed=false
var source_commit=""
func _initialize():call_deferred("capture")
func shot(g,name,condition):
	g.camera.force_update_scroll();g.queue_redraw();g.hud.queue_redraw()
	if DisplayServer.get_name()=="headless":
		await process_frame
		records.append({"file":name,"dry_run":true,"conditions":condition})
		return
	for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image();var error=image.save_png(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+name)
	failed=failed or error!=OK
	var clock=g.world.Cycle.clock(g.world)
	records.append({"file":name,"source_commit":source_commit,"resolution":[image.get_width(),image.get_height()],"seed":g.world.seed_value,"tick":g.world.tick,"day":g.world.campaign.day,"game_time":g.world.Cycle.label(g.world),"fixture":condition!="Fresh production map paused at start; no fixture changes","conditions":condition,"paused":true,"method":"Actual Godot Viewport PNG on private noninteractive Windows desktop; unmodified full frame","png_error":error})
func ready(w,kind,q):
	var d=w.BUILD[kind]
	w.Buildings.layer(w,kind)[q]={"id":w.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"materials":w.Buildings.Cost.materials(w,kind),"resource":d.get("resource","soil"),"armor":0,"open":false,"lock_hp":0}
	w.next_structure_id+=1;w.invalidate_navigation()
func neutral(g):
	g.crafting_panel.opened=false;g.zone_controls.selected_id=-1;g.neutral();g.pointer=Vector2(-100,-100)
func work_until(w,condition,limit=400):
	for i in range(limit):
		w.tick+=1;w.calendar_ticks+=1;w.campaign.day=w.Cycle.clock(w).calendar_day();w.Work.step(w)
		if condition.call():return true
	return false
func capture():
	Engine.max_fps=30;source_commit=OS.get_environment("FARM_REVIEW_COMMIT")
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+45000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:push_error("Phase2 capture loading failed: "+boot.failure);quit(1);return
	var g=boot.game;var w=g.world;w.paused=true
	g.set_process(false);g.set_process_input(false);g.set_process_unhandled_input(false)
	g.story_modal="";g.field_book=false;g.field_shop=false;g.controls.visible=true
	g.recenter();neutral(g);g.refresh()
	await shot(g,"01-day-overview.png","Fresh production map paused at start; no fixture changes")
	var q=w.keeper.pos+Vector2i(5,-2)
	# Small local fixture clearing, explicitly recorded. Keep generated surrounding map.
	for x in range(q.x-1,q.x+8):
		for y in range(q.y-1,q.y+5):
			var cell=Vector2i(x,y)
			if cell in w.Story.idol_cells(w):continue
			w.trees.erase(cell);w.rocks.erase(cell);w.natural.erase(cell)
	w.invalidate_navigation();g.view_positions.clear()
	g.select_group(0);g.ColonyPanels.architecture_category(g,"設置");g.select_tool("mushroom_bed")
	g.pointer=g.get_canvas_transform()*g.center(q)
	await shot(g,"02-architect-mushroom.png","Local empty placement fixture near base; existing architect selects 1x1 cultivation bed, mixed wood8/soil4 cost and real ghost; other terrain retained")
	neutral(g)
	for r in w.field_items:
		if r.kind=="wood":r.forbidden=true
	w.Stock.sync(w);w.act("mushroom_bed",q);var plan=w.jobs.back();w.Stock.add(w,"wood",3,q,"site",plan.id)
	g.selected={"kind":"job","id":plan.id,"pos":q};g.refresh()
	await shot(g,"03-mushroom-pending.png","Explicit partial-delivery fixture: active mixed-cost bed plan, onsite wood3 of wood8+soil4; stored wood forbidden to show real material-wait ghost. No simulation progress claim")
	w.Jobs.cancel(w,plan.id)
	for r in w.field_items:
		if r.kind=="wood":r.forbidden=false
	ready(w,"mushroom_bed",q);w.keeper.auto_collect=false;w.keeper.pos=q+Vector2i.LEFT;g.view_positions.clear()
	w.Craft.enqueue(w,q,"grow_mushroom","count",3);var crop_job=w.jobs.back()
	if not work_until(w,func():return w.structures[q].has("culture")):push_error("Capture seed fixture failed");quit(1);return
	neutral(g);g.selected_structures=[q];g.selection_layer="structure";g.selected={"kind":"structure","pos":q};g.crafting_panel.show(g,q)
	await shot(g,"04-mushroom-growing.png","Ready bed is a fixture; seed taken from initial physical stock and inoculated by real HumanWork/Craft executor. Paused immediately after seeding, 48h wait. No full-day simulation")
	var crop=w.structures[q].culture;w.calendar_ticks+=int(crop.ready_tick)-w.tick;w.tick=crop.ready_tick;w.campaign.day=w.Cycle.clock(w).calendar_day();w.keeper.pos=q+Vector2i.LEFT
	if not work_until(w,func():return not w.jobs.has(crop_job)):push_error("Capture harvest fixture failed");quit(1);return
	neutral(g);g.camera.position=g.center(q);g.view_positions.clear();g.selected_resources=[w.keeper.pos];g.selected={"kind":"resource","pos":w.keeper.pos};g.refresh()
	await shot(g,"05-mushroom-harvest.png","Same inoculated crop; fixture clock advanced exactly to maturity; real harvest executor created mushroom3 at worker feet; auto-collect OFF only for visibility. Full-frame real game, not natural 48h play")
	var cook=q+Vector2i(3,1);ready(w,"cooking_bench",cook);w.Craft.enqueue(w,cook,"roast_mushroom","count",5);var cooking=w.jobs.back()
	if not work_until(w,func():return cooking.craft_progress>=1.5):push_error("Capture cooking progress failed");quit(1);return
	neutral(g);g.camera.position=g.center(cook);g.view_positions.clear();g.crafting_panel.show(g,cook)
	await shot(g,"06-cooking-workbench.png","Completed cooking bench fixture; real seed-stock mushroom2 reservation, transport and cooking executor paused at >=1.5s work; five-portion batch uses established satiety20 per portion")
	neutral(g);var stock=w.zones.filter(func(z):return z.kind=="stockpile")[0]
	stock.name="食材置場";stock.filter={"all":false,"categories":{"food":true},"subs":{},"items":{}};stock.priority=1;w.Stock.sync(w)
	g.zone_controls.open(g,stock.id);g.refresh();g.recenter()
	await shot(g,"07-stockpile-food.png","Existing initial stockpile fixture renamed food store; food-only category filter and access displayed together; original physical goods retained even if filter excludes them")
	neutral(g);g.choose_walk();g.resident_tab="ステータス";g.refresh()
	await shot(g,"08a-resident-status.png","Same paused capture fixture; actual keeper HP/satiety/stamina/mood panel, no idealized values or screenshot retouching")
	g.HomeUI.open_schedule(g,"keeper");g.HomeUI.tab(g,"food")
	await shot(g,"08b-resident-food.png","Same keeper; life food-priority matrix, default resident-specific ranks, underlying real Controls")
	neutral(g);g.select_group(3)
	await shot(g,"09a-resident-work.png","Actual role priority panel; default actor priorities; paused state from declared work fixtures")
	neutral(g);g.choose_walk();g.resident_tab="仕事";g.refresh()
	await shot(g,"09b-auto-collect.png","Keeper work tab showing actual auto-collect checkbox (OFF for harvest screenshot fixture), current job and links")
	neutral(g);w.calendar_ticks=(w.campaign.day-1)*1728+17*72;w.phase="defend";w.spawn_enemy({"role":"kidnapper","entry":w.keeper.pos+Vector2i(5,-3),"lv":1,"wave":999})
	if not w.enemies.is_empty():w.enemies[-1].pos=w.keeper.pos+Vector2i(5,-3)
	g.recenter();g.refresh()
	await shot(g,"10-night-overview.png","Night/raid presentation fixture: calendar22:00, defend phase, one real enemy instance positioned near keeper, paused before attacks; not natural survival reach")
	w.enemies.clear();var origin=q+Vector2i(1,5)
	for x in range(5):
		for y in range(5):
			var cell=origin+Vector2i(x,y);w.trees.erase(cell);w.rocks.erase(cell);w.natural.erase(cell)
			ready(w,"wood_wall" if x==0 or x==4 or y==0 or y==4 else "wood_tile",cell)
	ready(w,"door",origin+Vector2i(2,0));var bed=origin+Vector2i(2,2);ready(w,"bed",bed)
	w.refresh_indoor();w.Zones.create(w,"residential",origin+Vector2i.ONE,origin+Vector2i(3,3));w.Homes.assign_pending(w)
	w.keeper.pos=bed;w.keeper.sleepiness=80;w.keeper.satiety=100;w.keeper.danger_near=false;w.keeper.danger_state="relaxed";w.Sleep.begin(w,w.keeper,false);w.keeper.asleep=true;w.keeper.resting=true;w.keeper.rest_target=bed
	g.actor_art["keeper"]={"resting":true,"since":g.visual_time-1.0,"action":"sleep","at":g.visual_time-1.0}
	neutral(g);g.selected={"kind":"house","id":w.homes.keys()[0]};g.camera.position=g.center(bed);g.view_positions.clear();g.refresh()
	await shot(g,"11-house-sleep.png","Explicit completed5x5 house/wood floor/door/bed/residential fixture; Homes assigned keeper. Night, keeper positioned at assigned bed and sleep presentation set; no claim of player-built progression")
	neutral(g);DisplayServer.window_set_size(Vector2i(1600,1000));root.size=Vector2i(1600,1000);g.recenter();g.select_group(0);g.ColonyPanels.architecture_category(g,"設置");g.select_tool("mushroom_bed")
	await shot(g,"12-wide-overview-1600.png","Same declared production/house/night fixture; viewport resized1600x1000, cultivation architect open. Actual full-frame UI")
	var record={"source_commit":source_commit,"method":"Current source Godot loading.tscn/main.gd viewport, matching packaged implementation commit; private noninteractive desktop, no OS input, Dummy audio, single process","source_exe_sha256":OS.get_environment("FARM_REVIEW_EXE_SHA"),"fps_limit":Engine.max_fps,"renderer":RenderingServer.get_video_adapter_name(),"screens":records,"failed":failed,"elapsed_ms":Time.get_ticks_msec()}
	if DisplayServer.get_name()=="headless":record.method="Headless scene/control fixture preflight only; no rendered PNG, no GPU or private desktop launch"
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+("/CAPTURE_DRY_RUN.json" if DisplayServer.get_name()=="headless" else "/SCREENSHOT_MANIFEST.json"),FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	boot.queue_free();await process_frame;print("PHASE2_CAPTURE frames=",records.size());quit(1 if failed else 0)
