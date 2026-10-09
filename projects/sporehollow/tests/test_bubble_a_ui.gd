extends "res://tests/test_market_reference_ui.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	game.world.story.intro_seen=true
	root.add_child(game);await process_frame;await process_frame
	game.arrival_started=game.clock-5;game.refresh();game._process(0);game.set_process(false)
	var tick=game.world.tick;var gold=game.world.campaign.gold
	check(game.StoryView.morning_layout(game).paper.encloses(game.buttons.advance.get_global_rect()),"Preparation button inside morning paper")
	check(game.buttons.open_book.get_theme_stylebox("normal").bg_color==Color("dc934b"),"Book uses orange action style")
	for value in ["いらっしゃい、何か見ていくかい？","いらっしゃい","持ち物を見せてね","長い台詞でも、文字の行数に合わせて高さと余白を確保します。"]:
		var layout=game.MarketView.speech_layout(game,Rect2(0,0,204,67),value,18)
		check(layout.body.size.y>=layout.paragraph.get_size().y+28,"Text padding: "+value)
	check(game.MarketView.SPEECH_A.get_size()==Vector2(2172,724),"Original A RGBA loaded")
	game.hud.queue_redraw();game.queue_redraw();await capture("01_morning_bubble_a")
	await press("open_market");game.hud.queue_redraw();game.queue_redraw();await capture("02_merchant_greeting_a")
	await press("shop_buy");game.hud.queue_redraw();game.queue_redraw();await capture("03_short_greeting_a")
	check(game.world.tick==tick and game.world.campaign.gold==gold,"Presentation does not mutate time or money")
	await press("close_market");await press("advance");await settle()
	game.world.paused=true;game.select_group(-1);game.refresh()
	var z=game.camera.zoom.x;tick=game.world.tick
	await mouse(Vector2(700,380),MOUSE_BUTTON_WHEEL_UP)
	check(game.camera.zoom.x>z and game.group==-1,"Neutral wheel zooms without mode change")
	await mouse(Vector2(700,380),MOUSE_BUTTON_WHEEL_DOWN)
	check(is_equal_approx(game.camera.zoom.x,z) and game.world.tick==tick,"Neutral reverse zoom while paused")
	game.select_group(0);game.refresh();z=game.camera.zoom.x
	await mouse(Vector2(700,380),MOUSE_BUTTON_WHEEL_DOWN)
	check(game.camera.zoom.x==z and game.tool!="","Selected mode retains subtask wheel")
	game.world.structures.clear();game.world.floors.clear();game.world.natural.clear();game.world.story.idol={}
	for x in range(10,15):
		for y in range(7,12):
			var cell=Vector2i(x,y)
			if x in [10,14] or y in [7,11]:site("wood_wall",cell)
			else:site("wood_tile",cell)
	var structures=game.world.structures.duplicate(true)
	game.BuildingArt.refresh_wall_regions(game)
	check(game.BuildingArt.wall_outer_offset(game,game.center(Vector2i(10,9))).x<0,"Left wall moves outward from floor")
	check(game.BuildingArt.wall_outer_offset(game,game.center(Vector2i(14,9))).x>0,"Right wall moves outward from floor")
	game.select_group(-1);game.refresh();game.queue_redraw();game.hud.queue_redraw();await capture("04_wall_outer")
	check(game.world.structures==structures,"Wall display preserves collision data")
	FileAccess.open(output+"/bubble-a.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("BUBBLE_A: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)

