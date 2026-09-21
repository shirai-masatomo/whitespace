extends Node3D
## Mesh construction reference. Runtime loads saved geometry from levels/l1_editable.tscn.
## The first landing belongs to a terraced headland rooted in the seabed.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Growth = preload("res://game/headland_growth.gd")
const Collision = preload("res://game/level_collision.gd")
const OUTLINE = [
	Vector2(8, -12),
	Vector2(20, -14),
	Vector2(25, -23),
	Vector2(20, -29),
	Vector2(26, -35),
	Vector2(22, -44),
	Vector2(17, -49),
	Vector2(24, -62),
	Vector2(21, -68),
	Vector2(12, -71),
	Vector2(17, -79),
	Vector2(12, -83),
	Vector2(17, -92),
	Vector2(2, -104),
	Vector2(-8, -108),
	Vector2(-31, -117),
	Vector2(-43, -96),
	Vector2(-32, -73),
	Vector2(-26, -54),
	Vector2(-10, -48),
	Vector2(1, -44),
	Vector2(4, -36),
	Vector2(3, -28),
	Vector2(8, -22)
]

const FISSURE = [
	Vector2(5, -75),
	Vector2(13, -79),
	Vector2(12, -89),
	Vector2(5, -98),
	Vector2(2, -90),
	Vector2(3, -81)
]

static var fissure_outline: PackedVector2Array = _rounded_fissure()


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
					for layer in range(12):
						var upper_a := _wall_point(edge[0], layer / 12.0)
						var upper_b := _wall_point(edge[1], layer / 12.0)
						var lower_a := _wall_point(edge[0], (layer + 1) / 12.0)
						var lower_b := _wall_point(edge[1], (layer + 1) / 12.0)
						_triangle(st, upper_a, lower_b, upper_b)
						_triangle(st, upper_a, lower_a, lower_b)
	st.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", .3)
	stone.set_shader_parameter("caustic_strength", .3)
	Geo.put(self, st.commit(), stone)
	Growth.populate(self, height_at, _cell)
	Collision.build(self)


static func height_at(x: float, z: float) -> float:
	# Unequal terraces with a broken lip and a raised watershed beside the shaft.
	var inland := -z - x * .55 + sin(x * .09) * 2
	var top := -30.4
	var front := 1 - smoothstep(42, 60, -z)
	top += (sin(z * .23 + x * .1) * .8 + sin(x * .32) * .65) * front
	for band in [
		Vector3(53, 62, 3.2), Vector3(68, 79, 4.8), Vector3(79, 96, 6), Vector3(102, 115, 7)
	]:
		var walking_ramp := clampf((inland - band.x) / (band.y - band.x), 0, 1)
		var broken_scarp := smoothstep(lerpf(band.x, band.y, .68), band.y, inland)
		top -= lerpf(walking_ramp, broken_scarp, smoothstep(-3, 8, x)) * band.z
	top -= 2.5 * exp(-pow((x - 11) / 8, 2) - pow((z + 69) / 5, 2))
	# A continuous high shoulder grows from the western part of the same mass.
	var wall := smoothstep(-25, -37, x) * smoothstep(-56, -75, z)
	top += wall * (17 + sin(z * .075) * 4)
	var garden := Vector2(x + 18, z + 84).length()
	return lerpf(-44, top, smoothstep(3, 12, garden))


static func _cell(x: int, z: int) -> bool:
	var point := Vector2(x + .5, z + .5)
	return (
		Geometry2D.is_point_in_polygon(point, PackedVector2Array(OUTLINE))
		and not Geometry2D.is_point_in_polygon(point, fissure_outline)
	)


static func _vertex(x: int, z: int) -> Vector3:
	var point := Vector2(x, z)
	var neighbors := 0
	for offset in [Vector2i.ZERO, Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		if _cell(x + offset.x, z + offset.y):
			neighbors += 1
	if neighbors > 0 and neighbors < 4:
		var nearest := Vector2.INF
		for contour in [OUTLINE, fissure_outline]:
			for edge in range(contour.size()):
				var candidate := Geometry2D.get_closest_point_to_segment(
					point, contour[edge], contour[(edge + 1) % contour.size()]
				)
				if point.distance_squared_to(candidate) < point.distance_squared_to(nearest):
					nearest = candidate
		point = nearest
	return Vector3(point.x, height_at(point.x, point.y), point.y)


static func _wall_point(top: Vector3, t: float) -> Vector3:
	var point := top.lerp(_base(top), t)
	# A localized wave-cut recess makes the broken eastern lip overhang its base.
	# Keep the shaft sides clear; this is erosion of the outside coast only.
	var recess := smoothstep(10, 20, top.x) * exp(-pow((top.z + 66) / 18, 2))
	point.x -= recess * sin(t * PI) * 7
	point.z += recess * sin(t * PI) * 2
	var erosion := sin(t * PI) * sin(top.z * .27 + top.x * .2)
	point.x += erosion * 1.2
	point.z += sin(t * PI) * sin(top.x * .3) * .8
	return point


static func _base(top: Vector3) -> Vector3:
	# An eroded overhang is open beneath the front; the southern keel reaches
	# the -520m seabed instead of ending in another floating slab.
	var root := 1 - smoothstep(8, 27, Vector2(top.x + 18, top.z + 102).length())
	return Vector3(top.x - root * 160, minf(top.y - 14, -56) - root * 480, top.z - root * 90)


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .06)
		st.add_vertex(point)


static func _rounded_fissure() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(FISSURE.size()):
		var p0: Vector2 = FISSURE[posmod(index - 1, FISSURE.size())]
		var p1: Vector2 = FISSURE[index]
		var p2: Vector2 = FISSURE[(index + 1) % FISSURE.size()]
		var p3: Vector2 = FISSURE[(index + 2) % FISSURE.size()]
		for subdivision in range(5):
			var t := subdivision / 5.0
			points.append(
				(
					.5
					* (
						(2 * p1)
						+ (-p0 + p2) * t
						+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
						+ (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t
					)
				)
			)
	return points
