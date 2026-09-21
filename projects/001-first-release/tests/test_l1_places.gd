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
	fixture(Vector3(-3, -37, -89))
	await photo("l1-p1-bay", Vector3(28, -60, -119))
	fixture(Vector3(-18, -43, -84))
	check(await swim(Vector3(-16, -41, -105), 15), "Leave the algae garden toward the upper bridge")
	check(await swim(Vector3(0, -41, -112), 12), "The raised bed is reachable from the terrace")
	var walking := 0
	for frame in range(600):
		var difference := Vector2(24 - game.model.position.x, -118 - game.model.position.z)
		if difference.length() < 3:
			break
		await tick((difference / 3).limit_length())
		if game.model.standing:
			walking += 1
	check(
		game.model.position.x > 21 and walking > 90,
		"Walk across the upper bed without Space, instead of descending to a nearby rock"
	)
	fixture(Vector3(8, -62, -103))
	check(await swim(Vector3(30, -67, -115), 15), "Explore the hollow below the displaced bridge")
	check(await swim(Vector3(52, -78, -127), 15), "Lateral current has an open passage")
	check(game.model.setbacks == 0, "The bay detour does not require rescue")
	fixture(Vector3(30, -67, -115))
	var start: Vector3 = game.model.position
	for frame in range(180):
		await tick()
	check(game.model.position.x > start.x + 5, "The bay current carries a resting swimmer sideways")
	check(await swim(Vector3(25, -78, -99), 12), "Horizontal input can leave the optional current")
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
	for probe in [Vector3(24, -20, -118), Vector3(-42, -126, -126), Vector3(84, -280, -140)]:
		for fast_drop in [0.0, 1.0]:
			fixture(probe)
			var touched := false
			for frame in range(600):
				await tick(Vector2.ZERO, fast_drop)
				for body in game.motion.contact_bodies:
					if str(body.get_path()).contains("FaultedCoast"):
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
