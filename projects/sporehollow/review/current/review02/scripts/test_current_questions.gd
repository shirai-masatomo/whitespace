extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func click(p,button):
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=root.get_final_transform()*p;e.button_index=button;e.pressed=down;Input.parse_input_event(e);await process_frame
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.paused=true
	var idol=w.Story.at(w)
	check(abs(idol.x-w.W/2)<=3 and abs(idol.y-w.H/2)<=3,"New game idol is near map center")
	check(w.distance(w.keeper.pos,idol)<=3,"New game keeper is beside the central idol")
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.set_process(false)
	var view=g.get_canvas_transform()*((g.center(w.keeper.pos)+(Vector2(idol)+Vector2.ONE)*g.TILE)*0.5)
	check(view.distance_to(Vector2(640,400))<10,"Initial camera centers the keeper and idol together")
	w.enemies.clear();w.spawn_schedule.clear();w.trees.clear();w.natural.clear();w.structures.clear();w.floors.clear();w.field_items.clear()
	w.Stock.add(w,"soil",40,Vector2i(18,16));w.act("wall",Vector2i(20,16))
	var ids=w.jobs.map(func(j):return j.id);var keeper=w.keeper.pos;var tick=w.tick
	for mode in [0,4]:
		g.select_group(mode);g.refresh();await process_frame
		var targets=g.subtask_choices() if mode==0 else ["command_haul"]
		var found=false
		for id in targets:
			if g.buttons.has(id) and g.buttons[id].is_visible_in_tree():
				await click(g.buttons[id].get_global_rect().get_center(),MOUSE_BUTTON_RIGHT);found=true;break
		check(found and g.group==-1 and g.tool=="" and g.selected.is_empty(),"Right click on a displayed subtask clears selection in mode "+str(mode))
		check(w.jobs.map(func(j):return j.id)==ids and w.tick==tick and w.keeper.pos==keeper,"Right click preserves registered jobs, keeper and pause in mode "+str(mode))
	g.queue_free();await process_frame
	var f=FileAccess.open(out+"/questions.json",FileAccess.WRITE);f.store_string(JSON.stringify({"method":"Production Godot InputEvent dispatch; no physical OS input","checks":checks,"failures":failed},"\t"));f.close()
	print("CurrentQuestions: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
