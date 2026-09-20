extends Node3D
## Original low-cost shoals gather near oxygen algae; no collision or paid assets.
const Geo = preload("res://game/ocean_geometry.gd")
const Layout = preload("res://game/stage_layout.gd")
const Reef = preload("res://game/playground_rules.gd")
var rays: Array[Node3D] = []
var shoals: Array[Node3D] = []
var origins: Array[Vector3] = []
var reef_guide: Node3D
var canyon_rays: Array[Node3D] = []
var canyon_school: Node3D


func _ready() -> void:
	for platform in Layout.platforms():
		if platform.oxygen:
			make_shoal(platform.position + Vector3.UP * 5, 16)
	make_shoal(Vector3(8, -18, -21), 24)
	make_shoal(Vector3(6, -9, -24), 96, Vector3(2.4, 1.8, 1.0), true)
	reef_guide = shoals[-1]
	for zone in Layout.current_zones():
		make_shoal(zone.center, 32)
	for index in range(3):
		var ray := make_ray()
		ray.name = "RayGuide%d" % index
		ray.scale = Vector3.ONE * (1.0 - index * .15)
		add_child(ray)
		rays.append(ray)

	# Optional wildlife passage: bridge -> open wall cut -> offshore overlook.
	make_shoal(Vector3(124, -185, -195), 54)
	canyon_school = shoals[-1]
	for index in range(3):
		var ray := make_ray()
		ray.name = "CanyonRay%d" % index
		ray.scale = Vector3.ONE * (2.4 if index == 0 else 1.1)
		add_child(ray)
		canyon_rays.append(ray)


static func canyon_passage(time: float) -> Vector3:
	# The animals disappear around the outer shore and re-enter below it. They
	# reveal an actual alternate entrance, not a timed gate or escort objective.
	var places := [
		Vector3(113, -174, -211),
		Vector3(147, -184, -210),
		Vector3(180, -202, -192),
		Vector3(166, -197, -207),
		Vector3(146, -216, -210),
		Vector3(119, -214, -224),
		Vector3(108, -198, -223)
	]
	var progress := fposmod(time / 7, places.size())
	var index := int(progress)
	var t := progress - index
	var p0: Vector3 = places[posmod(index - 1, places.size())]
	var p1: Vector3 = places[index]
	var p2: Vector3 = places[(index + 1) % places.size()]
	var p3: Vector3 = places[(index + 2) % places.size()]
	return (
		.5
		* (
			(2 * p1)
			+ (-p0 + p2) * t
			+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
			+ (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t
		)
	)


func make_ray() -> Node3D:
	var animal := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Closed, curved disc: nearby wildlife must not be a single paper triangle.
	for face in [-1, 1]:
		for row in range(24):
			for lane in range(20):
				var a := _ray_point(row / 24.0, lane / 10.0 - 1, face)
				var b := _ray_point((row + 1) / 24.0, lane / 10.0 - 1, face)
				var c := _ray_point((row + 1) / 24.0, (lane + 1) / 10.0 - 1, face)
				var d := _ray_point(row / 24.0, (lane + 1) / 10.0 - 1, face)
				var points := [a, b, c, a, c, d] if face > 0 else [a, d, c, a, c, b]
				for point in points:
					st.add_vertex(point)
	st.generate_normals()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/shaders/ray.gdshader")
	Geo.put(animal, st.commit(), mat)
	for side in [-1, 1]:
		Geo.sphere(animal, .065, Geo.material(Color("0a1f25")), Vector3(side * .34, .32, -1.35))
	var tail := Geo.put(
		animal,
		Geo.loft([Vector3(0, .13, .13), Vector3(4, .015, .015)], 8),
		Geo.material(Color("284b4e")),
		Vector3(0, 0, 1)
	)
	tail.rotation.x = PI / 2
	return animal


func _ray_point(t: float, lane: float, face: int) -> Vector3:
	var z := -2 + t * 3.5
	var width := sin(pow(t, .68) * PI) * (1.3 + 2.5 * sin(t * PI))
	var thickness := .36 * pow(1 - lane * lane, 3) * sin(t * PI)
	var camber := -.16 * lane * lane * sin(t * PI)
	return Vector3(lane * width, camber + face * thickness, z)


static func reef_passage(time: float) -> Vector3:
	var phase := time * .2
	var progress := .5 - .5 * cos(phase)
	# Separate outward/return lanes let the group bend round instead of
	# stopping and flipping every fish through 180 degrees at the refuge.
	return (
		Vector3(6, -9, -24).lerp(Reef.PLANTS[0] + Vector3(0, 6, -3), progress)
		+ Vector3(0, 0, -6 * sin(phase))
	)


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
	var destination := reef_passage(elapsed)
	var separation := destination - player
	reef_guide.position = destination + separation.normalized() * maxf(0, 6 - separation.length())
	var reef_heading := reef_passage(elapsed + .1) - reef_passage(elapsed - .1)
	reef_guide.rotation.y = atan2(reef_heading.x, reef_heading.z)

	for index in range(canyon_rays.size()):
		var time := elapsed + index * 1.7
		var point := canyon_passage(time) + Vector3(0, -index * 1.5, index * 3)
		var away := point - player
		point += away.normalized() * maxf(0, 7 - away.length()) * .5
		canyon_rays[index].position = point
		var heading := canyon_passage(time + .3) - canyon_passage(time - .3)
		canyon_rays[index].rotation.y = atan2(-heading.x, -heading.z)
	var school_point := canyon_passage(elapsed + 3) + Vector3(0, -4, 0)
	var school_away := school_point - player
	canyon_school.position = (
		school_point + school_away.normalized() * maxf(0, 8 - school_away.length())
	)
	var school_heading := canyon_passage(elapsed + 3.3) - canyon_passage(elapsed + 2.7)
	canyon_school.rotation.y = atan2(school_heading.x, school_heading.z)


func make_shoal(
	point: Vector3, count: int, spread: Vector3 = Vector3.ONE, guided: bool = false
) -> void:
	var mesh := fish_mesh(not guided and count == 16)
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/shaders/fish.gdshader")
	material.set_shader_parameter("guided_motion", guided)
	mesh.surface_set_material(0, material)
	var swarm := MultiMesh.new()
	swarm.transform_format = MultiMesh.TRANSFORM_3D
	swarm.use_custom_data = true
	swarm.mesh = mesh
	swarm.instance_count = count
	swarm.custom_aabb = AABB(Vector3(-15, -6, -15), Vector3(30, 12, 30))
	var rng := RandomNumberGenerator.new()
	rng.seed = 92103 + count
	for index in range(count):
		var angle := index * 2.399
		var radius := sqrt(index / float(count)) * 2.4
		var offset := Vector3(cos(angle) * radius, sin(index * 3.7), sin(angle) * radius)
		var size := rng.randf_range(.4, .65)
		var turn := rng.randf_range(-.12, .12)
		if guided:
			# Unequal overlapping groups, with gaps and small juveniles between.
			var centres := [Vector3(-1.4, .3, -1.5), Vector3(.9, -.3, .4), Vector3(1.4, .7, 2.0)]
			offset = (
				centres[index % 3]
				+ Vector3(rng.randfn(0, .65), rng.randfn(0, .4), rng.randfn(0, .9))
			)
			size = rng.randf_range(.36, .74)
			turn = rng.randf_range(-.16, .16)
		offset *= spread
		swarm.set_instance_transform(
			index, Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * size), offset)
		)
		swarm.set_instance_custom_data(index, Color(index / float(count), 0, 0, 1))
	var school := MultiMeshInstance3D.new()
	school.multimesh = swarm
	school.position = point
	add_child(school)
	shoals.append(school)
	origins.append(point)


static func fish_mesh(deep_body: bool) -> ArrayMesh:
	# Original streamlined body plus separate forked fins. The old loft expanded
	# its tail into a solid wedge, making each animal look like the same token.
	var profile := [
		Vector3(-.54, .014, .026),
		Vector3(-.36, .038, .065),
		Vector3(-.12, .083, .115),
		Vector3(.18, .09, .125),
		Vector3(.38, .071, .095),
		Vector3(.52, .026, .042),
		Vector3(.57, .001, .006)
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(0, 0, 0))
	for row in range(profile.size() - 1):
		for side in range(12):
			for corner in [
				Vector2i(row, side),
				Vector2i(row + 1, side),
				Vector2i(row + 1, side + 1),
				Vector2i(row, side),
				Vector2i(row + 1, side + 1),
				Vector2i(row, side + 1)
			]:
				var ring: Vector3 = profile[corner.x]
				var angle: float = corner.y * TAU / 12
				st.add_vertex(
					Vector3(
						cos(angle) * ring.y,
						sin(angle) * ring.z * (1.35 if deep_body else 1),
						ring.x
					)
				)
	st.set_color(Color(1, 0, 0))
	var fork := .24 if deep_body else .19
	for side in [-1, 1]:
		for point in [
			Vector3(0, 0, -.48), Vector3(0, side * fork, -.78), Vector3(0, side * .045, -.65)
		]:
			st.add_vertex(point)
		for point in [
			Vector3(side * .065, -.025, .2),
			Vector3(side * .23, -.08, -.07),
			Vector3(side * .08, -.05, -.02)
		]:
			st.add_vertex(point)
	var dorsal := .28 if deep_body else .19
	for point in [Vector3(0, .09, -.18), Vector3(0, dorsal, -.08), Vector3(0, .11, .19)]:
		st.add_vertex(point)
	st.generate_normals()
	return st.commit()
