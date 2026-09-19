extends RefCounted
## Authored procedural meshes: shared by scenery and the articulated diver.


static func loft(profile: Array[Vector3], segments: int = 24, seed_value: int = 0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for row in range(profile.size() - 1):
		for side in range(segments):
			var corners: Array[Vector2i] = [
				Vector2i(row, side),
				Vector2i(row + 1, side + 1),
				Vector2i(row + 1, side),
				Vector2i(row, side),
				Vector2i(row, side + 1),
				Vector2i(row + 1, side + 1)
			]
			for corner in corners:
				var ring: Vector3 = profile[corner.x]
				var angle := corner.y * TAU / segments
				var rough := 1.0
				if seed_value != 0:
					rough += 0.09 * sin(angle * 5 + seed_value + corner.x * 0.8)
					rough += 0.055 * cos(angle * 9 - seed_value * 0.1)
				st.set_uv(
					Vector2(float(corner.y) / segments, float(corner.x) / (profile.size() - 1))
				)
				st.add_vertex(
					Vector3(cos(angle) * ring.y * rough, ring.x, sin(angle) * ring.z * rough)
				)
	st.generate_normals()
	return st.commit()


static func rock(size: Vector2, depth: float, seed_value: int) -> ArrayMesh:
	var x := size.x * 0.5
	var z := size.y * 0.5
	return loft(
		[
			Vector3(-depth, 0.01, 0.01),
			Vector3(-depth * 0.92, x * 0.42, z * 0.5),
			Vector3(-depth * 0.67, x * 0.83, z * 0.73),
			Vector3(-depth * 0.27, x * 1.12, z * 1.04),
			Vector3(-1.1, x * 1.16, z * 1.15),
			Vector3(0, x * 1.1, z * 1.1),
			Vector3(0, 0.01, 0.01)
		],
		32,
		seed_value
	)


static func boulder(size: Vector3, seed_value: int) -> ArrayMesh:
	var profile: Array[Vector3] = []
	for ring in range(13):
		var t := ring / 12.0
		var radius := maxf(.001, sin(t * PI))
		profile.append(Vector3((t - 1) * size.y, radius * size.x * .5, radius * size.z * .5))
	return loft(profile, 32, seed_value)


static func leaf(height: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for row in range(12):
		for index in [
			Vector2i(row, 0),
			Vector2i(row + 1, 0),
			Vector2i(row + 1, 1),
			Vector2i(row, 0),
			Vector2i(row + 1, 1),
			Vector2i(row, 1)
		]:
			var t: float = index.x / 12.0
			var w := maxf(0.01, sin(t * PI) * width)
			st.set_uv(Vector2(index.y, t))
			st.add_vertex(Vector3((index.y * 2 - 1) * w, t * height, sin(t * 3.3) * height * 0.17))
	st.generate_normals()
	return st.commit()


static func material(
	color: Color, roughness: float = 0.7, metallic: float = 0.0
) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


static func put(
	parent: Node3D, mesh: Mesh, mat: Material, point: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = point
	parent.add_child(instance)
	return instance


static func box(parent: Node3D, size: Vector3, mat: Material, point: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return put(parent, mesh, mat, point)


static func sphere(parent: Node3D, radius: float, mat: Material, point: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 24
	mesh.rings = 12
	return put(parent, mesh, mat, point)
