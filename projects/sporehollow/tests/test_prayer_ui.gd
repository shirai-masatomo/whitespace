extends "res://tests/test_controls.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only headless or isolated rendering")
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	var c=Farm.new_campaign();c.day=2
	game.world=Farm.new(c,31).begin_day();game.world.story.investigated=true;game.world.paused=true
	root.add_child(game);await process_frame;await process_frame
	game.reset_view();game.refresh();game.choose_walk()
	await mouse(game.screen_cell(game.world.Story.at(game.world)))
	check(["pray_animal","pray_gold","pray_item"].all(func(id):return game.buttons.has(id) and not game.buttons[id].disabled),"All three category controls are enabled")
	check(not game.buttons.has("pray_wealth"),"No obsolete fixed-gold control")
	var panel=game.context_panel.get_global_rect()
	check(panel.position.x>=0 and panel.end.x<=1280 and panel.position.y>=0 and panel.end.y<=800,"Category panel stays inside viewport")
	await capture("prayer_categories")
	await mouse(game.buttons.pray_item.get_global_rect().get_center())
	check(game.world.jobs.size()==1 and game.world.jobs[0].kind=="pray_item" and game.world.tick==0,"Real click queues one selected category while paused")
	game.world.Jobs.cancel(game.world,game.world.jobs[0].id);game.refresh()
	check(game.world.story.prayers.is_empty(),"Cancelling selection does not award a gift")
	game.world.keeper.pos=game.world.Story.goals(game.world)[0]
	game.story_action("pray_gold");game.world.paused=false
	for i in range(100):
		game.world.step()
		if game.world.jobs.is_empty():break
	game.world.paused=true;game.refresh();await process_frame
	check(game.world.story.prayers.size()==1 and ["pray_animal","pray_gold","pray_item"].all(func(id):return game.buttons[id].disabled),"Committed prayer disables every category for today")
	game.world.paused=false;game.world.start_night();game.world.spawn_schedule.clear();game.world.finish(true)
	game.world=Farm.new(game.world.next_campaign(),31);game.reset_view();game.refresh();await process_frame
	check(game.world.story.miracles.size()==1 and game.palette.get_children().any(func(n):return n is Label and n.text.begins_with("願いの贈り物：")),"Following morning displays the actual gift")
	await capture("prayer_morning")
	if output!="":FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("PRAYER_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
