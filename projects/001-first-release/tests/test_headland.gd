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
	game.pitch = -.35
	var entry := false
	for frame in range(900):
		await tick(Vector2(0, -1))
		if not entry and game.model.depth > 5:
			entry = true
			if gpu:
				await capture("104-headland-entry")
		if game.model.depth > 20 and game.model.standing:
			break
	check(entry and game.model.standing, "Ordinary forward entry lands on broad bedrock")
	check(game.model.depth < 42, "First contact happens in the shallows")
	observations.first_landing = var_to_str(game.model.position)
	if gpu:
		await capture("105-first-bedrock")
		await photo("109-first-terrace-choice", Vector3(-18, -44, -84))
		game.pitch = -.35
	var landed: Vector3 = game.model.position
	var walking := await walk_to(Vector2(-18, -84))
	check(walking > 100, "Cross the rock stairs on foot, without Space")
	check(game.model.oxygen == 100, "Terraced refuge is rooted and actually refills")
	check(
		game.model.position.distance_to(landed) > 20,
		"The first choice includes substantial lateral travel"
	)
	await photo("106-bedrock-stairs", Vector3(-16, -48, -104))
	observations.stairs = {"grounded_frames": walking, "seconds": game.model.elapsed}
	var lowest: float = game.model.position.y
	check(await walk_to(Vector2(5, -65)) > 80, "Climb back up the weathered steps without swimming")
	check(game.model.position.y > lowest + 5, "Stairs can be walked up as well as down")
	if gpu:
		await capture("107-return-steps")
	check(
		await swim(Vector3(-8, -60, -35), 18, false, false),
		"Leave the edge to the existing algae below"
	)
	check(game.model.oxygen == 100, "Rejoin the old sea route without a forced checkpoint")
	check(await swim(Vector3(15, -72, -58), 15, false, false), "Swim through the eroded underside")
	await photo("108-under-bedrock", Vector3(0, -42, -76))
	check(
		await swim(Vector3(20, -90, -58), 10, false, false),
		"The underside reconnects to the drifting wood"
	)
	check(game.model.setbacks == 0, "The full introduction needs no rescue or reset")
	observations.journey_seconds = game.model.elapsed
	record_sequence = false
	if gpu:
		var frames := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		frames.store_string(JSON.stringify(sequence, "  "))
		frames.close()
	await contacts()
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
