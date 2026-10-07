extends "res://tests/test_controls.gd"
func press(id: String):
	check(game.buttons.has(id),"Button: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
func drag_board(start: Vector2,end: Vector2):
	var e=InputEventMouseButton.new();e.position=start;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true
	Input.parse_input_event(e);await process_frame
	var motion=InputEventMouseMotion.new();motion.position=end;Input.parse_input_event(motion);await process_frame
	e=e.duplicate();e.position=end;e.pressed=false;Input.parse_input_event(e);await process_frame
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Safe rendering only")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},17)
	root.add_child(game);await process_frame;game.story_modal="";game.arrival_started=-10;game.refresh()
	await capture("01_morning")
	await press("open_market");await capture("02_merchant")
	await press("shop_buy");await capture("03_categories")
	await press("category_animals");await capture("04_animals")
	check(game.MarketView.texture_for("collar")!=null and game.Assets.texture("doberman")!=null,"Formal delivered UI images resolve")
	await mouse(Vector2(690,400),MOUSE_BUTTON_RIGHT);check(game.shop_level=="categories","Market right click goes one level back")
	await press("close_market");await press("open_book");await create_timer(0.65).timeout
	check(game.training_id==-1 and game.buttons.has("book_entry_1"),"Book opens to grid, not detail")
	await capture("05_book_grid")
	await press("book_entry_1");await create_timer(0.5).timeout
	check(game.training_id==1 and game.buttons.has("skill_rescue"),"Detail preserves selected individual and skill tooltip")
	check("屋内" in game.buttons.skill_rescue.tooltip_text or "救出" in game.buttons.skill_rescue.tooltip_text,"Skill tooltip describes implemented effect")
	await capture("06_shiba_detail")
	await press("book_list");await create_timer(0.5).timeout;await press("book_enemies")
	check(game.training_id==-1 and game.buttons.has("book_entry_0"),"Enemy section has unknown grid")
	await press("book_entry_0");await create_timer(0.5).timeout
	check(game.training_id==0,"Unknown enemy detail safe")
	await mouse(Vector2(700,400),MOUSE_BUTTON_RIGHT);await create_timer(0.65).timeout
	check(game.morning_screen=="morning" and game.world.tick==0,"UI animation never advances morning world")
	game.world=game.world.begin_day();game.world.paused=true;game.reset_view();game.refresh();await process_frame
	game.neutral();await key(KEY_TAB);check(game.group==0 and game.tool=="","Tab neutral to construction without action")
	await key(KEY_SHIFT);check(game.tool!="" and game.world.jobs.is_empty(),"Shift selects only")
	await key(KEY_TAB);check(game.group==1 and game.selected_animals.is_empty(),"Tab command mode only")
	await key(KEY_SHIFT);check(game.selected_animal==1 and game.world.jobs.is_empty(),"First command Shift selects nearby animal only")
	await key(KEY_SHIFT);check(game.tool!="" and game.world.jobs.is_empty(),"Next Shift selects action only")
	await key(KEY_TAB);check(game.group==2 and game.selected.get("kind")=="keeper","Tab keeper and tab highlight sync")
	var zoom=game.camera.zoom.x
	await mouse(Vector2(640,400),MOUSE_BUTTON_WHEEL_UP)
	check(game.camera.zoom.x>zoom and game.group==2,"Wheel zooms without mode change")
	await mouse(Vector2(640,400),MOUSE_BUTTON_WHEEL_DOWN)
	game.reset_view();game.choose_walk();game.refresh();await process_frame
	var start=game.world.keeper.pos;var a=Vector2i(10,11);var b=Vector2i(16,11)
	for p in [a,b]:game.world.natural.erase(p)
	game.world.field_items=game.world.field_items.filter(func(item):return item.pos not in [a,b])
	site("soil_tile",a)
	await mouse(game.screen_cell(a));await mouse(game.screen_cell(b))
	check(game.world.jobs.size()==2 and game.world.jobs.all(func(j):return j.kind=="move"),"Keeper clicks enqueue normal FIFO move jobs")
	check(game.world.manual_goal==null and not game.world.jobs_held and game.world.keeper.pos==start,"Paused move plans neither move nor hold world")
	var id=game.world.jobs[0].id
	var motion=InputEventMouseMotion.new();motion.position=game.screen_cell(a);Input.parse_input_event(motion);await process_frame
	check(game.hover_job==id,"Hover has fixed move JobID")
	await capture("10_plans_tooltip")
	await mouse(game.screen_cell(a),MOUSE_BUTTON_RIGHT)
	check(game.world.jobs.size()==1 and game.world.jobs[0].pos==b and game.group==2,"Right click cancels only hovered plan; no selection change")
	game.world.paused=false
	for i in range(100):
		game.world.step()
		if game.world.jobs.is_empty():break
	check(game.world.keeper.pos==b and game.world.jobs.is_empty(),"Remaining move executes physically")
	game.world.paused=true;game.refresh();await mouse(game.screen_cell(Vector2i(8,9)),MOUSE_BUTTON_RIGHT)
	check(game.group==-1,"Other right click clears selection")
	var camera_start=game.camera.position
	await drag_board(Vector2(550,350),Vector2(620,390))
	check(game.camera.position!=camera_start and game.selected_animals.is_empty(),"Neutral drag pans without selection")
	for mode in [0,1,2]:
		game.select_group(mode)
		var classes=game.selection_candidates().map(func(c):return c["class"])
		check(classes.all(func(c):return c in (["structure","floor"] if mode==0 else (["animal"] if mode==1 else ["resource"]))),"Mode filtered drag candidates "+str(mode))
	game.reset_view();game.neutral();game.camera.zoom=Vector2(0.65,0.65);game.clamp_camera();await capture("07_forest_overview")
	check(game.world.trees.keys().all(func(p):return not(p.x>3 and p.x<21 and p.y>3 and p.y<13)),"Central clearing contains no trees")
	if not game.world.trees.is_empty():
		var p=game.world.trees.keys()[0]
		check(not game.world.walkable(p) and not game.world.animal_walkable(game.world.animals[0],p),"Trunk blocks keeper and animal")
		check(not game.world.act("clear_tree",p) and game.world.Story.reason(game.world,"clear_tree",p).contains("道具"),"No bare-hand felling job")
	game.world.start_night();game.world.paused=true
	game.world.spawn_enemy({"entry":Vector2i(1,8),"role":"kidnapper"})
	var e=game.world.enemies.back();var original=e.pos
	check(e.pos.x< -20,"Enemy begins beyond zoomed-out viewport")
	for i in range(100):
		var previous=e.pos;game.world.enemy_step(e)
		check(Farm.distance(previous,e.pos)<=1,"Entrance has no teleport")
		if e.pos.x>=-3:break
	check(e.pos!=original,"Enemy walks through nonplay entrance lane")
	game.record_actor_tracks();await capture("08_forest_entry")
	game.reset_view();game.world.keeper.pos=Vector2i(7,8)
	var dog=game.world.animals[0];dog.pos=Vector2i(8,8);e.pos=Vector2i(9,8)
	dog.ultimate_gauge=95;game.world.Combat.hit(game.world,dog,e,"attack",1)
	e.stamina=35;game.world.keeper.stamina=45
	game.record_actor_tracks();game.choose_animal(dog.id);game.refresh()
	await capture("09_combat_ready")
	record.combat={"fixture":true,"dog_gauge":dog.ultimate_gauge,"enemy_stamina":e.stamina,"keeper_stamina":game.world.keeper.stamina}
	check(game.world.Story.idol_cells(game.world).size()==4,"Idol remains 2x2")
	if output!="":
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
		FileAccess.open(output+"/ui-revision.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("UI REVISION: %d checks failures=%d"%[checks,failures]);quit(1 if failures else 0)

func capture(name_value: String):
	if OS.get_environment("FARM_REVIEW_PREVIEW")=="1" and name_value not in ["01_morning","02_merchant","06_shiba_detail"]:return
	await super.capture(name_value)
