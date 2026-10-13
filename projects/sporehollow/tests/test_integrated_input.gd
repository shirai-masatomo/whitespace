extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok: bool,note: String):
	checks.append({"check":note,"passed":ok})
	if not ok:failed+=1;push_error(note)
func mouse(point: Vector2,button: int=MOUSE_BUTTON_LEFT):
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion);await process_frame
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.button_index=button;event.pressed=pressed;root.push_input(event);await process_frame
func drag(first: Vector2,last: Vector2):
	var e=InputEventMouseButton.new();e.position=first;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;root.push_input(e);await process_frame
	var move=InputEventMouseMotion.new();move.position=last;move.relative=last-first;root.push_input(move);await process_frame
	e=e.duplicate();e.position=last;e.pressed=false;root.push_input(e);await process_frame
func at(cell: Vector2i) -> Vector2:return game.get_canvas_transform()*game.center(cell)
func command(kind: String):game.group=4;game.item_commands.select(game,kind);await process_frame
func controls(node: Node) -> Array:
	var result=[]
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():result.append(child)
		result.append_array(controls(child))
	return result
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game);await process_frame;game.set_process(false)
	game.world=Farm.new({},31).begin_day();game.world.paused=true;game.world.story.intro_seen=true;game.world.trees.clear();game.world.natural.clear();game.world.rocks.clear();game.world.jobs.clear();game.reset_view();game.neutral();await process_frame
	var w=game.world;var initial=w.field_items.filter(func(row):return w.Stock.stored(w,row))[0];game.camera.position=game.center(initial.pos);game.camera.force_update_scroll();await process_frame;await mouse(at(initial.pos))
	check(w.jobs.is_empty() and game.buttons.has("collect_selection") and game.buttons.collect_selection.disabled,"Initial stocked material is information-only and cannot create a pointless hauling loop")
	game.neutral();game.camera.position=game.center(Vector2i(22,19));game.camera.force_update_scroll();await process_frame
	var cell=Vector2i(20,20);var first_id=w.Stock.add(w,"wood",4,cell).stock_id;await mouse(at(cell))
	check(game.selected_resources.has(cell) and w.jobs.is_empty(),"Actual ordinary click selects material without scheduling collection")
	check(game.buttons.has("collect_selection"),"Selected material exposes an explicit collection button")
	if game.buttons.has("collect_selection"):await mouse(game.buttons.collect_selection.get_global_rect().get_center())
	check(w.jobs.size()==1,"Only the explicit action schedules collection while paused")
	await mouse(at(cell));check(w.jobs.size()==1,"Selecting the object again does not duplicate the designation")
	game.neutral();await command("forbid");await mouse(at(cell));check(w.Stock.find(w,first_id).get("forbidden",false),"Command single click forbids a real item")
	var count=w.jobs.size();await command("allow");await mouse(at(cell));check(not w.Stock.find(w,first_id).get("forbidden",false) and w.jobs.size()==count,"Allow restores permission without registering another haul")
	var a=Vector2i(22,21);var b=Vector2i(24,21);var id_a=w.Stock.add(w,"wood",4,a).stock_id;var id_b=w.Stock.add(w,"stone",4,b).stock_id
	await command("forbid");await drag(at(a),at(b));check(w.Stock.find(w,id_a).get("forbidden",false) and w.Stock.find(w,id_b).get("forbidden",false),"Rectangle forbid applies to both items")
	await command("allow");await drag(at(a),at(b));check(not w.Stock.find(w,id_a).get("forbidden",false) and not w.Stock.find(w,id_b).get("forbidden",false),"Rectangle allow restores both items without hauling")
	await command("haul");await drag(at(a),at(b));check(w.jobs.size()==3,"Rectangle collection schedules exactly the new two item jobs")
	var before=w.Stock.totals(w);await command("clear");await mouse(at(a));check(w.jobs.size()==2 and w.Stock.totals(w)==before,"Single clear cancels work without removing goods")
	await drag(at(cell),at(b));check(w.jobs.is_empty() and w.Stock.totals(w)==before,"Rectangle clear cancels pending work and keeps goods")
	w.act("wood_tile",Vector2i(18,20));var registered=w.jobs.duplicate(true)
	for mode in [0,1,4]:
		game.select_group(mode);game.colony_page="";game.selected.clear();game.selected_resources.clear();game.selected_animals.clear();game.tool="";game.refresh();await process_frame
		var buttons=controls(game.palette);check(not buttons.is_empty(),"Panel has real input controls: "+str(mode))
		if not buttons.is_empty():await mouse(buttons[0].get_global_rect().get_center(),MOUSE_BUTTON_RIGHT)
		check(game.group==-1 and game.tool=="" and w.jobs==registered,"Right click over panel consumes press/release and preserves confirmed work: "+str(mode))
	game.group=0;game.architect_category="ゾーン";game.refresh();await process_frame
	await mouse(game.buttons.zone_stockpile.get_global_rect().get_center(),MOUSE_BUTTON_RIGHT);check(game.group==-1 and w.jobs==registered,"Right click over zone button returns neutral without cancelling work")
	game.colony_page="roles";game.refresh();await process_frame
	var person=game.colony_panel.find_child("Person_keeper",true,false);var priority=game.colony_panel.find_child("Priority_keeper_haul",true,false)
	check(person!=null and person.icon!=null and priority!=null,"Role table has adopted portrait, name and priority cells")
	var old=w.keeper.work_priorities.haul
	if priority!=null:await mouse(priority.get_global_rect().get_center())
	check(w.keeper.work_priorities.haul==(old+1)%5,"Role cell changes actual worker policy through the GUI input route")
	for resolution in [Vector2i(1280,800),Vector2i(1920,1080)]:
		root.size=resolution;game.group=0;game.colony_page="";game.architect_category="壁と扉";game.refresh();await process_frame
		check(game.colony_panel.get_global_rect().end.x<=410,"Architect keeps center clear at logical viewport "+str(resolution))
		var buttons=controls(game.palette);var overlap=false
		for i in range(buttons.size()):
			for j in range(i+1,buttons.size()):overlap=overlap or buttons[i].get_global_rect().intersects(buttons[j].get_global_rect())
		check(not overlap and buttons.all(func(button):return button.get_global_rect().end.y<=742),"Architect category/tool controls do not overlap or exceed footer: "+str(resolution))
		game.select_group(1);game.selected_animals.clear();game.refresh();await process_frame
		var hp=game.colony_panel.find_child("AnimalHP_1",true,false);var icon=game.colony_panel.find_child("Animal_1",true,false)
		check(hp is ProgressBar and hp.max_value==w.animals[0].max_hp and icon.icon!=null,"Animal table has real HP bar and adopted icon: "+str(resolution))
		var instructions=game.colony_panel.find_child("AnimalInstructions_1",true,false);check(instructions!=null,"Animal list shares the instruction entry, not duplicated orders")
	FileAccess.open(out+"/integrated-input.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Real Godot InputEvent routes and Control layout on headless viewport; no GPU images or OS input claim","checks":checks,"failures":failed},"\t"))
	game.queue_free();await process_frame;print("IntegratedInput: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
