extends SceneTree
## Repeatable evaluation, not a prediction of player fun or a global speedrun optimum.
const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var game
var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var results: Array[Dictionary] = []
	for route_name in Model.Layout.routes():
		results.append(evaluate_route(route_name, Model.Layout.routes()[route_name]))
	var rescue := evaluate_rescue()
	for result in results:
		if not result.complete or result.minimum_oxygen < 10:
			failures += 1
			push_error("Route must finish with a usable oxygen margin: " + result.name)
		if result.survey_visible != result.decisions:
			failures += 1
			push_error("Survey camera must reveal every evaluated next target: " + result.name)
		if result.aimed_camera_diver_framed != result.decisions:
			failures += 1
			push_error("Ledge view must retain the diver in frame: " + result.name)
		if result.aimed_camera_visible < result.decisions - 2:
			failures += 1
			push_error("Most departures must reveal their target without F: " + result.name)
	if rescue.controls_restored_seconds > 4 or rescue.lost_depth_m <= 0:
		failures += 1
		push_error("Representative rescue must lose depth and restore controls within four seconds")
	var report := {
		"routes": results,
		"rescue": rescue,
		"movement": evaluate_movement(),
		"scope":
		(
			"Scripted steering, instant contact refill, 60Hz. Movement timers use offshore fixtures. "
			+ "Camera checks are framing/occlusion, not human readability."
		)
	}
	var file := FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)


func evaluate_route(route_name: String, route: Array) -> Dictionary:
	game.model = Model.new()
	var legs: Array[Dictionary] = []
	var min_air: float = 100
	var framed := 0
	var unobstructed := 0
	var survey_visible := 0
	var aimed_visible := 0
	var diver_visible := 0
	for target in route:
		game.yaw = 0
		game.pitch = -0.65
		game._update_camera()
		var point: Vector3 = game.model.platforms[target].position + Vector3.UP * 2
		var screen: Vector2 = game.camera.unproject_position(point)
		if not game.camera.is_position_behind(point) and Rect2(0, 0, 1280, 720).has_point(screen):
			framed += 1
			var ray := PhysicsRayQueryParameters3D.create(game.camera.global_position, point)
			if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				unobstructed += 1
		var offset: Vector3 = point - game.model.position
		game.yaw = atan2(-offset.x, -offset.z)
		game._update_camera()
		var aimed_screen: Vector2 = game.camera.unproject_position(point)
		var aimed_ray := PhysicsRayQueryParameters3D.create(game.camera.global_position, point)
		if (
			not game.camera.is_position_behind(point)
			and Rect2(0, 0, 1280, 720).has_point(aimed_screen)
		):
			if game.get_world_3d().direct_space_state.intersect_ray(aimed_ray).is_empty():
				aimed_visible += 1
		var diver: Vector3 = game.model.position + Vector3.UP
		if not game.camera.is_position_behind(diver):
			if Rect2(0, 0, 1280, 720).has_point(game.camera.unproject_position(diver)):
				diver_visible += 1
		game.yaw = 0
		Input.action_press("survey")
		game.started = true
		game._update_camera()
		var survey_screen: Vector2 = game.camera.unproject_position(point)
		var survey_ray := PhysicsRayQueryParameters3D.create(game.camera.global_position, point)
		if (
			not game.camera.is_position_behind(point)
			and Rect2(0, 0, 1280, 720).has_point(survey_screen)
		):
			if game.get_world_3d().direct_space_state.intersect_ray(survey_ray).is_empty():
				survey_visible += 1
		Input.action_release("survey")
		var start: float = game.model.elapsed
		var arrived := false
		for frame in range(2400):
			var command := Driver.input_for(game.model, target)
			game.model.step(1.0 / 60, Vector2(command.x, command.z), command.y)
			min_air = minf(min_air, game.model.oxygen)
			if game.model.mode == Model.Mode.RETURNING:
				break
			if (
				game.model.grounded == target
				and (not game.model.platforms[target].oxygen or game.model.at_oxygen())
			):
				arrived = true
				break
		if not arrived:
			failures += 1
			push_error("Evaluation route cannot reach %s target %d" % [route_name, target])
			break
		legs.append(
			{
				"to": target,
				"travel_seconds": snappedf(game.model.elapsed - start, 0.01),
				"arrival_oxygen": snappedf(game.model.oxygen, 0.01)
			}
		)
		if game.model.at_oxygen():
			for frame in range(240):
				if game.model.oxygen >= game.model.config.oxygen_capacity:
					break
				game.model.step(1.0 / 60, Vector2.ZERO)
	return {
		"name": route_name,
		"seconds": snappedf(game.model.elapsed, 0.01),
		"minimum_oxygen": snappedf(min_air, 0.01),
		"complete": game.model.mode == Model.Mode.COMPLETE,
		"legs": legs,
		"departure_camera_framed": framed,
		"departure_camera_unoccluded": unobstructed,
		"survey_visible": survey_visible,
		"aimed_camera_visible": aimed_visible,
		"aimed_camera_diver_framed": diver_visible,
		"decisions": route.size(),
		"mean_leg_seconds": snappedf(_mean_leg(legs), 0.01)
	}


func _mean_leg(legs: Array[Dictionary]) -> float:
	var total := 0.0
	for leg in legs:
		total += leg.travel_seconds
	return total / max(1, legs.size())


func evaluate_rescue() -> Dictionary:
	var model = Model.new()
	for index in [1, 2, 3]:
		if not Driver.reach(model, index):
			failures += 1
		if model.at_oxygen():
			Driver.refill(model)
	while model.mode == Model.Mode.DIVING:
		model.step(1.0 / 60, Vector2.ZERO)
	var start: float = model.elapsed
	for frame in range(2000):
		model.step(1.0 / 60, Vector2.ZERO)
		if model.mode == Model.Mode.DIVING:
			break
	return {
		"lost_depth_m": model.depth_losses[0],
		"controls_restored_seconds": snappedf(model.elapsed - start, 0.01)
	}


func evaluate_movement() -> Dictionary:
	var report := {}
	for entry in [["sink", 0.0, false], ["fast", 1.0, false], ["ascend", 0.0, true]]:
		var model = Model.new()
		model.position = Vector3(300, -100, 0)
		model.grounded = -1
		for frame in range(120):
			model.step(1.0 / 60, Vector2.RIGHT, entry[1], entry[2])
		report[entry[0] + "_speed_mps"] = snappedf(absf(model.velocity.y), 0.01)
		report[entry[0] + "_oxygen_per_second"] = model.oxygen_rate
		report["horizontal_speed_mps"] = snappedf(model.velocity.x, 0.01)
	for descent in [0.0, 1.0]:
		var model = Model.new()
		model.position = Vector3(300, -10, 0)
		model.grounded = -1
		var frames := 0
		while model.mode == Model.Mode.DIVING and frames < 1800:
			model.step(1.0 / 60, Vector2.ZERO, descent)
			frames += 1
		report["fast_empty_seconds" if descent > 0 else "normal_empty_seconds"] = snappedf(
			frames / 60.0, 0.01
		)
	return report
