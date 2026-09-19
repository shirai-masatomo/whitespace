extends Node3D
## Procedural art study: continuous surface crossing and depth-stratified lighting.
const Layout = preload("res://game/stage_layout.gd")
const FONT = preload("res://game/ui_font.tres")
const TUNING = preload("res://game/default_config.tres")
var environment: Environment
var sun: DirectionalLight3D
var water_material: ShaderMaterial
var platforms: Array[Node3D] = []
var shafts: Node3D
var sun_disc: MeshInstance3D


func _ready() -> void:
	_make_atmosphere()
	_make_platforms()
	_make_ocean()
	_make_landmarks()


func _make_atmosphere() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("3188cb")
	sky_material.sky_horizon_color = Color("d8e9e5")
	sky_material.ground_bottom_color = Color("20434d")
	sky_material.ground_horizon_color = Color("8ec8d1")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.fog_enabled = true
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-15, -25, 0)
	sun.light_color = Color("fff0c8")
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120
	add_child(sun)
	var disc := QuadMesh.new()
	disc.size = Vector2(220, 220)
	var sun_mat := ShaderMaterial.new()
	sun_mat.shader = preload("res://game/shaders/sun.gdshader")
	sun_disc = add_mesh(disc, sun_mat, Vector3(110, 160, -950))


func _make_platforms() -> void:
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://game/shaders/stone.gdshader")
	var rust := material(Color("8a4f36"))
	var teal := material(Color("254d58"))
	var mint := material(Color("69ffd0"), true)
	var warm := material(Color("ffc47b"), true)
	for index in range(Layout.platforms().size()):
		var data: Dictionary = Layout.platforms()[index]
		var root := Node3D.new()
		root.position = data.position
		add_child(root)
		platforms.append(root)
		var size: Vector2 = data.size
		var tint := warm if data.goal else mint
		var body := StaticBody3D.new()
		body.position.y = -1.0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(size.x, 2, size.y)
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
		if index == 0:
			for plank in range(18):
				mesh_box(
					Vector3(0.96, 0.4, size.y),
					material(Color("99856a")),
					Vector3(plank - 8.5, -0.2, 0),
					root
				)
			for x in [-8, 8]:
				for z in [-7, 7]:
					mesh_box(Vector3(0.45, 12, 0.45), teal, Vector3(x, -6, z), root)
		elif index in [3, 5]:
			# Ribbed ship/container decks have the same readable, landable top bounds.
			mesh_box(Vector3(size.x, 5, size.y), rust, Vector3(0, -2.5, 0), root)
			for rib in range(9):
				mesh_box(
					Vector3(size.x, 0.08, 0.16),
					teal,
					Vector3(0, 0.04, -size.y / 2 + rib * size.y / 8),
					root
				)
			for x in [-size.x / 2, size.x / 2]:
				for z in range(6):
					mesh_box(
						Vector3(0.13, 4.5, 0.2), teal, Vector3(x, -2.5, -size.y / 2 + z * 2), root
					)
		else:
			mesh_box(Vector3(size.x, 1.4, size.y), stone, Vector3(0, -0.7, 0), root)
			var rock := CylinderMesh.new()
			rock.top_radius = minf(size.x, size.y) * 0.6
			rock.bottom_radius = 2
			rock.height = 10
			rock.radial_segments = 7
			add_mesh(rock, stone, Vector3(0, -6.3, 0), root)
		# Broken pillars frame ruin decks without obstructing landing bounds.
		if index in [4, 6, 9, 10]:
			for sign_x in [-1, 1]:
				var pillar := CylinderMesh.new()
				pillar.top_radius = 0.8
				pillar.bottom_radius = 1.1
				pillar.height = 8 + index % 3
				add_mesh(
					pillar, stone, Vector3(sign_x * (size.x / 2 + 1.5), 2.5, -size.y / 2), root
				)
			mesh_box(Vector3(size.x + 6, 1.3, 2), stone, Vector3(0, 6.8, -size.y / 2), root)
		for sign_z in [-1, 1]:
			mesh_box(
				Vector3(size.x, 0.10, 0.12),
				tint if data.oxygen or data.goal else teal,
				Vector3(0, 0.06, sign_z * size.y / 2),
				root
			)
		var label := Label3D.new()
		label.text = "%s / %dm" % [data.label, int(maxf(0, -data.position.y))]
		label.font = FONT
		label.font_size = 40
		label.pixel_size = 0.018
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 4, -size.y / 2)
		if index != 0:
			root.add_child(label)
		else:
			label.free()
		if data.oxygen:
			var sphere := SphereMesh.new()
			sphere.radius = TUNING.oxygen_radius
			sphere.height = TUNING.oxygen_radius * 2
			var bubble_mat := material(Color(0.25, 1.0, 0.75, 0.18), true)
			bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			add_mesh(sphere, bubble_mat, Vector3.UP * 1.6, root)
			var torus := TorusMesh.new()
			torus.inner_radius = 2.7
			torus.outer_radius = 3.0
			add_mesh(torus, mint, Vector3.UP * 0.2, root)


func _make_ocean() -> void:
	var surface := PlaneMesh.new()
	surface.size = Vector2(2600, 2600)
	surface.subdivide_width = 160
	surface.subdivide_depth = 160
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://game/shaders/water.gdshader")
	add_mesh(surface, water_material, Vector3.ZERO)
	var seabed := PlaneMesh.new()
	seabed.size = Vector2(2600, 2600)
	add_mesh(seabed, material(Color("102b35")), Vector3(0, -380, 0))
	shafts = Node3D.new()
	add_child(shafts)
	for index in range(16):
		var beam := CylinderMesh.new()
		beam.top_radius = 1.2 + index % 3
		beam.bottom_radius = 9 + index % 5
		beam.height = 110
		beam.radial_segments = 16
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://game/shaders/sunshaft.gdshader")
		mat.set_shader_parameter("tint", Color(0.65, 0.9, 1, 0.08))
		var shaft := add_mesh(
			beam, mat, Vector3(-80 + index * 14, -50, -35 - (index % 4) * 32), shafts
		)
		shaft.rotation.z = -0.28
	var rng := RandomNumberGenerator.new()
	rng.seed = 905
	var mote := SphereMesh.new()
	mote.radius = 0.07
	mote.height = 0.14
	mote.radial_segments = 4
	mote.rings = 2
	var motes := MultiMesh.new()
	motes.transform_format = MultiMesh.TRANSFORM_3D
	motes.mesh = mote
	motes.instance_count = 1200
	for index in range(1200):
		var point := Vector3(
			rng.randf_range(-100, 100), rng.randf_range(-320, -2), rng.randf_range(-160, 30)
		)
		motes.set_instance_transform(index, Transform3D(Basis.IDENTITY, point))
	var particles := MultiMeshInstance3D.new()
	particles.multimesh = motes
	particles.material_override = material(Color("90d8d6"), true)
	add_child(particles)


func _make_landmarks() -> void:
	var rock_mat := material(Color("183c48"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 250919
	for index in range(38):
		var rock := CylinderMesh.new()
		rock.top_radius = rng.randf_range(5, 16)
		rock.bottom_radius = rng.randf_range(18, 38)
		rock.height = rng.randf_range(40, 170)
		rock.radial_segments = 6
		var x := rng.randf_range(100, 450) * (-1 if index % 2 else 1)
		add_mesh(rock, rock_mat, Vector3(x, rng.randf_range(-360, -60), rng.randf_range(-550, 100)))
	# A distant broken arch and immense chain establish a scale beyond the route.
	for x in [-125, -65]:
		mesh_box(Vector3(12, 110, 15), rock_mat, Vector3(x, -210, -180))
	mesh_box(Vector3(80, 12, 15), rock_mat, Vector3(-95, -155, -180))
	var chain_mat := material(Color("41656b"))
	chain_mat.metallic = 0.65
	for link in range(18):
		var torus := TorusMesh.new()
		torus.inner_radius = 4.5
		torus.outer_radius = 6.3
		var instance := add_mesh(torus, chain_mat, Vector3(95, -15 - link * 12, -100))
		instance.rotation_degrees = Vector3(90, 90 * (link % 2), 0)
	var gold := material(Color("d5aa67"), true)
	for index in range(7):
		mesh_box(Vector3(1.2, 12, 1.2), gold, Vector3(50 + index * 14, -295, -180))


func sync_platforms(data: Array[Dictionary]) -> void:
	for index in range(platforms.size()):
		platforms[index].position = data[index].position


func update_depth(camera_y: float) -> void:
	var immersion := 1.0 - smoothstep(-1.5, 0.8, camera_y)
	var depth := maxf(0, -camera_y)
	var middle := smoothstep(35, 160, depth)
	var deep := smoothstep(170, 300, depth)
	var water_color := Color("15556d").lerp(Color("124268"), middle).lerp(Color("061723"), deep)
	environment.fog_light_color = Color("b9d9e6").lerp(water_color, immersion)
	environment.fog_density = lerpf(0.00012, lerpf(0.003, 0.007, deep), immersion)
	environment.fog_sky_affect = immersion
	environment.ambient_light_color = Color("c2dcf2").lerp(Color("458399"), immersion)
	environment.ambient_light_energy = lerpf(0.45, lerpf(0.48, 0.30, deep), immersion)
	sun.light_energy = lerpf(1.25, lerpf(1.15, 0.35, deep), immersion)
	sun.light_color = Color("fff0c8").lerp(Color("74bed4"), immersion * middle)
	shafts.visible = camera_y < 10 and depth < 150
	sun_disc.visible = camera_y > -1.5


func material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.75
	if glowing:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 0.8
	return result


func add_mesh(
	mesh: Mesh, surface: Material, point: Vector3, parent: Node3D = null
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surface
	instance.position = point
	(self if parent == null else parent).add_child(instance)
	return instance


func mesh_box(
	size: Vector3, surface: Material, point: Vector3, parent: Node3D = null
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(mesh, surface, point, parent)


func make_avatar() -> Node3D:
	var diver := Node3D.new()
	add_child(diver)
	var suit := material(Color("eeaa59"))
	var dark := material(Color("142b34"))
	var body := CapsuleMesh.new()
	body.radius = 0.38
	body.height = 1.4
	add_mesh(body, suit, Vector3(0, 0.95, 0), diver)
	var head := SphereMesh.new()
	head.radius = 0.38
	head.height = 0.76
	add_mesh(head, dark, Vector3(0, 1.8, -0.03), diver)
	mesh_box(Vector3(0.65, 1, 0.4), dark, Vector3(0, 1.1, 0.45), diver)
	for x in [-0.32, 0.32]:
		mesh_box(Vector3(0.4, 0.15, 0.8), suit, Vector3(x, 0.1, -0.16), diver)
	return diver


func make_bubble() -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.15
	sphere.height = 2.3
	var mat := material(Color(0.65, 0.94, 1.0, 0.5), true)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return add_mesh(sphere, mat, Vector3.ZERO)
