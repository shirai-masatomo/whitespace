extends RefCounted
## Talus and rooted vegetation follow the terraces, leaving clear walking lanes.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")


static func populate(parent: Node3D, ground: Callable, occupied: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 210921
	var stone := Nature.stone()
	stone.set_shader_parameter("caustic_strength", .12)
	stone.set_shader_parameter("strata_strength", .8)
	# Fragments cluster at the broken eastern lip and beneath the western shoulder.
	for center in [Vector2(15, -69), Vector2(15, -94), Vector2(-30, -99), Vector2(-27, -69)]:
		for index in range(6):
			var point: Vector2 = center + Vector2(rng.randf_range(-3, 3), rng.randf_range(-4, 4))
			if not occupied.call(floori(point.x), floori(point.y)):
				continue
			var size := Vector3(
				rng.randf_range(2, 6), rng.randf_range(.8, 2.8), rng.randf_range(2, 6)
			)
			var rock := Geo.put(
				parent,
				fragment(size, 60 + index),
				stone,
				Vector3(point.x, ground.call(point.x, point.y) + size.y * .3, point.y)
			)
			rock.name = "Talus%d" % parent.get_child_count()
			rock.rotation.y = rng.randf_range(-PI, PI)
	# Small deposits at the edge of the walking lane give scale without blocking it.
	for index in range(18):
		var center: Vector2 = [Vector2(-8, -60), Vector2(9, -62), Vector2(1, -72)][index % 3]
		var point := center + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2))
		var size := Vector3(
			rng.randf_range(.5, 1.6), rng.randf_range(.25, .6), rng.randf_range(.5, 1.4)
		)
		Geo.put(
			parent,
			fragment(size, 710 + index),
			stone,
			Vector3(point.x, ground.call(point.x, point.y) + size.y * .4, point.y)
		)
		if index % 3 == 0:
			Nature.kelp(
				parent, Vector3(point.x, ground.call(point.x, point.y), point.y), 1.4, index
			)
	# A glimpse of living water below distinguishes the new shaft from a dead pit.
	Nature.jelly(parent, 1.6, Vector3(8, -73, -88))
	Nature.jelly(parent, 1.1, Vector3(12, -78, -91))
	# Distinct groves: a low western garden, tall eastern curtains and a far fringe.
	for grove in [Vector3(-27, 7, -74), Vector3(17, 11, -63), Vector3(-9, 11, -104)]:
		for index in range(8):
			var x: float = grove.x + rng.randf_range(-4, 4)
			var z: float = grove.z + rng.randf_range(-5, 5)
			if not occupied.call(floori(x), floori(z)):
				continue
			Nature.canopy(
				parent,
				Vector3(x, ground.call(x, z), z),
				grove.y * rng.randf_range(.65, 1.2),
				510 + index
			)


static func fragment(size: Vector3, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rims: Array[PackedVector3Array] = []
	for row in range(3):
		var ring := PackedVector3Array()
		for index in range(9):
			var angle := index * TAU / 9
			var radius := rng.randf_range(.8, 1.12) * (.85 if row == 2 else 1.0)
			ring.append(
				Vector3(
					cos(angle) * size.x * .5 * radius + row * .18,
					(row * .5 - 1) * size.y + sin(angle * 2 + seed_value) * size.y * .09,
					sin(angle) * size.z * .5 * radius
				)
			)
		rims.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(9):
		var next := (index + 1) % 9
		for row in range(2):
			for point in [
				rims[row][index],
				rims[row][next],
				rims[row + 1][next],
				rims[row][index],
				rims[row + 1][next],
				rims[row + 1][index]
			]:
				st.add_vertex(point)
		for point in [
			Vector3(0, -size.y, 0),
			rims[0][next],
			rims[0][index],
			Vector3.ZERO,
			rims[2][index],
			rims[2][next]
		]:
			st.add_vertex(point)
	st.generate_normals()
	return st.commit()
