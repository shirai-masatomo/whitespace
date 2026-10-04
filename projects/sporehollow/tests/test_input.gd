extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool, why: String):
	checks+=1
	if not value: failures+=1; push_error(why)
func mouse(p: Vector2,button: int=MOUSE_BUTTON_LEFT,ctrl: bool=false):
	var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion)
	await process_frame
	var e=InputEventMouseButton.new();e.position=p;e.button_index=button;e.ctrl_pressed=ctrl;e.pressed=true
	Input.parse_input_event(e);await process_frame
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await process_frame
func site(kind,p):
	var d=Farm.BUILD[kind]
	game.world.Buildings.layer(game.world,kind)[p]={"id":game.world.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.get("resource","soil"),"open":false}
	game.world.next_structure_id+=1
func run():
	check(DisplayServer.get_name()=="headless","Input test must have no OS window")
	print("TEST_DATA_DIR: ",OS.get_user_data_dir())
	check("artifacts/validation/" in OS.get_user_data_dir().replace("\\","/"),"Test user data is isolated from normal play")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},17).begin_day();game.world.paused=true
	root.add_child(game);await process_frame;await process_frame
	game.reset_view();game.refresh();await process_frame
	var p=Vector2i(10,8)
	game.world.field_items.append({"kind":"egg","pos":p,"born_day":1})
	game.select_group(0);game.select_tool("wall",false);await process_frame
	await mouse(game.screen_cell(p))
	check(game.world.jobs.is_empty() and game.tool=="wall","Active construction does not collect egg or drop preview")
	await mouse(game.screen_cell(game.world.animals[0].pos))
	check(game.world.jobs.is_empty() and game.tool=="wall","Occupied construction click keeps construction intent")
	game.neutral();game.world.field_items.clear();site("soil_tile",p);site("wall",p);await process_frame
	await mouse(game.screen_cell(p));check(game.selected.get("kind")=="structure","Stack first selects upper structure")
	check(game.buttons.has("switch_layer"),"Layer switch is near stacked target")
	await mouse(game.buttons.switch_layer.get_global_rect().get_center())
	check(game.selected.get("kind")=="floor" and game.buttons.remove.disabled,"Floor layer and disabled dismantle above structure")
	var count=game.world.jobs.size();await mouse(game.buttons.remove.get_global_rect().get_center())
	check(game.world.jobs.size()==count and game.selected.get("kind")=="floor","Disabled action absorbs click, never selects behind")
	await mouse(game.buttons.switch_layer.get_global_rect().get_center())
	await mouse(game.buttons.remove.get_global_rect().get_center())
	check(game.world.jobs.size()==1 and game.world.jobs[0].target_layer=="structure" and game.world.tick==0,"Action queues upper demolition without advancing paused world")
	game.world.Jobs.cancel(game.world,game.world.jobs[0].id);game.world.structures.erase(p);game.neutral()
	await mouse(game.screen_cell(p));check(game.selected.get("kind")=="floor","Floor-only cell selectable")
	await mouse(game.buttons.remove.get_global_rect().get_center())
	check(game.world.jobs.size()==1 and game.world.jobs[0].target_layer=="floor","Near button queues correct floor ID")
	await mouse(game.screen_cell(p),MOUSE_BUTTON_RIGHT)
	check(game.selected.is_empty() and game.world.jobs.size()==1,"Right click only deselects, retains floor job")
	game.world.Jobs.cancel(game.world,game.world.jobs[0].id)
	for y in range(7,10):
		for x in range(9,13): site("soil_tile",Vector2i(x,y))
	game.selection_layer="floor"
	for y in range(7,10):
		for x in range(9,13): await mouse(game.screen_cell(Vector2i(x,y)),MOUSE_BUTTON_LEFT,true)
	check(game.selected_structures.size()==8,"Ctrl selection capped at eight floors")
	game.world.materials=100
	for x in range(4,9): game.world.act("wall",Vector2i(x,3))
	game.facility_action("remove")
	check(game.world.jobs.size()==8 and game.world.jobs.filter(func(j):return j.kind=="remove_floor").size()==3,"Eight selected floors share only three free queue slots")
	check(game.message=="3件予約・5件未登録","Batch reports reserved and not reserved separately")
	for j in game.world.jobs.duplicate():game.world.Jobs.cancel(game.world,j.id)
	game.neutral();game.drag_start=game.center(Vector2i(9,7))-Vector2(22,18)
	game.pointer=game.get_canvas_transform()*(game.center(Vector2i(12,9))+Vector2(22,18));game.drag_class="floor";game.drag_encounters.clear()
	game.finish_drag();check(game.selected_structures.size()==8,"Rectangle capped at eight, floor layer stays distinct")
	game.select_building(p,"floor");site("wood_tile",p);game.prune_selection()
	check(game.selected.is_empty(),"Replacement ID invalidates old UI selection")
	game.choose_walk();game.world.debug_enabled=true;game.debug_view=true;game.refresh()
	check(game.buttons.debug_lock.disabled,"Lock control disabled with keeper selected")
	game.view_positions["a1"]=Vector2(8,8);game.actor_tracks["a1"]=[Vector2(9,8),Vector2(9,9)]
	game.world.paused=false;game.smooth_actor("a1",Vector2i(9,9),0.1)
	check(game.view_positions.a1.y==8,"Interpolation follows first cardinal leg, no corner cutting")
	game.world.paused=true;var visual=game.view_positions.a1;game.smooth_actor("a1",Vector2i(9,9),1)
	check(game.view_positions.a1==visual,"Pause freezes interpolation")
	game.world.animals[0].facing=-1;game.world.animals[0].mode="rest"
	check(game.dog_facing(game.world.animals[0])==-1,"Rest selection retains last dog facing")
	game.toggle_menu();check(game.menu.get_children().any(func(c):return c is Label and c.text.begins_with("ビルド ")),"ESC menu contains build provenance")
	print("INPUT HEADLESS: ",checks," checks, failures=",failures)
	game.queue_free();await process_frame
	quit(1 if failures else 0)
