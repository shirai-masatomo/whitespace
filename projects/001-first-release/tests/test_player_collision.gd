extends SceneTree
## Actual capsule + game.advance, with fixture setup only before each contact.
const SCENE = preload("res://game/main.tscn")
const Driver = preload("res://tests/route_driver.gd")
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
	for index in [0, 1, 2, 3, 4, 5, 6, 9]:
		game.model.reset()
		game.world.sync_platforms(game.model.platforms)
		await physics_frame
		await audit_platform(index)
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
	file.store_string(
		JSON.stringify({"checks": checks, "failures": failures, "cases": evidence}, "  ")
	)
	game.queue_free()
	await process_frame
	await create_timer(.1).timeout
	print("Actual player collision: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
