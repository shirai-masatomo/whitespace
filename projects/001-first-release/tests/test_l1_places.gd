extends "res://tests/test_discovery.gd"
## Focused input tests of the new lateral bay and the final converging current.
const Biology = preload("res://game/biology_layout.gd")


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/l1-places"
	DirAccess.make_dir_recursive_absolute(capture_root)
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	# The old 60m lateral ride is no longer an entry branch. Its replacement
	# becomes available at the P1/P2 threshold; validate actual drift and exit.
	check(
		Places.sample_path(Model.Layout.SHALLOW_RIDE, Vector3(30, -67, -115), 5.5).is_zero_approx(),
		"No obsolete shallow branch current"
	)
	fixture(Model.Layout.SHALLOW_RIDE[0])
	var start: Vector3 = game.model.position
	for frame in range(180):
		await tick()
	check(game.model.position.distance_to(start) > 8, "Transition flow carries the swimmer")
	check(await swim(Vector3(35, -139, -72), 12), "Input can leave the transition current")
	fixture(Vector3(18, -337, -64))
	await photo("l1-p3-faults", Vector3(-22, -379, -128))
	fixture(Vector3(25, -449, -109))
	await photo("l1-g-inflow", Biology.PATH[0])
	check(
		await swim(Vector3(38, -452, -115), 12),
		"The basin leads around the shoulder to its low point"
	)
	check(
		await swim(Vector3(38, -472, -133), 15),
		"Swim into the sole crevice against no invisible floor"
	)
	check(game.model.flow_at(Vector3(38, -465, -133)).y < 0, "Crevice current pulls down into L2")
	check(game.model.position.y < -465, "Reach below the real-layer seabed")
	fixture(Vector3(38, -465, -133))
	check(await swim(Vector3(38, -453, -123), 15), "Space can escape the gate current")
	for probe in [
		Vector3(64, -115, -128),
		Vector3(-42, -126, -126),
		Vector3(-46, -126, -126),
		Vector3(84, -280, -140)
	]:
		# Erosion exposes the headland at the old x=-42 sample; the fault starts at x=-46.
		var expected := "ShallowHeadland" if probe.x == -42 else "FaultedCoast"
		for fast_drop in [0.0, 1.0]:
			fixture(probe)
			var touched := false
			for frame in range(600):
				await tick(Vector2.ZERO, fast_drop)
				for body in game.motion.contact_bodies:
					if str(body.get_path()).contains(expected):
						touched = true
				if touched:
					break
			if not touched:
				print("Missed fault: ", game.model.position)
				for body in game.motion.contact_bodies:
					print(body.get_path())
			check(
				touched,
				"Actual capsule lands on displaced strata at %s fast=%s" % [probe, fast_drop]
			)
	for x in [-160.0, 140.0]:
		check(
			Biology.sand_height(x, -133) > -410,
			"The outer seabed rises instead of competing with the gate"
		)
	game.queue_free()
	await process_frame
	print("L1 places: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)
