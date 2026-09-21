extends SceneTree
## Deliberate control gaps measure route sensitivity, not human failure rates or fun.
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var failures := 0


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var reports: Array[Dictionary] = []
	for name in ["fast_drop", "safe_gardens"]:
		var route: Array = Model.Layout.routes()[name]
		for gap in [0.0, .5, 1.0, 2.0, 3.0, 6.0, 10.0]:
			var cases: Array[Dictionary] = []
			for leg in range(route.size()):
				cases.append(trial(route, leg, gap))
			var completed := 0
			var rescue_max := 0.0
			for result in cases:
				completed += int(result.complete)
				rescue_max = maxf(rescue_max, result.rescue_seconds)
			if gap == 0 and completed != cases.size():
				failures += 1
				push_error("Baseline route must complete every control-gap fixture")
			reports.append(
				{
					"route": name,
					"gap_seconds": gap,
					"completed": completed,
					"trials": cases.size(),
					"max_rescue_seconds": snappedf(rescue_max, .01),
					"cases": cases
				}
			)
	var report := {
		"scope":
		(
			"One input release, 1 second after takeoff, on each leg separately. "
			+ "Fast steering resumes. Not human failure rates."
		),
		"results": reports
	}
	var file := FileAccess.open("res://artifacts/route-resilience.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	for result in reports:
		print(
			(
				"%s gap %.1fs: %d/%d, rescue max %.2fs"
				% [
					result.route,
					result.gap_seconds,
					result.completed,
					result.trials,
					result.max_rescue_seconds
				]
			)
		)
	quit(1 if failures else 0)


func trial(route: Array, gap_leg: int, gap_seconds: float) -> Dictionary:
	var model = Model.new()
	var minimum := 100.0
	var failed_target := -1
	for leg in range(route.size()):
		var target: int = route[leg]
		var airborne := 0
		var arrived := false
		for frame in range(3600):
			var command := Driver.input_for(model, target, true)
			if model.grounded < 0:
				airborne += 1
			if leg == gap_leg and airborne > 60 and airborne <= 60 + roundi(gap_seconds * 60):
				command = Vector3.ZERO
			model.step(1.0 / 60, Vector2(command.x, command.z), command.y)
			minimum = minf(minimum, model.oxygen)
			if model.mode == Model.Mode.RETURNING:
				break
			if (
				Driver.arrived(model, target)
				and (not model.platforms[target].oxygen or model.at_oxygen())
			):
				arrived = true
				break
		if not arrived:
			failed_target = target
			break
	var rescue_seconds := 0.0
	var lost_depth := 0.0
	if model.mode == Model.Mode.RETURNING:
		var failure_depth: float = model.depth
		for frame in range(1800):
			var old_position: Vector3 = model.position
			model.step(1.0 / 60, Vector2.ZERO)
			rescue_seconds += 1.0 / 60
			if model.position.distance_to(old_position) > model.rescue_speed / 60 + .01:
				failures += 1
				push_error("Rescue must remain continuous under missed-route fixtures")
			if model.mode == Model.Mode.DIVING:
				break
		lost_depth = failure_depth - model.depth
		if model.mode != Model.Mode.DIVING or model.oxygen != 100 or lost_depth <= 0:
			failures += 1
			push_error("Every failed route must restore control and oxygen after losing depth")
		if rescue_seconds > model.config.rescue_max_seconds + .02:
			failures += 1
			push_error("Long misses must not leave the player waiting beyond the rescue budget")
		var restored_x: float = model.position.x
		model.step(.1, Vector2.RIGHT)
		if model.position.x <= restored_x or model.mode != Model.Mode.DIVING:
			failures += 1
			push_error("Rescue must restore actual directional control immediately")
	return {
		"gap_before_target": route[gap_leg],
		"complete": model.mode == Model.Mode.COMPLETE,
		"failed_target": failed_target,
		"minimum_oxygen": snappedf(minimum, .01),
		"rescue_seconds": snappedf(rescue_seconds, .01),
		"lost_depth_m": snappedf(lost_depth, .01)
	}
