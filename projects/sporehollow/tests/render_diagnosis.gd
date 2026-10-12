extends SceneTree
func mark(stage: String):
	var file=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+OS.get_environment("FARM_REVIEW_CASE")+"-stage.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"stage":stage,"milliseconds":Time.get_ticks_msec()}));file.flush();file.close()
func _initialize():mark("initialize");call_deferred("run")
func run():
	mark("run")
	root.size=Vector2i(1280,800)
	var rect=ColorRect.new();rect.color=Color("72915e");rect.size=Vector2(1280,800);root.add_child(rect)
	await process_frame;await process_frame;mark("render_wait")
	await RenderingServer.frame_post_draw
	mark("image_read")
	var error=root.get_texture().get_image().save_png(OS.get_environment("FARM_REVIEW_OUTPUT")+"/probe_"+OS.get_environment("FARM_REVIEW_CASE")+".png")
	mark("saved:"+str(error));quit(error)
