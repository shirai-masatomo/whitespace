extends Node3D
## Interlocking walkable terraces, a rock bridge and an open offshore bypass.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")


func _ready() -> void:
	name = "TerracedCanyon"
	# Broad shelves alternate with ramps: walk without Space, then choose a drop.
	_ribbon("WestTerraces", Vector3(67, -160, -130), Vector3(0, 0, -1), 96, 14, 18, 0)
	_ribbon("EastSlope", Vector3(131, -168, -151), Vector3(0, 0, -1), 85, 12, 22, 1)
	_ribbon("RockBridge", Vector3(67, -184, -194), Vector3.RIGHT, 66, 11, 7, 2)
	# Deep enough to enter beneath the bridge and emerge on either side.
	_ribbon("LowerBalcony", Vector3(78, -211, -187), Vector3(0, 0, -1), 58, 17, 16, 1)
	# Cliffs rise beside the walking surfaces, not through their centres.
	for side in [-1, 1]:
		for index in range(9):
			var z := -145.0 - index * 12
			var x := (45.0 if side < 0 else 150.0) + sin(index * .8) * 5
			var top := -146.0 - index * 4.3 + sin(index * 1.7) * 7
			# Open cross-cut at the bridge: inside/outside is a real passage.
			if index in [3, 4, 5]:
				top -= 40
			var root := Node3D.new()
			root.name = "Cliff_%d_%d" % [side, index]
			add_child(root)
			var profile: Array[Vector3] = [
				Vector3(0, 3, 4),
				Vector3(-4, 11, 10),
				Vector3(-14, 15, 13),
				Vector3(-26, 12, 12),
				Vector3(-39, 18, 14),
				Vector3(-58, 19, 13),
				Vector3(-75, 5, 5),
				Vector3(-78, 0, 0)
			]
			Geo.put(root, Geo.loft(profile, 24, 1800 + index), Nature.stone(), Vector3(x, top, z))
			Collision.build(root)


static func height_at(distance: float, style: int) -> float:
	if style == 2:
		return sin(distance / 66 * PI) * 3
	if style == 1:
		return -distance * .27
	# 8m of observation shelf followed by a 4m descent at a walkable angle.
	return -floorf(distance / 16) * 6 - clampf(fmod(distance, 16) - 8, 0, 8) * .75


func _ribbon(
	label: String,
	start: Vector3,
	direction: Vector3,
	length_m: int,
	width: float,
	thickness: float,
	style: int
) -> void:
	var root := Node3D.new()
	root.name = label
	add_child(root)
	var across := Vector3(-direction.z, 0, direction.x)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(length_m):
		var corners: Array[Vector3] = []
		for longitudinal in [row, row + 1]:
			corners.append(_surface(start, direction, across, longitudinal, -1, width, style))
			corners.append(_surface(start, direction, across, longitudinal, 1, width, style))
		for lane in range(8):
			var left := lane / 4.0 - 1
			var right := (lane + 1) / 4.0 - 1
			_quad(
				st,
				_surface(start, direction, across, row, left, width, style),
				_surface(start, direction, across, row + 1, left, width, style),
				_surface(start, direction, across, row + 1, right, width, style),
				_surface(start, direction, across, row, right, width, style)
			)
		var bottom := Vector3.DOWN * thickness
		_quad(
			st, corners[1] + bottom, corners[3] + bottom, corners[2] + bottom, corners[0] + bottom
		)
		_quad(st, corners[0], corners[0] + bottom, corners[2] + bottom, corners[2])
		_quad(st, corners[3], corners[3] + bottom, corners[1] + bottom, corners[1])
		if row == 0:
			_quad(st, corners[1], corners[1] + bottom, corners[0] + bottom, corners[0])
		if row == length_m - 1:
			_quad(st, corners[2], corners[2] + bottom, corners[3] + bottom, corners[3])
	st.generate_normals()
	Geo.put(root, st.commit(), Nature.stone())
	Collision.build(root)


func _surface(
	start: Vector3,
	direction: Vector3,
	across: Vector3,
	distance: float,
	lane: float,
	width: float,
	style: int
) -> Vector3:
	var mid := start + direction * distance
	mid.y += height_at(distance, style)
	var half := width * .5 + sin(distance * .21) * 1.3 + sin(distance * .61) * .4
	# Irregular outer lips around a reliable walking line; geometry and collision
	# are the same surface. Broad bays replace a uniform rectangular walkway.
	half += pow(maxf(0, sin(distance * .08)), 3) * 3
	mid += across * half * lane
	mid.y += pow(absf(lane), 3) * (sin(distance * .4) * .7 - .5)
	return mid


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex in [a, b, c, a, c, d]:
		st.set_uv(Vector2(vertex.x, vertex.z) * .04)
		st.add_vertex(vertex)
