extends "res://tests/test_market_reference_ui.gd"
func extras():
	await press("close_market");await press("open_market");await press("shop_buy");await press("category_animals")
	var gold=game.world.campaign.gold;var count=game.world.campaign.animals.size()
	await press("trade_hen_-1");await press("confirm_trade")
	check(game.world.campaign.gold==gold-30 and game.world.campaign.animals.size()==count+1,"Confirm performs existing price and transaction once")
	await press("close_market");await press("open_book");await settle()
	await press("book_entry_1");await settle()
	for id in game.buttons:
		if id.begins_with("skill_"):
			check(game.buttons[id].text=="" and game.buttons[id].size.x>=80,"Readable icon without overlaid text: "+id)
	await capture("05_book_skill_icons")
	await mouse(Vector2(800,300),MOUSE_BUTTON_RIGHT);await settle()
	check(game.morning_screen=="morning","Book right-click closes safely")
	check(not game.buttons.has("diary") and not game.buttons.has("intro_again"),"Morning removes buttons only")
	check(game.buttons.advance.position.x>980 and game.buttons.advance.position.y>650,"Preparation control in lower right")
	await press("advance");await settle()
	check(game.world.phase=="day","Preparation still starts daytime")
	game.world.paused=true;game.select_group(0);game.refresh();await process_frame
	var jobs=game.world.jobs.size();var tick=game.world.tick
	await mouse(Vector2(810,490),MOUSE_BUTTON_WHEEL_DOWN)
	check(game.group==0 and game.tool!="" and game.world.jobs.size()==jobs,"Wheel selects construction subtask without issuing job")
	var tool=game.tool;await key(KEY_SHIFT)
	check(game.tool==tool and game.group==0,"Shift never cycles construction subtasks")
	game.select_group(1);game.refresh();await key(KEY_SHIFT)
	check(game.selected_animals.size()==1 and game.group==1,"Shift selects an active animal in command mode")
	await mouse(Vector2(810,490),MOUSE_BUTTON_WHEEL_DOWN)
	check(game.tool!="" and game.world.jobs.size()==jobs,"Command wheel selects only, never issues order")
	var selected=game.selected_animals.duplicate();tool=game.tool
	for i in range(12):game.world.PlayerEvents.add(game.world,"検証ログ %d"%i)
	game.hud.queue_redraw();await process_frame;await process_frame
	await mouse(game.event_log_rect.get_center(),MOUSE_BUTTON_WHEEL_UP)
	check(game.event_scroll==1 and game.selected_animals==selected and game.tool==tool,"Log wheel consumes input and reveals history")
	var zoom=game.camera.zoom
	await mouse(Vector2(810,490),MOUSE_BUTTON_WHEEL_UP,true)
	check(game.camera.zoom!=zoom and game.tool==tool,"Ctrl-wheel changes only zoom")
	check(game.world.tick==tick,"Paused UI actions advance no world time")
	var w=load("res://tests/review_enemy_feedback_fixture.gd").create("keeper_hidden")
	game.world=w;w.story.investigated=true;w.start_night();w.spawn_schedule.clear();w.paused=true
	for e in w.enemies:e.hp-=1
	game.reset_view();game.select_group(2);game.selected={};game.group=-1;game.refresh();game._process(0);game.queue_redraw();game.hud.queue_redraw();await process_frame
	await capture("06_enemy_hp_and_statue")
