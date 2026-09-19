extends RefCounted
## Share the authored upper rim between visible mesh and landable footprint.
const SEGMENTS := 32
const TOP_RING := 5
static var rim_cache: Dictionary = {}


static func profile(size: Vector2, depth: float) -> Array[Vector3]:
	var x := size.x * .5
	var z := size.y * .5
	return [
		Vector3(-depth, .01, .01),
		Vector3(-depth * .92, x * .42, z * .5),
		Vector3(-depth * .67, x * .83, z * .73),
		Vector3(-depth * .27, x * 1.12, z * 1.04),
		Vector3(-1.1, x * 1.16, z * 1.15),
		Vector3(0, x * 1.1, z * 1.1),
		Vector3(0, .01, .01)
	]


static func roughness(angle: float, seed_value: int, row: int) -> float:
	if seed_value == 0:
		return 1.0
	return (
		1 + .09 * sin(angle * 5 + seed_value + row * .8) + .055 * cos(angle * 9 - seed_value * .1)
	)


static func rim(size: Vector2, seed_value: int) -> PackedVector2Array:
	var key := Vector3(size.x, size.y, seed_value)
	if rim_cache.has(key):
		return rim_cache[key]
	var ring: Vector3 = profile(size, 1)[TOP_RING]
	var points := PackedVector2Array()
	for side in range(SEGMENTS):
		var angle := side * TAU / SEGMENTS
		var radius := roughness(angle, seed_value, TOP_RING)
		points.append(Vector2(cos(angle) * ring.y, sin(angle) * ring.z) * radius)
	rim_cache[key] = points
	return points


static func contains(point: Vector3, size: Vector2, seed_value: int, margin: float = 0) -> bool:
	return Geometry2D.is_point_in_polygon(
		Vector2(point.x, point.z), rim(size + Vector2.ONE * margin * 2, seed_value)
	)


static func ellipse_contains(point: Vector3, radius: Vector2, segments: int) -> bool:
	var normalized := Vector2(point.x, point.z) / radius
	var angle := fposmod(normalized.angle(), TAU / segments) - PI / segments
	# Polygon edges, rather than a slightly larger ideal circle around the mesh.
	return normalized.length() <= cos(PI / segments) / cos(angle) + .00001
