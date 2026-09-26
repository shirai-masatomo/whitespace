extends "res://tests/test_visual.gd"
## Real input journeys and controlled A/B fixtures. GPU mode records the journey.
const Places = preload("res://game/discovery_rules.gd")
var gpu := false
var checks := 0
var observations: Dictionary = {}


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(label)


func tick(axis: Vector2 = Vector2.ZERO, descent: float = 0, ascend: bool = false) -> void:
	game.yaw = 0
	game.advance(1.0 / 60, axis, descent, ascend)
	if gpu:
		await render_step()


func swim(
	point: Vector3, seconds: float = 25.0, riding: bool = false, allow_fast: bool = true
) -> bool:
	for frame in range(int(seconds * 60)):
		var difference: Vector3 = point - game.model.position
		if difference.length() < (6 if riding else 3):
			return true
		var axis: Vector2 = (Vector2(difference.x, difference.z) / 4).limit_length()
		var descent := 1.0 if difference.y < -3 and allow_fast else 0.0
		if riding:
			descent = 0
		await tick(axis, descent, difference.y > 1)
		if game.model.mode != Model.Mode.DIVING:
			print(
				"Swim rescue: ", point, " at ", game.model.position, " elapsed ", game.model.elapsed
			)
			return false
	print("Swim timeout: ", point, " from ", game.model.position, " air ", game.model.oxygen)
	for body in game.motion.contact_bodies:
		print("Blocked by ", body.get_path())
	return false


func photo(label: String, target: Vector3) -> void:
	if not gpu:
		return
	var offset: Vector3 = target - game.model.position - Vector3.UP * 1.4
	game.yaw = atan2(-offset.x, -offset.z)
	game.pitch = atan2(offset.y, Vector2(offset.x, offset.z).length())
	await capture(label)
	game.yaw = 0
	game.pitch = -.5


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	sequence_limit_seconds = 180
	capture_root = "res://artifacts/discovery-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	DirAccess.make_dir_recursive_absolute("res://artifacts/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.begin()
	game.pitch = -.5
	fixture(Vector3(45, -124, -45))
	await photo("36-transition-bubble", Places.bubbles(0)[0].center)
	check(
		await swim(Places.bubbles(game.model.elapsed)[0].center),
		"Enter a bubble from the P1/P2 transition"
	)
	check(game.model.in_air_pocket(), "Bubble is a volume to enter, not a landing platform")
	check(game.model.oxygen == 100, "Bubble restores air immediately")
	await photo("37-inside-air", Places.ARCH)
	var before: float = game.model.depth
	for frame in range(90):
		await tick()
	observations.bubble_depth_change = game.model.depth - before
	await photo("38-bubble-choice", Places.ARCH)
	check(
		await swim(Places.STREAM[0], 25, true), "Player can leave refuge by diving into the stream"
	)
	check(
		Places.stream_sample(game.model.position, 12).length() > 2,
		"Stream entry means actual current influence, not just reaching a waypoint"
	)
	await photo("39-current-entrance", Places.ARCH)
	for index in range(1, Places.STREAM.size()):
		check(
			await swim(Places.STREAM[index], 20, true),
			"Current bends through arch section %d" % index
		)
		if index == 2:
			await photo("40-through-arch", Places.STREAM[-1])
		if index == 3:
			await photo("41-unknown-shadow", Places.giant_position(game.model.elapsed))
	check(
		await swim(game.model.platforms[11].position + Vector3.UP),
		"The unknown route exits at a known refuge"
	)
	observations.discovery_seconds = game.model.elapsed
	await photo("42-found-refuge", Places.ARCH)
	record_sequence = false
	await compare_fixtures()
	var file := FileAccess.open("res://artifacts/discovery.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"checks": checks,
				"failed": failed,
				"observations": observations,
				"scope":
				"Real swept player and input-driven journey; comparisons do not establish fun"
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
	await create_timer(.1).timeout
	print("Discovery: %d checks, failed=%s, %s" % [checks, failed, observations])
	quit(1 if failed else 0)


func fixture(point: Vector3) -> void:
	game.restart()
	game.model.position = point
	game.model.grounded = -1
	game.model.velocity = Vector3.ZERO
	game.yaw = 0


func compare_fixtures() -> void:
	# These are isolated comparison fixtures, not part of the continuous recording.
	for enabled in [false, true]:
		fixture(Places.STREAM[0])
		game.model.config = game.model.config.duplicate()
		game.model.config.discovery_enabled = enabled
		for frame in range(240):
			await tick()
		observations["current_on" if enabled else "current_off"] = {
			"position": var_to_str(game.model.position),
			"distance_to_bend": game.model.position.distance_to(Places.STREAM[1]),
			"oxygen": game.model.oxygen
		}
	check(
		observations.current_on.distance_to_bend + 15 < observations.current_off.distance_to_bend,
		"A resting player is carried toward the hidden bend, not merely pushed down"
	)
	for enabled in [false, true]:
		fixture(Places.bubbles(0)[0].center)
		game.model.config = game.model.config.duplicate()
		game.model.config.discovery_enabled = enabled
		game.model.oxygen = 40
		for frame in range(120):
			await tick()
		observations["bubble_on" if enabled else "bubble_off"] = {
			"depth": game.model.depth, "oxygen": game.model.oxygen
		}
	check(observations.bubble_on.oxygen == 100, "Bubble differs from decorative sphere")
	check(
		observations.bubble_on.depth < observations.bubble_off.depth,
		"Breathing trades depth for safety"
	)
	fixture(Places.bubbles(0)[0].center)
	for frame in range(180):
		await tick(Vector2.ZERO, 1)
	check(not game.model.in_air_pocket(), "E can exit the buoyant refuge, never trapped")
	fixture(Places.STREAM[1])
	for frame in range(180):
		await tick(Vector2.LEFT, -1)
	check(
		Places.stream_sample(game.model.position, 12).length() < .1,
		"Lateral controls can leave the fast current"
	)
	# Walk/swim through the visible hole and block against the visible solid rim.
	fixture(Places.ARCH + Vector3(0, 0, 12))
	game.model.oxygen = 100
	check(await swim(Places.ARCH + Vector3(0, 0, -12), 8), "Arch opening is physically traversable")
	# The eastern rim now joins permanent bedrock. Isolate the western pillar
	# when checking the discovery toggle, so solid terrain is not a false failure.
	fixture(Places.ARCH + Vector3(-14, 0, 10))
	var hit := false
	for frame in range(120):
		await tick(Vector2(0, -1), -1)
		for body in game.motion.contact_bodies:
			if "SwimThroughArch" in str(body.get_path()):
				hit = true
	check(hit, "Solid arch rim blocks the actual player")
	fixture(Places.ARCH + Vector3(-14, 0, 10))
	game.model.config.discovery_enabled = false
	for frame in range(120):
		await tick(Vector2(0, -1), -1)
	check(
		game.model.position.z < Places.ARCH.z, "Disabled experiment leaves no invisible arch wall"
	)
	game.model.config.discovery_enabled = true
	for rate in [60, 15]:
		for fast in [false, true]:
			fixture(Places.ARCH + Vector3(0, 55, 0))
			for frame in range(rate * 4):
				game.advance(1.0 / rate, Vector2.ZERO, 1 if fast else 0, false)
				if game.model.standing:
					break
			check(game.model.standing, "Normal/fast descent lands on arch crown at %dHz" % rate)
			check(game.model.position.y > Places.ARCH.y + 34, "Arch crown blocks tunnelling")
		fixture(Places.ARCH + Vector3(0, 15, 0))
		var underside := false
		for frame in range(rate * 4):
			game.advance(1.0 / rate, Vector2.ZERO, 0, true)
			for body in game.motion.contact_bodies:
				if "SwimThroughArch" in str(body.get_path()):
					underside = true
		check(underside, "Space meets the visible inner arch at %dHz" % rate)
	for detour in [false, true]:
		fixture(Vector3(-85, -143, -78))
		game.model.oxygen = 18
		var success := true
		if detour:
			success = await swim(Places.bubbles(game.model.elapsed)[1].center)
			success = success and game.model.in_air_pocket()
			await photo("43-optional-air-lookout", Places.giant_position(game.model.elapsed))
		if success:
			success = await swim(game.model.platforms[11].position + Vector3.UP)
		observations["refuge_detour" if detour else "refuge_skip"] = {
			"success": success, "seconds": game.model.elapsed, "oxygen": game.model.oxygen
		}
	check(observations.refuge_detour.success, "An oxygen-poor swimmer can choose the air detour")
	check(not observations.refuge_skip.success, "Skipping refuge has a cost at low oxygen")
	fixture(Vector3(-85, -143, -78))
	game.model.oxygen = 100
	var skip_full := await swim(game.model.platforms[11].position + Vector3.UP)
	observations.refuge_skip_full = {"success": skip_full, "seconds": game.model.elapsed}
	check(skip_full, "The bubble is optional when oxygen is sufficient")
