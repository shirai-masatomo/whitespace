extends "res://tests/test_discovery.gd"
## Three views and actual movement across the shelf and into its deeper routes.
const Shelf = preload("res://game/coastal_seabed.gd")


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/seabed-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root)
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	fixture(Vector3(90, -57, 8))
	await photo("113-shelf-overview", Vector3(125, -100, -30))
	for descent in [0, 1]:
		fixture(Vector3(145, -70, -30))
		for frame in range(600):
			await tick(Vector2.ZERO, descent)
			if game.model.standing:
				break
		check(game.model.standing, "Normal and E descent land on the visible sea floor")
		check(game.model.depth < 120, "The shallow shelf is not the deep terminal floor")
	for frame in range(15):
		await tick()
	await photo("114-shelf-rim", Vector3(40, -135, -55))
	var grounded := 0
	for frame in range(160):
		await tick(Vector2(-1, 0))
		if game.model.standing:
			grounded += 1
	check(grounded > 50, "The sea floor can be traversed on foot")
	check(await swim(Vector3(45, -125, -45), 20), "Leave the shelf into the existing refuge")
	check(game.model.oxygen > 90, "The deeper route rejoins existing oxygen")
	check(await swim(Vector3(12, -172, -68), 14), "Continue below the surrounding sea floor")
	await photo("115-below-shelf", Vector3(105, -90, -40))
	check(game.model.setbacks == 0, "Sea floor is not a dead end or a rescue trap")
	game.queue_free()
	await process_frame
	print("Seabed: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)
