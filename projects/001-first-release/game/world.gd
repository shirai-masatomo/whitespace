extends Node3D
## Open ocean, scattered landable shelves and distant silhouettes. No enclosing walls.

const Layout = preload("res://game/stage_layout.gd")
const FONT = preload("res://game/ui_font.tres")
const TUNING = preload("res://game/default_config.tres")
var environment: Environment
var oxygen_material: StandardMaterial3D


func _ready() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a0dce5")
	environment.ambient_light_energy = 0.85
	environment.fog_enabled = true
	environment.fog_density = 0.0018
	environment.fog_sky_affect = 1.0
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65, -30, 0)
	sun.light_color = Color("c6efff")
	sun.light_energy = 1.4
	add_child(sun)
	var stone := material(Color("365d75"))
	var pale := material(Color("6c9aaf"))
	var mint := material(Color("83ffe0"), true)
	var gold := material(Color("ffc67c"), true)
	oxygen_material = material(Color(0.3, 1, 0.8, 0.16), true)
	oxygen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for index in range(Layout.platforms().size()):
		var platform: Dictionary = Layout.platforms()[index]
		var point: Vector3 = platform.position
		var size: Vector2 = platform.size
		var tint := gold if platform.goal else (mint if platform.oxygen else pale)
		mesh_box(Vector3(size.x, 2, size.y), stone, point + Vector3.DOWN * 1.04)
		mesh_box(
			Vector3(size.x, 0.10, size.y), material(Color("426674")), point - Vector3.UP * 0.05
		)
		for sign_z in [-1, 1]:
			mesh_box(
				Vector3(size.x, 0.16, 0.18), tint, point + Vector3(0, 0.07, sign_z * size.y / 2)
			)
		for sign_x in [-1, 1]:
			mesh_box(
				Vector3(0.18, 0.16, size.y), tint, point + Vector3(sign_x * size.x / 2, 0.07, 0)
			)
		var body := StaticBody3D.new()
		body.position = point + Vector3.DOWN
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(size.x, 2, size.y)
		shape.shape = box_shape
		body.add_child(shape)
		add_child(body)
		# Tapered undersides make each shelf read as an isolated floating island.
		var base := CylinderMesh.new()
		base.top_radius = minf(size.x, size.y) * 0.44
		base.bottom_radius = 1.8
		base.height = 7
		base.radial_segments = 5
		add_mesh(base, stone, point + Vector3(0, -5.5, 0))
		var label := Label3D.new()
		label.text = "%02d  %s\n%dm" % [index, platform.label, int(-point.y)]
		label.font = FONT
		label.font_size = 48
		label.pixel_size = 0.018
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = point + Vector3(0, 5, -size.y / 2)
		label.modulate = Color("f1f8e9")
		add_child(label)
		if platform.oxygen:
			var ring := CylinderMesh.new()
			ring.top_radius = TUNING.oxygen_radius
			ring.bottom_radius = TUNING.oxygen_radius
			ring.height = 0.12
			add_mesh(ring, mint, point + Vector3.UP * 0.12)
			var sphere := SphereMesh.new()
			sphere.radius = TUNING.oxygen_radius
			sphere.height = TUNING.oxygen_radius * 2
			add_mesh(sphere, oxygen_material, point + Vector3.UP * 1.6)
		elif platform.goal:
			mesh_box(Vector3(4, 0.2, 4), gold, point + Vector3.UP * 0.15)
	# Far silhouettes are sparse landmarks, not an enclosing cylinder.
	var rng := RandomNumberGenerator.new()
	rng.seed = 250919
	for index in range(36):
		var rock := CylinderMesh.new()
		rock.top_radius = rng.randf_range(8, 18)
		rock.bottom_radius = rng.randf_range(12, 24)
		rock.height = rng.randf_range(35, 85)
		rock.radial_segments = 5
		var x := rng.randf_range(-420, 420)
		var z := rng.randf_range(-500, 180)
		if absf(x) < 100:
			x += 180
		add_mesh(rock, stone, Vector3(x, rng.randf_range(-400, 30), z))
	var seabed := PlaneMesh.new()
	seabed.size = Vector2(2500, 2500)
	add_mesh(seabed, material(Color("173d59")), Vector3(0, -420, 0))
	var surface := PlaneMesh.new()
	surface.size = Vector2(2500, 2500)
	var surface_mat := material(Color("4bb1be"))
	surface_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_mesh(surface, surface_mat, Vector3(0, 35, 0))
	var mote := SphereMesh.new()
	mote.radius = 0.12
	mote.height = 0.24
	mote.radial_segments = 6
	mote.rings = 3
	var motes := MultiMesh.new()
	motes.transform_format = MultiMesh.TRANSFORM_3D
	motes.mesh = mote
	motes.instance_count = 950
	for index in range(950):
		var point := Vector3(
			rng.randf_range(-150, 150), rng.randf_range(-350, 25), rng.randf_range(-200, 100)
		)
		motes.set_instance_transform(index, Transform3D(Basis.IDENTITY, point))
	var particles := MultiMeshInstance3D.new()
	particles.multimesh = motes
	particles.material_override = pale
	add_child(particles)
	update_depth(0)


func update_depth(depth: float) -> void:
	var ratio := clampf(depth / 300, 0, 1)
	environment.background_color = Color("327d9a").lerp(Color("12253f"), ratio)
	environment.fog_light_color = environment.background_color
	environment.ambient_light_energy = lerpf(0.85, 0.55, ratio)


func material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	if glowing:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 0.6
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
	var suit := material(Color("ffc98b"))
	var dark := material(Color("183549"))
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
	var bubble_mat := material(Color(0.65, 0.94, 1.0, 0.5), true)
	bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return add_mesh(sphere, bubble_mat, Vector3.ZERO)
