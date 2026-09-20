extends "res://tests/test_discovery.gd"
## Fixed player-camera comparisons; fixtures are not claims of a complete route.
const Gardens = preload("res://game/playground_rules.gd")


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/canyon-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root)
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.begin()
	for view in [
		["60-canyon-approach", Vector3(62, -140, -104), Vector3(92, -181, -170)],
		["61-canyon-interior", Vector3(81, -177, -165), Vector3(108, -199, -217)],
		["62-canyon-exterior", Vector3(145, -185, -175), Vector3(107, -196, -206)]
	]:
		fixture(view[1])
		await photo(view[0], view[2])
	await journeys()
	await oxygen_choices()
	await collisions()
	var file := FileAccess.open("res://artifacts/canyon.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify({"checks": checks, "failed": failed, "observations": observations}, "  ")
	)
	file.close()
	game.queue_free()
	await process_frame
	print("Canyon: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)


func journeys() -> void:
	# Begin at an established 125m refuge, not a teleport to the new terrace.
	record_sequence = true
	fixture(Vector3(45, -124, -45))
	check(await swim(Vector3(67, -159, -135), 25, false, false), "125m refuge to canyon garden")
	check(game.model.oxygen == 100, "Terrace garden is reachable and refills")
	for frame in range(120):
		await tick()
	var walking_frames := 0
	for frame in range(570):
		await tick(Vector2(0, -1))
		if game.model.standing:
			walking_frames += 1
		if frame == 180:
			await photo("67-rock-steps", Vector3(67, -176, -174))
	check(game.model.position.z < -185, "Walk terraces and descending ramps without Space")
	check(walking_frames > 380, "Walking rhythm replaces continuous swimming")
	observations.walking_frames = walking_frames
	observations.terrace_end = var_to_str(game.model.position)
	await photo("63-walk-terrace", Vector3(119, -182, -194))
	check(await swim(Vector3(100, -180, -194), 12, false, false), "Cliff to bridge crest")
	check(await swim(Gardens.PLANTS[6], 15, false, false), "Bridge crest reaches oxygen garden")
	await photo("64-crossing", Vector3(78, -216, -215))
	check(await swim(Vector3(104, -201, -215), 12, false, false), "Drop off bridge into interior")
	check(
		await swim(Vector3(78, -218, -222), 12, false, false),
		"Interior descent finds sheltered garden"
	)
	observations.journey_seconds = game.model.elapsed
	record_sequence = false
	if gpu:
		var frames := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		frames.store_string(JSON.stringify(sequence, "  "))
		frames.close()
	# Same junction, two legitimate exits. These are bounded branch fixtures.
	for outside in [false, true]:
		fixture(Vector3(131, -182, -209))
		await tick()
		var destination := Vector3(162, -203, -193) if outside else Vector3(105, -209, -194)
		check(await swim(destination, 15, false, false), "Cross-cut permits inside/outside choice")
		observations["outside_seconds" if outside else "inside_seconds"] = game.model.elapsed


func collisions() -> void:
	fixture(Vector3(67, -164, -149))
	for frame in range(60):
		await tick()
	for frame in range(180):
		await tick(Vector2(0, 1))
	print("Uphill position: ", game.model.position)
	check(game.model.position.y > -161, "Terrace ramps can also be walked back up without Space")
	# Actual capsule trajectories against top, sides and underside, at 60/15Hz.
	for rate in [60, 15]:
		for fast in [false, true]:
			fixture(Vector3(67, -154, -136))
			for frame in range(rate * 2):
				game.advance(1.0 / rate, Vector2.ZERO, 1 if fast else 0, false)
			check(game.model.standing, "Normal/fast landing at %dHz" % rate)
			check(game.model.position.y > -160.1, "Terrace top never tunnels")
		fixture(Vector3(100, -198, -192.2))
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
		print("Bridge ascent: ", game.model.position)
		check(game.model.position.y < -185.5, "Space is blocked by the eroded bridge underside")
		fixture(Vector3(100, -198, -194))
		var touched := false
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
			if not game.motion.contact_bodies.is_empty():
				touched = true
		check(touched, "Off-centre ascent contacts the curved underside before sliding off")
		fixture(Vector3(82, -169, -136))
		for frame in range(rate):
			game.advance(1.0 / rate, Vector2(-1, 0), 0, false)
		check(game.model.position.x > 73, "Side wall blocks horizontal capsule")


func oxygen_choices() -> void:
	for oxygen in [30, 100]:
		for bridge in [false, true]:
			fixture(Vector3(87, -177, -206))
			game.model.oxygen = oxygen
			var target: Vector3 = Gardens.PLANTS[6] if bridge else Gardens.PLANTS[7]
			var arrived := true
			if bridge:
				arrived = await swim(Vector3(100, -179, -194), 15, false, false)
			if arrived:
				arrived = await swim(target, 15, false, false)
			observations["oxygen_%d_bridge_%s" % [oxygen, bridge]] = {
				"arrived": arrived, "seconds": game.model.elapsed, "oxygen": game.model.oxygen
			}
			check(arrived or oxygen == 30, "Both branches remain available with full oxygen")
			if arrived:
				check(game.model.oxygen == 100, "Arrival reaches the real oxygen volume")
	check(observations.oxygen_30_bridge_true.arrived, "Low oxygen permits the upper refuge")
	check(not observations.oxygen_30_bridge_false.arrived, "Low oxygen makes further depth risky")
