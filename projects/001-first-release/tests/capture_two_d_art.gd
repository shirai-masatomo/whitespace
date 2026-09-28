extends SceneTree
## Fixed-time samples of the normal following camera, with real movement first.


func _initialize() -> void:
	root.unfocusable = true
	call_deferred("run")


func run() -> void:
	var output := "res://artifacts/art-preview"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	var game = load("res://game/two_d/main.tscn").instantiate()
	game.automated = true
	root.add_child(game)
	var shots := {
		"shallow": Vector2(58, 17),
		"seabed": Vector2(68, 234),
		"biology": Vector2(66, 322),
		"creature": Vector2(70, 336),
	}
	if "--jelly" in OS.get_cmdline_user_args():
		shots = {"jelly": Vector2(65, 74)}
	for label in shots:
		game.player.position = shots[label] * 24 - Vector2(0, 30)
		game.player.velocity = Vector2.ZERO
		game.clock = 8.0
		game.message_time = 0.0
		for frame in range(30):
			await physics_frame
			game.step(1.0 / 60.0, 0.0, false, false)
		game.player.velocity = Vector2.ZERO
		for frame in range(120):
			await physics_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(output + "/" + label + ".png")
		assert(result == OK)
		print(
			label,
			" depth=",
			game.depth(),
			" draws=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		)
	quit()
