extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var checks=0
var failures=0
var output=""
var capture_serial=0
var record={"checks":[],"captures":[],"events":[]}
func _initialize(): call_deferred("run")
func check(ok: bool, why: String):
	checks+=1
	record.checks.append({"check":why,"passed":ok})
	if not ok: failures+=1;push_error(why)
func mouse(p: Vector2,button: int=MOUSE_BUTTON_LEFT,ctrl: bool=false):
	record.events.append({"mouse":[p.x,p.y],"button":button,"ctrl":ctrl,"tick":game.world.tick})
	var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion);await process_frame
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=p;event.button_index=button;event.pressed=pressed;event.ctrl_pressed=ctrl
		Input.parse_input_event(event);await process_frame
func key(code: int,shift: bool=false,echo: bool=false):
	record.events.append({"key":code,"shift":shift,"echo":echo,"tick":game.world.tick})
	var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.shift_pressed=shift;e.pressed=true;e.echo=echo
	Input.parse_input_event(e);await process_frame
	e=e.duplicate();e.pressed=false;e.echo=false;Input.parse_input_event(e);await process_frame
func capture(name: String):
	if output=="": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
	record.captures.append({"file":name+".png","group":game.group,"tool":game.tool,"book":game.book_motion,"animal_id":game.training_id,"tick":game.world.tick,"jobs":game.world.jobs.duplicate(true)})
func movie(prefix: String,seconds: float):
	var elapsed=0.0;var index=0
	while elapsed<seconds:
		await create_timer(0.06).timeout
		await capture(prefix+"_%02d"%index)
		elapsed+=0.06;index+=1
func drag_button(id: String,target: Vector2,cancel=false):
	var start=game.buttons[id].get_global_rect().get_center()
	var e=InputEventMouseButton.new();e.position=start;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true
	Input.parse_input_event(e);await process_frame
	var motion=InputEventMouseMotion.new();motion.position=target;Input.parse_input_event(motion);await process_frame
	await capture("subtask_drag_"+id+"_%d"%capture_serial)
	capture_serial+=1
	if cancel: await key(KEY_ESCAPE)
	e=e.duplicate();e.position=target;e.pressed=false;Input.parse_input_event(e);await process_frame
func site(kind: String,p: Vector2i):
	var d=Farm.BUILD[kind]
	game.world.Buildings.layer(game.world,kind)[p]={"id":game.world.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.get("resource","soil"),"open":false,"lock_hp":12}
	game.world.next_structure_id+=1
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only headless or isolated station")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},17).begin_day();game.world.paused=true
	root.add_child(game);await process_frame;await process_frame
	game.subtasks.order={0:[],1:[],2:[]};game.reset_view();game.refresh()
	await key(KEY_TAB);check(game.group==0,"Neutral Tab enters build")
	for point in [Vector2(700,20),Vector2(700,775),Vector2(1240,440),Vector2(8,430),Vector2(700,430),Vector2(1018,200)]:
		game.neutral();game.camera.zoom=Vector2.ONE
		await mouse(point,MOUSE_BUTTON_WHEEL_DOWN)
		check(game.group==-1 and game.camera.zoom.x<1,"Wheel zooms at "+str(point))
		await key(KEY_TAB);check(game.group==0,"Tab build")
		await key(KEY_TAB);check(game.group==1 and game.selected_animals.is_empty(),"Tab orders only")
		await key(KEY_TAB);check(game.group==2,"Tab keeper")
		await key(KEY_TAB);check(game.group==0,"Tab skips neutral")
	game.recenter()
	game.select_group(0);var before=game.world.jobs.size()
	await key(KEY_SHIFT);check(game.tool=="wall","Build first Shift selects first operation")
	for i in range(7):await key(KEY_SHIFT)
	check(game.tool=="locked_door","Shift cycles available construction")
	await key(KEY_SHIFT,false,true);check(game.tool=="locked_door","Shift key repeat ignored")
	await drag_button("locked_door",game.buttons.wall.get_global_rect().get_center())
	check(game.subtask_choices()[0]=="locked_door" and game.tool=="locked_door","Reorder keeps selected operation ID")
	game.tool="";await key(KEY_SHIFT);check(game.tool=="locked_door","Shift follows reordered display")
	game.refresh();game.select_group(1);await key(KEY_SHIFT)
	check(game.selected_animal==1 and game.tool=="","First command Shift selects resident only")
	await key(KEY_SHIFT);check(game.tool=="guide","Next Shift selects guide without issuing")
	await drag_button("rest",game.buttons.guide.get_global_rect().get_center())
	check(game.subtask_choices()[0]=="rest","Command button order independent of build order")
	game.tool="";await key(KEY_SHIFT);check(game.tool=="rest","Shift uses changed order")
	var order=game.subtask_choices().duplicate();await drag_button("rest",Vector2(700,450))
	check(game.subtask_choices()==order,"Out-of-range drop restores order")
	await drag_button("rest",game.buttons.auto.get_global_rect().get_center(),true)
	check(game.subtask_choices()==order and game.group==1,"Escape cancels just subtask drag")
	check(game.world.jobs.size()==before and game.world.tick==0,"Shift and reordering never execute or advance paused world")
	await capture("commands_reordered")
	var orders=game.subtasks.order.duplicate(true);game.select_group(0);game.refresh()
	check(game.subtasks.order[0]==orders[0] and game.subtasks.order[1]==orders[1],"Mode/refresh preserves order")
	var saved=load("res://game/subtasks.gd").new();saved.load_settings()
	check(saved.order[1]==orders[1],"UI-only order saves and restores")
	game.world.debug_enabled=true;game.world.debug_action("cat",{});game.world.debug_action("hen",{})
	var cat=game.world.animals.filter(func(a):return a.species=="cat")[0]
	var hen=game.world.animals.filter(func(a):return a.species=="hen")[0]
	game.choose_animal(cat.id);await key(KEY_SHIFT);check(game.tool=="equip" and game.group==1 and game.world.jobs.is_empty(),"Cat Shift selects equipment only, never animal command")
	game.choose_animal(hen.id);await key(KEY_SHIFT);check(game.tool=="guide" and game.subtask_choices()==["guide","equip"],"Hen guides or receives equipment, no dog commands")
	game.choose_animal(1);game.choose_animal(hen.id,true);await key(KEY_SHIFT)
	check(game.world.jobs.is_empty(),"Mixed species selection and Shift do not issue")
	game.world.animals[0].unavailable_through_day=99
	game.select_group(1);await key(KEY_SHIFT);check(game.selected_animal==hen.id,"Nearest eligible resident excludes recuperating dog")
	game.world.animals.clear();game.select_group(1);await key(KEY_SHIFT)
	check(game.group==1 and game.selected_animals.is_empty(),"No animals keeps command mode")
	game.world=Farm.new({},17);game.world.campaign.gold=300;game.reset_view();game.arrival_started=game.clock-5;game.refresh()
	game.world.debug_enabled=true;game.world.debug_action("hen",{});game.world.debug_action("cat",{})
	await capture("morning")
	await mouse(game.buttons.open_market.get_global_rect().get_center());await capture("market_home")
	check(game.buttons.has("shop_buy") and game.buttons.has("shop_sell"),"Market root has buy/sell")
	var back=game.buttons.shop_back.get_global_rect()
	await mouse(game.buttons.shop_buy.get_global_rect().get_center());await capture("market_categories")
	check(not game.buttons.has("market_buy") and not game.buttons.has("shop_buy"),"No duplicate trade choice in category")
	await mouse(game.buttons.category_materials.get_global_rect().get_center());await capture("market_list")
	var trade=game.buttons.keys().filter(func(id):return id.begins_with("trade_"))[0]
	await mouse(game.buttons[trade].get_global_rect().get_center());await capture("market_detail")
	check(game.buttons.shop_back.get_global_rect()==back,"Back is fixed across levels")
	var before_trade=game.world.campaign.gold
	await mouse(game.buttons.confirm_trade.get_global_rect().get_center())
	check(game.world.campaign.gold<before_trade,"Explicit purchase alone trades")
	var gold=game.world.campaign.gold
	for level in ["list","categories"]:
		await mouse(Vector2(600,500),MOUSE_BUTTON_RIGHT);check(game.shop_level==level,"Right click one level to "+level)
	await mouse(Vector2(600,500),MOUSE_BUTTON_RIGHT);check(game.shop_side=="home","Category returns to trade entry")
	await mouse(Vector2(600,500),MOUSE_BUTTON_RIGHT);check(game.morning_screen=="morning" and game.world.phase=="shop","Root returns to morning only")
	check(game.world.campaign.gold==gold,"Back never trades")
	game.open_market();await mouse(game.buttons.shop_sell.get_global_rect().get_center())
	await mouse(game.buttons.category_materials.get_global_rect().get_center())
	check(game.shop_side=="sell" and not game.buttons.has("market_buy"),"Selling has separate hierarchy")
	await mouse(game.buttons.close_market.get_global_rect().get_center())
	check(game.morning_screen=="morning" and game.world.phase=="shop","Menu button never starts day")
	await mouse(game.buttons.open_book.get_global_rect().get_center())
	check(game.book_motion=="opening","Book opens from closed state")
	await movie("book_open",0.65);await capture("book_opened")
	check(game.book_motion=="" and game.morning_screen=="book","Opening completes with world paused")
	await mouse(game.buttons.book_entry_1.get_global_rect().get_center());await create_timer(0.5).timeout
	var id=game.training_id;var tick=game.world.tick
	await mouse(game.buttons.book_next.get_global_rect().get_center());await movie("book_next",0.5)
	check(game.training_id!=id,"Page commits correct next animal")
	await mouse(game.buttons.book_prev.get_global_rect().get_center());await movie("book_previous",0.5)
	check(game.training_id==id and game.world.tick==tick,"Previous returns ID without world time")
	await mouse(game.buttons.rename.get_global_rect().get_center());await process_frame
	var book_id=game.training_id;var rate=game.speed
	await key(KEY_TAB);await key(KEY_KP_ADD);check(game.training_id==book_id and game.speed==rate,"Naming Tab and plus do not affect board")
	game.name_edit.release_focus();game.rename_open=false;game.refresh()
	await mouse(Vector2(600,500),MOUSE_BUTTON_RIGHT);await movie("book_close",0.65)
	check(game.morning_screen=="morning","Book right-click closes to morning")
	await mouse(game.buttons.open_book.get_global_rect().get_center());await key(KEY_ESCAPE);await create_timer(0.65).timeout
	check(game.morning_screen=="morning" and game.book_motion=="","Opening interrupted safely")
	game.world.campaign.animals=game.world.campaign.animals.slice(0,1)
	game.open_book();await create_timer(0.65).timeout
	check(game.buttons.book_next.disabled and game.buttons.book_prev.disabled,"Single animal page controls disabled")
	game.close_morning_screen();await create_timer(0.65).timeout
	game.world.campaign.animals.clear();game.open_book();await create_timer(0.65).timeout
	check(game.training_id==-1 and game.buttons.book_next.disabled,"Empty book is safe and cannot turn")
	game.close_morning_screen();await create_timer(0.65).timeout
	game.world=Farm.new({},17).begin_day();game.world.paused=true;game.world.natural.clear();game.reset_view();game.refresh()
	var patterns=[[Vector2i(0,0)],[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0)],[Vector2i(0,-1),Vector2i(0,0),Vector2i(0,1)],[Vector2i(0,-1),Vector2i(0,0),Vector2i(1,0)],[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],[Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]]
	for i in range(patterns.size()):
		for offset in patterns[i]: site(["wall","wood_wall","stone_wall"][i%3],Vector2i(4+(i%3)*5,5+(i/3)*5)+offset)
	site("door",Vector2i(5,10));site("wood_wall",Vector2i(6,10))
	game.recenter();await capture("wall_connections")
	game.world.structures[Vector2i(5,10)].open=true;game.gate_views[game.world.structures[Vector2i(5,10)].id]=1.0;await capture("wall_door_open")
	game.world.structures.erase(Vector2i(9,4));await capture("wall_removed")
	game.world.structures.clear()
	for rotation in range(4):
		for pattern in range(2):
			var origin=Vector2i(5+rotation*5,5+pattern*5)
			var offsets=[Vector2i.ZERO,Vector2i.UP,Vector2i.RIGHT]+([Vector2i.LEFT] if pattern==1 else [])
			for offset in offsets:
				for turn in range(rotation):offset=Vector2i(-offset.y,offset.x)
				site(["wall","wood_wall","stone_wall"][(rotation+pattern)%3],origin+offset)
	await capture("wall_corners_and_tees")
	game.world.structures.clear()
	for y in [5,6,8,9]:site("stone_wall",Vector2i(10,y))
	site("locked_door",Vector2i(10,7));site("wall",Vector2i(11,9));site("wood_wall",Vector2i(12,9))
	game.world.keeper.pos=Vector2i(11,8);game.world.animals[0].pos=Vector2i(12,10)
	await capture("wall_vertical_door_depth")
	game.world.structures[Vector2i(10,7)].open=true;game.gate_views[game.world.structures[Vector2i(10,7)].id]=1.0
	await capture("wall_vertical_door_open")
	check(not game.world.structures.values().any(func(b):return b.kind in ["kennel","coop"]),"No active huts")
	game.choose_walk();await key(KEY_TAB);check(not game.world.keeper.resting,"Keeper Tab never rests")
	for code in [KEY_EQUAL,KEY_PLUS,KEY_KP_ADD]:
		game.speed=0.5;await key(code);check(game.speed==1,"Speed-up key "+str(code))
	for code in [KEY_MINUS,KEY_KP_SUBTRACT]:
		game.speed=1;await key(code);check(game.speed==0.5,"Speed-down key "+str(code))
	if output!="":
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
		record.asset_commit=JSON.parse_string(FileAccess.get_file_as_string("res://game/art_provenance.json")).latest_delivery_commit
		record.dirty=OS.get_environment("FARM_REVIEW_DIRTY")
		FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("CONTROLS: ",checks," checks failures=",failures)
	quit(1 if failures else 0)
