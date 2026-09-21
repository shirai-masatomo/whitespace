extends Node3D
## The first landing belongs to a terraced headland rooted in the seabed.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
const OUTLINE = [
	Vector2(8, -12),
	Vector2(20, -14),
	Vector2(20, -29),
	Vector2(17, -49),
	Vector2(24, -62),
	Vector2(12, -83),
	Vector2(-8, -108),
	Vector2(-31, -117),
	Vector2(-43, -96),
	Vector2(-32, -73),
	Vector2(-26, -54),
	Vector2(-10, -48),
	Vector2(8, -44)
]


func _ready() -> void:
	name = "ShallowHeadland"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-46, 26):
		for z in range(-120, -10):
			if not _cell(x, z):
				continue
			var a := _vertex(x, z)
			var b := _vertex(x + 1, z)
			var c := _vertex(x + 1, z + 1)
			var d := _vertex(x, z + 1)
			_triangle(st, a, b, c)
			_triangle(st, a, c, d)
			_triangle(st, _base(a), _base(c), _base(b))
			_triangle(st, _base(a), _base(d), _base(c))
			for edge in [[a, b, x, z - 1], [b, c, x + 1, z], [c, d, x, z + 1], [d, a, x - 1, z]]:
				if not _cell(edge[2], edge[3]):
					_triangle(st, edge[0], _base(edge[1]), edge[1])
					_triangle(st, edge[0], _base(edge[0]), _base(edge[1]))
	st.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", .5)
	Geo.put(self, st.commit(), stone)
	Collision.build(self)


static func height_at(x: float, z: float) -> float:
	var descent := maxf(0, -z - 47) * .25 + maxf(0, -x) * .25
	# Broad treads and weathered bevels, not invisible controller step-ups.
	var step := 2.0
	var fraction := fmod(descent, step) / step
	var terrace := floorf(descent / step) * step + clampf((fraction - .4) / .6, 0, 1) * step
	var top := -30.4 - terrace
	# A continuous high shoulder grows from the western part of the same mass.
	var wall := smoothstep(-25, -37, x) * smoothstep(-56, -75, z)
	top += wall * (17 + sin(z * .075) * 4)
	var garden := Vector2(x + 18, z + 84).length()
	return lerpf(-44, top, smoothstep(3, 7, garden))


static func _cell(x: int, z: int) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(x + .5, z + .5), PackedVector2Array(OUTLINE))


static func _vertex(x: int, z: int) -> Vector3:
	var point := Vector2(x, z)
	var neighbors := 0
	for offset in [Vector2i.ZERO, Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		if _cell(x + offset.x, z + offset.y):
			neighbors += 1
	if neighbors > 0 and neighbors < 4:
		var nearest := Vector2.INF
		for edge in range(OUTLINE.size()):
			var candidate := Geometry2D.get_closest_point_to_segment(
				point, OUTLINE[edge], OUTLINE[(edge + 1) % OUTLINE.size()]
			)
			if point.distance_squared_to(candidate) < point.distance_squared_to(nearest):
				nearest = candidate
		point = nearest
	return Vector3(point.x, height_at(point.x, point.y), point.y)


static func _base(top: Vector3) -> Vector3:
	# An eroded overhang is open beneath the front; the southern keel reaches
	# the -520m seabed instead of ending in another floating slab.
	var root := 1 - smoothstep(8, 27, Vector2(top.x + 18, top.z + 102).length())
	return Vector3(top.x - root * 160, minf(top.y - 14, -56) - root * 480, top.z - root * 90)


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .06)
		st.add_vertex(point)
