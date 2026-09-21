extends "res://tests/test_discovery.gd"
## Requested phase views: ordinary chase camera, local input journeys, no survey camera.


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/l1-views"
	DirAccess.make_dir_recursive_absolute(capture_root)
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	check(await swim(Vector3(8, -7, -18), 12, false, false), "Enter water from the pier")
	await normal_view("p1-entry", 0, -.25)
	check(await swim(Vector3(12, -29, -28), 12, false, false), "Reach the first headland")
	await normal_view("p1-choice", -.2, -.25)
	fixture(Vector3(3, -28, -49))
	check(
		await swim(Vector3(-9, -31, -64), 10), "Fish window can be entered from the first headland"
	)
	check(await swim(Vector3(-11, -34, -75), 8), "Pass through the rock window toward the garden")
	# Local starts keep captures inexpensive; these are not a claimed complete run.
	fixture(Vector3(0, -154, -62))
	check(await swim(Vector3(-9, -159, -73), 8), "Approach the cliff from open water")
	await normal_view("p2-coast", .65, -.42)
	fixture(Vector3(-49, -188, -102))
	check(await swim(Vector3(-55, -189, -106), 6), "Explore the middle shelf beside the cliff")
	await normal_view("p2-inside", -.7, -.3)
	var walking := 0
	var joined_contacts := 0
	for frame in range(240):
		# Follow the exposed lip around the cliff, rather than steer into its rock face.
		var difference := Vector2(-46 - game.model.position.x, -96 - game.model.position.z)
		await tick((difference / 3).limit_length())
		if game.model.standing:
			walking += 1
		for body in game.motion.contact_bodies:
			if str(body.get_path()).contains("JoinedTerraces"):
				joined_contacts += 1
	check(
		walking > 120 and joined_contacts > 30 and game.model.position.z > -98,
		"Walk from the old shelf into the joined cliff bed"
	)
	print(
		"Shelf walk ", game.model.position, " standing/bed contacts ", walking, "/", joined_contacts
	)
	fixture(Vector3(-53, -209, -107))
	check(await swim(Vector3(-55, -209, -97), 8), "Swim between the upper and recessed beds")
	fixture(Vector3(5, -449, -109))
	check(await swim(Vector3(17, -450, -109), 6), "Cross the seabed toward the sand drift")
	await normal_view("p4-seabed", -.65, -.25)
	check(await swim(Vector3(38, -452, -117), 9), "Follow the current to the fissure")
	await normal_view("g-crevice", 0, -.55)
	check(await swim(Vector3(38, -472, -133), 12), "Enter the deeper passage")
	game.queue_free()
	await process_frame
	print("L1 review input: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)


func normal_view(label: String, heading: float, elevation: float) -> void:
	game.yaw = heading
	game.pitch = elevation
	game.third_person = true
	if gpu:
		await capture(label)
	print(label, " position=", game.model.position, " yaw=", heading, " pitch=", elevation)
