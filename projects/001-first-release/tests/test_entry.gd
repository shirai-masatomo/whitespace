extends "res://tests/test_discovery.gd"


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	capture_root = "res://artifacts/entry-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	await photo("50-pier-choices", Vector3(20, -8, -28))
	for frame in range(600):
		await tick(Vector2(1, -1).normalized())
		if game.model.depth > 5:
			break
	check(
		game.model.depth > 5 and game.model.elapsed < 10, "Player enters open water from the pier"
	)
	check(game.model.mode == game.model.Mode.DIVING, "Entry is continuous gameplay")
	game.pitch = .75
	game._update_camera()
	var focus: Vector3 = game.model.position + Vector3.UP * 1.4
	check(
		(
			not game.camera.is_position_behind(focus)
			and Rect2(0, 0, 1280, 720).has_point(game.camera.unproject_position(focus))
		),
		"Looking up at sunlight underwater keeps the diver in frame"
	)
	await photo("51-enter-ocean", Vector3(35, -20, -28))
	await photo("52-surface-light", game.model.position + Vector3(3, 16, -18))
	check(await swim(Vector3(32, -28, -25)), "The shoal's destination is actually reachable")
	await photo("53-kelp-from-sea", Vector3(53, -20, -50))
	var guide: Node3D = game.world.life.reef_guide
	game.world.life.update(Vector3(500, 0, 500), 0)
	var first: Vector3 = guide.position
	game.world.life.update(Vector3(500, 0, 500), PI / .2)
	check(guide.position.x - first.x > 20, "Fish movement leads sideways into the reef")
	check(game.model.oxygen == 100, "Exploration reaches the living oxygen refuge")
	var file := FileAccess.open("res://artifacts/entry.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify({"checks": checks, "failed": failed, "seconds": game.model.elapsed}, "  ")
	)
	file.close()
	game.queue_free()
	await process_frame
	print("Entry: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)
