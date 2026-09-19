extends SceneTree
## Actual capsule + game.advance, with fixture setup only before each contact.
const SCENE = preload("res://game/main.tscn")
const Driver = preload("res://tests/route_driver.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Collision = preload("res://game/level_collision.gd")
var game
var failures := 0
var checks := 0
var evidence: Array[Dictionary] = []


func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func probe(label: String, surface: Vector3, direction: Vector3, fast: bool, dt: float) -> void:
	game.model.reset()
	game.model.grounded = -1
	game.yaw = 0
	var gap := 2.3 if absf(direction.y) > .1 else .8
	game.model.position = surface - direction * gap - Vector3.UP * .85
	game.model.velocity = direction * (15 if fast else 7)
	var touched := false
	var first_position := Vector3.ZERO
	for frame in range(int(1.8 / dt)):
		game.model.oxygen = 100
		var axis := Vector2(direction.x, direction.z).normalized()
		game.advance(dt, axis, 1 if fast else 0, direction.y > .1)
		for normal in game.motion.contacts:
			if normal.dot(direction) < -.25:
				touched = true
				first_position = game.model.position
		if touched:
			break
	check(touched, "Swept player did not collide: " + label)
	evidence.append({"case": label, "contact": touched, "position": str(first_position)})


func audit_platform(index: int) -> void:
	var platform: Dictionary = game.model.platforms[index]
	var root_node: Node3D = game.world.platforms[index]
	var body: StaticBody3D = root_node.get_node("SolidGeometry")
	var shape: ConcavePolygonShape3D = body.get_child(0).shape
	var bounds := AABB(shape.get_faces()[0], Vector3.ZERO)
	for point in shape.get_faces():
		bounds = bounds.expand(point)
	var center: Vector3 = root_node.global_position + bounds.get_center()
	center += Vector3(.21, 0, .17)
	if index == 0:
		center = root_node.global_position + Vector3(.5, -.175, 1)
	for direction in [
		Vector3.DOWN,
		Vector3.UP,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3(-1, 0, -1).normalized()
	]:
		var origin: Vector3 = center - direction * 40
		var ray := PhysicsRayQueryParameters3D.create(origin, center + direction * 40, 1)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(), "Fixture mesh ray: %d %s" % [index, direction])
		if hit.is_empty():
			continue
		for dt in [1.0 / 60, 1.0 / 15]:
			await probe(
				"%s %s dt=%.3f" % [platform.kind, direction, dt],
				hit.position,
				direction,
				direction.y < 0,
				dt
			)
		await probe(
			"%s normal %s" % [platform.kind, direction], hit.position, direction, false, 1.0 / 60
		)


func run() -> void:
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	game.set_physics_process(false)
	await physics_frame
	await process_frame
	for index in [0, 1, 2, 3, 4, 5, 6, 9, 13, 14, 16, 17]:
		game.model.reset()
		game.world.sync_platforms(game.model.platforms)
		await physics_frame
		await audit_platform(index)
	await audit_small_solids()
	game.model.reset()
	game.model.position = game.model.platforms[5].position + Vector3.UP * .003
	game.model.grounded = 5
	for frame in range(180):
		game.advance(1.0 / 60, Vector2.ZERO)
	check(
		(
			game.model.grounded == 5
			and absf(game.model.position.x - game.model.platforms[5].position.x) < .2
		),
		"Moving platform carries the actual capsule"
	)
	var cliff_ray := PhysicsRayQueryParameters3D.create(
		Vector3(-30, -40, 5), Vector3(-150, -40, 5), 1
	)
	var cliff_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(cliff_ray)
	check(not cliff_hit.is_empty(), "Reachable coastline is solid")
	if not cliff_hit.is_empty():
		await probe("coastline side", cliff_hit.position, Vector3.LEFT, false, 1.0 / 60)
	for route_name in game.model.Layout.routes():
		game.model.reset()
		var complete := true
		for index in game.model.Layout.routes()[route_name]:
			if not Driver.reach(game.model, index, 40, route_name == "fast_drop"):
				complete = false
				push_error(
					"Actual route stopped: %s at %d, %s" % [route_name, index, game.model.position]
				)
				break
		check(complete, "Actual collision route " + route_name)
	game.model.reset()
	for index in [1, 2, 3]:
		Driver.reach(game.model, index)
	for frame in range(240):
		var target: Vector3 = game.model.platforms[3].position + Vector3(0, 0, 5.6)
		var offset := Vector2(target.x - game.model.position.x, target.z - game.model.position.z)
		game.advance(1.0 / 60, (offset * 1.6 / 7.0).limit_length())
	print(
		"Curved walk: ",
		game.model.position,
		" ground ",
		game.model.grounded,
		" velocity ",
		game.model.velocity
	)
	check(
		(
			game.model.grounded == 3
			and game.model.position.z > -52.8
			and game.model.position.y < -90.2
		),
		"Curved wood traversal reaches edge on the surface"
	)
	var file := FileAccess.open("res://artifacts/player-collision.json", FileAccess.WRITE)
	audit_oxygen_choice()
	file.store_string(
		JSON.stringify({"checks": checks, "failures": failures, "cases": evidence}, "  ")
	)
	game.queue_free()
	await process_frame
	await create_timer(.1).timeout
	print("Actual player collision: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func audit_small_solids() -> void:
	var fixtures := Node3D.new()
	game.world.add_child(fixtures)
	var point := Vector3(260, -85, 0)
	Geo.box(fixtures, Vector3(3, .06, 3), Geo.material(Color.WHITE), point)
	Geo.box(fixtures, Vector3(.08, 4, 3), Geo.material(Color.WHITE), point + Vector3(6, 0, 0))
	Geo.sphere(fixtures, .45, Geo.material(Color.WHITE), point + Vector3(12, 0, 0))
	Collision.build(fixtures)
	await physics_frame
	await process_frame

	for dt in [1.0 / 60, 1.0 / 15]:
		await probe("6cm thin floor E", point + Vector3.UP * .03, Vector3.DOWN, true, dt)
		await probe("6cm underside Space", point + Vector3.DOWN * .03, Vector3.UP, false, dt)
		await probe("8cm wall side", point + Vector3(5.96, 0, 0), Vector3.RIGHT, false, dt)
		await probe("small curved object", point + Vector3(12, .45, 0), Vector3.DOWN, true, dt)
		await probe("thin floor rim", point + Vector3(1.48, .03, 0), Vector3.DOWN, true, dt)
	fixtures.queue_free()
	await process_frame


func audit_oxygen_choice() -> void:
	var choices: Array[Dictionary] = []
	for air in [100.0, 30.0]:
		for target in [8, 19]:
			game.model.reset()
			for stop in [2, 10, 6]:
				check(Driver.reach(game.model, stop), "Reach oxygen decision fixture")
			game.model.oxygen = air
			# Leave the existing plant before reducing the experimental reserve.
			for frame in range(120):
				var command := Driver.input_for(game.model, target, true)
				game.advance(1.0 / 60, Vector2(command.x, command.z), command.y)
				if not game.model.at_oxygen():
					break
			game.model.oxygen = air
			var arrived := Driver.reach(game.model, target, 40, true)
			choices.append({"starting_oxygen": air, "target": target, "arrived": arrived})
			check(
				arrived == (air == 100 or target == 19), "Oxygen changes a meaningful route choice"
			)
	print("Oxygen decisions: ", choices)
