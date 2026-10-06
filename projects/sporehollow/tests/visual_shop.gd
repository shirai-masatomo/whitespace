extends SceneTree
# Current game UI, isolated save directory, real game-local mouse input.
var game
var output = ""
var shots = []
var events = []
func _initialize(): call_deferred("run")
func click(id: String):
	if not game.buttons.has(id):
		push_error("Missing shop button: " + id); quit(2); return
	var p = game.buttons[id].get_global_rect().get_center()
	events.append({"button":id,"position":[p.x,p.y],"gold":game.world.campaign.gold})
	var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed
		Input.parse_input_event(e);await process_frame
func capture(label: String):
	# Move off controls so labels remain readable, without clicking anything.
	var motion=InputEventMouseMotion.new();motion.position=Vector2(20,400);Input.parse_input_event(motion)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var file="%02d_%s.png" % [shots.size()+1,label]
	var error=root.get_texture().get_image().save_png(output+"/"+file)
	if error!=OK:push_error("Capture failed: "+file);quit(3);return
	var controls={}
	for id in game.buttons:
		var b=game.buttons[id]
		if b.is_visible_in_tree():controls[id]={"disabled":b.disabled,"position":[b.position.x,b.position.y],"size":[b.size.x,b.size.y]}
	shots.append({"file":file,"label":label,"screen":game.morning_screen,"side":game.shop_side,"level":game.shop_level,"category":game.shop_category,"page":game.shop_page,"product":game.product_row.duplicate(true),"gold":game.world.campaign.gold,"tick":game.world.tick,"notice":game.shop_notice,"controls":controls,"shop_log":game.world.shop_log.duplicate(true)})
func browse(side: String):
	await click("shop_"+side);await capture(side+"_categories")
	for category in game.MARKET_CATEGORIES:
		await click("category_"+category)
		var pages=maxi(1,ceili(game.shop_rows().size()/4.0))
		for page in range(pages):
			await capture(side+"_"+category+"_list_"+str(page+1))
			var ids=game.buttons.keys().filter(func(id):return id.begins_with("trade_"))
			for id in ids:
				await click(id);await capture(side+"_"+category+"_"+id.trim_prefix("trade_"));await click("shop_back")
			if page+1<pages:await click("shop_page")
		await click("shop_back")
	await click("shop_back")
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();root.add_child(game)
	if game.story_modal!="": await click("story_close")
	await create_timer(3.0).timeout
	await capture("morning_menu")
	await click("open_market");await capture("market_entry")
	await browse("buy")
	await click("shop_buy");await click("category_materials");await click("trade_wood_-1")
	await click("confirm_trade");await capture("purchase_complete")
	await click("shop_back");await capture("purchase_back_to_list")
	await click("shop_back");await capture("purchase_back_to_categories")
	await click("category_animals");await capture("another_category_after_purchase")
	await click("close_market");await capture("market_closed_morning")
	await click("open_market");await browse("sell")
	await click("shop_sell");await click("category_materials");await click("trade_wood_-1")
	await click("confirm_trade");await capture("sale_complete")
	await click("close_market");await capture("final_morning")
	# Supplemental states reached by normal trades, without modifying stock or money.
	await click("open_market");await click("shop_buy");await click("category_animals")
	await click("trade_cat_-1");await capture("insufficient_gold_detail")
	await click("shop_back");await click("shop_back");await click("category_items")
	await click("trade_whistle_-1");await click("confirm_trade");await capture("sold_out_detail")
	await click("shop_back");await capture("sold_out_list")
	await click("close_market");await click("open_market");await click("shop_sell");await click("category_items")
	await click("trade_whistle_-1");await capture("sell_whistle_detail")
	await click("confirm_trade");await capture("sell_whistle_depleted")
	await click("close_market");await capture("supplemental_final_morning")
	FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"Current main.tscn, isolated GPU viewport, game-local mouse press/release. Default new campaign; no debug money or stock changes.","shots":shots,"events":events},"  "))
	print("SHOP_CAPTURE_OK ",shots.size()," screenshots")
	quit()
