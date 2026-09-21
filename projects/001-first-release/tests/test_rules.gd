extends SceneTree
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var checks := 0
var failures := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func tick(model, seconds: float, axis := Vector2.ZERO, descent := 0.0, ascend := false) -> void:
	for frame in range(int(seconds * 60)):
		model.step(1.0 / 60, axis, descent, ascend)


func airborne(depth := 60.0):
	var model = Model.new()
	model.position = Vector3(100, -depth, 0)
	model.grounded = -1
	return model


func _initialize() -> void:
	var model = Model.new()
	tick(model, 30)
	check(model.position.y == 6 and model.oxygen == 100, "Start outdoors, safe without input")
	tick(model, 4, Vector2.RIGHT)
	check(
		model.position.y < 0 and model.oxygen < 100,
		"Walk off pier to enter water without scene change"
	)
	model = airborne()
	tick(model, 2)
	check(is_equal_approx(model.velocity.y, -5), "Normal sink 5m/s")
	tick(model, 2, Vector2.ZERO, 1)
	check(is_equal_approx(model.velocity.y, -15), "Fast sink 15m/s")
	tick(model, 3, Vector2.ZERO, 0, true)
	check(is_equal_approx(model.velocity.y, 6.6), "Space ascends at 6.6m/s")
	tick(model, 2)
	check(is_equal_approx(model.velocity.y, -5), "Release Space resumes sinking")
	model = airborne(2)
	tick(model, 5, Vector2.ZERO, 0, true)
	check(
		model.position.y <= 0.21 and model.oxygen == 100, "Surface breathing cannot launch into sky"
	)
	model = airborne()
	tick(model, 1, Vector2.ONE)
	check(
		is_equal_approx(Vector2(model.velocity.x, model.velocity.z).length(), 7),
		"Diagonal speed capped"
	)
	_test_oxygen()
	_test_platforms()
	_test_rescue()
	_test_interactions()
	for route_name in Model.Layout.routes():
		model = Model.new()
		for index in Model.Layout.routes()[route_name]:
			check(
				Driver.reach(model, index, 40.0, route_name in Model.Layout.fast_routes()),
				"Route %s reaches %d" % [route_name, index]
			)
		check(model.mode == Model.Mode.COMPLETE, "Route completes: " + route_name)
	model.reset()
	check(
		model.position == Vector3(0, 6, 0) and model.setbacks == 0, "Reset restores outdoor start"
	)
	print("Rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_interactions() -> void:
	var model = Model.new()
	model.position = Vector3(10, -43, -25)
	model.grounded = -1
	var before: Vector3 = model.position
	tick(model, .5)
	check(model.position.x > before.x + .6, "Current physically drifts the player")
	check(model.interactions.current > 0, "Current interaction measured")
	check(model.flow_at(Vector3(400, -40, 0)) == Vector3.ZERO, "Current has bounded influence")
	model = Model.new()
	model.position = model.platforms[4].position + Vector3.UP * .1
	model.grounded = -1
	model.velocity.y = -5
	tick(model, .1)
	check(model.velocity.y > 0 and model.interactions.jelly == 1, "Jelly contact lifts player")
	check(model.oxygen == 100, "Jelly bounce preserves instant oxygen refill")
	tick(model, 1)
	check(
		model.grounded == 4 and model.interactions.jelly == 1,
		"Jelly cooldown allows stable landing"
	)
	model.position = model.platforms[4].position + Vector3(6, .1, 0)
	model.grounded = -1
	model.jelly_cooldown = 3
	tick(model, 1)
	check(model.grounded == 4 and model.position.y < -125.5, "Feet follow jelly dome near its edge")
	model = Model.new()
	model.grounded = 5
	model.position = model.platforms[5].position
	tick(model, 2)
	check(model.position.distance_to(model.platforms[5].position) < .01, "Buoy carries idle player")
	var geo = load("res://game/ocean_geometry.gd")
	var mesh: ArrayMesh = geo.rock(Vector2(12, 12), 8, 5)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var upper_normals := 0
	for i in range(vertices.size()):
		if absf(vertices[i].y) < .01 and Vector2(vertices[i].x, vertices[i].z).length() < .1:
			check(normals[i].y > .9, "Landable cap normal points upward")
			upper_normals += 1
	check(upper_normals > 0, "Cap normal test sampled actual vertices")


func _test_oxygen() -> void:
	var normal = airborne()
	var fast = airborne()
	tick(normal, 1)
	tick(fast, 1, Vector2.ZERO, 1)
	check(is_equal_approx(normal.oxygen, 96), "Normal consumption 4/s")
	check(is_equal_approx(fast.oxygen, 90), "Fast consumption 2.5 times normal")
	var combined = airborne()
	tick(combined, 1, Vector2.ZERO, 1, true)
	check(is_equal_approx(combined.oxygen, 96), "Space has priority over E and uses normal cost")
	for descent in [0.0, 1.0]:
		var model = airborne(10)
		var frames := 0
		while model.mode == Model.Mode.DIVING and frames < 1800:
			model.step(1.0 / 60, Vector2.ZERO, descent)
			frames += 1
		var expected := 25.0 if descent == 0 else 10.0
		check(absf(frames / 60.0 - expected) < 0.02, "Oxygen depletion timer")
	var contact = Model.new()
	contact.position = contact.platforms[2].position + Vector3.UP * 2
	contact.grounded = -1
	contact.oxygen = 0.01
	contact.step(1.0 / 60, Vector2.ZERO)
	check(contact.oxygen == 100 and contact.grounded == -1, "Airborne touch refills instantly")
	check(
		contact.checkpoint == 2 and contact.mode == Model.Mode.DIVING,
		"Contact rescues last oxygen point before depletion"
	)
	contact.position += Vector3.RIGHT * 5
	contact.step(0.5, Vector2.ZERO)
	check(contact.oxygen < 100, "Leaving sphere resumes consumption")


func _test_platforms() -> void:
	var model = Model.new()
	model.position = Vector3(14, -20, -18)
	model.grounded = -1
	model.step(1, Vector2.ZERO, 1)
	check(model.grounded == 1 and model.depth == 30, "Swept fast landing")
	tick(model, 1)
	check(model.depth == 30 and model.oxygen < 100, "Ground stops sinking but not oxygen")
	tick(model, 1, Vector2.ZERO, 0, true)
	check(model.grounded == -1 and model.depth < 30, "Space leaves a platform upward")
	model = Model.new()
	model.position = model.platforms[5].position + Vector3.RIGHT
	model.grounded = 5
	tick(model, 2)
	check(
		absf(model.position.x - model.platforms[5].position.x - 1) < 0.001,
		"Moving container carries grounded player"
	)
	check(absf(model.platforms[5].position.x - 20) > 4, "Container moves through the world")
	tick(model, 3, Vector2.RIGHT)
	check(model.grounded == -1, "Can leave moving deck")


func _test_rescue() -> void:
	var model = Model.new()
	for index in [1, 2, 10, 4]:
		check(Driver.reach(model, index), "Rescue setup reaches %d" % index)
	model.position.x += 5
	model.oxygen = 0.01
	model.step(1.0 / 60, Vector2.ZERO)
	check(model.return_checkpoint == 10, "Failure beside 125m spot loses depth to visited branch")
	var frames := 0
	while model.mode == Model.Mode.RETURNING and frames < 2000:
		var old: Vector3 = model.position
		model.step(1.0 / 60, Vector2.ONE, 1, true)
		check(
			old.distance_to(model.position) <= model.rescue_speed / 60 + 0.001,
			"Rescue never teleports"
		)
		frames += 1
	check(frames / 60.0 <= model.config.rescue_max_seconds, "Rescue respects its time budget")
	check(model.mode == Model.Mode.DIVING and model.depth == 95, "Rescue finishes with control")
	check(model.oxygen == 100, "Rescue restarts with oxygen")
	# Rising above saved spots must never produce a downward rescue or free progress.
	model.position = Vector3(80, -20, 0)
	model.grounded = -1
	model.oxygen = 0.01
	model.step(1.0 / 60, Vector2.ZERO)
	check(model.return_checkpoint == 0, "After ascent rescue chooses a shallower visited spot")
	tick(model, 8)
	check(
		model.position.y == 6 and model.previous_checkpoint == 0,
		"Rescue returns to outdoor start safely"
	)
	model = airborne(model.config.missed_goal_depth + 1)
	model.step(0.1, Vector2.ZERO)
	check(model.mode == Model.Mode.RETURNING, "Missing goal cannot strand player")
