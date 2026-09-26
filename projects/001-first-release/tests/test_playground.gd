extends "res://tests/test_discovery.gd"
const Reef = preload("res://game/playground_rules.gd")
var minimum_oxygen := 100.0


# Geometry fixture coordinates remain reef-local; all input and collision use
# the current authored world placement. This is a P2 excursion, not pier entry.
func fixture(point: Vector3) -> void:
	super.fixture(game.model.reef_frame * point)


func swim(
	point: Vector3, seconds: float = 25.0, riding: bool = false, allow_fast: bool = true
) -> bool:
	return await super.swim(game.model.reef_frame * point, seconds, riding, allow_fast)


func photo(label: String, target: Vector3) -> void:
	await super.photo(label, game.model.reef_frame * target)


func tick(axis: Vector2 = Vector2.ZERO, descent: float = 0, ascend: bool = false) -> void:
	await super.tick(axis, descent, ascend)
	minimum_oxygen = minf(minimum_oxygen, game.model.oxygen)


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
	fixture(Vector3(21, -17, -21))
	if "--loop-only" in OS.get_cmdline_user_args():
		record_sequence = false
		await compare_cavern_loop()
		print("Cavern loop: %d checks, failed=%s, %s" % [checks, failed, observations])
		game.queue_free()
		await process_frame
		quit(1 if failed else 0)
		return
	if "--updraft-only" in OS.get_cmdline_user_args():
		record_sequence = false
		await compare_updraft()
		game.queue_free()
		await process_frame
		quit(1 if failed else 0)
		return
	check(
		await swim(Reef.PLANTS[0], 25, false, false), "P2 reef is reachable from its entry approach"
	)
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
	await photo("54-cave-window", Vector3(85, -49, -61))
	start = game.model.position
	for frame in range(70):
		await tick(Vector2.RIGHT)
	check(game.model.position.x - start.x > 5, "Walk inside before diving again")
	check(await swim(Reef.PLANTS[3]), "Leave through a different underwater exit")
	check(not game.model.in_dry_cave(), "Water movement resumes outside")
	await photo("48-other-exit", Vector3(45, -100, -60))
	observations.cavern_journey_seconds = game.model.elapsed
	observations.horizontal_extent = game.model.position.x
	check(await swim(Vector3(144, -74, -80), 25, false, false), "Leave the cave into open water")
	check(
		await swim(Vector3(105, -94, -96), 25, false, false),
		"Choose a lateral descent after the cave"
	)
	check(
		await super.swim(game.model.garden_points[5] + Vector3.UP, 25, false, false),
		"The exploratory space reconnects to the deeper game"
	)
	observations.journey_to_deeper_route_seconds = game.model.elapsed
	record_sequence = false
	await compare_spaces()
	await audit_surfaces()
	await audit_garden_rescue()
	await compare_updraft()
	await compare_cavern_loop()
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
	for route in ["roof", "outside", "outside_fast", "window", "reverse"]:
		fixture(Reef.PLANTS[1] + Vector3.UP * 2)
		minimum_oxygen = 100
		var complete := true
		var points: Array[Vector3] = []
		if route == "roof":
			points = [Vector3(85, -20, -66), Vector3(104, -28, -48)]
		elif route == "window":
			points = [
				Vector3(77, -50, -66),
				Vector3(85, -50, -52),
				Vector3(94, -44, -44),
				Vector3(99, -42, -48)
			]
		elif route.begins_with("outside"):
			points = [
				Vector3(87, -48, -77),
				Vector3(119, -60, -80),
				Vector3(145, -61, -83),
				Vector3(145, -61, -65),
				Reef.PLANTS[3]
			]
		else:
			fixture(Reef.PLANTS[3] + Vector3.UP)
			points = [Vector3(125, -53, -62), Vector3(114, -42, -49), Vector3(99, -42, -48)]
		for point in points:
			complete = await swim(point, 25, false, route != "outside") and complete
			if not complete:
				break
		check(complete, "Alternate approach: " + route)
		if route == "roof":
			for frame in range(90):
				await tick()
			check(game.model.terrain_grounded, "The visible cavern roof is a usable destination")
		if route == "reverse":
			check(game.model.in_dry_cave(), "The refuge is reachable from either mouth")
		observations[route] = {
			"complete": complete,
			"seconds": game.model.elapsed,
			"oxygen": game.model.oxygen,
			"minimum_oxygen": minimum_oxygen
		}
		await photo("49-" + route, Vector3(95, -42, -48) if route != "reverse" else Reef.CAVE_START)
	check(
		observations.outside_fast.minimum_oxygen < observations.outside.minimum_oxygen - 5,
		"Fast descent spends more oxygen on the same clear outer route"
	)
	for route in ["window", "outside"]:
		fixture(Vector3(74, -44, -74))
		game.model.oxygen = 35
		var points: Array[Vector3] = [
			Vector3(77, -50, -66), Vector3(85, -50, -52), Vector3(99, -42, -48)
		]
		if route == "outside":
			points = [
				Vector3(87, -48, -77),
				Vector3(119, -60, -80),
				Vector3(145, -61, -83),
				Reef.PLANTS[3]
			]
		var complete := true
		for point in points:
			if not await swim(point, 25, false, false):
				complete = false
				break
		check(complete if route == "window" else not complete, "35% oxygen decision: " + route)
		observations["low_" + route] = {
			"complete": complete, "seconds": game.model.elapsed, "oxygen": game.model.oxygen
		}


func audit_surfaces() -> void:
	# Ray positions locate actual visible geometry; every assertion is then made
	# with player movement and its swept capsule, including coarse physics steps.
	var surfaces := [
		["reef top", Vector3(37, -18, -27), Vector3(37, -42, -27)],
		["reef underside", Vector3(37, -54, -27), Vector3(37, -25, -27)],
		# The former side-wall fixture at z=-40 is now the intentional cleft mouth.
		["reef side", Vector3(8, -34, -30), Vector3(42, -34, -30)],
		["cleft inner side", Vector3(32, -38, -42), Vector3(32, -38, -30)],
		["cleft opposite side", Vector3(38, -38, -45), Vector3(38, -38, -57)],
		["cave roof", Vector3(104, -14, -48), Vector3(104, -40, -48)],
		["chimney rim", Vector3(115, -12, -65), Vector3(115, -50, -65)],
		["cave side", Vector3(104, -40, -90), Vector3(104, -40, -48)],
		["cave underside", Vector3(104, -76, -48), Vector3(104, -40, -48)]
	]
	for surface in surfaces:
		var direction: Vector3 = (surface[2] - surface[1]).normalized()
		var ray := PhysicsRayQueryParameters3D.create(
			game.model.reef_frame * surface[1], game.model.reef_frame * surface[2], 1
		)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(), "Visible solid: " + surface[0])
		if hit.is_empty():
			continue
		for dt in [1.0 / 60, 1.0 / 15]:
			super.fixture(hit.position - direction * 2.5 - Vector3.UP * 1.05)
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


func audit_garden_rescue() -> void:
	# Enter each plant with real movement. Failure depth is a separate setup;
	# the whole rescue/re-formation and subsequent input are then continuous.
	for garden in range(Reef.PLANTS.size()):
		super.fixture(game.model.garden_points[garden] + Vector3.UP * 3)
		for frame in range(30):
			await tick()
		check(
			game.model.visited_gardens.has(garden),
			"Visiting a new garden records a real safe position"
		)
		var safe: Vector3 = game.model.visited_gardens.get(garden, Vector3.ZERO)
		game.model.position = safe + Vector3(25, -55, 0)
		game.model.grounded = -1
		game.model.terrain_grounded = false
		game.model.oxygen = .01
		await tick()
		check(game.model.return_garden, "Rescue selects the visited garden instead of the pier")
		var elapsed: float = game.model.elapsed
		for frame in range(360):
			if game.model.mode == game.model.Mode.DIVING:
				break
			await tick()
		check(
			game.model.position.distance_to(safe) < .1,
			"Re-formation uses the previously occupied clear capsule position"
		)
		check(
			game.model.failure_depth - game.model.depth >= game.model.config.min_setback,
			"Garden rescue loses depth"
		)
		check(
			game.model.elapsed - elapsed <= game.model.config.rescue_max_seconds + .1,
			"Rescue remains bounded"
		)
		var before: Vector3 = game.model.position
		for frame in range(45):
			await tick(Vector2.LEFT, 0, true)
		check(
			game.model.position.distance_to(before) > 2,
			"Input resumes outside the rock after rescue"
		)


func compare_updraft() -> void:
	game.model.config = game.model.config.duplicate()
	for enabled in [false, true]:
		fixture(Reef.UPDRAFT + Vector3.DOWN * 10)
		game.model.config.cavern_current_enabled = enabled
		var initial: float = game.model.position.y
		for frame in range(120):
			await tick()
		observations["updraft_" + str(enabled)] = {
			"rise": game.model.position.y - initial, "oxygen": game.model.oxygen
		}
		check(
			game.world.effects.cavern_jet.emitting == enabled if gpu else true,
			"Comparison disables the visible jet too"
		)
		await photo("55-updraft-" + str(enabled), Vector3(104, -29, -48))
		game.avatar.animate(game.model)
		check(
			game.avatar.pose == ("ascend" if enabled else "sink"),
			"Diver pose follows the actual direction through the current"
		)
	check(
		observations.updraft_true.rise > 7 and observations.updraft_false.rise < -8,
		"The bubble column offers an optional way back upward"
	)
	var before: Vector3 = game.model.position
	for frame in range(150):
		await tick(Vector2.RIGHT)
	check(game.model.position.x - before.x > 12, "Horizontal input exits the column freely")
	check(game.model.velocity.y < 0, "Leaving the column resumes natural sinking")
	fixture(Reef.UPDRAFT + Vector3.DOWN * 5)
	before = game.model.position
	for frame in range(180):
		await tick(Vector2.ZERO, 1)
	check(game.model.position.y < before.y - 6, "E can dive against the updraft")


func compare_cavern_loop() -> void:
	var previous_root := capture_root
	var previous_sequence := sequence
	var previous_frames := simulation_frames
	if gpu:
		capture_root += "/loop"
		DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
		sequence = []
		simulation_frames = 0
		record_sequence = true
	await run_cavern_loop()
	if gpu:
		var file := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(sequence, "  "))
		file.close()
	capture_root = previous_root
	sequence = previous_sequence
	simulation_frames = previous_frames
	record_sequence = false


func run_cavern_loop() -> void:
	# Start at a previously tested breathing shore. The loop itself is continuous
	# real input, without teleporting to the roof or through an opening.
	fixture(Vector3(99, -42, -48))
	game.model.config = game.model.config.duplicate()
	game.model.config.cavern_current_enabled = true
	minimum_oxygen = 100
	check(await swim(Vector3(85, -49, -52)), "Leave the refuge toward the side window")
	check(await swim(Vector3(80, -49, -65)), "Swim out through the side opening")
	check(await swim(Reef.UPDRAFT + Vector3.DOWN * 4), "Enter the visible bubble column")
	var before: float = game.model.position.y
	for frame in range(480):
		await tick()
	print("Jet ride: ", before, " -> ", game.model.position, " oxygen ", game.model.oxygen)
	check(game.model.position.y - before > 8, "Ride the flow toward the roof without Space")
	await photo("56-column-to-roof", Vector3(114, -30, -53))
	check(await swim(Vector3(104, -23, -48)), "Leave the current onto the cavern roof")
	for frame in range(100):
		await tick()
	print("Roof landing: ", game.model.position, " grounded ", game.model.terrain_grounded)
	check(game.model.terrain_grounded, "Land on the roof after riding the flow")
	audit_roof_algae()
	check(
		game.model.oxygen == 100, "Roof algae allow looking around rather than rushing a known path"
	)
	check(await swim(Vector3(103, -28, -54)), "Walk toward the upper opening")
	await photo("57-roof-opening", Vector3(114, -41, -53))
	check(await swim(Vector3(115, -41, -52)), "Drop through the roof into the same breathing shore")
	for frame in range(90):
		await tick()
	check(game.model.in_dry_cave(), "The upper entrance connects back to the air refuge")
	check(game.model.terrain_grounded, "The upper entrance lands on a walkable shore")
	check(game.model.oxygen == 100, "Completing the loop restores oxygen without a screen")
	await photo("58-chimney-from-inside", Vector3(115, -28, -53))
	observations.cavern_loop = {
		"seconds": game.model.elapsed, "oxygen": game.model.oxygen, "minimum_oxygen": minimum_oxygen
	}
	# Air supports walking, not flying: leave by the underwater mouth rather than
	# pretending Space can swim upward through the dry chamber to the chimney.
	check(await swim(Reef.PLANTS[3]), "Leave the completed loop by a different underwater mouth")
	check(not game.model.in_dry_cave(), "Swimming resumes after leaving the dry chamber")
	record_sequence = false
	for fast_drop in [false, true]:
		fixture(Vector3(115, -23, -52))
		for frame in range(360):
			await tick(Vector2.ZERO, 1 if fast_drop else 0)
			if game.model.terrain_grounded:
				break
		check(game.model.terrain_grounded, "Actual chimney drop lands, E=" + str(fast_drop))
		check(game.model.in_dry_cave(), "Chimney landing stays in the refuge")
		check(
			(game.model.reef_frame.affine_inverse() * game.model.position).y > -48,
			"Chimney drop does not tunnel through the shore"
		)


func audit_roof_algae() -> void:
	var leaves: MeshInstance3D = game.world.authored.get_node(
		"OxygenGardens/OxygenGarden4/OxygenAlgae/Fronds"
	)
	var arrays := leaves.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var gap := 0.0
	var roots := 0
	for index in range(vertices.size()):
		if uv[index].y > .001:
			continue
		var point := leaves.to_global(vertices[index])
		var query := PhysicsRayQueryParameters3D.create(
			point + Vector3.UP, point + Vector3.DOWN * 2, 1
		)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			gap = INF
		else:
			gap = maxf(gap, absf(point.y - hit.position.y))
		roots += 1
	check(roots > 0, "Roof algae contain visible rooted fronds")
	check(gap < .16, "Rendered algae roots match the actual sloping collision surface")
	observations.roof_algae_max_gap = gap
