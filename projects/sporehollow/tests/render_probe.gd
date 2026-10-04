extends SceneTree
func _initialize(): call_deferred("run")
func run():
	if not "--isolated-review" in OS.get_cmdline_user_args() or OS.get_environment("FARM_REVIEW_OUTPUT")=="": quit(2); return
	root.size=Vector2i(1280,800)
	var game=load("res://game/main.tscn").instantiate()
	game.automated=true;game.world=game.Farm.new({},17).begin_day();game.world.paused=true
	root.add_child(game)
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var picture=root.get_texture().get_image()
	var output=OS.get_environment("FARM_REVIEW_OUTPUT")
	var result=picture.save_png(output+"/probe.png")
	print("ISOLATED GPU PROBE ",DisplayServer.get_name()," ",picture.get_size()," saved=",result)
	quit(result)
