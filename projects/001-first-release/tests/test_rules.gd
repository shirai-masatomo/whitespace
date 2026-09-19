extends SceneTree

const Model = preload("res://game/dive_model.gd")
const Config = preload("res://game/dive_config.gd")
var failures: int = 0
var checks: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func simulate(
	model, seconds: float, direction: float, sprint: bool = false, fps: float = 60
) -> void:
	for frame in range(int(seconds * fps)):
		model.step(1.0 / fps, direction, sprint)


func _initialize() -> void:
	var regular = Model.new()
	var fast = Model.new()
	simulate(regular, 2, 1)
	simulate(fast, 2, 1, true)
	check(regular.depth > 20, "Descending should gain depth")
	check(fast.depth > regular.depth, "Sprint must descend faster")
	check(fast.pressure > regular.pressure, "Rapid descent must be riskier")
	var before: float = regular.pressure
	simulate(regular, 3, 0)
	check(regular.pressure < before, "Staying still must recover pressure after braking")
	check(is_zero_approx(regular.vertical_speed), "Releasing dive must stop vertical drift")
	simulate(regular, 10, -1)
	check(regular.depth == 0 and regular.pressure == 0, "Surface and pressure must clamp at zero")
	var reckless = Model.new()
	for frame in range(1200):
		reckless.step(1.0 / 60, 1, true)
		if reckless.mode == Model.Mode.RETURNING:
			break
	check(reckless.mode == Model.Mode.RETURNING, "Continuous rushing must fail")
	var failure_depth: float = reckless.depth
	var preserved_best: float = reckless.best_depth
	var previous_depth: float = reckless.depth
	while reckless.mode == Model.Mode.RETURNING:
		reckless.step(1.0 / 60, 1, true)
		check(reckless.depth <= previous_depth, "Holding dive cannot cancel forced ascent")
		check(
			previous_depth - reckless.depth <= 20.0 / 60.0 + 0.0001,
			"Failure must move continuously, not teleport"
		)
		previous_depth = reckless.depth
	check(reckless.depth < failure_depth, "Failure must cost depth")
	check(reckless.best_depth == preserved_best, "Best depth is informational, not a checkpoint")
	check(reckless.setbacks == 1, "One failure should count once")
	check(reckless.pressure == 20, "Recovery must leave a playable pressure level")
	var recovered: float = reckless.depth
	simulate(reckless, 1, 1)
	check(reckless.depth > recovered, "Immediate retry must work")
	var cautious = Model.new()
	var recovering := false
	for frame in range(60 * 180):
		if cautious.pressure > 65:
			recovering = true
		elif cautious.pressure < 15:
			recovering = false
		cautious.step(1.0 / 60, 0 if recovering else 1)
		if cautious.mode == Model.Mode.COMPLETE:
			break
	check(
		cautious.mode == Model.Mode.COMPLETE,
		"Alternating descent and rest must reach goal within 3 minutes"
	)
	check(cautious.setbacks == 0, "Cautious route must not require forced ascent")
	print("Cautious route: %.2fs, %.1fm" % [cautious.elapsed, cautious.depth])
	var finished_time: float = cautious.elapsed
	simulate(cautious, 3, 1, true)
	check(
		cautious.depth == 300 and cautious.elapsed == finished_time, "Completion must remain stable"
	)
	cautious.reset()
	check(
		cautious.depth == 0 and cautious.setbacks == 0 and cautious.mode == Model.Mode.DIVING,
		"Replay must fully reset"
	)
	var config = Config.new()
	config.goal_depth = 10.0
	var tie = Model.new(config)
	tie.depth = 9.99
	tie.pressure = 99.999
	tie.step(0.1, 1)
	check(tie.mode == Model.Mode.RETURNING, "Pressure must win a goal/failure tie")
	var slow_fps = Model.new()
	var fast_fps = Model.new()
	simulate(slow_fps, 2, 1, false, 30)
	simulate(fast_fps, 2, 1, false, 120)
	check(absf(slow_fps.depth - fast_fps.depth) < 0.4, "Motion must be timestep stable")
	check(absf(slow_fps.pressure - fast_fps.pressure) < 1, "Pressure must be timestep stable")
	print("Rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
