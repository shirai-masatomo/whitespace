extends SceneTree
# Run ONLY through an approved noninteractive GPU launcher; never directly on the desktop.
const Farm=preload("res://game/world.gd")
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	var views_path=OS.get_environment("FARM_BIOME_VIEWS")
	if out=="" or views_path=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var views=JSON.parse_string(FileAccess.get_file_as_string(views_path))
	if not views is Dictionary:quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},int(views.seed)).begin_day();w.story.intro_seen=true;w.paused=true
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g)
	await process_frame;await process_frame
	g.set_process(false);g.audio.set_process(false);g.neutral()
	var files=[]
	for view in views.views:
		w.calendar_ticks=int(view.ticks)
		w.phase="defend" if w.Cycle.period(w)=="night" else "day"
		g.reset_view();g.camera.zoom=Vector2.ONE*float(view.zoom)
		g.camera.position=g.center(Vector2i(int(view.cell[0]),int(view.cell[1])))
		g.camera.force_update_scroll();g.refresh_jobs();g.queue_redraw();g.hud.queue_redraw()
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var path=out+"/"+view.name+".png"
		if root.get_texture().get_image().save_png(path)!=OK:quit(1);return
		files.append({"file":view.name+".png","cell":view.cell,"zoom":view.zoom,"ticks":w.calendar_ticks})
	var f=FileAccess.open(out+"/capture-manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed":views.seed,"resolution":[1280,800],"renderer":DisplayServer.get_name(),"persistence_disabled":not g.persistence_enabled,"files":files,"note":"Controlled real-game render; not human play or FPS certification"},"\t"));f.close()
	g.queue_free();await process_frame;quit()
