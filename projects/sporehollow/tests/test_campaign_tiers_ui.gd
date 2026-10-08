extends "res://tests/test_controls.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only isolated rendering or headless verification")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	var c=Farm.new_campaign();c.day=7;var w=Farm.new(c,31).begin_day();w.story.investigated=true;w.story.intro_seen=true;w.Story.pray(w,"item");w.persist_farm();c=w.campaign.duplicate(true);c.day=10;c.night_ready=false
	game.world=Farm.new(c,34);root.add_child(game);game.set_process(false);await process_frame
	game.arrival_started=-10;game.StoryView.open(game,"radio");game._process(0);await process_frame
	var scroll=game.story_panel.get_children().filter(func(n):return n is ScrollContainer)[0]
	scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await process_frame
	check(game.world.story.news[-1].title=="落とし物を狙う盗難" and game.world.spawn_schedule.any(func(row):return row.wave>=100 and row.role=="thief"),"The readable warning corresponds to the actual scheduled role")
	await capture("01_reaction_radio")
	game.StoryView.close(game);game._process(0)
	check(game.world.phase=="shop" and game.world.tick==0 and game.story_modal=="","Reading the reaction does not advance simulation")
	print("CAMPAIGN_TIERS_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
