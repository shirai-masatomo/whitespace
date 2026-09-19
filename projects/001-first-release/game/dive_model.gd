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
var oxygen_rate: float = 0.0
var current_flow := Vector3.ZERO
var jelly_cooldown: float = 0.0
var interactions: Dictionary = {"current": 0, "jelly": 0}
var best_depth: float = 0.0
var elapsed: float = 0.0
var setbacks: int = 0
var grounded: int = 0
var checkpoint: int = 0
var previous_checkpoint: int = 0
var visited_oxygen: Array[int] = [0]
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
	platforms = Layout.platforms()
	position = platforms[0].position
	velocity = Vector3.ZERO
	oxygen = config.oxygen_capacity
	oxygen_rate = 0.0
	current_flow = Vector3.ZERO
	jelly_cooldown = 0.0
	interactions = {"current": 0, "jelly": 0}
	best_depth = 0.0
	elapsed = 0.0
	setbacks = 0
	grounded = 0
	checkpoint = 0
	previous_checkpoint = 0
	depth_losses.clear()
	visited_oxygen.assign([0])
	rescue_reason = ""
	mode = Mode.DIVING


func inside(point: Vector3, platform: Dictionary, margin: float = 0.0) -> bool:
	if platform.get("round", false):
		var offset := Vector2(point.x - platform.position.x, point.z - platform.position.z)
		var radius: Vector2 = platform.size * .5 + Vector2.ONE * margin
		return (offset / radius).length_squared() <= 1.0
	return (
		absf(point.x - platform.position.x) <= platform.size.x * 0.5 + margin
		and absf(point.z - platform.position.z) <= platform.size.y * 0.5 + margin
	)


func surface_height(point: Vector3, platform: Dictionary) -> float:
	if platform.kind != "jelly":
		return platform.position.y
	var radius: float = platform.size.x * .56
	var r := Vector2(point.x - platform.position.x, point.z - platform.position.z).length() / radius
	# Match the authored bell profile so feet follow its dome, not an invisible plane.
	var drop: float
	if r <= .6:
		drop = lerpf(0, .09, r / .6)
	elif r <= .88:
		drop = lerpf(.09, .30, (r - .6) / .28)
	else:
		drop = lerpf(.30, .63, (r - .88) / .12)
	return platform.position.y - radius * drop


func oxygen_contact() -> int:
	for index in range(platforms.size()):
		if platforms[index].oxygen:
			var center: Vector3 = platforms[index].position + Vector3.UP * 1.6
			if (position + Vector3.UP).distance_to(center) <= config.oxygen_radius:
				return index
	return -1


func at_oxygen() -> bool:
	return oxygen_contact() >= 0


func step(delta: float, horizontal: Vector2, descent: float = 0.0, ascend: bool = false) -> void:
	if delta <= 0 or mode == Mode.COMPLETE:
		return
	elapsed += delta
	for index in range(platforms.size()):
		var platform: Dictionary = platforms[index]
		var old_platform: Vector3 = platform.position
		platform.position = (
			platform.origin + Vector3.RIGHT * sin(elapsed * platform.sway.y) * platform.sway.x
		)
		if grounded == index:
			position += platform.position - old_platform
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
	current_flow = flow_at(position) if grounded < 0 else Vector3.ZERO
	if current_flow.length() > .1:
		interactions.current += 1
	var next := position + (Vector3(velocity.x, 0, velocity.z) + current_flow) * delta
	jelly_cooldown = maxf(0, jelly_cooldown - delta)
	if ascend and position.y < 0.5:
		grounded = -1
	if grounded >= 0 and not inside(next, platforms[grounded]):
		grounded = -1
	if grounded < 0:
		var sink: float = config.sink_speed
		if descent > 0:
			sink = config.fast_sink_speed
		elif descent < 0:
			sink = config.brake_sink_speed
		if position.y > 0.5:
			velocity.y = maxf(-20, velocity.y - config.air_gravity * delta)
		else:
			var target_speed: float = config.ascent_speed if ascend else -sink
			velocity.y = move_toward(velocity.y, target_speed, config.vertical_acceleration * delta)
		next.y += velocity.y * delta
		if ascend and start.y <= 0.5 and next.y > 0.2:
			next.y = 0.2
			velocity.y = 0.0
		# Sweep the whole segment: fast descent cannot tunnel through thin floors.
		var first_hit: float = 2.0
		for index in range(platforms.size()):
			var floor_y: float = surface_height(next, platforms[index])
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
			next.y = surface_height(next, platforms[grounded])
			velocity.y = 0.0
	else:
		velocity.y = 0.0
		next.y = surface_height(next, platforms[grounded])
	position = next
	# Jelly landing is a readable gentle bounce; rescue and oxygen rules are unchanged.
	if grounded >= 0 and platforms[grounded].kind == "jelly" and jelly_cooldown <= 0:
		velocity.y = config.jelly_push
		grounded = -1
		position.y += 0.02
		jelly_cooldown = config.jelly_cooldown
		interactions.jelly += 1
	best_depth = maxf(best_depth, depth)
	oxygen_rate = 0.0
	var oxygen_index := oxygen_contact()
	if oxygen_index >= 0 or position.y >= -1:
		oxygen = config.oxygen_capacity
		if (
			oxygen_index >= 0
			and oxygen_index != checkpoint
			and platforms[oxygen_index].position.y < platforms[checkpoint].position.y
		):
			previous_checkpoint = checkpoint
			checkpoint = oxygen_index
			visited_oxygen.append(oxygen_index)
	else:
		var rate: float = config.oxygen_consumption
		if descent > 0 and not ascend and grounded < 0:
			rate *= config.fast_oxygen_multiplier
		oxygen_rate = rate
		oxygen = maxf(0.0, oxygen - rate * delta)
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
	return_checkpoint = 0
	# Space can move above a saved spot. Never rescue downward to that old spot.
	for index in visited_oxygen:
		if platforms[index].position.y >= position.y + config.min_setback:
			return_checkpoint = index
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
			var retained: Array[int] = []
			for index in visited_oxygen:
				if platforms[index].position.y >= return_target.y:
					retained.append(index)
				if platforms[index].position.y > return_target.y:
					previous_checkpoint = index
			visited_oxygen = retained
			grounded = checkpoint
			velocity = Vector3.ZERO
			oxygen = config.oxygen_capacity
			mode = Mode.DIVING


func flow_at(point: Vector3) -> Vector3:
	var flow := Vector3.ZERO
	for zone in Layout.current_zones():
		var distance: float = ((point - zone.center) / zone.radius).length()
		flow += zone.flow * maxf(0, 1 - distance)
	return flow
