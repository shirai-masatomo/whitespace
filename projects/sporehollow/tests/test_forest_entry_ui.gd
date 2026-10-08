extends "res://tests/test_playthrough_ui.gd"
func ticks(count: int):
	for i in range(count):game.world.step();game.record_actor_tracks();game._process(Farm.DT)
	await process_frame
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only isolated rendering or headless")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	await fresh();var w=game.world;w.animals[0].pos=Vector2i(4,5);w.animals[0].mode="stay";w.animals[0].order=w.animals[0].pos;w.keeper.pos=Vector2i(3,5);game.debug_view=true
	var entry=Vector2i(12,15);var edge=w.exit_for(entry)
	for i in range(3):
		w.spawn_enemy({"role":"maid","entry":entry,"lv":1,"debug_single":true})
		var e=w.enemies.back();e.pos=edge+Vector2i(0,i);e.entry=entry;e.ai_accuracy=100
	game.camera.position=Vector2(12,15)*game.TILE;game.camera.zoom=Vector2(1.5,1.5);game.clamp_camera()
	await ticks(1);await capture("01_clear_entry")
	await ticks(39);await capture("02_arrived")
	check(w.enemies.all(func(e):return w.inside(e.pos) and e.get("arrival_cleared",false)),"All three clear the entrance in the rendered scene")
	FileAccess.open(output+"/forest-entry-ui.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  ")) if output!="" else null
	game.queue_free();await process_frame
	print("FOREST_ENTRY_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
