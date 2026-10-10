extends SceneTree
const Farm=preload("res://game/world.gd")
const Model=preload("res://game/colony_view_model.gd")
var game
var failed=0
var output=""
var record={"method":"Paused controlled jobs and injected Godot mouse/key events; one isolated GPU image; no human play","checks":[]}
func _initialize():call_deferred("run")
func check(ok: bool,note: String):
	record.checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func press(button):
	var at=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await process_frame
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func tab():
	for down in [true,false]:
		var e=InputEventKey.new();e.physical_keycode=KEY_TAB;e.keycode=KEY_TAB;e.pressed=down;Input.parse_input_event(e);await process_frame
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true;game.world.paused=true
	root.add_child(game);await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false);game.reset_view();game.neutral()
	var w=game.world;w.natural[Vector2i(6,6)]="stump";w.field_items=[{"kind":"egg","pos":Vector2i(7,6),"born_day":1}]
	check(w.Jobs.enqueue(w,"wall",Vector2i(5,6),-1) and w.Jobs.enqueue(w,"collect",Vector2i(6,6),-1) and w.Jobs.enqueue(w,"collect",Vector2i(7,6),-1),"Fixture reserves real construction, gathering and item jobs")
	w.jobs[0].work_credit=0.5
	var snapshot=w.jobs.duplicate(true);var resources=w.campaign.resources.duplicate(true);var id=w.next_job_id;var tick=w.tick
	check(Model.jobs(w).map(func(row):return row.id)==w.jobs.map(func(j):return j.id) and Model.jobs(w,"採取")[0].execution_index==1 and Model.jobs(w,"回収")[0].execution_index==2,"Category adapters retain global order and job identity")
	game.set_job_category(Model.CATEGORIES.find("採取"));var shown=game.queue_controls.get_children().filter(func(n):return n.has_meta("job_id"))
	check(shown.size()==1 and shown[0].get_meta("job_id")==snapshot[1].id and shown[0].tooltip_text.contains("全体2番目"),"Filtered queue shows the original execution number")
	await press(shown[0]);check(game.queue_drag_id==-1 and w.jobs==snapshot,"Filtered rows cannot accidentally reorder hidden jobs")
	await press(game.buttons.roles)
	check(game.colony_page=="roles" and not game.buttons.walk.visible and Model.people(w).size()==1,"Roles replaces the public keeper tab and displays the existing human")
	await press(game.colony_panel.find_child("Person_keeper",true,false))
	check(game.selected.get("kind")=="keeper" and ["keeper_rest","resume_jobs","keeper_book","inventory"].all(func(key):return game.buttons.has(key) and game.buttons[key].is_visible_in_tree()),"Role selection retains rest, resume, book and inventory routes")
	await press(game.buttons.group1);await press(game.colony_panel.find_child("Animal_1",true,false))
	check(game.selected_animal==1 and game.buttons.has("auto") and game.buttons.has("stay") and not game.buttons.has("tame"),"Animal selection reaches existing commands without an active taming action")
	await press(game.buttons.group0);await press(game.buttons.architect_category_2)
	check(game.architect_category=="床" and game.subtask_choices()==["soil_tile","wood_tile","stone_tile"],"Architect categories connect to existing floor tools")
	game.neutral();await tab();var first=game.group;await tab();var second=game.group;await tab()
	check(first==0 and second==1 and game.colony_page=="roles","Tab cycles Architect, Animals and Roles")
	check(w.jobs==snapshot and w.campaign.resources==resources and w.next_job_id==id and w.tick==tick,"UI navigation preserves job IDs, reservations, progress, execution order and simulation time")
	game.set_job_category(0);game.message_until=-1;game.select_group(0);game.refresh_jobs();game.queue_redraw();game.hud.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/colony-panels.png")
	record.jobs=snapshot;record.resources=resources;record.new_priority_rules=false;record.taming_enabled=false
	FileAccess.open(output+"/colony-panels.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("Colony panels: ",record.checks.size()," checks, ",failed," failures")
	quit(1 if failed else 0)
