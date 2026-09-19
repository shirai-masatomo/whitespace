extends Node3D
## Original low-cost shoals gather near oxygen algae; no collision or paid assets.
const Geo = preload("res://game/ocean_geometry.gd")
const Layout = preload("res://game/stage_layout.gd")


func _ready() -> void:
	for platform in Layout.platforms():
		if platform.oxygen:
			make_shoal(platform.position + Vector3.UP * 5, 16)
	make_shoal(Vector3(8, -18, -21), 24)


func make_shoal(point: Vector3, count: int) -> void:
	var shape := Geo.loft(
		[
			Vector3(-.8, .02, .3),
			Vector3(-.53, .025, .035),
			Vector3(-.32, .08, .14),
			Vector3(.05, .14, .23),
			Vector3(.38, .1, .15),
			Vector3(.62, .02, .03)
		],
		12
	)
	var combined := SurfaceTool.new()
	combined.begin(Mesh.PRIMITIVE_TRIANGLES)
	combined.append_from(shape, 0, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3.ZERO))
	var mesh := combined.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/shaders/fish.gdshader")
	mesh.surface_set_material(0, material)
	var swarm := MultiMesh.new()
	swarm.transform_format = MultiMesh.TRANSFORM_3D
	swarm.use_custom_data = true
	swarm.mesh = mesh
	swarm.instance_count = count
	swarm.custom_aabb = AABB(Vector3(-15, -6, -15), Vector3(30, 12, 30))
	for index in range(count):
		var angle := index * 2.399
		var radius := sqrt(index / float(count)) * 2.4
		var offset := Vector3(cos(angle) * radius, sin(index * 3.7), sin(angle) * radius)
		swarm.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ONE * .65), offset))
		swarm.set_instance_custom_data(index, Color(index / float(count), 0, 0, 1))
	var school := MultiMeshInstance3D.new()
	school.multimesh = swarm
	school.position = point
	add_child(school)
