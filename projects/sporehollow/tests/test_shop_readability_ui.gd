extends "res://tests/test_morning_layout_ui.gd"

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	root.add_child(game);game.set_process(false);await process_frame
	game.story_modal="";game.arrival_started=-10;game.save_status=""
	# Display fixture: all five English tiers, including tiers not rolled by the normal shop.
	game.world.shop_stock=[]
	var species=["hen","cat","doberman","bullfrog","hedgehog"]
	for tier in range(5):
		game.world.shop_stock.append({"product":species[tier],"remaining":1,"individual":{"rarity":tier,"bonus_skills":[],"loyalty":75}})
	var tick=game.world.tick;var gold=game.world.campaign.gold
	for window_size in [Vector2i(1280,800),Vector2i(1024,640),Vector2i(1600,1000)]:
		root.size=window_size;await process_frame;await process_frame
		var suffix="_%dx%d"%[window_size.x,window_size.y]
		game.close_morning_screen();game.refresh();await settle()
		await press("open_market");await capture("01_bubble_home"+suffix)
		await press("shop_buy");await press("category_animals")
		for tier in range(5):
			for small in [true,false]:
				var layout=game.MarketView.Assets.badge_layout(game,tier,small)
				var text_size=game.FONT.get_string_size(layout.title,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.font_size)
				check(layout.title==["Common","Uncommon","Rare","Epic","Legendary"][tier],"English rarity label preserved")
				check(layout.size.x<=140 and layout.baseline.x+text_size.x<=layout.size.x-8,"Full rarity label and padding fit shop/book content")
				check(layout.baseline.y-game.FONT.get_ascent(layout.font_size)>=0 and layout.baseline.y+game.FONT.get_descent(layout.font_size)<=layout.size.y,"Rarity font ascenders and descenders fit")
		await capture("02_shop_four_tiers"+suffix)
		await press("trade_cat_-1");check(game.MarketView.rarity_label(game,game.product_row)=="Uncommon","Detail uses the same unmodified rarity")
		await press("shop_back");await press("shop_page");await capture("03_shop_legendary"+suffix)
		await press("close_market");await press("open_market");await press("shop_sell");await capture("04_bubble_sell"+suffix)
		await press("close_market");await press("open_book")
		game.world.campaign.animals[0].rarity=4;game.training_id=game.world.campaign.animals[0].id;game.book_next_id=game.training_id
		game.refresh();await settle();await capture("05_book_legendary"+suffix)
		check(game.world.tick==tick and game.world.campaign.gold==gold,"Reading and navigating do not change time or money")
	# Actual tooltip presentation supplements the footer clipping assertions.
	game.close_morning_screen();game.world.story.radio=true
	game.world.story.news=[{"day":1,"title":"遠い町から届いた長い放送見出しを表示しても紙面を飛び出さず全文を確認できる","text":"テスト用"}]
	game.refresh();await settle()
	var note=game.palette.get_node("MorningNews")
	var motion=InputEventMouseMotion.new();motion.position=note.get_global_rect().get_center();root.push_input(motion,true)
	await create_timer(0.8).timeout;await capture("06_morning_full_tooltip")
	record.method="Local viewport input; fixed five-tier UI fixture at three window sizes; no normal saves, trades, or OS input."
	var destination=output+"/shop-readability.json" if output!="" else "user://shop-readability.json"
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("SHOP_READABILITY_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
