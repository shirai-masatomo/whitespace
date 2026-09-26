extends "res://tests/test_discovery.gd"
## Ordinary entry, walking across the first bedrock, then rejoining the sea.


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	capture_root = "res://artifacts/headland-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	# Local terrain regression. The current introduction is test_entry.gd;
	# this older rock shelf no longer carries a competing oxygen destination.
	fixture(Vector3(0, -32, -64))
	check(await walk_to(Vector2(-18, -84)) > 80, "The weathered terrace remains walkable")
	await contacts()
	await explore_fissure()
	var file := FileAccess.open("res://artifacts/headland.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify({"checks": checks, "failed": failed, "observations": observations}, "  ")
	)
	file.close()
	game.queue_free()
	await process_frame
	print("Headland: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)


func walk_to(target: Vector2) -> int:
	var grounded := 0
	for frame in range(900):
		var offset := target - Vector2(game.model.position.x, game.model.position.z)
		if offset.length() < 1:
			return grounded
		await tick((offset / 2).limit_length())
		if game.model.standing:
			grounded += 1
	check(false, "Walking route must reach its target")
	return grounded


func contacts() -> void:
	for rate in [60, 15]:
		for fast in [false, true]:
			fixture(Vector3(0, -20, -65))
			for frame in range(rate * 4):
				game.advance(1.0 / rate, Vector2.ZERO, 1 if fast else 0, false)
			check(game.model.standing, "Normal/E contact with shallow bedrock at %dHz" % rate)
			check(game.model.position.y > -40, "Fast descent cannot tunnel through the terrace")
		fixture(Vector3(0, -68, -64))
		var touched := false
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
			for body in game.motion.contact_bodies:
				touched = touched or "ShallowHeadland" in str(body.get_path())
		check(
			touched and game.model.position.y < -54,
			"Space meets the visible underside at %dHz" % rate
		)

		fixture(Vector3(18, -51, -100))
		var side_contact := false
		for frame in range(rate * 5):
			game.advance(1.0 / rate, Vector2(-1, -.15), -1, false)
			for body in game.motion.contact_bodies:
				side_contact = side_contact or "ShallowHeadland" in str(body.get_path())
		check(side_contact, "Diagonal swimming meets the bedrock side at %dHz" % rate)


func explore_fissure() -> void:
	# This branch starts at the refuge reached by the continuous journey above.
	fixture(Vector3(-18, -43, -84))
	for frame in range(60):
		await tick()
	var start: float = game.model.elapsed
	check(await walk_to(Vector2(-1, -82)) > 60, "Walk from the refuge to the fissure lip")
	await photo("110-fissure-lip", Vector3(7, -52, -86))
	check(
		await swim(Vector3(7, -66, -84), 10), "The visible fissure opens through the entire bedrock"
	)
	await photo("111-fissure-exit", Vector3(7, -39, -83))
	check(
		await swim(Vector3(17, -70, -68), 10),
		"Exit below the cliff into a different part of the sea"
	)
	check(game.model.setbacks == 0, "The optional fissure needs no rescue")
	observations.fissure_seconds = game.model.elapsed - start
	for rate in [60, 15]:
		fixture(Vector3(7, -29, -84))
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 1, false)
		check(game.model.depth > 63, "E fits through the real opening at %dHz" % rate)
