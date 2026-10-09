extends "res://tests/test_morning_layout_ui.gd"

func hover(p: Vector2):
	if not viewport_mouse_notified:root.notify_mouse_entered();viewport_mouse_notified=true
	var event=InputEventMouseMotion.new();event.position=p;root.push_input(event,true)
	await process_frame;await process_frame

func press(id: String):
	check(game.buttons.has(id),"Control exists: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())

func extras():
	pass

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	game.world.story.intro_seen=true;game.world.campaign.gold=300
	# Display fixture contains five offers, with a bonus skill and one sold-out card.
	game.world.shop_stock=[]
	var species=["hen","cat","doberman","bullfrog","hedgehog"]
	for i in range(species.size()):
		game.world.shop_stock.append({"product":species[i],"remaining":0 if i==2 else 1,"individual":{"species":species[i],"lv":1,"rarity":i,"bonus_skills":["hardy"] if i==0 else [],"loyalty":75}})
	root.add_child(game);await process_frame;await process_frame
	game.arrival_started=game.clock-5;game.refresh();game._process(0);game.set_process(false);await process_frame
	var tick=game.world.tick;var gold=game.world.campaign.gold
	await capture("01_morning_reference")
	await press("open_market");game.clock=6.0;game.hud.queue_redraw();await capture("02_market_bubble_closed")
	game.clock=6.15;game.hud.queue_redraw();pass # No delivered talking frames; do not fabricate mouth animation.
	await press("shop_buy");await press("category_animals")
	check(game.MarketView.list_title(game)=="商品一覧","Buy heading is product list")
	check(not game.buttons.has("shop_page"),"Product pagination replaced by scrolling")
	var bar=game.palette.get_node("MarketScroll")
	check(bar.visible and bar.max_value>bar.page,"Overflow has visible draggable scrollbar")
	check(game.buttons["trade_hen_-1"].size==Vector2(728,72),"Compact vertical product rows")
	check(game.MarketView.FOOTER.encloses(game.buttons.market_skill_3.get_global_rect()),"Skill controls fit inside the fixed explanation panel")
	await hover(game.buttons["trade_hen_-1"].get_global_rect().get_center())
	check(game.MarketView.hovered_row(game).id=="hen","Pointer changes fixed footer product")
	check(game.buttons["trade_hen_-1"].tooltip_text=="","Product description does not use a floating tooltip")
	var skills=game.MarketView.skill_rows(game,game.MarketView.hovered_row(game))
	check(skills.size()==2 and skills[0].id=="lay" and skills[1].id=="hardy","Only possessed/unlocked and bonus skills are shown")
	await capture("04_product_list_and_skills")
	await hover(game.buttons.market_skill_1.get_global_rect().get_center())
	check(game.get_meta("market_skill")==1,"Skill hover selects fixed footer explanation")
	pass
	var group=game.group;var tool=game.tool;var zoom=game.camera.zoom
	await mouse(Vector2(950,420),MOUSE_BUTTON_WHEEL_DOWN)
	check(bar.value==56,"Wheel moves continuous list by bounded vertical distance")
	check(game.group==group and game.tool==tool and game.camera.zoom==zoom,"Market wheel does not leak into field mode or zoom")
	await mouse(Vector2(950,420),MOUSE_BUTTON_WHEEL_DOWN)
	check(bar.value==bar.max_value-bar.page,"Scrolling clamps at end")
	pass
	await mouse(Vector2(950,420),MOUSE_BUTTON_WHEEL_DOWN)
	check(bar.value==56 and game.group==group and game.tool==tool,"Wheel at end remains consumed")
	await press("trade_hedgehog_-1")
	check(game.product_row.id=="hedgehog" and game.buttons.has("cancel_trade"),"Scrolled offer opens explicit confirmation with cancel")
	await capture("07_purchase_confirmation")
	var remembered=game.get_meta("market_scroll")
	await press("cancel_trade")
	check(game.shop_level=="list" and game.get_meta("market_scroll")==remembered,"Cancel returns to same scroll position without trading")
	game.buttons["trade_hen_-1"].grab_focus();await process_frame;await process_frame
	check(game.get_meta("market_scroll")==0,"Keyboard focus reveals an offscreen offer")
	game.buttons["trade_hedgehog_-1"].grab_focus();await process_frame;await process_frame
	check(game.get_meta("market_scroll")==56,"Keyboard focus can reach last offer without a page button")
	check(game.world.campaign.gold==gold and game.world.tick==tick,"Hover, scrolling and cancel do not mutate simulation or money")
	await press("trade_doberman_-1")
	check(game.buttons.confirm_trade.disabled and game.buttons.confirm_trade.tooltip_text=="売り切れ","Sold-out offer remains inspectable but cannot trade")
	pass
	await press("close_market");await press("open_market");await press("shop_sell");await press("category_animals")
	check(game.MarketView.list_title(game)=="持ち物一覧","Sell heading is belongings list")
	check(not game.palette.get_node("MarketScroll").visible,"No scrollbar is shown without overflow")
	pass
	await mouse(Vector2(900,430),MOUSE_BUTTON_WHEEL_DOWN)
	check(game.group==group and game.tool==tool and game.camera.zoom==zoom,"Short-list wheel also stays inside market")
	check(game.world.jobs.is_empty() and game.world.shop_log.is_empty(),"UI inspection never issues jobs or trades")
	await extras()
	if output!="":FileAccess.open(output+"/market-reference.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("MARKET_REFERENCE_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
