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
	var authored := "--remnant-authored" in OS.get_cmdline_user_args()
	if authored:
		capture_root += "-authored"
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
	if "--cove-only" in OS.get_cmdline_user_args():
		capture_root = "res://artifacts/cove-" + RenderingServer.get_current_rendering_method()
		DirAccess.make_dir_recursive_absolute(capture_root)
		await cove_exploration()
		await cove_window_routes()
		await cove_current_control()
		await current_choices()
		await current_detours()
		await continuous_current_choices()
		await finish("cove")
		return
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
	await remnant_contacts()
	await cleft_passage()
	await wildlife_detour()
	await wildlife_entrance()
	await early_return_choice()
	await cove_exploration()
	await cove_window_routes()
	await cove_current_control()
	await current_choices()
	await current_detours()
	await continuous_current_choices()
	wildlife_clearance()
	var output := "canyon-authored" if authored else "canyon"
	await finish(output)


func finish(output: String) -> void:
	var file := FileAccess.open("res://artifacts/" + output + ".json", FileAccess.WRITE)
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
	check(walking_frames > 300, "Walking rhythm replaces continuous swimming")
	observations.walking_frames = walking_frames
	observations.terrace_end = var_to_str(game.model.position)
	await photo("63-walk-terrace", Vector3(119, -182, -194))
	check(await swim(Vector3(67, -173, -182), 12, false, false), "Rise within the open cliff cut")
	check(await swim(Vector3(87, -166, -187), 12, false, false), "Swim over the shoulder lip")
	check(await swim(Vector3(100, -180, -194), 12, false, false), "Shoulder to observation shelf")
	check(
		await swim(Gardens.PLANTS[6], 15, false, false), "Observation shelf reaches oxygen garden"
	)
	await photo("64-crossing", Vector3(78, -216, -215))
	check(
		await swim(Vector3(104, -201, -215), 12, false, false), "Drop off promontory into interior"
	)
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
		if not outside:
			check(
				await swim(Vector3(120, -201, -214), 12, false, false),
				"Descend around the broken seaward tip"
			)
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
		print("Remnant ascent: ", game.model.position)
		check(game.model.position.y < -185.5, "Space is blocked by the eroded promontory underside")
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
				returned = await swim(Gardens.PLANTS[6] + Vector3.UP * 2, 12, false, false)
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
		Gardens.PLANTS[7] + Vector3.UP * 2
	]:
		if arrived:
			arrived = await swim(point, 15, false, false)
			if point.x == 145 and gpu:
				await capture("75-lower-entrance")
	check(
		arrived and game.model.oxygen == 100,
		"Offshore detour can continue through a lower entrance to the next garden"
	)
	for frame in range(60):
		await tick()
	check(
		game.model.standing and game.model.oxygen == 100,
		"Lower entrance finishes standing on the refuge, not refilling through its side"
	)
	if gpu:
		await capture("76-refuge-landing")
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
		targets.append_array([Vector3(117, -217, -220), Gardens.PLANTS[7] + Vector3.UP * 2])
		var arrived := true
		for target in targets:
			if arrived:
				arrived = await swim(target, 15, false, false)
		if arrived:
			for frame in range(60):
				await tick()
			check(
				game.model.standing and game.model.oxygen == 100,
				"Early return reaches the top of the algae shelf"
			)
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


func cleft_passage() -> void:
	fixture(Vector3(91, -181, -177))
	check(
		await swim(Vector3(89, -186, -194), 8, false, false), "Swim into the visible remnant cleft"
	)
	check(
		await swim(Vector3(89, -173, -194), 8, false, false),
		"Space rises through the cleft opening"
	)
	observations.cleft_seconds = game.model.elapsed
	observations.cleft_oxygen = game.model.oxygen


func remnant_contacts() -> void:
	for rate in [60, 15]:
		for fast in [false, true]:
			fixture(Vector3(100, -170, -192))
			for frame in range(rate * 3):
				game.advance(1.0 / rate, Vector2.ZERO, 1 if fast else 0, false)
			check(
				game.model.standing and game.model.position.y > -184,
				"Normal and E land on the new promontory at %dHz" % rate
			)
		fixture(Vector3(135, -182, -192))
		var touched := false
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.LEFT, 0, false)
			for body in game.motion.contact_bodies:
				if "StratifiedWest" in str(body.get_path()):
					touched = true
		print("Seaward contact: ", game.model.position, " ", game.motion.contact_bodies)
		check(touched, "The broken seaward face stops lateral movement at %dHz" % rate)
		fixture(Vector3(138, -176, -200))
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 1, false)
		print("Bay descent: ", game.model.position, " ", game.motion.contact_bodies)
		check(
			game.model.position.y < -198,
			"The visible east-shore opening permits a fast descent at %dHz" % rate
		)


func cove_exploration() -> void:
	fixture(Gardens.PLANTS[7] + Vector3.UP * 2)
	game.pitch = -.35
	for frame in range(60):
		await tick()
	var grounded := 0
	for frame in range(100):
		await tick(Vector2.RIGHT)
		if game.model.standing:
			grounded += 1
	check(grounded > 55, "The garden opens onto walkable ground beside the sinkhole")
	observations.cove_walk_grounded = grounded
	observations.cove_walk_end = var_to_str(game.model.position)
	if gpu:
		await capture("79-cove-normal-view")
	await photo("77-cove-shore", Vector3(90, -239, -241))
	check(
		await swim(Vector3(88, -246, -240), 12, false, false),
		"Leave the shore and dive inside the sinkhole"
	)
	observations.cove_dive_seconds = game.model.elapsed
	await photo("78-inside-cove", Vector3(121, -236, -237))
	check(
		await swim(Vector3(123, -236, -238), 12, false, false),
		"The sinkhole has a real offshore side opening"
	)
	observations.cove_exit_seconds = game.model.elapsed
	for rate in [60, 15]:
		for fast in [false, true]:
			fixture(Vector3(78, -210, -222))
			for frame in range(rate * 3):
				game.advance(1.0 / rate, Vector2.ZERO, 1 if fast else 0, false)
			check(
				game.model.standing and game.model.position.y > -222,
				"Normal and E land on the cove refuge at %dHz" % rate
			)
		fixture(Vector3(88, -230, -240))
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2.ZERO, 1, false)
		print("Cove fast descent: ", game.model.position, " ", game.motion.contact_bodies)
		check(game.model.position.y < -262, "Fast descent crosses the open hole at %dHz" % rate)
		fixture(Vector3(88, -230, -235))
		var touched := false
		for frame in range(rate * 3):
			game.advance(1.0 / rate, Vector2(0, 1), 0, false)
			for body in game.motion.contact_bodies:
				if "SunkenCove" in str(body.get_path()):
					touched = true
		check(touched, "Lateral input meets the visible cove inner bank at %dHz" % rate)
		fixture(Vector3(78, -259, -222))
		touched = false
		for frame in range(rate * 5):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
			for body in game.motion.contact_bodies:
				if "SunkenCove" in str(body.get_path()):
					touched = true
		check(
			touched and game.model.position.y < -224,
			"Space contacts the cove underside instead of entering the shore at %dHz" % rate
		)


func cove_window_routes() -> void:
	for variant in range(3):
		var over := variant == 1
		var low := variant == 2
		fixture(Gardens.PLANTS[7] + Vector3.UP * 2)
		game.pitch = -.35
		follow_heading = true
		minimum_oxygen = game.model.oxygen
		var save_sequence := variant == 0 and "/cove-" in capture_root
		if save_sequence:
			sequence.clear()
			simulation_frames = 0
			record_sequence = true
			DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
		var targets := [
			Vector3(88, -226, -230),
			Vector3(89, -241, -252),
			Vector3(91, -239, -267),
			Places.COVE_STREAM[1]
		]
		if over:
			targets = [Vector3(74, -219, -241), Vector3(61, -199, -257), Vector3(70, -204, -270)]
		var arrived := true
		for index in range(targets.size()):
			if arrived:
				arrived = await swim(targets[index], 12, not over and index == 3, false)
				if low and index == 0:
					# Compare the decision after leaving the plant's instant refill volume.
					game.model.oxygen = 80
				if not over and not low and index == 1 and gpu:
					await capture("80-window-approach")
		check(arrived, "The sea window permits %s travel" % ("above" if over else "through"))
		if over:
			for frame in range(60):
				await tick()
			check(game.model.standing, "The headland crown is an actual observation perch")
		if gpu and not low:
			await capture("82-window-crown" if over else "81-window-exit")
		observations["window_over" if over else ("window_through_80" if low else "window_through")] = {
			"arrived": arrived, "seconds": game.model.elapsed, "minimum_oxygen": minimum_oxygen
		}
		if not over and arrived:
			for index in range(2, Places.COVE_STREAM.size()):
				if arrived:
					arrived = await swim(Places.COVE_STREAM[index], 15, true, false)
			if arrived:
				arrived = await swim(
					game.model.platforms[16].position + Vector3.UP, 10, false, false
				)
			if arrived:
				for frame in range(180):
					var difference: Vector3 = (
						game.model.platforms[16].position - game.model.position
					)
					await tick(
						(Vector2(difference.x, difference.z) / 3).limit_length(),
						0,
						difference.y > 1
					)
					if game.model.oxygen == 100 or game.model.mode != Model.Mode.DIVING:
						break
			check(
				(arrived and game.model.oxygen == 100) != low,
				"Full oxygen permits the current crossing, while 80 percent requires a shorter choice"
			)
			if low:
				check(
					game.model.mode == Model.Mode.RETURNING,
					"The low-oxygen detour ends in seamless rescue"
				)
			observations["cove_rejoin_80" if low else "cove_rejoin"] = {
				"arrived": arrived, "seconds": game.model.elapsed, "minimum_oxygen": minimum_oxygen
			}
			if gpu and not low:
				await capture("83-current-rejoins-reef")
		if save_sequence:
			record_sequence = false
			if gpu:
				var file := FileAccess.open(
					capture_root + "/sequence/frames.json", FileAccess.WRITE
				)
				file.store_string(JSON.stringify(sequence, "  "))
				file.close()
		follow_heading = false
	for rate in [60, 15]:
		fixture(Vector3(89, -242, -267))
		var touched := false
		for frame in range(rate * 4):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
			for body in game.motion.contact_bodies:
				if "SunkenCove" in str(body.get_path()):
					touched = true
		check(
			touched and game.model.position.y < -223,
			"Space meets the sea window roof at %dHz" % rate
		)


func cove_current_control() -> void:
	game.model.config = game.model.config.duplicate()
	var speed: float = game.model.config.cove_stream_speed
	var origin := Places.COVE_STREAM[2].lerp(Places.COVE_STREAM[3], .25)
	for enabled in [false, true]:
		fixture(origin)
		game.model.config.cove_stream_speed = speed if enabled else 0.0
		for frame in range(120):
			await tick()
		observations["cove_flow_on" if enabled else "cove_flow_off"] = {
			"position": var_to_str(game.model.position),
			"distance": origin.distance_to(game.model.position)
		}
		if enabled:
			check(
				game.model.position.z > origin.z + 25,
				"A passive swimmer actually rides the returning current"
			)
			for frame in range(180):
				await tick(Vector2.RIGHT)
			check(
				Places.sample_path(Places.COVE_STREAM, game.model.position, speed).length() < 1,
				"Horizontal input can leave the fast current"
			)
	game.model.config.cove_stream_speed = speed
	var hits := 0
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for index in range(Places.COVE_STREAM.size() - 1):
		var query := PhysicsRayQueryParameters3D.create(
			Places.COVE_STREAM[index], Places.COVE_STREAM[index + 1], 1
		)
		if not space.intersect_ray(query).is_empty():
			hits += 1
	check(hits == 0, "The current centreline does not promise passage through solid terrain")
	observations.cove_current_wall_crossings = hits
	fixture(Vector3(88, -226, -230))
	game.model.oxygen = 80
	var returned := await swim(Gardens.PLANTS[7] + Vector3.UP, 8, false, false)
	for frame in range(60):
		await tick()
	check(
		returned and game.model.oxygen == 100,
		"At the 80 percent decision point, turning back to the cove algae is viable"
	)


func current_choices() -> void:
	var original: float = game.model.config.cove_stream_speed
	for speed in [18.0, 21.0, 24.0]:
		game.model.config.cove_stream_speed = speed
		for stage in [1, 2]:
			var origin: Vector3 = (
				Places.COVE_STREAM[2]
				if stage == 1
				else Places.COVE_STREAM[3].lerp(Places.COVE_STREAM[4], .5)
			)
			for mode in ["ride", "side", "space", "fast"]:
				fixture(origin)
				for frame in range(180):
					await tick(
						Vector2.LEFT if mode == "side" else Vector2.ZERO,
						1 if mode == "fast" else 0,
						mode == "space"
					)
				var influence := (
					Places.sample_path(Places.COVE_STREAM, game.model.position, speed).length()
				)
				observations["current_%d_%d_%s" % [speed, stage, mode]] = {
					"end": var_to_str(game.model.position),
					"oxygen": game.model.oxygen,
					"influence": influence
				}
				if mode != "ride":
					check(
						influence < 1,
						"The %d m/s current allows %s escape at segment %d" % [speed, mode, stage]
					)
	game.model.config.cove_stream_speed = original


func current_detours() -> void:
	# Real route continuations after leaving the flow, not empty-water exit checks.
	for stage in [1, 2]:
		fixture(
			(
				Places.COVE_STREAM[2]
				if stage == 1
				else Places.COVE_STREAM[3].lerp(Places.COVE_STREAM[4], .5)
			)
		)
		for frame in range(180):
			await tick(Vector2.ZERO if stage == 1 else Vector2.LEFT, 0, stage == 1)
		var targets := [
			Vector3(123, -236, -238),
			Vector3(112, -219, -222),
			Vector3(92, -219, -220),
			Gardens.PLANTS[7] + Vector3.UP
		]
		if stage == 2:
			targets = [Vector3(38, -244, -96), game.model.platforms[16].position + Vector3.UP]
		var arrived := true
		for target in targets:
			if arrived:
				arrived = await swim(target, 15, false, false)
		print(
			"Current detour ",
			stage,
			": ",
			arrived,
			" at ",
			game.model.position,
			" oxygen ",
			game.model.oxygen,
			" seconds ",
			game.model.elapsed
		)
		check(
			arrived and game.model.oxygen == 100,
			"Leaving current segment %d can reach an existing refuge" % stage
		)
		observations["current_detour_%d" % stage] = {
			"arrived": arrived, "oxygen": game.model.oxygen, "seconds": game.model.elapsed
		}


func continuous_current_choices() -> void:
	var original: float = game.model.config.cove_stream_speed
	# GPU captures only the selected speed; headless retains the alternatives.
	for speed in [24.0] if gpu else [18.0, 21.0, 24.0]:
		game.model.config.cove_stream_speed = speed
		for stage in [1, 2]:
			fixture(Gardens.PLANTS[7] + Vector3.UP * 2)
			minimum_oxygen = 100
			var entry := [
				Vector3(88, -226, -230),
				Vector3(89, -241, -252),
				Vector3(91, -239, -267),
				Places.COVE_STREAM[1],
				Places.COVE_STREAM[2]
			]
			if stage == 2:
				entry.append(Places.COVE_STREAM[3])
				entry.append(Places.COVE_STREAM[3].lerp(Places.COVE_STREAM[4], .5))
			var arrived := true
			for index in range(entry.size()):
				if arrived:
					arrived = await swim(entry[index], 15, index >= 3, false)
			check(
				arrived, "Continuous oxygen reaches the %d m/s stage %d decision" % [speed, stage]
			)
			var decision_air: float = game.model.oxygen
			if gpu:
				await photo(
					"91-current-return-choice" if stage == 1 else "92-current-rejoin-choice",
					Gardens.PLANTS[7] if stage == 1 else game.model.platforms[16].position
				)
			# Leave diagonally: a separate three-second vertical/sideways action
			# spent the oxygen needed for the last metres back to the refuge.
			var exits := [
				Vector3(123, -236, -238),
				Vector3(112, -219, -222),
				Vector3(92, -219, -220),
				Gardens.PLANTS[7] + Vector3.UP
			]
			if stage == 2:
				exits = [Vector3(38, -244, -96)]
			for target in exits:
				if arrived:
					arrived = await swim(target, 15, false, false)
			if stage == 2 and arrived:
				# The refuge moves; chase its current position until actual contact,
				# not an old waypoint within the generic three-metre arrival tolerance.
				for frame in range(600):
					if game.model.oxygen == 100 or game.model.mode != Model.Mode.DIVING:
						break
					var offset: Vector3 = (
						game.model.platforms[16].position + Vector3.UP - game.model.position
					)
					await tick((Vector2(offset.x, offset.z) / 2).limit_length(), 0, offset.y > .5)
			var result := {
				"arrived": arrived and game.model.oxygen == 100,
				"decision_oxygen": decision_air,
				"minimum_oxygen": minimum_oxygen,
				"seconds": game.model.elapsed,
				"end_oxygen": game.model.oxygen,
				"end": var_to_str(game.model.position)
			}
			observations["continuous_current_%d_%d" % [speed, stage]] = result
			print("Continuous current ", speed, "/", stage, ": ", result)
			if speed == 24:
				check(result.arrived, "Continuous current choice refills without oxygen reset")
			if gpu:
				await capture("93-return-contact" if stage == 1 else "94-rejoin-contact")
	game.model.config.cove_stream_speed = original
