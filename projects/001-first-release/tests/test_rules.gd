extends SceneTree

const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var failures: int = 0
var checks: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func tick(model, seconds: float, axis := Vector2.ZERO, descent: float = 0) -> void:
	for frame in range(int(seconds * 60)):
		model.step(1.0 / 60, axis, descent)


func airborne(depth: float = 60.0):
	var model = Model.new()
	model.position = Vector3(100, -depth, 0)
	model.grounded = -1
	return model


func _initialize() -> void:
	var model = Model.new()
	tick(model, 30)
	check(model.depth == 0 and model.oxygen == 100, "Start is safe on oxygen platform")
	tick(model, 2, Vector2.RIGHT)
	check(model.grounded == -1 and model.depth > 0, "Walking off automatically sinks")
	model = airborne()
	tick(model, 2)
	check(is_equal_approx(model.velocity.y, -5), "Natural terminal sink is 5 m/s")
	tick(model, 2, Vector2.ZERO, 1)
	check(is_equal_approx(model.velocity.y, -9), "E descent is 9 m/s")
	tick(model, 2, Vector2.ZERO, -1)
	check(is_equal_approx(model.velocity.y, -2), "Q slows but cannot hover or rise")
	tick(model, 1, Vector2.ONE)
	check(
		is_equal_approx(Vector2(model.velocity.x, model.velocity.z).length(), 7),
		"Diagonal speed capped"
	)
	tick(model, 1, Vector2.ZERO)
	check(Vector2(model.velocity.x, model.velocity.z).length() < 0.01, "Water steering can brake")
	model = Model.new()
	model.position = Vector3(14, -20, -18)
	model.grounded = -1
	model.step(2, Vector2.ZERO, 1)
	check(model.grounded == 1 and model.depth == 30, "Swept landing cannot tunnel through platform")
	tick(model, 1)
	check(model.depth == 30 and model.velocity.y == 0, "Landing stops descent")
	check(model.oxygen < 90, "Ordinary platforms do not refill oxygen")
	model.position = model.platforms[2].position
	model.grounded = 2
	model.oxygen = 0.1
	tick(model, 4)
	check(
		model.oxygen == 100 and model.checkpoint == 2,
		"Oxygen refills in four seconds and records safe spot"
	)
	model.position.x += 4
	tick(model, 1)
	check(
		is_equal_approx(model.oxygen, 96), "Outside bubble on same platform still consumes oxygen"
	)
	model.oxygen = 0.01
	tick(model, 1.0 / 60)
	check(
		model.mode == Model.Mode.RETURNING and model.return_checkpoint == 0,
		"Failure at checkpoint edge loses previous leg"
	)
	var scene_steps := 0
	while model.mode == Model.Mode.RETURNING and scene_steps < 2000:
		var before: Vector3 = model.position
		model.step(1.0 / 60, Vector2.ONE, 1)
		check(
			before.distance_to(model.position) <= 32.0 / 60 + 0.001, "Rescue must remain continuous"
		)
		scene_steps += 1
	check(
		model.grounded == 0 and model.oxygen == 100 and model.depth_losses[0] == 60,
		"Rescue returns to safe platform with oxygen"
	)
	tick(model, 2, Vector2.RIGHT)
	check(model.depth > 0 and model.mode == Model.Mode.DIVING, "Immediate retry without reset")
	_test_route()
	_test_branch_history()
	_test_failure_metrics()
	_test_edges()
	print("Rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_route() -> void:
	var model = Model.new()
	for index in model.Layout.routes().platforms:
		check(Driver.reach(model, index), "Route can reach platform %d" % index)
		if model.platforms[index].oxygen:
			Driver.refill(model)
	check(
		model.mode == Model.Mode.COMPLETE and model.setbacks == 0,
		"Whole route reaches goal without failure"
	)
	print("Route completion: %.2f seconds" % model.elapsed)
	var completed: Vector3 = model.position
	tick(model, 2, Vector2.ONE)
	check(model.position == completed, "Completion freezes movement")
	model.reset()
	check(
		model.depth == 0 and model.setbacks == 0 and model.mode == Model.Mode.DIVING,
		"Replay resets progress"
	)


func _test_failure_metrics() -> void:
	var losses: Array[float] = []
	for descent in [0.0, 1.0, -1.0]:
		var model = airborne()
		model.checkpoint = 2
		var frames := 0
		while model.mode == Model.Mode.DIVING and frames < 1600:
			model.step(1.0 / 60, Vector2.ZERO, descent)
			frames += 1
		check(absf(frames / 60.0 - 25) < 0.02, "Full oxygen lasts 25 seconds")
		check(model.mode == Model.Mode.RETURNING, "Depletion starts rescue")
		var loss: float = model.failure_depth + model.return_target.y
		losses.append(loss)
		tick(model, 20)
		check(
			model.mode == Model.Mode.DIVING and model.grounded == 2,
			"Airborne rescue returns safely"
		)
	var waiting = Model.new()
	waiting.position = waiting.platforms[3].position
	waiting.grounded = 3
	waiting.checkpoint = 2
	tick(waiting, 25.1)
	losses.append(waiting.failure_depth + waiting.return_target.y)
	var total := 0.0
	for loss in losses:
		total += loss
	print(
		(
			"Depth loss sample (natural / E / Q / ordinary platform): %s; mean %.2fm"
			% [losses, total / losses.size()]
		)
	)
	var file := FileAccess.open("res://artifacts/metrics.json", FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"depth_losses_m": losses,
				"mean_loss_m": total / losses.size(),
				"oxygen_seconds": 25,
				"refill_seconds": 4
			},
			"  "
		)
	)


func _test_edges() -> void:
	var model = airborne(299)
	model.step(1, Vector2.ZERO)
	check(model.mode != Model.Mode.COMPLETE, "Passing goal depth without landing is not a win")
	model = airborne(345)
	model.step(0.1, Vector2.ZERO)
	check(
		model.mode == Model.Mode.RETURNING, "Missing all platforms cannot strand player below goal"
	)
	model = Model.new()
	model.position = model.platforms[9].position
	model.grounded = 9
	model.oxygen = 0.01
	model.step(0.1, Vector2.ZERO)
	check(model.mode == Model.Mode.RETURNING, "Oxygen depletion takes precedence over goal")
	var fine = airborne()
	var coarse = airborne()
	for frame in range(120):
		fine.step(1.0 / 120, Vector2.RIGHT)
	for frame in range(30):
		coarse.step(1.0 / 30, Vector2.RIGHT)
	check(
		fine.position.distance_to(coarse.position) < 0.15,
		"Frame rate changes have small movement error"
	)
	check(absf(fine.oxygen - coarse.oxygen) < 0.001, "Oxygen independent of tick rate")


func _test_branch_history() -> void:
	var model = Model.new()
	for index in [1, 2, 10, 4]:
		check(Driver.reach(model, index), "Branch reaches %d" % index)
		if model.at_oxygen():
			Driver.refill(model)
	check(
		model.checkpoint == 4 and model.previous_checkpoint == 10,
		"History follows visits, not platform array order"
	)
	# Empty air just outside the bubble must return to the visited 95m branch.
	model.position.x += 4
	model.oxygen = 0.01
	model.step(1.0 / 60, Vector2.ZERO)
	check(model.return_checkpoint == 10, "Near-checkpoint failure returns to branch")
	tick(model, 6)
	check(
		model.checkpoint == 10 and model.previous_checkpoint == 2,
		"Rescue preserves 60m predecessor, not unvisited 260m"
	)
	check(model.depth == 95 and model.depth_losses[0] == 30, "Branch failure loses depth")
	model.position.x += 4
	model.oxygen = 0.01
	model.step(1.0 / 60, Vector2.ZERO)
	check(model.return_checkpoint == 2, "Repeated failure cannot advance to an unvisited deep spot")
	tick(model, 6)
	check(model.depth == 60, "Repeated branch rescue reaches correct shallower spot")
