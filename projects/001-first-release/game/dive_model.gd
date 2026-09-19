extends RefCounted
## Deterministic swept top-surface platform physics. Position is the player's feet.

enum Mode { DIVING, RETURNING, COMPLETE }
const Config = preload("res://game/dive_config.gd")
const Layout = preload("res://game/stage_layout.gd")

var config: Resource
var platforms: Array[Dictionary]
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var oxygen: float = 100.0
var best_depth: float = 0.0
var elapsed: float = 0.0
var setbacks: int = 0
var grounded: int = 0
var checkpoint: int = 0
var previous_checkpoint: int = 0
var return_checkpoint: int = 0
var return_target := Vector3.ZERO
var return_phase: int = 0
var failure_depth: float = 0.0
var depth_losses: Array[float] = []
var rescue_reason: String = ""
var mode: Mode = Mode.DIVING
var depth: float:
	get:
		return maxf(0, -position.y)


func _init(tuning: Resource = null) -> void:
	config = tuning if tuning != null else Config.new()
	platforms = Layout.platforms()
	reset()


func reset() -> void:
	position = platforms[0].position
	velocity = Vector3.ZERO
	oxygen = config.oxygen_capacity
	best_depth = 0.0
	elapsed = 0.0
	setbacks = 0
	grounded = 0
	checkpoint = 0
	previous_checkpoint = 0
	depth_losses.clear()
	rescue_reason = ""
	mode = Mode.DIVING


func inside(point: Vector3, platform: Dictionary, margin: float = 0.0) -> bool:
	return (
		absf(point.x - platform.position.x) <= platform.size.x * 0.5 + margin
		and absf(point.z - platform.position.z) <= platform.size.y * 0.5 + margin
	)


func at_oxygen() -> bool:
	if grounded < 0 or not platforms[grounded].oxygen:
		return false
	var offset: Vector3 = position - platforms[grounded].position
	return Vector2(offset.x, offset.z).length() <= config.oxygen_radius


func step(delta: float, horizontal: Vector2, descent: float = 0.0) -> void:
	if delta <= 0 or mode == Mode.COMPLETE:
		return
	elapsed += delta
	if mode == Mode.RETURNING:
		_return_step(delta)
		return
	var acceleration: float = (
		config.platform_acceleration if grounded >= 0 else config.water_acceleration
	)
	var desired: Vector2 = horizontal.limit_length() * config.horizontal_speed
	var horizontal_velocity := Vector2(velocity.x, velocity.z).move_toward(
		desired, acceleration * delta
	)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	var start := position
	var next := position + Vector3(velocity.x, 0, velocity.z) * delta
	if grounded >= 0 and not inside(next, platforms[grounded]):
		grounded = -1
	if grounded < 0:
		var sink: float = config.sink_speed
		if descent > 0:
			sink = config.fast_sink_speed
		elif descent < 0:
			sink = config.brake_sink_speed
		velocity.y = move_toward(velocity.y, -sink, config.vertical_acceleration * delta)
		next.y += velocity.y * delta
		# Sweep the whole segment: fast descent cannot tunnel through thin floors.
		var first_hit: float = 2.0
		for index in range(platforms.size()):
			var floor_y: float = platforms[index].position.y
			if start.y >= floor_y - 0.001 and next.y <= floor_y and start.y > next.y:
				var fraction := (start.y - floor_y) / (start.y - next.y)
				var hit := start.lerp(next, fraction)
				if (
					fraction < first_hit
					and inside(hit, platforms[index])
					and inside(next, platforms[index])
				):
					first_hit = fraction
					grounded = index
		if grounded >= 0:
			next.y = platforms[grounded].position.y
			velocity.y = 0.0
	else:
		velocity.y = 0.0
	position = next
	best_depth = maxf(best_depth, depth)
	if at_oxygen():
		oxygen = minf(config.oxygen_capacity, oxygen + config.oxygen_recovery * delta)
		if (
			grounded != checkpoint
			and platforms[grounded].position.y < platforms[checkpoint].position.y
		):
			previous_checkpoint = checkpoint
			checkpoint = grounded
	else:
		oxygen = maxf(0.0, oxygen - config.oxygen_consumption * delta)
	if oxygen <= 0:
		begin_return("酸素切れ")
	elif (
		depth > config.missed_goal_depth
		or Vector2(position.x, position.z).length() > config.ocean_extent
	):
		begin_return("航路を外れた")
	elif grounded >= 0 and platforms[grounded].goal:
		mode = Mode.COMPLETE
		velocity = Vector3.ZERO


func begin_return(reason: String) -> void:
	mode = Mode.RETURNING
	rescue_reason = reason
	setbacks += 1
	failure_depth = depth
	return_checkpoint = checkpoint
	if depth + platforms[checkpoint].position.y < config.min_setback:
		return_checkpoint = previous_checkpoint
	return_target = platforms[return_checkpoint].position
	return_phase = 0
	grounded = -1
	velocity = Vector3.ZERO


func _return_step(delta: float) -> void:
	# Bubble passes through platforms during rescue. Lift first, then glide over
	# the safe spot, then settle: all motion is continuous, never a teleport.
	var target: Vector3 = return_target + Vector3.UP * config.rescue_clearance
	if return_phase == 0:
		target.x = position.x
		target.z = position.z
	elif return_phase == 2:
		target = return_target
	var old := position
	position = position.move_toward(target, config.emergency_speed * delta)
	velocity = (position - old) / delta
	if position.is_equal_approx(target):
		if return_phase < 2:
			return_phase += 1
		else:
			depth_losses.append(maxf(0.0, failure_depth - depth))
			checkpoint = return_checkpoint
			previous_checkpoint = 0
			for index in range(checkpoint):
				if platforms[index].oxygen:
					previous_checkpoint = index
			grounded = checkpoint
			velocity = Vector3.ZERO
			oxygen = config.oxygen_capacity
			mode = Mode.DIVING
