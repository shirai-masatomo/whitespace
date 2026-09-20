extends RefCounted
## Places and phenomena, independent of platform targets and navigation arrows.
const ARCH := Vector3(-50, -45, -90)
const STREAM: Array[Vector3] = [
	Vector3(-24, -42, -23), Vector3(-50, -41, -70), Vector3(-50, -49, -108), Vector3(-40, -112, -66)
]


static func bubbles(time: float) -> Array[Dictionary]:
	return [
		{"center": Vector3(-15 + sin(time * .12) * 2, -20, -32), "radius": 7.5},
		{"center": Vector3(-52, -99 + sin(time * .1), -60), "radius": 5.0}
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
	var nearest := INF
	var flow := Vector3.ZERO
	for index in range(STREAM.size() - 1):
		var origin := STREAM[index]
		var segment := STREAM[index + 1] - origin
		var t := clampf((point - origin).dot(segment) / segment.length_squared(), 0, 1)
		var distance := point.distance_to(origin + segment * t)
		if distance < nearest:
			nearest = distance
			# Gentle attraction keeps the bend readable; lateral input can still leave.
			flow = segment.normalized() * speed + (origin + segment * t - point) * .3
	# Carry a resting swimmer around bends instead of letting normal sinking cut the tube.
	return (flow + Vector3.UP * buoyancy) * smoothstep(7.5, 2.5, nearest)


static func giant_position(time: float) -> Vector3:
	return Vector3(
		-32 + sin(time * .025) * 20, -139 + sin(time * .035) * 6, -110 + cos(time * .025) * 8
	)
