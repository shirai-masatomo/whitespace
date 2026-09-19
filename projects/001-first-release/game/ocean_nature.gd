extends RefCounted
const Geo = preload("res://game/ocean_geometry.gd")
const Layout = preload("res://game/stage_layout.gd")
const WOOD = preload("res://game/shaders/wood.gdshader")


static func stone() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/stone.gdshader")
	return mat


static func kelp(parent: Node3D, point: Vector3, height: float, seed_value: int) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/kelp.gdshader")
	for blade in range(7):
		var leaf := Geo.put(
			parent,
			Geo.leaf(height * (0.65 + 0.07 * blade), 0.07 + height * 0.018),
			mat,
			point + Vector3(sin(blade * 2.4) * 0.7, 0, cos(blade * 2.4) * 0.7)
		)
		leaf.rotation.y = blade * 2.4 + seed_value
		leaf.rotation.z = sin(blade * 2.4) * 0.3


static func jelly(parent: Node3D, radius: float, point: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = point
	parent.add_child(root)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/jelly.gdshader")
	Geo.put(
		root,
		Geo.loft(
			[
				Vector3(-radius * .3, radius * .95, radius * .95),
				Vector3(-radius * .05, radius, radius),
				Vector3(radius * .28, radius * .88, radius * .88),
				Vector3(radius * .49, radius * .60, radius * .60),
				Vector3(radius * .58, .01, .01)
			],
			48
		),
		mat,
		Vector3(0, -radius * .58, 0)
	)
	var tentacle := ShaderMaterial.new()
	tentacle.shader = preload("res://game/shaders/tentacle.gdshader")
	var combined := SurfaceTool.new()
	combined.begin(Mesh.PRIMITIVE_TRIANGLES)
	for strand in range(16):
		var theta := strand * TAU / 16
		var profile: Array[Vector3] = []
		for ring in range(17):
			var t := ring / 16.0
			var width := (.025 + radius * .017) * (.12 + t * .88)
			profile.append(Vector3(-radius * (2.7 - t * 1.9), width, width))
		var mesh := Geo.loft(profile, 8)
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(vertices.size()):
			var t := (-vertices[i].y / radius - .8) / 1.9
			vertices[i].x += sin(t * 5 + theta) * radius * .12 * t
			vertices[i].z += cos(t * 4 + theta) * radius * .1 * t
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var curled := ArrayMesh.new()
		curled.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		combined.append_from(
			curled,
			0,
			Transform3D(Basis(), Vector3(cos(theta) * radius * .65, 0, sin(theta) * radius * .65))
		)
	Geo.put(root, combined.commit(), tentacle)

	return root


static func deck(root: Node3D, data: Dictionary, index: int) -> void:
	var size: Vector2 = data.size
	match data.kind:
		"pier":
			var wood := ShaderMaterial.new()
			wood.shader = WOOD
			for plank in range(18):
				Geo.box(root, Vector3(.94, .35, size.y), wood, Vector3(plank - 8.5, -.175, 0))
			for x in [-8.4, 8.4]:
				for z in [-7, 0, 7]:
					Geo.put(
						root,
						Geo.loft([Vector3(-15, .24, .24), Vector3(1.1, .24, .24)]),
						wood,
						Vector3(x, 0, z)
					)
			# Weathered mooring equipment, outside the walkable centre.
			var metal := Geo.material(Color("505853"), .7, .5)
			for x in [-7, 7]:
				Geo.put(
					root,
					Geo.loft(
						[Vector3(0, .32, .32), Vector3(.65, .26, .26), Vector3(.72, .42, .42)]
					),
					metal,
					Vector3(x, 0, 5)
				)
		"jelly":
			jelly(root, size.x * .56, Vector3.ZERO)
		"driftwood":
			var wood := ShaderMaterial.new()
			wood.shader = WOOD
			wood.set_shader_parameter("trunk", true)
			for log_index in range(3):
				var length_scale := 0.94 + log_index * .07
				var trunk := Geo.put(
					root,
					Geo.loft(
						[
							Vector3(-size.x * .56, .001, .001),
							Vector3(-size.x * .56, .4, 1.1),
							Vector3(-size.x * .4, 1.4, 2.15),
							Vector3(-size.x * .2, 1.8, 2.3),
							Vector3(size.x * .12, 1.75, 2.05),
							Vector3(size.x * .35, 1.4, 1.95),
							Vector3(size.x * .56, .6, 1.2),
							Vector3(size.x * .56, .001, .001)
						],
						20,
						18 + log_index
					),
					wood,
					Vector3(0, -1.6, (log_index - 1) * 3.7)
				)
				trunk.rotation.z = PI / 2
				trunk.rotation.y = (log_index - 1) * .045
				trunk.scale.y = length_scale
				for twig in range(3):
					var branch := Geo.put(
						trunk,
						Geo.loft(
							[
								Vector3(0, .5, .55),
								Vector3(1.4, .28, .3),
								Vector3(3.4, .06, .08),
								Vector3(3.5, .001, .001)
							],
							12,
							log_index + twig + 1
						),
						wood,
						Vector3(.35, size.x * .38, (twig - 1) * .5)
					)
					branch.rotation.x = (twig - 1) * .55
			kelp(root, Vector3(-size.x * .3, -.1, size.y * .32), 3.8, index)
		"buoy":
			var rust := Geo.material(Color("ba673d"), .6, .3)
			var metal := Geo.material(Color("243f45"), .4, .6)
			Geo.put(
				root,
				Geo.loft(
					[
						Vector3(-4, 4, 3),
						Vector3(-2, size.x * .58, size.y * .55),
						Vector3(0, size.x * .54, size.y * .54),
						Vector3(0, .01, .01)
					],
					36
				),
				rust
			)
			for x in [-4, 4]:
				Geo.box(root, Vector3(.3, 2, .3), metal, Vector3(x, 1, 4))
			Geo.box(root, Vector3(8.3, .3, .3), metal, Vector3(0, 2, 4))
			Geo.box(root, Vector3(2.4, 1.2, 1.4), metal, Vector3(-3, .6, 3))
		_:
			Geo.put(root, Geo.rock(size, 12 + index % 3 * 4, index + 8), stone())
			for edge in range(6):
				var angle := edge * TAU / 6
				var spot := Vector3(cos(angle) * size.x * .49, 0, sin(angle) * size.y * .49)
				kelp(root, spot, 3 + index % 3, index + edge)
			if data.kind == "cliff":
				Geo.put(root, Geo.rock(Vector2(17, 13), 25, 71), stone(), Vector3(-11, -3, 4))


static func landscape(parent: Node3D) -> void:
	var mat := stone()
	var rng := RandomNumberGenerator.new()
	rng.seed = 260919
	for i in range(4):
		Geo.put(
			parent,
			Geo.boulder(Vector3(95 + i * 20, 50, 80), 800 + i),
			mat,
			Vector3(-210 + i * 95, 11 + i % 2 * 8, -450 - i * 50)
		)
	# One open coastline to the left; the right and horizon remain ocean.
	for i in range(10):
		var x := -40 - i % 3 * 24
		var y := 9 - i * 15
		Geo.put(parent, Geo.boulder(Vector3(65, 90, 85), 100 + i), mat, Vector3(x, y, 30 - i * 27))
	for i in range(35):
		var point := Vector3(
			rng.randf_range(-220, 380), rng.randf_range(-330, -200), rng.randf_range(-650, -160)
		)
		var width := rng.randf_range(35, 100)
		Geo.put(
			parent,
			Geo.boulder(Vector3(width, rng.randf_range(60, 140), width * .8), 400 + i),
			mat,
			point
		)
	for i in range(20):
		var point := Vector3(
			rng.randf_range(-55, 80), rng.randf_range(-160, -40), rng.randf_range(-140, -20)
		)
		# Scenic outcrops are kept outside the landable route bounds.
		point.x += 70 if point.x > 0 else -50
		Geo.put(parent, Geo.boulder(Vector3(12, 15, 10), 600 + i), mat, point)
		kelp(parent, point, 10 + i % 4, i)
	for i in range(8):
		jelly(parent, 1.3 + i % 3 * .5, Vector3(38 + i * 5, -30 - i * 8, -60 - i * 4))
	# Fragmented rock arch; no artificial ruin in the real layer.
	for side in [-1, 1]:
		Geo.put(
			parent,
			Geo.rock(Vector2(20, 25), 75, 88 + side),
			mat,
			Vector3(90 + side * 22, -95, -145)
		)
	var bridge := Geo.put(parent, Geo.rock(Vector2(60, 25), 12, 73), mat, Vector3(90, -95, -145))
	bridge.rotation.z = .1
