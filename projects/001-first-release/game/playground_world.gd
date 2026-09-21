extends Node3D
## Connected rock surfaces and a hollow refuge, all sharing rendered collision.
const Rules = preload("res://game/playground_rules.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
var cavern_faces := PackedVector3Array()


func _ready() -> void:
	name = "PlayableReef"
	_make_reef()
	_make_cave()
	for index in range(Rules.PLANTS.size()):
		var plant := Node3D.new()
		plant.name = "OxygenGarden%d" % index
		plant.position = Rules.PLANTS[index]
		add_child(plant)
		Nature.oxygen_algae(plant, 80 + index, _roof_height if index == 4 else Callable())
		var light := OmniLight3D.new()
		light.light_color = Color("74e2b9")
		light.light_energy = 1.5
		light.omni_range = 12
		plant.add_child(light)


func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .04)
		st.add_vertex(point)


func _reef_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Godot's front faces are clockwise. The original shelf wound its outside
	# faces inward, producing wrong light and self-shadowing despite backface collision.
	triangle(st, c, b, a)


func _make_reef() -> void:
	var root := Node3D.new()
	root.name = "WalkableKelpReef"
	add_child(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(18, 74, 2):
		for z in range(-90, 2, 2):
			if not _reef_cell(x, z):
				continue
			var a := _reef_vertex(x, z)
			var b := _reef_vertex(x + 2, z)
			var c := _reef_vertex(x + 2, z + 2)
			var d := _reef_vertex(x, z + 2)
			_reef_triangle(st, a, c, b)
			_reef_triangle(st, a, d, c)
			var bottom := Vector3.DOWN * 12
			_reef_triangle(st, a + bottom, b + bottom, c + bottom)
			_reef_triangle(st, a + bottom, c + bottom, d + bottom)
			# Close every coastline and the shaft: the reef has a traversable roof,
			# solid edges and an underside, rather than a one-sided scenery sheet.
			var edges := [[a, b, x, z - 2], [b, c, x + 2, z], [c, d, x, z + 2], [d, a, x - 2, z]]
			for edge in edges:
				if not _reef_cell(edge[2], edge[3]):
					for layer in range(6):
						var first := _wall_vertex(edge[0], layer)
						var second := _wall_vertex(edge[1], layer)
						var third := _wall_vertex(edge[1], layer + 1)
						var fourth := _wall_vertex(edge[0], layer + 1)
						_reef_triangle(st, first, second, third)
						_reef_triangle(st, first, third, fourth)
	st.generate_normals()
	Geo.put(root, st.commit(), Nature.stone())
	for index in range(28):
		var angle := index * TAU / 28
		var x := 45 + cos(angle) * (21 + sin(angle * 5) * 3)
		var z := -45 + sin(angle) * (36 + cos(angle * 3) * 4)
		if _cleft(x, z, 10):
			continue
		Geo.put(
			root,
			Geo.boulder(Vector3(10, 15, 13), index + 330),
			Nature.stone(),
			Vector3(x, _reef_roof(x, z) + 1, z)
		)
	var rng := RandomNumberGenerator.new()
	rng.seed = 260920
	# Clumps and clear lanes, not a uniform plantation. Tall upper fronds frame
	# the view on entry; shorter plants let the swimmer see between the roots.
	var groves := [Vector2(31, -26), Vector2(55, -33), Vector2(38, -69), Vector2(58, -77)]
	for index in range(42):
		var center: Vector2 = groves[index % groves.size()]
		var angle := rng.randf_range(0, TAU)
		var radius := sqrt(rng.randf()) * 8
		var x := center.x + cos(angle) * radius
		var z := center.y + sin(angle) * radius
		var clearing := false
		for plant in [Rules.PLANTS[0], Rules.PLANTS[1]]:
			clearing = clearing or Vector2(x - plant.x, z - plant.z).length() < 6
		if clearing:
			continue
		if x > 34 and x < 50 and z > -48 and z < -24:
			continue  # A sightline from the first garden into the lateral cleft.
		if _reef_cell(int(x), int(z)) and Vector2(x - 49, z + 50).length() > 10:
			var height := rng.randf_range(10, 21)
			_make_kelp(root, Vector3(x, _reef_roof(x, z), z), height, index)
	Collision.build(root)


func _reef_roof(x: float, z: float) -> float:
	# The garden's rim falls away into the lateral opening. The opening becomes
	# a place visible from the refuge, instead of a slot hidden beyond a flat slab.
	var inlet := smoothstep(28, 38, -z) * (1 - smoothstep(46, 54, -z))
	inlet *= exp(-pow((x - 35) / 11, 2))
	# A high northern root and a low cleft lip break the broad horizontal
	# roof into a walk-around shoulder and a descending view into the reef.
	var root := 12 * exp(-pow((x - 54) / 8, 2) - pow((z + 12) / 15, 2))
	root += 7 * exp(-pow((x - 62) / 8, 2) - pow((z + 33) / 7, 2))
	root *= smoothstep(4, 9, Vector2(x - 32, z + 25).length())
	return Rules.reef_height(x, z) + root - inlet * 6


func _reef_cell(x: int, z: int) -> bool:
	var p := Vector2(x + 1 - 45, z + 1 + 45)
	var angle := atan2(p.y / 39, p.x / 23)
	var coast := 1 + .07 * sin(angle * 5) + .04 * cos(angle * 9)
	return (
		Vector2(p.x / 23, p.y / 39).length() < coast
		and Vector2(x + 1 - 49, z + 1 + 50).length() > 7
		and not _cleft(x + 1, z + 1, 4)
	)


func _cleft(x: float, z: float, radius: float) -> bool:
	var center := -38.0 - (x - 23) * .45 + sin(x * .2)
	return x < 50 and absf(z - center) < radius


func _reef_field(point: Vector2) -> float:
	var p := point - Vector2(45, -45)
	var angle := atan2(p.y / 39, p.x / 23)
	var coast := 1 + .07 * sin(angle * 5) + .04 * cos(angle * 9)
	var shore := (coast - Vector2(p.x / 23, p.y / 39).length()) * 23
	var shaft := point.distance_to(Vector2(49, -50)) - 7
	var center := -38.0 - (point.x - 23) * .45 + sin(point.x * .2)
	var cleft := maxf(absf(point.y - center) - 4, point.x - 50)
	return minf(shore, minf(shaft, cleft))


func _reef_gradient(point: Vector2) -> Vector2:
	return (
		Vector2(
			_reef_field(point + Vector2(.1, 0)) - _reef_field(point - Vector2(.1, 0)),
			_reef_field(point + Vector2(0, .1)) - _reef_field(point - Vector2(0, .1))
		)
		/ .2
	)


func _reef_vertex(x: int, z: int) -> Vector3:
	if not _sculpted_cleft(x, z):
		return Vector3(x, _reef_roof(x, z), z)
	var neighbors := 0
	for offset in [Vector2i.ZERO, Vector2i(-2, 0), Vector2i(0, -2), Vector2i(-2, -2)]:
		if _reef_cell(x + offset.x, z + offset.y):
			neighbors += 1
	var point := Vector2(x, z)
	# Shared boundary vertices follow the opening, rather than grid-square teeth.
	if neighbors > 0 and neighbors < 4:
		for iteration in range(3):
			var gradient := _reef_gradient(point)
			point -= (
				(gradient * _reef_field(point) / maxf(.1, gradient.length_squared()))
				. limit_length(1.5)
			)
	return Vector3(point.x, _reef_roof(point.x, point.y), point.y)


func _wall_vertex(top: Vector3, layer: int) -> Vector3:
	var depth := layer / 6.0
	if not _sculpted_cleft(top.x, top.z):
		return top + Vector3.DOWN * 12 * depth
	var point := Vector2(top.x, top.z)
	var inward := _reef_gradient(point).normalized()
	# Eroded bands open swimming alcoves under the lip, without invisible ledges.
	var recess := sin(depth * PI) * (1.6 + .65 * sin(top.x * .4 + top.z * .3 + layer * 1.7))
	return top + Vector3(inward.x * recess, -12 * depth, inward.y * recess)


func _sculpted_cleft(x: float, z: float) -> bool:
	return x < 55 and z < -32 and z > -59


func _make_kelp(parent: Node3D, point: Vector3, height: float, seed_value: int) -> void:
	Nature.canopy(parent, point, height, seed_value)


func _make_cave() -> void:
	var rock := Nature.stone()
	rock.set_shader_parameter("caustic_strength", .06)
	var root := Node3D.new()
	root.name = "TwoMouthCavern"
	add_child(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(35):
		for side in range(32):
			if _cave_window(row, side):
				continue
			for thickness in [0.0, 3.5]:
				var corners: Array[Vector3] = []
				for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					corners.append(_cave_point(Vector2i(row, side) + offset, thickness))
				triangle(st, corners[0], corners[1], corners[2])
				triangle(st, corners[0], corners[2], corners[3])
			var edges := [
				[Vector2i(row, side), Vector2i(row + 1, side), row, side - 1],
				[Vector2i(row + 1, side), Vector2i(row + 1, side + 1), row + 1, side],
				[Vector2i(row + 1, side + 1), Vector2i(row, side + 1), row, side + 1],
				[Vector2i(row, side + 1), Vector2i(row, side), row - 1, side]
			]
			for edge in edges:
				if _cave_window(edge[2], edge[3]):
					var a := _cave_point(edge[0], 0)
					var b := _cave_point(edge[1], 0)
					var c := _cave_point(edge[1], 3.5)
					var d := _cave_point(edge[0], 3.5)
					triangle(st, a, b, c)
					triangle(st, a, c, d)
	# Connect inner and outer shells around both mouths; leave the openings clear.
	for t in [0.0, 1.0]:
		for side in range(32):
			var corners: Array[Vector3] = []
			for offset in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 3.5), Vector2(0, 3.5)]:
				var angle: float = (side + offset.x) * TAU / 32
				var radius: Vector2 = Rules.cave_radius(t, angle) + Vector2.ONE * offset.y
				corners.append(
					Rules.cave_center(t) + Vector3(0, cos(angle) * radius.x, sin(angle) * radius.y)
				)
			triangle(st, corners[0], corners[1], corners[2])
			triangle(st, corners[0], corners[2], corners[3])
	st.generate_normals()
	Geo.put(root, st.commit(), rock)
	# Sloping shores cross the waterline; a swimmer can walk out without a jump
	# or an invisible teleport onto a raised island.
	var shore := SurfaceTool.new()
	shore.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(84, 122, 2):
		for z in range(-54, -38, 2):
			var points: Array[Vector3] = []
			for corner in [
				Vector2(x, z), Vector2(x + 2, z), Vector2(x + 2, z + 2), Vector2(x, z + 2)
			]:
				var shoreline := -46 + sin(corner.x * .14) * 1.7
				var wet_edge := maxf(0, absf(corner.y - shoreline) - 3.5)
				var y := -43 - maxf(0, absf(corner.x - 103) - 8) * .65
				y -= wet_edge * .38
				y += sin(corner.x * .32) * sin(corner.y * .27) * .18
				points.append(Vector3(corner.x, y, corner.y))
			triangle(shore, points[0], points[2], points[1])
			triangle(shore, points[0], points[3], points[2])
	shore.generate_normals()
	Geo.put(root, shore.commit(), rock)
	Collision.build(root)
	var water := SurfaceTool.new()
	Collision.collect(root, Transform3D.IDENTITY, cavern_faces)
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(139):
		var x := 68.0 + index * .5
		var left := _water_span(x)
		var right := _water_span(x + .5)
		if left != Vector2.ZERO and right != Vector2.ZERO:
			var a := Vector3(x, -45, left.x)
			var b := Vector3(x + .5, -45, right.x)
			var c := Vector3(x + .5, -45, right.y)
			var d := Vector3(x, -45, left.y)
			triangle(water, a, c, b)
			triangle(water, a, d, c)
	water.generate_normals()
	var wet := ShaderMaterial.new()
	wet.shader = preload("res://game/shaders/cave_water.gdshader")
	Geo.put(self, water.commit(), wet)
	var glow := OmniLight3D.new()
	glow.position = Vector3(104, -34, -48)
	glow.light_color = Color("bed6c1")
	glow.light_energy = 2.5
	glow.omni_range = 24
	add_child(glow)


func _cave_window(row: int, side: int) -> bool:
	# A second, higher opening makes the roof part of the same place: the
	# external updraft, roof walk and interior shore form an optional loop.
	var wrapped := posmod(side + 16, 32) - 16
	var roof_open := Vector2((row - 23.0) / 3.7, (wrapped + .5) / 2.4)
	var side_open := Vector2((row - 8.5) / 3.2, (side - 21.0) / 2.6)
	return side_open.length_squared() < 1 or roof_open.length_squared() < 1


func _cave_point(cell: Vector2i, thickness: float) -> Vector3:
	var coordinates := Vector2(cell)
	var open_count := 0
	for offset in [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i.ZERO]:
		if _cave_window(cell.x + offset.x, cell.y + offset.y):
			open_count += 1
	if open_count > 0 and open_count < 4:
		# Project shared edge vertices to a continuous aperture. Merely removing
		# grid cells produced rectangular teeth in both the silhouette and contact.
		var is_roof := cell.x > 16
		var center := Vector2(23.5, 0) if is_roof else Vector2(9, 21.5)
		var radius := Vector2(3.7, 2.4) if is_roof else Vector2(3.2, 2.6)
		if is_roof:
			coordinates.y = wrapf(coordinates.y, -16, 16)
		var radial := ((coordinates - center) / radius).normalized()
		var uneven := 1 + .065 * sin(radial.angle() * 3 + .8)
		coordinates = center + radial * radius * uneven
	var t := coordinates.x / 35.0
	var angle := coordinates.y * TAU / 32
	var radius := Rules.cave_radius(t, angle) + Vector2.ONE * thickness
	return Rules.cave_center(t) + Vector3(0, cos(angle) * radius.x, sin(angle) * radius.y)


func _water_span(x: float) -> Vector2:
	var center := Rules.cave_center((x - 68) / 70)
	var origin := Vector3(x, -45, center.z)
	if not Rules.inside_cave(origin):
		return Vector2.ZERO
	var edges := Vector2.ZERO
	for side in [-1, 1]:
		var inner := 0.0
		var outer := 24.0
		for iteration in range(14):
			var distance := (inner + outer) * .5
			if Rules.inside_cave(origin + Vector3(0, 0, distance * side), -.05):
				inner = distance
			else:
				outer = distance
		if side < 0:
			edges.x = center.z - outer
		else:
			edges.y = center.z + outer
	return edges


func _roof_height(point: Vector3) -> float:
	# Match the actual rendered triangles, not an analytic surface that differs
	# between samples. Root each frond on the sloping roof instead of floating.
	var highest := point.y - 4
	for index in range(0, cavern_faces.size(), 3):
		var a := cavern_faces[index]
		var b := cavern_faces[index + 1] - a
		var c := cavern_faces[index + 2] - a
		var offset := point - a
		var det := b.x * c.z - b.z * c.x
		if absf(det) < .00001:
			continue
		var u := (offset.x * c.z - offset.z * c.x) / det
		var v := (b.x * offset.z - b.z * offset.x) / det
		if u >= 0 and v >= 0 and u + v <= 1:
			var y := a.y + b.y * u + c.y * v
			if y < point.y + 3:
				highest = maxf(highest, y)
	return highest
