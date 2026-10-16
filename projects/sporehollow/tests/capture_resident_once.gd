extends SceneTree
func _initialize():call_deferred("capture")
func capture():
	Engine.max_fps=30
	var boot=load("res://game/loading.tscn").instantiate()
	root.add_child(boot)
	var deadline=Time.get_ticks_msec()+45000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:push_error("Capture loading failed or exceeded 45 seconds: "+boot.failure);quit(1);return
	var g=boot.game
	g.world.paused=true;g.set_process(false);g.set_process_input(false);g.set_process_unhandled_input(false)
	g.story_modal="";g.field_book=false;g.field_shop=false;g.controls.visible=true
	g.choose_walk();g.recenter();g.camera.force_update_scroll();g.queue_redraw();g.hud.queue_redraw()
	for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
	var folder=OS.get_environment("FARM_REVIEW_OUTPUT")
	var screenshot=root.get_texture().get_image()
	if screenshot.is_empty():push_error("Empty screenshot");quit(1);return
	var error=screenshot.save_png(folder+"/01-current-resident.png")
	var record={"scene":"resident detail","source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"actual Godot viewport, private noninteractive desktop; same game source as current EXE, not an EXE-window screenshot","width":screenshot.get_width(),"height":screenshot.get_height(),"seed":g.world.seed_value,"tick":g.world.tick,"paused":g.world.paused,"fps_limit":Engine.max_fps,"rendering_driver":RenderingServer.get_video_adapter_name(),"elapsed_ms":Time.get_ticks_msec(),"png_error":error,"setup":"fresh generated map, default resident; no fabricated equipment or mood; selected keeper via existing UI handler"}
	var f=FileAccess.open(folder+"/resident-capture.json",FileAccess.WRITE);f.store_string(JSON.stringify(record,"  "));f.close()
	boot.queue_free();await process_frame
	print("Resident viewport capture complete: ",error);quit(0 if error==OK else 1)
