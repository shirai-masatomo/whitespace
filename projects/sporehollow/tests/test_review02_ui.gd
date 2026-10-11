extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func mouse(p,button,down):
	var e=InputEventMouseButton.new();e.position=root.get_final_transform()*p;e.button_index=button;e.pressed=down;Input.parse_input_event(e);await process_frame
func click(p,button=MOUSE_BUTTON_LEFT):
	await mouse(p,button,true);await mouse(p,button,false)
func key(k):
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=k;e.physical_keycode=k;e.pressed=down;Input.parse_input_event(e);await process_frame
func press(g,id):
	check(g.buttons.has(id) and g.buttons[id].is_visible_in_tree(),"Displayed action: "+id)
	if g.buttons.has(id):await click(g.buttons[id].get_global_rect().get_center())
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.enemies.clear();w.spawn_schedule.clear();w.natural.clear();w.trees.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.keeper.pos=Vector2i(10,10);w.keeper.sleepiness=0;w.keeper.satiety=100;w.paused=true;w.nature_config.spawn_chance_per_second=0
	for a in w.animals:a.pos=Vector2i(18,18);a.home=a.pos;a.mode="stay"
	w.Stock.add(w,"soil",40,Vector2i(10,9));w.act("wall",Vector2i(8,10))
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.neutral();g.camera.position=g.center(Vector2i(13,11));g.camera.force_update_scroll()
	var jobs=w.jobs.map(func(j):return j.id)
	for size in [Vector2i(1280,800),Vector2i(1920,1080)]:
		root.size=size;await process_frame;await process_frame
		g.select_group(0);g.tool="wall";g.refresh();await process_frame
		await click(g.buttons.wall.get_global_rect().get_center(),MOUSE_BUTTON_RIGHT)
		check(g.group==-1 and g.tool=="" and w.jobs.map(func(j):return j.id)==jobs,"Subtask right click clears mode without deleting work at "+str(size))
	root.size=Vector2i(1280,800);await process_frame;await process_frame
	g.select_group(0);g.refresh();await process_frame
	var p=g.buttons.wall.get_global_rect().get_center()
	await mouse(p,MOUSE_BUTTON_LEFT,true)
	var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*(p+Vector2(20,0));motion.relative=Vector2(20,0);Input.parse_input_event(motion);await process_frame
	check(g.subtasks.dragging,"Subtask drag starts above the movement threshold")
	await click(p+Vector2(20,0),MOUSE_BUTTON_RIGHT);await mouse(p+Vector2(20,0),MOUSE_BUTTON_LEFT,false)
	check(not g.subtasks.dragging and g.group==0 and w.jobs.map(func(j):return j.id)==jobs,"Right click during subtask drag cancels only the uncommitted drag")
	g.choose_walk();w.Work.set_drafted(w,"keeper",true);g.refresh();g._process(0)
	check(g.buttons.keeper_rest.disabled and g.buttons.resume_jobs.disabled and g.buttons.keeper_equip.disabled,"Drafted normal work actions remain disabled after process refresh")
	await press(g,"keeper_rest");await press(g,"resume_jobs")
	check(not w.keeper.resting and w.jobs.map(func(j):return j.id)==jobs,"Clicks on disabled drafted actions do not issue work")
	check(not g.buttons.keeper_book.disabled and not g.buttons.inventory.disabled,"Read-only book and inventory remain available while drafted")
	w.calendar_ticks=1100;w.phase="day";g.refresh();g._process(0)
	check(g.buttons.advance.text=="朝まで休む" and g.buttons.advance.disabled and "徴兵" in g.buttons.advance.tooltip_text,"20:16 uses the clock and exposes drafted rest refusal")
	w.Work.set_drafted(w,"keeper",false);w.spawn_schedule=[{"tick":w.tick+20}];w.schedule_index=0;g.refresh();g._process(0)
	check(g.buttons.advance.disabled,"Pending night raid cannot be skipped by UI")
	w.spawn_schedule.clear();w.spawn_enemy({"archetype":"kidnapper","role":"kidnapper","entry":Vector2i(0,10)});var enemy=w.enemies.back();enemy.pos=Vector2i(17,10);g.refresh();g._process(0)
	check(g.buttons.advance.disabled and g.buttons.threats.visible and g.buttons.threats.text=="敵 1体","Living enemy blocks skipping and is exposed at night")
	w.calendar_ticks=1728;w.phase="day";g.refresh();g._process(0)
	check(g.buttons.threats.text=="残る敵 1体" and g.buttons.advance.disabled,"The same enemy remains visibly dangerous next morning")
	var position=w.keeper.pos;var tick=w.tick
	await press(g,"threats")
	check(g.selected.get("kind")=="enemy" and w.keeper.pos==position and w.tick==tick and w.jobs.map(func(j):return j.id)==jobs,"Threat button focuses only; no movement, job or time side effect")
	w.enemies.clear();w.calendar_ticks=50;w.phase="day";w.paused=false;g.neutral()
	await key(KEY_ESCAPE)
	check(g.menu_open and w.paused and not g.menu_was_paused,"Opening the menu suspends an otherwise running world")
	check(not g.buttons.has("menu_day") and not g.buttons.has("menu_morning") and not g.menu.has_node("ControlGuide"),"Main menu has no ambiguous phase reset or full key guide")
	await press(g,"menu_help");check(g.menu_page=="help" and g.menu.has_node("ControlGuide"),"Help is a separate page")
	await key(KEY_ESCAPE);check(g.menu_open and g.menu_page=="main","Escape from help returns to menu without resuming time")
	await press(g,"menu_new");await press(g,"menu_back")
	check(g.world==w and w.tick==tick,"Cancelling the new-game confirmation preserves the current colony")
	g.persistence_enabled=true;g.development_save_path="user://review02.snapshot"
	await press(g,"menu_save")
	var saved=w.Snapshot.restore(g.development_save_path)
	check(saved!=null and not saved.paused and saved.keeper.pos==position and saved.jobs.map(func(j):return j.id)==jobs,"Save captures the pre-menu pause setting, positions and job IDs")
	w.keeper.pos=Vector2i(11,10);w.campaign.gold=1
	await press(g,"menu_load")
	check(g.world.keeper.pos==position and g.world.campaign.gold==40 and g.menu_open and g.world.paused and not g.menu_was_paused,"Load restores state while keeping the modal pause until resume")
	await press(g,"menu_resume");check(not g.menu_open and not g.world.paused,"Menu resume restores saved running state")
	await key(KEY_ESCAPE);await press(g,"menu_new");await press(g,"menu_confirm_new")
	var files=DirAccess.get_files_at("user://history")
	var history=g.world.Snapshot.restore("user://history/"+files[-1]) if not files.is_empty() else null
	check(g.world!=w and g.world.campaign.day==1 and g.world.calendar_ticks==0 and history!=null and history.jobs.map(func(j):return j.id)==jobs,"Confirmed new colony writes a full restoration history before starting day1 at05:00")
	check(g.world.Story.at(g.world).distance_to(Vector2(g.world.W/2,g.world.H/2))<=3 and g.world.distance(g.world.keeper.pos,g.world.Story.at(g.world))<=3,"Confirmed new game uses central keeper and idol")
	g.persistence_enabled=false;g.queue_free();await process_frame
	var f=FileAccess.open(out+"/review02-ui.json",FileAccess.WRITE);f.store_string(JSON.stringify({"method":"Godot InputEvent dispatch at1280x800 and1920x1080 with private user data. Not physical OS input or human play.","checks":checks,"failures":failed},"\t"));f.close()
	print("Review02UI: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
