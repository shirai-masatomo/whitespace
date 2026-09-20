extends RefCounted
## Spatial destinations, not a required sequence of platform indices.
const PLANTS: Array[Vector3] = [
	Vector3(27, -30, -31),
	Vector3(55, -34, -69),
	Vector3(71, -58, -42),
	Vector3(135, -66, -65),
	Vector3(103, -26.4, -49),
	Vector3(67, -160, -135),
	Vector3(116, -181.83, -194),
	Vector3(92, -222, -220)
]
const CAVE_START := Vector3(68, -54, -42)
const CAVE_END := Vector3(138, -61, -65)
const UPDRAFT := Vector3(84, -48, -67)


static func updraft_pulse(time: float) -> float:
	return .82 + .18 * smoothstep(-.6, .3, sin(time * .45))


static func updraft(point: Vector3, time: float, speed: float) -> Vector3:
	var offset := point - UPDRAFT
	var horizontal := Vector2(offset.x, offset.z).length()
	var strength := smoothstep(8, 3, horizontal) * smoothstep(24, 15, absf(offset.y))
	return Vector3.UP * speed * strength * updraft_pulse(time)


static func reef_height(x: float, z: float) -> float:
	return (
		-25
		- (x - 25) * .09
		+ (z + 8) * .11
		+ sin(x * .15) * .65
		+ sin(x * .21) * sin(z * .15) * 1.2
	)


static func cave_center(t: float) -> Vector3:
	return Vector3(68 + t * 70, -54 + sin(t * PI) * 16 - t * 7, -42 - t * t * 23)


static func cave_radius(t: float, angle: float) -> Vector2:
	var swell := sin(t * PI)
	var rough := 1 + .07 * sin(angle * 5 + t * 17) + .04 * sin(angle * 9 - t * 31)
	# Broad unequal lobes read at a distance; small roughness alone made a tube.
	rough += .13 * sin(angle * 3 + t * 8) * swell
	return Vector2(8 + 3 * swell, 11 + 5 * swell * swell) * rough


static func inside_cave(point: Vector3, margin: float = 0.0) -> bool:
	var t := (point.x - 68) / 70
	if t <= 0 or t >= 1:
		return false
	var local := point - cave_center(t)
	var angle := atan2(local.z / 14, local.y / 10)
	var radius := cave_radius(t, angle) - Vector2.ONE * margin
	return Vector2(local.y / radius.x, local.z / radius.y).length_squared() < 1


static func air_at(point: Vector3) -> bool:
	return point.y > -45 and inside_cave(point, .25)


static func near_plant(point: Vector3) -> bool:
	return plant_index(point) >= 0


static func plant_index(point: Vector3) -> int:
	for index in range(PLANTS.size()):
		if point.distance_to(PLANTS[index]) < 4.0:
			return index
	return -1
