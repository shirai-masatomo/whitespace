extends SceneTree
## Compare real mesh triangles against landing rules, not against their shared helper.
const Model = preload("res://game/dive_model.gd")
const Nature = preload("res://game/ocean_nature.gd")
var failures := 0
var samples := 0


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var model = Model.new()
	model.config.current_strength = 0  # Isolate footprint from lateral current displacement.
	for index in range(model.platforms.size()):
		var platform: Dictionary = model.platforms[index]
		if platform.kind not in ["rock", "kelp", "cliff", "jelly", "buoy"]:
			continue
		platform.sway = Vector2.ZERO  # Moving-platform tracking is tested separately.
		var fixture := Node3D.new()
		root.add_child(fixture)
		Nature.deck(fixture, platform, index)
		var surface := fixture.find_child("LandingSurface", true, false) as MeshInstance3D
		var triangles := surface.mesh.get_faces()
		for vertex in range(triangles.size()):
			triangles[vertex] = surface.global_transform * triangles[vertex]
		for angle_index in range(32):
			# Avoid rays exactly on shared triangle edges, where epsilon is implementation-dependent.
			var angle := (angle_index + .37) * TAU / 32
			for radius in [.95, 1.05, 1.2, 1.3]:
				var offset := Vector3(
					cos(angle) * platform.size.x * .5 * radius,
					0,
					sin(angle) * platform.size.y * .5 * radius
				)
				var minimum_y: float = -platform.size.x * .36 if platform.kind == "jelly" else -.001
				var top_y := top_height(triangles, offset, minimum_y)
				var visible := is_finite(top_y)
				var landable: bool = model.inside(offset + platform.position, platform)
				samples += 1
				if visible != landable:
					failures += 1
					push_error(
						"Visible landing rim and footprint differ at %d: %s" % [index, offset]
					)
				if visible:
					model.position = platform.position + offset + Vector3.UP * (top_y + 2)
					model.velocity = Vector3.DOWN * 15
					model.grounded = -1
					model.jelly_cooldown = 0
					model.oxygen = 100
					model.mode = Model.Mode.DIVING
					var bounces: int = model.interactions.jelly
					for frame in range(12):
						model.step(1.0 / 60, Vector2.ZERO, 1)
					var landed: bool = model.grounded == index
					if platform.kind == "jelly":
						landed = model.interactions.jelly > bounces
					if not landed:
						failures += 1
						push_error("Fast descent must land on visible rim %d: %s" % [index, offset])
		fixture.free()
	print("Platform surfaces: %d mesh comparisons, %d failures" % [samples, failures])
	quit(1 if failures else 0)


func top_height(faces: PackedVector3Array, point: Vector3, minimum_y: float) -> float:
	var height := -INF
	for index in range(0, faces.size(), 3):
		if minf(faces[index].y, minf(faces[index + 1].y, faces[index + 2].y)) < minimum_y:
			continue
		var hit = Geometry3D.ray_intersects_triangle(
			point + Vector3.UP * 20, Vector3.DOWN, faces[index], faces[index + 1], faces[index + 2]
		)
		if hit != null:
			height = maxf(height, hit.y)
	return height
