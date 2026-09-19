extends RefCounted
## Shared trunk cross-sections for the visible mesh and deterministic footing.
const SEGMENTS := 20
const BASE_Y := -1.6
static var profiles: Dictionary = {}


static func profile(width: float) -> Array[Vector3]:
	if not profiles.has(width):
		var rings: Array[Vector3] = [
			Vector3(-width * .56, .001, .001),
			Vector3(-width * .56, .4, 1.1),
			Vector3(-width * .4, 1.4, 2.15),
			Vector3(-width * .2, 1.6, 2.3),
			Vector3(width * .12, 1.6, 2.05),
			Vector3(width * .35, 1.4, 1.95),
			Vector3(width * .56, .6, 1.2),
			Vector3(width * .56, .001, .001)
		]
		profiles[width] = rings
	return profiles[width]


static func origin(index: int) -> Vector3:
	return Vector3(0, BASE_Y, (index - 1) * 3.7)


static func heading(index: int) -> float:
	return (index - 1) * .045


static func length_scale(index: int) -> float:
	return .94 + index * .07


static func height_at(point: Vector3, size: Vector2) -> float:
	if absf(point.x) > size.x * .65 or absf(point.z) > 6.5:
		return -INF
	var top := -INF
	var rings := profile(size.x)
	for index in range(3):
		var local := (point - origin(index)).rotated(Vector3.UP, -heading(index))
		var along := -local.x / length_scale(index)
		for row in range(rings.size() - 1):
			var start := rings[row]
			var end := rings[row + 1]
			if end.x <= start.x or along < start.x or along > end.x:
				continue
			var radii := start.lerp(end, (along - start.x) / (end.x - start.x))
			if absf(local.z) > radii.z:
				continue
			# Piecewise polygon height agrees with the rendered radial segments.
			var ratio := clampf(local.z / radii.z, -1.0, 1.0)
			var step := TAU / SEGMENTS
			var angle := floorf(asin(ratio) / step) * step
			var fraction := (ratio - sin(angle)) / (sin(angle + step) - sin(angle))
			var height := radii.y * lerpf(cos(angle), cos(angle + step), fraction)
			top = maxf(top, BASE_Y + height)
	return top
