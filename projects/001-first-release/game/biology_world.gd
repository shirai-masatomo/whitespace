extends Node3D
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
const Layout = preload("res://game/biology_layout.gd")
const Octopus = preload("res://game/giant_octopus.gd")
var giant: Node3D
var inflow: Array[MeshInstance3D] = []
var inflow_length := 0.0


func _ready() -> void:
	name = "BiologyEntrance"
	make_floor()
	make_throat()
	make_inflow()
	var material := Nature.stone()
	for data in [
		[Vector3(22, -454, -139), Vector3(14, 18, 46)],
		[Vector3(53, -444, -140), Vector3(19, 26, 60)],
		[Vector3(-65, -505, -170), Vector3(90, 95, 100)],
		[Vector3(134, -506, -125), Vector3(100, 100, 120)],
		[Vector3(-48, -590, -209), Vector3(85, 140, 180)],
		[Vector3(155, -578, -235), Vector3(100, 180, 170)],
		[Vector3(56, -603, -290), Vector3(180, 140, 65)]
	]:
		var part := Node3D.new()
		add_child(part)
		Geo.put(part, Geo.boulder(data[1], int(absf(data[0].x))), material, data[0])
		Collision.build(part)
	giant = Octopus.new()
	add_child(giant)


static func globe(parent: Node3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/shaders/water_globe.gdshader")
	Geo.sphere(parent, 2.2, material, Vector3.ZERO)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("63d9e6")
	lamp.light_energy = 1.6
	lamp.omni_range = 13
	lamp.shadow_enabled = true
	parent.add_child(lamp)


func update(model) -> void:
	giant.update(model.elapsed, model.depth)
	for i in range(inflow.size()):
		var distance: float = fposmod(i * 1.7 + model.elapsed * 2.4, inflow_length)
		var index := 0
		while index < Layout.APPROACH.size() - 2:
			var length: float = Layout.APPROACH[index].distance_to(Layout.APPROACH[index + 1])
			if distance < length:
				break
			distance -= length
			index += 1
		var direction: Vector3 = (Layout.APPROACH[index + 1] - Layout.APPROACH[index]).normalized()
		var point: Vector3 = Layout.APPROACH[index] + direction * distance
		point += Vector3(sin(i * 2.39) * 3.6, cos(i * 1.7) * .5, sin(i) * 2.5)
		if index < 2:
			# Sand saltates along the real floor; only near the opening does it fall.
			point.y = (
				Layout.sand_height(point.x, point.z) + .25 + absf(sin(i + model.elapsed * 2)) * .9
			)
		inflow[i].position = point
		var across := direction.cross(Vector3.FORWARD).normalized()
		inflow[i].basis = Basis(across, direction, across.cross(direction))


func make_floor() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-240, 280, 3):
		for z in range(-340, 120, 3):
			if not occupied(x, z):
				continue
			var a := floor_vertex(x, z)
			var b := floor_vertex(x + 3, z)
			var c := floor_vertex(x + 3, z + 3)
			var d := floor_vertex(x, z + 3)
			for point in [a, b, c, a, c, d]:
				st.add_vertex(point)
	st.generate_normals()
	var sand := ShaderMaterial.new()
	sand.shader = preload("res://game/shaders/terminal_sand.gdshader")
	var floor_root := Node3D.new()
	floor_root.name = "SandFloor"
	add_child(floor_root)
	Geo.put(floor_root, st.commit(), sand)
	# Low reef/kelp patches frame the approach, keeping the one throat readable.
	for i in range(18):
		var x := -12.0 + i * 4
		var z := -115.0 + sin(i * 2.4) * 9
		var point := Vector3(x, Layout.sand_height(x, z), z)
		Nature.kelp(floor_root, point, 1.5 + i % 3, 910 + i)
		if i % 4 == 0:
			Geo.put(
				floor_root, Geo.boulder(Vector3(5, 2, 4), i), Nature.stone(), point + Vector3.UP
			)
	# Exposed bedding on either side of the sandy runnel. The lane itself stays open.
	for i in range(15):
		var x := -16.0 + i * 4.8
		var z := -94.0 - i * 2.3 - (12 if i % 2 else 0)
		var point := Vector3(x, Layout.sand_height(x, z), z)
		if Vector2((x - 38) / 10, (z + 133) / 18).length() < 1:
			continue
		var slab := Geo.put(
			floor_root,
			Geo.fault_block(Vector3(8, 2.5, 5), 90 + i),
			Nature.stone(),
			point + Vector3.UP * .7
		)
		slab.rotation.y = .5 + sin(i) * .3
		Nature.kelp(floor_root, point + Vector3.UP * .5, 1.3, 440 + i)
	Collision.build(floor_root)


static func occupied(x: float, z: float) -> bool:
	return not Geometry2D.is_point_in_polygon(Vector2(x + 1.5, z + 1.5), Layout.mouth_outline())


static func floor_vertex(x: float, z: float) -> Vector3:
	var neighbors := 0
	for offset in [Vector2.ZERO, Vector2(-3, 0), Vector2(0, -3), Vector2(-3, -3)]:
		if occupied(x + offset.x, z + offset.y):
			neighbors += 1
	if neighbors > 0 and neighbors < 4:
		var outline := Layout.mouth_outline()
		var nearest := Vector2.INF
		for side in range(outline.size()):
			var candidate := Geometry2D.get_closest_point_to_segment(
				Vector2(x, z), outline[side], outline[(side + 1) % outline.size()]
			)
			if (
				candidate.distance_squared_to(Vector2(x, z))
				< nearest.distance_squared_to(Vector2(x, z))
			):
				nearest = candidate
		return Vector3(nearest.x, -457, nearest.y)
	return Vector3(x, Layout.sand_height(x, z), z)


func make_throat() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(100):
		for side in range(32):
			for outside in [false, true]:
				var a := throat_point(row / 100.0, side, outside)
				var b := throat_point((row + 1) / 100.0, side, outside)
				var c := throat_point((row + 1) / 100.0, side + 1, outside)
				var d := throat_point(row / 100.0, side + 1, outside)
				for point in [a, b, c, a, c, d]:
					st.add_vertex(point)
	st.generate_normals()
	var part := Node3D.new()
	part.name = "NarrowThroat"
	add_child(part)
	Geo.put(part, st.commit(), Nature.stone())
	Collision.build(part)


static func throat_point(t: float, side: int, outside: bool) -> Vector3:
	var index := mini(int(t * 5), 4)
	var local := t * 5 - index
	var center := Layout.PATH[index].lerp(Layout.PATH[index + 1], local)
	var angle := side * TAU / 32
	var radius := Layout.radius(t)
	var uneven := 1 + sin(angle * 3 + t * 11) * .10 + sin(angle * 7 - t * 17) * .05
	uneven = lerpf(1, uneven, smoothstep(0, .1, t))
	if outside:
		radius += Vector2(25, 22)
	var result := (
		center + Vector3(cos(angle) * radius.x * uneven, 0, sin(angle) * radius.y * uneven)
	)
	if not outside:
		var outline := Layout.mouth_outline()[side % 32]
		var mouth := Vector3(outline.x, center.y, outline.y)
		result = mouth.lerp(result, smoothstep(0, .16, t))
	return result


func make_inflow() -> void:
	for i in range(Layout.APPROACH.size() - 1):
		inflow_length += Layout.APPROACH[i].distance_to(Layout.APPROACH[i + 1])
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/shaders/flow_mote.gdshader")
	for i in range(180):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(.055 + (i % 3) * .025, .12 + (i % 5) * .06)
		var mote := Geo.put(self, mesh, material)
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		inflow.append(mote)
