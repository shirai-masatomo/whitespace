extends "res://tests/test_controls.gd"
const Stroke=preload("res://game/wall_stroke.gd")

func motion(p: Vector2):
	var e=InputEventMouseMotion.new();e.position=p;Input.parse_input_event(e);await process_frame

func button(p: Vector2,pressed: bool,index: int=MOUSE_BUTTON_LEFT):
	var e=InputEventMouseButton.new();e.position=p;e.button_index=index;e.pressed=pressed
	Input.parse_input_event(e);await process_frame

func prepare(seed_value: int=17):
	game.world=Farm.new({},seed_value).begin_day();game.world.paused=true
	game.world.trees.clear();game.world.natural.clear();game.world.field_items.clear()
	game.world.animals.clear();game.world.keeper.pos=Vector2i(4,11)
	game.world.structures.clear();game.world.floors.clear();game.world.materials=500
	game.world.wood=500;game.world.stone=500;game.world.campaign.unlocked_blueprints.append("stone")
	game.reset_view();game.recenter();game.select_group(0);game.select_tool("wall",false)
	game.camera.force_update_scroll();await process_frame

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only isolated or headless verification")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	root.add_child(game);game.set_process(false);await process_frame
	for seed_value in [17,31,73]:
		await prepare(seed_value)
		for kind in Farm.Buildings.WALLS:
			game.world.campaign.unlocked_blueprints.append(Farm.BUILD[kind].get("blueprint",""))
			var stroke=Stroke.new();stroke.begin(kind,Vector2i(5,6));stroke.add(Vector2i(10,6));stroke.add(Vector2i(10,8));stroke.add(Vector2i(5,6))
			check(stroke.cells.size()==stroke.seen.size() and stroke.cells.size()>8,"Fast L stroke and backtrack deduplicate: %s/%d"%[kind,seed_value])
			var before=game.world.resource_amount(Farm.BUILD[kind].get("resource","soil"));var preview=stroke.plan(game.world)
			check(preview.accepted==8 and preview.cost==80 and game.world.jobs.is_empty() and game.world.resource_amount(Farm.BUILD[kind].get("resource","soil"))==before,"Preview observes eight-slot budget without charging")
			var actual=stroke.commit(game.world)
			check(actual.accepted==preview.accepted and game.world.jobs.size()==8 and game.world.resource_amount(Farm.BUILD[kind].get("resource","soil"))==before-80 and game.world.structures.is_empty(),"Release pays once and queues work; structures are not instant")
			for j in game.world.jobs.duplicate():game.world.Jobs.cancel(game.world,j.id)
			check(game.world.resource_amount(Farm.BUILD[kind].get("resource","soil"))==before,"Existing queue cancellation refunds all paid reservations")
	for delta in [Vector2i(6,3),Vector2i(-6,3),Vector2i(-6,-3),Vector2i(6,-3),Vector2i(0,8),Vector2i(8,0)]:
		var path=Stroke.segment(Vector2i(10,10),Vector2i(10,10)+delta);var joined=true
		for i in range(1,path.size()):joined=joined and Farm.distance(path[i-1],path[i])==1
		check(joined and path[-1]==Vector2i(10,10)+delta,"Fast diagonal/horizontal path remains cardinally connected "+str(delta))
	await prepare()
	var start=game.screen_cell(Vector2i(5,7));var end=game.screen_cell(Vector2i(10,7))
	game.world.materials=25
	await motion(start);await button(start,true);await motion(end)
	var preview=game.wall_stroke.plan(game.world)
	check(preview.accepted==2 and preview.skipped==4 and game.world.materials==25 and game.world.jobs.is_empty(),"Mouse-down and motion only preview affordable cells")
	game._process(0);game.queue_redraw();await capture("01_wall_drag_budget")
	await button(end,false)
	check(game.world.jobs.size()==2 and game.world.materials==5 and game.tool=="wall" and game.group==0,"Release queues the displayed affordable walls and retains tool")
	await prepare();game.world.trees[Vector2i(7,7)]={};game.world.act("wall",Vector2i(6,7))
	var stroke=Stroke.new();stroke.begin("wall",Vector2i(5,7));stroke.add(Vector2i(9,7));preview=stroke.plan(game.world)
	check(preview.accepted==3 and preview.skipped==2,"Existing reservation and tree are skipped; later cells still fit")
	stroke.commit(game.world);check(game.world.jobs.size()==4 and game.world.materials==460,"Invalid cells and duplicates are never charged")
	await prepare();await mouse(start)
	check(game.world.jobs.size()==1 and game.world.jobs[0].pos==Vector2i(5,7),"Single wall click remains one ordinary reservation")
	for cancel in ["escape","right_ui","mode","zoom","focus","phase","release_ui"]:
		await prepare();await motion(start);await button(start,true);await motion(end)
		match cancel:
			"escape":await key(KEY_ESCAPE)
			"right_ui":await button(Vector2(650,775),true,MOUSE_BUTTON_RIGHT);await button(Vector2(650,775),false,MOUSE_BUTTON_RIGHT)
			"mode":game.select_group(1)
			"zoom":await mouse(end,MOUSE_BUTTON_WHEEL_UP)
			"focus":game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"phase":game.world.phase="dawn";game.refresh()
			"release_ui":await button(Vector2(650,775),false)
		await button(end,false)
		check(game.world.jobs.is_empty() and game.world.materials==500 and game.wall_stroke.kind=="" and not game.menu_open,"Cancel never leaks a paid click: "+cancel)
	await prepare();game.neutral();var camera_before=game.camera.position
	await motion(start);await button(start,true);await motion(end);await button(end,false)
	check(game.camera.position!=camera_before and game.world.jobs.is_empty(),"Neutral drag retains camera panning")
	await prepare();var ui=game.buttons.group0.get_global_rect().get_center()
	check(game.subtask_choices().all(func(id):return game.buttons[id].get_global_rect().end.y<=game.buttons.group0.get_global_rect().position.y-4),"Construction controls keep a clear gap above the mode bar")
	await motion(ui);await button(ui,true);await motion(end);await button(end,false)
	check(game.world.jobs.is_empty(),"Pressing UI then releasing on the field never draws walls")
	await prepare();game.neutral()
	check(game.buttons.walk.text=="主人公" and game.buttons.walk.position.x<game.buttons.group0.position.x and game.buttons.group0.position.x<game.buttons.group1.position.x,"Displayed modes are keeper, build, orders")
	for expected in [2,0,1,2]:await key(KEY_TAB);check(game.group==expected,"Tab follows visual order including entry from neutral")
	game.toggle_menu();game._process(0);await capture("02_modes_and_help")
	if output!="":
		var file=FileAccess.open(output+"/wall-drag.json",FileAccess.WRITE);file.store_string(JSON.stringify(record,"  "));file.close()
	print("WALL_DRAG: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
