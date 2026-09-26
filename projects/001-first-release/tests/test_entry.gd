extends "res://tests/test_discovery.gd"
## Current P0/P1 journey: sequential landmarks, then the first two destinations.


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/intro"
	DirAccess.make_dir_recursive_absolute(capture_root)
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	var entry_seen := false
	for target in [1, 2, 3, 4]:
		var arrived := false
		for frame in range(1800):
			var command := Driver.input_for(game.model, target)
			await tick(Vector2(command.x, command.z), command.y)
			if not entry_seen and game.model.depth > 7:
				entry_seen = true
				await capture("intro-entry")
			if Driver.arrived(game.model, target):
				arrived = true
				break
			if game.model.mode == Model.Mode.RETURNING:
				break
		check(arrived, "Sequential introduction reaches %d at %s" % [target, game.model.position])
		if not arrived:
			break
	check(game.model.setbacks == 0, "The introduction needs no forced rescue")
	var junction: Vector3 = game.model.position
	await capture("intro-transition")
	check(junction.y < -115, "Choices open after the shallow introduction")
	check(game.model.garden_at(Vector3(27, -30, -31)) < 0, "No obsolete entry-side oxygen lure")
	check(not Places.breathing(Vector3(-15, -20, -32), 0), "No obsolete entry-side air pocket")
	fixture(Vector3(99, -42, -48))
	check(not game.model.in_dry_cave(), "Relocated cave leaves no invisible air in the shallows")
	fixture(junction)
	var garden: Vector3 = game.world.authored.gardens()[0]
	check(
		await swim(Vector3(61, -127, -61), 10, false, false),
		"Swim above the reef lip before landing"
	)
	check(
		await swim(garden + Vector3.UP, 20, false, false),
		"First choice reaches the reef-side garden"
	)
	check(game.model.oxygen == 100, "The moved visible garden really refills")
	fixture(junction)
	check(
		await swim(Places.bubbles(0)[0].center, 22, false, false),
		"Other choice reaches the cliff-side air pocket"
	)
	check(game.model.in_air_pocket(), "The cliff-side destination provides real air")
	print("Intro: %d checks, failed=%s, junction=%s" % [checks, failed, junction])
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
