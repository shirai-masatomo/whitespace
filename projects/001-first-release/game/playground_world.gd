extends Node3D
## Connected rock surfaces and a hollow refuge, all sharing rendered collision.
const Rules = preload("res://game/playground_rules.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")


func _ready() -> void:
	name = "PlayableReef"
	_make_reef()
	_make_cave()
	for index in range(Rules.PLANTS.size()):
		var plant := Node3D.new()
		plant.position = Rules.PLANTS[index]
		add_child(plant)
		Nature.oxygen_algae(plant, 80 + index)
		var light := OmniLight3D.new()
		light.light_color = Color("74e2b9")
		light.light_energy = 1.5
		light.omni_range = 12
		plant.add_child(light)


func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .04)
		st.add_vertex(point)


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
			var a := Vector3(x, Rules.reef_height(x, z), z)
			var b := Vector3(x + 2, Rules.reef_height(x + 2, z), z)
			var c := Vector3(x + 2, Rules.reef_height(x + 2, z + 2), z + 2)
			var d := Vector3(x, Rules.reef_height(x, z + 2), z + 2)
			triangle(st, a, c, b)
			triangle(st, a, d, c)
			var bottom := Vector3.DOWN * 12
			triangle(st, a + bottom, b + bottom, c + bottom)
			triangle(st, a + bottom, c + bottom, d + bottom)
			# Close every coastline and the shaft: the reef has a traversable roof,
			# solid edges and an underside, rather than a one-sided scenery sheet.
			var edges := [[a, b, x, z - 2], [b, c, x + 2, z], [c, d, x, z + 2], [d, a, x - 2, z]]
			for edge in edges:
				if not _reef_cell(edge[2], edge[3]):
					triangle(st, edge[0], edge[1], edge[1] + bottom)
					triangle(st, edge[0], edge[1] + bottom, edge[0] + bottom)
	st.generate_normals()
	Geo.put(root, st.commit(), Nature.stone())
	for index in range(28):
		var angle := index * TAU / 28
		var x := 45 + cos(angle) * (21 + sin(angle * 5) * 3)
		var z := -45 + sin(angle) * (36 + cos(angle * 3) * 4)
		Geo.put(
			root,
			Geo.boulder(Vector3(10, 15, 13), index + 330),
			Nature.stone(),
			Vector3(x, Rules.reef_height(x, z) + 1, z)
		)
	for index in range(22):
		var x := 30 + (index % 4) * 9.0 + sin(index * 3.7) * 3
		var z := -17 - (index / 4) * 11.0
		if _reef_cell(int(x), int(z)) and Vector2(x - 49, z + 50).length() > 10:
			_make_kelp(root, Vector3(x, Rules.reef_height(x, z), z), 11 + index % 7, index)
	Collision.build(root)


func _reef_cell(x: int, z: int) -> bool:
	var p := Vector2(x + 1 - 45, z + 1 + 45)
	var angle := atan2(p.y / 39, p.x / 23)
	var coast := 1 + .07 * sin(angle * 5) + .04 * cos(angle * 9)
	return (
		Vector2(p.x / 23, p.y / 39).length() < coast
		and Vector2(x + 1 - 49, z + 1 + 50).length() > 7
	)


func _make_kelp(parent: Node3D, point: Vector3, height: float, seed_value: int) -> void:
	# Thin rising stipes with lateral fronds and a canopy leave sightlines at
	# diver height. Long blades planted at ground level read as terrestrial grass.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(Geo.leaf(height, .09), 0, Transform3D.IDENTITY)
	for branch in range(12):
		var t := .18 + branch * .064
		var angle := branch * 2.399 + seed_value
		var basis := Basis(Vector3.UP, angle) * Basis(Vector3.FORWARD, 1.0 + .25 * sin(branch))
		st.append_from(
			Geo.leaf(2.8 + t * 2, .3 + t * .2),
			0,
			Transform3D(basis, Vector3(0, t * height, sin(t * 3.3) * height * .17))
		)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/kelp.gdshader")
	Geo.put(parent, st.commit(), mat, point)


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
					var t: float = (row + offset.x) / 35.0
					var angle: float = (side + offset.y) * TAU / 32
					var radius: Vector2 = Rules.cave_radius(t, angle) + Vector2.ONE * thickness
					var point := Rules.cave_center(t)
					point += Vector3(0, cos(angle) * radius.x, sin(angle) * radius.y)
					corners.append(point)
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
				var y := -43 - maxf(0, absf(corner.x - 103) - 8) * .65
				points.append(Vector3(corner.x, y, corner.y))
			triangle(shore, points[0], points[2], points[1])
			triangle(shore, points[0], points[3], points[2])
	shore.generate_normals()
	Geo.put(root, shore.commit(), rock)
	Collision.build(root)
	var water := SurfaceTool.new()
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
	return Vector2((row - 8.5) / 3.2, (side - 21.0) / 2.6).length_squared() < 1


func _cave_point(cell: Vector2i, thickness: float) -> Vector3:
	var t := cell.x / 35.0
	var angle := cell.y * TAU / 32
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
