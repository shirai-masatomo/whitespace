extends RefCounted
## Deterministic rules; no scene, UI, Steam, or input dependencies.

enum Mode { DIVING, RETURNING, COMPLETE }
const Config = preload("res://game/dive_config.gd")

var config: Resource
var depth: float = 0.0
var best_depth: float = 0.0
var pressure: float = 0.0
var vertical_speed: float = 0.0
var return_depth: float = 0.0
var elapsed: float = 0.0
var setbacks: int = 0
var mode: Mode = Mode.DIVING


func _init(tuning: Resource = null) -> void:
	config = tuning if tuning != null else Config.new()


func reset() -> void:
	depth = 0.0
	best_depth = 0.0
	pressure = 0.0
	vertical_speed = 0.0
	return_depth = 0.0
	elapsed = 0.0
	setbacks = 0
	mode = Mode.DIVING


func step(delta: float, vertical_input: float, sprint: bool = false) -> void:
	if delta <= 0.0 or mode == Mode.COMPLETE:
		return
	elapsed += delta
	if mode == Mode.RETURNING:
		var previous := depth
		depth = move_toward(depth, return_depth, config.forced_ascent_speed * delta)
		vertical_speed = (depth - previous) / delta
		pressure = move_toward(pressure, config.recovery_pressure, 32.0 * delta)
		if is_equal_approx(depth, return_depth):
			mode = Mode.DIVING
			vertical_speed = 0.0
			pressure = config.recovery_pressure
		return
	var direction := clampf(vertical_input, -1.0, 1.0)
	var target: float = direction * (config.descend_speed if direction > 0 else config.ascend_speed)
	if sprint and direction > 0:
		target *= config.sprint_multiplier
	vertical_speed = move_toward(vertical_speed, target, config.acceleration * delta)
	var old_depth := depth
	depth = clampf(depth + vertical_speed * delta, 0.0, config.goal_depth)
	var descended := depth - old_depth
	if descended > 0.001:
		pressure += (
			descended * config.pressure_per_metre * (1.0 + vertical_speed * config.speed_penalty)
		)
	else:
		pressure -= config.recovery_per_second * delta
	pressure = clampf(pressure, 0.0, config.pressure_limit)
	best_depth = maxf(best_depth, depth)
	# Pressure wins ties: touching the goal at the limit must not bypass failure.
	if pressure >= config.pressure_limit:
		mode = Mode.RETURNING
		setbacks += 1
		return_depth = maxf(0.0, depth - config.setback_metres)
	elif depth >= config.goal_depth:
		mode = Mode.COMPLETE
		vertical_speed = 0.0
