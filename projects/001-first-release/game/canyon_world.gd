extends Node3D
## Interlocking walkable terraces, a broken promontory and an open offshore bypass.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Remnant = preload("res://game/canyon_remnant.gd")
const Collision = preload("res://game/level_collision.gd")


func _ready() -> void:
	name = "TerracedCanyon"
	# Broad shelves alternate with ramps: walk without Space, then choose a drop.
	_ribbon("WestTerraces", Vector3(67, -160, -130), Vector3(0, 0, -1), 96, 14, 18, 0)
	_ribbon("EastSlope", Vector3(131, -168, -151), Vector3(0, 0, -1), 85, 12, 22, 3)
	# Deep enough to enter beneath the promontory and emerge on either side.
	_ribbon("LowerBalcony", Vector3(78, -211, -187), Vector3(0, 0, -1), 58, 17, 16, 1)
	# Continuous asymmetric rock strata, with an open tidal saddle beside the promontory.
	for side in [-1, 1]:
		_cliff(side)


func _cliff(side: int) -> void:
	var root := Node3D.new()
	root.name = "StratifiedWest" if side < 0 else "StratifiedEast"
	add_child(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(66):
		var a := _cliff_ring(row * 2.0, side)
		var b := _cliff_ring((row + 1) * 2.0, side)
		for index in range(a.size()):
			var next := (index + 1) % a.size()
			if side < 0:
				_quad(st, a[index], b[index], b[next], a[next])
			else:
				_quad(st, a[next], b[next], b[index], a[index])
		if row in [0, 65]:
			var ring := a if row == 0 else b
			var center := Vector3.ZERO
			for point in ring:
				center += point / ring.size()
			for index in range(ring.size()):
				var next := (index + 1) % ring.size()
				if (side < 0) == (row == 0):
					_quad(st, center, ring[index], ring[next], center)
				else:
					_quad(st, center, ring[next], ring[index], center)
	if side < 0:
		Remnant.append_to(st)
	st.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", 1.0)
	Geo.put(root, st.commit(), stone)
	Collision.build(root)


func _cliff_ring(distance: float, side: int) -> Array[Vector3]:
	var z := -126 - distance
	var phase := distance * .063 + side * 1.3
	var top := -144 - distance * .24 + sin(phase) * 8 + sin(phase * 2.3) * 3
	# A low, broad opening preserves the swim-through; no invisible tunnel.
	var gap := smoothstep(36, 50, distance) * (1 - smoothstep(87, 99, distance))
	top -= gap * (55 if side > 0 else 38)
	var inner := (49.0 if side < 0 else 150.0) + sin(phase * 1.7) * 3
	var end_taper := smoothstep(0, 16, distance) * (1 - smoothstep(113, 132, distance))
	top -= (1 - end_taper) * 39
	var bottom := -289 - distance * .12
	var height := top - bottom
	# Different shelf widths and overhangs rather than identical vertical posts.
	var profile: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(.03, 3),
		Vector2(.045, 11),
		Vector2(.085, 10),
		Vector2(.11, -2),
		Vector2(.17, -3),
		Vector2(.19, 12),
		Vector2(.23, 11),
		Vector2(.27, -4),
		Vector2(.40, 4),
		Vector2(.43, 14),
		Vector2(.47, 10),
		Vector2(.65, 8),
		Vector2(.69, 16),
		Vector2(1, 18),
		Vector2(1, -31),
		Vector2(0, -31)
	]
	if side > 0:
		# A recessed, sloping shore with a collapsed bay, not a phase-shifted copy
		# of the western shelves. The middle opens onto offshore wildlife.
		top = _east_section(distance, false)
		inner = _east_section(distance, true)
		height = top - bottom
		profile = [
			Vector2(0, -4),
			Vector2(.07, 5),
			Vector2(.24, 8),
			Vector2(.29, 3),
			Vector2(.56, 5),
			Vector2(.73, 17),
			Vector2(1, 26),
			Vector2(1, -38),
			Vector2(.13, -27)
		]
	var result: Array[Vector3] = []
	for index in range(profile.size()):
		var next := (index + 1) % profile.size()
		for division in range(4):
			var phase_y := index + division / 4.0
			var p := profile[index].lerp(profile[next], division / 4.0)
			var notch := sin(distance * .18 + phase_y * .7 + side) * 2
			var inward := (p.y + notch) * (.08 + .92 * end_taper)
			inward += sin(distance * .09 + phase_y * 1.2 + side) * 3
			var y := top - p.x * height
			if index < profile.size() - 2:
				y += sin(distance * .13 + phase_y * 1.1) * 1.8
				inward += sin(distance * .41 + y * .27) * 1.2
				inward += sin(distance * .22 - y * .17) * 1.8
				inward -= pow(maxf(0, sin(distance * .082 + side * 2)), 4) * 9
			var bend := sin(phase_y * .7 + side) * 4
			bend += sin(distance * .14 + phase_y) * 1.5
			result.append(Vector3(inner - side * inward, y, z + bend))
	return result


func _east_section(distance: float, horizontal: bool) -> float:
	var sections := [
		Vector3(0, -211, 178),
		Vector3(16, -151, 166),
		Vector3(38, -178, 174),
		Vector3(53, -219, 185),
		Vector3(76, -248, 193),
		Vector3(98, -190, 165),
		Vector3(115, -184, 171),
		Vector3(132, -246, 194)
	]
	for index in range(sections.size() - 1):
		var a: Vector3 = sections[index]
		var b: Vector3 = sections[index + 1]
		if distance <= b.x:
			var p := a.lerp(b, smoothstep(a.x, b.x, distance))
			return p.z if horizontal else p.y
	return sections[-1].z if horizontal else sections[-1].y


static func height_at(distance: float, style: int) -> float:
	if style != 0:
		return -distance * .27
	# Six weathered steps between observation shelves. Bevels are visible and
	# walkable in both directions, rather than an invisible character step-up.
	var steps := clampf((fmod(distance, 16) - 8) * .75, 0, 6)
	var descend := floorf(steps) + clampf((fmod(steps, 1) - .2) / .8, 0, 1)
	return -floorf(distance / 16) * 6 - descend


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
	var subdivisions := 4 if style == 0 else 1
	var stride := 1.0 / subdivisions
	for index in range(length_m * subdivisions):
		var row := index * stride
		if _terrace_cut(style, row, 0) and _terrace_cut(style, row, 7):
			continue
		var corners: Array[Vector3] = []
		for longitudinal in [row, row + stride]:
			corners.append(_surface(start, direction, across, longitudinal, -1, width, style))
			corners.append(_surface(start, direction, across, longitudinal, 1, width, style))
		for lane in range(8):
			if _terrace_cut(style, row, lane):
				continue
			var left := lane / 4.0 - 1
			var right := (lane + 1) / 4.0 - 1
			_quad(
				st,
				_surface(start, direction, across, row, left, width, style),
				_surface(start, direction, across, row + stride, left, width, style),
				_surface(start, direction, across, row + stride, right, width, style),
				_surface(start, direction, across, row, right, width, style)
			)
			_quad(
				st,
				_under(start, direction, across, row, right, width, thickness, style),
				_under(start, direction, across, row + stride, right, width, thickness, style),
				_under(start, direction, across, row + stride, left, width, thickness, style),
				_under(start, direction, across, row, left, width, thickness, style)
			)
			for edge in [-1, 1]:
				if _terrace_cut(style, row, lane + edge):
					var rim := left if edge < 0 else right
					_quad(
						st,
						_surface(start, direction, across, row, rim, width, style),
						_under(start, direction, across, row, rim, width, thickness, style),
						_under(
							start, direction, across, row + stride, rim, width, thickness, style
						),
						_surface(start, direction, across, row + stride, rim, width, style)
					)
			for edge in [-1, 1]:
				if _terrace_cut(style, row + edge * stride, lane):
					_cap(
						st,
						start,
						direction,
						across,
						row if edge < 0 else row + stride,
						lane,
						width,
						thickness,
						style,
						edge > 0
					)
		var under: Array[Vector3] = []
		for longitudinal in [row, row + stride]:
			for lane in [-1, 1]:
				under.append(
					_under(start, direction, across, longitudinal, lane, width, thickness, style)
				)
		_quad(st, corners[0], under[0], under[2], corners[2])
		if not _terrace_cut(style, row, 7):
			_quad(st, corners[3], under[3], under[1], corners[1])
		if row == 0:
			for lane in range(8):
				_cap(st, start, direction, across, row, lane, width, thickness, style, false)
		if index == length_m * subdivisions - 1:
			for lane in range(8):
				_cap(
					st, start, direction, across, row + stride, lane, width, thickness, style, true
				)
	st.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", 1.0)
	Geo.put(root, st.commit(), stone)
	Collision.build(root)


func _terrace_cut(style: int, distance: float, lane: int) -> bool:
	# A collapsed outer terrace leaves a narrow wall-side shelf. Walking around
	# and swimming through the break are choices within the same piece of rock.
	if style == 3:
		return distance >= 38 and distance < 62 and lane >= 0 and lane < 8
	return style == 0 and distance >= 40 and distance < 52 and lane >= 3 and lane < 8


func _surface(
	start: Vector3,
	direction: Vector3,
	across: Vector3,
	distance: float,
	lane: float,
	width: float,
	style: int
) -> Vector3:
	if style == 0:
		# Eroded fracture lips, not a rectangular hole cut from a tiled stair.
		var mouth := exp(-pow((distance - 40) / 3, 2))
		var far_lip := exp(-pow((distance - 52) / 3, 2))
		distance = maxf(0, distance + (-mouth * 1.5 + far_lip * 1.8) * (1 - lane * lane))
	var mid := start + direction * distance
	mid.y += height_at(distance, style)
	var half := width * .5 + sin(distance * .21) * 1.3 + sin(distance * .61) * .4
	# Irregular outer lips around a reliable walking line; geometry and collision
	# are the same surface. Broad bays replace a uniform rectangular walkway.
	half += pow(maxf(0, sin(distance * .08)), 3) * 3
	if style == 0:
		var neck := smoothstep(20, 24, distance) * (1 - smoothstep(34, 38, distance))
		half *= 1 - .65 * neck
	if style == 3:
		var taper := (
			1 - smoothstep(29, 38, distance) if distance < 50 else smoothstep(62, 72, distance)
		)
		half *= .12 + .88 * taper
	mid += across * half * lane
	mid.y += pow(absf(lane), 3) * (sin(distance * .4) * .7 - .5)
	return mid


func _under(
	start: Vector3,
	direction: Vector3,
	across: Vector3,
	distance: float,
	lane: float,
	width: float,
	thickness: float,
	style: int
) -> Vector3:
	var point := _surface(start, direction, across, distance, lane, width, style)
	var depth := thickness
	depth *= 1 - .32 * lane * lane
	point.y -= depth
	point -= across * lane * 1.1
	return point


func _cap(
	st: SurfaceTool,
	start: Vector3,
	direction: Vector3,
	across: Vector3,
	distance: float,
	lane: int,
	width: float,
	thickness: float,
	style: int,
	reverse: bool
) -> void:
	var left := lane / 4.0 - 1
	var right := (lane + 1) / 4.0 - 1
	var a := _surface(start, direction, across, distance, left, width, style)
	var b := _under(start, direction, across, distance, left, width, thickness, style)
	var c := _under(start, direction, across, distance, right, width, thickness, style)
	var d := _surface(start, direction, across, distance, right, width, style)
	if reverse:
		_quad(st, a, b, c, d)
	else:
		_quad(st, d, c, b, a)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex in [a, b, c, a, c, d]:
		st.set_uv(Vector2(vertex.x, vertex.z) * .04)
		st.add_vertex(vertex)
