extends RefCounted
## Places and phenomena, independent of platform targets and navigation arrows.
const ARCH := Vector3(-85, -145, -45)
const STREAM: Array[Vector3] = [
	Vector3(-32, -128, -36),
	Vector3(-85, -139, -30),
	Vector3(-85, -147, -63),
	Vector3(-43, -135, -47)
]
const COVE_STREAM: Array[Vector3] = [
	Vector3(90, -244, -278),
	Vector3(118, -255, -288),
	Vector3(136, -261, -237),
	Vector3(108, -255, -175),
	Vector3(63, -246, -112),
	Vector3(16, -237, -60)
]


static func bubbles(time: float) -> Array[Dictionary]:
	return [
		{"center": Vector3(-15 + sin(time * .12) * 2, -130, -72), "radius": 7.5},
		{"center": Vector3(-75, -140 + sin(time * .1), -67), "radius": 5.0}
	]


static func breathing(point: Vector3, time: float) -> bool:
	for bubble in bubbles(time):
		if (point + Vector3.UP).distance_to(bubble.center) < bubble.radius - .5:
			return true
	return false


static func bubble_flow(point: Vector3, time: float, lift: float) -> Vector3:
	var result := Vector3.ZERO
	for bubble in bubbles(time):
		var distance: float = point.distance_to(bubble.center) / bubble.radius
		result += Vector3.UP * lift * maxf(0, 1 - distance * distance)
	return result


static func stream_sample(point: Vector3, speed: float, buoyancy: float = 0) -> Vector3:
	return sample_path(STREAM, point, speed, buoyancy)


static func sample_path(
	path: Array[Vector3], point: Vector3, speed: float, buoyancy: float = 0, fade_exit: bool = false
) -> Vector3:
	if speed <= 0:
		return Vector3.ZERO
	var nearest := INF
	var flow := Vector3.ZERO
	var strength := 1.0
	for index in range(path.size() - 1):
		var origin := path[index]
		var segment := path[index + 1] - origin
		var t := clampf((point - origin).dot(segment) / segment.length_squared(), 0, 1)
		var distance := point.distance_to(origin + segment * t)
		if distance < nearest:
			nearest = distance
			# Gentle attraction keeps the bend readable; lateral input can still leave.
			flow = segment.normalized() * speed + (origin + segment * t - point) * .3
			strength = 1 - smoothstep(.7, 1, t) if fade_exit and index == path.size() - 2 else 1.0
	# Carry a resting swimmer around bends instead of letting normal sinking cut the tube.
	return (flow + Vector3.UP * buoyancy) * smoothstep(7.5, 2.5, nearest) * strength


static func giant_position(time: float) -> Vector3:
	return Vector3(
		-32 + sin(time * .025) * 20, -139 + sin(time * .035) * 6, -110 + cos(time * .025) * 8
	)
