extends "res://tests/test_controls.gd"
func press(id: String):
	check(game.buttons.has(id),"UI button exists: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only isolated or headless rendering")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	# UI fixture: day3 and 180G to inspect all adopted new products, no live save.
	var data=Farm.new_campaign();data.day=3;data.gold=180
	game.world=Farm.new(data,31);root.add_child(game);await process_frame
	game.story_modal="";game.arrival_started=-10;game.refresh();await capture("01_morning")
	await press("open_market");await press("shop_buy");await press("category_animals")
	await capture("02_shop_individuals")
	var stock=game.world.shop_stock.duplicate(true)
	await press("trade_doberman_-1");await capture("03_doberman_detail")
	var individual=game.MarketView.individual(game,game.product_row).duplicate(true)
	await press("close_market");await press("open_market");await press("shop_buy");await press("category_animals");await press("trade_doberman_-1")
	check(individual==game.MarketView.individual(game,game.product_row),"Close/reopen keeps individual rarity and bonus skills")
	await press("confirm_trade");await press("close_market")
	await press("open_market");await press("shop_buy");await press("category_items")
	while not game.buttons.has("trade_collar_-1") and game.buttons.has("shop_page"):await press("shop_page")
	await capture("04_equipment_shop")
	await press("trade_collar_-1");await capture("05_collar_detail");await press("confirm_trade");await press("close_market")
	check(game.world.campaign.animals.any(func(a):return a.species=="doberman") and game.world.item_count("collar")==1,"Real shop transactions buy new animal and equipment")
	await press("open_book");await create_timer(0.7).timeout
	await press("book_enemies");await press("book_entry_0");await create_timer(0.5).timeout;await capture("06_enemy_unknown")
	var w=game.world
	w.spawn_enemy({"role":"kidnapper","entry":w.entries[0]});var e=w.enemies.back();e.pos=w.keeper.pos+Vector2i(2,0)
	Farm.Progression.tick(w);game.refresh();await capture("07_enemy_seen")
	e.observed_action=true;Farm.Progression.tick(w);game.refresh();await capture("08_enemy_observed")
	Farm.Progression.enemy_hurt(w,e,999);game.refresh();await capture("09_enemy_defeated")
	await press("book_next")
	if output!="":await movie("book_turn",0.42)
	else:await create_timer(0.6).timeout
	check(game.training_id==1 and game.book_section=="enemies","Existing page turn changes enemy page safely")
	await mouse(Vector2(700,400),MOUSE_BUTTON_RIGHT);await create_timer(0.6).timeout
	check(game.morning_screen=="morning" and w.tick==0,"Book closes to morning without world time")
	game.world=game.world.begin_day();game.world.paused=true;game.reset_view();game.refresh()
	await mouse(game.screen_cell(game.world.animals[0].pos))
	check(game.selected_animal==1,"Board selects original Shiba")
	game.select_tool("equip",false);check(game.world.jobs.is_empty() and not game.equipment_open,"Equipment selection alone never executes")
	await press("equip");await capture("10_equipment_picker")
	await press("equip_collar");await capture("11_equipment_queued_paused")
	check(game.world.jobs.size()==1 and game.world.jobs[0].kind=="equip" and game.world.animals[0].equipment.is_empty(),"Paused local equipment queued exactly once")
	game.world.paused=false
	for i in range(200):
		game.world.step()
		if game.world.jobs.is_empty():break
	game.world.paused=true;game.refresh();await capture("12_equipped")
	check(game.world.animals[0].equipment.get("item_id","")=="collar","Queued equipment reaches animal and executes")
	# Explicit controlled fixtures for new actor/action render coverage.
	game.world.debug_enabled=true
	for species in ["bullfrog","hedgehog"]:game.world.debug_action(species,{})
	game.world.start_night();game.world.enemies.clear()
	for id in Farm.ProgressData.ENEMY_ROWS:
		game.world.spawn_enemy({"role":id,"entry":game.world.entries[0]})
		var actor=game.world.enemies.back();actor.pos=Vector2i(5+game.world.enemies.size()*2,9);actor.state="探索"
	game.reset_view();game.refresh();await capture("13_new_roles_placeholder")
	check(game.world.animals.size()==4 and game.world.enemies.size()==Farm.ProgressData.ENEMY_ROWS.size(),"New actors share existing farm scene")
	if output!="":
		record.method="Current game, real local input. Controlled day3/180G shop, role render fixtures explicitly marked. No user save."
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
		FileAccess.open(output+"/progression-ui.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("PROGRESSION UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)

