extends Node3D
## Original primitive-only test shaft. No imported game scenery.

const FONT = preload("res://game/ui_font.tres")


func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("071c2c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("57a3bb")
	environment.ambient_light_energy = 0.65
	environment.fog_enabled = true
	environment.fog_light_color = Color("0c3547")
	environment.fog_density = 0.012
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, -25, 0)
	sun.light_color = Color("9cdbef")
	sun.light_energy = 1.2
	add_child(sun)
	var stone := material(Color("203e50"))
	var pale := material(Color("45869a"))
	var glow := material(Color("55d8d0"), true)
	var gold := material(Color("ffc787"), true)
	for level in range(25):
		var depth := level * 12.5
		for segment in range(24):
			var angle := TAU * segment / 24.0
			var ring_part := box(Vector3(5.4, 0.4, 0.55), glow if level % 8 == 0 else pale)
			ring_part.position = Vector3(sin(angle) * 21, -depth, cos(angle) * 21)
			ring_part.rotation.y = angle
		for side in range(8):
			var angle := TAU * side / 8.0
			var pillar := box(Vector3(2.6, 12.0, 2.0), stone)
			pillar.position = Vector3(sin(angle) * 25, -depth - 6, cos(angle) * 25)
			pillar.rotation.y = angle
		if level % 8 == 0:
			var label := Label3D.new()
			label.text = "%03d m" % int(depth)
			label.font = FONT
			label.font_size = 96
			label.pixel_size = 0.04
			label.position = Vector3(0, -depth + 3.5, -20)
			label.modulate = Color("a6efe4")
			add_child(label)
	var cable := box(Vector3(0.12, 300, 0.12), gold)
	cable.position = Vector3(12, -150, -12)
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 25
	floor_mesh.bottom_radius = 25
	floor_mesh.height = 1
	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.material_override = stone
	floor_instance.position.y = -302
	add_child(floor_instance)
	var destination := box(Vector3(8, 0.25, 8), gold)
	destination.position = Vector3(0, -301, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7193
	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 0.07
	mote_mesh.height = 0.14
	mote_mesh.radial_segments = 6
	mote_mesh.rings = 3
	var motes := MultiMesh.new()
	motes.transform_format = MultiMesh.TRANSFORM_3D
	motes.mesh = mote_mesh
	motes.instance_count = 700
	for index in range(700):
		var point := Vector3(
			rng.randf_range(-22, 22), rng.randf_range(-300, 8), rng.randf_range(-22, 22)
		)
		motes.set_instance_transform(index, Transform3D(Basis.IDENTITY, point))
	var particles := MultiMeshInstance3D.new()
	particles.multimesh = motes
	particles.material_override = pale
	add_child(particles)


func material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	if glowing:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 1.2
	return result


func box(size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surface
	add_child(instance)
	return instance
