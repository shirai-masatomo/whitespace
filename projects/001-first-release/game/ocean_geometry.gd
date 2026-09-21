extends RefCounted
## Authored procedural meshes: shared by scenery and the articulated diver.
const RockSurface = preload("res://game/rock_surface.gd")


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
				var rough := RockSurface.roughness(angle, seed_value, corner.x)
				st.set_uv(
					Vector2(float(corner.y) / segments, float(corner.x) / (profile.size() - 1))
				)
				st.add_vertex(
					Vector3(cos(angle) * ring.y * rough, ring.x, sin(angle) * ring.z * rough)
				)
	st.generate_normals()
	return st.commit()


static func rock(size: Vector2, depth: float, seed_value: int) -> ArrayMesh:
	return loft(RockSurface.profile(size, depth), RockSurface.SEGMENTS, seed_value)


static func boulder(size: Vector3, seed_value: int) -> ArrayMesh:
	var profile: Array[Vector3] = []
	for ring in range(13):
		var t := ring / 12.0
		var radius := maxf(.001, sin(t * PI))
		profile.append(Vector3((t - 1) * size.y, radius * size.x * .5, radius * size.z * .5))
	return loft(profile, 32, seed_value)


static func fault_block(size: Vector3, seed_value: int) -> ArrayMesh:
	# Thick tilted beds with a displaced middle ledge. Unlike a boulder, this
	# supports walking along strata and has recesses beneath the exposed lip.
	var profile: Array[Vector3] = []
	for band in [
		Vector3(-1, .001, .001),
		Vector3(-.91, .44, .44),
		Vector3(-.69, .52, .47),
		Vector3(-.55, .38, .41),
		Vector3(-.48, .37, .40),
		Vector3(-.44, .55, .51),
		Vector3(-.32, .52, .49),
		Vector3(-.18, .39, .38),
		Vector3(-.11, .45, .41),
		Vector3(-.035, .30, .32),
		Vector3(0, .001, .001)
	]:
		profile.append(Vector3(band.x * size.y, band.y * size.x, band.z * size.z))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in loft(profile, 32, seed_value).get_faces():
		var t: float = -point.y / size.y
		point.x += sin(t * 4 + seed_value) * size.x * .10
		point.z += (smoothstep(.42, .52, t) - .5) * size.z * .13
		surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()


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
