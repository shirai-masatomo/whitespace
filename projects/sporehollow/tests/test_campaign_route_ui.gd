extends "res://tests/test_controls.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only headless or isolated rendering")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	var target=Farm.Progression.Encounters.route_definition().completion_night
	var c=Farm.new_campaign();c.day=target;var w=Farm.new(c,31).begin_day();w.start_night();w.spawn_schedule.clear();w.finish(true)
	game.world=Farm.new(w.next_campaign(),32);root.add_child(game);game.set_process(false);await process_frame
	game.arrival_started=-10;game.refresh();game._process(0);await process_frame
	check(game.buttons.advance.visible and game.buttons.advance.text=="牧場を続ける" and game.buttons.has("route_restart"),"Completed morning offers continuation and a separate new campaign")
	var settled=game.world.campaign.duplicate(true);var stock=game.world.shop_stock.duplicate(true)
	game.refresh();game._process(0)
	check(game.world.campaign==settled and game.world.shop_stock==stock and game.world.tick==0,"Redrawing the endpoint does not mutate progress, goods or rewards")
	await capture("01_route_complete")
	await mouse(game.buttons.route_restart.get_global_rect().get_center());game._process(0)
	check(game.restart_confirm and game.world.campaign==settled and not game.buttons.advance.visible,"Opening new-campaign choice preserves the current farm")
	await mouse(game.buttons.route_restart_cancel.get_global_rect().get_center());game._process(0)
	check(not game.restart_confirm and game.world.campaign==settled,"Cancelling new campaign preserves the current farm")
	await mouse(game.buttons.advance.get_global_rect().get_center());game._process(0)
	check(game.world.phase=="day" and game.world.campaign.day==target+1 and Farm.Progression.Encounters.reached(game.world.campaign),"Continue enters the following day with the same completed farm")
	game.world=Farm.new(settled,32);game.restart_confirm=false;game.reset_view();game.arrival_started=-10;game.refresh();game._process(0)
	await mouse(game.buttons.route_restart.get_global_rect().get_center());game._process(0)
	await mouse(game.buttons.route_restart_yes.get_global_rect().get_center());game._process(0)
	check(game.world.phase=="shop" and game.world.campaign.day==1 and not Farm.Progression.Encounters.reached(game.world.campaign) and game.world.campaign.animals.size()==1 and not game.world.story.intro_seen,"Confirmed new campaign starts clean with the introduction available")
	if output!="":FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("CAMPAIGN_ROUTE_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
