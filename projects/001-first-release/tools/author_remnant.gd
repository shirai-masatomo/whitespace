extends SceneTree
## One authored rock, not a new terrain system. Rebuild with --headless --script.
## Coordinates describe crest, fracture shoulders, ledges and basal buttresses.
const CROWN = [
	Vector3(39, -163, -173),
	Vector3(54, -161, -170),
	Vector3(59, -174, -188),
	Vector3(74, -172, -190),
	Vector3(82, -170, -177),
	Vector3(88, -178, -183),
	Vector3(82, -180, -192),
	Vector3(86, -184, -199),
	Vector3(94, -183, -197),
	Vector3(94, -181, -184),
	Vector3(101, -180, -178),
	Vector3(108, -184, -186),
	Vector3(127, -181.83, -183),
	Vector3(132, -187, -192),
	Vector3(119, -186, -201),
	Vector3(115, -184, -206),
	Vector3(102, -184, -199),
	Vector3(90, -181, -204),
	Vector3(74, -176, -199),
	Vector3(63, -190, -210),
	Vector3(39, -213, -202)
]
const LEDGES = [
	Vector3(43, -193, -174),
	Vector3(55, -175, -173),
	Vector3(63, -183, -187),
	Vector3(73, -178, -187),
	Vector3(78, -180, -177),
	Vector3(85, -184, -184),
	Vector3(80, -189, -191),
	Vector3(84, -191, -200),
	Vector3(96, -188, -199),
	Vector3(99, -187, -184),
	Vector3(101, -186, -180),
	Vector3(107, -189, -188),
	Vector3(123, -187, -181),
	Vector3(130, -191, -191),
	Vector3(117, -193, -200),
	Vector3(115, -191, -203),
	Vector3(101, -190, -202),
	Vector3(91, -190, -206),
	Vector3(74, -186, -202),
	Vector3(64, -202, -211),
	Vector3(41, -223, -202)
]
const BASE = [
	Vector3(44, -223, -181),
	Vector3(53, -207, -178),
	Vector3(58, -191, -189),
	Vector3(70, -188, -193),
	Vector3(79, -184, -184),
	Vector3(83, -188, -188),
	Vector3(80, -194, -192),
	Vector3(84, -195, -197),
	Vector3(98, -193, -196),
	Vector3(101, -193, -187),
	Vector3(103, -191, -185),
	Vector3(110, -195, -190),
	Vector3(121, -192, -188),
	Vector3(127, -197, -192),
	Vector3(121, -202, -198),
	Vector3(115, -198, -202),
	Vector3(102, -194, -207),
	Vector3(90, -200, -209),
	Vector3(72, -199, -199),
	Vector3(61, -214, -205),
	Vector3(44, -233, -201)
]
# Interior control vertices interrupt the single planar lid. The oxygen patch
# is explicitly level and the shoulder is high enough to invite an ascent.
const TOP_CONTROLS = [
	Vector3(52, -165, -183),
	Vector3(53, -185, -197),
	Vector3(64, -172, -196),
	Vector3(75, -174, -195),
	Vector3(80, -174, -183),
	Vector3(82, -184, -201),
	Vector3(98, -182, -190),
	Vector3(103, -181.83, -192),
	Vector3(103, -183, -196),
	Vector3(111, -181.83, -191),
	Vector3(111, -181.83, -197),
	Vector3(121, -181.83, -191),
	Vector3(121, -181.83, -197),
	Vector3(116, -181.83, -194),
	Vector3(124, -182, -187)
]
var triangles: Array[PackedVector3Array] = []


func _initialize() -> void:
	var rings: Array[PackedVector3Array] = []
	for controls in [CROWN, LEDGES, BASE]:
		var ring := PackedVector3Array()
		for i in range(controls.size()):
			for step in range(3):
				ring.append(
					controls[i].cubic_interpolate(
						controls[(i + 1) % controls.size()],
						controls[posmod(i - 1, controls.size())],
						controls[(i + 2) % controls.size()],
						step / 3.0
					)
				)
		rings.append(ring)
	if not cap(rings[0], false, TOP_CONTROLS) or not cap(rings[2], true, []):
		quit(1)
		return
	for row in range(2):
		for i in range(rings[row].size()):
			var j := (i + 1) % rings[row].size()
			triangles.append(
				PackedVector3Array([rings[row][i], rings[row + 1][i], rings[row + 1][j]])
			)
			triangles.append(PackedVector3Array([rings[row][i], rings[row + 1][j], rings[row][j]]))
	# Subdivide the authored cage as one closed surface; no terrain noise/height
	# formula. Shared-edge topology keeps cap and side smoothing continuous.
	for iteration in range(0 if "--rough-cage" in OS.get_cmdline_user_args() else 2):
		if not subdivide():
			quit(1)
			return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in triangles:
		for point in triangle:
			st.set_uv(Vector2(point.x, point.z) * .04)
			st.add_vertex(point)
	st.generate_normals()
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var result := ResourceSaver.save(st.commit(), "res://artifacts/authored_remnant.tres")
	print("Authored remnant: ", triangles.size(), " triangles; save=", result)
	quit(result)


func cap(ring: PackedVector3Array, underside: bool, controls: Array) -> bool:
	var polygon := PackedVector2Array()
	for point in ring:
		polygon.append(Vector2(point.x, point.z))
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty():
		push_error("The authored perimeter must be simple")
		return false
	var faces: Array[PackedVector3Array] = []
	for i in range(0, indices.size(), 3):
		faces.append(
			PackedVector3Array([ring[indices[i]], ring[indices[i + 1]], ring[indices[i + 2]]])
		)
	for point in controls:
		var inserted := false
		for i in range(faces.size()):
			var t := faces[i]
			if Geometry2D.is_point_in_polygon(
				Vector2(point.x, point.z),
				PackedVector2Array(
					[Vector2(t[0].x, t[0].z), Vector2(t[1].x, t[1].z), Vector2(t[2].x, t[2].z)]
				)
			):
				faces[i] = PackedVector3Array([t[0], t[1], point])
				faces.append(PackedVector3Array([t[1], t[2], point]))
				faces.append(PackedVector3Array([t[2], t[0], point]))
				inserted = true
				break
		if not inserted:
			push_error("Interior control must be within its crown")
			return false
	for face in faces:
		if underside:
			face.reverse()
		triangles.append(face)
	return true


func subdivide() -> bool:
	var points: Array[Vector3] = []
	var lookup := {}
	var faces: Array[Array] = []
	var neighbours := {}
	var edges := {}
	for triangle in triangles:
		var face: Array[int] = []
		for point in triangle:
			if not lookup.has(point):
				lookup[point] = points.size()
				neighbours[points.size()] = {}
				points.append(point)
			face.append(lookup[point])
		faces.append(face)
		for i in range(3):
			var a: int = face[i]
			var b: int = face[(i + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			neighbours[a][b] = true
			neighbours[b][a] = true
			if not edges.has(key):
				edges[key] = []
			edges[key].append(face[(i + 2) % 3])
	var smooth: Array[Vector3] = []
	for i in range(points.size()):
		var n: int = neighbours[i].size()
		var beta := 3.0 / (8 * n) if n > 3 else 3.0 / 16
		var point := points[i] * (1 - n * beta)
		for other in neighbours[i]:
			point += points[other] * beta
		smooth.append(point)
	var midpoints := {}
	for key in edges:
		if edges[key].size() != 2:
			push_error("Authored cage must be watertight")
			return false
		midpoints[key] = (points[key.x] + points[key.y]) * .375
		midpoints[key] += (points[edges[key][0]] + points[edges[key][1]]) * .125
	triangles.clear()
	for face in faces:
		var ab: Vector3 = midpoints[Vector2i(mini(face[0], face[1]), maxi(face[0], face[1]))]
		var bc: Vector3 = midpoints[Vector2i(mini(face[1], face[2]), maxi(face[1], face[2]))]
		var ca: Vector3 = midpoints[Vector2i(mini(face[2], face[0]), maxi(face[2], face[0]))]
		triangles.append(PackedVector3Array([smooth[face[0]], ab, ca]))
		triangles.append(PackedVector3Array([ab, smooth[face[1]], bc]))
		triangles.append(PackedVector3Array([ca, bc, smooth[face[2]]]))
		triangles.append(PackedVector3Array([ab, bc, ca]))
	return true
