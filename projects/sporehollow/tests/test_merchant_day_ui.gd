extends "res://tests/test_market_reference_ui.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	game.world.story.intro_seen=true
	root.add_child(game);await process_frame;await process_frame
	game.set_process(false)
	check(game.world.phase=="day" and not game.buttons.has("open_market"),"Start directly in field without morning entry")
	check(not game.world.merchant_present() and game.merchant_visual_elapsed()<0,"No merchant before five-second entry delay")
	game.world.tick=19
	check(not game.world.merchant_present(),"No interaction just before five seconds")
	game.world.tick=20
	check(game.world.merchant_present() and game.merchant_visual_elapsed()==0,"Entry begins at five seconds")
	var trace=[]
	for rate in [0.5,1.0,2.0]:
		game.world.tick=22;game.accumulated=0
		var previous=game.merchant_world_position().x
		for frame in range(1,4):
			game.accumulated=frame*rate/60.0
			var next=game.merchant_world_position().x
			check(next>previous and next-previous<5,"Cart interpolates between ticks at speed "+str(rate))
			trace.append({"speed":rate,"frame":frame,"x":next});previous=next
	game.world.tick=0;game.accumulated=0
	record.events.append({"cart_interpolation":trace})
	for i in range(40):game.world.step()
	check(game.world.trees.keys().all(func(p):return not preload("res://game/forest_pattern.gd").merchant_clearing(p)),"Merchant apron has no trees or tree collision")
	game._process(0);game.hud.queue_redraw();game.queue_redraw();await capture("01_day_merchant_arrival")

	game.world.tick=136 # Begin approach at 34 seconds, just before scheduled departure.
	game.world.paused=true;var tick=game.world.tick
	await mouse(game.screen_cell(Farm.MERCHANT_CELL))
	check(game.merchant_requested and not game.field_shop,"Click reserves physical approach during pause")
	for i in range(50):game.world.step();game._process(0)
	check(game.world.tick==tick,"Pause does not consume merchant visit")
	game.world.paused=false
	for i in range(590):
		game.world.step();game.record_actor_tracks();
		game._process(Farm.DT)
		if game.field_shop:break
	check(game.field_shop and game.world.keeper.pos in game.world.merchant_talk_cells(),"Keeper approaches before shop opens")
	check(game.world.phase=="day","Shop retains daytime phase")
	check(game.world.tick*Farm.DT>35 and game.world.merchant_present(),"Merchant waits beyond deadline for physical approach and shopping")
	check(game.world.keeper.pos==game.world.merchant_talk_cells()[0],"Prefer cart front over distant diagonal candidate")
	check(game.view_positions.keeper.distance_to(Vector2(game.world.keeper.pos))<0.08,"Conversation waits for visible keeper arrival")
	tick=game.world.tick;var before=[game.world.keeper.duplicate(true),game.world.animals.duplicate(true),game.world.natural.duplicate(true),game.world.jobs.duplicate(true)]
	for i in range(1000):game.world.step()
	check(game.world.tick==tick and [game.world.keeper.duplicate(true),game.world.animals.duplicate(true),game.world.natural.duplicate(true),game.world.jobs.duplicate(true)]==before,"World simulation remains frozen in shop")
	game.hud.queue_redraw();game.queue_redraw();await capture("02_shop_from_conversation")
	check(game.buttons.has("open_market") and game.buttons.has("open_book"),"Conversation offers shopping and journal")
	await press("open_book");await settle()
	check(game.field_book and game.world.market_open,"Conversation journal retains time stop")
	game.close_morning_screen();await settle()
	check(game.field_shop and game.morning_screen=="morning" and game.buttons.has("open_market"),"Book closes back to conversation choice")
	await press("open_market")
	await press("shop_buy");await press("category_materials");await press("trade_soil_-1")
	var gold=game.world.campaign.gold
	await press("confirm_trade")
	check(game.world.campaign.gold==gold-15,"Existing confirmed purchase works during daytime conversation")
	await press("close_market")
	check(game.field_shop and game.morning_screen=="morning","Shop returns to conversation choice")
	await press("close_market")
	check(not game.field_shop and not game.world.market_open and game.world.phase=="day","Close returns directly to daytime")
	game.queue_redraw();game.hud.queue_redraw();await capture("04_conversation_distance")
	game.world.merchant_leave_at=Farm.MERCHANT_DELAY+Farm.MERCHANT_SECONDS
	game.world.tick=int(34.95/Farm.DT)
	check(game.world.merchant_present(),"Merchant present before 35 seconds")
	game.world.step()
	check(not game.world.merchant_present(),"Merchant unavailable at 35 seconds")
	game.open_market();check(not game.field_shop,"Cannot reopen after departure")
	game.world.tick=int(37/Farm.DT);game._process(0);game.queue_redraw();game.hud.queue_redraw();await capture("03_merchant_departed")
	game.choose_walk();game.refresh();await press("keeper_book")
	game.clock=game.book_started;game._process(0);game.hud.queue_redraw();await capture("05_adopted_closed_cover")
	check(preload("res://game/adopted_art.gd").CLOSED.resource_path=="res://assets/ui/journal_cover_green.png","User adopted green cover is connected")
	game.clock=game.book_started+0.20;game._process(0);game.hud.queue_redraw();await capture("07_cover_opening")
	await settle();game.hud.queue_redraw();await capture("06_book_open")
	check(game.field_book,"Keeper can still open animal book in daytime")
	game.world.campaign.exp_pool=100
	var id=game.world.campaign.animals[0].id
	check(game.world.train_animal(id) and game.world.Orders.animal(game.world,id).lv==2,"Daytime training updates resident in place")
	check(game.world.rename_animal(id,"テスト") and game.world.Orders.animal(game.world,id).name=="テスト","Daytime naming updates same resident")
	game.close_morning_screen();await settle()
	game.world.phase="dawn";game.world.next_campaign()
	game.advance();game._process(0)
	check(game.world.phase=="day" and not game.world.merchant_present(),"Following day also waits five seconds for merchant")
	var wait_world=Farm.new({},31).begin_day()
	wait_world.tick=140;wait_world.merchant_approach=wait_world.merchant_talk_cells()[0];wait_world.manual_goal=wait_world.merchant_approach
	check(wait_world.merchant_present(),"Valid approach holds merchant at deadline")
	wait_world.manual_goal=null
	check(not wait_world.merchant_present(),"Cancelled or failed movement releases waiting merchant")
	wait_world.manual_goal=wait_world.merchant_approach;wait_world.keeper.state="unconscious"
	check(not wait_world.merchant_present(),"Incapacitation releases merchant wait")
	var saved=Farm.new({},31);var save_record=game.MorningSave.capture(saved)
	check(not save_record.is_empty() and game.MorningSave.restore(save_record)!=null,"Existing start-of-day save remains compatible")
	FileAccess.open(output+"/merchant-day.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("MERCHANT_DAY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)

