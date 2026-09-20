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
	# Inspect the actual starting view as well as deliberately aimed comparisons.
	# This journey uses W only, with no mouse/camera changes or target steering.
	record_sequence = false
	if gpu:
		await capture("68-default-pier")
	for frame in range(600):
		await tick(Vector2(0, -1))
		if game.model.depth > 5:
			break
	check(game.model.depth > 5, "Straight forward input enters the ocean")
	var entry_start: Vector3 = game.model.position
	if gpu:
		await capture("69-default-entry")
	game.restart()
	simulation_frames = 0
	record_sequence = true
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
	check(game.camera.position.y < -1.4, "Camera joins the submerged swimmer after entry")
	await photo("52-surface-light", game.model.position + Vector3(3, 16, -18))
	check(await swim(Vector3(32, -28, -25)), "The shoal's destination is actually reachable")
	await photo("53-kelp-from-sea", Vector3(53, -20, -50))
	var guide: Node3D = game.world.life.reef_guide
	game.world.life.update(Vector3(500, 0, 500), 0)
	var first: Vector3 = guide.position
	game.world.life.update(Vector3(500, 0, 500), PI / .2)
	check(guide.position.x - first.x > 20, "Fish movement leads sideways into the reef")
	var turn_max := 0.0
	var previous_yaw := guide.rotation.y
	var wall_hits := 0
	for sample in range(1, 316):
		var time := sample * .1
		game.world.life.update(Vector3(500, 0, 500), time)
		if sample > 1:
			turn_max = maxf(turn_max, absf(angle_difference(previous_yaw, guide.rotation.y)))
		previous_yaw = guide.rotation.y
		var query := PhysicsRayQueryParameters3D.create(
			game.world.life.reef_passage(time - .1), guide.position, 1
		)
		if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			wall_hits += 1
	check(turn_max < .08, "The shoal bends continuously through its return rather than flipping")
	check(wall_hits == 0, "The shoal's new return centreline stays outside solid reef")
	observations.shoal_max_turn_degrees_per_tenth = rad_to_deg(turn_max)
	observations.shoal_wall_crossings = wall_hits
	check(game.model.oxygen == 100, "Exploration reaches the living oxygen refuge")
	await photo("65-cleft-choice", Vector3(40, -34, -45))
	check(
		await swim(Vector3(30, -32, -41), 12, false, false),
		"Leave the garden sideways into the cleft"
	)
	check(
		await swim(Vector3(32, -38, -42), 12, false, false),
		"Swim inside the reef instead of hopping between rocks"
	)
	await photo("66-inside-reef-cleft", Vector3(49, -39, -50))
	check(
		await swim(Vector3(49, -40, -50), 12, false, false), "The lateral opening joins the shaft"
	)
	var journey_seconds: float = game.model.elapsed
	record_sequence = false
	for oxygen in [10, 20, 100]:
		for bubble in [false, true]:
			fixture(entry_start)
			game.model.oxygen = oxygen
			var target: Vector3 = Places.bubbles(0)[0].center if bubble else Vector3(32, -28.2, -25)
			var arrived := await reach_oxygen(target)
			observations["oxygen_%d_bubble_%s" % [oxygen, bubble]] = {
				"arrived": arrived, "seconds": game.model.elapsed, "oxygen": game.model.oxygen
			}
			check(arrived or oxygen < 100, "Both initial destinations can be reached with full air")
	var file := FileAccess.open("res://artifacts/entry.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"checks": checks,
				"failed": failed,
				"seconds": journey_seconds,
				"choices": observations
			},
			"  "
		)
	)
	file.close()
	if gpu:
		file = FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(sequence, "  "))
		file.close()
	game.queue_free()
	await process_frame
	print("Entry: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)


func reach_oxygen(target: Vector3) -> bool:
	for frame in range(900):
		var offset: Vector3 = target - game.model.position
		await tick((Vector2(offset.x, offset.z) / 4).limit_length(), 0, offset.y > 1)
		if game.model.mode != game.model.Mode.DIVING:
			return false
		if game.model.oxygen == 100:
			return true
	return false
