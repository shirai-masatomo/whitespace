extends "res://tests/test_discovery.gd"
const Reef = preload("res://game/playground_rules.gd")


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	sequence_limit_seconds = 200
	capture_root = "res://artifacts/playground-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	check(await swim(Reef.PLANTS[0]), "The distant shallow reef is reachable from the pier")
	await photo("44-kelp-reef-arrival", Vector3(58, -26, -50))
	for frame in range(30):
		await tick()
	check(game.model.terrain_grounded, "Scenic reef is real standing terrain")
	var start: Vector3 = game.model.position
	for frame in range(120):
		await tick(Vector2.RIGHT)
	check(game.model.position.x - start.x > 10, "Walk horizontally across continuous reef")
	check(game.model.terrain_grounded, "Walking keeps terrain support")
	await photo("45-reef-walking", Reef.CAVE_START)
	check(await swim(Vector3(61, -29, -38)), "Choose the rim rather than falling into the shaft")
	check(await swim(Vector3(61, -32, -66)), "Walk around the open shaft")
	check(await swim(Reef.PLANTS[1]), "A second garden lies across the reef, not directly below")
	check(await swim(Vector3(49, -31, -50)), "Find the shaft in the reef")
	check(await swim(Vector3(49, -50, -50)), "Dive through the real opening")
	check(await swim(Vector3(63, -52, -42)), "Approach the open mouth from outside")
	check(await swim(Reef.PLANTS[2]), "Dive under the reef to the cavern mouth")
	await photo("46-cavern-mouth", Vector3(96, -37, -48))
	check(await swim(Vector3(84, -43, -43)), "Enter and rise inside the cave")
	check(await swim(Vector3(99, -42, -48)), "Swim into the interior air chamber")
	for frame in range(90):
		await tick()
	check(game.model.in_dry_cave(), "Air exists within the cave, not on a menu")
	check(game.model.terrain_grounded, "Player can stand inside the cavern")
	check(game.model.oxygen == 100, "Air chamber permits route planning without oxygen loss")
	await photo("47-air-cave", Reef.CAVE_END)
	start = game.model.position
	for frame in range(70):
		await tick(Vector2.RIGHT)
	check(game.model.position.x - start.x > 5, "Walk inside before diving again")
	check(await swim(Reef.PLANTS[3]), "Leave through a different underwater exit")
	check(not game.model.in_dry_cave(), "Water movement resumes outside")
	await photo("48-other-exit", Vector3(45, -100, -60))
	observations.cavern_journey_seconds = game.model.elapsed
	observations.horizontal_extent = game.model.position.x
	record_sequence = false
	await compare_spaces()
	await audit_surfaces()
	var file := FileAccess.open("res://artifacts/playground.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify({"checks": checks, "failed": failed, "observations": observations}, "  ")
	)
	file.close()
	if gpu:
		file = FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(sequence, "  "))
		file.close()
	game.queue_free()
	await process_frame
	print("Playground: %d checks, failed=%s, %s" % [checks, failed, observations])
	quit(1 if failed else 0)


func compare_spaces() -> void:
	check(
		not Reef.air_at(Vector3(80, -26, -35)),
		"Outside the curved ceiling is water, not box-shaped free oxygen"
	)
	check(not Reef.air_at(Vector3(94, -30, -65)), "Outside the side wall remains underwater")
	# These alternate journeys start at the already reached garden. Fixture setup
	# is separate from the continuous pier-to-cave recording.
	for route in ["roof", "outside", "outside_fast", "reverse"]:
		fixture(Reef.PLANTS[1] + Vector3.UP * 2)
		var complete := true
		var points: Array[Vector3] = []
		if route == "roof":
			points = [Vector3(85, -20, -66), Vector3(104, -28, -48)]
		elif route.begins_with("outside"):
			points = [
				Vector3(87, -48, -82),
				Vector3(119, -60, -87),
				Vector3(143, -61, -70),
				Reef.PLANTS[3]
			]
		else:
			fixture(Reef.PLANTS[3] + Vector3.UP)
			points = [Vector3(125, -53, -62), Vector3(114, -42, -49), Vector3(99, -42, -48)]
		for point in points:
			complete = await swim(point, 25, route == "outside") and complete
			if not complete:
				break
		if route == "outside_fast":
			check(
				game.model.oxygen == 0 and game.model.mode == game.model.Mode.RETURNING,
				"Repeated fast dives exhaust oxygen before the outer refuge"
			)
		else:
			check(complete, "Alternate approach: " + route)
		if route == "roof":
			for frame in range(90):
				await tick()
			check(game.model.terrain_grounded, "The visible cavern roof is a usable destination")
		if route == "reverse":
			check(game.model.in_dry_cave(), "The refuge is reachable from either mouth")
		observations[route] = {
			"complete": complete, "seconds": game.model.elapsed, "oxygen": game.model.oxygen
		}
		await photo("49-" + route, Vector3(95, -42, -48) if route != "reverse" else Reef.CAVE_START)


func audit_surfaces() -> void:
	# Ray positions locate actual visible geometry; every assertion is then made
	# with player movement and its swept capsule, including coarse physics steps.
	var surfaces := [
		["reef top", Vector3(37, -18, -27), Vector3(37, -42, -27)],
		["reef underside", Vector3(37, -54, -27), Vector3(37, -25, -27)],
		["reef side", Vector3(8, -34, -40), Vector3(42, -34, -40)],
		["cave roof", Vector3(104, -14, -48), Vector3(104, -40, -48)],
		["cave side", Vector3(104, -40, -90), Vector3(104, -40, -48)],
		["cave underside", Vector3(104, -76, -48), Vector3(104, -40, -48)]
	]
	for surface in surfaces:
		var direction: Vector3 = (surface[2] - surface[1]).normalized()
		var ray := PhysicsRayQueryParameters3D.create(surface[1], surface[2], 1)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(), "Visible solid: " + surface[0])
		if hit.is_empty():
			continue
		for dt in [1.0 / 60, 1.0 / 15]:
			fixture(hit.position - direction * 2.5 - Vector3.UP * 1.05)
			game.model.velocity = direction * 15
			var touched := false
			for frame in range(int(1.5 / dt)):
				game.advance(dt, Vector2(direction.x, direction.z), 1, direction.y > .1)
				if game.motion.contact_bodies.has(hit.collider):
					touched = true
					break
			check(touched, "Actual player contact: %s dt=%s" % [surface[0], dt])
			check(
				(game.model.position + Vector3.UP * 1.05 - hit.position).dot(direction) < .5,
				"No tunnelling: %s dt=%s" % [surface[0], dt]
			)
