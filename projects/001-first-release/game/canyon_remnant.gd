extends RefCounted
## A cliff-rooted promontory, with a broken seaward end and a swimmable undercut.
## Its footprint is a place to traverse, not a bridge extruded along an axis.
const OUTLINE = [
	Vector2(39, -173),
	Vector2(54, -170),
	Vector2(59, -188),
	Vector2(74, -190),
	Vector2(82, -177),
	Vector2(88, -183),
	Vector2(82, -192),
	Vector2(86, -199),
	Vector2(94, -197),
	Vector2(94, -184),
	Vector2(101, -178),
	Vector2(108, -186),
	Vector2(127, -183),
	Vector2(132, -192),
	Vector2(119, -201),
	Vector2(115, -206),
	Vector2(102, -199),
	Vector2(90, -204),
	Vector2(74, -199),
	Vector2(63, -210),
	Vector2(39, -202)
]


static func append_to(st: SurfaceTool) -> void:
	var polygon := PackedVector2Array()
	for index in range(OUTLINE.size()):
		var a: Vector2 = OUTLINE[posmod(index - 1, OUTLINE.size())]
		var b: Vector2 = OUTLINE[index]
		var c: Vector2 = OUTLINE[(index + 1) % OUTLINE.size()]
		var d: Vector2 = OUTLINE[(index + 2) % OUTLINE.size()]
		for part in range(4):
			polygon.append(b.cubic_interpolate(c, a, d, part / 4.0))
	var indices := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, indices.size(), 3):
		_patch(
			st, polygon[indices[index]], polygon[indices[index + 1]], polygon[indices[index + 2]], 3
		)
	for index in range(polygon.size()):
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		var before := polygon[posmod(index - 1, polygon.size())]
		var after := polygon[(index + 2) % polygon.size()]
		var start_direction := (b - before).normalized()
		var end_direction := (after - a).normalized()
		for part in range(8):
			var p := a.lerp(b, part / 8.0)
			var q := a.lerp(b, (part + 1) / 8.0)
			var dp := start_direction.lerp(end_direction, part / 8.0).normalized()
			var dq := start_direction.lerp(end_direction, (part + 1) / 8.0).normalized()
			var np := Vector3(dp.y, 0, -dp.x)
			var nq := Vector3(dq.y, 0, -dq.x)
			for band in range(6):
				var v := _rim(p, np, band / 6.0)
				var w := _rim(p, np, (band + 1) / 6.0)
				var x := _rim(q, nq, (band + 1) / 6.0)
				var y := _rim(q, nq, band / 6.0)
				_face(st, v, w, x)
				_face(st, v, x, y)


static func _rim(p: Vector2, inward: Vector3, fraction: float) -> Vector3:
	var point := _point(p, false).lerp(_point(p, true), fraction)
	# Eroded bedding breaks the sheer slab face; both endpoints stay sealed.
	var recess := sin(fraction * PI) * (1.2 + sin(p.x * .3 + p.y * .2) * .4)
	recess += sin(fraction * PI * 4) * sin(fraction * PI) * .22
	return point + inward * recess


static func _patch(st: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, level: int) -> void:
	if level > 0:
		var ab := (a + b) * .5
		var bc := (b + c) * .5
		var ca := (c + a) * .5
		_patch(st, a, ab, ca, level - 1)
		_patch(st, ab, b, bc, level - 1)
		_patch(st, ca, bc, c, level - 1)
		_patch(st, ab, bc, ca, level - 1)
		return
	_face(st, _point(a, false), _point(b, false), _point(c, false))
	_face(st, _point(c, true), _point(b, true), _point(a, true))


static func _point(p: Vector2, underside: bool) -> Vector3:
	# A broad northern shoulder descends into a low seaward observation shelf.
	# Preserve an almost level patch where the existing oxygen plants grow.
	var shoulder := exp(-pow((p.x - 65) / 23, 2) - pow((p.y + 176) / 14, 2))
	var root := 1 - smoothstep(43, 73, p.x)
	# The high western remnant and low observation shelf are separated by a
	# deep cleft, with a southern walk-around. This changes traversal, not noise.
	var high_shoulder := 1 - smoothstep(73, 96, p.x)
	var y := -181.83 + high_shoulder * 11 + shoulder * 3 + root * 3
	y += sin(p.x * .19 + p.y * .13) * .6 * (1 - smoothstep(99, 113, p.x))
	var weather := sin(p.x * .31 + p.y * .24) * .55
	weather += sin(p.x * .14 - p.y * .37) * .35
	var refuge := 1 - smoothstep(4, 9, p.distance_to(Vector2(116, -194)))
	y += weather * (1 - refuge)
	if underside:
		y -= 6 + root * 48 + shoulder * 6
		y -= sin(p.x * .16 + p.y * .24) * 1.8
	var horizontal := p
	if underside:
		# Different basal footprints: the root plunges into the wall, while the
		# outer shelf is undercut towards its seaward toe, rather than one band.
		var outer := smoothstep(84, 110, p.x)
		var base := Vector2(49, -199).lerp(Vector2(126, -190), outer)
		horizontal = p.lerp(base, .12 + outer * .13)
	return Vector3(horizontal.x, y, horizontal.y)


static func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .04)
		st.add_vertex(point)
