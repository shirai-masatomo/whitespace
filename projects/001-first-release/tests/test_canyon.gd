extends "res://tests/test_discovery.gd"
## Fixed player-camera comparisons; fixtures are not claims of a complete route.
const Gardens = preload("res://game/playground_rules.gd")
var follow_heading := false
var minimum_oxygen := 100.0


func tick(axis: Vector2 = Vector2.ZERO, descent: float = 0, ascend: bool = false) -> void:
	if follow_heading:
		if axis.length() > .1:
			game.yaw = lerp_angle(game.yaw, atan2(-axis.x, -axis.y), .035)
		var local := Vector3(axis.x, 0, axis.y).rotated(Vector3.UP, -game.yaw)
		game.advance(1.0 / 60, Vector2(local.x, local.z), descent, ascend)
		if gpu:
			await render_step()
	else:
		await super.tick(axis, descent, ascend)
	minimum_oxygen = minf(minimum_oxygen, game.model.oxygen)


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
	await terrace_choices()
	await oxygen_choices()
	await collisions()
	await wildlife_detour()
	await wildlife_entrance()
	await early_return_choice()
	wildlife_clearance()
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
	game.pitch = -.35
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
			if gpu:
				await capture("72-walking-view")
			await photo("67-rock-steps", Vector3(67, -176, -174))
			game.pitch = -.35
	check(game.model.position.z < -178, "Walking reaches the collapsed terrace")
	check(game.model.position.z > -185, "Blind forward input cannot walk through the far rock lip")
	check(walking_frames < 530, "The collapsed terrace interrupts ground contact")
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


func terrace_choices() -> void:
	for shelf in [true, false]:
		fixture(Vector3(67, -171, -165))
		game.pitch = -.35
		for frame in range(30):
			await tick()
		var targets := [Vector3(63, -172, -167), Vector3(63, -178, -184), Vector3(67, -178, -188)]
		if not shelf:
			targets = [Vector3(67, -175, -184), Vector3(67, -178, -188)]
		var grounded_frames := 0
		var swimming_frames := 0
		var ascent_frames := 0
		var reached := 0
		for target in targets:
			for frame in range(600):
				var offset: Vector3 = target - game.model.position
				if Vector2(offset.x, offset.z).length() < .75:
					reached += 1
					break
				var axis := (Vector2(offset.x, offset.z) / 2).limit_length()
				var ascend: bool = not shelf and offset.y > 1
				await tick(axis, 0, ascend)
				if ascend:
					ascent_frames += 1
				if game.model.standing:
					grounded_frames += 1
				else:
					swimming_frames += 1
				if gpu and frame == 80 and reached == (1 if shelf else 0):
					await capture("73-ledge-walk" if shelf else "74-swim-break")
		check(reached == targets.size(), "Terrace choice reaches the far side")
		observations["terrace_shelf" if shelf else "terrace_swim"] = {
			"walking_frames": grounded_frames,
			"swimming_frames": swimming_frames,
			"ascent_frames": ascent_frames,
			"seconds": game.model.elapsed,
			"oxygen": game.model.oxygen,
			"position": var_to_str(game.model.position)
		}
		if shelf:
			check(
				ascent_frames == 0 and grounded_frames > swimming_frames * 3,
				"Wall-side ledge can be walked without Space"
			)
		else:
			check(
				swimming_frames > 30 and ascent_frames > 15,
				"Crossing the break changes body state and needs ascent correction"
			)


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
		fixture(Vector3(67, -182, -176))
		var fracture_contact := false
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2(0, -1), 0, false)
			for body in game.motion.contact_bodies:
				fracture_contact = fracture_contact or "WestTerraces" in str(body.get_path())
		check(
			game.model.position.z > -185 and fracture_contact,
			"The far fracture face blocks three seconds of real forward swimming"
		)
		fixture(Vector3(67, -178, -176))
		for frame in range(rate):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
		check(game.model.position.y > -174, "The visible fracture is open to Space ascent")
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


func wildlife_detour() -> void:
	# From the existing bridge refuge, observe offshore wildlife and return.
	# No refill, collectible or unlock is added to this optional place.
	for oxygen in [35, 100]:
		fixture(Gardens.PLANTS[6] + Vector3(4.5, 2, 0))
		game.model.oxygen = oxygen
		var arrived := await swim(Vector3(131, -178, -211), 12, false, false)
		if arrived:
			arrived = await swim(Vector3(149, -187, -210), 10, false, false)
		if arrived:
			await photo("70-tidal-window", Vector3(176, -204, -192))
			arrived = await swim(Vector3(171, -202, -194), 10, false, false)
		var outside_oxygen: float = game.model.oxygen
		var returned := false
		if arrived:
			await photo("71-offshore-wildlife", Vector3(176, -207, -196))
			returned = await swim(Vector3(149, -185, -210), 12, false, false)
			if returned:
				returned = await swim(Vector3(131, -178, -211), 12, false, false)
			if returned:
				returned = await swim(Gardens.PLANTS[6], 12, false, false)
		observations["wildlife_%d" % oxygen] = {
			"arrived": arrived,
			"returned": returned,
			"outside_oxygen": outside_oxygen,
			"seconds": game.model.elapsed
		}
		if oxygen == 100:
			check(
				arrived and returned,
				"Optional wildlife lookout and return are physically reachable"
			)
			check(outside_oxygen < 80, "Wildlife detour consumes oxygen; not another refill point")
			check(game.model.oxygen == 100, "Return actually reaches the original algae")
	check(
		not observations.wildlife_35.returned, "Low oxygen makes staying at the refuge meaningful"
	)
	# Real capsule contact with the newly shaped wall, not a mesh-point comparison.
	for rate in [60, 15]:
		fixture(Vector3(70, -188, -152))
		var touched := false
		for frame in range(rate * 5):
			game.advance(1.0 / rate, Vector2.LEFT, 0, false)
			for body in game.motion.contact_bodies:
				if "StratifiedWest" in str(body.get_path()):
					touched = true
		check(touched, "Lateral movement meets the visible stratified wall at %dHz" % rate)


func wildlife_clearance() -> void:
	# A moving clue must not suggest passing through solid geology.
	var life = game.world.life
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var hits := 0
	for frame in range(1, 241):
		var time := frame * 49.0 / 240
		var previous: Vector3 = life.canyon_passage(time - 49.0 / 240)
		var current: Vector3 = life.canyon_passage(time)
		var heading := (current - previous).normalized()
		var across := Vector3(-heading.z, 0, heading.x)
		for wing in [-7, 0, 7]:
			var query := PhysicsRayQueryParameters3D.create(
				previous + across * wing, current + across * wing, 1
			)
			if not space.intersect_ray(query).is_empty():
				hits += 1
				print("Wildlife wall sample: ", time, " ", space.intersect_ray(query))
	observations.wildlife_wall_crossings = hits
	check(hits == 0, "Wildlife centre and wing corridors never cross solid cliff faces")


func wildlife_entrance() -> void:
	fixture(Gardens.PLANTS[6] + Vector3(4.5, 2, 0))
	game.pitch = -.35
	follow_heading = true
	minimum_oxygen = 100
	var old_root := capture_root
	capture_root += "/lower-entrance"
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	sequence.clear()
	simulation_frames = 0
	record_sequence = true
	var arrived := true
	for point in [
		Vector3(131, -178, -211),
		Vector3(149, -187, -210),
		Vector3(166, -200, -207),
		Vector3(145, -216, -210),
		Vector3(117, -217, -220),
		Gardens.PLANTS[7]
	]:
		if arrived:
			arrived = await swim(point, 15, false, false)
			if point.x == 145 and gpu:
				await capture("75-lower-entrance")
	check(
		arrived and game.model.oxygen == 100,
		"Offshore detour can continue through a lower entrance to the next garden"
	)
	observations.wildlife_lower_entrance = {
		"arrived": arrived, "seconds": game.model.elapsed, "minimum_oxygen": minimum_oxygen
	}
	if gpu:
		var file := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(sequence, "  "))
		file.close()
	capture_root = old_root
	record_sequence = false
	follow_heading = false


func early_return_choice() -> void:
	for outside in [false, true]:
		fixture(Gardens.PLANTS[6] + Vector3(4.5, 2, 0))
		game.model.oxygen = 80
		minimum_oxygen = 80
		var targets := [Vector3(131, -178, -211)]
		if outside:
			targets.append_array(
				[Vector3(149, -187, -210), Vector3(166, -200, -207), Vector3(145, -216, -210)]
			)
		targets.append_array([Vector3(117, -217, -220), Gardens.PLANTS[7]])
		var arrived := true
		for target in targets:
			if arrived:
				arrived = await swim(target, 15, false, false)
		observations["early_inside_80" if not outside else "full_outside_80"] = {
			"arrived": arrived, "seconds": game.model.elapsed, "minimum_oxygen": minimum_oxygen
		}
		check(
			arrived != outside, "At 80% oxygen the early inside descent is safer than the full loop"
		)
		if outside:
			check(
				game.model.mode == Model.Mode.RETURNING,
				"The long 80% route ends in seamless rescue, not a blocked-controller timeout"
			)
