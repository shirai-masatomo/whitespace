extends Node3D
## Original low-cost shoals gather near oxygen algae; no collision or paid assets.
const Geo = preload("res://game/ocean_geometry.gd")
const Layout = preload("res://game/stage_layout.gd")
var rays: Array[Node3D] = []
var shoals: Array[Node3D] = []
var origins: Array[Vector3] = []
var reef_guide: Node3D


func _ready() -> void:
	for platform in Layout.platforms():
		if platform.oxygen:
			make_shoal(platform.position + Vector3.UP * 5, 16)
	make_shoal(Vector3(8, -18, -21), 24)
	make_shoal(Vector3(15, -12, -19), 48)
	reef_guide = shoals[-1]
	for zone in Layout.current_zones():
		make_shoal(zone.center, 32)
	for index in range(3):
		var ray := make_ray()
		ray.name = "RayGuide%d" % index
		ray.scale = Vector3.ONE * (1.0 - index * .15)
		add_child(ray)
		rays.append(ray)


func make_ray() -> Node3D:
	var animal := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Original swept diamond silhouette, rounded head and tapered trailing tail.
	var rim := [
		Vector3(0, .2, -2),
		Vector3(1.1, .05, -1.2),
		Vector3(3.6, 0, .5),
		Vector3(1.1, -.05, 1),
		Vector3(0, 0, 1.5),
		Vector3(-1.1, -.05, 1),
		Vector3(-3.6, 0, .5),
		Vector3(-1.1, .05, -1.2)
	]
	for index in range(rim.size()):
		for point in [Vector3(0, .28, 0), rim[(index + 1) % rim.size()], rim[index]]:
			st.add_vertex(point)
	st.generate_normals()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/ray.gdshader")
	Geo.put(animal, st.commit(), mat)
	for side in [-1, 1]:
		Geo.sphere(animal, .11, Geo.material(Color("0a1f25")), Vector3(side * .34, .25, -1.35))
	var tail := Geo.put(
		animal,
		Geo.loft([Vector3(0, .13, .13), Vector3(4, .015, .015)], 8),
		Geo.material(Color("284b4e")),
		Vector3(0, 0, 1)
	)
	tail.rotation.x = PI / 2
	return animal


func update(player: Vector3, elapsed: float, giant: Vector3 = Vector3.INF) -> void:
	for index in range(rays.size()):
		var phase := elapsed * .075 + index * .65
		# The school crosses the open water toward an optional rock-garden entrance.
		var natural := Vector3(-20 + cos(phase) * 18, -122 + sin(phase) * 12, -78 + sin(phase) * 12)
		var separation := natural - player
		var avoidance := separation.normalized() * maxf(0, 5 - separation.length())
		rays[index].position = natural + avoidance
		rays[index].rotation.y = atan2(sin(phase) * 40, -cos(phase) * 15)
	for index in range(shoals.size()):
		var away := origins[index] - player
		var escape := away.normalized() * maxf(0, 7 - away.length()) * .65
		if giant.is_finite():
			var disturbance := origins[index] - giant
			escape += disturbance.normalized() * maxf(0, 42 - disturbance.length()) * .4
		shoals[index].position = origins[index] + escape
	# A living lateral clue, with a return path, rather than an arrow or a
	# mandatory escort. The shoal repeatedly crosses towards the kelp refuge.
	var progress := .5 - .5 * cos(elapsed * .2)
	var destination := Vector3(12, -12, -18).lerp(Vector3(35, -22, -28), progress)
	var separation := destination - player
	reef_guide.position = destination + separation.normalized() * maxf(0, 6 - separation.length())


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
	shoals.append(school)
	origins.append(point)
