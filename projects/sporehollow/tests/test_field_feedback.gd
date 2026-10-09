extends "res://tests/test_controls.gd"

func run():
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31);root.add_child(game);game.set_process(false)
	game.arrival_started=-10;game.refresh();await process_frame
	check(game.buttons.advance.get_theme_font_size("font_size")==20,"Morning retains the readable primary action")
	game.advance();game._process(0);await process_frame
	check(game.world.phase=="day","The morning action reaches the field")
	check(Rect2(0,0,1280,800).encloses(game.buttons.advance.get_global_rect()),"The reused action fits the viewport after morning-to-day transition")
	check(game.buttons.advance.get_theme_font_size("font_size")==16,"Morning font size does not leak into the field toolbar")
	game.world.start_night();game.world.spawn_schedule.clear();game.world.early_clear=true
	game.refresh();await process_frame
	check(Rect2(0,0,1280,800).encloses(game.buttons.advance.get_global_rect()),"The reward-bearing dawn-rest action fits the viewport")
	game.world.story.idol.state="preparing"
	check(game.idol_warning_text()!="","An active extraction preparation exposes a persistent HUD warning")
	game.world.story.idol.state="transporting";game.clock+=60
	check(game.idol_warning_text()!="","The extraction warning does not expire while transport continues")
	game.world.story.idol.state="interrupted"
	check(game.idol_warning_text()=="","Stopping extraction clears its warning")
	game.world.story.idol.state="transporting";game.world.phase="result"
	check(game.idol_warning_text()=="","The result screen does not retain a stale extraction warning")
	game.queue_free();await process_frame
	print("FIELD_FEEDBACK: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
