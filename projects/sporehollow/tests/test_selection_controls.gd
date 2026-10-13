extends "res://tests/test_integrated_input.gd"
var captures=[]
func snap(id: String):
	if DisplayServer.get_name()=="headless":return
	game.queue_redraw();game.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var err=root.get_texture().get_image().save_png(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+id+".png")
	check(err==OK,"GPU screenshot saved: "+id)
	captures.append({"file":id+".png","selected":game.selected.duplicate(),"animals":game.selected_animals.duplicate(),"resources":game.selected_resources.duplicate(),"jobs":game.world.jobs.duplicate(true)})
func held_drag(first: Vector2,last: Vector2):
	var m=InputEventMouseMotion.new();m.position=first;root.push_input(m);await process_frame
	var e=InputEventMouseButton.new();e.position=first;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;root.push_input(e);await process_frame
	m=InputEventMouseMotion.new();m.position=last;m.relative=last-first;root.push_input(m);await process_frame
func release(point: Vector2):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;root.push_input(e);await process_frame
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true;game.world.paused=true
	root.add_child(game);await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false)
	var w=game.world;w.trees.clear();w.natural.clear();w.rocks.clear();w.mountains.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.enemies.clear()
	w.keeper.pos=Vector2i(20,20);w.animals[0].pos=Vector2i(21,18)
	var second=w.animals[0].duplicate(true);second.id=2;second.pos=Vector2i(23,18);w.animals.append(second)
	for x in range(20,30):w.Stock.add(w,"wood",8,Vector2i(x,19))
	game.reset_view();game.camera.position=game.center(Vector2i(23,19));game.camera.force_update_scroll();game.neutral();await process_frame
	var origin=game.camera.position
	for paused in [false,true]:
		w.paused=paused;game.neutral();await process_frame
		await held_drag(at(Vector2i(20,17)),at(Vector2i(25,20)))
		check(game.drag_class=="animal","First enclosed classification chooses animals; paused="+str(paused))
		if paused:await snap("01_neutral_drag")
		await release(at(Vector2i(25,20)))
		check(game.selected_animals==[1,2] and game.selected_resources.is_empty() and game.group==-1,"Neutral drag selects only animals and keeps neutral; paused="+str(paused))
		check(not game.animal_list_open and not game.animal_commands_open and w.jobs.is_empty(),"Selection does not open management or issue jobs")
		check(game.camera.position==origin,"Neutral selection does not pan camera")
	game.open_animal_commands(1);check(game.selected_animals==[1,2] and game.animal_commands_open,"Opening instructions preserves the multiselection without issuing commands")
	game.neutral();await held_drag(at(Vector2i(20,19)),at(Vector2i(29,20)));await release(at(Vector2i(29,20)))
	check(game.selected_resources.size()==8 and game.selected_animals.is_empty(),"Resources category and selection limit eight")
	game.neutral();await held_drag(at(Vector2i(20,19)),at(Vector2i(29,18)));await release(at(Vector2i(29,18)))
	check(game.selected_resources.size()==8 and game.selected_animals.is_empty(),"Reversed drag stays in first resource category despite animals")
	var previous=game.selected_resources.duplicate();await held_drag(at(Vector2i(20,17)),at(Vector2i(25,20)))
	await mouse(at(Vector2i(25,20)),MOUSE_BUTTON_RIGHT);await release(at(Vector2i(25,20)))
	check(game.selected_resources==previous and not game.dragging and w.jobs.is_empty(),"Right click cancels only unconfirmed rectangle; original selection/work survive")
	game.neutral();await held_drag(at(Vector2i(28,16)),at(Vector2i(29,17)));await release(at(Vector2i(29,17)))
	check(game.selected.is_empty() and game.selected_resources.is_empty() and game.camera.position==origin,"Empty rectangle does not move or order")
	# Existing facility category and ID records remain usable from neutral.
	for p in [Vector2i(21,17),Vector2i(22,17)]:w.floors[p]={"id":p.x,"kind":"soil_tile","status":"ready","hp":20,"max_hp":20,"resource":"soil","cost":1}
	await held_drag(at(Vector2i(20,16)),at(Vector2i(23,17))+Vector2(0,8));await release(at(Vector2i(23,17))+Vector2(0,8))
	check(game.selected_structures.size()==2 and game.selection_layer=="floor" and game.buttons.has("remove"),"Neutral floor selection keeps target-layer dismantle menu")
	game.neutral();w.trees[Vector2i(27,17)]={};w.trees[Vector2i(28,17)]={}
	await held_drag(at(Vector2i(26,16)),at(Vector2i(29,17))+Vector2(0,8));await release(at(Vector2i(29,17))+Vector2(0,8))
	check(game.selected_trees.size()==2 and game.buttons.has("clear_tree"),"Neutral trees use existing forestry actions")
	w.trees.clear();game.neutral();w.field_items.clear();w.floors.clear()
	w.spawn_enemy({"role":"salaryman","entry":w.entries[0],"debug_single":true});var e=w.enemies.back();e.pos=Vector2i(24,19)
	w.Work.set_drafted(w,"keeper",true);game.choose_walk();await process_frame
	for paused in [false,true]:
		w.paused=paused;await mouse(at(e.pos))
		check(game.selected.get("kind")=="enemy" and game.selected.id==e.id and w.jobs.is_empty(),"Enemy click selects without attack; paused="+str(paused))
		check(game.buttons.has("target_attack") and not game.buttons.target_attack.disabled,"Target menu offers explicit attack")
	await snap("02_target_selected")
	var before_tick=w.tick;var before_pos=w.keeper.pos
	await mouse(game.buttons.target_attack.get_global_rect().get_center())
	check(w.jobs.size()==1 and w.jobs[0].kind=="direct_attack" and w.jobs[0].enemy_id==e.id,"Explicit Attack click designates selected enemy exactly once")
	check(w.tick==before_tick and w.keeper.pos==before_pos,"Paused confirmation never moves or advances time")
	await snap("03_attack_confirmed")
	var attack_id=w.jobs[0].id;await mouse(at(Vector2i(27,20)),MOUSE_BUTTON_RIGHT)
	check(game.selected.is_empty() and w.jobs.size()==1 and w.jobs[0].id==attack_id,"Right click clears target only, retains confirmed attack")
	w.spawn_enemy({"role":"salaryman","entry":w.entries[1],"debug_single":true});var other=w.enemies.back();other.pos=Vector2i(26,19)
	await mouse(at(other.pos));check(game.selected.get("id")==other.id and w.jobs[0].enemy_id==e.id,"Selecting another target does not replace the confirmed order")
	await mouse(game.buttons.target_attack.get_global_rect().get_center());check(w.jobs.size()==1 and w.jobs[0].enemy_id==other.id,"Explicit new attack replaces only existing direct command")
	var stale=game.selected.duplicate();other.hp=0;game.target_action("attack",stale)
	check(w.jobs.size()==1,"Dead target rejects confirmation without creating another order")
	w.Jobs.cancel(w,w.jobs[0].id);w.Work.set_drafted(w,"keeper",false);game.select_target("enemy",e.id);await process_frame
	check(game.buttons.target_attack.disabled,"Attack unavailable while not drafted")
	await mouse(game.buttons.target_attack.get_global_rect().get_center());check(w.jobs.is_empty() and game.selected.get("id")==e.id,"Disabled action consumes click without ordering or selecting the ground")
	w.Work.set_drafted(w,"keeper",true);game.select_target("enemy",e.id);await process_frame;await mouse(game.buttons.target_attack.get_global_rect().get_center())
	w.paused=false;e.pos=w.keeper.pos+Vector2i.RIGHT;var hp=e.hp
	for i in range(12):w.step()
	check(e.hp<hp,"Confirmed attack executes existing combat after resuming")
	game.neutral();var zoom=game.camera.zoom.x;await mouse(at(Vector2i(23,17)),MOUSE_BUTTON_WHEEL_UP)
	check(game.camera.zoom.x>zoom and game.group==-1,"Neutral wheel remains zoom")
	w.paused=true;origin=game.camera.position;game.keys_down={KEY_D:true};game._process(0.1);game.keys_down.clear()
	check(game.camera.position.x>origin.x,"WASD remains available for map movement")
	var record={"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"Godot InputEvent through real controls; isolated fixture seed31, explicit positions, headless or isolated GPU; no OS input","checks":checks,"failures":failed,"captures":captures}
	FileAccess.open(out+"/ui-survey.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	FileAccess.open(out+"/selection-controls.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	game.queue_free();await process_frame;print("SelectionControls: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
